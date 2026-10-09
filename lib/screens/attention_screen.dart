import 'package:flutter/material.dart';
import '../models/sla_status.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import '../services/database_service.dart';
import '../services/sla_service.dart';
import '../utils/theme.dart';
import '../widgets/task_card.dart';
import 'task_details_screen.dart';

class AttentionScreen extends StatefulWidget {
  const AttentionScreen({super.key});

  @override
  State<AttentionScreen> createState() => _AttentionScreenState();
}

class _AttentionScreenState extends State<AttentionScreen> {
  List<Task> _tasks = [];
  Map<int, TeamMember> _members = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _load() async {
    try {
      final db = DatabaseService.instance;
      final all = await db.getTasks();
      final members = await db.getMembers();
      final open = all.where((t) => SlaService.statusOf(t) != SlaStatus.completed).toList()
        ..sort((a, b) => SlaService.urgencyScore(b).compareTo(SlaService.urgencyScore(a)));
      if (!mounted) return;
      setState(() {
        _tasks = open;
        _members = {for (final m in members) m.id!: m};
      });
    } catch (_) {
      if (!mounted) return;
      _snack('Could not load tasks.');
    }
  }

  Future<void> _markDone(Task t) async {
    try {
      await DatabaseService.instance.updateTask(t.copyWith(status: TaskStatus.done));
      _load();
    } catch (_) {
      if (!mounted) return;
      _snack('Could not update the task. Try again.');
    }
  }

  Future<void> _open(Task t) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailsScreen(task: t)));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final groups = {
      'Overdue': SlaStatus.overdue,
      'At risk': SlaStatus.atRisk,
      'Watch list': SlaStatus.onTrack,
    };

    final rows = <Widget>[];
    groups.forEach((title, status) {
      final items = _tasks.where((t) => SlaService.statusOf(t) == status).toList();
      if (items.isEmpty) return;
      rows.add(Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
        child: Text('$title (${items.length})', style: text.titleMedium?.copyWith(color: status.color)),
      ));
      for (final t in items) {
        rows.add(TaskCard(task: t, assignee: _members[t.assigneeId], onTap: () => _open(t)));
        rows.add(Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _markDone(t),
            icon: const Icon(Icons.check),
            label: const Text('Mark done'),
          ),
        ));
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Attention queue')),
      body: rows.isEmpty
          ? const Center(child: Text('Nothing needs you right now.'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 96),
              children: rows,
            ),
    );
  }
}