import 'package:flutter/material.dart';
import '../models/team_member.dart';
import '../services/database_service.dart';
import '../services/prefs_service.dart';
import '../utils/theme.dart';
import '../widgets/member_avatar.dart';
import 'app_shell.dart';

/// OWNER: Member B. Working baseline: pick who you are. No real auth needed.
/// TODO(B): welcome illustration/brand block, "Add new member" option, error state if DB fails.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  List<TeamMember> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final members = await DatabaseService.instance.getMembers();
    if (!mounted) return;
    setState(() {
      _members = members;
      _loading = false;
    });
  }

  Future<void> _signIn(TeamMember m) async {
    await PrefsService.setCurrentUser(m.id!);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AppShell()));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: AppSpacing.xl),
            Text('Beacon', style: text.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text('Know which tasks need you before they slip.', style: text.bodyMedium),
            const SizedBox(height: AppSpacing.xl),
            Text('Who is working today?', style: text.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      itemCount: _members.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, i) {
                        final m = _members[i];
                        return Card(
                          child: ListTile(
                            leading: MemberAvatar(m),
                            title: Text(m.name, style: text.titleMedium),
                            subtitle: Text(m.role),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _signIn(m),
                          ),
                        );
                      },
                    ),
            ),
          ]),
        ),
      ),
    );
  }
}
