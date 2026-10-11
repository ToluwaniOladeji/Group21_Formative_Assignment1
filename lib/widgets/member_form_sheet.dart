import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/team_member.dart';
import '../services/database_service.dart';
import '../services/prefs_service.dart';
import '../utils/theme.dart';
import '../utils/validators.dart';
import 'member_avatar.dart';

// These are the avator colours a member can pick
const List<int> kMemberColors = [
  0xFF4338CA,
  0xFF0D9488,
  0xFFDB2777,
  0xFFEA580C,
  0xFF7C3AED,
  0xFF0284C7,
  0xFF475569,
];

// Sheet used to add a memmber or edit one, it is shared by the sign-in, team and profile screens, so the rules live in one place.
// It will then save to the SQLite and returns the saved member with its id
Future<TeamMember?> showMemberFormSheet(
  BuildContext context, {
    TeamMember? member,
    required List<TeamMember> existing,
  }
) {
  return showModalBottomSheet<TeamMember>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (_) => _MemberFormSheet(member: member, existing: existing),
  );
}

class _MemberFormSheet extends StatefulWidget {
  final TeamMember? member;
  final List<TeamMember> existing;
  const _MemberFormSheet({required this.member, required this.existing});

  @override
  State<_MemberFormSheet> createState() => _MemberFormSheet();
}

class _MemberFormSheetState extends State<_MemberFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(text: widget.member?.name ?? '');
  late final TextEditingController _role = TextEditingController(text: widget.member?.role ?? '');
  late final TextEditingController _email = TextEditingController(text: widget.member?.email ?? '');
  late int _color = widget.member?.colorValue ?? kMemberColors[widget.existing.length % kMemberColors.length];
  bool _saving = false;
  String? _saveError;
  bool get _isEdit => widget.member != null;

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    _email.dispose();
    super.dispose();
  }

  // Validation
  // Name and email reuse the shared validators.

  String? _roleValidator(String? v) {
    final basic = v?.trim() ?? '';
    if (s.isEmpty) return 'Enter a role, like a QA Tester';
    if (s.length > 40) return 'Keep the role under 40 characters.';
    return null;
  }

  String? emailValidator(String? v) {
    final basic = Validators.email(v);
    if (basic != null) return basic;
    final entered = v!.trim().toLowerCase();
    final taken = widget.existing.any((m) => m.id != widget.member?.id && m.email.toLowerCase() == entered);
    return taken ? 'Another member already uses this email. Please use a different email.' : null;
  }

  // Saving
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final db = DatabaseService.instance;
    try {
      final draft = TeamMember(
        id: widget.member?.id,
        name: _name.text.trim(),
        role: _role.text.trim(),
        email: _email.text.trim(),
        colorValue: _color,
      );
      final TeamMember saved;
      if (_isEdit) {
        await db.updateMember(draft);
        saved = draft;
      } else {
        final id = await db.insertMember(draft);
        saved = TeamMember(id: id, name: draft.name, role: draft.role, email: draft.email, colorValue: draft.colorValue);
      }
      await _logActivity(saved);
      if (!mounted) return;
      Navigator.pop(context, saved);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = 'Could not save this member. Please try again.';
      });
    }
  }

  // Log activity will add a line to the acitivty log when someone is signed in
  Future<void> _logActivity(TeamMember saved) async {
    final actorId = PrefsService.currentUserId;
    if (actorId == null) return; // adding a member from the sign-in screen
    try {
      final db = DatabaseService.instance;
      final actor = await db.getMember(actorId);
      final who = actor?.name.split(' ').first ?? 'Someone';
      final message = !_isEdit
          ? '$who added ${saved.name} to the team'
          : actorId == saved.id
              ? '$who updated their profile'
              : "$who updated ${saved.name}'s details";
      await db.logActivity(actorId, message);
    } catch (_) {}
  }

  // UI
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      // Keeps the form above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              // Live preview: the initials update as the name is typed.
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _name,
                builder: (_, value, __) {
                  final shown = value.text.trim().isEmpty ? '?' : value.text;
                  return MemberAvatar(TeamMember(name: shown, role: '', email: '', colorValue: _color), radius: 24);
                },
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(_isEdit ? 'Edit member' : 'Add member', style: text.titleLarge)),
            ]),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              inputFormatters: [LengthLimitingTextInputFormatter(40)],
              decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline)),
              validator: Validators.name,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _role,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Role', prefixIcon: Icon(Icons.work_outline)),
              validator: _roleValidator,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
              validator: _emailValidator,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Avatar colour', style: text.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [
              for (var i = 0; i < kMemberColors.length; i++)
                _ColourDot(
                  colorValue: kMemberColors[i],
                  label: 'Avatar colour ${i + 1}',
                  selected: kMemberColors[i] == _color,
                  onTap: () => setState(() => _color = kMemberColors[i]),
                ),
            ]),
            if (_saveError != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_saveError!, style: text.bodySmall?.copyWith(color: AppColors.overdue)),
            ],
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isEdit ? 'Save changes' : 'Add member'),
            ),
          ]),
        ),
      ),
    );
  }
}

// The Colour circle class for the avatar
class _ColourDot extends StatelessWidget {
  final int colorValue;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ColourDot({required this.colorValue, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Color(colorValue),
                shape: BoxShape.circle,
                border: selected ? Border.all(color: AppColors.ink, width: 3) : null,
              ),
              child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
            ),
          ),
        ),
      ),
    );
  }
}