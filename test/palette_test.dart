import 'dart:convert';

import 'package:cosplay_makeup/data/app_store.dart';
import 'package:cosplay_makeup/models/app_data.dart';
import 'package:cosplay_makeup/models/character.dart';
import 'package:cosplay_makeup/models/cosmetic_item.dart';
import 'package:cosplay_makeup/models/palette.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('新しいパレットはたて×よこ個の1マスで埋まる', () {
    final p = Palette(name: 'テスト', rows: 2, cols: 3);
    expect(p.cells.length, 6);
  });

  test('長方形になる選び方だけ結合できる', () {
    final p = Palette(name: 'テスト', rows: 2, cols: 2);
    final a = p.cellAt(0, 0)!.id;
    final b = p.cellAt(0, 1)!.id;
    final d = p.cellAt(1, 1)!.id;
    expect(p.canMerge({a, b}), isTrue);
    expect(p.canMerge({a, d}), isFalse); // ななめ
    expect(p.canMerge({a, b, d}), isFalse); // L字
  });

  test('結合すると1マスになり、色のあるマスの色が残る', () {
    final p = Palette(name: 'テスト', rows: 2, cols: 2);
    final a = p.cellAt(0, 0)!;
    final b = p.cellAt(1, 0)!..color = 0xFF112233;
    final merged = p.merge({a.id, b.id})!;
    expect(merged.color, 0xFF112233);
    expect(merged.rowSpan, 2);
    expect(p.cells.length, 3);
    expect(p.cellAt(0, 0), same(merged));
    expect(p.cellAt(1, 0), same(merged));
  });

  test('結合を解除すると元のマス数に戻り、同じ色が入る', () {
    final p = Palette(name: 'テスト', rows: 2, cols: 2);
    final ids = p.cells.map((c) => c.id).toSet();
    final merged = p.merge(ids)!..color = 0xFFABCDEF;
    p.unmerge(merged.id);
    expect(p.cells.length, 4);
    expect(p.cells.every((c) => c.color == 0xFFABCDEF), isTrue);
  });

  test('マス数を減らすとはみ出したマスは消え、結合マスは縮む', () {
    final p = Palette(name: 'テスト', rows: 3, cols: 3);
    p.merge({p.cellAt(0, 0)!.id, p.cellAt(0, 1)!.id, p.cellAt(0, 2)!.id});
    p.cellAt(2, 2)!.color = 0xFF000000;
    expect(p.cellsLostByResize(2, 2).length, 1);
    p.resize(2, 2);
    expect(p.cellAt(0, 0)!.colSpan, 2);
    expect(p.cells.length, 3);
  });

  test('ブランド名とマスの形も保存され、古いデータは1:1になる', () {
    final p = Palette(
      brand: 'dasique',
      name: 'シャドウパレット',
      shade: '01',
      rows: 3,
      cols: 2,
      aspectW: 2,
      aspectH: 3,
    );
    final restored = Palette.fromJson(
      jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>,
    );
    expect(restored.displayName, 'dasique シャドウパレット 01');
    expect(restored.shade, '01');
    expect(restored.aspectW, 2);
    expect(restored.aspectH, 3);

    final old = Palette.fromJson({
      'id': 'x',
      'name': '古い',
      'rows': 1,
      'cols': 1,
    });
    expect(old.brand, '');
    expect(old.shade, '');
    expect(old.aspectW, 1);
    expect(old.aspectH, 1);
  });

  test('メイクと工程の並びが保存形式で残る', () {
    final look = MakeupLook(
      title: '本番メイク',
      steps: [
        MakeupStep(part: 'アイホール', paletteId: 'p', cellId: 'c'),
        MakeupStep(part: 'ハイライト', itemId: 'i'),
        MakeupStep(part: 'ぼかす', memo: '指で'),
      ],
    );
    final data = AppData(
      characters: [
        Character(name: 'キャラ', looks: [look]),
      ],
      items: [CosmeticItem(brand: 'B', product: 'P', shade: '01')],
    );
    final restored = AppData.fromJson(
      jsonDecode(jsonEncode(data.toJson())) as Map<String, dynamic>,
    );
    final steps = restored.characters.single.looks.single.steps;
    expect(steps.map((s) => s.part), ['アイホール', 'ハイライト', 'ぼかす']);
    expect(steps[0].usesPalette, isTrue);
    expect(steps[1].usesItem, isTrue);
    expect(steps[2].memo, '指で');
    expect(restored.items.single.displayName, 'B P');
  });

  test('結合で消えたマスを使っていた工程は、結合後のマスにつながる', () async {
    final store = await _store();
    final p = store.addPalette(_settings(1, 2));
    final left = p.cellAt(0, 0)!;
    p.cellAt(0, 1)!
      ..name = '右'
      ..color = 0xFF123456;
    final look = store.addLook(store.addCharacter('キャラ', '', ''), 'メイク');
    look.steps.add(MakeupStep(part: '頬')..usePaletteCell(p.id, left.id));
    store.mergeCells(p, {left.id, p.cellAt(0, 1)!.id});
    final info = store.resolveStep(look.steps.single)!;
    expect(info.isLost, isFalse);
    expect(info.title, '右');
  });

  test('パレットや単品コスメを削除しても、工程には名前と色が残る', () async {
    final store = await _store();
    final p = store.addPalette(_settings(1, 1));
    final cell = p.cells.single
      ..name = 'ブラウン'
      ..color = 0xFF8C5A43;
    final item = store.addItem('B', 'ハイライター', '01');
    final look = store.addLook(store.addCharacter('キャラ', '', ''), 'メイク');
    look.steps.addAll([
      MakeupStep(part: '目尻')..usePaletteCell(p.id, cell.id),
      MakeupStep(part: '頬骨')..useItem(item.id),
    ]);
    store.changed();
    store.deletePalette(p.id);
    store.deleteItem(item.id);
    final a = store.resolveStep(look.steps[0])!;
    final b = store.resolveStep(look.steps[1])!;
    expect(a.isLost, isTrue);
    expect(a.title, 'ブラウン');
    expect(a.color, 0xFF8C5A43);
    expect(b.isLost, isTrue);
    expect(b.title, '01');
  });

  test('最近更新したメイクは新しい順', () async {
    final store = await _store();
    final c = store.addCharacter('キャラ', '', '');
    final a = store.addLook(c, 'A')..updatedAt = 1;
    final b = store.addLook(c, 'B')..updatedAt = 2;
    expect(store.recentLooks(5).map((r) => r.look), [b, a]);
    expect(store.lookCount, 2);
    a.pinned = true;
    expect(store.pinnedLooks().map((r) => r.look), [a]);
  });
}

Future<AppStore> _store() async {
  SharedPreferences.setMockInitialValues({});
  final store = AppStore();
  await store.load();
  return store;
}

PaletteSettings _settings(int rows, int cols) => (
  brand: '',
  name: 'テスト',
  shade: '',
  rows: rows,
  cols: cols,
  aspectW: 1,
  aspectH: 1,
);
