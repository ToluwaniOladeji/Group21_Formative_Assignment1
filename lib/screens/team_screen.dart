import 'package:flutter/material.dart';
import '../models/team_member.dart';
import '../services/database_service.dart';
import '../utils/theme.dart';
import '../widgets/member_avatar.dart';

/// OWNER: Member B. Working baseline: list of members.
/// TODO(B): task count per member, add/edit member (bottom sheet with Form + Validators),
///          delete (uses db.deleteMember, show SnackBar if refused), tap -> member's tasks.
class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  List<TeamMember> _members = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final m = await DatabaseService.instance.getMembers();
    if (!mounted) return;
    setState(() => _members = m);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Team')),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _members.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, i) {
          final m = _members[i];
          return Card(
            child: ListTile(leading: MemberAvatar(m), title: Text(m.name, style: text.titleMedium), subtitle: Text(m.role)),
          );
        },
      ),
    );
  }
}
