import 'package:flutter/material.dart';
import '../utils/theme.dart';

class StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  const StatCard({super.key, required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Icon(icon, color: color),
          Text('$value', style: text.headlineMedium?.copyWith(color: color)),
          Text(label, style: text.bodySmall),
        ]),
      ),
    );
  }
}
