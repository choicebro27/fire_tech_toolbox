// lib/services/purchase_service.dart
//
// Handles all communication with the App Store / Google Play billing APIs.
// Uses the official `in_app_purchase` Flutter plugin.
//
// ── Product IDs ──────────────────────────────────────────────────────────────
// Create this product ID as a Non-Consumable in both stores:
//   App Store Connect  → In-App Purchases → com.firetechtoolbox.myapp.pro_unlock
//   Google Play Console → In-app products → com.firetechtoolbox.myapp.pro_unlock
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'entitlement_service.dart';

const String kProProductId = 'com.firetechtoolbox.myapp.pro_unlock';

class PurchaseService {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  ProductDetails? _proProduct;

  // Publicly readable loading / error state
  bool isLoading = false;
  String? errorMessage;

  // Notifier so UI can rebuild when state changes
  final ValueNotifier<bool> loadingNotifier = ValueNotifier(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier(null);

  // ── Initialise ─────────────────────────────────────────────────────────────

  Future<void> init() async {
    // Listen to the purchase stream — fires on purchase, restore, error
    _purchaseSubscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: _onStreamDone,
      onError: _onStreamError,
    );

    // Load the product from the store
    await _loadProduct();

    // On Android, complete any pending purchases from a previous session
    if (Platform.isAndroid) {
      await _iap.restorePurchases();
    }
  }

  Future<void> _loadProduct() async {
    _setLoading(true);
    try {
      final available = await _iap.isAvailable();
      if (!available) {
        _setError('Store not available. Check your internet connection.');
        return;
      }

      final response = await _iap.queryProductDetails({kProProductId});

      if (response.error != null) {
        _setError('Could not load product: ${response.error!.message}');
        return;
      }

      if (response.productDetails.isEmpty) {
        // Product not found — most likely the product ID doesn't match what's
        // in the store, or the product hasn't been approved yet.
        _setError('Pro product not found in store. Check product ID setup.');
        return;
      }

      _proProduct = response.productDetails.first;
      _setError(null);
    } catch (e) {
      _setError('Error loading product: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ── Purchase ───────────────────────────────────────────────────────────────

  Future<void> buyPro() async {
    if (_proProduct == null) {
      await _loadProduct();
      if (_proProduct == null) return;
    }

    final purchaseParam = PurchaseParam(productDetails: _proProduct!);

    try {
      // Non-consumable = buyNonConsumable
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      _setError('Purchase failed: $e');
    }
  }

  // ── Restore ────────────────────────────────────────────────────────────────
  // Required by App Store guidelines — must be accessible from your UI.

  Future<void> restorePurchases() async {
    _setLoading(true);
    try {
      await _iap.restorePurchases();
      // Results arrive via _onPurchaseUpdate stream
    } catch (e) {
      _setError('Restore failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ── Stream handler ─────────────────────────────────────────────────────────

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // Verify and unlock
          await _deliverPurchase(purchase);
          break;

        case PurchaseStatus.error:
          _setError(purchase.error?.message ?? 'Purchase error');
          break;

        case PurchaseStatus.canceled:
          // User cancelled — no action needed
          break;

        case PurchaseStatus.pending:
          // Payment pending (e.g. parental approval on Google Play)
          // Don't unlock yet
          break;
      }

      // IMPORTANT: must call completePurchase to close the transaction
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _deliverPurchase(PurchaseDetails purchase) async {
    // For a one-time unlock, server-side receipt validation is strongly
    // recommended for production, but client-side is acceptable for low-risk
    // non-consumables like a tool unlock.
    //
    // To add server validation:
    //   1. Send purchase.verificationData.serverVerificationData to your server
    //   2. Server calls Apple/Google receipt validation endpoints
    //   3. Only unlock if server confirms valid
    //
    // For now we trust the plugin's status — sufficient for App Store approval.

    if (purchase.productID == kProProductId) {
      await EntitlementService.instance.unlock();
    }
  }

  void _onStreamDone() {
    _purchaseSubscription?.cancel();
  }

  void _onStreamError(dynamic error) {
    _setError('Purchase stream error: $error');
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _setLoading(bool v) {
    isLoading = v;
    loadingNotifier.value = v;
  }

  void _setError(String? msg) {
    errorMessage = msg;
    errorNotifier.value = msg;
  }

  /// Display price string from the store (e.g. "$4.99")
  String get priceString => _proProduct?.price ?? '\$4.99';

  /// True if the product loaded successfully from the store
  bool get productAvailable => _proProduct != null;

  void dispose() {
    _purchaseSubscription?.cancel();
    loadingNotifier.dispose();
    errorNotifier.dispose();
  }
}
