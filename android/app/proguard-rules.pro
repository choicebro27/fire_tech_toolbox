# android/app/proguard-rules.pro
#
# ProGuard / R8 rules for Fire Tech Toolbox
# These prevent R8 from stripping classes needed at runtime.

# ── Flutter ───────────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ── in_app_purchase / Google Play Billing ─────────────────────────────────────
-keep class com.android.vending.billing.** { *; }
-keep class com.android.billingclient.** { *; }

# ── sqflite ───────────────────────────────────────────────────────────────────
-keep class com.tekartik.sqflite.** { *; }

# ── file_picker ───────────────────────────────────────────────────────────────
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# ── permission_handler ────────────────────────────────────────────────────────
-keep class com.baseflow.permissionhandler.** { *; }

# ── noise_meter / audio ───────────────────────────────────────────────────────
-keep class com.github.csdcorp.noise_meter.** { *; }

# ── flutter_gemma ─────────────────────────────────────────────────────────────
# Keep TensorFlow Lite and Gemma inference classes from being stripped
-keep class org.tensorflow.** { *; }
-keep class com.google.mediapipe.** { *; }
-keep class com.google.ai.edge.** { *; }
-dontwarn org.tensorflow.**
-dontwarn com.google.mediapipe.**

# ── pdfx ──────────────────────────────────────────────────────────────────────
-keep class io.scer.pdf_renderer.** { *; }

# ── General Kotlin / coroutines ───────────────────────────────────────────────
-keep class kotlin.** { *; }
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlin.**
-dontwarn kotlinx.coroutines.**

# ── Flutter deferred components (Play Feature Delivery — not used, suppress) ──
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# ── OkHttp TLS extensions (optional providers, not used directly) ─────────────
-dontwarn org.bouncycastle.jsse.**
-dontwarn org.conscrypt.**
-dontwarn org.openjsse.**

# ── javax annotation processor classes (compile-time only, not needed at runtime)
-dontwarn javax.lang.model.**
