import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers.dart';
import '../../widgets/progress_bar.dart';

class PathsScreen extends ConsumerStatefulWidget {
  const PathsScreen({super.key});

  @override
  ConsumerState<PathsScreen> createState() => _PathsScreenState();
}

class _PathsScreenState extends ConsumerState<PathsScreen> {
  Future<void> _deletePath(String id, String name) async {
    final profile = ref.read(profileProvider);

    final path = ref.read(pathsProvider).where((p) => p.id == id).firstOrNull;
    if (path != null && path.isHeavenPath) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Path'),
        content: Text(
          'Delete "$name"?\nAll progress on this path will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final db = ref.read(persistenceProvider);
    await db.deletePath(id);

    if (profile != null && profile.selectedPathId == id) {
      final remaining =
      ref.read(pathsProvider).where((p) => p.id != id).toList();
      profile.selectedPathId =
      remaining.isNotEmpty ? remaining.first.id : null;
      await ref.read(profileProvider.notifier).save(profile);
      ref.read(profileProvider.notifier).refresh();
    }

    ref.read(pathsProvider.notifier).refresh();
  }

  Future<void> _addPath() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Path'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Flutter Path, Calculus, Physics',
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => Navigator.pop(ctx, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('ADD'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (name == null || name.isEmpty) return;

    await ref.read(pathsProvider.notifier).add(name);

    final profile = ref.read(profileProvider);
    if (profile != null &&
        (profile.selectedPathId == null || profile.selectedPathId!.isEmpty)) {
      final paths = ref.read(pathsProvider);
      if (paths.isNotEmpty) {
        profile.selectedPathId = paths.last.id;
        await ref.read(profileProvider.notifier).save(profile);
        ref.read(profileProvider.notifier).refresh();
      }
    }
  }

  Future<void> _selectPath(String id) async {
    final profile = ref.read(profileProvider);
    if (profile == null) return;
    profile.selectedPathId = id;
    await ref.read(profileProvider.notifier).save(profile);
  }

  String _formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final paths = ref.watch(pathsProvider);
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PATH ATTAINMENT'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add path',
            onPressed: _addPath,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPath,
        icon: const Icon(Icons.add),
        label: const Text('ADD PATH'),
        backgroundColor: AppTheme.primary,
      ),
      body: paths.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'No paths yet.\nAdd a path, then select it before cultivating.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.inkDim),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _addPath,
                icon: const Icon(Icons.add),
                label: const Text('ADD FIRST PATH'),
              ),
            ],
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        itemCount: paths.length,
        itemBuilder: (context, index) {
          final p = paths[index];
          final selected = profile?.selectedPathId == p.id;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _selectPath(p.id),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.surfaceElevated
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected ? AppTheme.accent : AppTheme.border,
                  width: selected ? 1.5 : 0.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (selected)
                        const Icon(
                          Icons.check_circle,
                          color: AppTheme.accent,
                          size: 18,
                        ),
                      if (!p.isHeavenPath)
                        IconButton(
                          icon:
                          const Icon(Icons.delete_outline, size: 20),
                          color: AppTheme.inkDim,
                          tooltip: 'Delete path',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          onPressed: () => _deletePath(p.id, p.name),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${p.attainmentLabel}  ·  ${p.daoMarkLabel}: ${p.daoMarks}',
                    style: const TextStyle(
                      color: AppTheme.jade,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  CultivationProgressBar(
                    progress: p.progressPercent,
                    height: 6,
                    color: AppTheme.jade,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${(p.progressPercent * 100).toStringAsFixed(1)}% to next',
                        style: const TextStyle(
                          color: AppTheme.inkDim,
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Studied ${_formatDuration(p.totalStudySeconds)}',
                        style: const TextStyle(
                          color: AppTheme.inkDim,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}