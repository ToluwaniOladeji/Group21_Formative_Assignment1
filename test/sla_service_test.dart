import 'package:beacon_tracker/models/sla_status.dart';
import 'package:beacon_tracker/models/task.dart';
import 'package:beacon_tracker/services/sla_service.dart';
import 'package:flutter_test/flutter_test.dart';

Task task({required Duration due, Priority p = Priority.medium, TaskStatus s = TaskStatus.inProgress, required DateTime now}) =>
    Task(title: 'x', assigneeId: 1, priority: p, status: s, dueDate: now.add(due), createdAt: now);

void main() {
  final now = DateTime(2026, 1, 1, 9);

  test('done task is completed even if late', () {
    expect(SlaService.statusOf(task(due: const Duration(days: -3), s: TaskStatus.done, now: now), now: now), SlaStatus.completed);
  });
  test('past deadline and not done is overdue', () {
    expect(SlaService.statusOf(task(due: const Duration(hours: -1), now: now), now: now), SlaStatus.overdue);
  });
  test('blocked task is at risk', () {
    expect(SlaService.statusOf(task(due: const Duration(days: 20), s: TaskStatus.blocked, now: now), now: now), SlaStatus.atRisk);
  });
  test('medium priority in progress: at risk inside 48h', () {
    expect(SlaService.statusOf(task(due: const Duration(hours: 40), now: now), now: now), SlaStatus.atRisk);
    expect(SlaService.statusOf(task(due: const Duration(hours: 60), now: now), now: now), SlaStatus.onTrack);
  });
  test('not-started tasks get a wider risk window', () {
    expect(SlaService.statusOf(task(due: const Duration(hours: 60), s: TaskStatus.todo, now: now), now: now), SlaStatus.atRisk);
  });
}
