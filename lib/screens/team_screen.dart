import 'package:flutter/material.dart';
import '../models/team_member.dart';
import '../services/prefs_service.dart';
import '../services/database_service.dart';
import '../utils/snackbars.dart';
import '../utils/theme.dart';
import '../widgets/member_avatar.dart';
import '../widgets/member_form_sheet.dart';
import '../widgets/state_message.dart';
import 'member_tasks_screen.dart';

enum _MemberAction { edit, delete }

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  List<TeamMember> _members = [];
  Map<int, int> _taskCounts = {}; 
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final db = DatabaseService.instance;
      final members = await db.getMembers();
      final counts = await Future.wait(members.map((m) => db.countTasksFor(m.id!)));
      if (!mounted) return;
      setState(() {
        _members = members;
        _taskCounts = {for (var i = 0; i < members.length; i++) members[i].id!: counts[i]};
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

  Future<void> _addOrEdit([TeamMember? member]) async {
    final saved = await showMemberFormSheet(context, member: member, existing: _members);
    if (saved == null || !mounted) return;
    await _load();
    if (!mounted) return;
    AppSnack.show(context, member == null ? '${saved.name} added to the team.' : 'Saved changes to ${saved.name}.');
  }

  Future<void> _delete(TeamMember m) async {
    if (m.id == PrefsService.currentUserId) {
      AppSnack.show(context, 'You are signed in as ${m.name}. Sign in as someone else before removing this member.', error: true);
      return;
    }
    final owned = _taskCounts[m.id] ?? 0;
    if (owned > 0) {
      AppSnack.show(context, '${m.name} still owns $owned task${owned == 1 ? '' : 's'}. Reassign or delete them first.', error: true);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove ${m.name}?'),
        content: const Text('They will be removed from the team. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove', style: TextStyle(color: AppColors.overdue)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final db = DatabaseService.instance;
      final deleted = await db.deleteMember(m.id!);
      if (!mounted) return;
      if (!deleted) {
        await _load();
        if (!mounted) return;
        AppSnack.show(context, '${m.name} still owns tasks. Reassign or delete them first.', error: true);
        return;
      }
      await _logRemoval(m);
      await _load();
      if (!mounted) return;
      AppSnack.show(context, '${m.name} removed from the team.');
    } catch (_) {
      if (!mounted) return;
      AppSnack.show(context, 'Could not remove ${m.name}. Please try again.', error: true);
    }
  }

  //It is to make sure that a logging failure does not hide a successful delete
  Future<void> _logRemoval(TeamMember removed) async {
    final actorId = PrefsService.currentUserId;
    if (actorId == null) return;
    try {
      TeamMember? actor;
      for (final member in _members) {
        if (member.id == actorId) {
          actor = member;
          break;
        }
      }
      final who = actor?.name.split(' ').first ?? 'Someone';
    } catch (_) {}
  }

  Future<void> _openTasks(TeamMember m) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => MemberTasksScreen(member: m)));
    if (mounted) _load(); // task counts may have changed
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_failed) {
      return StateMessage(
        icon: Icons.error_outline,
        title: 'Could not load the team',
        message: 'Something went wrong while reading the member list.',
        actionLabel: 'Try again',
        onActionPressed: () {
          setState(() => _loading = true);
          _load();
        },
      );
    }
    if (_members.isEmpty) {
      return StateMessage(
        icon: Icons.group_add_outlined,
        title: 'No team members yet',
        message: 'Add your first team member.',
        actionLabel: 'Add member',
        onActionPressed: () => _addOrEdit(),
      );
    }
    final text = Theme.of(context).textTheme;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        // Bottom padding keeps the floating button from hiding the last card.
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 96),
        itemCount: _members.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, i) {
          final m = _members[i];
          final n = _taskCounts[m.id] ?? 0;
          final isMe = m.id == PrefsService.currentUserId;
          return Card(
            child: ListTile(
              leading: MemberAvatar(m),
              title: Text(isMe ? '${m.name} (you)' : m.name, style: text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${m.role}  |  ${n == 1 ? '1 task' : '$n tasks'}', maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => _openTasks(m),
              trailing: PopupMenuButton<_MemberAction>(
                tooltip: 'Member options',
                onSelected: (a) => a == _MemberAction.edit ? _addOrEdit(m) : _delete(m),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: _MemberAction.edit, child: Text('Edit')),
                  PopupMenuItem(value: _MemberAction.delete, child: Text('Delete', style: TextStyle(color: AppColors.overdue))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      // backgroundColor: AppColors.background
      appBar: AppBar(title: const Text('Team')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEdit(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add member'),
      ),
      body: _body(),
    );
  }
}
