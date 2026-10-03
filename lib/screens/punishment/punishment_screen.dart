import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../services/persistence_service.dart';
import '../onboarding/onboarding_screen.dart';

class PunishmentScreen extends ConsumerStatefulWidget {
  const PunishmentScreen({super.key});

  @override
  ConsumerState<PunishmentScreen> createState() => _PunishmentScreenState();
}

class _PunishmentScreenState extends ConsumerState<PunishmentScreen> {
  bool _confirming = false;
  bool _executing = false;

  Future<void> _executePunishment() async {
    setState(() => _executing = true);
    await Future.delayed(const Duration(milliseconds: 800));
    final db = PersistenceService();
    await db.wipeAllData();
    if (!mounted) return;
    // Show death screen then restart
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _DeathDialog(),
    );
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PUNISHMENT'),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A0000), Color(0xFF0D0D0D)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 72,
                color: AppTheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'HEAVEN\'S WILL',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.primaryLight,
                      letterSpacing: 4,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'The path of a Gu Master is paved with death.\n'
                'One button. Complete erasure.\n'
                'Your cultivation, your Gu, your paths —\n'
                'all return to nothingness.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.inkDim,
                      height: 1.6,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              if (!_confirming && !_executing)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => setState(() => _confirming = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: const Text(
                      'PUNISHMENT',
                      style: TextStyle(
                        fontSize: 18,
                        letterSpacing: 3,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              if (_confirming && !_executing) ...[
                Text(
                  'This will permanently erase all progress.\nThere is no recovery.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryLight,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _confirming = false),
                        child: const Text('CANCEL'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _executePunishment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                        ),
                        child: const Text('ERASE EVERYTHING'),
                      ),
                    ),
                  ],
                ),
              ],
              if (_executing)
                const Column(
                  children: [
                    CircularProgressIndicator(color: AppTheme.primary),
                    SizedBox(height: 16),
                    Text(
                      'Severing fate threads...',
                      style: TextStyle(color: AppTheme.inkDim),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeathDialog extends StatelessWidget {
  const _DeathDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0A0000),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'DEATH',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your aperture has collapsed.\nAll Gu worms have perished.\nThe river of time forgets your name.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.inkDim,
                    height: 1.6,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                ),
                child: const Text('REINCARNATE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
