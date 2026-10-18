import 'package:flutter/material.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

class AgregarScreen extends StatefulWidget {
  const AgregarScreen({super.key});

  @override
  State<AgregarScreen> createState() => _AgregarScreenState();
}

class _AgregarScreenState extends State<AgregarScreen> {
  final name = TextEditingController();
  final balance = TextEditingController();
  final rate = TextEditingController();
  final cuota = TextEditingController();
  final day = TextEditingController();

  DebtKind kind = DebtKind.prestamista;
  Owner owner = Owner.tu;
  bool monthly = true;
  bool remind = true;

  @override
  void dispose() {
    name.dispose();
    balance.dispose();
    rate.dispose();
    cuota.dispose();
    day.dispose();
    super.dispose();
  }

  double? _num(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '').replaceAll(' ', ''));

  double? get _ratePct => _num(rate);

  void _save() {
    final b = _num(balance);
    final c = _num(cuota);
    final dd = int.tryParse(day.text.trim());
    final r = (_ratePct ?? 0) / 100;
    if (name.text.trim().isEmpty || b == null || b <= 0 || c == null || c <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Faltan el nombre, el saldo y la cuota.')));
      return;
    }
    final s = StoreScope.of(context);
    s.addDebt(Debt(
      id: 'd${DateTime.now().microsecondsSinceEpoch}',
      name: name.text.trim(),
      kind: kind,
      owner: owner,
      balance: b,
      rateKind: r <= 0 ? RateKind.ninguna : (monthly ? RateKind.mensual : RateKind.tea),
      rate: r,
      cuota: c,
      payDay: (dd ?? 1).clamp(1, 31).toInt(),
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final pctNow = _ratePct;
    String? warn;
    if (pctNow != null && pctNow > 0) {
      final m = monthly ? pctNow / 100 : 0.0;
      if (monthly && m >= 0.04) {
        final annual = (1 + m);
        double a = 1;
        for (var i = 0; i < 12; i++) {
          a *= annual;
        }
        warn = 'Tasa alta: equivale a ${((a - 1) * 100).toStringAsFixed(1)}% al año';
      } else if (!monthly && pctNow >= 60) {
        warn = 'Tasa alta: cuesta ${pctNow.toStringAsFixed(0)}% al año';
      }
    }

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Row(children: [
              Expanded(child: Text('Nueva deuda', style: ts(p, 32, w: FontWeight.w700, ls: -0.6))),
              roundButton(p, Icons.close, () => Navigator.of(context).pop(), label: 'Cerrar'),
            ]),
            const SizedBox(height: 16),
            _label(p, '¿A quién le debes?'),
            _field(p, name, TextInputType.text),
            const SizedBox(height: 14),
            _label(p, 'Tipo de deuda'),
            _seg<DebtKind>(p, const [DebtKind.banco, DebtKind.prestamista, DebtKind.tarjeta, DebtKind.cuota],
                (k) => k.label, kind, (k) => setState(() => kind = k)),
            const SizedBox(height: 14),
            _label(p, '¿De quién es esta deuda?'),
            _seg<Owner>(p, Owner.values, (o) => o.label, owner, (o) => setState(() => owner = o)),
            const SizedBox(height: 14),
            _label(p, 'Saldo pendiente (S/)'),
            _field(p, balance, const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 14),
            _label(p, 'Tasa de interés'),
            Row(children: [
              Expanded(
                  child: _field(p, rate, const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: p.card2, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  _toggleBtn(p, '% mensual', monthly, () => setState(() => monthly = true)),
                  const SizedBox(width: 4),
                  _toggleBtn(p, '% anual', !monthly, () => setState(() => monthly = false)),
                ]),
              ),
            ]),
            if (warn != null) ...[
              const SizedBox(height: 6),
              Text(warn, style: ts(p, 12, w: FontWeight.w700, color: p.red)),
            ],
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                flex: 14,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _label(p, 'Cuota mensual (S/)'),
                  _field(p, cuota, const TextInputType.numberWithOptions(decimal: true)),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 10,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _label(p, 'Día de pago'),
                  _field(p, day, TextInputType.number),
                ]),
              ),
            ]),
            const SizedBox(height: 14),
            panel(
              p,
              radius: 18,
              pad: EdgeInsets.zero,
              child: switchTile(p, 'Recordarme el pago',
                  'Aviso 3 días antes y el día del vencimiento', remind,
                  (v) => setState(() => remind = v)),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _save,
              child: Container(
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: p.pri, borderRadius: BorderRadius.circular(18)),
                child: Text('Guardar deuda', style: ts(p, 16, w: FontWeight.w700, color: p.onPri)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(Pal p, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: ts(p, 12, w: FontWeight.w600, color: p.muted)),
      );

  Widget _field(Pal p, TextEditingController c, TextInputType type,
      {ValueChanged<String>? onChanged}) {
    return TextField(
      controller: c,
      keyboardType: type,
      onChanged: onChanged,
      style: ts(p, 16, w: FontWeight.w600),
      cursorColor: p.pri,
      decoration: InputDecoration(
        filled: true,
        fillColor: p.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.line, width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.pri, width: 1.5)),
      ),
    );
  }

  Widget _toggleBtn(Pal p, String t, bool on, VoidCallback f) => GestureDetector(
        onTap: f,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: on ? p.text : Colors.transparent, borderRadius: BorderRadius.circular(11)),
          child: Text(t,
              style: ts(p, 13,
                  w: on ? FontWeight.w700 : FontWeight.w600, color: on ? p.bg : p.muted)),
        ),
      );

  Widget _seg<T>(Pal p, List<T> items, String Function(T) label, T sel, ValueChanged<T> on) {
    return Row(children: [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => on(items[i]),
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: items[i] == sel ? p.pri : p.card,
                border: Border.all(color: items[i] == sel ? p.pri : p.line, width: 1.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(label(items[i]),
                  style: ts(p, 12,
                      w: items[i] == sel ? FontWeight.w700 : FontWeight.w600,
                      color: items[i] == sel ? p.onPri : p.text)),
            ),
          ),
        ),
      ],
    ]);
  }
}
