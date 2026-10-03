import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../cultivation/cultivation_screen.dart';
import '../status/status_screen.dart';
import '../gu/gu_collection_screen.dart';
import '../paths/paths_screen.dart';
import '../punishment/punishment_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final _pages = const [
    CultivationScreen(),
    StatusScreen(),
    GuCollectionScreen(),
    PathsScreen(),
    PunishmentScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.self_improvement),
              label: 'Cultivation',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Status',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bug_report_outlined),
              label: 'Gu',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.alt_route),
              label: 'Paths',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dangerous_outlined),
              label: 'Punishment',
            ),
          ],
        ),
      ),
    );
  }
}
