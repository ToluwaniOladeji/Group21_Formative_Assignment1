import 'package:flutter/material.dart';
import '../models/sla_status.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import '../services/database_service.dart';
import '../services/prefs_service.dart';
import '../services/sla_service.dart';
import '../utils/theme.dart';
import '../widgets/stat_card.dart';
import 'activity_screen.dart';
import 'attention_screen.dart';
import 'workload_screen.dart';

/// OWNER: Member D. Working baseline: greeting + four SLA counters + links to extra screens.
/// TODO(D): status distribution bar/ring, upcoming deadlines list, recent activity preview,
///          pull-to-refresh, empty state.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Task> _tasks = [];
  TeamMember? _me;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = DatabaseService.instance;
    final tasks = await db.getTasks();
    final me = await db.getMember(PrefsService.currentUserId!);
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _me = me;
    });
  }

  int _count(SlaStatus s) => _tasks.where((t) => SlaService.statusOf(t) == s).length;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [
        Text('Hello, ${_me?.name.split(' ').first ?? ''}', style: text.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text('${_tasks.length} tasks across the project', style: text.bodySmall),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.5,
          children: [
            for (final s in SlaStatus.values)
              StatCard(label: s.label, value: _count(s), color: s.color, icon: s.icon),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _link(context, Icons.priority_high, 'Attention queue', 'Most urgent tasks first', const AttentionScreen()),
        _link(context, Icons.bar_chart, 'Team workload', 'Who is carrying what', const WorkloadScreen()),
        _link(context, Icons.history, 'Activity log', 'Everything that changed', const ActivityScreen()),
      ]),
    );
  }

  Widget _link(BuildContext context, IconData icon, String title, String sub, Widget screen) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Card(
          child: ListTile(
            leading: Icon(icon, color: AppColors.primary),
            title: Text(title),
            subtitle: Text(sub),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
          ),
        ),
      );
}
