import 'package:hive/hive.dart';


/// Static template from JSON
class MaterialTemplate {
  final int id;
  final String name;
  final String category;
  final String daoPath;
  final String rarity;
  final int typicalRank;
  final int minRank;
  final int maxRank;
  final String whereFound;
  final dynamic price;
  final String priceUnit;
  final double? obtainmentProbability;
  final String description;

  MaterialTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.daoPath,
    required this.rarity,
    required this.typicalRank,
    required this.minRank,
    required this.maxRank,
    required this.whereFound,
    this.price,
    required this.priceUnit,
    this.obtainmentProbability,
    required this.description,
  });

  factory MaterialTemplate.fromJson(Map<String, dynamic> json) => MaterialTemplate(
    id: json['id'] as int,
    name: json['name'] as String? ?? 'Unknown',
    category: json['category'] as String? ?? 'Misc',
    daoPath: json['daoPath'] as String? ?? 'Unknown',
    rarity: json['rarity'] as String? ?? 'Common',
    typicalRank: json['typicalRank'] as int? ?? 1,
    minRank: json['minRank'] as int? ?? 1,
    maxRank: json['maxRank'] as int? ?? 1,
    whereFound: json['whereFound'] as String? ?? '',
    price: json['price'],
    priceUnit: json['priceUnit'] as String? ?? 'primal stones',
    obtainmentProbability: (json['obtainmentProbability'] as num?)?.toDouble(),
    description: json['description'] as String? ?? '',
  );

  String get key => 'mat_$id';
}

/// Owned material quantity
@HiveType(typeId: 4)
class OwnedMaterial extends HiveObject {
  @HiveField(0)
  int materialId;

  @HiveField(1)
  int quantity;

  OwnedMaterial({
    required this.materialId,
    this.quantity = 0,
  });

  Map<String, dynamic> toJson() => {
    'materialId': materialId,
    'quantity': quantity,
  };

  factory OwnedMaterial.fromJson(Map<String, dynamic> json) => OwnedMaterial(
    materialId: json['materialId'] as int,
    quantity: json['quantity'] as int? ?? 0,
  );
}
