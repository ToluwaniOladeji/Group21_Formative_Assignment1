import '../models/task.dart';

/// All form validation lives here so it is easy to find and explain in the demo.
/// Each returns null when valid, or an error message (Flutter's FormField convention).
class Validators {
  static String? title(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Enter a task title.';
    if (s.length < 3) return 'Title needs at least 3 characters.';
    if (s.length > 60) return 'Keep the title under 60 characters.';
    return null;
  }

  static String? description(String? v) {
    if ((v?.trim().length ?? 0) > 300) {
      return 'Description is limited to 300 characters.';
    }
    return null;
  }

  static String? name(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Enter a name.';
    if (s.length < 2) return 'Name is too short.';
    return null;
  }

  static String? email(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Enter an email address.';
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(s)) {
      return 'Enter a valid email, like name@team.com.';
    }
    return null;
  }

  static String? required(Object? v, String what) =>
      v == null ? 'Choose $what.' : null;

  /// New tasks cannot start with a deadline that has already passed.
  static String? dueDate(DateTime? v, {bool isNew = true}) {
    if (v == null) return 'Pick a due date.';
    if (isNew && v.isBefore(DateTime.now())) {
      return 'Due date cannot be in the past.';
    }
    return null;
  }

  static String? duplicateTitle(String title, int? assigneeId, List<Task> tasks,
      {int? editingId}) {
    final t = title.trim().toLowerCase();
    final clash = tasks.any((x) =>
        x.id != editingId &&
        x.assigneeId == assigneeId &&
        x.title.toLowerCase() == t);
    return clash ? 'This person already has a task with that title.' : null;
  }
}
