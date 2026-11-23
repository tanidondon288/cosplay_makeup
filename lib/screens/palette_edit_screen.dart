import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/palette.dart';
import '../widgets/dialogs.dart';
import '../widgets/palette_grid.dart';

/// パレット1つを編集する画面。マスの色を決めたり、マスを結合したりする。
class PaletteEditScreen extends StatefulWidget {
  const PaletteEditScreen({
    super.key,
    required this.store,
    required this.paletteId,
  });

  final AppStore store;
  final String paletteId;

  @override
  State<PaletteEditScreen> createState() => _PaletteEditScreenState();
}

class _PaletteEditScreenState extends State<PaletteEditScreen> {
  /// 結合するマスを選んでいる途中かどうか。
  bool _selecting = false;
  final _selected = <String>{};

  AppStore get _store => widget.store;

  void _stopSelecting() => setState(() {
    _selecting = false;
    _selected.clear();
  });

  Future<void> _onCellTap(Palette palette, PaletteCell cell) async {
    if (_selecting) {
      setState(() {
        if (!_selected.remove(cell.id)) _selected.add(cell.id);
      });
      return;
    }

    final result = await showDialog<CellEditResult>(
      context: context,
      builder: (_) => CellEditDialog(cell: cell),
    );
    if (result == null) return;
    cell
      ..name = result.name
      ..type = result.type
      ..color = result.color;
    if (result.unmerge) palette.unmerge(cell.id);
    _store.changed();
  }

  void _merge(Palette palette) {
    _store.mergeCells(palette, Set.of(_selected));
    _stopSelecting();
  }

  Future<void> _onMenu(String value, Palette palette) async {
    switch (value) {
      case 'settings':
        final settings = await showDialog<PaletteSettings>(
          context: context,
          builder: (_) =>
              PaletteSettingsDialog(title: 'パレットの設定', initial: palette),
        );
        if (settings == null || !mounted) return;
        final lost = palette.cellsLostByResize(settings.rows, settings.cols);
        if (lost.isNotEmpty) {
          final ok = await showConfirmDialog(
            context,
            title: 'マスが消えます',
            message: '色を設定したマスが ${lost.length} 個消えます。よろしいですか?',
            okLabel: '変更する',
          );
          if (!ok) return;
        }
        _store.applyPaletteSettings(palette, settings);
      case 'delete':
        final ok = await showConfirmDialog(
          context,
          title: 'パレットを削除',
          message: '「${palette.displayName}」を削除しますか?\nキャラの記録には、色と名前が残ります。',
          okLabel: '削除する',
        );
        if (!ok || !mounted) return;
        Navigator.pop(context);
        _store.deletePalette(palette.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final palette = _store.paletteById(widget.paletteId);
        if (palette == null) return const Scaffold();
        _selected.removeWhere((id) => palette.cellById(id) == null);

        return Scaffold(
          appBar: AppBar(
            title: Text(palette.displayName),
            actions: [
              if (!_selecting)
                TextButton(
                  onPressed: () => setState(() => _selecting = true),
                  child: const Text('結合'),
                ),
              PopupMenuButton<String>(
                onSelected: (v) => _onMenu(v, palette),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'settings', child: Text('名前・マス数・形を変更')),
                  PopupMenuItem(value: 'delete', child: Text('パレットを削除')),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                _selecting
                    ? 'つなげたいマスをタップして選び、「結合する」を押してください。\n選んだマスが長方形になるようにしてください。'
                    : 'マスをタップすると、色・名前・種類を設定できます。\n右上の「結合」でマスをつなげられます。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              PaletteGrid(
                palette: palette,
                selectedIds: _selected,
                maxCellSize: 96,
                onCellTap: (cell) => _onCellTap(palette, cell),
              ),
            ],
          ),
          bottomNavigationBar: _selecting
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _stopSelecting,
                            child: const Text('やめる'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: palette.canMerge(_selected)
                                ? () => _merge(palette)
                                : null,
                            child: const Text('結合する'),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}
