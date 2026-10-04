import 'package:flutter/material.dart';
import '../widgets/placeholder_screen.dart';

class AttentionScreen extends StatelessWidget {
  const AttentionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(title: 'Attention queue', owner: 'Member C', todo: ['Load tasks, drop Completed, sort by SlaService.urgencyScore (highest first)', 'Group under headers: Overdue, At risk, Watch list', 'Each row: TaskCard + one-tap "Mark done" or "Nudge" action', 'Friendly empty state: "Nothing needs you right now"', ]);
  }
}
