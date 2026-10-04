import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// The four SLA classes every task falls into. Computed, never stored.
enum SlaStatus { onTrack, atRisk, overdue, completed }

extension SlaStatusX on SlaStatus {
  String get label => switch (this) {
        SlaStatus.onTrack => 'On track',
        SlaStatus.atRisk => 'At risk',
        SlaStatus.overdue => 'Overdue',
        SlaStatus.completed => 'Completed',
      };

  Color get color => switch (this) {
        SlaStatus.onTrack => AppColors.onTrack,
        SlaStatus.atRisk => AppColors.atRisk,
        SlaStatus.overdue => AppColors.overdue,
        SlaStatus.completed => AppColors.completed,
      };

  IconData get icon => switch (this) {
        SlaStatus.onTrack => Icons.check_circle_outline,
        SlaStatus.atRisk => Icons.warning_amber_rounded,
        SlaStatus.overdue => Icons.error_outline,
        SlaStatus.completed => Icons.task_alt,
      };
}
