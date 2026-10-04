import 'package:flutter/material.dart';
import '../widgets/placeholder_screen.dart';

class WorkloadScreen extends StatelessWidget {
  const WorkloadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(title: 'Team workload', owner: 'Member B', todo: ['For each member: open tasks, at-risk + overdue count', 'Horizontal stacked bar per member built with Row + Expanded(flex: n) + Container', 'Flag anyone with 4+ open tasks as overloaded', 'Tap a member -> filtered task list', ]);
  }
}
