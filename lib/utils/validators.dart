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
    if ((v?.trim().length ?? 0) > 300) return 'Description is limited to 300 characters.';
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
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(s)) return 'Enter a valid email, like name@team.com.';
    return null;
  }

  static String? required(Object? v, String what) => v == null ? 'Choose $what.' : null;

  /// New tasks cannot start with a deadline that has already passed.
  static String? dueDate(DateTime? v, {bool isNew = true}) {
    if (v == null) return 'Pick a due date.';
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    if (isNew && v.isBefore(startOfToday)) return 'Due date cannot be in the past.';
    return null;
  }

  // ---- SLA rule thresholds (SLA Rules screen) ----
  static String? slaHours(String? v) {
    final n = int.tryParse(v?.trim() ?? '');
    if (n == null || n < 1 || n > 240) return 'Enter hours between 1 and 240.';
    return null;
  }

  /// The "not started" bonus may be 0 (turn it off).
  static String? slaBonus(String? v) {
    final n = int.tryParse(v?.trim() ?? '');
    if (n == null || n < 0 || n > 240) return 'Enter hours between 0 and 240.';
    return null;
  }

  /// Higher priority must get an equal or wider window than lower priority.
  static String? slaOrder(int high, int medium, int low) =>
      (high >= medium && medium >= low) ? null : 'Windows must satisfy High >= Medium >= Low.';
}
