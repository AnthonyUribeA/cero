import 'package:flutter/material.dart';
import 'models.dart';

/// Paleta de Cero: negro, verde menta y grises cálidos, en oscuro y en claro.
class Pal {
  final bool isDark;
  final Color bg, card, card2, line, text, muted, pri, onPri, cta, onCta;
  final Color red, redFill, green, greenFill, nav, tint, warn, okBg, track;
  final Map<Owner, Color> own;
  final Map<Owner, Color> ownBg;

  const Pal({
    required this.isDark,
    required this.bg,
    required this.card,
    required this.card2,
    required this.line,
    required this.text,
    required this.muted,
    required this.pri,
    required this.onPri,
    required this.cta,
    required this.onCta,
    required this.red,
    required this.redFill,
    required this.green,
    required this.greenFill,
    required this.nav,
    required this.tint,
    required this.warn,
    required this.okBg,
    required this.track,
    required this.own,
    required this.ownBg,
  });

  static const dark = Pal(
    isDark: true,
    bg: Color(0xFF0A0A0A),
    card: Color(0xFF171917),
    card2: Color(0xFF202420),
    line: Color(0xFF2C312C),
    text: Color(0xFFF4F6F4),
    muted: Color(0xFF9AA29A),
    pri: Color(0xFF38E0A8),
    onPri: Color(0xFF04261B),
    cta: Color(0xFF38E0A8),
    onCta: Color(0xFF04261B),
    red: Color(0xFFFF7A7A),
    redFill: Color(0xFFFF7A7A),
    green: Color(0xFF38E0A8),
    greenFill: Color(0xFF38E0A8),
    nav: Color(0xFF171917),
    tint: Color(0x2938E0A8),
    warn: Color(0x1FFF7A7A),
    okBg: Color(0x2438E0A8),
    track: Color(0xFF2C312C),
    own: {
      Owner.tu: Color(0xFF38E0A8),
      Owner.pareja: Color(0xFFB39DFF),
      Owner.persona3: Color(0xFFF472B6),
      Owner.varios: Color(0xFF9AA29A),
    },
    ownBg: {
      Owner.tu: Color(0x2938E0A8),
      Owner.pareja: Color(0x2EB39DFF),
      Owner.persona3: Color(0x2EF472B6),
      Owner.varios: Color(0x299AA29A),
    },
  );

  static const light = Pal(
    isDark: false,
    bg: Color(0xFFECEEEB),
    card: Color(0xFFFFFFFF),
    card2: Color(0xFFF3F5F2),
    line: Color(0xFFDADFD8),
    text: Color(0xFF0A0A0A),
    muted: Color(0xFF5F6760),
    pri: Color(0xFF0B8A64),
    onPri: Color(0xFFFFFFFF),
    cta: Color(0xFF0A0A0A),
    onCta: Color(0xFFFFFFFF),
    red: Color(0xFFC62828),
    redFill: Color(0xFFEF5B5B),
    green: Color(0xFF0B8A64),
    greenFill: Color(0xFF38E0A8),
    nav: Color(0xFFFFFFFF),
    tint: Color(0x2938E0A8),
    warn: Color(0x14C62828),
    okBg: Color(0x1A0B8A64),
    track: Color(0xFFDADFD8),
    own: {
      Owner.tu: Color(0xFF0B8A64),
      Owner.pareja: Color(0xFF7C5CE0),
      Owner.persona3: Color(0xFFC0328A),
      Owner.varios: Color(0xFF5F6760),
    },
    ownBg: {
      Owner.tu: Color(0x1F0B8A64),
      Owner.pareja: Color(0x1F7C5CE0),
      Owner.persona3: Color(0x1FC0328A),
      Owner.varios: Color(0x1F5F6760),
    },
  );

  static Pal of(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? dark : light;
}

ThemeData buildTheme(Pal p) {
  return ThemeData(
    useMaterial3: true,
    brightness: p.isDark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: p.bg,
    canvasColor: p.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: p.pri,
      brightness: p.isDark ? Brightness.dark : Brightness.light,
    ).copyWith(primary: p.pri, surface: p.bg),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}
