import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../services/prefs_service.dart';
import '../services/sla_service.dart';
import '../utils/theme.dart';
import '../utils/validators.dart';
import '../widgets/status_chip.dart';

/// OWNER: Member A.
/// Lets the team tune when a task becomes "At risk". Values are saved in
/// SharedPreferences (PrefsService) and read by SlaService everywhere in the app.
/// The preview card uses the DRAFT numbers, so you see the effect before saving.
class SlaRulesScreen extends StatefulWidget {
  const SlaRulesScreen({super.key});

  @override
  State<SlaRulesScreen> createState() => _SlaRulesScreenState();
}

class _SlaRulesScreenState extends State<SlaRulesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _high = TextEditingController();
  final _medium = TextEditingController();
  final _low = TextEditingController();
  final _bonus = TextEditingController();

  // Preview sample task
  Priority _pPriority = Priority.medium;
  TaskStatus _pStatus = TaskStatus.inProgress;
  double _pHours = 40; // hours until deadline (negative = already late)

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fill(SlaRules.current);
  }

  @override
  void dispose() {
    _high.dispose();
    _medium.dispose();
    _low.dispose();
    _bonus.dispose();
    super.dispose();
  }

  void _fill(SlaRules r) {
    _high.text = '${r.highHours}';
    _medium.text = '${r.mediumHours}';
    _low.text = '${r.lowHours}';
    _bonus.text = '${r.notStartedBonusHours}';
  }

  int _num(TextEditingController c, int fallback) => int.tryParse(c.text.trim()) ?? fallback;

  /// The numbers currently typed in the boxes (falls back to saved values if a box is invalid).
  SlaRules get _draft {
    final cur = SlaRules.current;
    return SlaRules(
      highHours: _num(_high, cur.highHours),
      mediumHours: _num(_medium, cur.mediumHours),
      lowHours: _num(_low, cur.lowHours),
      notStartedBonusHours: _num(_bonus, cur.notStartedBonusHours),
    );
  }

  Task get _sample {
    final now = DateTime.now();
    return Task(
      title: 'Sample task',
      assigneeId: 0,
      priority: _pPriority,
      status: _pStatus,
      dueDate: now.add(Duration(hours: _pHours.round())),
      createdAt: now,
    );
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), backgroundColor: error ? AppColors.overdue : AppColors.ink));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final d = _draft;
    final orderError = Validators.slaOrder(d.highHours, d.mediumHours, d.lowHours);
    if (orderError != null) {
      _snack(orderError, error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await PrefsService.saveSlaRules(d);
      await DatabaseService.instance.logAction(
          'updated the SLA rules (High ${d.highHours} h, Medium ${d.mediumHours} h, Low ${d.lowHours} h, not-started +${d.notStartedBonusHours} h)');
      _snack('SLA rules saved. Every task is re-checked with the new windows.');
    } catch (_) {
      _snack('Could not save the rules. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _reset() async {
    setState(() => _fill(SlaRules.defaults));
    await _save();
  }

  Future<void> _reloadDemo() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reload demo data?'),
        content: const Text('This deletes all tasks and the activity log and creates seven sample tasks with fresh deadlines. Team members are kept.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reload')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await DatabaseService.instance.reseedDemoData();
      _snack('Demo data reloaded.');
    } catch (_) {
      _snack('Could not reload demo data.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final d = _draft;
    final sample = _sample;
    final status = SlaService.statusOf(sample, rules: d);

    return Scaffold(
      appBar: AppBar(title: const Text('SLA rules')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // ---- How classification works ----
          Text('How a task is classified', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _rule('1', 'Done', 'Completed'),
                _rule('2', 'Deadline has passed', 'Overdue'),
                _rule('3', 'Blocked', 'At risk'),
                _rule('4', 'Time left within the window (High ${d.highHours} h, Medium ${d.mediumHours} h, Low ${d.lowHours} h, +${d.notStartedBonusHours} h if still To do)', 'At risk'),
                _rule('5', 'Anything else', 'On track'),
              ]),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ---- Editable windows ----
          Text('At-risk windows', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Form(
            key: _formKey,
            child: Column(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _hoursField('High priority', _high, Validators.slaHours)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _hoursField('Medium priority', _medium, Validators.slaHours)),
              ]),
              const SizedBox(height: AppSpacing.sm),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _hoursField('Low priority', _low, Validators.slaHours)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _hoursField('Not started: extra', _bonus, Validators.slaBonus)),
              ]),
            ]),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save rules'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(onPressed: _saving ? null : _reset, child: const Text('Reset to defaults')),
          const SizedBox(height: AppSpacing.lg),

          // ---- Live preview ----
          Text('Live preview', style: text.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text('Try a sample task. Uses the numbers above, even before you save.', style: text.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SegmentedButton<Priority>(
                  segments: [for (final p in Priority.values) ButtonSegment(value: p, label: Text(p.label))],
                  selected: {_pPriority},
                  onSelectionChanged: (s) => setState(() => _pPriority = s.first),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<TaskStatus>(
                  initialValue: _pStatus,
                  decoration: const InputDecoration(labelText: 'Task status'),
                  items: [
                    for (final s in TaskStatus.values) DropdownMenuItem(value: s, child: Text(s.label)),
                  ],
                  onChanged: (v) => setState(() => _pStatus = v ?? _pStatus),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(_pHours >= 0 ? 'Deadline in ${_pHours.round()} hours' : 'Deadline passed ${(-_pHours).round()} hours ago'),
                Slider(
                  min: -48,
                  max: 240,
                  divisions: 288,
                  value: _pHours,
                  onChanged: (v) => setState(() => _pHours = v),
                ),
                Row(children: [
                  StatusChip(status),
                  const SizedBox(width: AppSpacing.sm),
                ]),
                const SizedBox(height: AppSpacing.sm),
                Text(SlaService.explain(sample, rules: d), style: text.bodyMedium),
              ]),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ---- Demo tools ----
          Text('Demo tools', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: ListTile(
              leading: const Icon(Icons.restart_alt, color: AppColors.primary),
              title: const Text('Reload demo data'),
              subtitle: const Text('Fresh sample tasks covering every SLA state'),
              onTap: _reloadDemo,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _hoursField(String label, TextEditingController c, String? Function(String?) validator) {
    return TextFormField(
      controller: c,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: validator,
      onChanged: (_) => setState(() {}), // refresh the live preview while typing
      decoration: InputDecoration(labelText: label, suffixText: 'hours'),
    );
  }

  Widget _rule(String n, String condition, String result) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 22, child: Text(n, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary))),
      Expanded(child: Text('$condition  ->  $result')),
    ]),
  );
}
