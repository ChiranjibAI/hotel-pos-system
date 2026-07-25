import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotel_pos_system/constants/app_themes.dart';
import 'package:hotel_pos_system/models/repository/staff.dart';
import 'package:hotel_pos_system/models/staff/staff.dart';

/// A PIN-pad login screen shown when staff are configured and no one is
/// logged in. Displays a numeric keypad, the entered PIN as dots, and
/// validates against [StaffRepository.findByPin]. On success, calls
/// [StaffSession.login] and the parent rebuilds to show the main app.
class StaffLoginPage extends StatefulWidget {
  const StaffLoginPage({super.key});

  @override
  State<StaffLoginPage> createState() => _StaffLoginPageState();
}

class _StaffLoginPageState extends State<StaffLoginPage> {
  String _pin = '';
  String? _error;
  int _attempts = 0;

  static const _maxPinLength = 6;

  void _addDigit(String d) {
    if (_pin.length >= _maxPinLength) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pin += d;
      _error = null;
    });
    if (_pin.length >= 4) {
      _tryLogin();
    }
  }

  void _delete() {
    if (_pin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
    });
  }

  void _tryLogin() {
    final ok = StaffSession.instance.login(_pin);
    if (!ok) {
      _attempts++;
      HapticFeedback.heavyImpact();
      setState(() {
        _error = 'Invalid PIN. Try again.';
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Lock icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: BrandColors.gold.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_outline, size: 34, color: BrandColors.gold),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Staff Login',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enter your PIN to continue',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // PIN dots
                  _PinDots(length: _pin.length, maxLength: _maxPinLength),
                  const SizedBox(height: 12),
                  // Error
                  SizedBox(
                    height: 20,
                    child: _error != null
                        ? Text(_error!, style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: BrandColors.danger,
                            fontWeight: FontWeight.w600,
                          ))
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),
                  // Keypad
                  _PinPad(onDigit: _addDigit, onDelete: _delete),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PinDots extends StatelessWidget {
  final int length;
  final int maxLength;
  const _PinDots({required this.length, required this.maxLength});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(maxLength, (i) {
        final filled = i < length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: filled ? 16 : 14,
          height: filled ? 16 : 14,
          decoration: BoxDecoration(
            color: filled ? BrandColors.gold : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: filled ? BrandColors.gold : Colors.white24,
              width: 2,
            ),
          ),
        );
      }),
    );
  }
}

class _PinPad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  const _PinPad({required this.onDigit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          [null, '0', 'del'],
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((d) {
                if (d == null) return const SizedBox(width: 72, height: 72);
                if (d == 'del') {
                  return _PinKey(
                    child: const Icon(Icons.backspace_outlined, size: 26),
                    onTap: onDelete,
                  );
                }
                return _PinKey(
                  child: Text(d, style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  )),
                  onTap: () => onDigit(d),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _PinKey extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PinKey({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: isDark ? BrandColors.charcoalCard : BrandColors.creamCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white12 : BrandColors.creamBorder,
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}