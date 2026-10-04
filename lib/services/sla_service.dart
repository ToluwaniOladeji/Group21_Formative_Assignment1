import '../models/sla_status.dart';
import '../models/task.dart';

/// Editable SLA thresholds (hours before the deadline when a task becomes "At risk").
/// Saved in SharedPreferences so the team can tune them on the SLA Rules screen.
class SlaRules {
  final int highHours;
  final int mediumHours;
  final int lowHours;
  final int notStartedBonusHours;

  const SlaRules({
    this.highHours = 72,
    this.mediumHours = 48,
    this.lowHours = 24,
    this.notStartedBonusHours = 24,
  });

  static SlaRules current = const SlaRules();

  /// Risk window for one task: priority base, plus a bonus if work has not started.
  int windowFor(Task t) {
    final base = switch (t.priority) {
      Priority.high => highHours,
      Priority.medium => mediumHours,
      Priority.low => lowHours,
    };
    return t.status == TaskStatus.todo ? base + notStartedBonusHours : base;
  }
}

/// The ONE place SLA logic lives.
///
/// Rules, checked in order:
///  1. Done                          -> Completed
///  2. Deadline passed               -> Overdue
///  3. Blocked                       -> At risk (blocked work cannot progress)
///  4. Time left <= risk window      -> At risk (window depends on priority,
///                                      +bonus when still "To do")
///  5. Otherwise                     -> On track
class SlaService {
  static SlaStatus statusOf(Task t, {DateTime? now}) {
    final n = now ?? DateTime.now();
    if (t.status == TaskStatus.done) return SlaStatus.completed;
    if (n.isAfter(t.dueDate)) return SlaStatus.overdue;
    if (t.status == TaskStatus.blocked) return SlaStatus.atRisk;
    final hoursLeft = t.dueDate.difference(n).inHours;
    if (hoursLeft <= SlaRules.current.windowFor(t)) return SlaStatus.atRisk;
    return SlaStatus.onTrack;
  }

  /// Plain-language reason, shown on Task Details ("why is this At risk?").
  static String explain(Task t, {DateTime? now}) {
    final n = now ?? DateTime.now();
    switch (statusOf(t, now: n)) {
      case SlaStatus.completed:
        return 'This task is marked done.';
      case SlaStatus.overdue:
        return 'The deadline has passed and the task is not done.';
      case SlaStatus.atRisk:
        if (t.status == TaskStatus.blocked) return 'The task is blocked, so the deadline is in danger.';
        return 'Due within ${SlaRules.current.windowFor(t)} hours, the risk window for '
            '${t.priority.label.toLowerCase()} priority'
            '${t.status == TaskStatus.todo ? ' tasks that have not started' : ' tasks'}.';
      case SlaStatus.onTrack:
        return 'Enough time remains before the deadline.';
    }
  }

  /// Higher = needs attention sooner. Used by the Attention Queue screen.
  static int urgencyScore(Task t, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final status = statusOf(t, now: n);
    if (status == SlaStatus.completed) return -1;
    final base = switch (status) {
      SlaStatus.overdue => 1000,
      SlaStatus.atRisk => 500,
      _ => 0,
    };
    final hours = t.dueDate.difference(n).inHours.clamp(-300, 300);
    return base + t.priority.index * 25 - hours;
  }
}
