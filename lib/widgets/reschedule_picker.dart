import 'package:flutter/material.dart';

/// Shows a date picker then a time picker. Returns the combined DateTime,
/// or null if the user cancels either step.
Future<DateTime?> pickFollowUpDateTime(
  BuildContext context, {
  required DateTime initial,
}) async {
  final date = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime.now().subtract(const Duration(days: 1)),
    lastDate: DateTime.now().add(const Duration(days: 365)),
  );
  if (date == null || !context.mounted) return null;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );
  if (time == null) return null;

  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}
