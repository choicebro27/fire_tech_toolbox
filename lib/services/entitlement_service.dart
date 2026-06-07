// lib/services/entitlement_service.dart
//
// Persists the Pro unlock state to device storage via shared_preferences.
// This is the single source of truth for whether the user has purchased Pro.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kProUnlockedKey = 'pro_unlocked';

class EntitlementService extends ChangeNotifier {
  EntitlementService._();
  static final EntitlementService instance = EntitlementService._();

  bool _isPro = false;

  bool get isPro => _isPro;

  // ── Init: load from disk ───────────────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isPro = prefs.getBool(_kProUnlockedKey) ?? false;
    notifyListeners();
  }

  // ── Unlock (called after successful purchase/restore) ──────────────────────

  Future<void> unlock() async {
    if (_isPro) return; // already unlocked
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kProUnlockedKey, true);
    _isPro = true;
    notifyListeners();
  }

  // ── Dev/test helper: revoke unlock ────────────────────────────────────────
  // Remove this method before shipping to production.

  Future<void> debugRevoke() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kProUnlockedKey);
    _isPro = false;
    notifyListeners();
  }
}
