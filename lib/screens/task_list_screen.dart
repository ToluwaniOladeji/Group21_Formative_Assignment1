import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import '../services/database_service.dart';
import '../utils/theme.dart';
import '../widgets/task_card.dart';
import 'task_details_screen.dart';
import 'task_form_screen.dart';

/// OWNER: Member C. Working baseline: full list + add button + open details.
/// TODO(C): search bar, SLA filter chips (All/On track/At risk/Overdue/Completed),
///          "My tasks" toggle, sort by urgency, swipe-to-delete with undo, empty state.
class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  Map<int, TeamMember> _members = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = DatabaseService.instance;
    final tasks = await db.getTasks();
    final members = await db.getMembers();
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _members = {for (final m in members) m.id!: m};
    });
  }

  /// Push a screen, then reload: the pattern for "navigate and get fresh data back".
  Future<void> _open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Tasks')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(const TaskFormScreen()),
        icon: const Icon(Icons.add),
        label: const Text('New task'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 96),
        itemCount: _tasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, i) {
          final t = _tasks[i];
          return TaskCard(task: t, assignee: _members[t.assigneeId], onTap: () => _open(TaskDetailsScreen(task: t)));
        },
      ),
    );
  }
}
