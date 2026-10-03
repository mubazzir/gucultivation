import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../services/persistence_service.dart';
import '../home/home_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _pageController = PageController();
  String? _selectedAptitude;
  bool _revealing = false;
  late AnimationController _revealController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _fadeAnim = CurvedAnimation(parent: _revealController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pageController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  void _beginCultivation() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A Gu Master must have a name.')),
      );
      return;
    }
    // Random aptitude
    final aptitudes = AppConstants.aptitudes;
    _selectedAptitude = aptitudes[Random().nextInt(aptitudes.length)];
    setState(() => _revealing = true);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    _revealController.forward();
  }

  Future<void> _confirmAndEnter() async {
    final name = _nameController.text.trim();
    final aptitude = _selectedAptitude!;
    final db = PersistenceService();
    await db.createProfile(name, aptitude);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D0D0D), Color(0xFF1A0A0A), Color(0xFF0D0D0D)],
          ),
        ),
        child: SafeArea(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildNamePage(),
              _buildAptitudePage(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNamePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.spa, size: 64, color: AppTheme.accent),
          const SizedBox(height: 24),
          Text(
            'GU CULTIVATION',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.accent,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w300,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'The path of the Gu Master begins with a single step.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.inkDim,
                  fontStyle: FontStyle.italic,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Text(
            'What is your name, Gu Master?',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.ink, fontSize: 18),
            decoration: const InputDecoration(
              hintText: 'Enter your name',
              hintStyle: TextStyle(color: AppTheme.inkDim),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _beginCultivation(),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _beginCultivation,
              child: const Text('BEGIN CULTIVATION'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAptitudePage() {
    final desc = AppConstants.aptitudeDescriptions[_selectedAptitude] ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Your Primeval Essence Aptitude is...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.inkDim,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                Text(
                  _selectedAptitude ?? '?',
                  style: const TextStyle(
                    fontSize: 96,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accent,
                    letterSpacing: 8,
                  ),
                ),
                Text(
                  'GRADE',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.accentDark,
                        letterSpacing: 6,
                      ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    desc,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _confirmAndEnter,
              child: const Text('ENTER THE WORLD OF GU'),
            ),
          ),
        ],
      ),
    );
  }
}
