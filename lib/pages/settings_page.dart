// lib/pages/settings_page.dart
import 'package:flutter/material.dart';
import '../services/entitlement_service.dart';
import '../services/purchase_service.dart';
import '../theme/app_theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionHeader(label: 'PRO'),
          const SizedBox(height: 10),
          const _ProStatusCard(),
          const SizedBox(height: 28),

          const _SectionHeader(label: 'APPEARANCE'),
          const SizedBox(height: 10),
          _ThemeModeCard(notifier: AppThemeScope.of(context)),
          const SizedBox(height: 28),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Pro status card ───────────────────────────────────────────────────────────

class _ProStatusCard extends StatefulWidget {
  const _ProStatusCard();

  @override
  State<_ProStatusCard> createState() => _ProStatusCardState();
}

class _ProStatusCardState extends State<_ProStatusCard> {
  bool _restoring = false;

  Future<void> _restore() async {
    setState(() => _restoring = true);
    await PurchaseService.instance.restorePurchases();
    if (mounted) setState(() => _restoring = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: EntitlementService.instance,
      builder: (context, _) {
        final isPro = EntitlementService.instance.isPro;
        return _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(isPro ? Icons.verified_rounded : Icons.lock_rounded,
                      color: isPro ? AppColors.success : AppColors.accent, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    isPro ? 'Fire Tech Toolbox Pro' : 'Free Version',
                    style: TextStyle(
                      color: context.appText,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isPro ? AppColors.success : AppColors.accent).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (isPro ? AppColors.success : AppColors.accent).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      isPro ? 'UNLOCKED' : 'LOCKED',
                      style: TextStyle(
                        color: isPro ? AppColors.success : AppColors.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                isPro
                  ? 'You have full access to all tools including the Resistor Colour Code calculator and Decibel Meter.'
                  : 'Unlock the Resistor Colour Code calculator and Decibel Meter with a one-time purchase.',
                style: TextStyle(color: context.appTextSec, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 16),
              if (!isPro) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.lock_open_rounded, size: 18),
                    label: Text('Unlock Pro — ${PurchaseService.instance.priceString}'),
                    onPressed: () => PurchaseService.instance.buyPro(),
                  ),
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<String?>(
                  valueListenable: PurchaseService.instance.errorNotifier,
                  builder: (context, error, _) {
                    if (error == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        error,
                        style: const TextStyle(color: AppColors.danger, fontSize: 12),
                      ),
                    );
                  },
                ),
              ],
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _restoring ? null : _restore,
                  child: _restoring
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                      )
                    : Text(
                        'Restore Purchase',
                        style: TextStyle(
                          color: context.appTextSec,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                          decorationColor: context.appTextSec,
                        ),
                      ),
                ),
              ),

              // ── Debug only: remove before shipping ───────────────────────
              Divider(height: 20, color: context.appBorder),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => EntitlementService.instance.unlock(),
                    child: const Text('DEBUG: Grant Pro', style: TextStyle(color: AppColors.success, fontSize: 12)),
                  ),
                  TextButton(
                    onPressed: () => EntitlementService.instance.debugRevoke(),
                    child: const Text('DEBUG: Revoke Pro', style: TextStyle(color: AppColors.danger, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Theme mode card ───────────────────────────────────────────────────────────

class _ThemeModeCard extends StatelessWidget {
  final ThemeModeNotifier notifier;
  const _ThemeModeCard({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.palette_outlined, color: AppColors.accent, size: 18),
              const SizedBox(width: 10),
              Text('Theme Mode', style: TextStyle(color: context.appText, fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          _ThemeSegmentedControl(notifier: notifier),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: notifier,
            builder: (_, __) => Text(
              _modeDescription(notifier.mode),
              style: TextStyle(color: context.appTextMuted, fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  String _modeDescription(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'Dark mode always on — ideal for server rooms and low-light environments.';
      case ThemeMode.light:
        return 'Light mode always on — suitable for bright outdoor environments.';
      case ThemeMode.system:
        return 'Follows your device system appearance setting.';
    }
  }
}

class _ThemeSegmentedControl extends StatelessWidget {
  final ThemeModeNotifier notifier;
  const _ThemeSegmentedControl({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: notifier,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: context.appSurfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.appBorder),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _Segment(icon: Icons.dark_mode_rounded,       label: 'Dark',  selected: notifier.mode == ThemeMode.dark,   onTap: () => notifier.setMode(ThemeMode.dark)),
              _Segment(icon: Icons.light_mode_rounded,      label: 'Light', selected: notifier.mode == ThemeMode.light,  onTap: () => notifier.setMode(ThemeMode.light)),
              _Segment(icon: Icons.brightness_auto_rounded, label: 'Auto',  selected: notifier.mode == ThemeMode.system, onTap: () => notifier.setMode(ThemeMode.system)),
            ],
          ),
        );
      },
    );
  }
}

class _Segment extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Segment({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected
              ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: selected ? Colors.white : context.appTextMuted),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(
                color: selected ? Colors.white : context.appTextMuted,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared card container ─────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder),
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 12, color: AppColors.accent, margin: const EdgeInsets.only(right: 8)),
        Text(label, style: TextStyle(color: context.appTextMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.4)),
      ],
    );
  }
}
