import 'package:flutter/material.dart';
import '../format.dart';
import '../icons.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

/// Abre la hoja para anotar un ingreso extra.
void showIncomeSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const IncomeSheet(),
  );
}

/// Campo de texto que guarda al terminar de escribir.
class _EditField extends StatefulWidget {
  final String initial;
  final String hint;
  final bool numeric;
  final ValueChanged<String> onDone;
  final TextStyle style;
  const _EditField({
    super.key,
    required this.initial,
    required this.hint,
    required this.onDone,
    required this.style,
    this.numeric = false,
  });

  @override
  State<_EditField> createState() => _EditFieldState();
}

class _EditFieldState extends State<_EditField> {
  late final c = TextEditingController(text: widget.initial);
  final f = FocusNode();

  @override
  void initState() {
    super.initState();
    f.addListener(() {
      if (!f.hasFocus) widget.onDone(c.text);
    });
  }

  @override
  void dispose() {
    c.dispose();
    f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return TextField(
      controller: c,
      focusNode: f,
      style: widget.style,
      cursorColor: p.green,
      keyboardType: widget.numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      textCapitalization: widget.numeric ? TextCapitalization.none : TextCapitalization.words,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: widget.style.copyWith(color: p.muted.withValues(alpha: 0.55)),
        isCollapsed: true,
        border: InputBorder.none,
      ),
      onSubmitted: widget.onDone,
    );
  }
}

class IngresosScreen extends StatelessWidget {
  const IngresosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final s = StoreScope.of(context);
    final extras = s.incomes.where((i) => i.date.year == s.now.year && i.date.month == s.now.month).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    double parse(String v) => double.tryParse(v.replaceAll(',', '').replaceAll(' ', '')) ?? 0;

    Widget box(Widget child) => Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: p.card2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.line),
          ),
          child: child,
        );

    return CeroPage(
      backgroundColor: p.bg,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          CeroHeader(
            bottom: 24,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                backBtn(context),
                const SizedBox(width: 12),
                Text('Ingresos', style: hs(26, w: FontWeight.w600, ls: -0.5)),
              ]),
              const SizedBox(height: 16),
              Text('Entra este mes', style: hs(13, color: const Color(0xB3FFFFFF))),
              Text(money(s.incomeMonth), style: hs(40, w: FontWeight.w700, ls: -1)),
              Text('Sueldos ${money(s.totalIncome)} · extras ${money(s.extraIncomeMonth)}',
                  style: hs(13, w: FontWeight.w600, color: mint)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              panel(
                p,
                radius: 26,
                pad: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    iconTile(Ic.user, p.green, p.okBg, size: 36),
                    const SizedBox(width: 10),
                    Text('Tu nombre', style: ts(p, 15, w: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 10),
                  box(_EditField(
                    initial: s.userName,
                    hint: 'Cómo quieres que te salude la app',
                    style: ts(p, 16, w: FontWeight.w600),
                    onDone: s.setUserName,
                  )),
                ]),
              ),
              const SizedBox(height: 14),
              panel(
                p,
                radius: 26,
                pad: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Sueldos de cada mes', style: ts(p, 17, w: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Escribe el nombre y lo que gana cada uno. Si es solo tu sueldo, deja los otros en 0.',
                      style: ts(p, 12, color: p.muted, h: 1.4)),
                  for (var i = 0; i < s.people.length; i++) ...[
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(
                        flex: 5,
                        child: box(_EditField(
                          key: ValueKey('n$i${s.people[i].name}'),
                          initial: s.people[i].name,
                          hint: 'Nombre',
                          style: ts(p, 15, w: FontWeight.w600),
                          onDone: (v) => s.setPersonName(i, v),
                        )),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 4,
                        child: box(Row(children: [
                          Text('S/ ', style: ts(p, 15, w: FontWeight.w700, color: p.muted)),
                          Expanded(
                            child: _EditField(
                              key: ValueKey('i$i${s.people[i].income}'),
                              initial: s.people[i].income > 0 ? s.people[i].income.toStringAsFixed(0) : '',
                              hint: '0',
                              numeric: true,
                              style: ts(p, 15, w: FontWeight.w700),
                              onDone: (v) => s.setIncome(i, parse(v)),
                            ),
                          ),
                        ])),
                      ),
                    ]),
                  ],
                ]),
              ),
              const SizedBox(height: 14),
              panel(
                p,
                radius: 26,
                pad: const EdgeInsets.fromLTRB(18, 16, 10, 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Extras de ${monthsLong[s.now.month - 1]}', style: ts(p, 17, w: FontWeight.w600)),
                  if (extras.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('Aportes de familia, trabajos aparte, bonos...', style: ts(p, 13, color: p.muted)),
                    ),
                  for (final i in extras)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(i.label, style: ts(p, 15, w: FontWeight.w700)),
                            Text('${dueShort(i.date)} · ${i.tag}', style: ts(p, 12, color: p.muted)),
                          ]),
                        ),
                        Text('+${money(i.amount)}', style: ts(p, 15, w: FontWeight.w600, color: p.green, tab: true)),
                        GestureDetector(
                          onTap: () => s.removeIncome(i.id),
                          behavior: HitTestBehavior.opaque,
                          child: SizedBox(width: 36, height: 30, child: Icon(Ic.close, size: 16, color: p.muted)),
                        ),
                      ]),
                    ),
                ]),
              ),
              const SizedBox(height: 14),
              wideButton(p, 'Agregar ingreso extra', () => showIncomeSheet(context)),
            ]),
          ),
        ],
      ),
    );
  }
}

class IncomeSheet extends StatefulWidget {
  const IncomeSheet({super.key});

  @override
  State<IncomeSheet> createState() => _IncomeSheetState();
}

class _IncomeSheetState extends State<IncomeSheet> {
  final labelC = TextEditingController();
  final amountC = TextEditingController();
  String tag = 'Extra';
  String? error;

  @override
  void dispose() {
    labelC.dispose();
    amountC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final s = StoreScope.of(context);
    InputDecoration deco(String hint) => InputDecoration(
          hintText: hint,
          hintStyle: ts(p, 16, color: p.muted),
          isCollapsed: true,
          border: InputBorder.none,
        );
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Ingreso extra', style: ts(p, 20, w: FontWeight.w700)),
          const SizedBox(height: 14),
          Text('Qué fue', style: ts(p, 12, w: FontWeight.w600, color: p.muted)),
          const SizedBox(height: 6),
          TextField(
            controller: labelC,
            style: ts(p, 16, w: FontWeight.w600),
            cursorColor: p.green,
            textCapitalization: TextCapitalization.sentences,
            decoration: deco('Aporte de mamá, trabajo extra...'),
          ),
          const SizedBox(height: 10),
          divider(p),
          const SizedBox(height: 12),
          Text('Monto', style: ts(p, 12, w: FontWeight.w600, color: p.muted)),
          const SizedBox(height: 6),
          TextField(
            controller: amountC,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: ts(p, 22, w: FontWeight.w700),
            cursorColor: p.green,
            decoration: deco('S/ 0.00'),
          ),
          const SizedBox(height: 10),
          divider(p),
          const SizedBox(height: 12),
          Row(children: [
            for (final t in const ['Extra', 'Familia']) ...[
              outlineChip(p, t, on: tag == t, onTap: () => setState(() => tag = t)),
              const SizedBox(width: 8),
            ],
          ]),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error!, style: ts(p, 12, w: FontWeight.w700, color: p.red)),
          ],
          const SizedBox(height: 16),
          wideButton(p, 'Guardar ingreso', () {
            final a = double.tryParse(amountC.text.trim().replaceAll(',', '.'));
            if (a == null || a <= 0) {
              setState(() => error = 'Pon un monto mayor que cero');
              return;
            }
            final l = labelC.text.trim();
            s.addIncome(IncomeItem(
              id: 'i${DateTime.now().microsecondsSinceEpoch}',
              label: l.isEmpty ? tag : l,
              amount: a,
              date: DateTime(s.now.year, s.now.month, s.now.day),
              tag: tag,
            ));
            Navigator.of(context).pop();
          }),
        ]),
      ),
    );
  }
}
