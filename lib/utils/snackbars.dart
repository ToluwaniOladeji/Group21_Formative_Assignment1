import 'package:flutter/material.dart';
import 'theme.dart';

// The snackbar widget has been applied to display messages to the user(mostly the success and error messages).
// If another snackbar is showing, it will be hidden and then the new will be showing.
class AppSnack {
  static void show(BuildContext context, String message, {bool error = false,}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar (
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? AppColors.overdue : AppColors.ink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.input,),
        ),),);
  }
}