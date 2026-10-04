import 'package:flutter/material.dart';
import 'screens/app_shell.dart';
import 'screens/sign_in_screen.dart';
import 'services/database_service.dart';
import 'services/prefs_service.dart';
import 'utils/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PrefsService.init(); // SharedPreferences: session + SLA thresholds
  await DatabaseService.instance.init(); // SQLite: tasks, members, activity
  runApp(const BeaconApp());
}

class BeaconApp extends StatelessWidget {
  const BeaconApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beacon',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Already signed in? Skip straight to the app.
      home: PrefsService.currentUserId == null ? const SignInScreen() : const AppShell(),
    );
  }
}
