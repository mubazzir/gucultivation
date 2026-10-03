import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class UserProfile extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String aptitude;

  @HiveField(3)
  int cultivationRank;

  @HiveField(4)
  int realmStage;

  @HiveField(5)
  double currentEssenceInStage;

  @HiveField(6)
  double totalEssenceEarned;

  @HiveField(7)
  int totalStudySeconds;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime lastActiveAt;

  @HiveField(10)
  int currentStreak;

  @HiveField(11)
  int longestStreak;

  @HiveField(12)
  DateTime? lastCultivationDate;

  @HiveField(13)
  int todayStudySeconds;

  @HiveField(14)
  DateTime? todayDate;

  @HiveField(15)
  String? selectedPathId;

  @HiveField(16)
  int primalStones;

  @HiveField(17)
  int secondsTowardNextStone;

  UserProfile({
    required this.id,
    required this.name,
    required this.aptitude,
    this.cultivationRank = 1,
    this.realmStage = 0,
    this.currentEssenceInStage = 0,
    this.totalEssenceEarned = 0,
    this.totalStudySeconds = 0,
    required this.createdAt,
    required this.lastActiveAt,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCultivationDate,
    this.todayStudySeconds = 0,
    this.todayDate,
    this.selectedPathId,
    this.primalStones = 0,
    this.secondsTowardNextStone = 0,
  });

  String get rankLabel => 'Rank $cultivationRank';
  String get realmLabel {
    const labels = [
      'Initial Stage',
      'Middle Stage',
      'Upper Stage',
      'Peak Stage'
    ];
    return labels[realmStage.clamp(0, 3)];
  }

  String get fullCultivationLabel => '$rankLabel — $realmLabel';

  double get aptitudeModifier {
    switch (aptitude) {
      case 'A':
        return 1.5;
      case 'B':
        return 1.25;
      case 'C':
        return 1.0;
      case 'D':
        return 0.8;
      case 'E':
        return 0.6;
      default:
        return 1.0;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'aptitude': aptitude,
    'cultivationRank': cultivationRank,
    'realmStage': realmStage,
    'currentEssenceInStage': currentEssenceInStage,
    'totalEssenceEarned': totalEssenceEarned,
    'totalStudySeconds': totalStudySeconds,
    'createdAt': createdAt.toIso8601String(),
    'lastActiveAt': lastActiveAt.toIso8601String(),
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'lastCultivationDate': lastCultivationDate?.toIso8601String(),
    'todayStudySeconds': todayStudySeconds,
    'todayDate': todayDate?.toIso8601String(),
    'selectedPathId': selectedPathId,
    'primalStones': primalStones,
    'secondsTowardNextStone': secondsTowardNextStone,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    name: json['name'] as String,
    aptitude: json['aptitude'] as String,
    cultivationRank: json['cultivationRank'] as int? ?? 1,
    realmStage: json['realmStage'] as int? ?? 0,
    currentEssenceInStage:
    (json['currentEssenceInStage'] as num?)?.toDouble() ?? 0,
    totalEssenceEarned:
    (json['totalEssenceEarned'] as num?)?.toDouble() ?? 0,
    totalStudySeconds: json['totalStudySeconds'] as int? ?? 0,
    createdAt: DateTime.parse(json['createdAt'] as String),
    lastActiveAt: DateTime.parse(json['lastActiveAt'] as String),
    currentStreak: json['currentStreak'] as int? ?? 0,
    longestStreak: json['longestStreak'] as int? ?? 0,
    lastCultivationDate: json['lastCultivationDate'] != null
        ? DateTime.parse(json['lastCultivationDate'] as String)
        : null,
    todayStudySeconds: json['todayStudySeconds'] as int? ?? 0,
    todayDate: json['todayDate'] != null
        ? DateTime.parse(json['todayDate'] as String)
        : null,
    selectedPathId: json['selectedPathId'] as String?,
    primalStones: json['primalStones'] as int? ?? 0,
    secondsTowardNextStone: json['secondsTowardNextStone'] as int? ?? 0,
  );
}