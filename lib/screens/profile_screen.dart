import 'package:flutter/material.dart';
import '../models/team_member.dart';
import '../services/database_service.dart';
import '../services/prefs_service.dart';
import '../utils/theme.dart';
import '../widgets/member_avatar.dart';
import 'sign_in_screen.dart';
import 'sla_rules_screen.dart';

/// OWNER: Member B. Working baseline: current user, SLA rules link, working sign out.
/// TODO(B): edit profile (name/role/email with validation), "my stats" (tasks owned/done),
///          about section.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  TeamMember? _me;

  @override
  void initState() {
    super.initState();
    DatabaseService.instance.getMember(PrefsService.currentUserId!).then((m) {
      if (mounted) setState(() => _me = m);
    });
  }

  Future<void> _signOut() async {
    await PrefsService.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const SignInScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(padding: const EdgeInsets.all(AppSpacing.lg), children: [
      Center(child: MemberAvatar(_me, radius: 44)),
      const SizedBox(height: AppSpacing.md),
      Center(child: Text(_me?.name ?? '', style: text.titleLarge)),
      Center(child: Text(_me?.role ?? '', style: text.bodySmall)),
      const SizedBox(height: AppSpacing.lg),
      Card(
        child: Column(children: [
          ListTile(
            leading: const Icon(Icons.rule, color: AppColors.primary),
            title: const Text('SLA rules'),
            subtitle: const Text('When does a task become at risk?'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SlaRulesScreen())),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.overdue),
            title: const Text('Sign out', style: TextStyle(color: AppColors.overdue)),
            onTap: _signOut,
          ),
        ]),
      ),
    ]);
  }
}
