import 'package:flutter/material.dart';

import 'data/app_store.dart';
import 'screens/home_screen.dart';

void main() {
  final store = AppStore();
  store.load();
  runApp(CosplayMakeupApp(store: store));
}

class CosplayMakeupApp extends StatelessWidget {
  const CosplayMakeupApp({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'コスメイク帳',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFD8578A),
        useMaterial3: true,
      ),
      home: ListenableBuilder(
        listenable: store,
        builder: (context, _) => store.isLoaded
            ? HomeScreen(store: store)
            : const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
    );
  }
}
