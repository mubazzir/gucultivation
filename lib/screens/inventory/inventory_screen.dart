import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(persistenceProvider);
    final owned = ref.watch(materialCollectionProvider);
    final byRank = <int, List<MapEntry<dynamic, int>>>{};

    for (final o in owned) {
      final t = db.getMaterialTemplate(o.materialId);
      if (t == null) continue;
      byRank.putIfAbsent(t.typicalRank, () => []).add(MapEntry(t, o.quantity));
    }
    final ranks = byRank.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: const Text('INVENTORY')),
      body: ranks.isEmpty
          ? const Center(
        child: Text(
          'No materials yet.\nStudy 25+ minutes or complete tasks to spin.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.inkDim),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ranks.length,
        itemBuilder: (context, i) {
          final rank = ranks[i];
          final items = byRank[rank]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'RANK $rank MATERIALS',
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              ...items.map((e) {
                final t = e.key;
                final qty = e.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text('${t.category} · ${t.daoPath}',
                                style: const TextStyle(
                                    color: AppTheme.inkDim,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                      Text('×$qty',
                          style:
                          const TextStyle(color: AppTheme.jade)),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }
}