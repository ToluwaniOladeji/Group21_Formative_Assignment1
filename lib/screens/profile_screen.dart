import 'package:flutter/material.dart';
import '../models/team_member.dart';
import '../services/database_service.dart';
import '../services/prefs_service.dart';
import '../utils/theme.dart';
import '../widgets/member_avatar.dart';
import 'sign_in_screen.dart';
import 'sla_rules_screen.dart';
import '../models/task.dart';                 // TaskStatus
import '../widgets/member_form_sheet.dart';   // showMemberFormSheet
import '../widgets/state_message.dart';       // StateMessage
import '../utils/snackbars.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  TeamMember? _me;
  int _openTasks = 0;
  int _completedTasks = 0;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = PrefsService.currentUserId;

    if (userId == null) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _failed = true;
      });
      return;
    }

    try {
      final db = DatabaseService.instance;
      final member = await db.getMember(userId);
      final tasks = await db.getTasksFor(userId);

      if (!mounted) return;
      if (member == null) {
        setState(() {
          _loading = false;
          _failed = true;
        });
        return;
      }
      final completed = tasks.where((task) => task.status == TaskStatus.done).length;
      setState(() {
        _me = member;
        _completedTasks = completed;
        _openTasks = tasks.length - completed;
        _loading = false;
        _failed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _editProfile() async {
    final me = _me;
    if (me == null) return;

    try {
      final members = await DatabaseService.instance.getMembers();
      if (!mounted) return;
      final saved = await showMemberFormSheet(context, member: me, existing: members);
      if (saved == null || !mounted) return;
      await _load();
      if (!mounted) return;
      AppSnack.show(context, 'Profile updated.');
    } catch (_) {
      if (!mounted) return;
      AppSnack.show(context, 'Could not update your profile. Please try again.', error: true,
      );
    }
  }

  Future<void> _signOut() async {
    await PrefsService.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const SignInScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_failed || _me == null) {
      return StateMessage(
        icon: Icons.error_outline,
        title: 'Could not load profile',
        message: 'Something went wrong while loading your profile.',
        actionLabel: 'Try again',
        onActionPressed: () {
          setState(() => _loading = true);
          _load();
        },
      );
    }

    final me = _me!;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Center(child: MemberAvatar(me, radius: 44)),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Text(me.name, style: text.titleLarge, textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: AppSpacing.xs),
        Center(child: Text(me.role, style: text.bodySmall)),
        const SizedBox(height: AppSpacing.xs),
        Center(child: Text(me.email, style: text.bodySmall)),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _StatCard(label: 'Open tasks', value: _openTasks, icon: Icons.pending_actions_outlined,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatCard(label: 'Completed', value: _completedTasks, icon: Icons.task_alt_outlined,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.lg),

        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
                title: const Text('Edit profile'),
                subtitle: const Text('Update your name, role or email'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _editProfile,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.rule, color: AppColors.primary),
                title: const Text('SLA rules'),
                subtitle: const Text('When does a task become at risk?'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SlaRulesScreen()),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.overdue),
                title: const Text(
                  'Sign out',
                  style: TextStyle(color: AppColors.overdue),
                ),
                onTap: _signOut,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Small reusable statistic card for this screen.
class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: AppSpacing.xs),
            Text('$value', style: text.titleLarge),
            Text(label, style: text.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
