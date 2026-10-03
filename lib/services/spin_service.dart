import 'dart:math';
import '../config/cultivation_config.dart';
import '../models/gu_worm.dart';
import '../models/material_item.dart';
import 'persistence_service.dart';

enum SpinTier { basic, great, ultra }

class SpinReward {
  final bool isGu;
  final GuWormTemplate? gu;
  final MaterialTemplate? material;
  final int materialQty;
  final SpinTier tier;

  SpinReward({
    required this.isGu,
    this.gu,
    this.material,
    this.materialQty = 1,
    required this.tier,
  });

  String get displayName {
    if (isGu && gu != null) return gu!.name;
    if (material != null) return '${material!.name} ×$materialQty';
    return 'Nothing';
  }
}

class SpinService {
  final PersistenceService _db = PersistenceService();
  final Random _rng = Random();

  SpinTier? tierForSeconds(int seconds) {
    if (seconds >= CultivationConfig.ultraSpinSeconds) return SpinTier.ultra;
    if (seconds >= CultivationConfig.greatSpinSeconds) return SpinTier.great;
    if (seconds >= CultivationConfig.basicSpinSeconds) return SpinTier.basic;
    return null;
  }

  String tierLabel(SpinTier tier) {
    switch (tier) {
      case SpinTier.basic:
        return 'Basic Spin';
      case SpinTier.great:
        return 'Great Spin';
      case SpinTier.ultra:
        return 'Ultra Spin';
    }
  }

  Map<int, double> _weightsFor(SpinTier tier) {
    switch (tier) {
      case SpinTier.basic:
        return CultivationConfig.basicSpinRankWeights;
      case SpinTier.great:
        return CultivationConfig.greatSpinRankWeights;
      case SpinTier.ultra:
        return CultivationConfig.ultraSpinRankWeights;
    }
  }

  int _pickRank(Map<int, double> weights, List<GuWormTemplate> templates) {
    final usable = <int, double>{};
    double total = 0;
    weights.forEach((rank, w) {
      if (templates.any((g) => g.rank == rank)) {
        usable[rank] = w;
        total += w;
      }
    });
    if (total <= 0) return 1;
    double roll = _rng.nextDouble() * total;
    for (final e in usable.entries) {
      roll -= e.value;
      if (roll <= 0) return e.key;
    }
    return usable.keys.first;
  }

  Future<SpinReward> spin(SpinTier tier) async {
    final giveGu = _rng.nextDouble() < 0.55;
    final templates = _db.guTemplates;
    final materials = _db.materialTemplates;

    if (giveGu && templates.isNotEmpty) {
      final weights = _weightsFor(tier);
      final rank = _pickRank(weights, templates);
      final pool = templates.where((g) => g.rank == rank).toList();
      if (pool.isNotEmpty) {
        final chosen = pool[_rng.nextInt(pool.length)];
        await _db.addGu(chosen.id);
        return SpinReward(isGu: true, gu: chosen, tier: tier);
      }
    }

    if (materials.isNotEmpty) {
      final maxRank = tier == SpinTier.ultra
          ? 6
          : tier == SpinTier.great
          ? 4
          : 2;
      final pool =
      materials.where((m) => m.typicalRank <= maxRank).toList();
      final list = pool.isNotEmpty ? pool : materials;
      final chosen = list[_rng.nextInt(list.length)];
      final qty = tier == SpinTier.ultra
          ? 2 + _rng.nextInt(3)
          : tier == SpinTier.great
          ? 1 + _rng.nextInt(2)
          : 1;
      await _db.addMaterial(chosen.id, qty);
      return SpinReward(
        isGu: false,
        material: chosen,
        materialQty: qty,
        tier: tier,
      );
    }

    if (templates.isNotEmpty) {
      final chosen = templates[_rng.nextInt(templates.length)];
      await _db.addGu(chosen.id);
      return SpinReward(isGu: true, gu: chosen, tier: tier);
    }

    return SpinReward(isGu: false, tier: tier);
  }
}