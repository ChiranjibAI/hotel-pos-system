import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_pos_system/constants/constant.dart';
import 'package:hotel_pos_system/l10n/gen/app_localizations.dart';
import 'package:hotel_pos_system/services/cache.dart';

import 'constants/app_themes.dart';
import 'main.dart' show firebaseAvailable;
import 'routes.dart';
import 'settings/language_setting.dart';
import 'settings/settings_provider.dart';
import 'settings/theme_setting.dart';
import 'translator.dart';
import 'ui/onboarding/onboarding_wizard.dart';

class App extends StatefulWidget {
  static final routeObserver = RouteObserver<ModalRoute<void>>();

  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  static ValueNotifier<RoutingConfig>? routingConfig;

  // singleton be avoid recreate after hot reload.
  static RouterConfig<Object>? router;

  const App({super.key}); // coverage:ignore-line

  @override
  State<App> createState() => _AppState();

  // This widget is the root of your application.
  static Widget _buildApp(BuildContext context) {
    final routes = Routes.getDesiredRoute(MediaQuery.sizeOf(context).width);
    routingConfig ??= ValueNotifier(routes);
    routingConfig!.value = routes;
    router ??= GoRouter.routingConfig(
      initialLocation: Routes.initLocation,
      routingConfig: routingConfig!,
      navigatorKey: Routes.rootNavigatorKey,
      debugLogDiagnostics: kDebugMode,
      observers: [
        if (firebaseAvailable) FirebaseAnalyticsObserver(analytics: .instance),
        routeObserver,
      ],
    );

    return AnimatedBuilder(
      animation: SettingsProvider.instance,
      builder: (context, child) {
        return MaterialApp.router(
          routerConfig: router!,
          scaffoldMessengerKey: scaffoldMessengerKey,
          onGenerateTitle: (context) {
            final localizations = AppLocalizations.of(context)!;

            setAppLocalizations(localizations);
            LanguageSetting.instance.systemLanguage = S.localeName;

            FlutterNativeSplash.remove();

            return localizations.appTitle;
          },
          debugShowCheckedModeBanner: !isProd,
          locale: LanguageSetting.instance.value?.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: ThemeSetting.instance.value,
        );
      },
    );
  }
}

class _AppState extends State<App> {
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    // Check if onboarding has been completed. The check runs after the first
    // frame so the splash screen is visible while we read from the cache.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final completed = Cache.instance.get<bool>('onboarding.completed') ?? false;
      if (mounted && !completed) {
        FlutterNativeSplash.remove();
        setState(() => _showOnboarding = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding) {
      return MaterialApp(
        debugShowCheckedModeBanner: !isProd,
        theme: AppThemes.darkTheme,
        home: OnboardingWizard(
          onComplete: () {
            setState(() => _showOnboarding = false);
          },
        ),
      );
    }
    return App._buildApp(context);
  }
}
