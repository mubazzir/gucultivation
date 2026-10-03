import 'dart:math';
import '../config/cultivation_config.dart';
import '../models/user_profile.dart';
import 'persistence_service.dart';

class CultivationService {
  final PersistenceService _db = PersistenceService();

  Future<void> startCultivation({String? pathId}) async {
    final session = _db.getSession();
    if (session.isActive && !session.isPaused) return;

    final now = DateTime.now();
    if (session.isPaused && session.isActive) {
      session.isPaused = false;
      session.sessionStart = now;
      session.pauseStart = null;
    } else {
      session.isActive = true;
      session.isPaused = false;
      session.sessionStart = now;
      session.pauseStart = null;
      session.accumulatedSeconds = 0;
      session.pathId = pathId ?? _db.getProfile()?.selectedPathId;
    }
    await _db.saveSession(session);
  }

  Future<void> pauseCultivation() async {
    final session = _db.getSession();
    if (!session.isActive || session.isPaused) return;

    final elapsed = session.getElapsedSeconds();
    session.accumulatedSeconds = elapsed;
    session.isPaused = true;
    session.pauseStart = DateTime.now();
    session.sessionStart = null;
    await _db.saveSession(session);
  }

  /// Stops cultivation, applies study time, returns session seconds elapsed.
  Future<int> stopCultivation() async {
    final session = _db.getSession();
    if (!session.isActive) return 0;

    final elapsed = session.getElapsedSeconds();
    await _applyStudyTime(elapsed, session.pathId, grantStones: true);

    session.isActive = false;
    session.isPaused = false;
    session.sessionStart = null;
    session.pauseStart = null;
    session.accumulatedSeconds = 0;
    await _db.saveSession(session);

    final stats = _db.getStats();
    stats.totalSessions += 1;
    await _db.saveStats(stats);
    return elapsed;
  }

  Future<int> syncSession() async {
    final session = _db.getSession();
    if (!session.isActive || session.isPaused) {
      return session.accumulatedSeconds;
    }
    return session.getElapsedSeconds();
  }

  Future<void> _applyStudyTime(
      int seconds,
      String? pathId, {
        bool grantStones = true,
      }) async {
    if (seconds <= 0) return;
    final profile = _db.getProfile();
    if (profile == null) return;

    profile.totalStudySeconds += seconds;

    final today =
    DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    if (profile.todayDate == null ||
        profile.todayDate!.year != today.year ||
        profile.todayDate!.month != today.month ||
        profile.todayDate!.day != today.day) {
      profile.todayStudySeconds = 0;
      profile.todayDate = today;
    }
    profile.todayStudySeconds += seconds;

    _updateStreak(profile, today);

    final modifier = profile.aptitudeModifier;
    final essenceGained =
        (seconds / CultivationConfig.secondsPerEssence) * modifier;
    profile.currentEssenceInStage += essenceGained;
    profile.totalEssenceEarned += essenceGained;

    if (grantStones) {
      profile.secondsTowardNextStone += seconds;
      final gained = profile.secondsTowardNextStone ~/
          CultivationConfig.secondsPerPrimalStone;
      if (gained > 0) {
        profile.primalStones += gained;
        profile.secondsTowardNextStone %=
            CultivationConfig.secondsPerPrimalStone;
      }
    }

    if (pathId != null) {
      final path = _db.getPath(pathId);
      if (path != null) {
        final xpGained = (seconds / 30.0) * modifier;
        path.currentXp += xpGained;
        path.totalStudySeconds += seconds;
        while (path.level < 5 && path.currentXp >= path.xpToNext) {
          path.currentXp -= path.xpToNext;
          path.level += 1;
        }
        await _db.savePath(path);
      }
    }

    await _checkStageProgress(profile);

    final stats = _db.getStats();
    final key =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    stats.dailyStudySeconds[key] =
        (stats.dailyStudySeconds[key] ?? 0) + seconds;
    await _db.saveStats(stats);

    await _db.saveProfile(profile);
  }

  void _updateStreak(UserProfile profile, DateTime today) {
    if (profile.lastCultivationDate == null) {
      profile.currentStreak = 1;
      profile.longestStreak = 1;
      profile.lastCultivationDate = today;
      return;
    }
    final last = profile.lastCultivationDate!;
    final diff =
        today.difference(DateTime(last.year, last.month, last.day)).inDays;
    if (diff == 0) {
      // same day
    } else if (diff == 1) {
      profile.currentStreak += 1;
      if (profile.currentStreak > profile.longestStreak) {
        profile.longestStreak = profile.currentStreak;
      }
      profile.lastCultivationDate = today;
    } else {
      profile.currentStreak = 1;
      profile.lastCultivationDate = today;
    }
  }

  Future<void> _checkStageProgress(UserProfile profile) async {
    while (true) {
      final needed = CultivationConfig.essenceForStage(
        profile.cultivationRank,
        profile.realmStage,
      );
      if (profile.currentEssenceInStage < needed) break;

      profile.currentEssenceInStage -= needed;
      if (profile.realmStage < 3) {
        profile.realmStage += 1;
      } else {
        profile.currentEssenceInStage += needed;
        break;
      }
    }
  }

  Future<bool> spendStoneToAccelerate({int stones = 1}) async {
    final profile = _db.getProfile();
    if (profile == null || profile.primalStones < stones) return false;
    profile.primalStones -= stones;
    await _db.saveProfile(profile);

    final bonusSeconds =
        stones * CultivationConfig.accelerateSecondsPerStone;
    await _applyStudyTime(
      bonusSeconds,
      profile.selectedPathId,
      grantStones: false,
    );
    return true;
  }

  Future<BreakthroughResult> attemptBreakthrough() async {
    final profile = _db.getProfile();
    if (profile == null) {
      return BreakthroughResult(success: false, message: 'No profile.');
    }
    if (profile.realmStage < 3) {
      return BreakthroughResult(
        success: false,
        message: 'You must reach Peak Stage before attempting a breakthrough.',
      );
    }
    final needed = CultivationConfig.essenceForStage(
      profile.cultivationRank,
      profile.realmStage,
    );
    if (profile.currentEssenceInStage < needed) {
      return BreakthroughResult(
        success: false,
        message: 'Insufficient Primeval Essence for breakthrough.',
      );
    }

    final baseChance =
        CultivationConfig.breakthroughBaseChance[profile.cultivationRank] ??
            0.5;
    final success = Random().nextDouble() < baseChance;

    if (success) {
      profile.currentEssenceInStage -= needed;
      if (profile.cultivationRank < 9) {
        profile.cultivationRank += 1;
        profile.realmStage = 0;
      }
      final stats = _db.getStats();
      stats.breakthroughs += 1;
      await _db.saveStats(stats);
      await _db.saveProfile(profile);
      return BreakthroughResult(
        success: true,
        message:
        'Breakthrough successful! You have advanced to ${profile.fullCultivationLabel}.',
        newRank: profile.cultivationRank,
        newStage: profile.realmStage,
      );
    } else {
      profile.currentEssenceInStage *= 0.7;
      await _db.saveProfile(profile);
      return BreakthroughResult(
        success: false,
        message:
        'Breakthrough failed. Some Primeval Essence dispersed. Persist, Gu Master.',
      );
    }
  }

  double progressInCurrentStage(UserProfile profile) {
    final needed = CultivationConfig.essenceForStage(
      profile.cultivationRank,
      profile.realmStage,
    );
    if (needed <= 0) return 0;
    return (profile.currentEssenceInStage / needed).clamp(0.0, 1.0);
  }
}

class BreakthroughResult {
  final bool success;
  final String message;
  final int? newRank;
  final int? newStage;

  BreakthroughResult({
    required this.success,
    required this.message,
    this.newRank,
    this.newStage,
  });
}