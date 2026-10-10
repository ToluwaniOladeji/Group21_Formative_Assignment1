import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/activity_entry.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import 'prefs_service.dart';

/// SQLite access. Screens call these methods, then call setState() with the result.
///
/// Tables:  members(id, name, role, email, color)
///          tasks(id, title, description, category, assignee_id -> members.id, priority,
///                status, due_date, created_at, notes)
///          activity(id, task_id, member_id, message, timestamp)
/// Dates are stored as milliseconds since epoch (INTEGER); enums as their index.
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get _database async => _db ??= await _open();

  /// Call once from main(): opens the DB and seeds demo data on first launch.
  Future<void> init() async {
    final db = await _database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM members')) ?? 0;
    if (count == 0) await _seedAll(db);
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'beacon.db');
    return openDatabase(
      path,
      version: 1,
      // Make SQLite enforce the tasks -> members foreign key.
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, _) async {
        await db.execute('''CREATE TABLE members(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL, role TEXT NOT NULL, email TEXT NOT NULL, color INTEGER NOT NULL)''');
        await db.execute('''CREATE TABLE tasks(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL, description TEXT NOT NULL, category TEXT NOT NULL,
          assignee_id INTEGER NOT NULL, priority INTEGER NOT NULL, status INTEGER NOT NULL,
          due_date INTEGER NOT NULL, created_at INTEGER NOT NULL, notes TEXT NOT NULL,
          FOREIGN KEY(assignee_id) REFERENCES members(id))''');
        await db.execute('''CREATE TABLE activity(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          task_id INTEGER, member_id INTEGER NOT NULL,
          message TEXT NOT NULL, timestamp INTEGER NOT NULL)''');
      },
    );
  }

  // ---------------- Members ----------------
  Future<List<TeamMember>> getMembers() async {
    final rows = await (await _database).query('members', orderBy: 'name');
    return rows.map(TeamMember.fromMap).toList();
  }

  Future<TeamMember?> getMember(int id) async {
    final rows = await (await _database).query('members', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : TeamMember.fromMap(rows.first);
  }

  Future<int> insertMember(TeamMember m) async => (await _database).insert('members', m.toMap());

  Future<void> updateMember(TeamMember m) async =>
      (await _database).update('members', m.toMap(), where: 'id = ?', whereArgs: [m.id]);

  Future<int> countTasksFor(int memberId) async => Sqflite.firstIntValue(await (await _database)
      .rawQuery('SELECT COUNT(*) FROM tasks WHERE assignee_id = ?', [memberId])) ??
      0;

  /// Refuse to delete a member who still owns tasks (protects data integrity).
  /// Returns false when refused so the screen can explain why.
  Future<bool> deleteMember(int id) async {
    if (await countTasksFor(id) > 0) return false;
    await (await _database).delete('members', where: 'id = ?', whereArgs: [id]);
    return true;
  }

  // ---------------- Tasks ----------------
  Future<List<Task>> getTasks() async {
    final rows = await (await _database).query('tasks', orderBy: 'due_date ASC');
    return rows.map(Task.fromMap).toList();
  }

  Future<Task?> getTask(int id) async {
    final rows = await (await _database).query('tasks', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Task.fromMap(rows.first);
  }

  Future<List<Task>> getTasksFor(int memberId) async {
    final rows = await (await _database)
        .query('tasks', where: 'assignee_id = ?', whereArgs: [memberId], orderBy: 'due_date ASC');
    return rows.map(Task.fromMap).toList();
  }

  /// Returns the new row id.
  Future<int> insertTask(Task t) async => (await _database).insert('tasks', t.toMap());

  Future<void> updateTask(Task t) async =>
      (await _database).update('tasks', t.toMap(), where: 'id = ?', whereArgs: [t.id]);

  Future<void> deleteTask(int id) async =>
      (await _database).delete('tasks', where: 'id = ?', whereArgs: [id]);

  // ---------------- Activity ----------------
  /// Low-level insert with an explicit member.
  Future<void> logActivity(int memberId, String message, {int? taskId}) async {
    await (await _database).insert(
      'activity',
      ActivityEntry(memberId: memberId, taskId: taskId, message: message, timestamp: DateTime.now()).toMap(),
    );
  }

  /// USE THIS from screens. Logs as the signed-in member and never throws, so a
  /// logging problem can't break saving a task.
  ///
  /// `message` is the part AFTER the person's name, e.g.
  ///   'created "Fix login crash"'  ->  shown as  "Amara Okafor created "Fix login crash""
  Future<void> logAction(String message, {int? taskId}) async {
    final me = PrefsService.currentUserId;
    if (me == null) return;
    try {
      await logActivity(me, message, taskId: taskId);
    } catch (e) {
      debugPrint('Activity log failed: $e');
    }
  }

  Future<List<ActivityEntry>> getActivity({int limit = 100}) async {
    final rows = await (await _database).query('activity', orderBy: 'timestamp DESC', limit: limit);
    return rows.map(ActivityEntry.fromMap).toList();
  }

  // ---------------- Demo data ----------------
  /// Wipes tasks + activity and re-creates the demo tasks with fresh deadlines
  /// (relative to now). Members are kept, so nobody gets signed out.
  /// Run this before recording the demo so every SLA state is visible.
  Future<void> reseedDemoData() async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.delete('activity');
      await txn.delete('tasks');
    });
    final rows = await db.query('members', orderBy: 'id');
    if (rows.isEmpty) {
      await _seedAll(db);
    } else {
      await _seedTasks(db, rows.map((r) => r['id'] as int).toList());
    }
  }

  Future<void> _seedAll(Database db) async {
    final ids = <int>[];
    for (final m in const [
      TeamMember(name: 'Amara Okafor', role: 'Project Manager', email: 'amara@team.com', colorValue: 0xFF4338CA),
      TeamMember(name: 'Jonas Weber', role: 'Mobile Developer', email: 'jonas@team.com', colorValue: 0xFF0D9488),
      TeamMember(name: 'Sofia Reyes', role: 'UI/UX Designer', email: 'sofia@team.com', colorValue: 0xFFDB2777),
      TeamMember(name: 'Kenji Tanaka', role: 'QA Tester', email: 'kenji@team.com', colorValue: 0xFFEA580C),
    ]) {
      ids.add(await db.insert('members', m.toMap()));
    }
    await _seedTasks(db, ids);
  }

  /// Seven tasks covering every SLA state, plus a few activity entries.
  /// `ids` are member ids; indexes wrap around if the team was edited.
  Future<void> _seedTasks(Database db, List<int> ids) async {
    final now = DateTime.now();
    int who(int i) => ids[i % ids.length];

    Task t(String title, String cat, int person, Priority p, TaskStatus s, Duration due) => Task(
      title: title,
      category: cat,
      assigneeId: who(person),
      priority: p,
      status: s,
      dueDate: now.add(due),
      createdAt: now.subtract(const Duration(days: 5)),
    );

    final tasks = [
      t('Fix login crash on Android', 'Bug', 1, Priority.high, TaskStatus.inProgress, const Duration(days: -2)), // Overdue
      t('Write sprint test plan', 'QA', 3, Priority.medium, TaskStatus.todo, const Duration(hours: 30)), // At risk
      t('Design onboarding screens', 'Design', 2, Priority.high, TaskStatus.inProgress, const Duration(hours: 60)), // At risk
      t('Integrate payment API', 'Feature', 1, Priority.high, TaskStatus.blocked, const Duration(days: 6)), // At risk (blocked)
      t('Set up CI pipeline', 'DevOps', 1, Priority.low, TaskStatus.todo, const Duration(days: 9)), // On track
      t('Prepare client demo', 'Docs', 0, Priority.medium, TaskStatus.inProgress, const Duration(days: 5)), // On track
      t('Create app icon set', 'Design', 2, Priority.low, TaskStatus.done, const Duration(days: -1)), // Completed
    ];
    final taskIds = <int>[];
    for (final task in tasks) {
      taskIds.add(await db.insert('tasks', task.toMap()));
    }

    Future<void> log(int person, String msg, int taskIndex, Duration ago) => db.insert(
      'activity',
      ActivityEntry(
        memberId: who(person),
        taskId: taskIds[taskIndex],
        message: msg,
        timestamp: now.subtract(ago),
      ).toMap(),
    );
    await log(2, 'marked "Create app icon set" as done', 6, const Duration(hours: 3));
    await log(1, 'changed "Integrate payment API" from In progress to Blocked', 3, const Duration(hours: 9));
    await log(0, 'created "Prepare client demo"', 5, const Duration(days: 1, hours: 2));
    await log(3, 'created "Write sprint test plan"', 1, const Duration(days: 2));
  }
}
