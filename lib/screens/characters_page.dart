import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../widgets/navigation.dart';

/// キャラクター一覧。新規登録もここから。
class CharactersPage extends StatelessWidget {
  const CharactersPage({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('キャラクター')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final characters = store.data.characters;
          if (characters.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'コスプレするキャラクターを登録しましょう。\n右下の「キャラクターを追加」から登録できます。',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
            children: [
              for (final c in characters)
                Card(
                  child: ListTile(
                    onTap: () => openCharacter(context, store, c.id),
                    leading: CircleAvatar(child: Text(c.name.characters.first)),
                    title: Text(c.name),
                    subtitle: Text(
                      [
                        if (c.work.isNotEmpty) c.work,
                        'メイク ${c.looks.length} 件',
                      ].join('・'),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => addCharacterFlow(context, store),
        icon: const Icon(Icons.add),
        label: const Text('キャラクターを追加'),
      ),
    );
  }
}
