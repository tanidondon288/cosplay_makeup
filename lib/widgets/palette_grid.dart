import 'dart:math';

import 'package:flutter/material.dart';

import '../models/palette.dart';

/// パレットケースの色(実物のような明るいピンク)。
const _caseColor = Color(0xFFF7DFE4);
const _caseEdgeColor = Color(0xFFEBC6CE);

/// 色を設定していないマスの色。
const _blankCellColor = Color(0xFFFCEFF2);

/// マスの大きさに対する、マスとマスのすき間の割合。
const _gapRatio = 0.14;

/// マスの大きさに対する、ケースのふちの太さの割合。
const _caseRatio = 0.3;

/// パレットをマス目で表示する。結合したマスは1つの大きなマスとして描くので、
/// 内側の境界線は出ない。
class PaletteGrid extends StatelessWidget {
  const PaletteGrid({
    super.key,
    required this.palette,
    this.selectedIds = const {},
    this.onCellTap,
    this.showNames = true,
    this.maxCellSize = 80,
  });

  final Palette palette;
  final Set<String> selectedIds;
  final void Function(PaletteCell cell)? onCellTap;
  final bool showNames;
  final double maxCellSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = palette.cols;
        final rows = palette.rows;
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth -
                  4 // ケースのふちの線の分
            : maxCellSize * cols * 2;
        // マスの たて ÷ よこ。2:3 なら 1.5(縦長)。
        final ratio = palette.aspectH / palette.aspectW;
        // すき間とふちは、マスの短いほうの辺に合わせる。
        final shortSide = min(1.0, ratio);
        // 横幅 = マス×cols + すき間×(cols-1) + ケースのふち×2 から、マスの幅を決める。
        // マスの長いほうの辺が maxCellSize を超えないようにする。
        final cellW = max(
          4.0,
          min(
            maxCellSize / max(1.0, ratio),
            available /
                (cols + (_gapRatio * (cols - 1) + _caseRatio * 2) * shortSide),
          ),
        );
        final cellH = cellW * ratio;
        final unit = min(cellW, cellH);
        final gap = unit * _gapRatio;
        final edge = unit * _caseRatio;
        double extentX(int span) => cellW * span + gap * (span - 1);
        double extentY(int span) => cellH * span + gap * (span - 1);
        double offsetX(int index) => (cellW + gap) * index;
        double offsetY(int index) => (cellH + gap) * index;

        return Center(
          child: Container(
            padding: EdgeInsets.all(edge),
            decoration: BoxDecoration(
              color: _caseColor,
              borderRadius: BorderRadius.circular(edge * 0.5),
              border: Border.all(color: _caseEdgeColor, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: SizedBox(
              width: extentX(cols),
              height: extentY(rows),
              child: Stack(
                children: [
                  for (final cell in palette.cells)
                    Positioned(
                      left: offsetX(cell.col),
                      top: offsetY(cell.row),
                      width: extentX(cell.colSpan),
                      height: extentY(cell.rowSpan),
                      child: PaletteCellView(
                        cell: cell,
                        selected: selectedIds.contains(cell.id),
                        showName: showNames,
                        radius: unit * 0.1,
                        onTap: onCellTap == null
                            ? null
                            : () => onCellTap!(cell),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 色を明るく(amount > 0)または暗く(amount < 0)する。
Color _shade(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
}

/// パレットの1マス。実物のパンのように、ふちの線と少しの立体感を付ける。
class PaletteCellView extends StatelessWidget {
  const PaletteCellView({
    super.key,
    required this.cell,
    this.selected = false,
    this.showName = true,
    this.radius = 6,
    this.onTap,
  });

  final PaletteCell cell;
  final bool selected;
  final bool showName;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isBlank = cell.color == null;
    final color = isBlank ? _blankCellColor : Color(cell.color!);
    final textColor = color.computeLuminance() > 0.45
        ? Colors.black87
        : Colors.white;

    Widget? child;
    if (showName && cell.name.isNotEmpty) {
      child = Text(
        cell.name,
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11, height: 1.15, color: textColor),
      );
    } else if (showName && isBlank) {
      child = const Icon(Icons.add, size: 16, color: Color(0xFFD9A7B3));
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: color,
          // 左上を少し明るくして、粉がふんわり入っているように見せる。
          gradient: isBlank
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_shade(color, 0.06), color, _shade(color, -0.04)],
                ),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : isBlank
                ? _caseEdgeColor
                : _shade(color, -0.18),
            width: selected ? 3 : 1,
          ),
        ),
        child: child,
      ),
    );
  }
}

/// 記録の一覧などで使う、小さな色見本。
class ColorSwatchBox extends StatelessWidget {
  const ColorSwatchBox({super.key, required this.color, this.size = 36});

  final int? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color == null ? _blankCellColor : Color(color!),
        borderRadius: BorderRadius.circular(size / 4),
        border: Border.all(color: Colors.black12),
      ),
    );
  }
}
