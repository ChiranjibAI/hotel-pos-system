import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hotel_pos_system/constants/constant.dart';
import 'package:hotel_pos_system/models/analysis/analysis.dart';
import 'package:hotel_pos_system/models/printer.dart';
import 'package:hotel_pos_system/models/repository/cart.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'firebase_compatible_options.dart';
import 'helpers/logger.dart' as logutil;
import 'models/repository/cashier.dart';
import 'models/repository/menu.dart';
import 'models/repository/order_attributes.dart';
import 'models/repository/quantities.dart';
import 'models/repository/replenisher.dart';
import 'models/repository/seller.dart';
import 'models/repository/stock.dart';
import 'models/repository/tables.dart';
import 'services/cache.dart';
import 'services/database.dart';
import 'services/storage.dart';
import 'settings/collect_events_setting.dart';
import 'settings/settings_provider.dart';

/// Whether Firebase initialised successfully. When false, all Firebase-backed
/// features (analytics, crashlytics, in-app messaging) are silently skipped so
/// the offline-first POS still runs without a configured Firebase project.
bool firebaseAvailable = false;

void main() async {
  // Not all errors are caught by Flutter. Sometimes, errors are instead caught by Zones.
  await runZonedGuarded<Future<void>>(() async {
    // https://stackoverflow.com/questions/57689492/flutter-unhandled-exception-servicesbinding-defaultbinarymessenger-was-accesse
    final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

    // Firebase is optional — the POS is offline-first. If the project isn't
    // configured (e.g. stub google-services.json), skip Firebase gracefully.
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      firebaseAvailable = true;
      logutil.firebaseAvailable = true;
      logutil.Log.out('start with firebase: ${DefaultFirebaseOptions.currentPlatform.appId}', 'init');

      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      if (kDebugMode) {
        await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
        await FirebaseInAppMessaging.instance.setMessagesSuppressed(true);
      }
    } catch (e, s) {
      firebaseAvailable = false;
      logutil.firebaseAvailable = false;
      logutil.Log.out('firebase unavailable, running offline: $e', 'init');
      // Fall back to Flutter's default error handling when Crashlytics is off.
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        logutil.Log.out(details.exception.toString(), 'flutter_error');
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        logutil.Log.out(error.toString(), 'platform_error');
        return true;
      };
    }

    await Database.instance.initialize(logWhenQuery: isLocalTest);
    await Storage.instance.initialize();
    await Cache.instance.initialize();

    SettingsProvider.instance.initialize();
    logutil.Log.allowSendEvents = firebaseAvailable && CollectEventsSetting.instance.value;

    await Stock().initialize();
    await Quantities().initialize();
    await OrderAttributes().initialize();
    await Replenisher().initialize();
    await Cashier().reset();
    await Analysis().initialize();
    await Printers().initialize();
    await Tables().initialize();
    // Last for setup ingredient and quantity
    await Menu().initialize();

    /// Why use provider?
    /// https://stackoverflow.com/questions/57157823/provider-vs-inheritedwidget
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: SettingsProvider.instance),
          ChangeNotifierProvider.value(value: Menu.instance),
          ChangeNotifierProvider.value(value: Stock.instance),
          ChangeNotifierProvider.value(value: Quantities.instance),
          ChangeNotifierProvider.value(value: Replenisher.instance),
          ChangeNotifierProvider.value(value: OrderAttributes.instance),
          ChangeNotifierProvider.value(value: Seller.instance),
          ChangeNotifierProvider.value(value: Cashier.instance),
          ChangeNotifierProvider.value(value: Cart.instance),
          ChangeNotifierProvider.value(value: Printers.instance),
          ChangeNotifierProvider.value(value: Tables.instance),
        ],
        child: const App(),
      ),
    );
  }, (error, stack) {
    if (firebaseAvailable) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } else {
      logutil.Log.out(error.toString(), 'zone_error');
    }
  });
}