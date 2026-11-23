import 'package:flutter/material.dart';

import '../models/cosmetic_item.dart';

/// 単品コスメの入力結果。delete が true なら削除が押された。
typedef CosmeticItemResult = ({
  String brand,
  String product,
  String shade,
  bool delete,
});

/// 単品コスメのブランド名・商品名・カラバリを入力する。
class CosmeticItemDialog extends StatefulWidget {
  const CosmeticItemDialog({super.key, this.initial});

  /// 編集する単品コスメ。新しく登録するときは null。
  final CosmeticItem? initial;

  @override
  State<CosmeticItemDialog> createState() => _CosmeticItemDialogState();
}

class _CosmeticItemDialogState extends State<CosmeticItemDialog> {
  late final _brand = TextEditingController(text: widget.initial?.brand);
  late final _product = TextEditingController(text: widget.initial?.product);
  late final _shade = TextEditingController(text: widget.initial?.shade);

  @override
  void dispose() {
    _brand.dispose();
    _product.dispose();
    _shade.dispose();
    super.dispose();
  }

  void _close({bool delete = false}) {
    Navigator.pop<CosmeticItemResult>(context, (
      brand: _brand.text.trim(),
      product: _product.text.trim(),
      shade: _shade.text.trim(),
      delete: delete,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? '単品コスメを追加' : '単品コスメ'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _brand,
                autofocus: widget.initial == null,
                decoration: const InputDecoration(labelText: 'ブランド名'),
              ),
              TextField(
                controller: _product,
                decoration: const InputDecoration(
                  labelText: '商品名',
                  hintText: '例: ハイライター',
                ),
              ),
              TextField(
                controller: _shade,
                decoration: const InputDecoration(
                  labelText: 'カラバリ',
                  hintText: '例: 01 ムーンライト',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (widget.initial != null)
          TextButton(
            onPressed: () => _close(delete: true),
            child: Text(
              '削除',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () {
            if (_product.text.trim().isEmpty) return;
            _close();
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
