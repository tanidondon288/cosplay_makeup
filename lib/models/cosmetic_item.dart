import 'id.dart';

/// ハイライトなど、1色しかない単品コスメ。
class CosmeticItem {
  CosmeticItem({
    String? id,
    this.brand = '',
    required this.product,
    this.shade = '',
  }) : id = id ?? generateId();

  final String id;

  /// ブランド名。
  String brand;

  /// 商品名。
  String product;

  /// カラバリ(色の名前や番号)。
  String shade;

  /// ブランド名と商品名をつないだ名前。
  String get displayName =>
      [brand, product].where((s) => s.isNotEmpty).join(' ');

  Map<String, dynamic> toJson() => {
    'id': id,
    'brand': brand,
    'product': product,
    'shade': shade,
  };

  factory CosmeticItem.fromJson(Map<String, dynamic> json) => CosmeticItem(
    id: json['id'] as String,
    brand: json['brand'] as String? ?? '',
    product: json['product'] as String? ?? '',
    shade: json['shade'] as String? ?? '',
  );
}
