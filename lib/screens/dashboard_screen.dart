import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/followup.dart';
import '../providers/tracker_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/add_followup_sheet.dart';
import '../widgets/followup_card.dart';
import '../widgets/reschedule_picker.dart';
import 'followup_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tracker = context.watch<TrackerProvider>();
    final upcoming = tracker.upcomingFollowUps;

    final grouped = <String, List<FollowUp>>{};
    for (final f in upcoming) {
      final key = DateFormat('dd MMM yyyy').format(f.scheduledAt);
      grouped.putIfAbsent(key, () => []).add(f);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Follow-ups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => showAddFollowUpSheet(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddFollowUpSheet(context),
        label: const Text('Add follow-up'),
        icon: const Icon(Icons.add),
      ),
      body: tracker.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: tracker.load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                children: [
                  _StatsRow(tracker: tracker),
                  const SizedBox(height: 18),
                  if (grouped.isEmpty)
                    const _EmptyState()
                  else
                    for (final entry in grouped.entries) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, top: 6),
                        child: Text(
                          entry.key.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.amberDeep,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      for (final f in entry.value)
                        FollowUpCard(
                          followUp: f,
                          customer: tracker.customerFor(f),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  FollowUpDetailScreen(followUpId: f.id),
                            ),
                          ),
                          onCall: () => _call(tracker.customerFor(f).phone),
                          onSnooze: () => _snooze(context, f),
                          onComplete: () =>
                              tracker.markCompleted(f.id, completed: true),
                        ),
                    ],
                ],
              ),
            ),
    );
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _snooze(BuildContext context, FollowUp f) async {
    final newDate =
        await pickFollowUpDateTime(context, initial: f.scheduledAt);
    if (newDate == null || !context.mounted) return;
    await context.read<TrackerProvider>().rescheduleFollowUp(f.id, newDate);
  }
}

class _StatsRow extends StatelessWidget {
  final TrackerProvider tracker;
  const _StatsRow({required this.tracker});

  @override
  Widget build(BuildContext context) {
    final pending = NumberFormat.currency(
            locale: 'en_IN', symbol: '\u20b9', decimalDigits: 0)
        .format(tracker.totalPending);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          _stat('Pending', pending, AppColors.amberDeep),
          _divider(),
          _stat('Today', '${tracker.todayCount}', AppColors.tealDeep),
          _divider(),
          _stat('Overdue', '${tracker.overdueCount}', AppColors.coralDeep),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 34, color: AppColors.line);

  Widget _stat(String label, String value, Color color) => Expanded(
        child: Column(
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 11, color: AppColors.muted)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: const [
          Icon(Icons.event_available_outlined,
              size: 40, color: AppColors.line),
          SizedBox(height: 14),
          Text('No follow-ups yet',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          SizedBox(height: 6),
          Text('Add your first follow-up to start tracking calls.',
              style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
        ],
      ),
    );
  }
}
