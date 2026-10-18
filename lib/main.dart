import 'package:flutter/material.dart';
import 'screens/arranque.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AppStore(persist: true);
  await store.load();
  runApp(CeroApp(store: store));
}

class CeroApp extends StatefulWidget {
  final AppStore? store;
  const CeroApp({super.key, this.store});

  @override
  State<CeroApp> createState() => _CeroAppState();
}

class _CeroAppState extends State<CeroApp> {
  late final AppStore store = widget.store ?? AppStore();

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
