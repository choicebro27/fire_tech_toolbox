// lib/services/gemma_service.dart
//
// Wraps flutter_gemma v0.3.x to provide on-device LLM inference.
// Gemma 2B-IT runs entirely on the device — no API key, works offline.

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'standards_db.dart';

const String _kModelDownloadedKey = 'gemma_model_downloaded';

// IMPORTANT: The HuggingFace URL for google/gemma-2b-it-tflite is a gated
// repository that requires authentication. For production:
//   1. Download the model from: https://www.kaggle.com/models/google/gemma/frameworks/tfLite/
//   2. Host it on your own Firebase Storage (or any CDN with public read access)
//   3. Replace the URL below with your hosted URL
const String _kModelUrl =
    'https://huggingface.co/google/gemma-2b-it-tflite/resolve/main/gemma-2b-it-gpu-int4.bin';

enum GemmaStatus { notDownloaded, downloading, ready, error }

class GemmaService extends ChangeNotifier {
  GemmaService._();
  static final GemmaService instance = GemmaService._();

  GemmaStatus _status = GemmaStatus.notDownloaded;
  double _downloadProgress = 0.0;
  String? _errorMessage;
  http.Client? _downloadClient;

  GemmaStatus get status => _status;
  double get downloadProgress => _downloadProgress;
  String? get errorMessage => _errorMessage;
  bool get isReady => _status == GemmaStatus.ready;

  // ── Init: check if model already downloaded ───────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final downloaded = prefs.getBool(_kModelDownloadedKey) ?? false;
    if (!downloaded) return;

    // Verify the file actually exists (user may have cleared storage)
    final file = await _modelFile();
    if (!await file.exists()) {
      await prefs.remove(_kModelDownloadedKey);
      return;
    }
    await _initModel();
  }

  Future<File> _modelFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/model.bin');
  }

  // ── Download + init ───────────────────────────────────────────────────────

  Future<void> downloadModel() async {
    if (_status == GemmaStatus.downloading || _status == GemmaStatus.ready) return;

    _status = GemmaStatus.downloading;
    _downloadProgress = 0.0;
    _errorMessage = null;
    notifyListeners();

    try {
      final file = await _modelFile();

      // Use http package so we can inspect the status code before saving.
      // large_file_handler (used by flutter_gemma internally) blindly saves
      // whatever the server returns — including 401 error pages.
      _downloadClient = http.Client();
      final response = await _downloadClient!.send(
        http.Request('GET', Uri.parse(_kModelUrl)),
      );

      if (response.statusCode == 401) {
        throw Exception(
          'The Gemma model requires a HuggingFace account with accepted Gemma '
          'terms of use. Download the model from Kaggle and host it on your own '
          'server or Firebase Storage, then update the URL in gemma_service.dart.',
        );
      }
      if (response.statusCode != 200) {
        throw Exception(
          'Download server returned HTTP ${response.statusCode}. '
          'Check the model URL in gemma_service.dart.',
        );
      }

      final totalBytes = response.contentLength ?? 0;
      int received = 0;
      final sink = file.openWrite();
      try {
        await for (final chunk in response.stream) {
          sink.add(chunk);
          received += chunk.length;
          if (totalBytes > 0) {
            _downloadProgress = received / totalBytes;
            notifyListeners();
          }
        }
      } finally {
        await sink.close();
      }
      _downloadClient = null;

      await _initModel();

      // Only persist the "downloaded" flag after a confirmed successful init.
      if (_status == GemmaStatus.ready) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_kModelDownloadedKey, true);
      }
    } catch (e) {
      _status = GemmaStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _downloadClient = null;
      await _deleteModelFile();
      notifyListeners();
    }
  }

  Future<void> _deleteModelFile() async {
    try {
      final file = await _modelFile();
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  Future<void> _initModel() async {
    try {
      await FlutterGemmaPlugin.instance.init(
        maxTokens: 1024,
        temperature: 0.2,
        topK: 40,
      );
      // flutter_gemma's init() swallows PlatformExceptions internally.
      // Awaiting isInitialized surfaces the real result — throws if init failed.
      await FlutterGemmaPlugin.instance.isInitialized;
      _status = GemmaStatus.ready;
      _errorMessage = null;
    } catch (e) {
      _status = GemmaStatus.error;
      _errorMessage =
          'Model initialisation failed — the file may be corrupt. '
          'Tap Retry to download again.';
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kModelDownloadedKey);
      await _deleteModelFile();
    }
    notifyListeners();
  }

  // ── Ask a question (RAG: retrieve chunks → build prompt → stream tokens) ──

  Stream<String> ask(String question) async* {
    if (!isReady) {
      yield 'Model not loaded. Please download the AI model first.';
      return;
    }

    // 1. Retrieve relevant chunks from the uploaded standards
    final chunks = await StandardsDb.instance.search(question, limit: 4);

    if (chunks.isEmpty) {
      yield 'No relevant sections found in your uploaded standards. '
            'Please upload the relevant Australian Standard PDF in the Library tab first.';
      return;
    }

    // 2. Build the RAG prompt using Gemma instruction-tuned format
    final prompt = _buildPrompt(question: question, chunks: chunks);

    // 3. Stream tokens back from the on-device model
    try {
      final responseStream = FlutterGemmaPlugin.instance.getResponseAsync(
        prompt: prompt,
      );

      await for (final token in responseStream) {
        if (token != null && token.isNotEmpty) {
          yield token;
        }
      }
    } catch (e) {
      yield '\n\n[Generation error: ${e.toString()}]';
    }
  }

  // ── Prompt construction ───────────────────────────────────────────────────

  String _buildPrompt({
    required String question,
    required List<StandardChunk> chunks,
  }) {
    final contextBuffer = StringBuffer();
    for (final chunk in chunks) {
      final label = chunk.clauseRef.isNotEmpty
          ? '${chunk.standardName} — Clause ${chunk.clauseRef} (p.${chunk.pageNumber})'
          : '${chunk.standardName} — Page ${chunk.pageNumber}';
      contextBuffer.writeln('[$label]');
      contextBuffer.writeln(chunk.content.trim());
      contextBuffer.writeln();
    }

    // Gemma 2B-IT instruction format
    return '<start_of_turn>user\n'
        'You are a fire protection standards assistant for Australian technicians.\n'
        'Answer ONLY using the standard excerpts below. '
        'Always cite the exact clause number and standard name. '
        'If the answer is not in the excerpts, say so clearly. '
        'Be concise and practical.\n\n'
        'STANDARD EXCERPTS:\n'
        '$contextBuffer\n'
        'QUESTION: $question\n'
        '<end_of_turn>\n'
        '<start_of_turn>model\n';
  }

  @override
  void dispose() {
    _downloadClient?.close();
    super.dispose();
  }
}
