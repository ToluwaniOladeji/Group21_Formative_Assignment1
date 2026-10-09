import 'package:beacon_tracker/models/sla_status.dart';
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import '../services/database_service.dart';
import '../services/prefs_service.dart';
import '../services/sla_service.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';
import '../widgets/member_avatar.dart';
import '../widgets/status_chip.dart';
// import 'task_form_screen.dart'; // TODO(D): uncomment when Member C's form is merged

/// OWNER: Member D. Shows one task: SLA chip + reason, assignee, facts,
/// status dropdown (saves + logs), notes, edit and delete.
class TaskDetailsScreen extends StatefulWidget {
  final Task task;
  const TaskDetailsScreen({super.key, required this.task});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  late Task _task; // local copy, so the screen can change when status changes
  TeamMember? _assignee;
  TeamMember? _me;
  bool _changed = false; // tells the previous screen to reload
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _notesController.text = _task.notes;
    _loadPeople();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadPeople() async {
    try {
      final db = DatabaseService.instance;
      final assignee = await db.getMember(_task.assigneeId);
      final me = await db.getMember(PrefsService.currentUserId!);
      if (!mounted) return;
      setState(() {
        _assignee = assignee;
        _me = me;
      });
    } catch (e) {
      _showMessage('Could not load the assignee.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // Save a changed task, log it, then setState so the SLA chip updates at once.
  Future<void> _save(Task updated, String logMessage) async {
    try {
      final db = DatabaseService.instance;
      await db.updateTask(updated);
      await db.logActivity(PrefsService.currentUserId!, logMessage,
          taskId: updated.id);
      if (!mounted) return;
      setState(() {
        _task = updated;
        _changed = true;
      });
    } catch (e) {
      _showMessage('Could not save the change. Please try again.');
    }
  }

  Future<void> _changeStatus(TaskStatus? newStatus) async {
    if (newStatus == null || newStatus == _task.status) return;
    final who = _me?.name.split(' ').first ?? 'Someone';
    await _save(_task.copyWith(status: newStatus),
        '$who moved "${_task.title}" to ${newStatus.label}');
    _showMessage('Status changed to ${newStatus.label}');
  }

  Future<void> _saveNotes() async {
    final who = _me?.name.split(' ').first ?? 'Someone';
    await _save(_task.copyWith(notes: _notesController.text.trim()),
        '$who updated notes on "${_task.title}"');
    _showMessage('Notes saved');
  }

  Future<void> _confirmDelete() async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this task?'),
        content: Text('"${_task.title}" will be removed. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.overdue))),
        ],
      ),
    );
    if (sure != true) return;
    try {
      final db = DatabaseService.instance;
      final who = _me?.name.split(' ').first ?? 'Someone';
      await db.deleteTask(_task.id!);
      await db.logActivity(
          PrefsService.currentUserId!, '$who deleted "${_task.title}"');
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showMessage('Could not delete the task. Please try again.');
    }
  }

  Future<void> _edit() async {
    // TODO(D): replace the line below with this once Member C's form is merged:
    //
    // final saved = await Navigator.push<bool>(
    //   context,
    //   MaterialPageRoute(builder: (_) => TaskFormScreen(task: _task)),
    // );
    // if (saved == true) {
    //   final tasks = await DatabaseService.instance.getTasks();
    //   final fresh = tasks.where((t) => t.id == _task.id);
    //   if (fresh.isNotEmpty && mounted) {
    //     setState(() {
    //       _task = fresh.first;
    //       _notesController.text = _task.notes;
    //       _changed = true;
    //     });
    //     _loadPeople();
    //   }
    // }
    _showMessage('Edit form is coming soon.');
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final status = SlaService.statusOf(_task); // recalculated on every rebuild

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Task details'),
          actions: [
            IconButton(
                tooltip: 'Edit task',
                icon: const Icon(Icons.edit_outlined),
                onPressed: _edit),
            IconButton(
                tooltip: 'Delete task',
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.overdue),
                onPressed: _confirmDelete),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md,
              AppSpacing.md, AppSpacing.listBottom),
          children: [
            Text(_task.title, style: text.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Align(alignment: Alignment.centerLeft, child: StatusChip(status)),
            const SizedBox(height: AppSpacing.md),
            Card(
              color: status.color.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(SlaService.explain(_task)),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(children: [
                  Row(children: [
                    MemberAvatar(_assignee),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_assignee?.name ?? 'Unassigned',
                                style: text.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text(_assignee?.role ?? '', style: text.bodySmall),
                          ]),
                    ),
                  ]),
                  const Divider(height: AppSpacing.lg),
                  _fact(context, Icons.event_outlined, 'Due',
                      '${Fmt.date(_task.dueDate)} (${Fmt.timeLeft(_task.dueDate)})'),
                  const SizedBox(height: AppSpacing.sm),
                  _fact(context, Icons.flag_outlined, 'Priority',
                      _task.priority.label),
                  const SizedBox(height: AppSpacing.sm),
                  _fact(context, Icons.folder_outlined, 'Category',
                      _task.category),
                ]),
              ),
            ),
            if (_task.description.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text('Description', style: text.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(_task.description, style: text.bodyMedium),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text('Update status', style: text.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<TaskStatus>(
              // key makes the dropdown rebuild when the status changes
              key: ValueKey(_task.status),
              initialValue: _task.status,
              items: [
                for (final s in TaskStatus.values)
                  DropdownMenuItem(value: s, child: Text(s.label)),
              ],
              onChanged: _changeStatus,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Notes', style: text.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              maxLength: 300,
              decoration: const InputDecoration(
                  hintText: 'Add a note about this task'),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(onPressed: _saveNotes, child: const Text('Save notes')),
          ],
        ),
      ),
    );
  }

  // One row: icon + label + value. Expanded keeps long values from overflowing.
  Widget _fact(BuildContext context, IconData icon, String label, String value) {
    final text = Theme.of(context).textTheme;
    return Row(children: [
      Icon(icon, size: 20, color: AppColors.primary),
      const SizedBox(width: AppSpacing.sm),
      Text('$label: ', style: text.bodySmall),
      Expanded(
        child: Text(value,
            style: text.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
      ),
    ]);
  }
}