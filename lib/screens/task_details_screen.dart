import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/sla_service.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';
import '../widgets/status_chip.dart';

/// OWNER: Member D. Working baseline: title, SLA chip, "why" explanation, key facts.
/// TODO(D): assignee row, status dropdown that saves + logs activity, notes field,
///          edit button -> TaskFormScreen(task: task), delete with confirm dialog,
///          reload task after edit (pass result back with Navigator.pop).
class TaskDetailsScreen extends StatelessWidget {
  final Task task;
  const TaskDetailsScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final status = SlaService.statusOf(task);
    return Scaffold(
      appBar: AppBar(title: const Text('Task details')),
      body: ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [
        Text(task.title, style: text.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Align(alignment: Alignment.centerLeft, child: StatusChip(status)),
        const SizedBox(height: AppSpacing.md),
        Card(
          color: status.color.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(SlaService.explain(task)),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Due ${Fmt.date(task.dueDate)}  (${Fmt.timeLeft(task.dueDate)})'),
        Text('Priority: ${task.priority.label}'),
        Text('Status: ${task.status.label}'),
      ]),
    );
  }
}
