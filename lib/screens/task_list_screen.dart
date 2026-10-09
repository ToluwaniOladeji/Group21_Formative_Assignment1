import 'package:flutter/material.dart';
import '../models/sla_status.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import '../services/database_service.dart';
import '../services/sla_service.dart';
import '../utils/theme.dart';
import '../widgets/task_card.dart';
import 'task_details_screen.dart';
import 'task_form_screen.dart';
import '../services/prefs_service.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  Map<int, TeamMember> _members = {};
  String _query = '';
  SlaStatus? _filter;
  bool _mineOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final db = DatabaseService.instance;
      final tasks = await db.getTasks();
      final members = await db.getMembers();
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _members = {for (final m in members) m.id!: m};
      });
    } catch (_) {
      if (!mounted) return;
      _snack('Could not load tasks.');
    }
  }

  void _snack(String msg, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg), action: action));
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    _load();
  }

  List<Task> get _shown {
    final q = _query.trim().toLowerCase();
    final list = _tasks.where((t) {
      final okSearch = t.title.toLowerCase().contains(q);
      final okFilter = _filter == null || SlaService.statusOf(t) == _filter;
      final okMine = !_mineOnly || t.assigneeId == PrefsService.currentUserId;
      return okSearch && okFilter && okMine;
    }).toList();
    list.sort((a, b) =>
        SlaService.urgencyScore(b).compareTo(SlaService.urgencyScore(a)));
    return list;
  }

  Future<bool> _confirmDelete(Task t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('"${t.title}" will be removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep task')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete task',
                style: TextStyle(color: AppColors.overdue)),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _delete(Task t) async {
    setState(() => _tasks.remove(t));
    try {
      await DatabaseService.instance.deleteTask(t.id!);
      // Log the activity
      final me = PrefsService.currentUserId;
      if (me != null) {
        await DatabaseService.instance.logActivity(me, 'deleted "${t.title}"');
      }
    } catch (_) {
      if (!mounted) return;
      _snack('Could not delete the task.');
      _load();
      return;
    }
    if (!mounted) return;
    _snack('Deleted "${t.title}"',
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await DatabaseService.instance.insertTask(t);
            _load();
          },
        ));
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Tasks')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(const TaskFormScreen()),
        icon: const Icon(Icons.add),
        label: const Text('New task'),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: TextField(
            decoration: const InputDecoration(
                hintText: 'Search by title', prefixIcon: Icon(Icons.search)),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: FilterChip(
                  label: const Text('My tasks'),
                  selected: _mineOnly,
                  onSelected: (v) => setState(() => _mineOnly = v),
                ),
              ),
              for (final s in <SlaStatus?>[null, ...SlaStatus.values])
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(s?.label ?? 'All'),
                    selected: _filter == s,
                    onSelected: (_) => setState(() => _filter = s),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: shown.isEmpty
              ? Center(
                  child: Text(
                    _tasks.isEmpty
                        ? 'No tasks yet. Add your first task.'
                        : 'No tasks match your search or filter.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.sm, AppSpacing.md, 96),
                  itemCount: shown.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) {
                    final t = shown[i];
                    return Dismissible(
                      key: ValueKey(t.id),
                      confirmDismiss: (dir) async {
                        if (dir == DismissDirection.startToEnd) {
                          _open(TaskFormScreen(task: t));
                          return false;
                        }
                        return _confirmDelete(t);
                      },
                      onDismissed: (_) => _delete(t),
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                        ),
                        child: const Icon(Icons.edit_outlined,
                            color: Colors.white),
                      ),
                      secondaryBackground: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.overdue,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                        ),
                        child: const Icon(Icons.delete_outline,
                            color: Colors.white),
                      ),
                      child: TaskCard(
                        task: t,
                        assignee: _members[t.assigneeId],
                        onTap: () => _open(TaskDetailsScreen(task: t)),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
