import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'format.dart';
import 'models.dart';
import 'store.dart';

CellValue _t(String s) => TextCellValue(s);
CellValue _n(num v) => DoubleCellValue(v.toDouble());

/// Arma el Excel con cuatro hojas: Resumen, Deudas, Aportes y Calendario.
List<int>? buildWorkbook(AppStore s) {
  final x = Excel.createExcel();
  x.rename('Sheet1', 'Resumen');

  final head = CellStyle(
    bold: true,
    fontColorHex: ExcelColor.fromHexString('#FFFFFFFF'),
    backgroundColorHex: ExcelColor.fromHexString('#FF2A66E0'),
  );
  final bold = CellStyle(bold: true);

  void styleRow(Sheet sh, int row, int cols, CellStyle st) {
    for (var c = 0; c < cols; c++) {
      sh.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row)).cellStyle = st;
    }
  }

  final plan = s.plan;
  final income = s.totalIncome;
  final cuotas = s.totalCuotas;
  final now = s.now;
  final fecha = '${now.day} ${monthsLong[now.month - 1]} ${now.year}';

  // 1. Resumen
  final r = x['Resumen'];
  r.appendRow([_t('Cero · resumen de deudas'), _t('')]);
  styleRow(r, 0, 2, head);
  final resumen = <List<CellValue>>[
    [_t('Generado el'), _t(fecha)],
    [_t('Deuda total (S/)'), _n(s.totalDebt.round())],
    [_t('Cuotas del mes (S/)'), _n(cuotas.round())],
    [_t('Ingreso de todos (S/)'), _n(income.round())],
    [_t('Porcentaje del ingreso que va a deudas (%)'), _n(income > 0 ? (cuotas / income * 100).round() : 0)],
    [_t('Les queda para vivir (S/)'), _n((income - cuotas).round())],
    [_t('Intereses del primer mes (S/)'), _n(s.totalInterest.round())],
    [_t('Estrategia'), _t(s.strategy == Strategy.avalancha ? 'Más intereses primero' : 'La más chica primero')],
    [_t('Extra mensual en el plan (S/)'), _n(s.extra.round())],
    [_t('Libres de deudas en'), _t(monthLabel(s.startMonth, plan.months, long: true))],
    [_t('Meses que faltan'), _n(plan.months)],
    [_t('Intereses totales del plan (S/)'), _n(plan.interest)],
  ];
  for (final row in resumen) {
    r.appendRow(row);
  }
  r.setColumnWidth(0, 46);
  r.setColumnWidth(1, 28);

  // 2. Deudas
  final d = x['Deudas'];
  d.appendRow([
    _t('Deuda'), _t('Tipo'), _t('Dueño'), _t('Saldo (S/)'), _t('Tasa'),
    _t('Equivale al año (%)'), _t('Cuota (S/)'), _t('Día de pago'),
    _t('Termina'), _t('Intereses que faltan (S/)'),
  ]);
  styleRow(d, 0, 10, head);
  final ordered = [...s.debts]..sort((a, b) => b.annualRate.compareTo(a.annualRate));
  for (final debt in ordered) {
    final fin = plan.close[debt.id] ?? plan.months;
    d.appendRow([
      _t(debt.name),
      _t(debt.kind.label),
      _t(debt.owner.label),
      _n(debt.balance.round()),
      _t(debt.rateLabel),
      _n((debt.annualRate * 100 * 10).round() / 10),
      _n(debt.cuota.round()),
      _n(debt.payDay),
      _t(monthLabel(s.startMonth, fin)),
      _n(plan.interestBy[debt.id] ?? 0),
    ]);
  }
  final last = ordered.length + 1;
  d.appendRow([
    _t('TOTAL'), _t(''), _t(''),
    FormulaCellValue('SUM(D2:D$last)'),
    _t(''), _t(''),
    FormulaCellValue('SUM(G2:G$last)'),
    _t(''), _t(''),
    FormulaCellValue('SUM(J2:J$last)'),
  ]);
  styleRow(d, last, 10, bold);
  const widths = [24.0, 14.0, 12.0, 14.0, 14.0, 18.0, 12.0, 12.0, 14.0, 24.0];
  for (var c = 0; c < widths.length; c++) {
    d.setColumnWidth(c, widths[c]);
  }

  // 3. Aportes
  final a = x['Aportes'];
  a.appendRow([
    _t('Persona'), _t('Ingreso (S/)'), _t('Aporta a las cuotas (S/)'),
    _t('Le queda para vivir (S/)'), _t('Parte del ingreso total (%)'),
  ]);
  styleRow(a, 0, 5, head);
  final aportes = s.contributions(cuotas);
  for (var i = 0; i < s.people.length; i++) {
    final p = s.people[i];
    a.appendRow([
      _t(p.name),
      _n(p.income.round()),
      _n(aportes[i].round()),
      _n((p.income - aportes[i]).round()),
      _n(income > 0 ? (p.income / income * 100).round() : 0),
    ]);
  }
  final lastA = s.people.length + 1;
  a.appendRow([
    _t('TOTAL'),
    FormulaCellValue('SUM(B2:B$lastA)'),
    FormulaCellValue('SUM(C2:C$lastA)'),
    FormulaCellValue('SUM(D2:D$lastA)'),
    _t(''),
  ]);
  styleRow(a, lastA, 5, bold);
  const wa = [18.0, 16.0, 26.0, 26.0, 28.0];
  for (var c = 0; c < wa.length; c++) {
    a.setColumnWidth(c, wa[c]);
  }

  // 4. Calendario
  final c = x['Calendario'];
  c.appendRow([_t('Mes'), _t('Pagan (S/)'), _t('De eso, intereses (S/)'), _t('Deuda que queda (S/)')]);
  styleRow(c, 0, 4, head);
  for (final m in plan.rows) {
    c.appendRow([
      _t(monthLabel(s.startMonth, m.month, long: true)),
      _n(m.payment.round()),
      _n(m.interest.round()),
      _n(m.remaining.round()),
    ]);
  }
  const wc = [24.0, 16.0, 24.0, 24.0];
  for (var i = 0; i < wc.length; i++) {
    c.setColumnWidth(i, wc[i]);
  }

  return x.encode();
}

/// Guarda el Excel y abre el menú de compartir del teléfono.
Future<void> exportExcel(BuildContext context, AppStore s) async {
  final messenger = ScaffoldMessenger.of(context);
  if (kIsWeb) {
    messenger.showSnackBar(const SnackBar(
        content: Text('El Excel se exporta desde la app del teléfono. En la versión web todavía no.')));
    return;
  }
  try {
    final bytes = buildWorkbook(s);
    if (bytes == null) {
      messenger.showSnackBar(const SnackBar(content: Text('No se pudo armar el Excel.')));
      return;
    }
    final dir = await getTemporaryDirectory();
    final n = s.now;
    final name = 'Cero-deudas-${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}.xlsx';
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles(
      [
        XFile(file.path,
            mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
      ],
      subject: 'Cero · mis deudas',
    );
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('No se pudo exportar: $e')));
  }
}
