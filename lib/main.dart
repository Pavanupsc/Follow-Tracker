import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/tracker_provider.dart';
import 'screens/root_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const FollowUpTrackerApp());
}

class FollowUpTrackerApp extends StatelessWidget {
  const FollowUpTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TrackerProvider()..load(),
      child: MaterialApp(
        title: 'Follow-up Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const RootShell(),
      ),
    );
  }
}
