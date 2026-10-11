import 'package:flutter/material.dart';
import '../widgets/placeholder_screen.dart';
import '../models/sla_status.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import '../services/database_service.dart';
import '../services/sla_service.dart';
import '../utils/theme.dart';
import '../widgets/member_avatar.dart';
import '../widgets/state_message.dart';
import 'member_tasks_screen.dart';

class WorkloadScreen extends StatefulWidget {
  const WorkloadScreen({super.key});

  @override
  State<WorkloadScreen> createState() => _WorkloadScreenState();
}

class _WorkloadScreenState extends State<WorkloadScreen> {
  List<TeamMember> _members = [];
  List<Task> _tasks = [];

  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final db = DatabaseService.instance;

      final members = await db.getMembers();
      final tasks = await db.getTasks();

      if (!mounted) return;

      setState(() {
        _members = members;
        _tasks = tasks;
        _loading = false;
        _failed = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  List<Task> _tasksFor(TeamMember member) {
    return _tasks
        .where((task) => task.assigneeId == member.id)
        .toList();
  }

  Future<void> _openMember(TeamMember member) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MemberTasksScreen(
          member: member,
        ),
      ),
    );

    if (mounted) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team workload'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _failed
              ? StateMessage(
                  icon: Icons.error_outline,
                  title: 'Could not load workload',
                  message:'Something went wrong while reading team workload data.',
                  actionLabel: 'Try again',
                  onActionPressed: () {
                    setState(() {
                      _loading = true;
                    });

                    _load();
                  },
                )
              : _members.isEmpty
                  ? const StateMessage(
                      icon: Icons.groups_outlined,
                      title: 'No team members yet',
                      message: 'Add team members before viewing workload.',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xl,
                        ),
                        children: [
                          Text('Workload overview', style: text.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.xs,
                          ),
                          Text('See how open work is distributed and who may need support.', style: text.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.lg,
                          ),

                          // Explain what the four bar colours mean.
                          const _WorkloadLegend(),

                          const SizedBox(height: AppSpacing.lg,
                          ),

                          // Build one workload card for each member.
                          for (var i = 0;
                              i < _members.length;
                              i++) ...[
                            _MemberWorkloadCard(
                              member: _members[i],
                              tasks: _tasksFor(_members[i]),
                              onTap: () =>
                                  _openMember(_members[i]),
                            ),
                            if (i != _members.length - 1)
                              const SizedBox(
                                height: AppSpacing.sm,
                              ),
                          ],
                        ],
                      ),
                    ),
    );
  }
}

class _MemberWorkloadCard extends StatelessWidget {
  final TeamMember member;
  final List<Task> tasks;
  final VoidCallback onTap;

  const _MemberWorkloadCard({
    required this.member,
    required this.tasks,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    // Use the central SLA service rather than recreating
    // SLA rules inside this screen.
    final counts = SlaService.counts(tasks);
    final onTrack = counts[SlaStatus.onTrack] ?? 0;
    final atRisk = counts[SlaStatus.atRisk] ?? 0;
    final overdue = counts[SlaStatus.overdue] ?? 0;
    final completed = counts[SlaStatus.completed] ?? 0;
    final openTasks = onTrack + atRisk + overdue;
    final overloaded = openTasks >= 4;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          AppRadius.card,
        ),
        child: Padding(
          padding: const EdgeInsets.all(
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  MemberAvatar(
                    member,
                    radius: 22,
                  ),

                  const SizedBox(
                    width: AppSpacing.md,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: text.titleMedium,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                        ),
                        Text(
                          member.role,
                          style: text.bodySmall,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  if (overloaded)
                    const Chip(
                      avatar: Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                      ),
                      label: Text(
                        'Overloaded',
                      ),
                    ),

                  const Icon(
                    Icons.chevron_right,
                  ),
                ],
              ),

              const SizedBox(
                height: AppSpacing.md,
              ),

              Text(
                '$openTasks open task${openTasks == 1 ? '' : 's'}'
                '  •  $atRisk at risk'
                '  •  $overdue overdue',
                style: text.bodySmall,
              ),

              const SizedBox(
                height: AppSpacing.sm,
              ),

              _StackedWorkloadBar(
                onTrack: onTrack,
                atRisk: atRisk,
                overdue: overdue,
                completed: completed,
              ),

              const SizedBox(
                height: AppSpacing.sm,
              ),

              Text(
                '$completed completed',
                style: text.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StackedWorkloadBar extends StatelessWidget {
  final int onTrack;
  final int atRisk;
  final int overdue;
  final int completed;

  const _StackedWorkloadBar({
    required this.onTrack,
    required this.atRisk,
    required this.overdue,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final total = onTrack + atRisk + overdue + completed;

    // A member with no tasks still gets an empty bar
    if (total == 0) {
      return Container(
        height: 14,
        decoration: BoxDecoration(
          color: AppColors.completed,
          borderRadius: BorderRadius.circular(
            AppRadius.input,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(
        AppRadius.input,
      ),
      child: SizedBox(
        height: 14,
        child: Row(
          children: [
            if (onTrack > 0)
              Expanded(
                flex: onTrack,
                child: Container(
                  color: AppColors.onTrack,
                ),
              ),

            if (atRisk > 0)
              Expanded(
                flex: atRisk,
                child: Container(
                  color: AppColors.atRisk,
                ),
              ),

            if (overdue > 0)
              Expanded(
                flex: overdue,
                child: Container(
                  color: AppColors.overdue,
                ),
              ),

            if (completed > 0)
              Expanded(
                flex: completed,
                child: Container(
                  color: AppColors.completed,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WorkloadLegend extends StatelessWidget {
  const _WorkloadLegend();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        _LegendItem(
          color: AppColors.onTrack,
          label: 'On track',
        ),
        _LegendItem(
          color: AppColors.atRisk,
          label: 'At risk',
        ),
        _LegendItem(
          color: AppColors.overdue,
          label: 'Overdue',
        ),
        _LegendItem(
          color: AppColors.completed,
          label: 'Completed',
        ),
      ],
    );
  }
}

/// One item in the workload colour legend.
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(
          width: AppSpacing.xs,
        ),
        Text(
          label,
          style: text.bodySmall,
        ),
      ],
    );
  }
}