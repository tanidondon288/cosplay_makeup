import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/app_data.dart';
import '../models/character.dart';
import '../models/cosmetic_item.dart';
import '../models/palette.dart';
import 'app_storage.dart';

/// 工程に表示するコスメの情報。
class StepCosmetic {
  const StepCosmetic({
    required this.title,
    required this.detail,
    required this.color,
    required this.isItem,
    required this.isLost,
  });

  /// 色の名前やカラバリ。
  final String title;

  /// パレット名や商品名。
  final String detail;
  final int? color;

  /// 単品コスメなら true。
  final bool isItem;

  /// 元のコスメがもうないとき true(控えを表示している)。
  final bool isLost;
}

/// キャラクターとメイクの組。
typedef LookRef = ({Character character, MakeupLook look});

/// アプリのデータを持ち、変更があれば画面に知らせて保存する。
class AppStore extends ChangeNotifier {
  AppStore({AppStorage? storage}) : _storage = storage ?? AppStorage();

  final AppStorage _storage;
  AppData _data = AppData();
  bool _isLoaded = false;

  AppData get data => _data;
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    _data = await _storage.load() ?? AppData();
    _isLoaded = true;
    notifyListeners();
  }

  /// データを変えたあとに呼ぶ。工程の控えを最新にし、画面を更新して保存する。
  void changed() {
    _refreshSnapshots();
    notifyListeners();
    _storage.save(_data);
  }

  Iterable<MakeupStep> get _allSteps => [
    for (final c in _data.characters)
      for (final l in c.looks) ...l.steps,
  ];

  void _refreshSnapshots() {
    for (final step in _allSteps) {
      final live = resolveStep(step);
      if (live == null || live.isLost) continue;
      step
        ..snapTitle = live.title
        ..snapDetail = live.detail
        ..snapColor = live.color;
    }
  }

  Palette? paletteById(String? id) {
    for (final p in _data.palettes) {
      if (p.id == id) return p;
    }
    return null;
  }

  CosmeticItem? itemById(String? id) {
    for (final i in _data.items) {
      if (i.id == id) return i;
    }
    return null;
  }

  Character? characterById(String? id) {
    for (final c in _data.characters) {
      if (c.id == id) return c;
    }
    return null;
  }

  // ---- パレット ----

  Palette addPalette(PaletteSettings settings) {
    final palette = Palette(
      brand: settings.brand,
      name: settings.name,
      shade: settings.shade,
      rows: settings.rows,
      cols: settings.cols,
      aspectW: settings.aspectW,
      aspectH: settings.aspectH,
    );
    _data.palettes.add(palette);
    changed();
    return palette;
  }

  void deletePalette(String id) {
    // 控えを最新にしてから消すので、工程には色と名前が残る。
    _refreshSnapshots();
    _data.palettes.removeWhere((p) => p.id == id);
    changed();
  }

  /// マスを結合し、消えたマスを使っていた工程を結合後のマスにつなぎ直す。
  bool mergeCells(Palette palette, Set<String> ids) {
    _refreshSnapshots();
    final base = palette.merge(ids);
    if (base == null) return false;
    for (final step in _allSteps) {
      if (step.paletteId == palette.id && ids.contains(step.cellId)) {
        step.cellId = base.id;
      }
    }
    changed();
    return true;
  }

  /// 名前・マス数・マスの形をまとめて変える。
  void applyPaletteSettings(Palette palette, PaletteSettings settings) {
    _refreshSnapshots();
    palette
      ..brand = settings.brand
      ..name = settings.name
      ..shade = settings.shade
      ..aspectW = settings.aspectW
      ..aspectH = settings.aspectH
      ..resize(settings.rows, settings.cols);
    changed();
  }

  // ---- 単品コスメ ----

  CosmeticItem addItem(String brand, String product, String shade) {
    final item = CosmeticItem(brand: brand, product: product, shade: shade);
    _data.items.add(item);
    changed();
    return item;
  }

  void deleteItem(String id) {
    _refreshSnapshots();
    _data.items.removeWhere((i) => i.id == id);
    changed();
  }

  // ---- キャラクターとメイク ----

  Character addCharacter(String name, String work, String memo) {
    final character = Character(name: name, work: work, memo: memo);
    _data.characters.add(character);
    changed();
    return character;
  }

  void deleteCharacter(String id) {
    _data.characters.removeWhere((c) => c.id == id);
    changed();
  }

  MakeupLook addLook(Character character, String title) {
    final look = MakeupLook(title: title);
    character.looks.add(look);
    changed();
    return look;
  }

  void deleteLook(Character character, String lookId) {
    character.looks.removeWhere((l) => l.id == lookId);
    changed();
  }

  /// メイクの中身を変えたときに呼ぶ。更新日時を今にして保存する。
  void touchLook(MakeupLook look) {
    look.updatedAt = DateTime.now().millisecondsSinceEpoch;
    changed();
  }

  /// お気に入り(☆)のメイク(新しく更新した順)。
  List<LookRef> pinnedLooks() => [
    for (final ref in recentLooks(lookCount))
      if (ref.look.pinned) ref,
  ];

  /// 最近更新したメイク(新しい順)。
  List<LookRef> recentLooks(int limit) {
    final all = <LookRef>[
      for (final c in _data.characters)
        for (final l in c.looks) (character: c, look: l),
    ]..sort((a, b) => b.look.updatedAt.compareTo(a.look.updatedAt));
    return all.take(limit).toList();
  }

  int get lookCount =>
      _data.characters.fold(0, (sum, c) => sum + c.looks.length);

  /// 工程で使ったコスメの情報。コスメを使っていない工程は null。
  StepCosmetic? resolveStep(MakeupStep step) {
    if (step.usesItem) {
      final item = itemById(step.itemId);
      if (item == null) return _snapshot(step, isItem: true);
      return StepCosmetic(
        title: item.shade.isEmpty ? item.product : item.shade,
        detail: item.shade.isEmpty ? item.brand : item.displayName,
        color: null,
        isItem: true,
        isLost: false,
      );
    }
    if (step.usesPalette) {
      final palette = paletteById(step.paletteId);
      final cell = palette?.cellById(step.cellId);
      if (cell == null) return _snapshot(step, isItem: false);
      return StepCosmetic(
        title: cell.name.isEmpty ? '(名前なし)' : cell.name,
        detail: '${palette!.displayName}・${cell.type}',
        color: cell.color,
        isItem: false,
        isLost: false,
      );
    }
    return null;
  }

  StepCosmetic _snapshot(MakeupStep step, {required bool isItem}) =>
      StepCosmetic(
        title: step.snapTitle,
        detail: step.snapDetail,
        color: step.snapColor,
        isItem: isItem,
        isLost: true,
      );

  // ---- バックアップ ----

  /// バックアップ用の文字列。
  String exportJson() => jsonEncode(_data.toJson());

  /// バックアップの文字列からデータを戻す。読めなければ false。
  bool importJson(String text) {
    try {
      _data = AppData.fromJson(jsonDecode(text.trim()) as Map<String, dynamic>);
    } on FormatException {
      return false;
    } on TypeError {
      return false;
    }
    changed();
    return true;
  }
}
