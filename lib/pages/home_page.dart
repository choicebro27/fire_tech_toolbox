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
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 20),
                  _buildToolCards(context),
                  const Spacer(),
                  _buildFooter(context),
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
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.22),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_fire_department_rounded,
                color: AppColors.accent,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FIRE TECH',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3.2,
                    fontFamily: 'monospace',
                    height: 1.1,
                  ),
                ),
                Builder(
                    builder: (ctx) => Text(
                          'TOOLBOX',
                          style: TextStyle(
                            color: ctx.appText,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3.2,
                            fontFamily: 'monospace',
                            height: 1.1,
                          ),
                        )),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accent.withValues(alpha: 0.85),
                AppColors.accent.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Builder(
            builder: (ctx) => Text(
                  'Field reference tools for fire protection technicians.',
                  style: TextStyle(
                    color: ctx.appText,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                )),
        const SizedBox(height: 6),
        Builder(
            builder: (ctx) => Text(
                  'AS 1670 · AS 1851',
                  style: TextStyle(
                    color: ctx.appTextSec,
                    fontSize: 13,
                    height: 1.5,
                  ),
                )),
      ],
    );
  }

  // ── Tool cards ────────────────────────────────────────────────────────────

  Widget _buildToolCards(BuildContext context) {
    const tools = [
      _ToolInfo(
        icon: Icons.battery_charging_full_rounded,
        label: 'Battery Size Calculator',
        tag: 'AS 1670 · AS 1851',
        accentColor: AppColors.accent,
      ),
      _ToolInfo(
        icon: Icons.cable_rounded,
        label: 'Resistor Colour Code',
        tag: 'PRO',
        accentColor: Color(0xFF3B82F6),
      ),
      _ToolInfo(
        icon: Icons.graphic_eq_rounded,
        label: 'Decibel Meter',
        tag: 'PRO',
        accentColor: Color(0xFF10B981),
      ),
      _ToolInfo(
        icon: Icons.auto_awesome_rounded,
        label: 'Standards AI Chat',
        tag: 'PRO',
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
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        ...tools.map((tool) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ToolCard(tool: tool),
            )),
      ],
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.accent, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Field reference only. Always verify against manufacturer datasheets '
              'and current Australian Standards.',
              style: TextStyle(
                color: context.appTextSec,
                fontSize: 10.5,
                height: 1.5,
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
  final String tag;
  final Color accentColor;

  const _ToolInfo({
    required this.icon,
    required this.label,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tool.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: tool.accentColor.withValues(alpha: 0.28)),
            ),
            child: Icon(tool.icon, color: tool.accentColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              tool.label,
              style: TextStyle(
                color: context.appText,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: tool.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border:
                  Border.all(color: tool.accentColor.withValues(alpha: 0.28)),
            ),
            child: Text(
              tool.tag,
              style: TextStyle(
                color: tool.accentColor,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
