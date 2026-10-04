/// One line in the audit trail ("Grace moved Design login to Done").
class ActivityEntry {
  final int? id;
  final int? taskId;
  final int memberId;
  final String message;
  final DateTime timestamp;

  const ActivityEntry({
    this.id,
    this.taskId,
    required this.memberId,
    required this.message,
    required this.timestamp,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'task_id': taskId,
        'member_id': memberId,
        'message': message,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory ActivityEntry.fromMap(Map<String, Object?> m) => ActivityEntry(
        id: m['id'] as int,
        taskId: m['task_id'] as int?,
        memberId: m['member_id'] as int,
        message: m['message'] as String,
        timestamp: DateTime.fromMillisecondsSinceEpoch(m['timestamp'] as int),
      );
}
