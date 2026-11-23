import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_store.dart';
import '../models/character.dart';
import '../widgets/dialogs.dart';
import '../widgets/look_list.dart';
import '../widgets/navigation.dart';
import '../widgets/palette_grid.dart';

/// ホーム。見出しの帯、すぐ使えるボタン、お気に入りメイク、
/// キャラクターとパレットの横スクロール、最近更新したメイクを表示する。
class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.store,
    required this.onOpenCharacters,
    required this.onOpenPalettes,
    required this.onOpenItems,
    required this.onOpenMakeup,
  });

  final AppStore store;
  final VoidCallback onOpenCharacters;
  final VoidCallback onOpenPalettes;
  final VoidCallback onOpenItems;
  final VoidCallback onOpenMakeup;

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _export(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: store.exportJson()));
    if (!context.mounted) return;
    _showMessage(context, 'バックアップをコピーしました。メモアプリなどに貼り付けて保存してください。');
  }

  Future<void> _import(BuildContext context) async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => const TextInputDialog(
        title: 'バックアップから復元',
        label: 'コピーしておいたバックアップを貼り付け',
        multiline: true,
      ),
    );
    if (text == null || text.isEmpty || !context.mounted) return;
    final ok = await showConfirmDialog(
      context,
      title: '復元しますか?',
      message: '今のデータはすべて、バックアップの内容に置き換わります。',
      okLabel: '復元する',
    );
    if (!ok || !context.mounted) return;
    _showMessage(
      context,
      store.importJson(text) ? '復元しました' : 'バックアップを読み込めませんでした',
    );
  }

  /// 「メイクを記録」: キャラクターを選んで、新しいメイクを作る。
  Future<void> _recordMakeup(BuildContext context) async {
    final characters = store.data.characters;
    if (characters.isEmpty) {
      _showMessage(context, '先にキャラクターを登録してください');
      await addCharacterFlow(context, store);
      return;
    }
    final character = characters.length == 1
        ? characters.single
        : await showDialog<Character>(
            context: context,
            builder: (context) => SimpleDialog(
              title: const Text('どのキャラクターのメイク?'),
              children: [
                for (final c in characters)
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, c),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(c.name),
                    ),
                  ),
              ],
            ),
          );
    if (character == null || !context.mounted) return;
    await addLookFlow(context, store, character);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final pinned = store.pinnedLooks();
          final recent = store.recentLooks(5);
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _Banner(
                store: store,
                onOpenCharacters: onOpenCharacters,
                onOpenMakeup: onOpenMakeup,
                onOpenPalettes: onOpenPalettes,
                onOpenItems: onOpenItems,
                onExport: () => _export(context),
                onImport: () => _import(context),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _recordMakeup(context),
                        icon: const Icon(Icons.edit_note),
                        label: const Text('メイクを記録'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => addPaletteFlow(context, store),
                        icon: const Icon(Icons.palette),
                        label: const Text('パレットを登録'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const _SectionTitle(icon: Icons.star, title: 'お気に入りメイク'),
              if (pinned.isEmpty)
                const _Hint('メイクの画面で ☆ を押すと、ここに表示されます。')
              else
                for (final ref in pinned) _LookCard(store: store, ref: ref),
              _SectionTitle(
                icon: Icons.face,
                title: 'キャラクター',
                onMore: onOpenCharacters,
              ),
              _CharacterStrip(store: store),
              _SectionTitle(
                icon: Icons.palette,
                title: 'パレット',
                onMore: onOpenPalettes,
              ),
              _PaletteStrip(store: store),
              const _SectionTitle(icon: Icons.history, title: '最近更新したメイク'),
              if (recent.isEmpty)
                const _Hint('まだメイクがありません。上の「メイクを記録」から始められます。')
              else
                for (final ref in recent) _LookCard(store: store, ref: ref),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

/// いちばん上のピンクの帯。アプリ名と登録数、バックアップのメニュー。
class _Banner extends StatelessWidget {
  const _Banner({
    required this.store,
    required this.onOpenCharacters,
    required this.onOpenMakeup,
    required this.onOpenPalettes,
    required this.onOpenItems,
    required this.onExport,
    required this.onImport,
  });

  final AppStore store;
  final VoidCallback onOpenCharacters;
  final VoidCallback onOpenMakeup;
  final VoidCallback onOpenPalettes;
  final VoidCallback onOpenItems;
  final VoidCallback onExport;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final data = store.data;
    const textColor = Color(0xFF6B2A41);

    Widget count(String label, int n, VoidCallback onTap) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '$label $n',
          style: const TextStyle(color: textColor, fontSize: 13),
        ),
      ),
    );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5B8C8), Color(0xFFFADDE5), Color(0xFFF3D3F0)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 8, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: textColor),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'コスメイク帳',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    iconColor: textColor,
                    onSelected: (v) => v == 'export' ? onExport() : onImport(),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'export', child: Text('バックアップをコピー')),
                      PopupMenuItem(value: 'import', child: Text('バックアップから復元')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'コスプレメイクの記録帳',
                style: TextStyle(color: textColor, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  count('キャラ', data.characters.length, onOpenCharacters),
                  count('メイク', store.lookCount, onOpenMakeup),
                  count('パレット', data.palettes.length, onOpenPalettes),
                  count('単品', data.items.length, onOpenItems),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title, this.onMore});

  final IconData icon;
  final String title;

  /// 「すべて見る」を押したとき。null なら出さない。
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 8, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
          if (onMore != null)
            TextButton(onPressed: onMore, child: const Text('すべて見る')),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _LookCard extends StatelessWidget {
  const _LookCard({required this.store, required this.ref});

  final AppStore store;
  final LookRef ref;

  @override
  Widget build(BuildContext context) {
    final look = ref.look;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: ListTile(
        onTap: () => openLook(context, store, ref.character, look),
        leading: look.pinned
            ? Icon(Icons.star, color: Colors.amber.shade600)
            : const Icon(Icons.folder_outlined),
        title: Text(look.title),
        subtitle: Text(
          '${ref.character.name}・${look.steps.length} 工程・'
          '${formatShortDate(look.updatedAt)}',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

/// キャラクターの丸いアイコンを横に並べる。最後に「追加」。
class _CharacterStrip extends StatelessWidget {
  const _CharacterStrip({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final characters = store.data.characters;

    Widget item({
      required Widget avatar,
      required String label,
      required VoidCallback onTap,
    }) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            avatar,
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );

    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final c in characters)
            item(
              avatar: CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  c.name.characters.first,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              label: c.name,
              onTap: () => openCharacter(context, store, c.id),
            ),
          item(
            avatar: CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.add),
            ),
            label: '追加',
            onTap: () => addCharacterFlow(context, store),
          ),
        ],
      ),
    );
  }
}

/// パレットを小さな絵のまま横に並べる。最後に「追加」。
class _PaletteStrip extends StatelessWidget {
  const _PaletteStrip({required this.store});

  final AppStore store;

  static const _width = 120.0;
  static const _pictureHeight = 84.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palettes = store.data.palettes;

    Widget item({
      required Widget picture,
      required String label,
      required VoidCallback onTap,
    }) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: _width,
        child: Column(
          children: [
            SizedBox(width: _width, height: _pictureHeight, child: picture),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );

    return SizedBox(
      height: _pictureHeight + 28,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: palettes.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i == palettes.length) {
            return item(
              picture: Center(
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.add),
                ),
              ),
              label: '追加',
              onTap: () => addPaletteFlow(context, store),
            );
          }
          final p = palettes[i];
          return item(
            // 縦長のパレットでも枠に収まるように縮める。
            picture: FittedBox(
              child: SizedBox(
                width: _width,
                child: PaletteGrid(
                  palette: p,
                  showNames: false,
                  maxCellSize: 28,
                ),
              ),
            ),
            label: p.shade.isEmpty ? p.name : '${p.name} ${p.shade}',
            onTap: () => openPalette(context, store, p.id),
          );
        },
      ),
    );
  }
}
