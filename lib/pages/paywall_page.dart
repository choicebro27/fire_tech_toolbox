// lib/pages/paywall_page.dart
//
// Renders the actual page content blurred behind a purchase sheet.
// Wrap any locked page with: PaywallOverlay(child: YourPage())

import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/entitlement_service.dart';
import '../services/purchase_service.dart';
import '../theme/app_theme.dart';

class PaywallOverlay extends StatefulWidget {
  /// The actual page content — rendered blurred behind the paywall.
  final Widget child;

  /// Feature name shown in the paywall headline, e.g. "Resistor Calculator"
  final String featureName;

  /// Bullet points shown on the paywall sheet
  final List<String> features;

  const PaywallOverlay({
    super.key,
    required this.child,
    required this.featureName,
    required this.features,
  });

  @override
  State<PaywallOverlay> createState() => _PaywallOverlayState();
}

class _PaywallOverlayState extends State<PaywallOverlay>
    with SingleTickerProviderStateMixin {

  late AnimationController _sheetCtrl;
  late Animation<Offset> _sheetAnim;

  bool _isPurchasing = false;
  bool _isRestoring  = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _sheetCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _sheetAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _sheetCtrl, curve: Curves.easeOutCubic));
    _sheetCtrl.forward();

    // Listen to purchase service errors
    PurchaseService.instance.errorNotifier.addListener(_onPurchaseError);
    PurchaseService.instance.loadingNotifier.addListener(_onPurchaseLoading);
  }

  @override
  void dispose() {
    PurchaseService.instance.errorNotifier.removeListener(_onPurchaseError);
    PurchaseService.instance.loadingNotifier.removeListener(_onPurchaseLoading);
    _sheetCtrl.dispose();
    super.dispose();
  }

  void _onPurchaseError() {
    if (!mounted) return;
    setState(() => _errorMsg = PurchaseService.instance.errorNotifier.value);
  }

  void _onPurchaseLoading() {
    if (!mounted) return;
    setState(() => _isPurchasing = PurchaseService.instance.loadingNotifier.value);
  }

  Future<void> _handlePurchase() async {
    setState(() { _errorMsg = null; _isPurchasing = true; });
    await PurchaseService.instance.buyPro();
    if (mounted) setState(() => _isPurchasing = false);
  }

  Future<void> _handleRestore() async {
    setState(() { _errorMsg = null; _isRestoring = true; });
    await PurchaseService.instance.restorePurchases();
    if (mounted) setState(() => _isRestoring = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: EntitlementService.instance,
      builder: (context, _) {
        // If user has Pro — just show the page normally
        if (EntitlementService.instance.isPro) {
          return widget.child;
        }

        // Otherwise: blurred content + paywall sheet on top
        return Stack(
          children: [
            // ── Blurred background (the actual page) ───────────────────────
            IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: widget.child,
              ),
            ),

            // ── Dark scrim ─────────────────────────────────────────────────
            Container(color: Colors.black.withValues(alpha: 0.55)),

            // ── Paywall sheet ──────────────────────────────────────────────
            Align(
              alignment: Alignment.center,
              child: SlideTransition(
                position: _sheetAnim,
                child: _PaywallSheet(
                  featureName: widget.featureName,
                  features: widget.features,
                  isPurchasing: _isPurchasing,
                  isRestoring: _isRestoring,
                  errorMsg: _errorMsg,
                  onPurchase: _handlePurchase,
                  onRestore: _handleRestore,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Paywall sheet ─────────────────────────────────────────────────────────────

class _PaywallSheet extends StatelessWidget {
  final String featureName;
  final List<String> features;
  final bool isPurchasing;
  final bool isRestoring;
  final String? errorMsg;
  final VoidCallback onPurchase;
  final VoidCallback onRestore;

  const _PaywallSheet({
    required this.featureName,
    required this.features,
    required this.isPurchasing,
    required this.isRestoring,
    required this.errorMsg,
    required this.onPurchase,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final price = PurchaseService.instance.priceString;
    final isDark = context.isDark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1E2A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 40,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.12),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Lock icon ─────────────────────────────────────────────────
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.4), width: 1.5),
              ),
              child: const Icon(Icons.lock_rounded, color: AppColors.accent, size: 28),
            ),
            const SizedBox(height: 16),

            // ── Headline ──────────────────────────────────────────────────
            Text(
              'Unlock $featureName',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.appText,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Part of Fire Tech Toolbox Pro — a one-time purchase.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.appTextSec, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),

            // ── Feature list ──────────────────────────────────────────────
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(f, style: TextStyle(color: context.appText, fontSize: 13, height: 1.4))),
                ],
              ),
            )),
            const SizedBox(height: 20),

            // ── Error message ─────────────────────────────────────────────
            if (errorMsg != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_rounded, color: AppColors.danger, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(errorMsg!, style: const TextStyle(color: AppColors.danger, fontSize: 12))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Purchase button ───────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (isPurchasing || isRestoring) ? null : onPurchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: isPurchasing
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Unlock Pro — $price',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                    ),
              ),
            ),
            const SizedBox(height: 10),

            // ── Restore button (required by App Store guidelines) ─────────
            TextButton(
              onPressed: (isPurchasing || isRestoring) ? null : onRestore,
              child: isRestoring
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

            // ── Legal footnote ────────────────────────────────────────────
            const SizedBox(height: 4),
            Text(
              'One-time purchase. No subscription. Unlocks on all your devices.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.appTextMuted, fontSize: 11, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
