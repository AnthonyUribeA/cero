import 'package:flutter/material.dart';
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
          color: primary ? p.pri : (enabled ? p.card2 : p.card),
          borderRadius: BorderRadius.circular(primary ? 22 : 14),
        ),
        child: Icon(icon,
            size: 20,
            color: primary ? p.onPri : (enabled ? p.text : p.muted.withValues(alpha: 0.5))),
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
      roundButton(p, Icons.remove, onLess, label: lessLabel),
      SizedBox(
        width: width,
        child: Text(value,
            textAlign: TextAlign.center, style: ts(p, 18, w: FontWeight.w700, tab: true)),
      ),
      roundButton(p, Icons.add, onMore, label: moreLabel),
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
          color: outline ? Colors.transparent : p.pri,
          border: outline ? Border.all(color: p.pri, width: 2) : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label,
            style: ts(p, 16, w: FontWeight.w700, color: outline ? p.pri : p.onPri)),
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
