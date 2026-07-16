import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/tracker_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/add_customer_sheet.dart';
import '../widgets/add_followup_sheet.dart';
import '../widgets/followup_card.dart';
import '../widgets/reschedule_picker.dart';
import 'followup_detail_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  Widget build(BuildContext context) {
    final tracker = context.watch<TrackerProvider>();
    final customer =
        tracker.customers.firstWhere((c) => c.id == widget.customerId);
    final pending = tracker.followUpsFor(customer.id, completed: false);
    final completed = tracker.followUpsFor(customer.id, completed: true);
    final totalPending = pending.fold(0.0, (s, f) => s + f.pendingAmount);

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined),
            onPressed: () async {
              final uri = Uri(scheme: 'tel', path: customer.phone);
              if (await canLaunchUrl(uri)) await launchUrl(uri);
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showAddCustomerSheet(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            showAddFollowUpSheet(context, preselected: customer),
        label: const Text('Add follow-up'),
        icon: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                children: [
                  _row('Phone', customer.phone),
                  _row(
                      'Total pending',
                      NumberFormat.currency(
                              locale: 'en_IN',
                              symbol: '\u20b9',
                              decimalDigits: 0)
                          .format(totalPending),
                      valueColor: AppColors.amberDeep),
                  if (customer.address != null)
                    _row('Address', customer.address!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          TabBar(
            controller: _tab,
            labelColor: AppColors.ink,
            unselectedLabelColor: AppColors.muted,
            indicatorColor: AppColors.amber,
            tabs: [
              Tab(text: 'Pending (${pending.length})'),
              Tab(text: 'Completed (${completed.length})'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _list(pending, customer),
                _list(completed, customer),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v, {Color? valueColor}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            Text(v,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    color: valueColor)),
          ],
        ),
      );

  Widget _list(List followUps, customer) {
    if (followUps.isEmpty) {
      return const Center(
          child: Text('Nothing here yet',
              style: TextStyle(color: AppColors.muted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: followUps.length,
      itemBuilder: (_, i) {
        final f = followUps[i];
        return FollowUpCard(
          followUp: f,
          customer: customer,
          showCustomerName: false,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => FollowUpDetailScreen(followUpId: f.id)),
          ),
          onCall: () async {
            final uri = Uri(scheme: 'tel', path: customer.phone);
            if (await canLaunchUrl(uri)) await launchUrl(uri);
          },
          onSnooze: () => _pickAndReschedule(f.id, f.scheduledAt),
          onComplete: () =>
              context.read<TrackerProvider>().markCompleted(f.id),
        );
      },
    );
  }

  Future<void> _pickAndReschedule(String id, DateTime current) async {
    final newDate = await pickFollowUpDateTime(context, initial: current);
    if (newDate == null || !mounted) return;
    await context.read<TrackerProvider>().rescheduleFollowUp(id, newDate);
  }
}
