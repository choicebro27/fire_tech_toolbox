// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideUp,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 36),
                  _buildToolCards(context),
                  const SizedBox(height: 36),
                  _buildFooter(context),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.25),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_fire_department_rounded,
                color: AppColors.accent,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FIRE TECH',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3.5,
                    fontFamily: 'monospace',
                    height: 1.1,
                  ),
                ),
                Text(
                  'TOOLBOX',
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3.5,
                    fontFamily: 'monospace',
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 28),
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accent.withValues(alpha: 0.9),
                AppColors.accent.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Field reference tools for\nfire protection technicians.',
          style: TextStyle(
            color: context.appText,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'AS 1670.1 · AS 1851 compliant calculations.\nBuilt for the field',
          style: TextStyle(
            color: context.appTextSec,
            fontSize: 14,
            height: 1.65,
          ),
        ),
      ],
    );
  }

  // ── Tool cards ────────────────────────────────────────────────────────────

  Widget _buildToolCards(BuildContext context) {
    const tools = [
      _ToolInfo(
        icon: Icons.battery_charging_full_rounded,
        label: 'Battery Size\nCalculator',
        description:
            'Calculate minimum backup battery capacity per AS 1670/AS 1851',
        tag: 'AS 1670.1 · AS 1851',
        accentColor: AppColors.accent,
      ),
      _ToolInfo(
        icon: Icons.cable_rounded,
        label: 'Resistor\nColour Code',
        description:
            'Identify EOL resistor values with a live visual reference. '
            'Supports 4-band and 5-band IEC 60062 resistors.',
        tag: 'EOL Zones · PRO',
        accentColor: Color(0xFF3B82F6),
      ),
      _ToolInfo(
        icon: Icons.graphic_eq_rounded,
        label: 'Decibel\nMeter',
        description: 'Real-time microphone sound level measurement'
            'Max, average and calibration offset.',
        tag: 'DB Meter · PRO',
        accentColor: Color(0xFF10B981),
      ),
      _ToolInfo(
        icon: Icons.auto_awesome_rounded,
        label: 'Standards\nAI Chat',
        description: 'Ask questions and get clause-cited answers from your own '
            'standards PDFs. Runs fully on-device — no internet required.',
        tag: 'Standards AI Chat · PRO',
        accentColor: Color(0xFF8B5CF6),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TOOLS',
          style: TextStyle(
            color: context.appTextMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        ...tools.map((tool) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ToolCard(tool: tool),
            )),
      ],
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.accent, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Field reference tool only. Always verify results against manufacturer '
              'datasheets and current Australian Standards. Not a substitute for '
              'formal compliance certification.',
              style: TextStyle(
                color: context.appTextSec,
                fontSize: 11,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _ToolInfo {
  final IconData icon;
  final String label;
  final String description;
  final String tag;
  final Color accentColor;

  const _ToolInfo({
    required this.icon,
    required this.label,
    required this.description,
    required this.tag,
    required this.accentColor,
  });
}

// ── Tool card ─────────────────────────────────────────────────────────────────

class _ToolCard extends StatelessWidget {
  final _ToolInfo tool;

  const _ToolCard({required this.tool});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: tool.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tool.accentColor.withValues(alpha: 0.3)),
            ),
            child: Icon(tool.icon, color: tool.accentColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tool.label,
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  tool.description,
                  style: TextStyle(
                    color: context.appTextSec,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 9),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: tool.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: tool.accentColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    tool.tag,
                    style: TextStyle(
                      color: tool.accentColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
