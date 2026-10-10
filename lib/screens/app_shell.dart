import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'task_list_screen.dart';
import 'team_screen.dart';

/// Bottom-navigation host. Tabs are rebuilt when selected, so each one
/// reloads fresh data from SQLite in its initState().
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _tabs = <Widget>[DashboardScreen(), TaskListScreen(), TeamScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          setState(() => _index = 0);
        }
      },
      child: Scaffold(
        body: SafeArea(child: _tabs[_index]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: 'Tasks'),
            NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Team'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
