import 'package:flutter/material.dart';
import '../models/team_member.dart';
import '../services/database_service.dart';
import '../services/prefs_service.dart';
import '../utils/theme.dart';
import '../utils/snackbars.dart';
import '../utils/validators.dart';
import '../widgets/member_avatar.dart';
import '../widgets/member_form_sheet.dart';
import '../widgets/state_message.dart';
import 'app_shell.dart';

// the chosen member id is saved in SharedPreferences and restored on the next launch.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }
  void _goToApp() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AppShell()));
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final members = await DatabaseService.instance.getMembers();
      final entered = _email.text.trim().toLowerCase();
      TeamMember? match;

      for (final member in members) {
        if (member.email.trim().toLowerCase() == entered) {
          match = member;
          break;
        }
      }
      if (match == null) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _error = 'No member uses this email. Check the spelling, or join the team below.';
        });
        return;
      }
      await PrefsService.setCurrentUser(match.id!);
      if (!mounted) return;
      _goToApp();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not sign in. Please try again.';
      });
    }
  }

  Future<void> _join() async {
    setState(() => _busy = true);
    try {
      final members = await DatabaseService.instance.getMembers();
      if (!mounted) return;
      final saved = await showMemberFormSheet(context, existing: members);
      if (saved == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      await PrefsService.setCurrentUser(saved.id!);
      if (!mounted) return;
      _goToApp();
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppSnack.show(context, 'Could not add a team member. Please try again.',
          error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  // Brand block
                  Row(children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.input)),
                      child: const Icon(Icons.sensors, color: Colors.white),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text('Beacon', style: text.headlineMedium),
                  ]),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Know which tasks need you before they slip.', style: text.bodyMedium),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Welcome back', style: text.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Sign in with your team email.', style: text.bodySmall),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (!_busy) {_signIn();}
                    },
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                    decoration: const InputDecoration(labelText: 'Email', hintText: 'name@team.com', prefixIcon: Icon(Icons.mail_outline)),
                    validator: Validators.email,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(_error!, style: text.bodySmall?.copyWith(color: AppColors.overdue)),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: _busy ? null : _signIn,
                    child: _busy
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Sign in'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Text('New to Beacon?', style: text.bodySmall),
                    ),
                    const Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: AppSpacing.lg),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _join,
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Join the team'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}