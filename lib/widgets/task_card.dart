import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import '../services/sla_service.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';
import 'member_avatar.dart';
import 'status_chip.dart';

/// Signature element of the app: a coloured "SLA edge" on the left of each task.
class TaskCard extends StatelessWidget {
  final Task task;
  final TeamMember? assignee;
  final VoidCallback onTap;
  const TaskCard({super.key, required this.task, required this.assignee, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = SlaService.statusOf(task);
    final text = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(width: 6, color: status.color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(children: [
                  MemberAvatar(assignee),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(task.title, style: text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text('${task.category}  |  ${task.priority.label} priority', style: text.bodySmall),
                    ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center, children: [
                    StatusChip(status),
                    const SizedBox(height: 4),
                    Text(status.name == 'completed' ? Fmt.date(task.dueDate) : Fmt.timeLeft(task.dueDate), style: text.bodySmall),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
