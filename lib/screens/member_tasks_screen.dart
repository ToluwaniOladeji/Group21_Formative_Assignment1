import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import '../services/database_service.dart';
import '../services/sla_service.dart';
import '../utils/theme.dart';
import '../widgets/state_message.dart';
import '../widgets/task_card.dart';
import 'task_details_screen.dart';


class MemberTasksScreen extends StatefulWidget {
  final TeamMember member;
  const MemberTasksScreen({super.key, required this.member});

  @override
  State<MemberTasksScreen> createState() => _MemberTasksScreenState();
}

class _MemberTasksScreenState extends State<MemberTasksScreen> {
  List<Task> _tasks = [];
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final mine = await DatabaseService.instance.getTasksFor(widget.member.id!);
      mine.sort((a, b) => SlaService.urgencyScore(b).compareTo(SlaService.urgencyScore(a)));
      if (!mounted) return;
      setState(() {
        _tasks = mine;
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

  Future<void> _open(Task t) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailsScreen(task: t)));
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.member;
    final text = Theme.of(context).textTheme;
    final done = _tasks.where((t) => t.status == TaskStatus.done).length;
    return Scaffold(
      appBar: AppBar(title: Text(m.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _failed
              ? StateMessage(
                  icon: Icons.error_outline,
                  title: 'Could not load tasks',
                  message: 'Something went wrong while reading the task list.',
                  actionLabel: 'Try again',
                  onActionPressed: () {
                    setState(() => _loading = true);
                    _load();
                  },
                )
              : _tasks.isEmpty
                  ? StateMessage(
                      icon: Icons.assignment_outlined,
                      title: 'No tasks yet',
                      message: '${m.name.split(' ').first} has no assigned tasks.',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xl),
                        itemCount: _tasks.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (_, i) {
                          if (i == 0) {
                            return Text('${m.role}  |  ${_tasks.length - done} open, $done done', style: text.bodySmall);
                          }
                          final t = _tasks[i - 1];
                          return TaskCard(task: t, assignee: m, onTap: () => _open(t));
                        },
                      ),
                    ),
    );
  }
}
