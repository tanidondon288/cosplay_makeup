import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/character.dart';
import '../widgets/dialogs.dart';
import '../widgets/look_list.dart';

/// キャラクター1人の画面。情報の編集・削除と、そのキャラのメイク一覧。
class CharacterScreen extends StatelessWidget {
  const CharacterScreen({
    super.key,
    required this.store,
    required this.characterId,
  });

  final AppStore store;
  final String characterId;

  Future<void> _onMenu(
    BuildContext context,
    String value,
    Character character,
  ) async {
    switch (value) {
      case 'edit':
        final info = await showDialog<CharacterInfo>(
          context: context,
          builder: (_) => CharacterInfoDialog(
            initial: (
              name: character.name,
              work: character.work,
              memo: character.memo,
            ),
          ),
        );
        if (info == null) return;
        character
          ..name = info.name
          ..work = info.work
          ..memo = info.memo;
        store.changed();
      case 'delete':
        final ok = await showConfirmDialog(
          context,
          title: 'キャラクターを削除',
          message: '「${character.name}」と、そのメイク記録をすべて削除しますか?',
          okLabel: '削除する',
        );
        if (!ok || !context.mounted) return;
        Navigator.pop(context);
        store.deleteCharacter(character.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final character = store.characterById(characterId);
        if (character == null) return const Scaffold();
        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            title: Text(character.name),
            actions: [
              PopupMenuButton<String>(
                onSelected: (v) => _onMenu(context, v, character),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('名前・作品名を編集')),
                  PopupMenuItem(value: 'delete', child: Text('キャラクターを削除')),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
            children: [
              if (character.work.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    character.work,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (character.memo.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                  child: Text(character.memo),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                child: Text('メイク', style: theme.textTheme.titleMedium),
              ),
              LookList(store: store, character: character),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => addLookFlow(context, store, character),
            icon: const Icon(Icons.add),
            label: const Text('メイクを追加'),
          ),
        );
      },
    );
  }
}
