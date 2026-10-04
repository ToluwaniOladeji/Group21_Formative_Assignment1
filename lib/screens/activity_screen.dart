import 'package:flutter/material.dart';
import '../widgets/placeholder_screen.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(title: 'Activity log', owner: 'Member A', todo: ['Load db.getActivity(), show with MemberAvatar + message + Fmt.ago(timestamp)', 'Make sure task create/update/delete/status change call db.logActivity(...)', 'Empty state and pull to refresh', ]);
  }
}
