import 'dart:math';

import 'id.dart';

/// マスに設定できるコスメの種類。
const makeupTypes = ['アイシャドウ', 'シェーディング', 'ハイライト', 'チーク', 'その他'];

/// パレットを作る・変えるときに決める内容。
typedef PaletteSettings = ({
  String brand,
  String name,
  String shade,
  int rows,
  int cols,
  int aspectW,
  int aspectH,
});

/// パレットの1マス。結合したマスは rowSpan / colSpan が2以上になる。
class PaletteCell {
  PaletteCell({
    String? id,
    required this.row,
    required this.col,
    this.rowSpan = 1,
    this.colSpan = 1,
    this.name = '',
    this.color,
    this.type = 'アイシャドウ',
  }) : id = id ?? generateId();

  final String id;

  /// 左上の位置(0から数える)。
  int row;
  int col;

  /// たて・よこに何マス分つながっているか。
  int rowSpan;
  int colSpan;

  /// 色の名前(例: 「03 テラコッタ」)。
  String name;

  /// 色(ARGB)。まだ設定していないマスは null。
  int? color;

  /// アイシャドウ、シェーディングなどの種類。
  String type;

  bool get isMerged => rowSpan > 1 || colSpan > 1;

  /// 何も設定されていないマスかどうか。
  bool get isBlank => color == null && name.isEmpty;

  /// 指定した位置がこのマスに含まれるかどうか。
  bool contains(int r, int c) =>
      r >= row && r < row + rowSpan && c >= col && c < col + colSpan;

  Map<String, dynamic> toJson() => {
    'id': id,
    'row': row,
    'col': col,
    'rowSpan': rowSpan,
    'colSpan': colSpan,
    'name': name,
    'color': color,
    'type': type,
  };

  factory PaletteCell.fromJson(Map<String, dynamic> json) => PaletteCell(
    id: json['id'] as String,
    row: json['row'] as int,
    col: json['col'] as int,
    rowSpan: json['rowSpan'] as int? ?? 1,
    colSpan: json['colSpan'] as int? ?? 1,
    name: json['name'] as String? ?? '',
    color: json['color'] as int?,
    type: json['type'] as String? ?? makeupTypes.first,
  );
}

/// たて rows マス × よこ cols マスのパレット。
class Palette {
  Palette({
    String? id,
    this.brand = '',
    required this.name,
    this.shade = '',
    required this.rows,
    required this.cols,
    this.aspectW = 1,
    this.aspectH = 1,
    List<PaletteCell>? cells,
  }) : id = id ?? generateId(),
       cells = cells ?? [] {
    normalize();
  }

  final String id;

  /// ブランド名(例: dasique)。
  String brand;

  /// パレット名(商品名。例: シャドウパレット)。
  String name;

  /// カラー(例: 01 シュガーバレエ)。
  String shade;
  int rows;
  int cols;

  /// 1マスの形。よこ aspectW : たて aspectH(例: 2:3 なら縦長)。
  int aspectW;
  int aspectH;

  final List<PaletteCell> cells;

  /// ブランド名・パレット名・カラーをつないだ、一覧などに出す名前。
  String get displayName =>
      [brand, name, shade].where((s) => s.isNotEmpty).join(' ');

  PaletteCell? cellById(String? id) {
    for (final cell in cells) {
      if (cell.id == id) return cell;
    }
    return null;
  }

  PaletteCell? cellAt(int r, int c) {
    for (final cell in cells) {
      if (cell.contains(r, c)) return cell;
    }
    return null;
  }

  /// 枠からはみ出したマスを削り、空いた場所に1マスを補い、左上から順に並べる。
  void normalize() {
    cells.removeWhere((c) => c.row >= rows || c.col >= cols);
    for (final cell in cells) {
      cell.rowSpan = min(cell.rowSpan, rows - cell.row);
      cell.colSpan = min(cell.colSpan, cols - cell.col);
    }
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (cellAt(r, c) == null) {
          cells.add(PaletteCell(row: r, col: c));
        }
      }
    }
    cells.sort((a, b) {
      final byRow = a.row.compareTo(b.row);
      return byRow != 0 ? byRow : a.col.compareTo(b.col);
    });
  }

  /// マス数を小さくしたときに消える、設定済みのマス。
  List<PaletteCell> cellsLostByResize(int newRows, int newCols) => cells
      .where((c) => (c.row >= newRows || c.col >= newCols) && !c.isBlank)
      .toList();

  void resize(int newRows, int newCols) {
    rows = newRows;
    cols = newCols;
    normalize();
  }

  /// 選んだマスが、すき間のない長方形になっているときだけ結合できる。
  bool canMerge(Set<String> ids) {
    if (ids.length < 2) return false;
    final selected = cells.where((c) => ids.contains(c.id)).toList();
    if (selected.length != ids.length) return false;

    final top = selected.map((c) => c.row).reduce(min);
    final left = selected.map((c) => c.col).reduce(min);
    final bottom = selected.map((c) => c.row + c.rowSpan).reduce(max);
    final right = selected.map((c) => c.col + c.colSpan).reduce(max);
    final area = selected.fold<int>(0, (sum, c) => sum + c.rowSpan * c.colSpan);
    // マスは重ならないので、面積が長方形と同じならすき間なく埋まっている。
    return area == (bottom - top) * (right - left);
  }

  /// 選んだマスを1つにつなげる。色と名前は、色が設定されている最初のマスのものを残す。
  ///
  /// 結合できないときは null を返す。
  PaletteCell? merge(Set<String> ids) {
    if (!canMerge(ids)) return null;
    final selected = cells.where((c) => ids.contains(c.id)).toList();

    final top = selected.map((c) => c.row).reduce(min);
    final left = selected.map((c) => c.col).reduce(min);
    final bottom = selected.map((c) => c.row + c.rowSpan).reduce(max);
    final right = selected.map((c) => c.col + c.colSpan).reduce(max);

    final base = selected.firstWhere(
      (c) => !c.isBlank,
      orElse: () => selected.first,
    );
    base
      ..row = top
      ..col = left
      ..rowSpan = bottom - top
      ..colSpan = right - left;
    cells.removeWhere((c) => ids.contains(c.id) && c.id != base.id);
    normalize();
    return base;
  }

  /// 結合したマスを1マスずつに戻す。どのマスにも同じ色と名前を入れる。
  void unmerge(String id) {
    final cell = cellById(id);
    if (cell == null || !cell.isMerged) return;
    for (var r = cell.row; r < cell.row + cell.rowSpan; r++) {
      for (var c = cell.col; c < cell.col + cell.colSpan; c++) {
        if (r == cell.row && c == cell.col) continue;
        cells.add(
          PaletteCell(
            row: r,
            col: c,
            name: cell.name,
            color: cell.color,
            type: cell.type,
          ),
        );
      }
    }
    cell
      ..rowSpan = 1
      ..colSpan = 1;
    normalize();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'brand': brand,
    'name': name,
    'shade': shade,
    'rows': rows,
    'cols': cols,
    'aspectW': aspectW,
    'aspectH': aspectH,
    'cells': [for (final c in cells) c.toJson()],
  };

  factory Palette.fromJson(Map<String, dynamic> json) => Palette(
    id: json['id'] as String,
    brand: json['brand'] as String? ?? '',
    name: json['name'] as String,
    shade: json['shade'] as String? ?? '',
    rows: json['rows'] as int,
    cols: json['cols'] as int,
    aspectW: json['aspectW'] as int? ?? 1,
    aspectH: json['aspectH'] as int? ?? 1,
    cells: [
      for (final c in json['cells'] as List? ?? const [])
        PaletteCell.fromJson(c as Map<String, dynamic>),
    ],
  );
}
