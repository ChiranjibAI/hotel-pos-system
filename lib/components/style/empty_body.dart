import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotel_pos_system/constants/app_themes.dart';
import 'package:hotel_pos_system/translator.dart';

/// A premium empty-state widget with a branded illustration (icon in a
/// circular gold-tinted container), title, description, and action button.
///
/// Replaces the old plain-text empty body with a polished visual that matches
/// the Level 1 brand theme.
class EmptyBody extends StatelessWidget {
  final String? title;
  final String? content;

  /// navigate to the route when the button is pressed, either this or [onPressed] must be provided
  final String? routeName;

  /// path parameters for the route
  final Map<String, String> pathParameters;

  final VoidCallback? onPressed;

  /// Optional custom icon (defaults to a box/empty illustration).
  final IconData icon;

  /// Optional custom accent color for the icon (defaults to gold).
  final Color? accentColor;

  const EmptyBody({
    super.key,
    this.title,
    this.content,
    this.routeName,
    this.pathParameters = const <String, String>{},
    this.onPressed,
    this.icon = Icons.inventory_2_outlined,
    this.accentColor,
  }) : assert(true, '');

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? BrandColors.gold;
    return SizedBox(
      height: 360,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Branded illustration container
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 44, color: color),
          ),
          const SizedBox(height: 24),
          Text(
            title ?? S.emptyBodyTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (content != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 10, 32, 0),
              child: Text(
                content!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  height: 1.5,
                ),
              ),
            ),
          const SizedBox(height: 24),
          if (routeName != null || onPressed != null)
            ElevatedButton.icon(
              key: const Key('empty_body'),
              onPressed: onPressed ?? () => context.pushNamed(routeName!, pathParameters: pathParameters),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                S.emptyBodyAction,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
          ),
        ],
      ),
    );
  }
}