import 'package:flutter/material.dart';

import '../models/palette.dart';
import 'color_picker_dialog.dart';
import 'palette_grid.dart';

/// はい/いいえを聞く。はいなら true。
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String okLabel = 'OK',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(okLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// 文字を1つ入力してもらう。キャンセルなら null。
class TextInputDialog extends StatefulWidget {
  const TextInputDialog({
    super.key,
    required this.title,
    this.initial = '',
    this.label = '',
    this.multiline = false,
  });

  final String title;
  final String initial;
  final String label;
  final bool multiline;

  @override
  State<TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<TextInputDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: widget.multiline ? 4 : 1,
        maxLines: widget.multiline ? 8 : 1,
        decoration: InputDecoration(labelText: widget.label),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

typedef CharacterInfo = ({String name, String work, String memo});

/// キャラ名・作品名・メモを入力する。
class CharacterInfoDialog extends StatefulWidget {
  const CharacterInfoDialog({super.key, this.initial});

  final CharacterInfo? initial;

  @override
  State<CharacterInfoDialog> createState() => _CharacterInfoDialogState();
}

class _CharacterInfoDialogState extends State<CharacterInfoDialog> {
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _work = TextEditingController(text: widget.initial?.work);
  late final _memo = TextEditingController(text: widget.initial?.memo);

  @override
  void dispose() {
    _name.dispose();
    _work.dispose();
    _memo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'キャラを追加' : 'キャラの情報'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                autofocus: widget.initial == null,
                decoration: const InputDecoration(labelText: 'キャラ名'),
              ),
              TextField(
                controller: _work,
                decoration: const InputDecoration(labelText: '作品名(なくてもOK)'),
              ),
              TextField(
                controller: _memo,
                minLines: 1,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'メモ(なくてもOK)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) return;
            Navigator.pop<CharacterInfo>(context, (
              name: name,
              work: _work.text.trim(),
              memo: _memo.text.trim(),
            ));
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}

/// パレットのブランド名・カラー名・マス数・マスの形を決める。
class PaletteSettingsDialog extends StatefulWidget {
  const PaletteSettingsDialog({super.key, required this.title, this.initial});

  final String title;

  /// 編集するパレット。新しく作るときは null。
  final Palette? initial;

  @override
  State<PaletteSettingsDialog> createState() => _PaletteSettingsDialogState();
}

class _PaletteSettingsDialogState extends State<PaletteSettingsDialog> {
  static const _maxCount = 8;
  static const _maxAspect = 4;
  late final _brand = TextEditingController(text: widget.initial?.brand);
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _shade = TextEditingController(text: widget.initial?.shade);
  late int _rows = widget.initial?.rows ?? 3;
  late int _cols = widget.initial?.cols ?? 3;
  late int _aspectW = widget.initial?.aspectW ?? 1;
  late int _aspectH = widget.initial?.aspectH ?? 1;

  @override
  void dispose() {
    _brand.dispose();
    _name.dispose();
    _shade.dispose();
    super.dispose();
  }

  Widget _numberPicker({
    required int value,
    required int maxValue,
    required String suffix,
    required void Function(int) update,
  }) {
    return DropdownButton<int>(
      isExpanded: true,
      value: value,
      items: [
        for (var i = 1; i <= maxValue; i++)
          DropdownMenuItem(value: i, child: Text('$i$suffix')),
      ],
      onChanged: (v) => setState(() => update(v!)),
    );
  }

  /// 「ラベル  [左]  記号  [右]」の1行。
  Widget _pairRow(String label, Widget left, String mark, Widget right) {
    return Row(
      children: [
        SizedBox(width: 72, child: Text(label)),
        Expanded(child: left),
        SizedBox(width: 28, child: Text(mark, textAlign: TextAlign.center)),
        Expanded(child: right),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = Palette(
      name: '',
      rows: _rows,
      cols: _cols,
      aspectW: _aspectW,
      aspectH: _aspectH,
    );

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _brand,
                autofocus: widget.initial == null,
                decoration: const InputDecoration(
                  labelText: 'ブランド名',
                  hintText: '例: dasique',
                ),
              ),
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'パレット名',
                  hintText: '例: シャドウパレット',
                ),
              ),
              TextField(
                controller: _shade,
                decoration: const InputDecoration(
                  labelText: 'カラー',
                  hintText: '例: 01 シュガーバレエ',
                ),
              ),
              const SizedBox(height: 20),
              _pairRow(
                'マスの数',
                _numberPicker(
                  value: _cols,
                  maxValue: _maxCount,
                  suffix: ' よこ',
                  update: (v) => _cols = v,
                ),
                '×',
                _numberPicker(
                  value: _rows,
                  maxValue: _maxCount,
                  suffix: ' たて',
                  update: (v) => _rows = v,
                ),
              ),
              _pairRow(
                'マスの形',
                _numberPicker(
                  value: _aspectW,
                  maxValue: _maxAspect,
                  suffix: ' よこ',
                  update: (v) => _aspectW = v,
                ),
                ':',
                _numberPicker(
                  value: _aspectH,
                  maxValue: _maxAspect,
                  suffix: ' たて',
                  update: (v) => _aspectH = v,
                ),
              ),
              Text(
                'マスの形は、1マスの よこ と たて の長さの比です。\n1:1 で正方形、2:3 で縦長になります。',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Center(
                child: SizedBox(
                  width: 180,
                  child: PaletteGrid(
                    palette: preview,
                    showNames: false,
                    maxCellSize: 40,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () {
            final brand = _brand.text.trim();
            final name = _name.text.trim();
            final shade = _shade.text.trim();
            final isBlank = brand.isEmpty && name.isEmpty && shade.isEmpty;
            Navigator.pop<PaletteSettings>(context, (
              brand: brand,
              name: isBlank ? '新しいパレット' : name,
              shade: shade,
              rows: _rows,
              cols: _cols,
              aspectW: _aspectW,
              aspectH: _aspectH,
            ));
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}

/// マスの編集結果。
class CellEditResult {
  const CellEditResult({
    required this.name,
    required this.type,
    required this.color,
    this.unmerge = false,
  });

  final String name;
  final String type;
  final int? color;

  /// 「結合を解除」が押されたとき true。
  final bool unmerge;
}

/// マスの色・名前・種類を編集する。
class CellEditDialog extends StatefulWidget {
  const CellEditDialog({super.key, required this.cell});

  final PaletteCell cell;

  @override
  State<CellEditDialog> createState() => _CellEditDialogState();
}

class _CellEditDialogState extends State<CellEditDialog> {
  late final _name = TextEditingController(text: widget.cell.name);
  late String _type = widget.cell.type;
  late int? _color = widget.cell.color;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickColor() async {
    final picked = await showDialog<Color>(
      context: context,
      builder: (_) => ColorPickerDialog(initial: Color(_color ?? 0xFFC99A7A)),
    );
    if (picked != null) setState(() => _color = picked.toARGB32());
  }

  CellEditResult _result({bool unmerge = false}) => CellEditResult(
    name: _name.text.trim(),
    type: _type,
    color: _color,
    unmerge: unmerge,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.cell.isMerged ? '結合したマス' : 'マス'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('色', style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                children: [
                  GestureDetector(
                    onTap: _pickColor,
                    child: Container(
                      width: 56,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _color == null ? null : Color(_color!),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black26),
                      ),
                      child: _color == null ? const Icon(Icons.add) : null,
                    ),
                  ),
                  TextButton(onPressed: _pickColor, child: const Text('色を選ぶ')),
                  if (_color != null)
                    TextButton(
                      onPressed: () => setState(() => _color = null),
                      child: const Text('色なし'),
                    ),
                ],
              ),
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: '色の名前(例: 03 テラコッタ)',
                ),
              ),
              const SizedBox(height: 16),
              Text('種類', style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final t in makeupTypes)
                    ChoiceChip(
                      label: Text(t),
                      selected: _type == t,
                      onSelected: (_) => setState(() => _type = t),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (widget.cell.isMerged)
          TextButton(
            onPressed: () => Navigator.pop(context, _result(unmerge: true)),
            child: const Text('結合を解除'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _result()),
          child: const Text('保存'),
        ),
      ],
    );
  }
}
