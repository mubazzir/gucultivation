import 'package:hive/hive.dart';


@HiveType(typeId: 1)
class CultivationSession extends HiveObject {
  @HiveField(0)
  bool isActive;

  @HiveField(1)
  bool isPaused;

  @HiveField(2)
  DateTime? sessionStart;

  @HiveField(3)
  DateTime? pauseStart;

  @HiveField(4)
  int accumulatedSeconds; // time already counted before current run/pause

  @HiveField(5)
  String? pathId;

  CultivationSession({
    this.isActive = false,
    this.isPaused = false,
    this.sessionStart,
    this.pauseStart,
    this.accumulatedSeconds = 0,
    this.pathId,
  });

  /// Calculate current elapsed seconds using timestamps to survive app kills
  int getElapsedSeconds() {
    if (!isActive) return accumulatedSeconds;
    if (isPaused) {
      return accumulatedSeconds;
    }
    if (sessionStart == null) return accumulatedSeconds;
    final now = DateTime.now();
    final running = now.difference(sessionStart!).inSeconds;
    return accumulatedSeconds + running.clamp(0, 86400 * 7); // safety cap 7 days
  }

  Map<String, dynamic> toJson() => {
    'isActive': isActive,
    'isPaused': isPaused,
    'sessionStart': sessionStart?.toIso8601String(),
    'pauseStart': pauseStart?.toIso8601String(),
    'accumulatedSeconds': accumulatedSeconds,
    'pathId': pathId,
  };

  factory CultivationSession.fromJson(Map<String, dynamic> json) => CultivationSession(
    isActive: json['isActive'] as bool? ?? false,
    isPaused: json['isPaused'] as bool? ?? false,
    sessionStart: json['sessionStart'] != null
        ? DateTime.parse(json['sessionStart'] as String)
        : null,
    pauseStart: json['pauseStart'] != null
        ? DateTime.parse(json['pauseStart'] as String)
        : null,
    accumulatedSeconds: json['accumulatedSeconds'] as int? ?? 0,
    pathId: json['pathId'] as String?,
  );
}
