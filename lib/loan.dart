import 'dart:math' as math;

/// Cuota fija para pagar [p] en [n] meses con tasa mensual [r] (capital + interés).
double amortCuota(double p, double r, int n) {
  if (n <= 0) return p;
  if (r <= 0) return p / n;
  return p * r / (1 - math.pow(1 + r, -n).toDouble());
}

/// Meses para pagar [p] con cuota [c] y tasa mensual [r]. Devuelve -1 si la cuota
/// no alcanza ni para el interés (la deuda nunca baja).
int monthsToPay(double p, double r, double c) {
  if (p <= 0) return 0;
  if (c <= 0) return -1;
  if (r <= 0) return (p / c).ceil();
  if (c <= p * r + 0.005) return -1;
  final n = -math.log(1 - p * r / c) / math.log(1 + r);
  return (n - 1e-9).ceil();
}

/// Lo que se debe después de pagar [k] cuotas de un préstamo de [p] a [n] meses.
double balanceAfter(double p, double r, int n, int k) {
  if (k >= n) return 0;
  final c = amortCuota(p, r, n);
  if (r <= 0) return p - c * k;
  final remaining = n - k;
  return c * (1 - math.pow(1 + r, -remaining).toDouble()) / r;
}

/// Tasa mensual implícita de un préstamo de [p] con [n] cuotas de [c].
/// Es la que usa el banco aunque no la diga (incluye seguros y comisiones).
double impliedRate(double p, double c, int n) {
  if (p <= 0 || c <= 0 || n <= 0) return 0;
  if (c * n <= p + 0.005) return 0;
  var lo = 0.0, hi = 1.0;
  for (var i = 0; i < 100; i++) {
    final mid = (lo + hi) / 2;
    if (amortCuota(p, mid, n) > c) {
      hi = mid;
    } else {
      lo = mid;
    }
  }
  return (lo + hi) / 2;
}

/// Tasa anual equivalente (TEA) de una tasa mensual.
double teaOf(double monthly) => math.pow(1 + monthly, 12).toDouble() - 1;

/// Tasa mensual equivalente de una TEA.
double monthlyOf(double tea) => math.pow(1 + tea, 1 / 12).toDouble() - 1;

/// Forma de pago de un préstamo.
/// 0: cuota fija (lo mismo cada mes). 1: capital fijo (bajas lo mismo de capital
/// y el interés va bajando). 2: solo interés, y el capital al final.
const payMethodNames = ['Cuota fija', 'Capital fijo', 'Solo interés'];

/// Una fila del cronograma.
class SchedRow {
  final int i; // 0 = primer mes
  final double pay; // lo que pagas ese mes (incluye el adelanto)
  final double interest;
  final double capital; // capital normal de la cuota
  final double extra; // capital adelantado ese mes
  final double remaining;
  const SchedRow(this.i, this.pay, this.interest, this.capital, this.extra, this.remaining);
}

/// Cronograma mes a mes. [extras] son adelantos de capital por mes (0 = primer mes).
/// Con cuota fija, un adelanto mantiene la cuota y acorta el plazo.
List<SchedRow> buildSchedule({
  required double balance,
  required double r,
  required int method,
  double? cuota,
  int? term,
  Map<int, double> extras = const {},
}) {
  final rows = <SchedRow>[];
  var bal = balance;
  final n = (term == null || term <= 0) ? null : term;
  double c;
  if (method == 0) {
    c = (cuota != null && cuota > 0) ? cuota : amortCuota(balance, r, n ?? 12);
  } else {
    c = 0;
  }
  final capPer = method == 1 ? balance / (n ?? 12) : 0.0;
  for (var k = 0; k < 600 && bal > 0.005; k++) {
    final i = bal * r;
    double base;
    switch (method) {
      case 1:
        base = math.min(capPer, bal) + i;
        break;
      case 2:
        base = (n != null && k >= n - 1) ? bal + i : i;
        break;
      default:
        base = math.min(c, bal + i);
    }
    // Si la cuota no cubre ni el interés y no hay adelantos, no termina nunca.
    final cap = base - i;
    final ex = math.min(math.max(extras[k] ?? 0, 0).toDouble(), math.max(bal - cap, 0).toDouble());
    bal = bal - cap - ex;
    if (bal < 0.005) bal = 0;
    rows.add(SchedRow(k, base + ex, i, cap, ex, bal));
    if (method == 0 && cap <= 0 && ex <= 0 && k > 0 && rows.length > 240) break;
  }
  return rows;
}

double scheduleInterest(List<SchedRow> rows) => rows.fold(0.0, (t, x) => t + x.interest);
