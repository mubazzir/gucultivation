import 'dart:async';
import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers.dart';
import '../../core/constants/app_constants.dart';
import '../../services/cultivation_service.dart';
import '../../services/spin_service.dart';
import '../../config/cultivation_config.dart';
import '../../widgets/progress_bar.dart';
import '../tasks/tasks_screen.dart';
import '../inventory/inventory_screen.dart';
import '../refinement/refinement_screen.dart';
import '../spin/spin_wheel_screen.dart';
import '../paths/paths_screen.dart';

class CultivationScreen extends ConsumerStatefulWidget {
  const CultivationScreen({super.key});

  @override
  ConsumerState<CultivationScreen> createState() =>
      _CultivationScreenState();
}

class _CultivationScreenState extends ConsumerState<CultivationScreen> {
  Timer? _ticker;
  int _displaySeconds = 0;

  @override
  void initState() {
    super.initState();
    _startTicker();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final db = ref.read(persistenceProvider);
      await db.ensureHeavenPath();
      await db.ensureHeavenDayRollover();
      ref.read(pathsProvider.notifier).refresh();
      if (mounted) setState(() {});
    });
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final session = ref.read(sessionProvider);
      if (session.isActive) {
        setState(() {
          _displaySeconds = session.getElapsedSeconds();
        });
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  Future<void> _pickPath() async {
    final paths = ref.read(pathsProvider);
    if (paths.isEmpty) return;

    final profile = ref.read(profileProvider);
    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.surfaceElevated,
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'SELECT PATH TO CULTIVATE',
                  style: TextStyle(
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...paths.map(
                    (p) => ListTile(
                  title: Text(p.name),
                  subtitle: Text(
                    '${p.attainmentLabel} · ${p.daoMarkLabel}: ${p.daoMarks}',
                  ),
                  trailing: profile?.selectedPathId == p.id
                      ? const Icon(Icons.check, color: AppTheme.accent)
                      : null,
                  onTap: () => Navigator.pop(ctx, p.id),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (chosen == null || profile == null) return;
    profile.selectedPathId = chosen;
    await ref.read(profileProvider.notifier).save(profile);
    ref.read(profileProvider.notifier).refresh();
    ref.read(pathsProvider.notifier).refresh();
  }

  Future<void> _start() async {
    final svc = ref.read(cultivationServiceProvider);
    final profile = ref.read(profileProvider);
    await svc.startCultivation(pathId: profile?.selectedPathId);
    ref.read(sessionProvider.notifier).refresh();
    setState(() {
      _displaySeconds = ref.read(sessionProvider).getElapsedSeconds();
    });
  }

  Future<void> _stop() async {
    final svc = ref.read(cultivationServiceProvider);
    final elapsed = await svc.stopCultivation();

    ref.read(sessionProvider.notifier).refresh();
    ref.read(profileProvider.notifier).refresh();
    ref.read(pathsProvider.notifier).refresh();
    setState(() => _displaySeconds = 0);

    final tier = SpinService().tierForSeconds(elapsed);
    if (tier != null && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SpinWheelScreen(tier: tier)),
      );
      ref.read(guCollectionProvider.notifier).refresh();
      ref.read(materialCollectionProvider.notifier).refresh();
      ref.read(profileProvider.notifier).refresh();
      ref.read(pathsProvider.notifier).refresh();
    }
  }

  Future<void> _accelerate() async {
    final svc = ref.read(cultivationServiceProvider);
    await svc.spendStoneToAccelerate(stones: 1);
    ref.read(profileProvider.notifier).refresh();
    ref.read(pathsProvider.notifier).refresh();
  }

  Future<void> _breakthrough() async {
    final svc = ref.read(cultivationServiceProvider);
    final result = await svc.attemptBreakthrough();
    ref.read(profileProvider.notifier).refresh();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(result.success ? 'BREAKTHROUGH' : 'FAILURE'),
        content: Text(result.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ACKNOWLEDGE'),
          ),
        ],
      ),
    );
  }

  Widget _heavenTasksCard() {
    final db = ref.read(persistenceProvider);
    final status = db.getHeavenTaskStatus();
    final heaven = db.getHeavenPath();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'HEAVEN PATH',
                style: TextStyle(
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accent,
                ),
              ),
              const Spacer(),
              Text(
                'Dao Marks: ${heaven?.daoMarks ?? 0}',
                style: const TextStyle(color: AppTheme.jade, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '+1 when done · −1 each missed at day end',
            style: TextStyle(color: AppTheme.inkDim, fontSize: 11),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.heavenDailyTasks.map((id) {
              final done = status[id] == true;
              final label = AppConstants.heavenTaskLabels[id] ?? id;
              return FilterChip(
                label: Text(label),
                selected: done,
                onSelected: done
                    ? null
                    : (_) async {
                  await db.completeHeavenTask(id);
                  ref.read(pathsProvider.notifier).refresh();
                  setState(() {});
                },
                selectedColor: AppTheme.jade.withOpacity(0.3),
                checkmarkColor: AppTheme.jade,
                labelStyle: TextStyle(
                  color: done ? AppTheme.jade : AppTheme.ink,
                  fontSize: 12,
                ),
                side: BorderSide(
                  color: done ? AppTheme.jade : AppTheme.border,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final session = ref.watch(sessionProvider);
    final paths = ref.watch(pathsProvider);
    final svc = ref.read(cultivationServiceProvider);

    if (profile == null) {
      return const Scaffold(
        body: Center(child: Text('No profile')),
      );
    }

    final progress = svc.progressInCurrentStage(profile);
    final selectedPath =
        paths.where((p) => p.id == profile.selectedPathId).firstOrNull;
    final isRunning = session.isActive;

    if (isRunning) {
      _displaySeconds = session.getElapsedSeconds();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(profile.name.toUpperCase()),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${profile.aptitude} Grade',
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  Text(
                    profile.fullCultivationLabel,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.accent,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CultivationProgressBar(progress: progress),
                  const SizedBox(height: 8),
                  Text(
                    '${(progress * 100).toStringAsFixed(1)}%  ·  '
                        '${profile.currentEssenceInStage.toStringAsFixed(1)} / '
                        '${CultivationConfig.essenceForStage(profile.cultivationRank, profile.realmStage).toStringAsFixed(0)} PE',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Lifetime: ${_formatDuration(profile.totalStudySeconds)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Today: ${_formatDuration(profile.todayStudySeconds)}'
                        '  ·  Streak: ${profile.currentStreak}d',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Primal Stones: ${profile.primalStones}',
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Path selector
            GestureDetector(
              onTap: session.isActive ? null : _pickPath,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.alt_route, color: AppTheme.jade, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: selectedPath != null
                          ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedPath.name,
                            style: const TextStyle(
                              color: AppTheme.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            session.isActive
                                ? '${selectedPath.attainmentLabel} · ${selectedPath.daoMarkLabel}: ${selectedPath.daoMarks}'
                                : '${selectedPath.attainmentLabel} · tap to change',
                            style: const TextStyle(
                              color: AppTheme.inkDim,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
                          : const Text(
                        'No path selected — tap to choose',
                        style: TextStyle(color: AppTheme.inkDim),
                      ),
                    ),
                    if (selectedPath != null)
                      Text(
                        '${(selectedPath.progressPercent * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(color: AppTheme.jade),
                      ),
                  ],
                ),
              ),
            ),

            // Heaven Path daily tasks
            _heavenTasksCard(),

            const SizedBox(height: 24),
            Center(
              child: Text(
                _formatDuration(_displaySeconds),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w200,
                  color: isRunning ? AppTheme.accent : AppTheme.ink,
                  letterSpacing: 4,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                isRunning ? 'CULTIVATING...' : 'READY',
                style: TextStyle(
                  color: isRunning ? AppTheme.jade : AppTheme.inkDim,
                  letterSpacing: 3,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                '25m → Basic · 1h → Great · 5h → Ultra Spin',
                style: TextStyle(color: AppTheme.inkDim, fontSize: 11),
              ),
            ),
            const SizedBox(height: 24),

            if (!session.isActive)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _start,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('START'),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _stop,
                  icon: const Icon(Icons.stop),
                  label: const Text('STOP'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryLight,
                  ),
                ),
              ),

            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: profile.primalStones > 0 ? _accelerate : null,
              icon: const Icon(Icons.bolt),
              label: Text(
                'ACCELERATE (1 Stone → 10m)  ·  Own ${profile.primalStones}',
              ),
            ),

            if (profile.realmStage >= 3) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _breakthrough,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.accent),
                ),
                child: const Text('ATTEMPT BREAKTHROUGH'),
              ),
            ],

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'QUICK ACTIONS',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppTheme.inkDim,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ActionChip(
                  label: 'Tasks',
                  icon: Icons.checklist,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TasksScreen()),
                  ),
                ),
                _ActionChip(
                  label: 'Paths',
                  icon: Icons.alt_route,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PathsScreen()),
                    );
                    ref.read(pathsProvider.notifier).refresh();
                    ref.read(profileProvider.notifier).refresh();
                  },
                ),
                _ActionChip(
                  label: 'Inventory',
                  icon: Icons.inventory_2_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InventoryScreen()),
                  ),
                ),
                _ActionChip(
                  label: 'Refine',
                  icon: Icons.science_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RefinementScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: AppTheme.accent),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppTheme.surfaceElevated,
      side: const BorderSide(color: AppTheme.border),
      labelStyle: const TextStyle(color: AppTheme.ink),
    );
  }
}