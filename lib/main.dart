// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'services/entitlement_service.dart';
import 'services/purchase_service.dart';
import 'services/gemma_service.dart';
import 'pages/home_page.dart';
import 'pages/battery_calculator_page.dart';
import 'pages/resistor_page.dart';
import 'pages/decibel_meter_page.dart';
import 'pages/ai_chat_page.dart';
import 'pages/settings_page.dart';
import 'pages/paywall_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load persisted unlock state
  await EntitlementService.instance.init();

  // Connect to App Store / Play billing
  await PurchaseService.instance.init();

  // Load Gemma if already downloaded
  await GemmaService.instance.init();

  runApp(const FireTechToolboxApp());
}

class FireTechToolboxApp extends StatefulWidget {
  const FireTechToolboxApp({super.key});

  @override
  State<FireTechToolboxApp> createState() => _FireTechToolboxAppState();
}

class _FireTechToolboxAppState extends State<FireTechToolboxApp> {
  final ThemeModeNotifier _themeModeNotifier = ThemeModeNotifier();

  @override
  void dispose() {
    _themeModeNotifier.dispose();
    PurchaseService.instance.dispose();
    GemmaService.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeScope(
      notifier: _themeModeNotifier,
      child: AnimatedBuilder(
        animation: _themeModeNotifier,
        builder: (context, _) {
          final mode = _themeModeNotifier.mode;
          final platformBrightness =
              WidgetsBinding.instance.platformDispatcher.platformBrightness;
          final effectivelyDark = mode == ThemeMode.dark ||
              (mode == ThemeMode.system && platformBrightness == Brightness.dark);

          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                effectivelyDark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: effectivelyDark
                ? AppColors.darkSurface
                : AppColors.lightSurface,
            systemNavigationBarIconBrightness:
                effectivelyDark ? Brightness.light : Brightness.dark,
          ));

          return MaterialApp(
            title: 'Fire Tech Toolbox',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: mode,
            home: const _HomeShell(),
          );
        },
      ),
    );
  }
}

// ─── Shell ────────────────────────────────────────────────────────────────────

class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _currentIndex = 0;

  static const _navItems = [
    BottomNavigationBarItem(icon: Icon(Icons.home_rounded),                  label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.battery_charging_full_rounded), label: 'Battery'),
    BottomNavigationBarItem(icon: Icon(Icons.cable_rounded),                 label: 'Resistor'),
    BottomNavigationBarItem(icon: Icon(Icons.graphic_eq_rounded),            label: 'dB Meter'),
    BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_rounded),          label: 'AI'),
    BottomNavigationBarItem(icon: Icon(Icons.settings_rounded),              label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomePage(),
      const BatteryCalculatorPage(),
      const PaywallOverlay(
        featureName: 'Resistor Colour Code',
        features: [
          '4-band and 5-band resistor identification',
          'Live visual resistor graphic with real-time band colours',
          'Instant resistance value in Ω, kΩ and MΩ',
          'EOL zone resistor reference for fire panels',
        ],
        child: ResistorPage(),
      ),
      const PaywallOverlay(
        featureName: 'Decibel Meter',
        features: [
          'Real-time microphone dB measurement',
          'Max & average tracking for sounder testing',
          'AS 1670.1 compliance reference levels built in',
          'Calibration offset for accuracy against a reference SLM',
        ],
        child: DecibelMeterPage(),
      ),
      const PaywallOverlay(
        featureName: 'Standards AI Chat',
        features: [
          'Ask questions — get clause-cited answers from your standards',
          'Upload AS 1670.1, AS 1851 or any Australian Standard PDF',
          'Runs 100% on-device — no internet required after setup',
          'Never sends your standards data anywhere',
        ],
        child: AiChatPage(),
      ),
      const SettingsPage(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.appBorder, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          items: _navItems,
          onTap: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}
