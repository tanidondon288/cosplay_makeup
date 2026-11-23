import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/cosmetic_item.dart';
import '../widgets/cosmetic_item_dialog.dart';
import '../widgets/dialogs.dart';
import '../widgets/navigation.dart';
import '../widgets/palette_grid.dart';

/// パレットと単品コスメの一覧。上の切り替えで表示を変える。
class PalettesPage extends StatelessWidget {
  const PalettesPage({
    super.key,
    required this.store,
    required this.showItems,
    required this.onShowItemsChanged,
  });

  final AppStore store;

  /// true なら単品コスメ、false ならパレットを表示する。
  final bool showItems;
  final void Function(bool) onShowItemsChanged;

  Future<void> _editItem(BuildContext context, [CosmeticItem? item]) async {
    final result = await showDialog<CosmeticItemResult>(
      context: context,
      builder: (_) => CosmeticItemDialog(initial: item),
    );
    if (result == null || !context.mounted) return;
    if (item == null) {
      store.addItem(result.brand, result.product, result.shade);
      return;
    }
    if (result.delete) {
      final ok = await showConfirmDialog(
        context,
        title: '単品コスメを削除',
        message: '「${item.product}」を削除しますか?\nメイク記録には、名前が残ります。',
        okLabel: '削除する',
      );
      if (ok) store.deleteItem(item.id);
      return;
    }
    item
      ..brand = result.brand
      ..product = result.product
      ..shade = result.shade;
    store.changed();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('パレット')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: SegmentedButton<bool>(
              expandedInsets: EdgeInsets.zero,
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: false, label: Text('パレット')),
                ButtonSegment(value: true, label: Text('単品コスメ')),
              ],
              selected: {showItems},
              onSelectionChanged: (s) => onShowItemsChanged(s.first),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: store,
              builder: (context, _) =>
                  showItems ? _buildItems(context) : _buildPalettes(context),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            showItems ? _editItem(context) : addPaletteFlow(context, store),
        icon: const Icon(Icons.add),
        label: Text(showItems ? '単品コスメを追加' : 'パレットを追加'),
      ),
    );
  }

  Widget _emptyMessage(String text) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(text, textAlign: TextAlign.center),
    ),
  );

  Widget _buildPalettes(BuildContext context) {
    final palettes = store.data.palettes;
    if (palettes.isEmpty) {
      return _emptyMessage('持っているパレットを登録しましょう。\n右下の「パレットを追加」から、マスの数を決めて作れます。');
    }
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
      children: [
        for (final p in palettes)
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => openPalette(context, store, p.id),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (p.brand.isNotEmpty)
                            Text(
                              p.brand,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          if (p.name.isNotEmpty)
                            Text(p.name, style: theme.textTheme.titleMedium),
                          if (p.shade.isNotEmpty)
                            Text(
                              'カラー: ${p.shade}',
                              style: theme.textTheme.bodyMedium,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 140,
                      child: PaletteGrid(
                        palette: p,
                        showNames: false,
                        maxCellSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildItems(BuildContext context) {
    final items = store.data.items;
    if (items.isEmpty) {
      return _emptyMessage(
        'ハイライトなど、1色だけのコスメを登録しましょう。\n右下の「単品コスメを追加」から、ブランド名・商品名・カラバリで登録できます。',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
      children: [
        for (final item in items)
          Card(
            child: ListTile(
              onTap: () => _editItem(context, item),
              leading: const Icon(Icons.auto_awesome),
              title: Text(item.product),
              subtitle: Text(
                [
                  if (item.brand.isNotEmpty) item.brand,
                  if (item.shade.isNotEmpty) item.shade,
                ].join('・'),
              ),
            ),
          ),
      ],
    );
  }
}
