import 'package:flutter/material.dart';
import 'screens/arranque.dart';
import 'store.dart';
import 'theme.dart';

void main() => runApp(const CeroApp());

class CeroApp extends StatefulWidget {
  const CeroApp({super.key});

  @override
  State<CeroApp> createState() => _CeroAppState();
}

class _CeroAppState extends State<CeroApp> {
  final AppStore store = AppStore();

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      store: store,
      child: AnimatedBuilder(
        animation: store,
        builder: (context, _) => MaterialApp(
          title: 'Cero',
          debugShowCheckedModeBanner: false,
          themeMode: store.themeMode,
          theme: buildTheme(Pal.light),
          darkTheme: buildTheme(Pal.dark),
          home: const ArranqueScreen(),
        ),
      ),
    );
  }
}
