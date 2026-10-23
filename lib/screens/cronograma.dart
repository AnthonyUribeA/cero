import 'package:flutter/material.dart';
import '../format.dart';
import '../loan.dart';
import '../theme.dart';
import '../widgets.dart';

/// Simulador mes a mes: muestra cuota, interés, capital y saldo, y deja
/// adelantar capital en cualquier mes. Devuelve los adelantos al aplicar.
class CronogramaScreen extends StatefulWidget {
  final String title;
  final double balance;
  final double rate; // mensual
  final int method;
  final double? cuota;
  final int? term;
  final Map<int, double> extras;
  final int startYm; // año * 12 + mes - 1 del primer pago
  final String applyLabel;

  const CronogramaScreen({
    super.key,
    required this.title,
    required this.balance,
    required this.rate,
    required this.method,
    required this.startYm,
    this.cuota,
    this.term,
    this.extras = const {},
    this.applyLabel = 'Aplicar a mi plan',
  });

  @override
  State<CronogramaScreen> createState() => _CronogramaScreenState();
}

class _CronogramaScreenState extends State<CronogramaScreen> {
  late Map<int, double> extras = Map<int, double>.from(widget.extras);

  List<SchedRow> _rows(Map<int, double> ex) => buildSchedule(
        balance: widget.balance,
        r: widget.rate,
        method: widget.method,
        cuota: widget.cuota,
        term: widget.term,
        extras: ex,
      );

  String _month(int i) {
    final ym = widget.startYm + i;
    return '${monthsShort[ym % 12]} ${ym ~/ 12}';
  }

  String _m(double v) => v.abs() >= 1000 ? money(v) : 'S/ ${v.toStringAsFixed(2)}';

  Future<void> _edit(int i, double maxExtra) async {
    final c = TextEditingController(text: extras[i] == null ? '' : extras[i]!.toStringAsFixed(0));
    final p = Pal.of(context);
    final res = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Adelantar capital en ${_month(i)}', style: ts(p, 18, w: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Además de la cuota de ese mes. Puedes adelantar hasta ${_m(maxExtra)}.',
              style: ts(p, 13, color: p.muted, h: 1.4)),
          const SizedBox(height: 12),
          TextField(
            controller: c,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: ts(p, 20, w: FontWeight.w700),
            cursorColor: p.green,
            decoration: InputDecoration(
              prefixText: 'S/ ',
              prefixStyle: ts(p, 20, w: FontWeight.w700, color: p.muted),
              hintText: 'Ej. 500',
              hintStyle: ts(p, 20, color: p.muted.withValues(alpha: 0.55)),
              border: InputBorder.none,
            ),
          ),
        ]),
        actions: [
          if (extras.containsKey(i))
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(0),
              child: Text('Quitar', style: ts(p, 14, w: FontWeight.w700, color: p.red)),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancelar', style: ts(p, 14, w: FontWeight.w700, color: p.muted)),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(double.tryParse(c.text.trim().replaceAll(',', '')) ?? 0),
            child: Text('Listo', style: ts(p, 14, w: FontWeight.w700, color: p.green)),
          ),
        ],
      ),
    );
    c.dispose();
    if (res == null) return;
    setState(() {
      if (res <= 0) {
        extras.remove(i);
      } else {
        extras[i] = res;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final rows = _rows(extras);
    final base = _rows(const {});
    final interest = scheduleInterest(rows);
    final baseInterest = scheduleInterest(base);
    final saved = baseInterest - interest;
    final fewer = base.length - rows.length;
    final totalExtra = extras.values.fold(0.0, (t, v) => t + v);
    final changed = extras.isNotEmpty;

    Widget kv(String k, String v, {Color? c}) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(k, style: hs(13, color: const Color(0xB3FFFFFF))),
            Text(v, style: hs(14, w: FontWeight.w700, color: c ?? Colors.white)),
          ]),
        );

    return CeroPage(
      backgroundColor: p.bg,
      body: Column(children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              CeroHeader(
                bottom: 24,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    backBtn(context),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Cronograma', style: hs(24, w: FontWeight.w600, ls: -0.4)),
                        Text('${widget.title} · ${payMethodNames[widget.method]}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: hs(13, color: const Color(0xB3FFFFFF))),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  Text('Terminas en ${_month(rows.isEmpty ? 0 : rows.length - 1)}',
                      style: hs(26, w: FontWeight.w700, ls: -0.5)),
                  kv('Meses', '${rows.length}'),
                  kv('Interés total', _m(interest), c: const Color(0xFFFF9F9F)),
                  if (changed) ...[
                    kv('Adelantas en total', _m(totalExtra), c: mint),
                    kv('Ahorras de interés', _m(saved), c: mint),
                    if (fewer > 0) kv('Terminas antes', '$fewer ${fewer == 1 ? 'mes' : 'meses'}', c: mint),
                  ],
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Text('Toca "+ capital" en un mes para pagar más ese mes.',
                    style: ts(p, 12, w: FontWeight.w600, color: p.muted)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: panel(
                  p,
                  radius: 24,
                  pad: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                  child: Column(children: [
                    Row(children: [
                      SizedBox(width: 62, child: Text('Mes', style: ts(p, 11, w: FontWeight.w700, color: p.muted))),
                      Expanded(child: Text('Pagas', textAlign: TextAlign.right, style: ts(p, 11, w: FontWeight.w700, color: p.muted))),
                      Expanded(child: Text('Interés', textAlign: TextAlign.right, style: ts(p, 11, w: FontWeight.w700, color: p.muted))),
                      Expanded(child: Text('Debes', textAlign: TextAlign.right, style: ts(p, 11, w: FontWeight.w700, color: p.muted))),
                      const SizedBox(width: 74),
                    ]),
                    for (final r in rows) ...[
                      const SizedBox(height: 6),
                      divider(p),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(children: [
                          SizedBox(
                            width: 62,
                            child: Text(_month(r.i), style: ts(p, 12, w: FontWeight.w700)),
                          ),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text(_m(r.pay), style: ts(p, 13, w: FontWeight.w700, tab: true)),
                              Text('capital ${_m(r.capital + r.extra)}',
                                  style: ts(p, 10, color: p.green)),
                            ]),
                          ),
                          Expanded(
                            child: Text(_m(r.interest),
                                textAlign: TextAlign.right,
                                style: ts(p, 13, w: FontWeight.w600, tab: true, color: p.red)),
                          ),
                          Expanded(
                            child: Text(_m(r.remaining),
                                textAlign: TextAlign.right, style: ts(p, 13, w: FontWeight.w600, tab: true)),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              final before = r.remaining + r.extra;
                              _edit(r.i, before);
                            },
                            child: Container(
                              width: 68,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: r.extra > 0 ? mint : Colors.transparent,
                                border: r.extra > 0 ? null : Border.all(color: p.line, width: 1.5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(r.extra > 0 ? '+${r.extra.toStringAsFixed(0)}' : '+ capital',
                                  style: ts(p, 11,
                                      w: FontWeight.w700,
                                      color: r.extra > 0 ? const Color(0xFF04261B) : p.text)),
                            ),
                          ),
                        ]),
                      ),
                    ],
                  ]),
                ),
              ),
            ],
          ),
        ),
        Container(
          color: p.bg,
          padding: EdgeInsets.fromLTRB(20, 10, 20, 16 + MediaQuery.of(context).padding.bottom),
          child: wideButton(p, widget.applyLabel, () => Navigator.of(context).pop(extras)),
        ),
      ]),
    );
  }
}
