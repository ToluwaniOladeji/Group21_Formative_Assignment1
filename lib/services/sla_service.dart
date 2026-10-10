import '../models/sla_status.dart';
import '../models/task.dart';

/// Editable SLA thresholds: hours before the deadline when a task becomes "At risk".
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

  static const SlaRules defaults = SlaRules();

  /// The rules the whole app uses. Loaded at startup by PrefsService.init().
  static SlaRules current = defaults;

  SlaRules copyWith({int? highHours, int? mediumHours, int? lowHours, int? notStartedBonusHours}) => SlaRules(
    highHours: highHours ?? this.highHours,
    mediumHours: mediumHours ?? this.mediumHours,
    lowHours: lowHours ?? this.lowHours,
    notStartedBonusHours: notStartedBonusHours ?? this.notStartedBonusHours,
  );

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
///
/// `now` and `rules` are optional parameters so the logic can be unit-tested
/// and previewed with draft rules without touching global state.
class SlaService {
  static SlaStatus statusOf(Task t, {DateTime? now, SlaRules? rules}) {
    final n = now ?? DateTime.now();
    final r = rules ?? SlaRules.current;
    if (t.status == TaskStatus.done) return SlaStatus.completed;
    if (n.isAfter(t.dueDate)) return SlaStatus.overdue;
    if (t.status == TaskStatus.blocked) return SlaStatus.atRisk;
    if (t.dueDate.difference(n) <= Duration(hours: r.windowFor(t))) return SlaStatus.atRisk;
    return SlaStatus.onTrack;
  }

  /// Plain-language reason, shown on Task Details ("why is this At risk?").
  static String explain(Task t, {DateTime? now, SlaRules? rules}) {
    final r = rules ?? SlaRules.current;
    switch (statusOf(t, now: now, rules: r)) {
      case SlaStatus.completed:
        return 'This task is marked done.';
      case SlaStatus.overdue:
        return 'The deadline has passed and the task is not done.';
      case SlaStatus.atRisk:
        if (t.status == TaskStatus.blocked) return 'The task is blocked, so the deadline is in danger.';
        return 'Due within ${r.windowFor(t)} hours, the risk window for '
            '${t.priority.label.toLowerCase()} priority'
            '${t.status == TaskStatus.todo ? ' tasks that have not started' : ' tasks'}.';
      case SlaStatus.onTrack:
        return 'Enough time remains before the deadline.';
    }
  }

  /// Higher = needs attention sooner. Overdue > At risk > On track, then by
  /// priority, then by how close the deadline is. Completed tasks always rank last.
  static int urgencyScore(Task t, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final status = statusOf(t, now: n);
    if (status == SlaStatus.completed) return -10000;
    final base = switch (status) {
      SlaStatus.overdue => 1000,
      SlaStatus.atRisk => 500,
      _ => 0,
    };
    final hours = t.dueDate.difference(n).inHours.clamp(-300, 300);
    return base + t.priority.index * 25 - hours;
  }

  /// Tasks sorted most urgent first (returns a new list).
  static List<Task> sortByUrgency(Iterable<Task> tasks, {DateTime? now}) {
    final n = now ?? DateTime.now();
    return tasks.toList()..sort((a, b) => urgencyScore(b, now: n).compareTo(urgencyScore(a, now: n)));
  }

  /// How many tasks fall in each SLA class (used by the dashboard counters).
  static Map<SlaStatus, int> counts(Iterable<Task> tasks, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final result = {for (final s in SlaStatus.values) s: 0};
    for (final t in tasks) {
      final s = statusOf(t, now: n);
      result[s] = result[s]! + 1;
    }
    return result;
  }
}
