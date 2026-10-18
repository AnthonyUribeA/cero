import 'dart:math' as math;

String money(num n) {
  final neg = n < 0;
  final s = n.abs().round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return '${neg ? '−' : ''}S/ $b';
}

const monthsShort = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
];
const monthsLong = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
];
const weekdays = [
  'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'
];

/// Mes número [m] (1 = el mes de [start]).
String monthLabel(DateTime start, int m, {bool long = false}) {
  final idx = (start.month - 1) + (m - 1);
  final y = start.year + idx ~/ 12;
  final mo = idx % 12;
  return long ? '${monthsLong[mo]} de $y' : '${monthsShort[mo]} $y';
}

int daysInMonth(int y, int m) => DateTime(y, m + 1, 0).day;

/// Próxima fecha de pago para un día del mes.
DateTime nextDue(int payDay, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  var y = now.year;
  var m = now.month;
  var dt = DateTime(y, m, math.min(payDay, daysInMonth(y, m)));
  if (dt.isBefore(today)) {
    m += 1;
    if (m > 12) {
      m = 1;
      y += 1;
    }
    dt = DateTime(y, m, math.min(payDay, daysInMonth(y, m)));
  }
  return dt;
}

String dueLong(DateTime d) =>
    '${_cap(weekdays[d.weekday - 1])} ${d.day} de ${monthsLong[d.month - 1]}';

String dueShort(DateTime d) => '${d.day} ${monthsShort[d.month - 1]}';

String _cap(String s) => s[0].toUpperCase() + s.substring(1);

int daysUntil(DateTime d, DateTime now) =>
    d.difference(DateTime(now.year, now.month, now.day)).inDays;

String inDays(int n) {
  if (n == 0) return 'hoy';
  if (n == 1) return 'mañana';
  return 'en $n días';
}
