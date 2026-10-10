import 'package:beacon_tracker/models/activity_entry.dart';
import 'package:beacon_tracker/models/task.dart';
import 'package:beacon_tracker/models/team_member.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Task survives a toMap -> fromMap round trip (what SQLite does)', () {
    final t = Task(
      id: 7,
      title: 'Fix login',
      description: 'desc',
      category: 'Bug',
      assigneeId: 3,
      priority: Priority.high,
      status: TaskStatus.blocked,
      dueDate: DateTime(2026, 10, 9, 14, 30),
      createdAt: DateTime(2026, 10, 4),
      notes: 'n',
    );
    final back = Task.fromMap(t.toMap());
    expect(back.id, 7);
    expect(back.title, 'Fix login');
    expect(back.priority, Priority.high);
    expect(back.status, TaskStatus.blocked);
    expect(back.dueDate, DateTime(2026, 10, 9, 14, 30));
    expect(back.assigneeId, 3);
  });
  test('new Task has no id in its map (SQLite assigns it)', () {
    final t = Task(title: 'x', assigneeId: 1, dueDate: DateTime(2026), createdAt: DateTime(2026));
    expect(t.toMap().containsKey('id'), isFalse);
  });
  test('copyWith changes only what is given', () {
    final t = Task(id: 1, title: 'a', assigneeId: 1, dueDate: DateTime(2026), createdAt: DateTime(2026));
    final u = t.copyWith(status: TaskStatus.done);
    expect(u.isDone, isTrue);
    expect(u.id, 1);
    expect(u.title, 'a');
  });
  test('TeamMember initials and round trip', () {
    const m = TeamMember(id: 1, name: 'Amara Okafor', role: 'PM', email: 'a@b.co', colorValue: 0xFF123456);
    expect(m.initials, 'AO');
    expect(const TeamMember(name: 'sofia', role: '', email: '', colorValue: 0).initials, 'S');
    expect(TeamMember.fromMap(m.toMap()).email, 'a@b.co');
  });
  test('ActivityEntry round trip keeps nullable task id', () {
    final e = ActivityEntry(id: 1, memberId: 2, message: 'did a thing', timestamp: DateTime(2026, 10, 4));
    final back = ActivityEntry.fromMap(e.toMap());
    expect(back.taskId, isNull);
    expect(back.message, 'did a thing');
  });
}
