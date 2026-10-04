import 'package:intl/intl.dart';

class Fmt {
  static String date(DateTime d) => DateFormat('d MMM yyyy').format(d);
  static String dateTime(DateTime d) => DateFormat('d MMM, HH:mm').format(d);

  /// "3 days left", "5 hours left", "2 days overdue"
  static String timeLeft(DateTime due, {DateTime? now}) {
    final diff = due.difference(now ?? DateTime.now());
    final abs = diff.abs();
    final unit = abs.inHours >= 48 ? '${abs.inDays} days' : abs.inHours >= 1 ? '${abs.inHours} h' : '${abs.inMinutes} min';
    return diff.isNegative ? '$unit overdue' : '$unit left';
  }

  /// "2 h ago" style text for the activity feed.
  static String ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes} min ago';
    if (d.inDays < 1) return '${d.inHours} h ago';
    return '${d.inDays} d ago';
  }
}
