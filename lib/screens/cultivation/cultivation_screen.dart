import 'dart:async';
import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers.dart';
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
  ConsumerState<CultivationScreen> createState() => _CultivationScreenState();
}

class _CultivationScreenState extends ConsumerState<CultivationScreen> {
  Timer? _ticker;
  int _displaySeconds = 0;

  @override
  void initState() {
    super.initState();
    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final session = ref.read(sessionProvider);
      if (session.isActive && !session.isPaused) {
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
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _pickPath() async {
    final paths = ref.read(pathsProvider);
    if (paths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a path first on the Paths tab.'),
          backgroundColor: AppTheme.surfaceElevated,
        ),
      );
      return;
    }
    final profile = ref.read(profileProvider);
    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.surfaceElevated,
      builder: (ctx) => SafeArea(
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
                subtitle: Text(p.attainmentLabel),
                trailing: profile?.selectedPathId == p.id
                    ? const Icon(Icons.check, color: AppTheme.accent)
                    : null,
                onTap: () => Navigator.pop(ctx, p.id),
              ),
            ),
          ],
        ),
      ),
    );
    if (chosen != null && profile != null) {
      profile.selectedPathId = chosen;
      await ref.read(profileProvider.notifier).save(profile);
    }
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

  Future<void> _pause() async {
    final svc = ref.read(cultivationServiceProvider);
    await svc.pauseCultivation();
    ref.read(sessionProvider.notifier).refresh();
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
    } else if (elapsed > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Study at least 25 minutes in one session for a Basic Spin.',
          ),
          backgroundColor: AppTheme.surfaceElevated,
        ),
      );
    }
  }

  Future<void> _accelerate() async {
    final svc = ref.read(cultivationServiceProvider);
    final ok = await svc.spendStoneToAccelerate(stones: 1);
    ref.read(profileProvider.notifier).refresh();
    ref.read(pathsProvider.notifier).refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Accelerated cultivation (+10 min essence).'
              : 'Not enough Primal Stones.',
        ),
        backgroundColor: AppTheme.surfaceElevated,
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final session = ref.watch(sessionProvider);
    final paths = ref.watch(pathsProvider);
    final svc = ref.read(cultivationServiceProvider);

    if (profile == null) {
      return const Scaffold(body: Center(child: Text('No profile')));
    }

    final progress = svc.progressInCurrentStage(profile);
    final selectedPath =
        paths.where((p) => p.id == profile.selectedPathId).firstOrNull;
    final isRunning = session.isActive && !session.isPaused;
    final isPaused = session.isActive && session.isPaused;

    if (isRunning) {
      _displaySeconds = session.getElapsedSeconds();
    } else if (isPaused) {
      _displaySeconds = session.accumulatedSeconds;
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
                    'Today: ${_formatDuration(profile.todayStudySeconds)}  ·  Streak: ${profile.currentStreak}d',
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

            // Path selector — XP goes to this path while timer runs
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
                            '${selectedPath.attainmentLabel} · tap to change',
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

            const SizedBox(height: 24),
            Center(
              child: Text(
                _formatDuration(_displaySeconds),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w200,
                  color: isRunning
                      ? AppTheme.accent
                      : isPaused
                      ? AppTheme.inkDim
                      : AppTheme.ink,
                  letterSpacing: 4,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                isRunning
                    ? 'CULTIVATING...'
                    : isPaused
                    ? 'PAUSED'
                    : 'READY',
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
            Row(
              children: [
                if (!session.isActive) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _start,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('START'),
                    ),
                  ),
                ] else if (isPaused) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _start,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('RESUME'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _stop,
                      icon: const Icon(Icons.stop),
                      label: const Text('STOP'),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pause,
                      icon: const Icon(Icons.pause),
                      label: const Text('PAUSE'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _stop,
                      icon: const Icon(Icons.stop),
                      label: const Text('STOP'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryLight,
                      ),
                    ),
                  ),
                ],
              ],
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PathsScreen()),
                    ).then((_) {
                      ref.read(pathsProvider.notifier).refresh();
                      ref.read(profileProvider.notifier).refresh();
                    });
                  },
                ),
                _ActionChip(
                  label: 'Inventory',
                  icon: Icons.inventory_2_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const InventoryScreen()),
                  ),
                ),
                _ActionChip(
                  label: 'Refine',
                  icon: Icons.science_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RefinementScreen()),
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