/// Central configuration for cultivation progression.
class CultivationConfig {
  static const int secondsPerEssence = 60;

  static const double baseEssencePerStage = 30.0;
  static const double rankGrowthFactor = 3.2;
  static const double stageGrowthFactor = 1.6;

  static const Map<int, double> breakthroughBaseChance = {
    1: 1.0,
    2: 0.95,
    3: 0.90,
    4: 0.80,
    5: 0.70,
    6: 0.55,
    7: 0.40,
    8: 0.25,
    9: 0.15,
  };

  static double essenceRequiredFor(int rank, int stageIndex) {
    double total = 0;
    for (int r = 1; r <= rank; r++) {
      final stagesInRank = (r == rank) ? stageIndex : 4;
      for (int s = 0; s < stagesInRank; s++) {
        total += essenceForStage(r, s);
      }
    }
    return total;
  }

  static double essenceForStage(int rank, int stageIndex) {
    final rankMultiplier = rankGrowthFactor * (rank - 1);
    final stageMultiplier = stageGrowthFactor * stageIndex;
    return baseEssencePerStage * (1 + rankMultiplier) * (1 + stageMultiplier);
  }

  static double essenceToNextStage(
      int rank, int stageIndex, double currentEssenceInStage) {
    final needed = essenceForStage(rank, stageIndex);
    return (needed - currentEssenceInStage).clamp(0, needed);
  }

  static const double pathBaseXp = 100.0;
  static const double pathGrowthFactor = 2.15;

  static double pathXpForLevel(int level) {
    return pathBaseXp * (pathGrowthFactor * level);
  }

  static double cumulativePathXp(int level) {
    double total = 0;
    for (int i = 0; i < level; i++) {
      total += pathXpForLevel(i);
    }
    return total;
  }

  // Spin tiers (seconds)
  static const int basicSpinSeconds = 25 * 60;
  static const int greatSpinSeconds = 60 * 60;
  static const int ultraSpinSeconds = 5 * 60 * 60;

  static const Map<int, double> basicSpinRankWeights = {
    1: 70.0,
    2: 25.0,
    3: 5.0,
  };

  static const Map<int, double> greatSpinRankWeights = {
    1: 40.0,
    2: 30.0,
    3: 20.0,
    4: 10.0,
  };

  static const Map<int, double> ultraSpinRankWeights = {
    2: 25.0,
    3: 30.0,
    4: 25.0,
    5: 12.0,
    6: 6.0,
    7: 2.0,
  };

  static const int secondsPerPrimalStone = 3600;
  static const int accelerateSecondsPerStone = 10 * 60;
  static const int materialsRequiredPerGuRank = 2;
}

class GuDropConfig {
  static const Map<int, double> rankWeights = {
    1: 50.0,
    2: 25.0,
    3: 12.0,
    4: 6.0,
    5: 3.0,
    6: 1.5,
    7: 0.8,
    8: 0.3,
    9: 0.1,
  };

  static const double taskGuChanceEasy = 0.15;
  static const double taskGuChanceNormal = 0.25;
  static const double taskGuChanceHard = 0.40;
  static const double taskGuChanceExtreme = 0.55;
  static const double eventGuChance = 0.35;
  static const double milestoneGuChance = 0.50;
  static const double breakthroughGuChance = 0.60;
}