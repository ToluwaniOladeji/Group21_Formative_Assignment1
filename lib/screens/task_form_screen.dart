import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import '../services/database_service.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';
import '../utils/validators.dart';
import '../services/prefs_service.dart';

const _gap = SizedBox(height: AppSpacing.md);

class TaskFormScreen extends StatefulWidget {
  final Task? task;
  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _key = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  List<TeamMember> _members = [];
  List<Task> _tasks = [];
  int? _assigneeId;
  DateTime? _due;
  Priority _priority = Priority.medium;
  TaskStatus _status = TaskStatus.todo;
  bool _saving = false;
  bool _dirty = false;

  bool get _editing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    if (t != null) {
      _title.text = t.title;
      _desc.text = t.description;
      _assigneeId = t.assigneeId;
      _due = t.dueDate;
      _priority = t.priority;
      _status = t.status;
    }
    _loadLists();
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _loadLists() async {
    try {
      final db = DatabaseService.instance;
      final members = await db.getMembers();
      final tasks = await db.getTasks();
      if (!mounted) return;
      setState(() {
        _members = members;
        _tasks = tasks;
        if (!members.any((m) => m.id == _assigneeId)) _assigneeId = null;
      });
    } catch (_) {
      if (!mounted) return;
      _snack('Could not load team members.');
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _due ?? now,
      firstDate: _editing ? DateTime(2020) : now,
      lastDate: DateTime(now.year + 3),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_due ?? now),
    );
    if (time == null) return;
    setState(() {
      _due = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _dirty = true;
    });
  }

  Future<void> _save() async {
    if (_saving || !_key.currentState!.validate()) return;
    setState(() => _saving = true);
    final db = DatabaseService.instance;
    final title = _title.text.trim();
    final desc = _desc.text.trim();
    try {
      final old = widget.task;
      final me = PrefsService.currentUserId;
      if (old == null) {
        final id = await db.insertTask(Task(
          title: title,
          description: desc,
          assigneeId: _assigneeId!,
          priority: _priority,
          status: _status,
          dueDate: _due!,
          createdAt: DateTime.now(),
        ));
        if (me != null) {
          await db.logActivity(me, 'created "$title"', taskId: id);
        }
      } else {
        await db.updateTask(old.copyWith(
          title: title,
          description: desc,
          assigneeId: _assigneeId,
          priority: _priority,
          status: _status,
          dueDate: _due,
        ));
        if (me != null) {
          await db.logActivity(me, 'updated "$title"', taskId: old.id);
        }
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Could not save the task. Try again.');
    }
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your edits will be lost.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep editing')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Discard')),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_editing ? 'Edit task' : 'New task')),
        body: Form(
          key: _key,
          onChanged: () => setState(() => _dirty = true),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) =>
                    Validators.title(v) ??
                    Validators.duplicateTitle(v ?? '', _assigneeId, _tasks,
                        editingId: widget.task?.id),
              ),
              _gap,
              TextFormField(
                controller: _desc,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: Validators.description,
              ),
              _gap,
              DropdownButtonFormField<int>(
                initialValue: _assigneeId,
                decoration: const InputDecoration(labelText: 'Assigned to'),
                items: [
                  for (final m in _members)
                    DropdownMenuItem(value: m.id, child: Text(m.name))
                ],
                onChanged: (v) => setState(() => _assigneeId = v),
                validator: (v) => Validators.required(v, 'a team member'),
              ),
              _gap,
              FormField<DateTime>(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (_) => Validators.dueDate(_due, isNew: !_editing),
                builder: (f) => InkWell(
                  onTap: () async {
                    await _pickDue();
                    f.didChange(_due);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Deadline',
                      errorText: f.errorText,
                      suffixIcon: const Icon(Icons.event_outlined),
                    ),
                    child: Text(_due == null
                        ? 'Pick a date and time'
                        : '${Fmt.date(_due!)}, ${TimeOfDay.fromDateTime(_due!).format(context)}'),
                  ),
                ),
              ),
              _gap,
              DropdownButtonFormField<Priority>(
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: [
                  for (final p in Priority.values)
                    DropdownMenuItem(value: p, child: Text(p.label))
                ],
                onChanged: (v) => setState(() => _priority = v!),
              ),
              _gap,
              DropdownButtonFormField<TaskStatus>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: [
                  for (final s in TaskStatus.values)
                    DropdownMenuItem(value: s, child: Text(s.label))
                ],
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: const Text('Save task'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
