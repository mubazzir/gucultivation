import 'dart:math';
import '../config/cultivation_config.dart';
import '../models/gu_worm.dart';
import 'persistence_service.dart';

class GuService {
  final PersistenceService _db = PersistenceService();
  final Random _rng = Random();

  /// Attempt to drop a Gu. Returns the obtained Gu template or null.
  /// Step 1: select rank by weighted probability
  /// Step 2: uniform random among Gu of that rank
  Future<GuWormTemplate?> tryDropGu({int? maxRank}) async {
    final templates = _db.guTemplates;
    if (templates.isEmpty) return null;

    final effectiveMax = maxRank ?? 9;
    final weights = <int, double>{};
    double totalWeight = 0;
    GuDropConfig.rankWeights.forEach((rank, w) {
      if (rank <= effectiveMax && templates.any((g) => g.rank == rank)) {
        weights[rank] = w;
        totalWeight += w;
      }
    });
    if (totalWeight <= 0) return null;

    // Select rank
    double roll = _rng.nextDouble() * totalWeight;
    int selectedRank = 1;
    for (final entry in weights.entries) {
      roll -= entry.value;
      if (roll <= 0) {
        selectedRank = entry.key;
        break;
      }
    }

    // Uniform among that rank
    final pool = templates.where((g) => g.rank == selectedRank).toList();
    if (pool.isEmpty) return null;
    final chosen = pool[_rng.nextInt(pool.length)];

    // Add to inventory
    await _db.addGu(chosen.id);
    return chosen;
  }

  /// Chance-based attempt (e.g. after task)
  Future<GuWormTemplate?> rollForGu(double chance, {int? maxRank}) async {
    if (_rng.nextDouble() > chance) return null;
    return tryDropGu(maxRank: maxRank);
  }

  bool isObtained(int guId) {
    return _db.getOwnedGuById(guId) != null;
  }

  int quantityOf(int guId) {
    return _db.getOwnedGuById(guId)?.quantity ?? 0;
  }

  List<OwnedGu> getCollection() => _db.getOwnedGu();

  int totalObtainedCount() => _db.getOwnedGu().fold(0, (s, g) => s + 1);

  int totalUniqueTemplates() => _db.guTemplates.length;

  Map<int, int> collectedByRank() {
    final map = <int, int>{};
    for (final owned in _db.getOwnedGu()) {
      final t = _db.getGuTemplate(owned.guId);
      if (t != null) {
        map[t.rank] = (map[t.rank] ?? 0) + 1;
      }
    }
    return map;
  }

  Map<int, int> totalByRank() {
    final map = <int, int>{};
    for (final t in _db.guTemplates) {
      map[t.rank] = (map[t.rank] ?? 0) + 1;
    }
    return map;
  }
}
