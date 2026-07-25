import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotel_pos_system/constants/app_themes.dart';
import 'package:hotel_pos_system/services/cache.dart';
import 'package:hotel_pos_system/settings/currency_setting.dart';
import 'package:hotel_pos_system/settings/language_setting.dart';

/// First-run onboarding wizard.
///
/// Shown when `onboarding.completed` is not set in the cache. Walks the user
/// through: welcome → language → currency → restaurant name → done.
///
/// The wizard is self-contained — it calls [Cache.set] directly so the result
/// persists, and calls the setting's [update] so the live app picks up the
/// change without a restart.
class OnboardingWizard extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingWizard({super.key, required this.onComplete});

  @override
  State<OnboardingWizard> createState() => _OnboardingWizardState();
}

class _OnboardingWizardState extends State<OnboardingWizard> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  int _currentPage = 0;
  Language _selectedLanguage = Language.en;
  CurrencyTypes _selectedCurrency = CurrencyTypes.usd;

  static const _totalPages = 4;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _complete();
    }
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _complete() async {
    // Save language and currency
    await LanguageSetting.instance.update(_selectedLanguage);
    await CurrencySetting.instance.update(_selectedCurrency);

    // Save restaurant name
    if (_nameController.text.trim().isNotEmpty) {
      await Cache.instance.set<String>('restaurant.name', _nameController.text.trim());
    }

    // Mark onboarding complete
    await Cache.instance.set<bool>('onboarding.completed', true);

    HapticFeedback.mediumImpact();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgress(),
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildWelcomePage(),
                  _buildLanguagePage(),
                  _buildCurrencyPage(),
                  _buildNamePage(),
                ],
              ),
            ),
            // Navigation buttons
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: List.generate(_totalPages, (i) {
          final active = i <= _currentPage;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 4,
              decoration: BoxDecoration(
                color: active ? BrandColors.gold : Colors.white12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomBar() {
    final isLast = _currentPage == _totalPages - 1;
    final isFirst = _currentPage == 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Row(
        children: [
          if (!isFirst)
            TextButton(
              onPressed: _previousPage,
              child: Text(
                'Back',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
            )
          else
            const SizedBox(width: 60),
          const Spacer(),
          ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(140, 48),
            ),
            child: Text(
              isLast ? 'Get Started' : 'Next',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return _CenteredPage(
      icon: Icons.restaurant_menu,
      title: 'Welcome to\nHotel POS System',
      subtitle: 'The complete point-of-sale system for your restaurant.\nLet\'s set things up — it takes less than a minute.',
      child: const SizedBox.shrink(),
    );
  }

  Widget _buildLanguagePage() {
    return _CenteredPage(
      icon: Icons.language_rounded,
      title: 'Choose your language',
      subtitle: 'You can change this anytime in Settings.',
      child: Column(
        children: [
          for (final lang in Language.values)
            _OptionTile(
              label: _languageDisplayName(lang),
              selected: _selectedLanguage == lang,
              onTap: () => setState(() => _selectedLanguage = lang),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrencyPage() {
    return _CenteredPage(
      icon: Icons.payments_rounded,
      title: 'Select your currency',
      subtitle: 'Used for cash register and reports.',
      child: Column(
        children: [
          for (final cur in CurrencyTypes.values)
            _OptionTile(
              label: _currencyDisplayName(cur),
              selected: _selectedCurrency == cur,
              onTap: () => setState(() => _selectedCurrency = cur),
            ),
        ],
      ),
    );
  }

  Widget _buildNamePage() {
    return _CenteredPage(
      icon: Icons.storefront_rounded,
      title: 'What\'s your restaurant called?',
      subtitle: 'This name appears on receipts and reports.',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: TextField(
          controller: _nameController,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w600),
          decoration: const InputDecoration(
            hintText: 'e.g. Spice Garden',
            contentPadding: EdgeInsets.symmetric(vertical: 18),
          ),
          onSubmitted: (_) => _nextPage(),
        ),
      ),
    );
  }

  String _languageDisplayName(Language lang) {
    return switch (lang) {
      Language.en => 'English',
      Language.zhTW => '繁體中文',
    };
  }

  String _currencyDisplayName(CurrencyTypes cur) {
    return switch (cur) {
      CurrencyTypes.usd => 'US Dollar (\$)',
      CurrencyTypes.twd => 'Taiwan Dollar (NT\$)',
    };
  }
}

/// A reusable onboarding page layout — centered icon + title + subtitle + child.
class _CenteredPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _CenteredPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: BrandColors.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, size: 40, color: BrandColors.gold),
          ),
          const SizedBox(height: 28),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              color: Theme.of(context).textTheme.bodySmall?.color,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          child,
        ],
      ),
    );
  }
}

/// A selectable option tile with gold highlight when selected.
class _OptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Material(
        color: selected
            ? BrandColors.gold.withValues(alpha: 0.15)
            : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? BrandColors.gold : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle, color: BrandColors.gold, size: 24)
                else
                  Icon(Icons.radio_button_unchecked, color: Colors.white24, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}