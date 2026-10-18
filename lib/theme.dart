import 'package:flutter/material.dart';
import 'models.dart';

/// Paleta "Azul noche", en oscuro y en claro.
class Pal {
  final bool isDark;
  final Color bg, card, card2, line, text, muted, pri, onPri;
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
    bg: Color(0xFF0B1220),
    card: Color(0xFF131D33),
    card2: Color(0xFF1B2742),
    line: Color(0xFF2A3858),
    text: Color(0xFFEAF0FF),
    muted: Color(0xFF9AA8C7),
    pri: Color(0xFF4F8CFF),
    onPri: Color(0xFF06101F),
    red: Color(0xFFFF7A7A),
    redFill: Color(0xFFFF7A7A),
    green: Color(0xFF3DDC97),
    greenFill: Color(0xFF3DDC97),
    nav: Color(0xFF0F182B),
    tint: Color(0x2E4F8CFF),
    warn: Color(0x1FFF7A7A),
    okBg: Color(0x243DDC97),
    track: Color(0xFF2A3858),
    own: {
      Owner.tu: Color(0xFF4F8CFF),
      Owner.pareja: Color(0xFFB197FC),
      Owner.persona3: Color(0xFFF472B6),
      Owner.varios: Color(0xFF9AA8C7),
    },
    ownBg: {
      Owner.tu: Color(0x2E4F8CFF),
      Owner.pareja: Color(0x2EB197FC),
      Owner.persona3: Color(0x2EF472B6),
      Owner.varios: Color(0x299AA8C7),
    },
  );

  static const light = Pal(
    isDark: false,
    bg: Color(0xFFF2F5FB),
    card: Color(0xFFFFFFFF),
    card2: Color(0xFFE6ECF8),
    line: Color(0xFFD5DEF0),
    text: Color(0xFF0F1830),
    muted: Color(0xFF55627F),
    pri: Color(0xFF2A66E0),
    onPri: Color(0xFFFFFFFF),
    red: Color(0xFFBF3030),
    redFill: Color(0xFFEF5B5B),
    green: Color(0xFF0B7A52),
    greenFill: Color(0xFF22B573),
    nav: Color(0xFFFFFFFF),
    tint: Color(0x1F2A66E0),
    warn: Color(0x14BF3030),
    okBg: Color(0x1A0B7A52),
    track: Color(0xFFD5DEF0),
    own: {
      Owner.tu: Color(0xFF2A66E0),
      Owner.pareja: Color(0xFF7C5CE0),
      Owner.persona3: Color(0xFFC0328A),
      Owner.varios: Color(0xFF55627F),
    },
    ownBg: {
      Owner.tu: Color(0x1F2A66E0),
      Owner.pareja: Color(0x1F7C5CE0),
      Owner.persona3: Color(0x1FC0328A),
      Owner.varios: Color(0x1F55627F),
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
