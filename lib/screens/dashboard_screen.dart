import 'package:flutter/material.dart';
import '../models/sla_status.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import '../services/database_service.dart';
import '../services/prefs_service.dart';
import '../services/sla_service.dart';
import '../utils/theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/task_card.dart';
import 'activity_screen.dart';
import 'attention_screen.dart';
import 'workload_screen.dart';

/// OWNER: Member D. Greeting, four SLA counters, status bar,
/// upcoming deadlines, links to extra screens, pull to refresh.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Task> _tasks = [];
  TeamMember? _me;
  final Map<int, TeamMember?> _members = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Load from SQLite, then setState so the UI rebuilds with the new data.
  Future<void> _load() async {
    try {
      final db = DatabaseService.instance;
      final tasks = await db.getTasks();
      final me = await db.getMember(PrefsService.currentUserId!);
      final members = <int, TeamMember?>{};
      for (final t in tasks) {
        members[t.assigneeId] ??= await db.getMember(t.assigneeId);
      }
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _me = me;
        _members
          ..clear()
          ..addAll(members);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not load tasks. Pull down to try again.')),
      );
    }
  }

  int _count(SlaStatus s) =>
      _tasks.where((t) => SlaService.statusOf(t) == s).length;

  // Open tasks, soonest deadline first. Only the first 3 are shown.
  List<Task> get _upcoming {
    final open = _tasks
        .where((t) => SlaService.statusOf(t) != SlaStatus.completed)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return open.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        // Lets pull-to-refresh work even when the list is short.
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.listBottom),
        children: [
          Text('Hello, ${_me?.name.split(' ').first ?? ''}',
              style: text.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text('${_tasks.length} tasks across the project',
              style: text.bodySmall),
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
                StatCard(
                    label: s.label,
                    value: _count(s),
                    color: s.color,
                    icon: s.icon),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_tasks.isEmpty)
            _emptyState(context)
          else ...[
            _distributionBar(context),
            const SizedBox(height: AppSpacing.lg),
            Text('Upcoming deadlines', style: text.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            for (final t in _upcoming)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: TaskCard(
                  task: t,
                  assignee: _members[t.assigneeId],
                  onTap: () {
                    // TODO(D): open Task Details for this task
                  },
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.lg),
          _link(context, Icons.priority_high, 'Attention queue',
              'Most urgent tasks first', const AttentionScreen()),
          _link(context, Icons.bar_chart, 'Team workload',
              'Who is carrying what', const WorkloadScreen()),
          _link(context, Icons.history, 'Activity log',
              'Everything that changed', const ActivityScreen()),
        ],
      ),
    );
  }

  // One bar split into coloured parts, one part per SLA status.
  Widget _distributionBar(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Status distribution', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.chip),
            child: SizedBox(
              height: AppSpacing.sm,
              child: Row(children: [
                for (final s in SlaStatus.values)
                  if (_count(s) > 0)
                    Expanded(
                        flex: _count(s), child: Container(color: s.color)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _emptyState(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: Text('No tasks yet. Add your first task.',
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      );

  Widget _link(BuildContext context, IconData icon, String title, String sub,
          Widget screen) =>
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Card(
          child: ListTile(
            leading: Icon(icon, color: AppColors.primary),
            title: Text(title),
            subtitle: Text(sub),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => screen)),
          ),
        ),
      );
}