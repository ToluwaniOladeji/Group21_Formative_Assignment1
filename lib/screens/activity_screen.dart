import 'package:flutter/material.dart';
import '../models/activity_entry.dart';
import '../models/team_member.dart';
import '../services/database_service.dart';
import '../services/prefs_service.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';
import '../widgets/member_avatar.dart';
import 'task_details_screen.dart';

/// OWNER: Member A.
/// Audit trail read from the SQLite `activity` table. Entries are written by
/// DatabaseService.logAction(...) wherever a task or rule changes.
/// Tapping an entry that belongs to a task opens that task's details.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  List<ActivityEntry> _entries = [];
  Map<int, TeamMember> _members = {};
  bool _loading = true;
  String? _error;
  bool _onlyMine = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final db = DatabaseService.instance;
      final entries = await db.getActivity();
      final members = await db.getMembers();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _members = {for (final m in members) m.id!: m};
        _error = null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load the activity log.';
        _loading = false;
      });
    }
  }

  Future<void> _openTask(int taskId) async {
    final task = await DatabaseService.instance.getTask(taskId);
    if (!mounted) return;
    if (task == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('That task no longer exists.')));
      return;
    }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailsScreen(task: task)));
    _load();
  }

  List<ActivityEntry> get _visible {
    if (!_onlyMine) return _entries;
    final me = PrefsService.currentUserId;
    return _entries.where((e) => e.memberId == me).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity log')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _errorView()
          : RefreshIndicator(onRefresh: _load, child: _list()),
    );
  }

  Widget _errorView() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(_error!),
      const SizedBox(height: AppSpacing.sm),
      FilledButton(
        style: FilledButton.styleFrom(minimumSize: const Size(120, 44)),
        onPressed: () {
          setState(() => _loading = true);
          _load();
        },
        child: const Text('Try again'),
      ),
    ]),
  );

  Widget _list() {
    final text = Theme.of(context).textTheme;
    final items = _visible;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(), // lets pull-to-refresh work on short/empty lists
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: FilterChip(
            label: const Text('Only my activity'),
            selected: _onlyMine,
            onSelected: (v) => setState(() => _onlyMine = v),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xl),
            child: Column(children: [
              const Icon(Icons.history, size: 48, color: AppColors.textMuted),
              const SizedBox(height: AppSpacing.sm),
              Text('No activity yet', style: text.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text('Create or update a task and it will show up here.', style: text.bodySmall),
            ]),
          )
        else
          for (final e in items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Card(
                child: ListTile(
                  leading: MemberAvatar(_members[e.memberId]),
                  title: Text.rich(TextSpan(children: [
                    TextSpan(text: _members[e.memberId]?.name ?? 'Someone', style: const TextStyle(fontWeight: FontWeight.w700)),
                    TextSpan(text: ' ${e.message}'),
                  ])),
                  subtitle: Text(Fmt.ago(e.timestamp)),
                  trailing: e.taskId == null ? null : const Icon(Icons.chevron_right),
                  onTap: e.taskId == null ? null : () => _openTask(e.taskId!),
                ),
              ),
            ),
      ],
    );
  }
}
