import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/palette.dart';
import '../screens/character_screen.dart';
import '../screens/palette_edit_screen.dart';
import 'dialogs.dart';

/// いくつかの画面から使う「開く」「追加する」の流れ。

void openCharacter(BuildContext context, AppStore store, String id) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => CharacterScreen(store: store, characterId: id),
    ),
  );
}

void openPalette(BuildContext context, AppStore store, String id) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => PaletteEditScreen(store: store, paletteId: id),
    ),
  );
}

/// キャラクターの情報を聞いて登録し、そのまま開く。
Future<void> addCharacterFlow(BuildContext context, AppStore store) async {
  final info = await showDialog<CharacterInfo>(
    context: context,
    builder: (_) => const CharacterInfoDialog(),
  );
  if (info == null || !context.mounted) return;
  final character = store.addCharacter(info.name, info.work, info.memo);
  openCharacter(context, store, character.id);
}

/// パレットの設定を聞いて登録し、そのまま開く。
Future<void> addPaletteFlow(BuildContext context, AppStore store) async {
  final settings = await showDialog<PaletteSettings>(
    context: context,
    builder: (_) => const PaletteSettingsDialog(title: 'パレットを追加'),
  );
  if (settings == null || !context.mounted) return;
  final palette = store.addPalette(settings);
  openPalette(context, store, palette.id);
}
