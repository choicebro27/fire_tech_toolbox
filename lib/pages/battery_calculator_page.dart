// lib/pages/battery_calculator_page.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/widgets.dart';

// ─── Constants ──────────────────────────────────────────────────────────────

enum StandbyMode { monitored, unmonitored }

const List<double> kStandardBatterySizes = [
  1.2, 2.3, 3.2, 7.0, 9.0, 12.0, 17.0, 18.0,
  24.0, 26.0, 33.0, 38.0, 40.0, 55.0, 65.0, 75.0, 100.0,
];

const double kDeratingFactor = 1.25;
const double kFc = 2.0;
const double kDefaultAlarmTimeMinutes = 30.0;

// ─── Model ──────────────────────────────────────────────────────────────────

class BatteryCalcResult {
  final double standbyComponent;
  final double alarmComponent;
  final double baseCapacity;
  final double requiredCapacity;
  final double? recommendedSize;

  const BatteryCalcResult({
    required this.standbyComponent,
    required this.alarmComponent,
    required this.baseCapacity,
    required this.requiredCapacity,
    this.recommendedSize,
  });
}

BatteryCalcResult calculate({
  required double standbyHours,
  required double standbyCurrentA,
  required double alarmCurrentA,
  required double alarmTimeHours,
}) {
  final standbyComponent = standbyCurrentA * standbyHours;
  final alarmComponent   = kFc * (alarmCurrentA * alarmTimeHours);
  final base             = standbyComponent + alarmComponent;
  final required         = kDeratingFactor * base;

  double? recommended;
  for (final size in kStandardBatterySizes) {
    if (size >= required) { recommended = size; break; }
  }

  return BatteryCalcResult(
    standbyComponent: standbyComponent,
    alarmComponent: alarmComponent,
    baseCapacity: base,
    requiredCapacity: required,
    recommendedSize: recommended,
  );
}

// ─── Page ───────────────────────────────────────────────────────────────────

class BatteryCalculatorPage extends StatefulWidget {
  const BatteryCalculatorPage({super.key});

  @override
  State<BatteryCalculatorPage> createState() => _BatteryCalculatorPageState();
}

class _BatteryCalculatorPageState extends State<BatteryCalculatorPage> {
  final _formKey = GlobalKey<FormState>();
  StandbyMode _standbyMode = StandbyMode.monitored;
  final _standbyCurrentCtrl = TextEditingController();
  final _alarmCurrentCtrl = TextEditingController();
  final _alarmTimeCtrl = TextEditingController(text: '30');
  BatteryCalcResult? _result;

  @override
  void dispose() {
    _standbyCurrentCtrl.dispose();
    _alarmCurrentCtrl.dispose();
    _alarmTimeCtrl.dispose();
    super.dispose();
  }

  double get _standbyHours => _standbyMode == StandbyMode.monitored ? 24.0 : 72.0;

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final standbyA = double.tryParse(_standbyCurrentCtrl.text) ?? 0.0;
    final alarmA   = double.tryParse(_alarmCurrentCtrl.text) ?? 0.0;
    final alarmHrs = (double.tryParse(_alarmTimeCtrl.text) ?? kDefaultAlarmTimeMinutes) / 60.0;
    setState(() {
      _result = calculate(
        standbyHours: _standbyHours,
        standbyCurrentA: standbyA,
        alarmCurrentA: alarmA,
        alarmTimeHours: alarmHrs,
      );
    });
  }

  void _reset() {
    _formKey.currentState?.reset();
    _standbyCurrentCtrl.clear();
    _alarmCurrentCtrl.clear();
    _alarmTimeCtrl.text = '30';
    setState(() {
      _standbyMode = StandbyMode.monitored;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Battery Size Calculator'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), tooltip: 'Reset', onPressed: _reset),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStandbyModeSelector(context),
              const SizedBox(height: 12),
              _buildCurrentInput(context,
                label: 'Quiescent / Standby Current (Iq)',
                controller: _standbyCurrentCtrl,
              ),
              const SizedBox(height: 12),
              _buildCurrentInput(context,
                label: 'Alarm Current (Ia)',
                controller: _alarmCurrentCtrl,
              ),
              const SizedBox(height: 12),
              _buildAlarmTimeField(context),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.calculate_rounded, size: 20),
                  label: const Text('CALCULATE BATTERY SIZE'),
                  onPressed: _calculate,
                ),
              ),
              if (_result != null) ...[
                const SizedBox(height: 20),
                _buildResultCard(context, _result!),
              ],
              const SizedBox(height: 20),
              const InfoBox(
                icon: Icons.shield_outlined,
                text: 'AS 1670.1: C20 = 1.25 × ((Iq × Tq) + Fc(Ia × Ta)) where Fc = 2. '
                      '24-hour backup for monitored systems, 72-hour for unmonitored. '
                      'Default alarm duration is 30 minutes.',
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStandbyModeSelector(BuildContext context) {
    return TechCard(
      title: 'STANDBY RUNTIME (Tq)',
      child: Column(
        children: [
          _ModeButton(
            context: context,
            label: '24 Hours — Monitored System',
            sublabel: 'Externally monitored (AS 1670.1 Cl. 4)',
            selected: _standbyMode == StandbyMode.monitored,
            onTap: () => setState(() => _standbyMode = StandbyMode.monitored),
          ),
          const SizedBox(height: 8),
          _ModeButton(
            context: context,
            label: '72 Hours — Unmonitored System',
            sublabel: 'No external monitoring (AS 1670.1 Cl. 4)',
            selected: _standbyMode == StandbyMode.unmonitored,
            onTap: () => setState(() => _standbyMode = StandbyMode.unmonitored),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentInput(BuildContext context, {
    required String label,
    required TextEditingController controller,
  }) {
    return TechCard(
      title: label.toUpperCase(),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(color: context.appText),
        decoration: const InputDecoration(
          hintText: 'e.g. 0.085',
          labelText: 'Amps (A)',
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Required';
          final n = double.tryParse(v);
          if (n == null) return 'Invalid number';
          if (n < 0) return 'Must be ≥ 0';
          return null;
        },
      ),
    );
  }

  Widget _buildAlarmTimeField(BuildContext context) {
    return TechCard(
      title: 'ALARM TIME (Ta)',
      child: TextFormField(
        controller: _alarmTimeCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(color: context.appText),
        decoration: InputDecoration(
          labelText: 'Alarm Duration',
          suffixText: 'minutes',
          suffixStyle: TextStyle(color: context.appTextSec),
          helperText: 'Default: 30 min per AS 1670.1',
          helperStyle: TextStyle(color: context.appTextMuted, fontSize: 11),
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Required';
          final n = double.tryParse(v);
          if (n == null) return 'Invalid number';
          if (n <= 0) return 'Must be > 0';
          return null;
        },
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, BatteryCalcResult result) {
    final oversize = result.recommendedSize == null;
    final resultColor = oversize ? AppColors.danger : AppColors.success;
    return TechCard(
      title: 'CALCULATION RESULT',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResultRow(label: 'C20  (×1.25 derating)', value: '${result.requiredCapacity.toStringAsFixed(3)} Ah', valueColor: AppColors.warning),
          Divider(height: 24, color: context.appBorder),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: resultColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: resultColor.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                Text(
                  oversize ? 'EXCEEDS STANDARD SIZES' : 'RECOMMENDED BATTERY',
                  style: TextStyle(color: resultColor, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                ),
                const SizedBox(height: 6),
                Text(
                  oversize ? '> 100 Ah\nConsult manufacturer'
                    : '${result.recommendedSize!.toStringAsFixed(result.recommendedSize! < 10 ? 1 : 0)} Ah',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: resultColor,
                    fontSize: oversize ? 22 : 42,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                    height: 1.1,
                  ),
                ),
                if (!oversize) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Next standard size ≥ ${result.requiredCapacity.toStringAsFixed(3)} Ah',
                    style: TextStyle(color: context.appTextMuted, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _ModeButton extends StatelessWidget {
  final BuildContext context;
  final String label;
  final String sublabel;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.context,
    required this.label,
    required this.sublabel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext ctx) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : ctx.appSurfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.accent : ctx.appBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: selected ? AppColors.accent : ctx.appTextMuted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(
                    color: selected ? ctx.appText : ctx.appTextSec,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  )),
                  const SizedBox(height: 2),
                  Text(sublabel, style: TextStyle(color: ctx.appTextMuted, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
