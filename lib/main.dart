import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dynamic_color/dynamic_color.dart';

import 'l10n/app_localizations.dart';
import 'src/l10n.dart';
import 'src/local_notification_service.dart';
import 'src/models.dart';
import 'src/schedule_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WakeUpApp());
}

class WakeUpApp extends StatefulWidget {
  const WakeUpApp({super.key});
  @override
  State<WakeUpApp> createState() => _WakeUpAppState();
}

class _WakeUpAppState extends State<WakeUpApp> {
  AppState? _appState;
  String _themeMode = kThemeModeSystem;
  bool _bootstrapping = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await LocalNotificationService.instance.initialize();
    await _loadState();
    if (mounted) {
      setState(() {
        _bootstrapping = false;
      });
    }
  }

  Future<void> _loadState() async {
    final state = await AppState.loadFromPrefs();
    if (mounted) {
      state.addListener(_onStateChanged);
      setState(() {
        _appState = state;
        _themeMode = state.themeMode;
      });
      unawaited(
        LocalNotificationService.instance.syncCourseReminderSchedules(state),
      );
    }
  }

  void _onStateChanged() {
    if (_appState != null) {
      unawaited(
        LocalNotificationService.instance.syncCourseReminderSchedules(
          _appState!,
        ),
      );
    }
    if (mounted && _appState != null && _appState!.themeMode != _themeMode) {
      setState(() {
        _themeMode = _appState!.themeMode;
      });
    }
  }

  @override
  void dispose() {
    _appState?.removeListener(_onStateChanged);
    _appState?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _appState;
    if (state == null || _bootstrapping) {
      // 启动加载屏
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          backgroundColor: const Color(0xFF1C1C1E),
          body: Center(
            child: Builder(
              builder: (innerContext) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF4ECDC4),
                    strokeWidth: 2,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    innerContext.l10n.loadingSchedule,
                    style: const TextStyle(
                      color: Color(0xFF6C6C70),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return _AppWithTheme(appState: state, themeMode: _themeMode);
  }
}

class _AppWithTheme extends StatefulWidget {
  final AppState appState;
  final String themeMode;
  const _AppWithTheme({required this.appState, required this.themeMode});

  @override
  State<_AppWithTheme> createState() => _AppWithThemeState();
}

class _AppWithThemeState extends State<_AppWithTheme> {
  ColorScheme? _lightDynamicScheme;
  ColorScheme? _darkDynamicScheme;
  bool _loadingDynamicColor = false;
  bool _dynamicColorAttempted = false;

  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_onAppStateChanged);
    _syncDynamicColorState();
  }

  @override
  void didUpdateWidget(covariant _AppWithTheme oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appState != widget.appState) {
      oldWidget.appState.removeListener(_onAppStateChanged);
      widget.appState.addListener(_onAppStateChanged);
      _syncDynamicColorState();
    }
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
    _syncDynamicColorState();
  }

  void _syncDynamicColorState() {
    if (!widget.appState.useMaterialDynamicColor ||
        _loadingDynamicColor ||
        _dynamicColorAttempted) {
      return;
    }

    if (_lightDynamicScheme != null && _darkDynamicScheme != null) {
      return;
    }

    _loadingDynamicColor = true;
    _loadDynamicColorSchemes();
  }

  Future<void> _loadDynamicColorSchemes() async {
    try {
      if (kIsWeb) {
        return;
      }

      if (defaultTargetPlatform == TargetPlatform.android) {
        final corePalette = await DynamicColorPlugin.getCorePalette();
        if (!mounted || corePalette == null) {
          return;
        }

        setState(() {
          _lightDynamicScheme = corePalette.toColorScheme();
          _darkDynamicScheme = corePalette.toColorScheme(
            brightness: Brightness.dark,
          );
        });
        return;
      }

      if (defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux) {
        final accentColor = await DynamicColorPlugin.getAccentColor();
        if (!mounted || accentColor == null) {
          return;
        }

        setState(() {
          _lightDynamicScheme = ColorScheme.fromSeed(
            seedColor: accentColor,
            brightness: Brightness.light,
          );
          _darkDynamicScheme = ColorScheme.fromSeed(
            seedColor: accentColor,
            brightness: Brightness.dark,
          );
        });
      }
    } finally {
      _dynamicColorAttempted = true;
      _loadingDynamicColor = false;
    }
  }

  ThemeMode _toThemeMode(String mode) {
    switch (mode) {
      case kThemeModeLight:
        return ThemeMode.light;
      case kThemeModeDark:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required bool isDark,
    required bool useDynamicColor,
  }) {
    if (!useDynamicColor) {
      return ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: isDark
            ? const Color(0xFF1C1C1E)
            : const Color(0xFFF2F2F7),
        cardColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFFFFFFF),
        dividerColor: isDark
            ? const Color(0xFF3A3A3C)
            : const Color(0xFFE5E5EA),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: isDark
              ? const Color(0xFF2C2C2E)
              : const Color(0xFFFFFFFF),
          foregroundColor: isDark ? Colors.white : const Color(0xFF1C1C1E),
          elevation: 0,
          titleTextStyle: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(
            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
          ),
        ),
        dialogTheme: DialogThemeData(
          titleTextStyle: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          contentTextStyle: TextStyle(
            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        extensions: [isDark ? AppColors.dark : AppColors.light],
      );
    }

    final appColors = AppColors(
      bg: Color.alphaBlend(
        colorScheme.primary.withValues(alpha: isDark ? 0.10 : 0.04),
        colorScheme.surface,
      ),
      card: Color.alphaBlend(
        colorScheme.surfaceTint.withValues(alpha: isDark ? 0.12 : 0.06),
        colorScheme.surface,
      ),
      divider: colorScheme.outline.withValues(alpha: 0.35),
      hint: colorScheme.onSurface.withValues(alpha: 0.65),
      primaryText: colorScheme.onSurface,
      secondaryText: colorScheme.onSurface.withValues(alpha: 0.82),
      inputBg: Color.alphaBlend(
        colorScheme.primary.withValues(alpha: isDark ? 0.18 : 0.08),
        colorScheme.surface,
      ),
      iconBg: Color.alphaBlend(
        colorScheme.primary.withValues(alpha: isDark ? 0.20 : 0.10),
        colorScheme.surface,
      ),
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: appColors.bg,
      cardColor: appColors.card,
      dividerColor: appColors.divider,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: appColors.card,
        foregroundColor: appColors.primaryText,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: appColors.primaryText,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: appColors.primaryText),
      ),
      dialogTheme: DialogThemeData(
        titleTextStyle: TextStyle(
          color: appColors.primaryText,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: appColors.hint,
          fontSize: 14,
          height: 1.5,
        ),
      ),
      extensions: [appColors],
    );
  }

  @override
  Widget build(BuildContext context) {
    const originalSeedColor = Color(0xFF4ECDC4);
    final lightScheme =
        widget.appState.useMaterialDynamicColor && _lightDynamicScheme != null
        ? _lightDynamicScheme!.harmonized()
        : ColorScheme.fromSeed(
            seedColor: originalSeedColor,
            brightness: Brightness.light,
          );
    final darkScheme =
        widget.appState.useMaterialDynamicColor && _darkDynamicScheme != null
        ? _darkDynamicScheme!.harmonized()
        : ColorScheme.fromSeed(
            seedColor: originalSeedColor,
            brightness: Brightness.dark,
          );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => context.l10n.appTitle,
      locale: widget.appState.appLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: _buildTheme(
        colorScheme: lightScheme,
        isDark: false,
        useDynamicColor: widget.appState.useMaterialDynamicColor,
      ),
      darkTheme: _buildTheme(
        colorScheme: darkScheme,
        isDark: true,
        useDynamicColor: widget.appState.useMaterialDynamicColor,
      ),
      themeMode: _toThemeMode(widget.themeMode),
      builder: (context, child) =>
          AppStateScope(notifier: widget.appState, child: child!),
      home: const SchedulePage(),
    );
  }
}
