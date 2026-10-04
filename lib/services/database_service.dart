import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/activity_entry.dart';
import '../models/task.dart';
import '../models/team_member.dart';

/// SQLite access. Screens call these methods, then call setState() with the result.
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get _database async => _db ??= await _open();

  /// Call once from main(): opens the DB and seeds demo data on first launch.
  Future<void> init() async {
    final db = await _database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM members')) ?? 0;
    if (count == 0) await _seed(db);
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'beacon.db');
    return openDatabase(path, version: 1, onCreate: (db, _) async {
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
    });
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

  Future<int> insertTask(Task t) async => (await _database).insert('tasks', t.toMap());

  Future<void> updateTask(Task t) async =>
      (await _database).update('tasks', t.toMap(), where: 'id = ?', whereArgs: [t.id]);

  Future<void> deleteTask(int id) async =>
      (await _database).delete('tasks', where: 'id = ?', whereArgs: [id]);

  // ---------------- Activity ----------------
  Future<void> logActivity(int memberId, String message, {int? taskId}) async {
    await (await _database).insert(
      'activity',
      ActivityEntry(memberId: memberId, taskId: taskId, message: message, timestamp: DateTime.now()).toMap(),
    );
  }

  Future<List<ActivityEntry>> getActivity({int limit = 50}) async {
    final rows = await (await _database).query('activity', orderBy: 'timestamp DESC', limit: limit);
    return rows.map(ActivityEntry.fromMap).toList();
  }

  // ---------------- Demo data ----------------
  /// Deadlines are relative to "now" so every SLA state is visible on first launch.
  Future<void> _seed(Database db) async {
    final now = DateTime.now();
    final ids = <int>[];
    for (final m in const [
      TeamMember(name: 'Amara Okafor', role: 'Project Manager', email: 'amara@team.com', colorValue: 0xFF4338CA),
      TeamMember(name: 'Jonas Weber', role: 'Mobile Developer', email: 'jonas@team.com', colorValue: 0xFF0D9488),
      TeamMember(name: 'Sofia Reyes', role: 'UI/UX Designer', email: 'sofia@team.com', colorValue: 0xFFDB2777),
      TeamMember(name: 'Kenji Tanaka', role: 'QA Tester', email: 'kenji@team.com', colorValue: 0xFFEA580C),
    ]) {
      ids.add(await db.insert('members', m.toMap()));
    }

    Task t(String title, String cat, int who, Priority p, TaskStatus s, Duration due) => Task(
          title: title,
          category: cat,
          assigneeId: ids[who],
          priority: p,
          status: s,
          dueDate: now.add(due),
          createdAt: now.subtract(const Duration(days: 5)),
        );

    for (final task in [
      t('Fix login crash on Android', 'Bug', 1, Priority.high, TaskStatus.inProgress, const Duration(days: -2)),
      t('Write sprint test plan', 'QA', 3, Priority.medium, TaskStatus.todo, const Duration(hours: 30)),
      t('Design onboarding screens', 'Design', 2, Priority.high, TaskStatus.inProgress, const Duration(hours: 60)),
      t('Integrate payment API', 'Feature', 1, Priority.high, TaskStatus.blocked, const Duration(days: 6)),
      t('Set up CI pipeline', 'DevOps', 1, Priority.low, TaskStatus.todo, const Duration(days: 9)),
      t('Prepare client demo', 'Docs', 0, Priority.medium, TaskStatus.inProgress, const Duration(days: 5)),
      t('Create app icon set', 'Design', 2, Priority.low, TaskStatus.done, const Duration(days: -1)),
    ]) {
      await db.insert('tasks', task.toMap());
    }
    await db.insert('activity', ActivityEntry(memberId: ids[2], message: 'Sofia finished Create app icon set', timestamp: now.subtract(const Duration(hours: 3))).toMap());
  }
}
