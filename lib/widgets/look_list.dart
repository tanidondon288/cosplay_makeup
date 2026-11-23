import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/character.dart';
import '../screens/look_screen.dart';
import 'dialogs.dart';

/// 「11/23 14:05」のような短い日時。
String formatShortDate(int millis) {
  final d = DateTime.fromMillisecondsSinceEpoch(millis);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.month}/${d.day} ${two(d.hour)}:${two(d.minute)}';
}

void openLook(
  BuildContext context,
  AppStore store,
  Character character,
  MakeupLook look,
) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) =>
          LookScreen(store: store, characterId: character.id, lookId: look.id),
    ),
  );
}

/// メイクのタイトルを聞いて新しく作り、そのまま開く。
Future<void> addLookFlow(
  BuildContext context,
  AppStore store,
  Character character,
) async {
  final title = await showDialog<String>(
    context: context,
    builder: (_) =>
        const TextInputDialog(title: 'メイクを追加', label: 'メイクのタイトル(例: 本番メイク)'),
  );
  if (title == null || title.isEmpty || !context.mounted) return;
  final look = store.addLook(character, title);
  openLook(context, store, character, look);
}

/// キャラクターのメイク(フォルダ)一覧。
class LookList extends StatelessWidget {
  const LookList({super.key, required this.store, required this.character});

  final AppStore store;
  final Character character;

  @override
  Widget build(BuildContext context) {
    if (character.looks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'まだメイクがありません。\n右下の「メイクを追加」で、タイトルを付けたメイクを作れます。',
          textAlign: TextAlign.center,
        ),
      );
    }
    return Column(
      children: [
        for (final look in character.looks)
          Card(
            child: ListTile(
              onTap: () => openLook(context, store, character, look),
              leading: look.pinned
                  ? Icon(Icons.star, color: Colors.amber.shade600)
                  : const Icon(Icons.folder_outlined),
              title: Text(look.title),
              subtitle: Text(
                '${look.steps.length} 工程・${formatShortDate(look.updatedAt)} 更新',
              ),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
      ],
    );
  }
}
