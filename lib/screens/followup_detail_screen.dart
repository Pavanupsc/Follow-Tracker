import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/tracker_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/reschedule_picker.dart';

class FollowUpDetailScreen extends StatelessWidget {
  final String followUpId;
  const FollowUpDetailScreen({super.key, required this.followUpId});

  @override
  Widget build(BuildContext context) {
    final tracker = context.watch<TrackerProvider>();
    final f = tracker.followUps.firstWhere((x) => x.id == followUpId);
    final customer = tracker.customerFor(f);
    final dateFmt = DateFormat('dd MMM yyyy, hh:mm a');
    final money = NumberFormat.currency(
        locale: 'en_IN', symbol: '\u20b9', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Follow-up details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_repeat_outlined),
            onPressed: () => _reschedule(context, f.id, f.scheduledAt),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.coralDeep),
            onPressed: () async {
              await context.read<TrackerProvider>().deleteFollowUp(f.id);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          _Card(
            title: 'Appointment',
            child: Column(
              children: [
                _row('Scheduled', dateFmt.format(f.scheduledAt)),
                _row('Originally set', dateFmt.format(f.originalDate)),
                _row('Customer', customer.name),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Status',
                          style: TextStyle(
                              color: AppColors.muted, fontSize: 13)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: f.status.bg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(f.status.label,
                            style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: f.status.fg)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            title: 'Amount',
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: () => _editAmounts(context, f.id, f.pendingAmount, f.paidAmount),
            ),
            child: Column(
              children: [
                _row('Pending', money.format(f.pendingAmount),
                    valueColor: AppColors.amberDeep),
                _row('Paid so far', money.format(f.paidAmount),
                    valueColor: AppColors.tealDeep),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            title: 'Notes',
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: () => _editNotes(context, f.id, f.notes ?? ''),
            ),
            child: Text(
              (f.notes == null || f.notes!.isEmpty)
                  ? 'No notes added yet.'
                  : f.notes!,
              style: const TextStyle(fontSize: 13.5),
            ),
          ),
          if (f.history.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Card(
              title: 'Reschedule history (${f.history.length})',
              child: Column(
                children: [
                  for (var i = 0; i < f.history.length; i++)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.softFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('#${i + 1}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: AppColors.muted)),
                              Text(
                                  DateFormat('dd MMM yyyy, hh:mm a')
                                      .format(f.history[i].changedAt),
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.muted)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(DateFormat('dd MMM').format(f.history[i].from),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(Icons.arrow_forward,
                                    size: 14, color: AppColors.amberDeep),
                              ),
                              Text(DateFormat('dd MMM').format(f.history[i].to),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  f.completed ? AppColors.muted : AppColors.teal,
            ),
            onPressed: () => context
                .read<TrackerProvider>()
                .markCompleted(f.id, completed: !f.completed),
            icon: Icon(f.completed ? Icons.undo : Icons.check),
            label: Text(f.completed ? 'Reopen follow-up' : 'Mark as done'),
          ),
        ),
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

  Future<void> _reschedule(
      BuildContext context, String id, DateTime current) async {
    final newDate = await pickFollowUpDateTime(context, initial: current);
    if (newDate == null || !context.mounted) return;
    await context.read<TrackerProvider>().rescheduleFollowUp(id, newDate);
  }

  Future<void> _editAmounts(
      BuildContext context, String id, double pending, double paid) async {
    final pendingCtrl = TextEditingController(text: pending.toStringAsFixed(0));
    final paidCtrl = TextEditingController(text: paid.toStringAsFixed(0));
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit amount'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pendingCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Pending amount'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: paidCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Paid amount'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await context.read<TrackerProvider>().updateAmounts(
                    id,
                    pendingAmount: double.tryParse(pendingCtrl.text) ?? pending,
                    paidAmount: double.tryParse(paidCtrl.text) ?? paid,
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _editNotes(
      BuildContext context, String id, String current) async {
    final ctrl = TextEditingController(text: current);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit notes'),
        content: TextField(controller: ctrl, maxLines: 4),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await context.read<TrackerProvider>().updateNotes(id, ctrl.text);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const _Card({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                      letterSpacing: 0.4)),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
