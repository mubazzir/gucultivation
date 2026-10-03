import 'package:hive/hive.dart';


/// Static template loaded from JSON assets
class GuWormTemplate {
  final int id;
  final String name;
  final int rank;
  final String rarity;
  final String daoPath;
  final String source;
  final String refinementMaterials;
  final double? refinementSuccess;
  final double? obtainmentProbability;
  final String description;

  GuWormTemplate({
    required this.id,
    required this.name,
    required this.rank,
    required this.rarity,
    required this.daoPath,
    required this.source,
    required this.refinementMaterials,
    this.refinementSuccess,
    this.obtainmentProbability,
    required this.description,
  });

  factory GuWormTemplate.fromJson(Map<String, dynamic> json) => GuWormTemplate(
    id: json['id'] as int,
    name: json['name'] as String? ?? 'Unknown',
    rank: json['rank'] as int? ?? 1,
    rarity: json['rarity'] as String? ?? 'Common',
    daoPath: json['daoPath'] as String? ?? 'Unknown',
    source: json['source'] as String? ?? 'Original',
    refinementMaterials: json['refinementMaterials'] as String? ?? '',
    refinementSuccess: (json['refinementSuccess'] as num?)?.toDouble(),
    obtainmentProbability: (json['obtainmentProbability'] as num?)?.toDouble(),
    description: json['description'] as String? ?? '',
  );

  String get key => 'gu_$id';
}

/// Owned Gu instance stored in Hive
@HiveType(typeId: 3)
class OwnedGu extends HiveObject {
  @HiveField(0)
  int guId; // references GuWormTemplate.id

  @HiveField(1)
  int quantity;

  @HiveField(2)
  bool isRefined;

  @HiveField(3)
  DateTime obtainedAt;

  @HiveField(4)
  int masteryLevel; // for future use with duplicates

  OwnedGu({
    required this.guId,
    this.quantity = 1,
    this.isRefined = false,
    required this.obtainedAt,
    this.masteryLevel = 0,
  });

  Map<String, dynamic> toJson() => {
    'guId': guId,
    'quantity': quantity,
    'isRefined': isRefined,
    'obtainedAt': obtainedAt.toIso8601String(),
    'masteryLevel': masteryLevel,
  };

  factory OwnedGu.fromJson(Map<String, dynamic> json) => OwnedGu(
    guId: json['guId'] as int,
    quantity: json['quantity'] as int? ?? 1,
    isRefined: json['isRefined'] as bool? ?? false,
    obtainedAt: DateTime.parse(json['obtainedAt'] as String),
    masteryLevel: json['masteryLevel'] as int? ?? 0,
  );
}
