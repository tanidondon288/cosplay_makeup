import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/character.dart';
import '../widgets/dialogs.dart';
import '../widgets/palette_grid.dart';

/// 工程で使うコスメの種類。
enum _Source { palette, item, none }

/// 工程を1つ追加・編集する画面。「保存」を押したときだけ記録に反映する。
class StepEditScreen extends StatefulWidget {
  const StepEditScreen({
    super.key,
    required this.store,
    required this.look,
    this.step,
  });

  final AppStore store;
  final MakeupLook look;

  /// 編集する工程。新しく追加するときは null。
  final MakeupStep? step;

  @override
  State<StepEditScreen> createState() => _StepEditScreenState();
}

class _StepEditScreenState extends State<StepEditScreen> {
  late final _part = TextEditingController(text: widget.step?.part ?? '');
  late final _memo = TextEditingController(text: widget.step?.memo ?? '');
  late final _Source _originalSource;
  late _Source _source;
  String? _paletteId;
  String? _cellId;
  String? _itemId;

  AppStore get _store => widget.store;

  @override
  void initState() {
    super.initState();
    final step = widget.step;
    _originalSource = step == null
        ? _Source.palette
        : step.usesItem
        ? _Source.item
        : step.usesPalette
        ? _Source.palette
        : _Source.none;
    _source = _originalSource;
    _paletteId = step?.paletteId;
    _cellId = step?.cellId;
    _itemId = step?.itemId;

    final palettes = _store.data.palettes;
    if (_store.paletteById(_paletteId) == null) {
      _paletteId = palettes.isEmpty ? null : palettes.first.id;
      _cellId = null;
    }
  }

  @override
  void dispose() {
    _part.dispose();
    _memo.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// 元のコスメが削除済みで、選び直していないとき true。控えをそのまま残す。
  bool get _keepsLostCosmetic {
    final step = widget.step;
    if (step == null || _source != _originalSource) return false;
    return _store.resolveStep(step)?.isLost ?? false;
  }

  void _save() {
    final part = _part.text.trim();
    final memo = _memo.text.trim();
    final cell = _store.paletteById(_paletteId)?.cellById(_cellId);
    final item = _store.itemById(_itemId);

    if (!_keepsLostCosmetic) {
      if (_source == _Source.palette && cell == null) {
        _showMessage('パレットのマスをタップして選んでください');
        return;
      }
      if (_source == _Source.item && item == null) {
        _showMessage('単品コスメを選んでください');
        return;
      }
    }
    if (part.isEmpty && memo.isEmpty && _source == _Source.none) {
      _showMessage('塗る場所かメモを入力してください');
      return;
    }

    final step = widget.step ?? MakeupStep();
    step
      ..part = part
      ..memo = memo;
    if (!_keepsLostCosmetic) {
      switch (_source) {
        case _Source.palette:
          step.usePaletteCell(_paletteId!, cell!.id);
        case _Source.item:
          step.useItem(item!.id);
        case _Source.none:
          step.clearCosmetic();
      }
    }
    if (widget.step == null) widget.look.steps.add(step);
    _store.touchLook(widget.look);
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showConfirmDialog(
      context,
      title: '工程を削除',
      message: 'この工程を削除しますか?',
      okLabel: '削除する',
    );
    if (!ok || !mounted) return;
    widget.look.steps.removeWhere((s) => s.id == widget.step!.id);
    _store.touchLook(widget.look);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final number = widget.step == null
        ? widget.look.steps.length + 1
        : widget.look.steps.indexOf(widget.step!) + 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.step == null ? '工程を追加' : '工程 $number を編集'),
        actions: [
          if (widget.step != null)
            IconButton(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
              tooltip: '削除',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _part,
            decoration: const InputDecoration(
              labelText: '塗る場所',
              hintText: '例: アイホール',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Text('使うコスメ', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<_Source>(
            expandedInsets: EdgeInsets.zero,
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: _Source.palette, label: Text('パレット')),
              ButtonSegment(value: _Source.item, label: Text('単品コスメ')),
              ButtonSegment(value: _Source.none, label: Text('なし')),
            ],
            selected: {_source},
            onSelectionChanged: (s) => setState(() => _source = s.first),
          ),
          const SizedBox(height: 12),
          if (_keepsLostCosmetic)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '記録したコスメ「${widget.step!.snapTitle}」は削除されています。'
                '選び直さなければ、そのまま残ります。',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ...switch (_source) {
            _Source.palette => _buildPalettePicker(theme),
            _Source.item => _buildItemPicker(theme),
            _Source.none => [
              Text('コスメを使わない工程として記録します。', style: theme.textTheme.bodySmall),
            ],
          },
          const SizedBox(height: 24),
          TextField(
            controller: _memo,
            minLines: 3,
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: 'メモ(ブラシ、塗り方、量など)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('保存'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPalettePicker(ThemeData theme) {
    final palettes = _store.data.palettes;
    if (palettes.isEmpty) {
      return [const Text('パレットがまだありません。\n「パレット」ページで先に登録してください。')];
    }
    final palette = _store.paletteById(_paletteId);
    final cell = palette?.cellById(_cellId);
    return [
      DropdownButton<String>(
        isExpanded: true,
        value: _paletteId,
        items: [
          for (final p in palettes)
            DropdownMenuItem(value: p.id, child: Text(p.displayName)),
        ],
        onChanged: (v) => setState(() {
          _paletteId = v;
          _cellId = null;
        }),
      ),
      const SizedBox(height: 12),
      if (palette != null)
        PaletteGrid(
          palette: palette,
          selectedIds: {?_cellId},
          onCellTap: (c) => setState(() => _cellId = c.id),
        ),
      const SizedBox(height: 8),
      if (cell != null)
        Row(
          children: [
            ColorSwatchBox(color: cell.color, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${cell.name.isEmpty ? '(名前なし)' : cell.name}・${cell.type}',
              ),
            ),
          ],
        )
      else
        Text('使った色のマスをタップしてください', style: theme.textTheme.bodySmall),
    ];
  }

  List<Widget> _buildItemPicker(ThemeData theme) {
    final items = _store.data.items;
    if (items.isEmpty) {
      return [const Text('単品コスメがまだありません。\n「パレット」ページの「単品コスメ」で先に登録してください。')];
    }
    return [
      Card(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            for (final item in items)
              ListTile(
                onTap: () => setState(() => _itemId = item.id),
                selected: item.id == _itemId,
                leading: const Icon(Icons.auto_awesome),
                title: Text(item.product),
                subtitle: Text(
                  [
                    if (item.brand.isNotEmpty) item.brand,
                    if (item.shade.isNotEmpty) item.shade,
                  ].join('・'),
                ),
                trailing: item.id == _itemId
                    ? const Icon(Icons.check_circle)
                    : null,
              ),
          ],
        ),
      ),
    ];
  }
}
