import 'package:hive/hive.dart';


@HiveType(typeId: 5)
class TaskModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? pathId;

  @HiveField(3)
  String difficulty; // Easy, Normal, Hard, Extreme

  @HiveField(4)
  DateTime? deadline;

  @HiveField(5)
  bool isCompleted;

  @HiveField(6)
  bool isDaily;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime? completedAt;

  TaskModel({
    required this.id,
    required this.title,
    this.pathId,
    this.difficulty = 'Normal',
    this.deadline,
    this.isCompleted = false,
    this.isDaily = false,
    required this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'pathId': pathId,
    'difficulty': difficulty,
    'deadline': deadline?.toIso8601String(),
    'isCompleted': isCompleted,
    'isDaily': isDaily,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
    id: json['id'] as String,
    title: json['title'] as String,
    pathId: json['pathId'] as String?,
    difficulty: json['difficulty'] as String? ?? 'Normal',
    deadline: json['deadline'] != null
        ? DateTime.parse(json['deadline'] as String)
        : null,
    isCompleted: json['isCompleted'] as bool? ?? false,
    isDaily: json['isDaily'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String),
    completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'] as String)
        : null,
  );
}
