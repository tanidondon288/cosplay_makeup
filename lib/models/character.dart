import 'id.dart';

/// メイクの1工程。「どこに」「どのコスメを」「どう塗ったか」。
///
/// コスメはパレットのマス・単品コスメ・なし のどれか。
class MakeupStep {
  MakeupStep({
    String? id,
    this.part = '',
    this.paletteId,
    this.cellId,
    this.itemId,
    this.snapTitle = '',
    this.snapDetail = '',
    this.snapColor,
    this.memo = '',
  }) : id = id ?? generateId();

  final String id;

  /// 塗る場所(自由入力。例: アイホール)。
  String part;

  /// パレットのマスを使ったとき。
  String? paletteId;
  String? cellId;

  /// 単品コスメを使ったとき。
  String? itemId;

  /// 使ったコスメの控え。コスメを削除しても工程に残るようにする。
  String snapTitle;
  String snapDetail;
  int? snapColor;

  String memo;

  bool get usesPalette => cellId != null;
  bool get usesItem => itemId != null;

  void usePaletteCell(String paletteId, String cellId) {
    this.paletteId = paletteId;
    this.cellId = cellId;
    itemId = null;
  }

  void useItem(String itemId) {
    this.itemId = itemId;
    paletteId = null;
    cellId = null;
  }

  void clearCosmetic() {
    paletteId = null;
    cellId = null;
    itemId = null;
    snapTitle = '';
    snapDetail = '';
    snapColor = null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'part': part,
    'paletteId': paletteId,
    'cellId': cellId,
    'itemId': itemId,
    'snapTitle': snapTitle,
    'snapDetail': snapDetail,
    'snapColor': snapColor,
    'memo': memo,
  };

  factory MakeupStep.fromJson(Map<String, dynamic> json) => MakeupStep(
    id: json['id'] as String,
    part: json['part'] as String? ?? '',
    paletteId: json['paletteId'] as String?,
    cellId: json['cellId'] as String?,
    itemId: json['itemId'] as String?,
    snapTitle: json['snapTitle'] as String? ?? '',
    snapDetail: json['snapDetail'] as String? ?? '',
    snapColor: json['snapColor'] as int?,
    memo: json['memo'] as String? ?? '',
  );
}

/// タイトルを付けたメイク1つ(フォルダのようなもの)。中に工程を順番に積み重ねる。
class MakeupLook {
  MakeupLook({
    String? id,
    required this.title,
    int? updatedAt,
    this.pinned = false,
    List<MakeupStep>? steps,
  }) : id = id ?? generateId(),
       updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch,
       steps = steps ?? [];

  final String id;
  String title;

  /// 最後に変更した日時(ミリ秒)。
  int updatedAt;

  /// お気に入り(☆)。ホームのいちばん上に出る。
  bool pinned;
  final List<MakeupStep> steps;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'updatedAt': updatedAt,
    'pinned': pinned,
    'steps': [for (final s in steps) s.toJson()],
  };

  factory MakeupLook.fromJson(Map<String, dynamic> json) => MakeupLook(
    id: json['id'] as String,
    title: json['title'] as String,
    updatedAt: json['updatedAt'] as int?,
    pinned: json['pinned'] as bool? ?? false,
    steps: [
      for (final s in json['steps'] as List? ?? const [])
        MakeupStep.fromJson(s as Map<String, dynamic>),
    ],
  );
}

/// コスプレするキャラクター1人。メイクを複数持てる。
class Character {
  Character({
    String? id,
    required this.name,
    this.work = '',
    this.memo = '',
    List<MakeupLook>? looks,
  }) : id = id ?? generateId(),
       looks = looks ?? [];

  final String id;
  String name;

  /// 作品名。
  String work;
  String memo;
  final List<MakeupLook> looks;

  MakeupLook? lookById(String? id) {
    for (final look in looks) {
      if (look.id == id) return look;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'work': work,
    'memo': memo,
    'looks': [for (final l in looks) l.toJson()],
  };

  factory Character.fromJson(Map<String, dynamic> json) => Character(
    id: json['id'] as String,
    name: json['name'] as String,
    work: json['work'] as String? ?? '',
    memo: json['memo'] as String? ?? '',
    looks: [
      for (final l in json['looks'] as List? ?? const [])
        MakeupLook.fromJson(l as Map<String, dynamic>),
    ],
  );
}
