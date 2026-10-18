import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import 'root.dart';

class CeroMark extends StatelessWidget {
  final double size;
  const CeroMark({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return CustomPaint(size: Size(size, size), painter: _MarkPainter(p));
  }
}

class _MarkPainter extends CustomPainter {
  final Pal p;
  _MarkPainter(this.p);

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 120;
    final ring = Paint()
      ..color = p.pri
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12 * k;
    canvas.drawCircle(Offset(60 * k, 60 * k), 32 * k, ring);
    final tick = Paint()
      ..color = p.greenFill
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10 * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(46 * k, 61 * k)
      ..lineTo(56 * k, 71 * k)
      ..lineTo(76 * k, 49 * k);
    canvas.drawPath(path, tick);
  }

  @override
  bool shouldRepaint(covariant _MarkPainter old) => old.p != p;
}

class ArranqueScreen extends StatefulWidget {
  const ArranqueScreen({super.key});

  @override
  State<ArranqueScreen> createState() => _ArranqueScreenState();
}

class _ArranqueScreenState extends State<ArranqueScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const RootShell(),
          transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CeroMark(),
                    const SizedBox(height: 18),
                    Text('Cero', style: ts(p, 44, w: FontWeight.w700, ls: -1.2)),
                    const SizedBox(height: 8),
                    Text('Sal de tus deudas, poco a poco', style: ts(p, 15, color: p.muted)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Text('Hecho por A. Uribe',
                  style: ts(p, 12, w: FontWeight.w600, color: p.muted, ls: 0.3)),
            ),
          ],
        ),
      ),
    );
  }
}
