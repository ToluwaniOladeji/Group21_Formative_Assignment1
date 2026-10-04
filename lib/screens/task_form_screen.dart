import 'package:flutter/material.dart';
import '../widgets/placeholder_screen.dart';

class TaskFormScreen extends StatelessWidget {
  const TaskFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(title: 'Create / edit task', owner: 'Member C', todo: ['Constructor: TaskFormScreen({Task? task}) - null means create, non-null means edit', 'Form + GlobalKey<FormState>, TextFormField (title, description) using Validators', 'DropdownButtonFormField for assignee, priority, status (assignee required)', 'showDatePicker + showTimePicker for the deadline, Validators.dueDate', 'Save: insert/update via DatabaseService in try/catch, log activity, SnackBar, Navigator.pop(true)', ]);
  }
}
