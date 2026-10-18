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
