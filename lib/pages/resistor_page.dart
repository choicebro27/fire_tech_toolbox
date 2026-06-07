// lib/pages/resistor_page.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/widgets.dart';

// ─── Data ────────────────────────────────────────────────────────────────────

class ResistorBand {
  final String name;
  final Color color;
  final int? digit;
  final double? multiplier;
  final String? tolerance;

  const ResistorBand({required this.name, required this.color, this.digit, this.multiplier, this.tolerance});
}

const List<ResistorBand> kDigitBands = [
  ResistorBand(name: 'Black',  color: Color(0xFF1A1A1A), digit: 0),
  ResistorBand(name: 'Brown',  color: Color(0xFF795548), digit: 1),
  ResistorBand(name: 'Red',    color: Color(0xFFE53935), digit: 2),
  ResistorBand(name: 'Orange', color: Color(0xFFFF6F00), digit: 3),
  ResistorBand(name: 'Yellow', color: Color(0xFFFFD600), digit: 4),
  ResistorBand(name: 'Green',  color: Color(0xFF43A047), digit: 5),
  ResistorBand(name: 'Blue',   color: Color(0xFF1E88E5), digit: 6),
  ResistorBand(name: 'Violet', color: Color(0xFF8E24AA), digit: 7),
  ResistorBand(name: 'Grey',   color: Color(0xFF757575), digit: 8),
  ResistorBand(name: 'White',  color: Color(0xFFEEEEEE), digit: 9),
];

const List<ResistorBand> kMultiplierBands = [
  ResistorBand(name: 'Black',  color: Color(0xFF1A1A1A), multiplier: 1),
  ResistorBand(name: 'Brown',  color: Color(0xFF795548), multiplier: 10),
  ResistorBand(name: 'Red',    color: Color(0xFFE53935), multiplier: 100),
  ResistorBand(name: 'Orange', color: Color(0xFFFF6F00), multiplier: 1000),
  ResistorBand(name: 'Yellow', color: Color(0xFFFFD600), multiplier: 10000),
  ResistorBand(name: 'Green',  color: Color(0xFF43A047), multiplier: 100000),
  ResistorBand(name: 'Blue',   color: Color(0xFF1E88E5), multiplier: 1000000),
  ResistorBand(name: 'Violet', color: Color(0xFF8E24AA), multiplier: 10000000),
  ResistorBand(name: 'Grey',   color: Color(0xFF757575), multiplier: 0.01),
  ResistorBand(name: 'White',  color: Color(0xFFEEEEEE), multiplier: 0.1),
  ResistorBand(name: 'Gold',   color: Color(0xFFFFD700), multiplier: 0.1),
  ResistorBand(name: 'Silver', color: Color(0xFFC0C0C0), multiplier: 0.01),
];

const List<ResistorBand> kToleranceBands = [
  ResistorBand(name: 'Brown',  color: Color(0xFF795548), tolerance: '±1%'),
  ResistorBand(name: 'Red',    color: Color(0xFFE53935), tolerance: '±2%'),
  ResistorBand(name: 'Green',  color: Color(0xFF43A047), tolerance: '±0.5%'),
  ResistorBand(name: 'Blue',   color: Color(0xFF1E88E5), tolerance: '±0.25%'),
  ResistorBand(name: 'Violet', color: Color(0xFF8E24AA), tolerance: '±0.1%'),
  ResistorBand(name: 'Grey',   color: Color(0xFF757575), tolerance: '±0.05%'),
  ResistorBand(name: 'Gold',   color: Color(0xFFFFD700), tolerance: '±5%'),
  ResistorBand(name: 'Silver', color: Color(0xFFC0C0C0), tolerance: '±10%'),
];

String formatResistance(double ohms) {
  if (ohms >= 1e6) return '${_compact(ohms / 1e6)} MΩ';
  if (ohms >= 1e3) return '${_compact(ohms / 1e3)} kΩ';
  return '${_compact(ohms)} Ω';
}

String _compact(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toStringAsFixed(v < 10 ? 2 : 1).replaceAll(RegExp(r'\.?0+$'), '');
}

// ─── Page ────────────────────────────────────────────────────────────────────

class ResistorPage extends StatefulWidget {
  const ResistorPage({super.key});

  @override
  State<ResistorPage> createState() => _ResistorPageState();
}

class _ResistorPageState extends State<ResistorPage> {
  bool _fiveBand = false;
  int _b1 = 1; // Brown
  int _b2 = 0; // Black
  int _b3 = 0;
  int _mult = 2; // Red = ×100 → 1kΩ
  int _tol = 6;  // Gold ±5%

  double get _resistance {
    final m = kMultiplierBands[_mult].multiplier ?? 1;
    if (_fiveBand) {
      return ((kDigitBands[_b1].digit ?? 0) * 100 +
              (kDigitBands[_b2].digit ?? 0) * 10 +
              (kDigitBands[_b3].digit ?? 0)) * m;
    } else {
      return ((kDigitBands[_b1].digit ?? 0) * 10 +
              (kDigitBands[_b2].digit ?? 0)) * m;
    }
  }

  void _reset() {
    setState(() {
      _fiveBand = false;
      _b1 = 1;
      _b2 = 0;
      _b3 = 0;
      _mult = 2;
      _tol = 6;
    });
  }

  String get _tolerance => kToleranceBands[_tol].tolerance ?? '±5%';

  List<Color> get _bandColors {
    final b1c = kDigitBands[_b1].color;
    final b2c = kDigitBands[_b2].color;
    final b3c = kDigitBands[_b3].color;
    final mc  = kMultiplierBands[_mult].color;
    final tc  = kToleranceBands[_tol].color;
    return _fiveBand ? [b1c, b2c, b3c, mc, tc] : [b1c, b2c, mc, tc];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resistor Colour Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset',
            onPressed: _reset,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBandToggle(context),
            const SizedBox(height: 16),
            _ResistorGraphic(colors: _bandColors, fiveBand: _fiveBand),
            const SizedBox(height: 16),
            _buildResultDisplay(context),
            const SizedBox(height: 16),
            TechCard(
              title: 'BAND SELECTION',
              child: Column(
                children: [
                  _BandRow(context: context, label: _fiveBand ? 'Band 1 (100s digit)' : 'Band 1 (10s digit)', color: kDigitBands[_b1].color,
                    child: _buildDropdown(context, value: _b1, items: kDigitBands, onChanged: (i) => setState(() => _b1 = i))),
                  const SizedBox(height: 12),
                  _BandRow(context: context, label: _fiveBand ? 'Band 2 (10s digit)' : 'Band 2 (1s digit)', color: kDigitBands[_b2].color,
                    child: _buildDropdown(context, value: _b2, items: kDigitBands, onChanged: (i) => setState(() => _b2 = i))),
                  if (_fiveBand) ...[
                    const SizedBox(height: 12),
                    _BandRow(context: context, label: 'Band 3 (1s digit)', color: kDigitBands[_b3].color,
                      child: _buildDropdown(context, value: _b3, items: kDigitBands, onChanged: (i) => setState(() => _b3 = i))),
                  ],
                  const SizedBox(height: 12),
                  _BandRow(context: context, label: 'Multiplier', color: kMultiplierBands[_mult].color,
                    child: _buildDropdown(context, value: _mult, items: kMultiplierBands, onChanged: (i) => setState(() => _mult = i))),
                  const SizedBox(height: 12),
                  _BandRow(context: context, label: 'Tolerance', color: kToleranceBands[_tol].color,
                    child: _buildDropdown(context, value: _tol, items: kToleranceBands, onChanged: (i) => setState(() => _tol = i))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const InfoBox(
              icon: Icons.electrical_services_outlined,
              text: 'EOL (End-of-Line) resistors supervise fire alarm zone wiring. '
                    'Common values: 2.2kΩ, 3.3kΩ, 4.7kΩ, 5.6kΩ, 10kΩ. '
                    'Always verify with the panel\'s installation manual.',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBandToggle(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _BandToggleButton(
          label: '4-Band',
          selected: !_fiveBand,
          isLeft: true,
          onTap: () => setState(() => _fiveBand = false),
        )),
        Expanded(child: _BandToggleButton(
          label: '5-Band',
          selected: _fiveBand,
          isLeft: false,
          onTap: () => setState(() => _fiveBand = true),
        )),
      ],
    );
  }

  Widget _buildResultDisplay(BuildContext context) {
    final r = _resistance;
    final valid = r > 0 && r.isFinite;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.08), blurRadius: 20, spreadRadius: 2)],
      ),
      child: Column(
        children: [
          Text('RESISTANCE VALUE', style: TextStyle(color: context.appTextMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Text(valid ? formatResistance(r) : '—',
            style: TextStyle(color: context.appText, fontSize: 42, fontWeight: FontWeight.w900, fontFamily: 'monospace', height: 1)),
          const SizedBox(height: 6),
          Text(_tolerance, style: const TextStyle(color: AppColors.warning, fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
          if (valid) ...[
            const SizedBox(height: 6),
            Text('${r.toStringAsFixed(r < 1 ? 3 : 0)} Ω', style: TextStyle(color: context.appTextMuted, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _buildDropdown(BuildContext context, {
    required int value,
    required List<ResistorBand> items,
    required ValueChanged<int> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      dropdownColor: context.appSurfaceAlt,
      style: TextStyle(color: context.appText, fontSize: 14),
      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), isDense: true),
      items: items.asMap().entries.map((e) {
        final band = e.value;
        return DropdownMenuItem<int>(
          value: e.key,
          child: Row(
            children: [
              Container(
                width: 18, height: 18,
                decoration: BoxDecoration(color: band.color, borderRadius: BorderRadius.circular(3), border: Border.all(color: Colors.white24, width: 0.5)),
              ),
              const SizedBox(width: 10),
              Text(band.name, style: TextStyle(color: context.appText, fontSize: 14)),
              if (band.digit != null)
                Text('  (${band.digit})', style: TextStyle(color: context.appTextMuted, fontSize: 12)),
              if (band.multiplier != null)
                Text('  ×${_formatMult(band.multiplier!)}', style: TextStyle(color: context.appTextMuted, fontSize: 12)),
              if (band.tolerance != null)
                Text('  ${band.tolerance}', style: TextStyle(color: context.appTextMuted, fontSize: 12)),
            ],
          ),
        );
      }).toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    );
  }

  String _formatMult(double m) {
    if (m >= 1e6) return '${(m / 1e6).toStringAsFixed(0)}M';
    if (m >= 1e3) return '${(m / 1e3).toStringAsFixed(0)}k';
    if (m < 1) return m.toString();
    return m.toStringAsFixed(0);
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _BandToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isLeft;
  final VoidCallback onTap;

  const _BandToggleButton({required this.label, required this.selected, required this.isLeft, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : context.appSurfaceAlt,
          borderRadius: BorderRadius.horizontal(
            left: isLeft ? const Radius.circular(10) : Radius.zero,
            right: !isLeft ? const Radius.circular(10) : Radius.zero,
          ),
          border: Border.all(color: selected ? AppColors.accent : context.appBorder, width: selected ? 1.5 : 1),
        ),
        child: Center(
          child: Text(label, style: TextStyle(
            color: selected ? AppColors.accent : context.appTextSec,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          )),
        ),
      ),
    );
  }
}

class _BandRow extends StatelessWidget {
  final BuildContext context;
  final String label;
  final Color color;
  final Widget child;

  const _BandRow({required this.context, required this.label, required this.color, required this.child});

  @override
  Widget build(BuildContext ctx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 10, height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 0.5))),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: ctx.appTextSec, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _ResistorGraphic extends StatelessWidget {
  final List<Color> colors;
  final bool fiveBand;
  const _ResistorGraphic({required this.colors, required this.fiveBand});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 80,
        child: CustomPaint(
          size: const Size(320, 80),
          painter: _ResistorPainter(colors: colors),
        ),
      ),
    );
  }
}

class _ResistorPainter extends CustomPainter {
  final List<Color> colors;
  const _ResistorPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = h / 2;

    const bodyLeft  = 0.22;
    const bodyRight = 0.78;
    const bodyTop   = 0.18;
    const bodyBot   = 0.82;
    const radius    = 12.0;

    final bL = w * bodyLeft;
    final bR = w * bodyRight;
    final bT = h * bodyTop;
    final bB = h * bodyBot;

    final wirePaint = Paint()..color = const Color(0xFF888888)..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, cx), Offset(bL, cx), wirePaint);
    canvas.drawLine(Offset(bR, cx), Offset(w, cx), wirePaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(bL + 2, bT + 3, bR + 2, bB + 3), const Radius.circular(radius)),
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );

    final bodyRect = RRect.fromRectAndRadius(Rect.fromLTRB(bL, bT, bR, bB), const Radius.circular(radius));
    canvas.drawRRect(bodyRect, Paint()..color = const Color(0xFFD4A574));
    canvas.drawRRect(bodyRect,
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Colors.white.withValues(alpha: 0.25), Colors.transparent],
      ).createShader(Rect.fromLTRB(bL, bT, bR, cx)),
    );

    final bodyWidth = bR - bL;
    final startX = bL + bodyWidth * 0.08;
    const bandW = 14.0;
    const gap   = 2.0;

    canvas.save();
    canvas.clipRRect(bodyRect);

    for (int i = 0; i < colors.length - 1; i++) {
      _drawBand(canvas, startX + i * (bandW + gap), bT, bandW, bB - bT, colors[i]);
    }
    _drawBand(canvas, bR - bodyWidth * 0.08 - bandW, bT, bandW, bB - bT, colors.last);

    canvas.restore();

    canvas.drawRRect(bodyRect, Paint()..color = Colors.black.withValues(alpha: 0.35)..style = PaintingStyle.stroke..strokeWidth = 1);
  }

  void _drawBand(Canvas canvas, double x, double top, double width, double height, Color color) {
    canvas.drawRect(Rect.fromLTWH(x, top, width, height), Paint()..color = color);
    canvas.drawRect(Rect.fromLTWH(x, top, 1, height), Paint()..color = Colors.white.withValues(alpha: 0.15));
  }

  @override
  bool shouldRepaint(_ResistorPainter old) => old.colors != colors;
}
