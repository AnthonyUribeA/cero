import 'package:flutter/material.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

class AgregarGastoScreen extends StatefulWidget {
  /// 0 fijo, 1 variable, 2 hormiga.
  final int initialKind;
  const AgregarGastoScreen({super.key, this.initialKind = 2});

  @override
  State<AgregarGastoScreen> createState() => _AgregarGastoScreenState();
}

class _AgregarGastoScreenState extends State<AgregarGastoScreen> {
  late int kind = widget.initialKind;
  final amountC = TextEditingController();
  final noteC = TextEditingController();
  int day = 1;
  int daysAgo = 0;
  String? category;
  String method = 'Yape';
  String? error;

  @override
  void dispose() {
    amountC.dispose();
    noteC.dispose();
    super.dispose();
  }

  List<String> get cats => kind == 1 ? variableCats : hormigaCats;

  void _save(AppStore s) {
    final amount = double.tryParse(amountC.text.trim().replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      setState(() => error = 'Pon un monto mayor que cero');
      return;
    }
    final id = 'x${DateTime.now().microsecondsSinceEpoch}';
    final note = noteC.text.trim();
    if (kind == 0) {
      s.addFixed(FixedBill(id: id, name: note.isEmpty ? 'Gasto fijo' : note, amount: amount, day: day));
    } else {
      final cat = category ?? cats.first;
      final today = DateTime(s.now.year, s.now.month, s.now.day);
      s.addExpense(Expense(
        id: id,
        kind: kind == 1 ? ExpenseKind.variable : ExpenseKind.hormiga,
        category: cat,
        note: note.isEmpty ? cat : note,
        amount: amount,
        date: today.subtract(Duration(days: daysAgo)),
        method: method,
      ));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final s = StoreScope.of(context);
    const kinds = ['Fijo', 'Variable', 'Hormiga'];
    final cat = category ?? cats.first;

    Widget label(String t) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(t, style: ts(p, 12, w: FontWeight.w600, color: p.muted)),
        );

    InputDecoration deco(String hint) => InputDecoration(
          hintText: hint,
          hintStyle: ts(p, 16, color: p.muted),
          isCollapsed: true,
          border: InputBorder.none,
        );

    return Scaffold(
      backgroundColor: p.bg,
      body: Column(children: [
        CeroHeader(
          bottom: 24,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              backBtn(context),
              const SizedBox(width: 12),
              Text('Agregar gasto', style: hs(24, w: FontWeight.w600)),
            ]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                  color: const Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(24)),
              child: Row(children: [
                for (var i = 0; i < kinds.length; i++)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        kind = i;
                        category = null;
                      }),
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: i == kind ? mint : Colors.transparent,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(kinds[i],
                            style: hs(14,
                                w: FontWeight.w700,
                                color: i == kind ? const Color(0xFF04261B) : Colors.white)),
                      ),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 18),
            Text('Monto', style: hs(13, w: FontWeight.w600, color: const Color(0xB3FFFFFF))),
            Row(children: [
              Text('S/ ', style: hs(40, w: FontWeight.w700, ls: -1)),
              Expanded(
                child: TextField(
                  controller: amountC,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  cursorColor: mint,
                  style: hs(40, w: FontWeight.w700, ls: -1),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: hs(40, w: FontWeight.w700, color: const Color(0x66FFFFFF)),
                    isCollapsed: true,
                    border: InputBorder.none,
                  ),
                  onChanged: (_) {
                    if (error != null) setState(() => error = null);
                  },
                ),
              ),
            ]),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(error!, style: hs(12, w: FontWeight.w700, color: const Color(0xFFFF9F9F))),
              ),
          ]),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              panel(
                p,
                radius: 26,
                pad: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  label(kind == 0 ? 'Nombre' : 'Descripción'),
                  TextField(
                    controller: noteC,
                    style: ts(p, 16, w: FontWeight.w600),
                    cursorColor: p.green,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: deco(kind == 0 ? 'Alquiler, luz, agua...' : 'Café con leche'),
                  ),
                  const SizedBox(height: 12),
                  divider(p),
                  const SizedBox(height: 14),
                  if (kind == 0) ...[
                    label('Se paga el día'),
                    stepper(p,
                        value: 'Día $day',
                        width: 100,
                        onLess: day > 1 ? () => setState(() => day--) : null,
                        onMore: day < 31 ? () => setState(() => day++) : null,
                        lessLabel: 'Día anterior',
                        moreLabel: 'Día siguiente'),
                    const SizedBox(height: 10),
                    Text('Se repite todos los meses y te avisamos antes de que venza.',
                        style: ts(p, 12, color: p.muted, h: 1.4)),
                  ] else ...[
                    label('Categoría'),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final c in cats)
                        outlineChip(p, c, on: c == cat, onTap: () => setState(() => category = c)),
                    ]),
                    const SizedBox(height: 16),
                    label('Fecha'),
                    Row(children: [
                      outlineChip(p, 'Hoy', on: daysAgo == 0, onTap: () => setState(() => daysAgo = 0)),
                      const SizedBox(width: 8),
                      outlineChip(p, 'Ayer', on: daysAgo == 1, onTap: () => setState(() => daysAgo = 1)),
                      const SizedBox(width: 8),
                      outlineChip(p, 'Anteayer', on: daysAgo == 2, onTap: () => setState(() => daysAgo = 2)),
                    ]),
                    const SizedBox(height: 16),
                    label('Pagado con'),
                    Row(children: [
                      for (final m in payMethods) ...[
                        outlineChip(p, m, on: m == method, onTap: () => setState(() => method = m)),
                        const SizedBox(width: 8),
                      ],
                    ]),
                  ],
                ]),
              ),
              const SizedBox(height: 16),
              wideButton(p, kind == 0 ? 'Guardar gasto fijo' : 'Guardar gasto', () => _save(s)),
            ],
          ),
        ),
      ]),
    );
  }
}
