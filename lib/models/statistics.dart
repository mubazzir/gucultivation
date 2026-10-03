import 'package:hive/hive.dart';


@HiveType(typeId: 6)
class Statistics extends HiveObject {
  @HiveField(0)
  int tasksCompleted;

  @HiveField(1)
  int guObtained;

  @HiveField(2)
  int guRefined;

  @HiveField(3)
  int materialsObtained;

  @HiveField(4)
  int breakthroughs;

  @HiveField(5)
  int eventsTriggered;

  @HiveField(6)
  int totalSessions;

  @HiveField(7)
  Map<String, int> dailyStudySeconds; // key: yyyy-MM-dd

  Statistics({
    this.tasksCompleted = 0,
    this.guObtained = 0,
    this.guRefined = 0,
    this.materialsObtained = 0,
    this.breakthroughs = 0,
    this.eventsTriggered = 0,
    this.totalSessions = 0,
    Map<String, int>? dailyStudySeconds,
  }) : dailyStudySeconds = dailyStudySeconds ?? {};

  Map<String, dynamic> toJson() => {
    'tasksCompleted': tasksCompleted,
    'guObtained': guObtained,
    'guRefined': guRefined,
    'materialsObtained': materialsObtained,
    'breakthroughs': breakthroughs,
    'eventsTriggered': eventsTriggered,
    'totalSessions': totalSessions,
    'dailyStudySeconds': dailyStudySeconds,
  };

  factory Statistics.fromJson(Map<String, dynamic> json) => Statistics(
    tasksCompleted: json['tasksCompleted'] as int? ?? 0,
    guObtained: json['guObtained'] as int? ?? 0,
    guRefined: json['guRefined'] as int? ?? 0,
    materialsObtained: json['materialsObtained'] as int? ?? 0,
    breakthroughs: json['breakthroughs'] as int? ?? 0,
    eventsTriggered: json['eventsTriggered'] as int? ?? 0,
    totalSessions: json['totalSessions'] as int? ?? 0,
    dailyStudySeconds: (json['dailyStudySeconds'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, v as int)) ??
        {},
  );
}
