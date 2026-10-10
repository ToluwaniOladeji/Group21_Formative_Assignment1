import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/sla_status.dart';
import '../models/task.dart';
import '../services/sla_service.dart';
import '../utils/theme.dart';

/// Donut chart: how many tasks are in each SLA status, with a legend.
class SlaDonutChart extends StatelessWidget {
  final List<Task> tasks;
  const SlaDonutChart({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final counts = {
      for (final s in SlaStatus.values)
        s: tasks.where((t) => SlaService.statusOf(t) == s).length,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Status distribution', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(alignment: Alignment.center, children: [
                CustomPaint(
                    size: const Size(120, 120), painter: _DonutPainter(counts)),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${tasks.length}', style: text.headlineMedium),
                  Text('tasks', style: text.bodySmall),
                ]),
              ]),
            ),
            const SizedBox(width: AppSpacing.lg),
            // Legend: one row per status, Expanded stops long text overflowing
            Expanded(
              child: Column(children: [
                for (final s in SlaStatus.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: s.color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(s.label, style: text.bodyMedium)),
                      Text('${counts[s]}', style: text.titleMedium),
                    ]),
                  ),
              ]),
            ),
          ]),
        ]),
      ),
    );
  }
}

/// Draws the donut: one arc per status, sized by its share of all tasks.
class _DonutPainter extends CustomPainter {
  final Map<SlaStatus, int> counts;
  _DonutPainter(this.counts);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 18.0;
    final total = counts.values.fold(0, (a, b) => a + b);
    final rect = Rect.fromLTWH(
        stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    // No tasks: draw a plain grey ring
    if (total == 0) {
      paint.color = AppColors.border;
      canvas.drawArc(rect, 0, 2 * math.pi, false, paint);
      return;
    }

    var start = -math.pi / 2; // start at the top
    for (final s in SlaStatus.values) {
      final count = counts[s] ?? 0;
      if (count == 0) continue;
      final sweep = 2 * math.pi * count / total;
      paint.color = s.color;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => true;
}

/// Bar chart: open (not done) tasks by priority.
class PriorityBarChart extends StatelessWidget {
  final List<Task> tasks;
  const PriorityBarChart({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final open = tasks.where((t) => t.status != TaskStatus.done);
    final counts = {
      for (final p in Priority.values)
        p: open.where((t) => t.priority == p).length,
    };
    final biggest = counts.values.fold(1, math.max); // avoids dividing by 0

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Open tasks by priority', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          for (final p in Priority.values.reversed) // High first
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(children: [
                SizedBox(
                    width: 64, child: Text(p.label, style: text.bodyMedium)),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                    child: LinearProgressIndicator(
                      value: counts[p]! / biggest,
                      minHeight: 12,
                      backgroundColor: AppColors.border,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('${counts[p]}', style: text.titleMedium),
              ]),
            ),
        ]),
      ),
    );
  }
}
