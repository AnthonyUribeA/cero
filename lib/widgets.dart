import 'package:flutter/material.dart';
import 'icons.dart';
import 'models.dart';
import 'theme.dart';

TextStyle ts(Pal p, double size,
    {FontWeight w = FontWeight.w500, Color? color, double? ls, bool tab = false, double? h}) {
  return TextStyle(
    fontSize: size,
    fontWeight: w,
    color: color ?? p.text,
    letterSpacing: ls,
    height: h,
    fontFeatures: tab ? const [FontFeature.tabularFigures()] : null,
  );
}

Widget panel(Pal p,
    {required Widget child,
    double radius = 22,
    EdgeInsets pad = const EdgeInsets.all(16),
    Color? color,
    VoidCallback? onTap}) {
  final box = Container(
    width: double.infinity,
    padding: pad,
    decoration: BoxDecoration(
      color: color ?? p.card,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: p.isDark
          ? null
          : const [BoxShadow(color: Color(0x0F0F1830), blurRadius: 2, offset: Offset(0, 1))],
    ),
    child: child,
  );
  if (onTap == null) return box;
  return GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: box);
}

Widget screenTitle(Pal p, String small, String title, {Widget? trailing}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(small, style: ts(p, 14, color: p.muted)),
            Text(title, style: ts(p, 32, w: FontWeight.w700, ls: -0.6)),
          ],
        ),
      ),
      if (trailing != null) trailing,
    ],
  );
}

Widget ownerChip(Pal p, Owner o) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
    decoration: BoxDecoration(color: p.ownBg[o], borderRadius: BorderRadius.circular(999)),
    child: Text(o.label, style: ts(p, 11, w: FontWeight.w700, color: p.own[o])),
  );
}

Widget roundButton(Pal p, IconData icon, VoidCallback? onTap,
    {bool primary = false, String? label}) {
  final enabled = onTap != null;
  return Semantics(
    button: true,
    label: label,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: primary ? p.cta : (enabled ? p.card2 : p.card),
          borderRadius: BorderRadius.circular(primary ? 22 : 14),
        ),
        child: Icon(icon,
            size: 20,
            color: primary ? p.onCta : (enabled ? p.text : p.muted.withValues(alpha: 0.5))),
      ),
    ),
  );
}

/// Botón − valor +
Widget stepper(Pal p,
    {required String value,
    required VoidCallback? onLess,
    required VoidCallback? onMore,
    double width = 84,
    String lessLabel = 'Bajar',
    String moreLabel = 'Subir'}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      roundButton(p, Ic.minus, onLess, label: lessLabel),
      SizedBox(
        width: width,
        child: Text(value,
            textAlign: TextAlign.center, style: ts(p, 18, w: FontWeight.w700, tab: true)),
      ),
      roundButton(p, Ic.plus, onMore, label: moreLabel),
    ],
  );
}

/// Barra partida en tramos con colores.
Widget splitBar(Pal p, List<MapEntry<double, Color>> parts, {double height = 12}) {
  final total = parts.fold(0.0, (s, e) => s + e.key);
  return SizedBox(
    height: height,
    child: Row(
      children: [
        for (var i = 0; i < parts.length; i++) ...[
          if (i > 0) const SizedBox(width: 2),
          Expanded(
            flex: (total > 0 ? (parts[i].key / total * 1000).round() : 1).clamp(1, 1000).toInt(),
            child: Container(
              decoration: BoxDecoration(
                color: parts[i].value,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(i == 0 ? height / 2 : 2),
                  right: Radius.circular(i == parts.length - 1 ? height / 2 : 2),
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

Widget progressBar(Pal p, double frac, Color fill, {double height = 8}) {
  final f = frac.clamp(0.0, 1.0).toDouble();
  return Container(
    height: height,
    decoration: BoxDecoration(color: p.track, borderRadius: BorderRadius.circular(height / 2)),
    child: FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: f,
      child: Container(
          decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(height / 2))),
    ),
  );
}

Widget bigButton(Pal p, String label, VoidCallback onTap, {bool outline = false}) {
  return Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: outline ? Colors.transparent : p.cta,
          border: outline ? Border.all(color: p.text, width: 1.5) : null,
          borderRadius: BorderRadius.circular(27),
        ),
        child: Text(label,
            style: ts(p, 16, w: FontWeight.w700, color: outline ? p.text : p.onCta)),
      ),
    ),
  );
}

Widget switchTile(Pal p, String title, String sub, bool value, ValueChanged<bool> onChanged) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: ts(p, 15, w: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(sub, style: ts(p, 12, color: p.muted, h: 1.4)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: p.greenFill,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: p.track,
        ),
      ],
    ),
  );
}

Widget divider(Pal p) => Container(height: 1, color: p.line);

const Color mint = Color(0xFF38E0A8);

/// Texto blanco para usar sobre la cabecera negra.
TextStyle hs(double size, {FontWeight w = FontWeight.w500, Color color = Colors.white, double? ls}) =>
    TextStyle(fontSize: size, fontWeight: w, color: color, letterSpacing: ls);

/// Cabecera negra con esquinas redondeadas y un brillo verde.
class CeroHeader extends StatelessWidget {
  final Widget child;
  final double bottom;
  const CeroHeader({super.key, required this.child, this.bottom = 22});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final wide = isWide(context);
    final box = Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: wide
            ? BorderRadius.circular(30)
            : const BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [Color(0x4738E0A8), Color(0x0038E0A8)]),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(wide ? 28 : 20, wide ? 26 : top + 14, wide ? 28 : 20, bottom),
            child: child,
          ),
        ],
      ),
    );
    if (!wide) return box;
    return Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 0), child: box);
  }
}

/// Botón redondo verde de la cabecera.
Widget circleBtn(IconData icon, VoidCallback? onTap, {String? label}) {
  return Semantics(
    button: true,
    label: label,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(color: mint, shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: const Color(0xFF04261B)),
      ),
    ),
  );
}

/// Botón redondo gris para "volver" sobre la cabecera.
Widget backBtn(BuildContext context) {
  return Semantics(
    button: true,
    label: 'Volver',
    child: GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(color: Color(0x24FFFFFF), shape: BoxShape.circle),
        child: const Icon(Ic.back, size: 24, color: Colors.white),
      ),
    ),
  );
}

/// Píldora para filtros sobre la cabecera negra.
Widget headPill(String label, bool on, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: on ? mint : Colors.transparent,
        border: on ? null : Border.all(color: const Color(0x47FFFFFF), width: 1.5),
        borderRadius: BorderRadius.circular(19),
      ),
      child: Text(label,
          style: hs(14, w: on ? FontWeight.w700 : FontWeight.w600, color: on ? const Color(0xFF04261B) : Colors.white)),
    ),
  );
}

/// Píldora con borde, sobre una tarjeta.
Widget outlineChip(Pal p, String label, {Color? dot, bool on = false, VoidCallback? onTap, Color? border}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: on ? mint : Colors.transparent,
        border: on ? null : Border.all(color: border ?? p.line, width: 1.5),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (dot != null) ...[
          Container(width: 9, height: 9, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 6),
        ],
        Text(label,
            style: ts(p, 12,
                w: FontWeight.w700, color: on ? const Color(0xFF04261B) : p.text)),
      ]),
    ),
  );
}

/// Cuadro con icono de color.
Widget iconTile(IconData icon, Color fg, Color bg, {double size = 42}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(size * 0.32),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [bg, bg.withValues(alpha: bg.a * 0.45)],
      ),
      border: Border.all(color: fg.withValues(alpha: 0.22), width: 1),
    ),
    child: Icon(icon, size: size * 0.5, color: fg),
  );
}

/// Casilla de "pagado".
Widget checkBox(Pal p, bool on, VoidCallback? onTap) {
  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: SizedBox(
      width: 40,
      height: 40,
      child: Center(
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: on ? mint : Colors.transparent,
            border: on ? null : Border.all(color: p.muted, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: on ? const Icon(Ic.check, size: 18, color: Color(0xFF04261B)) : null,
        ),
      ),
    ),
  );
}

/// Botón principal grande, de ancho completo.
Widget wideButton(Pal p, String label, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 54,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: p.cta, borderRadius: BorderRadius.circular(27)),
      child: Text(label, style: ts(p, 16, w: FontWeight.w700, color: p.onCta)),
    ),
  );
}

/// Abre una pantalla secundaria con botón de volver.
Route<void> subPage(Widget child) {
  return MaterialPageRoute<void>(
    builder: (context) {
      final p = Pal.of(context);
      return CeroPage(
        backgroundColor: p.bg,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: roundButton(p, Ic.back, () => Navigator.of(context).pop(),
                      label: 'Volver'),
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      );
    },
  );
}

/// Pantalla de computadora (ancho de tablet en horizontal o más).
bool isWide(BuildContext c) => MediaQuery.sizeOf(c).width >= 900;

/// En computadora centra el contenido con un ancho máximo.
Widget deskBody(BuildContext c, Widget child, {double max = 760}) {
  if (!isWide(c)) return child;
  return Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(constraints: BoxConstraints(maxWidth: max), child: child),
  );
}

/// Dos columnas en computadora; una sola, una debajo de otra, en el celular.
Widget twoCol(BuildContext context,
    {required List<Widget> left, required List<Widget> right, int leftFlex = 3, int rightFlex = 2}) {
  if (!isWide(context)) {
    return Column(children: [...left, const SizedBox(height: 16), ...right]);
  }
  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Expanded(flex: leftFlex, child: Column(children: left)),
    const SizedBox(width: 20),
    Expanded(flex: rightFlex, child: Column(children: right)),
  ]);
}

/// Página secundaria: en computadora queda centrada y no estirada.
class CeroPage extends StatelessWidget {
  final Color backgroundColor;
  final Widget body;
  const CeroPage({super.key, required this.backgroundColor, required this.body});

  @override
  Widget build(BuildContext context) =>
      Scaffold(backgroundColor: backgroundColor, body: deskBody(context, body));
}
