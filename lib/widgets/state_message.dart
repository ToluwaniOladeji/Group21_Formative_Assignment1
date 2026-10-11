import 'package:flutter/material.dart';
import '../utils/theme.dart';

// The state message widget has been used to display messages to the user(mostly the success and error messages).
// It is stateless because it doesn't need to manage any state, it will just show the message and be used in the stateful widget.
class StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  const StateMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onActionPressed,
  });

  // ... your existing build method stays exactly as it is

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: text.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text(message, style: text.bodySmall, textAlign: TextAlign.center),

            if (actionLabel !=null && onActionPressed != null) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: 220,
                child: ElevatedButton(
                  onPressed: onActionPressed,
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        )
      )
    );
  }
}