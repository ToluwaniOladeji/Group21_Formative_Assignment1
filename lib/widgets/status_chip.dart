import 'package:flutter/material.dart';
import '../models/sla_status.dart';
import '../utils/theme.dart';

/// Small pill showing an SLA status. Reused on lists, cards and details.
class StatusChip extends StatelessWidget {
  final SlaStatus status;
  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(status.icon, size: 14, color: status.color),
        const SizedBox(width: 4),
        Text(status.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: status.color, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
