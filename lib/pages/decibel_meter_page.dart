// lib/pages/decibel_meter_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../theme/widgets.dart';

const double kMinDb = 30.0;
const double kMaxDb = 120.0;
const double kAlarmMinDb    = 65.0;
const double kAmbientPlusDb = 75.0;

class DecibelMeterPage extends StatefulWidget {
  const DecibelMeterPage({super.key});

  @override
  State<DecibelMeterPage> createState() => _DecibelMeterPageState();
}

class _DecibelMeterPageState extends State<DecibelMeterPage>
    with SingleTickerProviderStateMixin {

  StreamSubscription<NoiseReading>? _sub;
  final NoiseMeter _noiseMeter = NoiseMeter();

  bool _isListening = false;
  bool _permissionDenied = false;

  double _currentDb = 0.0;
  double _maxDb = 0.0;
  double _avgDb = 0.0;
  int _sampleCount = 0;
  double _totalDb = 0.0;
  double _calibrationOffset = 0.0;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<bool> _requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> _startListening() async {
    final granted = await _requestPermission();
    if (!granted) { setState(() => _permissionDenied = true); return; }
    setState(() { _permissionDenied = false; _isListening = true; });
    _sub = _noiseMeter.noise.listen(
      (reading) {
        final raw = reading.meanDecibel;
        if (raw.isNaN || raw.isInfinite) return;
        final db = (raw + _calibrationOffset).clamp(kMinDb, kMaxDb);
        setState(() {
          _currentDb = db;
          if (db > _maxDb) _maxDb = db;
          _sampleCount++;
          _totalDb += db;
          _avgDb = _totalDb / _sampleCount;
        });
      },
      onError: (_) => _stopListening(),
    );
  }

  void _stopListening() {
    _sub?.cancel();
    _sub = null;
    setState(() => _isListening = false);
  }

  void _reset() {
    setState(() { _currentDb = 0; _maxDb = 0; _avgDb = 0; _sampleCount = 0; _totalDb = 0; });
  }

  Color _levelColor(double db) {
    if (db < 60) return AppColors.success;
    if (db < 80) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('dB Sounder Meter'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), tooltip: 'Reset stats', onPressed: _reset),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_permissionDenied) _buildPermissionDenied(context),
            _buildMainDisplay(context),
            const SizedBox(height: 16),
            _buildGauge(context),
            const SizedBox(height: 16),
            _buildStatsRow(context),
            const SizedBox(height: 16),
            _buildControlButton(),
            const SizedBox(height: 16),
            _buildCalibrationSlider(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDenied(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.mic_off_rounded, color: AppColors.danger, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Microphone access is required to measure sound levels. '
              'Please grant permission in your device Settings.',
              style: TextStyle(color: AppColors.danger, fontSize: 12, height: 1.5),
            ),
          ),
          TextButton(
            onPressed: openAppSettings,
            child: Text('Settings', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  Widget _buildMainDisplay(BuildContext context) {
    final db = _currentDb;
    final color = _isListening ? _levelColor(db) : context.appTextMuted;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final glow = _isListening ? _pulse.value * 0.15 : 0.0;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isListening ? color.withValues(alpha: 0.5) : context.appBorder,
              width: 1.5,
            ),
            boxShadow: _isListening
              ? [BoxShadow(color: color.withValues(alpha: glow), blurRadius: 30, spreadRadius: 5)]
              : [],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _isListening ? db.toStringAsFixed(1) : '--.-',
                    style: TextStyle(color: color, fontSize: 72, fontWeight: FontWeight.w900, fontFamily: 'monospace', height: 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10, left: 6),
                    child: Text('dB', style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 24, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _isListening ? _levelLabel(db) : 'TAP START TO MEASURE',
                style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5),
              ),
            ],
          ),
        );
      },
    );
  }

  String _levelLabel(double db) {
    if (db < 50) return 'QUIET';
    if (db < 65) return 'MODERATE';
    if (db < 75) return 'ALARM LEVEL MET';
    if (db < 90) return 'LOUD — SLEEPING AREAS MET';
    if (db < 100) return 'VERY LOUD';
    return '⚠ POTENTIALLY HARMFUL';
  }

  Widget _buildGauge(BuildContext context) {
    final db = _isListening ? _currentDb : kMinDb;
    final pct = ((db - kMinDb) / (kMaxDb - kMinDb)).clamp(0.0, 1.0);
    final color = _levelColor(db);

    return TechCard(
      title: 'LEVEL GAUGE  ($kMinDb – ${kMaxDb.toInt()} dB)',
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(height: 28, decoration: BoxDecoration(color: context.appSurfaceAlt, borderRadius: BorderRadius.circular(6))),
                Container(height: 28, decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0x332ECC71), Color(0x33F39C12), Color(0x33E74C3C)]),
                )),
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 120),
                  widthFactor: pct,
                  child: Container(height: 28, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${kMinDb.toInt()} dB', style: TextStyle(color: context.appTextMuted, fontSize: 10)),
              const _GaugeLabel(label: '65 dB\nMin',   color: AppColors.success),
              const _GaugeLabel(label: '75 dB\nSleep', color: AppColors.warning),
              Text('${kMaxDb.toInt()} dB', style: TextStyle(color: context.appTextMuted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatTile(context: context, label: 'MAX',     value: _maxDb > 0 ? '${_maxDb.toStringAsFixed(1)} dB' : '--', color: AppColors.danger)),
        const SizedBox(width: 12),
        Expanded(child: _StatTile(context: context, label: 'AVERAGE', value: _avgDb > 0 ? '${_avgDb.toStringAsFixed(1)} dB' : '--', color: AppColors.warning)),
        const SizedBox(width: 12),
        Expanded(child: _StatTile(context: context, label: 'SAMPLES', value: '$_sampleCount', color: AppColors.accent)),
      ],
    );
  }

  Widget _buildControlButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(_isListening ? Icons.stop_rounded : Icons.mic_rounded, size: 22),
        label: Text(_isListening ? 'STOP MEASURING' : 'START MEASURING'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isListening ? AppColors.danger : AppColors.accent,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: _isListening ? _stopListening : _startListening,
      ),
    );
  }

  Widget _buildCalibrationSlider(BuildContext context) {
    return TechCard(
      title: 'CALIBRATION OFFSET',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Offset', style: TextStyle(color: context.appTextSec, fontSize: 13)),
              Text(
                '${_calibrationOffset >= 0 ? '+' : ''}${_calibrationOffset.toStringAsFixed(1)} dB',
                style: TextStyle(color: context.appText, fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
              ),
            ],
          ),
          Slider(
            value: _calibrationOffset,
            min: -10, max: 10, divisions: 40,
            activeColor: AppColors.accent,
            inactiveColor: context.appBorder,
            label: '${_calibrationOffset.toStringAsFixed(1)} dB',
            onChanged: (v) => setState(() => _calibrationOffset = v),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('-10 dB', style: TextStyle(color: context.appTextMuted, fontSize: 11)),
              Text('Adjust against a calibrated SLM', style: TextStyle(color: context.appTextMuted, fontSize: 10)),
              Text('+10 dB', style: TextStyle(color: context.appTextMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final BuildContext context;
  final String label;
  final String value;
  final Color color;
  const _StatTile({required this.context, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: ctx.appSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ctx.appBorder),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: ctx.appTextMuted, fontSize: 10, letterSpacing: 1)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}

class _GaugeLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _GaugeLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(label, textAlign: TextAlign.center,
      style: TextStyle(color: color, fontSize: 9, height: 1.3, fontWeight: FontWeight.w700));
  }
}
