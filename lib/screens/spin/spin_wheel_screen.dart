import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers.dart';
import '../../services/spin_service.dart';

class SpinWheelScreen extends ConsumerStatefulWidget {
  final SpinTier tier;

  const SpinWheelScreen({super.key, required this.tier});

  @override
  ConsumerState<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends ConsumerState<SpinWheelScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;
  bool _spinning = false;
  bool _done = false;
  SpinReward? _reward;
  final _spinService = SpinService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _rotation = Tween<double>(begin: 0, end: 0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startSpin() async {
    if (_spinning || _done) return;
    setState(() {
      _spinning = true;
      _reward = null;
    });

    final turns = 4 + Random().nextDouble() * 3;
    _rotation = Tween<double>(begin: 0, end: turns * 2 * pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.reset();
    await _controller.forward();

    final reward = await _spinService.spin(widget.tier);
    ref.read(guCollectionProvider.notifier).refresh();
    ref.read(materialCollectionProvider.notifier).refresh();
    ref.read(profileProvider.notifier).refresh();

    setState(() {
      _reward = reward;
      _spinning = false;
      _done = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final label = _spinService.tierLabel(widget.tier);
    final color = widget.tier == SpinTier.ultra
        ? AppTheme.accent
        : widget.tier == SpinTier.great
        ? AppTheme.jade
        : AppTheme.primaryLight;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(label.toUpperCase()),
        automaticallyImplyLeading: _done,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                widget.tier == SpinTier.ultra
                    ? 'Fate itself turns the wheel...'
                    : widget.tier == SpinTier.great
                    ? 'A rare opportunity presents itself.'
                    : 'Heaven grants a minor fortune.',
                style: const TextStyle(color: AppTheme.inkDim, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotation.value,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            color.withOpacity(0.9),
                            AppTheme.surfaceElevated,
                            color.withOpacity(0.5),
                            AppTheme.surface,
                            color.withOpacity(0.9),
                          ],
                        ),
                        border: Border.all(color: color, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.35),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.spa, size: 56, color: AppTheme.ink),
                      ),
                    ),
                  ),
                ),
              ),
              if (_reward != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _reward!.isGu ? 'GU OBTAINED' : 'MATERIAL OBTAINED',
                        style: TextStyle(
                          color: color,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _reward!.displayName,
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_reward!.isGu && _reward!.gu != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Rank ${_reward!.gu!.rank} · ${_reward!.gu!.daoPath}',
                          style: const TextStyle(color: AppTheme.inkDim),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _reward),
                    child: const Text('CLAIM'),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _spinning ? null : _startSpin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      _spinning ? 'SPINNING...' : 'SPIN THE WHEEL',
                      style: const TextStyle(
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}