import 'character.dart';
import 'cosmetic_item.dart';
import 'palette.dart';

/// 保存するデータ全体。
class AppData {
  AppData({
    List<Palette>? palettes,
    List<CosmeticItem>? items,
    List<Character>? characters,
  }) : palettes = palettes ?? [],
       items = items ?? [],
       characters = characters ?? [];

  final List<Palette> palettes;

  /// 単品コスメ。
  final List<CosmeticItem> items;
  final List<Character> characters;

  Map<String, dynamic> toJson() => {
    'version': 2,
    'palettes': [for (final p in palettes) p.toJson()],
    'items': [for (final i in items) i.toJson()],
    'characters': [for (final c in characters) c.toJson()],
  };

  factory AppData.fromJson(Map<String, dynamic> json) => AppData(
    palettes: [
      for (final p in json['palettes'] as List? ?? const [])
        Palette.fromJson(p as Map<String, dynamic>),
    ],
    items: [
      for (final i in json['items'] as List? ?? const [])
        CosmeticItem.fromJson(i as Map<String, dynamic>),
    ],
    characters: [
      for (final c in json['characters'] as List? ?? const [])
        Character.fromJson(c as Map<String, dynamic>),
    ],
  );
}
