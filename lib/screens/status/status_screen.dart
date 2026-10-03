import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers.dart';
import '../../widgets/progress_bar.dart';
import '../../services/cultivation_service.dart';
import '../../config/cultivation_config.dart';

class StatusScreen extends ConsumerWidget {
  const StatusScreen({super.key});

  String _fmt(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final paths = ref.watch(pathsProvider);
    final stats = ref.watch(statsProvider);
    final guService = ref.watch(guServiceProvider);
    final svc = ref.read(cultivationServiceProvider);

    if (profile == null) {
      return const Scaffold(body: Center(child: Text('No profile')));
    }

    final progress = svc.progressInCurrentStage(profile);

    return Scaffold(
      appBar: AppBar(title: const Text('STATUS')),
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
                    profile.name.toUpperCase(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          letterSpacing: 2,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Aptitude: ${profile.aptitude} Grade',
                    style: const TextStyle(color: AppTheme.accent),
                  ),
                  const Divider(height: 32),
                  _row('Cultivation', profile.fullCultivationLabel),
                  const SizedBox(height: 8),
                  CultivationProgressBar(progress: progress),
                  const SizedBox(height: 4),
                  Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(color: AppTheme.inkDim, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  _row('Total Cultivation', _fmt(profile.totalStudySeconds)),
                  _row('Today', _fmt(profile.todayStudySeconds)),
                  _row('Current Streak', '${profile.currentStreak} days'),
                  _row('Longest Streak', '${profile.longestStreak} days'),
                  _row('Gu Worms', '${guService.totalObtainedCount()} / ${guService.totalUniqueTemplates()}'),
                  _row('Tasks Completed', '${stats.tasksCompleted}'),
                  _row('Breakthroughs', '${stats.breakthroughs}'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'PATHS',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.inkDim,
                    letterSpacing: 2,
                  ),
            ),
            const SizedBox(height: 12),
            ...paths.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(p.attainmentLabel,
                                  style: const TextStyle(color: AppTheme.inkDim, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text(
                          '${(p.progressPercent * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(color: AppTheme.jade),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.inkDim)),
          Text(value, style: const TextStyle(color: AppTheme.ink, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
