import 'package:flutter/material.dart';
import '../widgets/placeholder_screen.dart';

class SlaRulesScreen extends StatelessWidget {
  const SlaRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(title: 'SLA rules', owner: 'Member A', todo: ['Sliders/steppers for High, Medium, Low windows and the not-started bonus (hours)', 'Save via PrefsService.saveSlaRules (SharedPreferences), Reset to defaults button', 'Live preview: show how a sample task would be classified with the new numbers', 'Plain-language summary of the 5 rules in SlaService (rehearse this for the demo)', ]);
  }
}
