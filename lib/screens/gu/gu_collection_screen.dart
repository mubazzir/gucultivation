import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers.dart';
import '../../models/gu_worm.dart';

class GuCollectionScreen extends ConsumerWidget {
  const GuCollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(persistenceProvider);
    final ownedList = ref.watch(guCollectionProvider);
    final templates = db.guTemplates;
    final owned = {for (var g in ownedList) g.guId: g};

    final byRank = <int, List<GuWormTemplate>>{};
    for (final t in templates) {
      byRank.putIfAbsent(t.rank, () => []).add(t);
    }
    final ranks = byRank.keys.toList()..sort();

    final totalOwned = ownedList.length;
    final totalAll = templates.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GU COLLECTION'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '$totalOwned / $totalAll',
                style: const TextStyle(color: AppTheme.accent),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: ranks.length,
        itemBuilder: (context, index) {
          final rank = ranks[index];
          final list = byRank[rank]!;
          final ownedInRank =
              list.where((t) => owned.containsKey(t.id)).length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                child: Row(
                  children: [
                    Text(
                      'RANK $rank',
                      style: const TextStyle(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$ownedInRank / ${list.length}',
                      style: const TextStyle(
                          color: AppTheme.inkDim, fontSize: 12),
                    ),
                  ],
                ),
              ),
              ...list.map((t) {
                final isOwned = owned.containsKey(t.id);
                final qty = owned[t.id]?.quantity ?? 0;
                return _GuTile(
                  template: t,
                  isOwned: isOwned,
                  quantity: qty,
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

class _GuTile extends StatelessWidget {
  final GuWormTemplate template;
  final bool isOwned;
  final int quantity;

  const _GuTile({
    required this.template,
    required this.isOwned,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOwned ? AppTheme.surfaceElevated : AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isOwned ? AppTheme.border : AppTheme.locked,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isOwned
                  ? AppTheme.primary.withOpacity(0.3)
                  : AppTheme.locked,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              isOwned ? Icons.bug_report : Icons.lock_outline,
              color: isOwned ? AppTheme.accent : AppTheme.inkDim,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOwned ? template.name : '???',
                  style: TextStyle(
                    color: isOwned ? AppTheme.ink : AppTheme.inkDim,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isOwned)
                  Text(
                    '${template.daoPath} · ${template.rarity}',
                    style: const TextStyle(
                        color: AppTheme.inkDim, fontSize: 12),
                  )
                else
                  const Text(
                    'Unknown Gu  ·  LOCKED',
                    style:
                    TextStyle(color: AppTheme.inkDim, fontSize: 12),
                  ),
              ],
            ),
          ),
          if (isOwned && quantity > 1)
            Text(
              '×$quantity',
              style: const TextStyle(color: AppTheme.jade),
            ),
        ],
      ),
    );
  }
}