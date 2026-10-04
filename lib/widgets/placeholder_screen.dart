import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// Temporary body for screens that have not been built yet.
/// Delete this widget's usage in your screen when you start real work.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String owner;
  final List<String> todo;
  const PlaceholderScreen({super.key, required this.title, required this.owner, required this.todo});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [
        Text('Owner: $owner', style: text.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        for (final item in todo)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.check_box_outline_blank, size: 18, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Expanded(child: Text(item)),
            ]),
          ),
      ]),
    );
  }
}
