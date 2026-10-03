import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers.dart';
import '../../services/spin_service.dart';
import '../spin/spin_wheel_screen.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  Future<void> _addTask() async {
    final titleCtrl = TextEditingController();
    String difficulty = 'Normal';
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('New Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(hintText: 'Task name'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: difficulty,
                items: ['Easy', 'Normal', 'Hard', 'Extreme']
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setS(() => difficulty = v ?? 'Normal'),
                decoration: const InputDecoration(labelText: 'Difficulty'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('CANCEL')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, {
                'title': titleCtrl.text.trim(),
                'difficulty': difficulty,
              }),
              child: const Text('CREATE'),
            ),
          ],
        ),
      ),
    );
    if (result != null && result['title']!.isNotEmpty) {
      final db = ref.read(persistenceProvider);
      await db.addTask(
        title: result['title']!,
        difficulty: result['difficulty']!,
        pathId: ref.read(profileProvider)?.selectedPathId,
      );
      setState(() {});
    }
  }

  Future<void> _complete(String id) async {
    final db = ref.read(persistenceProvider);
    final tasks = db.getTasks();
    final task = tasks.where((t) => t.id == id).firstOrNull;
    if (task == null) return;
    await db.completeTask(task);

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SpinWheelScreen(tier: SpinTier.basic),
      ),
    );

    ref.read(guCollectionProvider.notifier).refresh();
    ref.read(materialCollectionProvider.notifier).refresh();
    ref.read(profileProvider.notifier).refresh();

    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(persistenceProvider);
    final active = db.getTasks(completed: false);
    final done = db.getTasks(completed: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TASKS'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addTask),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (active.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No active tasks.\nComplete a task for a Basic Spin reward.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.inkDim),
                ),
              ),
            ),
          ...active.map((t) => Container(
            margin: const EdgeInsets.only(bottom: 8),
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
                      Text(t.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      Text(t.difficulty,
                          style: const TextStyle(
                              color: AppTheme.inkDim, fontSize: 12)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _complete(t.id),
                  child: const Text('COMPLETE'),
                ),
              ],
            ),
          )),
          if (done.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('COMPLETED',
                style:
                TextStyle(color: AppTheme.inkDim, letterSpacing: 2)),
            const SizedBox(height: 8),
            ...done.take(10).map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '✓ ${t.title}',
                style: const TextStyle(
                    color: AppTheme.inkDim, fontSize: 13),
              ),
            )),
          ],
        ],
      ),
    );
  }
}