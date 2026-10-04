/// Workflow state chosen by the user. (SLA status is derived from this + deadline.)
enum TaskStatus { todo, inProgress, blocked, done }

extension TaskStatusX on TaskStatus {
  String get label => switch (this) {
        TaskStatus.todo => 'To do',
        TaskStatus.inProgress => 'In progress',
        TaskStatus.blocked => 'Blocked',
        TaskStatus.done => 'Done',
      };
}

enum Priority { low, medium, high }

extension PriorityX on Priority {
  String get label => switch (this) {
        Priority.low => 'Low',
        Priority.medium => 'Medium',
        Priority.high => 'High',
      };
}

class Task {
  final int? id;
  final String title;
  final String description;
  final String category;
  final int assigneeId;
  final Priority priority;
  final TaskStatus status;
  final DateTime dueDate;
  final DateTime createdAt;
  final String notes;

  const Task({
    this.id,
    required this.title,
    this.description = '',
    this.category = 'General',
    required this.assigneeId,
    this.priority = Priority.medium,
    this.status = TaskStatus.todo,
    required this.dueDate,
    required this.createdAt,
    this.notes = '',
  });

  Task copyWith({
    String? title,
    String? description,
    String? category,
    int? assigneeId,
    Priority? priority,
    TaskStatus? status,
    DateTime? dueDate,
    String? notes,
  }) =>
      Task(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        category: category ?? this.category,
        assigneeId: assigneeId ?? this.assigneeId,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        dueDate: dueDate ?? this.dueDate,
        createdAt: createdAt,
        notes: notes ?? this.notes,
      );

  // Column names match the SQLite table in database_service.dart
  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'description': description,
        'category': category,
        'assignee_id': assigneeId,
        'priority': priority.index,
        'status': status.index,
        'due_date': dueDate.millisecondsSinceEpoch,
        'created_at': createdAt.millisecondsSinceEpoch,
        'notes': notes,
      };

  factory Task.fromMap(Map<String, Object?> m) => Task(
        id: m['id'] as int,
        title: m['title'] as String,
        description: m['description'] as String,
        category: m['category'] as String,
        assigneeId: m['assignee_id'] as int,
        priority: Priority.values[m['priority'] as int],
        status: TaskStatus.values[m['status'] as int],
        dueDate: DateTime.fromMillisecondsSinceEpoch(m['due_date'] as int),
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        notes: m['notes'] as String,
      );
}
