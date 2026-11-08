import 'package:flutter/material.dart';

/// Shared presentation tokens. Business rules and storage live in the pages.
abstract final class LarasDesign {
  static const green = Color(0xFF087B58);
  static const brand = Color(0xFF15946C);
  static const ink = Color(0xFF22313A);
  static const mint = Color(0xFFE5F4EE);
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF99DEB1), Color(0xFFC9EDD0), Color(0xFFE4F4D8)],
  );
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF087B58), Color(0xFF075841)],
  );
  static Color tileTone(BuildContext context, int tone) {
    const light = [
      Color(0xFFE6F4EE),
      Color(0xFFEAF0FA),
      Color(0xFFFFF0DF),
      Color(0xFFF0EBFA),
    ];
    const dark = [
      Color(0xFF24443C),
      Color(0xFF273B51),
      Color(0xFF463D30),
      Color(0xFF3A3350),
    ];
    return (isDark(context) ? dark : light)[tone % 4];
  }

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
  static Color accent(BuildContext context) =>
      isDark(context) ? const Color(0xFF6ADCB0) : green;
  static String money(num value) {
    final digits = value.abs().round().toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return '${value < 0 ? '-' : ''}Rp$digits';
  }

  static Color text(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;
  static Color secondary(BuildContext context) =>
      isDark(context) ? const Color(0xFFA6B3BA) : const Color(0xFF65747E);
  static Color soft(BuildContext context) =>
      isDark(context) ? const Color(0xFF213A37) : mint;
  static Color line(BuildContext context) =>
      isDark(context) ? const Color(0xFF30424B) : const Color(0xFFE7ECEF);

  static ThemeData theme({bool dark = false}) {
    final surface = dark ? const Color(0xFF1B2B34) : Colors.white;
    final foreground = dark ? const Color(0xFFF2F6F8) : ink;
    final scheme = ColorScheme.fromSeed(
      seedColor: green,
      brightness: dark ? Brightness.dark : Brightness.light,
    ).copyWith(
      primary: green,
      onPrimary: Colors.white,
      surface: surface,
      onSurface: foreground,
      secondary: const Color(0xFF79C99B),
      onSecondary: ink,
      error: dark ? const Color(0xFFFFB4AB) : const Color(0xFFBA3C3C),
      outline: dark ? const Color(0xFF40535E) : const Color(0xFFE7ECEF),
    );
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      colorScheme: scheme,
      scaffoldBackgroundColor:
          dark ? const Color(0xFF101C23) : const Color(0xFFF6F7F9),
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    return base.copyWith(
      textTheme: base.textTheme
          .copyWith(
            bodyLarge: base.textTheme.bodyLarge?.copyWith(
              fontSize: 16,
              height: 1.55,
            ),
            bodyMedium: base.textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              height: 1.5,
            ),
            bodySmall: base.textTheme.bodySmall?.copyWith(
              fontSize: 13,
              height: 1.5,
            ),
          )
          .apply(bodyColor: foreground, displayColor: foreground),
      focusColor: green.withValues(alpha: .18),
      hoverColor: green.withValues(alpha: .06),
      appBarTheme: AppBarTheme(
        backgroundColor: base.scaffoldBackgroundColor,
        foregroundColor: foreground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 19,
          letterSpacing: -.4,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outline.withValues(alpha: .35)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 54),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          backgroundColor: green,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          shape: shape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 54),
          foregroundColor: foreground,
          side: BorderSide(color: scheme.outline),
          shape: shape,
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: dark ? const Color(0xFF6ADCB0) : green,
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF21333D) : const Color(0xFFF1F4F6),
        hintStyle: TextStyle(
          color: dark ? const Color(0xFFA6B3BA) : const Color(0xFF65747E),
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: .7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: green, width: 2),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: dark ? const Color(0xFF6ADCB0) : green,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          height: 1.6,
          color: dark ? const Color(0xFFA6B3BA) : const Color(0xFF65747E),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: green,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: shape,
        extendedTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surface,
        selectedColor: dark ? const Color(0xFF23473C) : const Color(0xFFE3F3EC),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
        showCheckmark: false,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline.withValues(alpha: .6),
        thickness: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// A finite entrance, disabled when the operating system requests less motion.
class LarasEntrance extends StatelessWidget {
  const LarasEntrance({super.key, required this.child, this.order = 0});
  final Widget child;
  final int order;
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context)) {
      return child;
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + order * 35),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - value)),
          child: child,
        ),
      ),
    );
  }
}

class LarasPageIntro extends StatelessWidget {
  const LarasPageIntro({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    this.icon = Icons.spa_outlined,
  });
  final String eyebrow, title, description;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: LarasDesign.green, size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  eyebrow.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w600,
                    color: LarasDesign.secondary(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 26,
              height: 1.2,
              letterSpacing: -.6,
              fontWeight: FontWeight.w600,
              color: LarasDesign.text(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              height: 1.55,
              color: LarasDesign.secondary(context),
            ),
          ),
        ],
      );
}
