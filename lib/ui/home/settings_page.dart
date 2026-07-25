import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:hotel_pos_system/components/sign_in_button.dart';
import 'package:hotel_pos_system/components/style/outlined_text.dart';
import 'package:hotel_pos_system/components/style/pop_button.dart';
import 'package:hotel_pos_system/constants/app_themes.dart';
import 'package:hotel_pos_system/constants/constant.dart';
import 'package:hotel_pos_system/routes.dart';
import 'package:hotel_pos_system/services/auth.dart';
import 'package:hotel_pos_system/settings/checkout_warning.dart';
import 'package:hotel_pos_system/settings/collect_events_setting.dart';
import 'package:hotel_pos_system/settings/language_setting.dart';
import 'package:hotel_pos_system/settings/order_awakening_setting.dart';
import 'package:hotel_pos_system/settings/theme_setting.dart';
import 'package:hotel_pos_system/translator.dart';

class SettingsPage extends StatelessWidget {
  final String? focus;

  const SettingsPage({super.key, this.focus});

  @override
  Widget build(BuildContext context) {
    const String flavor = .fromEnvironment('appFlavor');

    void navigateTo(Feature feature) {
      context.pushNamed(Routes.settingsFeature, pathParameters: {'feature': feature.name});
    }

    return SafeArea(
      child: ListView(
        padding: const .only(bottom: kFABSpacing, top: kTopSpacing),
        children: <Widget>[
          const SizedBox(height: 8.0),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final info = snapshot.data;
              return Row(
                mainAxisAlignment: .center,
                children: [
                  if (info != null) Text(S.settingVersion(info.version)),
                  const SizedBox(width: 8.0),
                  OutlinedText((kDebugMode ? '_' : '') + flavor.toUpperCase()),
                ],
              );
            },
          ),
          const SizedBox(height: 8.0),
          Padding(
            padding: const .symmetric(horizontal: 8.0),
            child: SignInButton(
              signedInWidgetBuilder: (user) => Row(
                mainAxisAlignment: .spaceBetween,
                children: [
                  Text(S.settingWelcome(user?.displayName ?? '')),
                  OutlinedButton(
                    key: const Key('feature.sign_out'),
                    onPressed: () async {
                      await Auth.instance.signOut();
                    },
                    child: Text(S.settingLogoutBtn),
                  ),
                ],
              ),
            ),
          ),
          // ===== GENERAL SECTION =====
          _SectionHeader(title: 'General'),
          ListenableBuilder(
            listenable: ThemeSetting.instance,
            builder: (context, _) {
              return ListTile(
                key: const Key('feature.theme'),
                leading: const Icon(Icons.palette_outlined),
                title: Text(S.settingThemeTitle),
                subtitle: Text(S.settingThemeName(ThemeSetting.instance.value.name)),
                trailing: const Icon(Icons.navigate_next_outlined),
                onTap: () => navigateTo(.theme),
              );
            },
          ),
          ListenableBuilder(
            listenable: LanguageSetting.instance,
            builder: (context, _) {
              return ListTile(
                key: const Key('feature.language'),
                leading: const Icon(Icons.language_outlined),
                title: Text(S.settingLanguageTitle),
                subtitle: Text(LanguageSetting.instance.language.title),
                trailing: const Icon(Icons.navigate_next_outlined),
                onTap: () => navigateTo(.language),
              );
            },
          ),
          ListenableBuilder(
            listenable: CheckoutWarningSetting.instance,
            builder: (context, _) {
              return ListTile(
                key: const Key('feature.checkout_warning'),
                leading: const Icon(Icons.store_mall_directory_outlined),
                title: Text(S.settingCheckoutWarningTitle),
                subtitle: Text(S.settingCheckoutWarningName(CheckoutWarningSetting.instance.value.name)),
                trailing: const Icon(Icons.navigate_next_outlined),
                onTap: () => navigateTo(.checkoutWarning),
              );
            },
          ),
          ListenableBuilder(
            listenable: OrderAwakeningSetting.instance,
            builder: (context, _) {
              return SwitchListTile.adaptive(
                key: const Key('feature.order_awakening'),
                secondary: const Icon(Icons.remove_red_eye_outlined),
                title: Text(S.settingOrderAwakeningTitle),
                subtitle: Text(S.settingOrderAwakeningDescription),
                autofocus: focus == 'orderAwakening',
                value: OrderAwakeningSetting.instance.value,
                onChanged: (value) => OrderAwakeningSetting.instance.update(value),
              );
            },
          ),
          // ===== RESTAURANT SECTION =====
          _SectionHeader(title: 'Restaurant'),
          // UPI Payment
          ListTile(
            key: const Key('feature.upi'),
            leading: const Icon(Icons.qr_code_outlined),
            title: const Text('UPI Payment'),
            subtitle: const Text('Accept UPI payments with zero fees'),
            trailing: const Icon(Icons.navigate_next_outlined),
            onTap: () => context.pushNamed(Routes.upiSettings),
          ),
          // Kitchen Display
          ListTile(
            key: const Key('feature.kitchen'),
            leading: const Icon(Icons.restaurant_outlined),
            title: const Text('Kitchen Display'),
            subtitle: const Text('Live order queue for the kitchen'),
            trailing: const Icon(Icons.navigate_next_outlined),
            onTap: () => context.pushNamed(Routes.kitchenDisplay),
          ),
          // Voice Ordering
          ListTile(
            key: const Key('feature.voice'),
            leading: const Icon(Icons.mic_outlined),
            title: const Text('Voice Ordering'),
            subtitle: const Text('Speak the order, app parses it'),
            trailing: const Icon(Icons.navigate_next_outlined),
            onTap: () => context.pushNamed(Routes.voiceOrdering),
          ),
          // Staff management
          ListTile(
            key: const Key('feature.staff'),
            leading: const Icon(Icons.people_outline),
            title: const Text('Staff Management'),
            subtitle: const Text('Add staff, set roles and PINs'),
            trailing: const Icon(Icons.navigate_next_outlined),
            onTap: () => context.pushNamed(Routes.staff),
          ),
          // Reservations
          ListTile(
            key: const Key('feature.reservations'),
            leading: const Icon(Icons.event_available_outlined),
            title: const Text('Reservations'),
            subtitle: const Text('Manage table bookings and waitlist'),
            trailing: const Icon(Icons.navigate_next_outlined),
            onTap: () => context.pushNamed(Routes.reservations),
          ),
          // QR Ordering
          ListTile(
            key: const Key('feature.qr'),
            leading: const Icon(Icons.qr_code_outlined),
            title: const Text('QR Table Ordering'),
            subtitle: const Text('Generate QR codes for each table'),
            trailing: const Icon(Icons.navigate_next_outlined),
            onTap: () => context.pushNamed(Routes.qrOrdering),
          ),
          // Aggregator Import
          ListTile(
            key: const Key('feature.aggregator'),
            leading: const Icon(Icons.delivery_dining_outlined),
            title: const Text('Aggregator Import'),
            subtitle: const Text('Import Zomato/Swiggy orders'),
            trailing: const Icon(Icons.navigate_next_outlined),
            onTap: () => context.pushNamed(Routes.aggregatorImport),
          ),
          // Loyalty Program
          ListTile(
            key: const Key('feature.loyalty'),
            leading: const Icon(Icons.card_giftcard_outlined),
            title: const Text('Loyalty Program'),
            subtitle: const Text('Customer points and rewards'),
            trailing: const Icon(Icons.navigate_next_outlined),
            onTap: () => context.pushNamed(Routes.loyalty),
          ),
          // ===== REPORTS & INSIGHTS =====
          _SectionHeader(title: 'Reports & Insights'),
          // Daily Sales Report
          ListTile(
            key: const Key('feature.daily'),
            leading: const Icon(Icons.today_outlined),
            title: const Text('Daily Sales Report'),
            subtitle: const Text('Today\'s summary, share to WhatsApp'),
            trailing: const Icon(Icons.navigate_next_outlined),
            onTap: () => context.pushNamed(Routes.dailyReport),
          ),
          // Menu Engineering
          ListTile(
            key: const Key('feature.eng'),
            leading: const Icon(Icons.analytics_outlined),
            title: const Text('Menu Engineering'),
            subtitle: const Text('Stars, Plowhorses, Dogs, Puzzles'),
            trailing: const Icon(Icons.navigate_next_outlined),
            onTap: () => context.pushNamed(Routes.menuEngineering),
          ),
          // GST Report
          ListTile(
            key: const Key('feature.gst'),
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('GST Report'),
            subtitle: const Text('Tax breakdown with CGST/SGST split'),
            trailing: const Icon(Icons.navigate_next_outlined),
            onTap: () => context.pushNamed(Routes.gstReport),
          ),
          // Day-Part Analysis
          ListTile(
            key: const Key('feature.daypart'),
            leading: const Icon(Icons.bar_chart_outlined),
            title: const Text('Day-Part Analysis'),
            subtitle: const Text('Hourly sales distribution'),
            trailing: const Icon(Icons.navigate_next_outlined),
            onTap: () => context.pushNamed(Routes.dayPart),
          ),
          // Recipe Costing
          ListTile(
            key: const Key('feature.costing'),
            leading: const Icon(Icons.calculate_outlined),
            title: const Text('Recipe Costing'),
            subtitle: const Text('Profit margins per menu item'),
            trailing: const Icon(Icons.navigate_next_outlined),
            onTap: () => context.pushNamed(Routes.recipeCosting),
          ),
          ListenableBuilder(
            listenable: CollectEventsSetting.instance,
            builder: (context, _) {
              return SwitchListTile.adaptive(
                key: const Key('feature.collect_events'),
                secondary: const Icon(Icons.report_outlined),
                title: Text(S.settingReportTitle),
                subtitle: Text(S.settingReportDescription),
                autofocus: focus == 'collectEvents',
                value: CollectEventsSetting.instance.value,
                onChanged: (value) => CollectEventsSetting.instance.update(value),
              );
            },
          ),
          const SizedBox(height: kFABSpacing),
        ],
      ),
    );
  }
}

class ItemListScaffold extends StatelessWidget {
  final Feature feature;

  const ItemListScaffold({super.key, required this.feature});

  @override
  Widget build(BuildContext context) {
    final hintStyle = TextStyle(color: Theme.of(context).hintColor);

    final selected = ValueNotifier<int>(feature.selected);
    return Scaffold(
      appBar: AppBar(title: Text(feature.title), leading: const PopButton()),
      body: ValueListenableBuilder(
        valueListenable: selected,
        builder: (context, value, child) => ListView(
          children: IterableZip([feature.itemTitles, feature.itemSubtitles])
              .mapIndexed(
                (index, pair) => ListTile(
                  title: Text(pair[0]),
                  trailing: value == index ? const Icon(Icons.check_outlined) : null,
                  subtitle: Text(pair[1], style: hintStyle),
                  onTap: () async {
                    if (value != index) {
                      selected.value = index;
                      await feature.update(index);
                    }
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

enum Feature {
  theme(),
  language(),
  checkoutWarning();

  const Feature();

  Iterable<String> get itemTitles {
    return switch (this) {
      .theme => ThemeMode.values.map((e) => S.settingThemeName(e.name)),
      .language => Language.values.map((e) => e.title),
      .checkoutWarning => CheckoutWarningTypes.values.map((e) => S.settingCheckoutWarningName(e.name)),
    };
  }

  Iterable<String> get itemSubtitles {
    return switch (this) {
      .theme => ThemeMode.values.map((e) => ''),
      .language => Language.values.map((e) => ''),
      .checkoutWarning => CheckoutWarningTypes.values.map((e) => S.settingCheckoutWarningTip(e.name)),
    };
  }

  String get title {
    return switch (this) {
      .theme => S.settingThemeTitle,
      .language => S.settingLanguageTitle,
      .checkoutWarning => S.settingCheckoutWarningTitle,
    };
  }

  int get selected {
    return switch (this) {
      .theme => ThemeSetting.instance.value.index,
      .language => LanguageSetting.instance.language.index,
      .checkoutWarning => CheckoutWarningSetting.instance.value.index,
    };
  }

  Future<void> update(int index) {
    return switch (this) {
      .theme => ThemeSetting.instance.update(ThemeMode.values[index]),
      .language => LanguageSetting.instance.update(Language.values[index]),
      .checkoutWarning => CheckoutWarningSetting.instance.update(CheckoutWarningTypes.values[index]),
    };
  }
}

/// A section header used to group settings entries with visual hierarchy.
/// Renders as a small gold uppercase label with top/bottom padding.
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: BrandColors.gold,
        ),
      ),
    );
  }
}
