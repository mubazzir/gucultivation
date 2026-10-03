import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers.dart';
import '../../config/cultivation_config.dart';
import '../../models/gu_worm.dart';
import '../../models/material_item.dart';

class RefinementScreen extends ConsumerStatefulWidget {
  const RefinementScreen({super.key});

  @override
  ConsumerState<RefinementScreen> createState() => _RefinementScreenState();
}

class _RefinementScreenState extends ConsumerState<RefinementScreen> {
  GuWormTemplate? _selected;
  bool _refining = false;

  int _requiredCount(int guRank) =>
      CultivationConfig.materialsRequiredPerGuRank;

  List<OwnedMaterial> _eligibleMaterials(int guRank) {
    final db = ref.read(persistenceProvider);
    final owned = ref.read(materialCollectionProvider);
    final eligible = <OwnedMaterial>[];
    for (final o in owned) {
      if (o.quantity <= 0) continue;
      final t = db.getMaterialTemplate(o.materialId);
      if (t != null && t.typicalRank >= guRank) {
        eligible.add(o);
      }
    }
    return eligible;
  }

  int _availableEligibleQty(int guRank) {
    return _eligibleMaterials(guRank).fold(0, (s, o) => s + o.quantity);
  }

  bool _canRefine(GuWormTemplate gu) {
    final ownedGu = ref.read(guCollectionProvider);
    final hasGu = ownedGu.any((g) => g.guId == gu.id);
    if (!hasGu) return false;
    return _availableEligibleQty(gu.rank) >= _requiredCount(gu.rank);
  }

  Future<void> _refine() async {
    if (_selected == null) return;
    final gu = _selected!;
    if (!_canRefine(gu)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Insufficient materials. Need materials of rank ≥ this Gu.',
          ),
          backgroundColor: AppTheme.primary,
        ),
      );
      return;
    }

    setState(() => _refining = true);
    final db = ref.read(persistenceProvider);
    final need = _requiredCount(gu.rank);
    var remaining = need;

    final eligible = _eligibleMaterials(gu.rank);
    eligible.sort((a, b) {
      final ta = db.getMaterialTemplate(a.materialId)?.typicalRank ?? 0;
      final tb = db.getMaterialTemplate(b.materialId)?.typicalRank ?? 0;
      return tb.compareTo(ta);
    });

    for (final o in eligible) {
      if (remaining <= 0) break;
      final take = remaining < o.quantity ? remaining : o.quantity;
      final ok = await db.consumeMaterial(o.materialId, take);
      if (ok) remaining -= take;
    }

    if (remaining > 0) {
      setState(() => _refining = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Refinement aborted: materials short.'),
          backgroundColor: AppTheme.primary,
        ),
      );
      return;
    }

    await Future.delayed(const Duration(milliseconds: 900));

    final owned = db.getOwnedGuById(gu.id);
    if (owned != null) {
      owned.isRefined = true;
      owned.masteryLevel += 1;
      await owned.save();
    }

    final stats = db.getStats();
    stats.guRefined += 1;
    await db.saveStats(stats);

    ref.read(guCollectionProvider.notifier).refresh();
    ref.read(materialCollectionProvider.notifier).refresh();

    setState(() => _refining = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Refinement successful: ${gu.name}'),
        backgroundColor: AppTheme.surfaceElevated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(persistenceProvider);
    final ownedList = ref.watch(guCollectionProvider);
    final ownedIds = ownedList.map((g) => g.guId).toSet();

    final candidates =
    db.guTemplates.where((t) => ownedIds.contains(t.id)).toList();

    final can = _selected != null && _canRefine(_selected!);

    return Scaffold(
      appBar: AppBar(title: const Text('REFINEMENT')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select an owned Gu to refine',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Requires ${CultivationConfig.materialsRequiredPerGuRank} materials of rank ≥ Gu rank.',
              style: const TextStyle(color: AppTheme.inkDim, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: candidates.isEmpty
                  ? const Center(
                child: Text(
                  'No owned Gu yet.\nObtain Gu from the spin wheel after study.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.inkDim),
                ),
              )
                  : ListView.builder(
                itemCount: candidates.length,
                itemBuilder: (context, i) {
                  final t = candidates[i];
                  final selected = _selected?.id == t.id;
                  final enough = _canRefine(t);
                  return GestureDetector(
                    onTap: () => setState(() => _selected = t),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.surfaceElevated
                            : AppTheme.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: selected
                              ? AppTheme.accent
                              : AppTheme.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Rank ${t.rank} · ${t.daoPath}',
                                  style: const TextStyle(
                                    color: AppTheme.inkDim,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            enough ? 'Ready' : 'Need mats',
                            style: TextStyle(
                              color: enough
                                  ? AppTheme.jade
                                  : AppTheme.primaryLight,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_selected != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Need ${_requiredCount(_selected!.rank)}× material rank ≥ ${_selected!.rank}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    Text(
                      'You have ${_availableEligibleQty(_selected!.rank)} eligible',
                      style: TextStyle(
                        fontSize: 12,
                        color: can ? AppTheme.jade : AppTheme.primaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: (_refining || !can) ? null : _refine,
                child: _refining
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Text(can ? 'REFINE' : 'INSUFFICIENT MATERIALS'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}