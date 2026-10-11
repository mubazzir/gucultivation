import 'package:hive/hive.dart';
import '../config/cultivation_config.dart';
import '../core/constants/app_constants.dart';

@HiveType(typeId: 2)
class PathModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int level;

  @HiveField(3)
  double currentXp;

  @HiveField(4)
  int totalStudySeconds;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  int daoMarks;

  PathModel({
    required this.id,
    required this.name,
    this.level = 0,
    this.currentXp = 0,
    this.totalStudySeconds = 0,
    required this.createdAt,
    this.daoMarks = 0,
  });

  /// e.g. "Wisdom Path" → "Wisdom Dao Mark"
  String get daoMarkLabel {
    final base = name
        .replaceAll(RegExp(r'\s*path\s*', caseSensitive: false), '')
        .trim();
    if (base.isEmpty) return 'Dao Mark';
    return '$base Dao Mark';
  }

  bool get isHeavenPath => name.toLowerCase().contains('heaven');

  String get attainmentLabel {
    if (level < 0) return AppConstants.attainmentRanks[0];
    if (level >= AppConstants.attainmentRanks.length) {
      return AppConstants.attainmentRanks.last;
    }
    return AppConstants.attainmentRanks[level];
  }

  double get xpToNext {
    if (level >= AppConstants.attainmentRanks.length - 1) return 0;
    return CultivationConfig.pathXpForLevel(level);
  }

  double get progressPercent {
    final needed = xpToNext;
    if (needed <= 0) return 1.0;
    return (currentXp / needed).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'level': level,
    'currentXp': currentXp,
    'totalStudySeconds': totalStudySeconds,
    'createdAt': createdAt.toIso8601String(),
    'daoMarks': daoMarks,
  };

  factory PathModel.fromJson(Map<String, dynamic> json) => PathModel(
    id: json['id'] as String,
    name: json['name'] as String,
    level: json['level'] as int? ?? 0,
    currentXp: (json['currentXp'] as num?)?.toDouble() ?? 0,
    totalStudySeconds: json['totalStudySeconds'] as int? ?? 0,
    createdAt: DateTime.parse(json['createdAt'] as String),
    daoMarks: json['daoMarks'] as int? ?? 0,
  );
}