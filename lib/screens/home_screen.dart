import 'package:flutter/material.dart';

import '../data/app_store.dart';
import 'characters_page.dart';
import 'home_page.dart';
import 'makeup_page.dart';
import 'palettes_page.dart';

/// アプリの土台。画面下のメインメニューでページを切り替える。
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.store});

  final AppStore store;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _homeTab = 0;
  static const _charactersTab = 1;
  static const _palettesTab = 2;
  static const _makeupTab = 3;

  int _tab = _homeTab;

  /// パレットページで単品コスメを表示するかどうか。
  bool _showItems = false;

  /// メイク記録ページで選んでいるキャラクター。
  String? _makeupCharacterId;

  void _go(int tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final page = switch (_tab) {
      _charactersTab => CharactersPage(store: store),
      _palettesTab => PalettesPage(
        store: store,
        showItems: _showItems,
        onShowItemsChanged: (v) => setState(() => _showItems = v),
      ),
      _makeupTab => MakeupPage(
        store: store,
        characterId: _makeupCharacterId,
        onCharacterChanged: (id) => setState(() => _makeupCharacterId = id),
      ),
      _ => HomePage(
        store: store,
        onOpenCharacters: () => _go(_charactersTab),
        onOpenPalettes: () => setState(() {
          _showItems = false;
          _tab = _palettesTab;
        }),
        onOpenItems: () => setState(() {
          _showItems = true;
          _tab = _palettesTab;
        }),
        onOpenMakeup: () => _go(_makeupTab),
      ),
    };

    return Scaffold(
      body: page,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _go,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'ホーム',
          ),
          NavigationDestination(
            icon: Icon(Icons.face_outlined),
            selectedIcon: Icon(Icons.face),
            label: 'キャラクター',
          ),
          NavigationDestination(
            icon: Icon(Icons.palette_outlined),
            selectedIcon: Icon(Icons.palette),
            label: 'パレット',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'メイク記録',
          ),
        ],
      ),
    );
  }
}
