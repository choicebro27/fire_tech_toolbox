// lib/pages/ai_chat_page.dart
//
// Two-tab page:
//   Tab 1 — Standards Library (upload / manage PDFs)
//   Tab 2 — AI Chat (ask questions, get clause-cited answers)

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/gemma_service.dart';
import '../services/pdf_indexer.dart';
import '../services/standards_db.dart';
import '../theme/app_theme.dart';
import '../theme/widgets.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Standards AI'),
        actions: const [AccentBadge(text: 'ON-DEVICE AI'), SizedBox(width: 12)],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: null, // inherits from theme
          tabs: const [
            Tab(icon: Icon(Icons.library_books_rounded), text: 'Library'),
            Tab(icon: Icon(Icons.chat_rounded),          text: 'Ask AI'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _LibraryTab(),
          _ChatTab(),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 1 — Standards Library
// ══════════════════════════════════════════════════════════════════════════════

class _LibraryTab extends StatefulWidget {
  const _LibraryTab();

  @override
  State<_LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<_LibraryTab> {
  List<StandardMeta> _standards = [];
  bool _loading = true;

  // Upload state
  bool _uploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';

  @override
  void initState() {
    super.initState();
    _loadStandards();
  }

  Future<void> _loadStandards() async {
    final list = await StandardsDb.instance.listStandards();
    if (mounted) setState(() { _standards = list; _loading = false; });
  }

  Future<void> _pickAndIndex() async {
    // 1. Let user pick a PDF
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;
    if (picked.path == null) return;

    // 2. Ask user to name the standard
    final name = await _showNameDialog(picked.name);
    if (name == null || name.trim().isEmpty) return;

    final standardId = standardNameToId(name);

    // Check for duplicate
    final exists = await StandardsDb.instance.standardExists(standardId);
    if (exists && mounted) {
      final replace = await _showReplaceDialog(name);
      if (replace != true) return;
      await StandardsDb.instance.deleteStandard(standardId);
    }

    // 3. Index
    setState(() { _uploading = true; _uploadProgress = 0; _uploadStatus = 'Starting…'; });

    try {
      final file = File(picked.path!);
      final chunks = await PdfIndexer.instance.indexPdf(
        file: file,
        standardName: name.trim(),
        standardId: standardId,
        onProgress: (progress, status) {
          if (mounted) setState(() { _uploadProgress = progress; _uploadStatus = status; });
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Indexed $chunks sections from ${name.trim()}'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ Failed to index PDF: $e'),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
      await _loadStandards();
    }
  }

  Future<String?> _showNameDialog(String filename) async {
    // Pre-populate with a cleaned-up filename guess
    final guess = filename
        .replaceAll('.pdf', '')
        .replaceAll('_', ' ')
        .replaceAll('-', ' ');

    final ctrl = TextEditingController(text: guess);
    try {
      return await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: ctx.appSurface,
          title: Text('Name this Standard', style: TextStyle(color: ctx.appText)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enter the standard name as it should appear in citations:',
                style: TextStyle(color: ctx.appTextSec, fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                style: TextStyle(color: ctx.appText),
                decoration: InputDecoration(
                  hintText: 'e.g. AS 1670.1-2018',
                  hintStyle: TextStyle(color: ctx.appTextMuted),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('Index PDF'),
            ),
          ],
        ),
      );
    } finally {
      ctrl.dispose();
    }
  }

  Future<bool?> _showReplaceDialog(String name) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.appSurface,
        title: Text('Replace existing?', style: TextStyle(color: ctx.appText)),
        content: Text('$name is already in your library. Replace it?',
          style: TextStyle(color: ctx.appTextSec)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStandard(StandardMeta meta) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.appSurface,
        title: Text('Delete standard?', style: TextStyle(color: ctx.appText)),
        content: Text('Remove ${meta.name} from your library? This cannot be undone.',
          style: TextStyle(color: ctx.appTextSec)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await StandardsDb.instance.deleteStandard(meta.id);
      await _loadStandards();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Model download status ────────────────────────────────────────
        const _ModelStatusBanner(),

        // ── Upload progress ──────────────────────────────────────────────
        if (_uploading) _buildUploadProgress(context),

        // ── Library list ─────────────────────────────────────────────────
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : _standards.isEmpty
              ? _buildEmptyState(context)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ..._standards.map((s) => _StandardCard(
                      meta: s,
                      onDelete: () => _deleteStandard(s),
                    )),
                    const SizedBox(height: 80), // fab clearance
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildUploadProgress(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
              ),
              const SizedBox(width: 10),
              Text('Indexing PDF…', style: TextStyle(color: context.appText, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: context.appSurfaceAlt,
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(_uploadStatus, style: TextStyle(color: context.appTextMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.library_add_rounded, size: 56, color: context.appTextMuted),
            const SizedBox(height: 16),
            Text('No standards uploaded yet',
              style: TextStyle(color: context.appText, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Upload your PDF copies of AS 1670.1, AS 1851 or any other Australian Standard. '
              'The AI will answer questions using the exact text from your standards.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.appTextSec, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Upload a Standard PDF'),
              onPressed: _uploading ? null : _pickAndIndex,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Standard card ─────────────────────────────────────────────────────────────

class _StandardCard extends StatelessWidget {
  final StandardMeta meta;
  final VoidCallback onDelete;

  const _StandardCard({required this.meta, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.accent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meta.name,
                  style: TextStyle(color: context.appText, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(
                  '${meta.pageCount} pages · ${meta.chunkCount} sections indexed',
                  style: TextStyle(color: context.appTextMuted, fontSize: 11),
                ),
                Text(
                  'Added ${_formatDate(meta.uploadedAt)}',
                  style: TextStyle(color: context.appTextMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
            onPressed: onDelete,
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day} ${_month(dt.month)} ${dt.year}';
  }

  String _month(int m) => ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];
}

// ── Model download banner ─────────────────────────────────────────────────────

class _ModelStatusBanner extends StatelessWidget {
  const _ModelStatusBanner();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GemmaService.instance,
      builder: (context, _) {
        final status = GemmaService.instance.status;
        switch (status) {
          case GemmaStatus.ready:
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.success.withValues(alpha: 0.08),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.success, size: 14),
                  SizedBox(width: 8),
                  Text('AI model ready — works offline', style: TextStyle(color: AppColors.success, fontSize: 12)),
                ],
              ),
            );

          case GemmaStatus.downloading:
            final progress = GemmaService.instance.downloadProgress;
            final knownSize = progress > 0;
            final label = knownSize
                ? 'Downloading AI model… ${(progress * 100).toStringAsFixed(0)}%'
                : 'Downloading AI model…';
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: AppColors.accent.withValues(alpha: 0.06),
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)),
                      const SizedBox(width: 8),
                      Text(label,
                        style: const TextStyle(color: AppColors.accent, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: knownSize ? progress : null,
                    backgroundColor: AppColors.accentSoft,
                    valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                    minHeight: 4,
                  ),
                ],
              ),
            );

          case GemmaStatus.error:
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: AppColors.danger.withValues(alpha: 0.08),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Download failed',
                          style: TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          GemmaService.instance.errorMessage ?? 'AI model error',
                          style: const TextStyle(color: AppColors.danger, fontSize: 11),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: GemmaService.instance.downloadModel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: const Text('Retry', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            );

          case GemmaStatus.notDownloaded:
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: context.appSurfaceAlt,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI model not downloaded',
                          style: TextStyle(color: context.appText, fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('~1.5 GB one-time download. Works offline once installed.',
                          style: TextStyle(color: context.appTextMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: GemmaService.instance.downloadModel,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                    child: const Text('Download', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            );
        }
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 2 — Chat
// ══════════════════════════════════════════════════════════════════════════════

class _ChatMessage {
  final bool isUser;
  final String text;
  final bool isStreaming;

  const _ChatMessage({required this.isUser, required this.text, this.isStreaming = false});

  _ChatMessage copyWith({String? text, bool? isStreaming}) => _ChatMessage(
    isUser: isUser,
    text: text ?? this.text,
    isStreaming: isStreaming ?? this.isStreaming,
  );
}

class _ChatTab extends StatefulWidget {
  const _ChatTab();

  @override
  State<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<_ChatTab> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isGenerating = false;

  // Suggested starter questions
  static const _suggestions = [
    'What is the minimum battery backup time for an unmonitored system?',
    'What dB level is required for a sounder in a sleeping area?',
    'How often must smoke detectors be tested under AS 1851?',
    'What is the maximum zone resistance for a conventional panel?',
    'What are the requirements for manual call point placement?',
  ];

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String question) async {
    if (question.trim().isEmpty || _isGenerating) return;

    final userMsg = _ChatMessage(isUser: true, text: question.trim());
    const aiMsg = _ChatMessage(isUser: false, text: '', isStreaming: true);

    setState(() {
      _messages.add(userMsg);
      _messages.add(aiMsg);
      _isGenerating = true;
    });
    _inputCtrl.clear();
    _scrollToBottom();

    final buffer = StringBuffer();
    await for (final token in GemmaService.instance.ask(question)) {
      buffer.write(token);
      setState(() {
        _messages[_messages.length - 1] = aiMsg.copyWith(text: buffer.toString());
      });
      _scrollToBottom();
    }

    setState(() {
      _messages[_messages.length - 1] =
          aiMsg.copyWith(text: buffer.toString(), isStreaming: false);
      _isGenerating = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _ModelStatusBanner(),
        Expanded(
          child: _messages.isEmpty
            ? _buildWelcome(context)
            : ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (ctx, i) => _MessageBubble(message: _messages[i]),
              ),
        ),
        _buildInputBar(context),
      ],
    );
  }

  Widget _buildWelcome(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.auto_awesome_rounded, color: AppColors.accent, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Standards AI', style: TextStyle(color: context.appText, fontSize: 17, fontWeight: FontWeight.w800)),
                  Text('Powered by Gemma — runs 100% on-device', style: TextStyle(color: context.appTextMuted, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const InfoBox(
            text: 'Ask any question about your uploaded Australian Standards. '
                  'Answers are drawn directly from the text you uploaded — '
                  'no internet connection required.',
          ),
          const SizedBox(height: 20),
          Text('SUGGESTED QUESTIONS',
            style: TextStyle(color: context.appTextMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.4)),
          const SizedBox(height: 10),
          ..._suggestions.map((q) => GestureDetector(
            onTap: () => _send(q),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.appBorder),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(q, style: TextStyle(color: context.appText, fontSize: 13))),
                  Icon(Icons.arrow_forward_ios_rounded, size: 12, color: context.appTextMuted),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      decoration: BoxDecoration(
        color: context.appSurface,
        border: Border(top: BorderSide(color: context.appBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              style: TextStyle(color: context.appText),
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: _isGenerating ? null : _send,
              decoration: InputDecoration(
                hintText: 'Ask a fire standards question…',
                hintStyle: TextStyle(color: context.appTextMuted),
                filled: true,
                fillColor: context.appSurfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Material(
              color: _isGenerating ? context.appSurfaceAlt : AppColors.accent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _isGenerating ? null : () => _send(_inputCtrl.text),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _isGenerating
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32, height: 32,
              margin: const EdgeInsets.only(right: 8, top: 2),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: AppColors.accent, size: 16),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.accent : context.appSurface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser ? null : Border.all(color: context.appBorder),
              ),
              child: message.text.isEmpty && message.isStreaming
                ? _TypingIndicator()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          color: isUser ? Colors.white : context.appText,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      if (message.isStreaming && message.text.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 10, height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: context.appTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.2;
            final opacity = ((_ctrl.value - delay) % 1.0).clamp(0.0, 0.6);
            return Container(
              width: 7, height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: context.appTextMuted.withValues(alpha: 0.3 + opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
