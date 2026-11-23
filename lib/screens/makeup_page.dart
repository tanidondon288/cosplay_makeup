import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../widgets/look_list.dart';

/// メイク記録。キャラクターを選んで、そのキャラのメイクを表示する。
class MakeupPage extends StatelessWidget {
  const MakeupPage({
    super.key,
    required this.store,
    required this.characterId,
    required this.onCharacterChanged,
  });

  final AppStore store;

  /// 選んでいるキャラクター。null なら最初のキャラクター。
  final String? characterId;
  final void Function(String id) onCharacterChanged;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final characters = store.data.characters;
        final character =
            store.characterById(characterId) ??
            (characters.isEmpty ? null : characters.first);

        return Scaffold(
          appBar: AppBar(title: const Text('メイク記録')),
          body: character == null
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      '先に「キャラクター」でキャラクターを登録してください。',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          const Text('キャラクター'),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: character.id,
                              items: [
                                for (final c in characters)
                                  DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name),
                                  ),
                              ],
                              onChanged: (id) {
                                if (id != null) onCharacterChanged(id);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    LookList(store: store, character: character),
                  ],
                ),
          floatingActionButton: character == null
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => addLookFlow(context, store, character),
                  icon: const Icon(Icons.add),
                  label: const Text('メイクを追加'),
                ),
        );
      },
    );
  }
}
