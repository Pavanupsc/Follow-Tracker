import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/customer.dart';
import '../providers/tracker_provider.dart';
import '../theme/app_theme.dart';
import 'add_customer_sheet.dart';

Future<void> showAddFollowUpSheet(BuildContext context,
    {Customer? preselected}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => AddFollowUpSheet(preselected: preselected),
  );
}

class AddFollowUpSheet extends StatefulWidget {
  final Customer? preselected;
  const AddFollowUpSheet({super.key, this.preselected});

  @override
  State<AddFollowUpSheet> createState() => _AddFollowUpSheetState();
}

class _AddFollowUpSheetState extends State<AddFollowUpSheet> {
  Customer? _customer;
  DateTime _dateTime = DateTime.now().add(const Duration(days: 1));
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _customer = widget.preselected;
  }

  @override
  Widget build(BuildContext context) {
    final tracker = context.watch<TrackerProvider>();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const Text('New follow-up',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _label('Customer'),
          if (widget.preselected == null)
            InkWell(
              onTap: () => _pickCustomer(context, tracker.customers),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _customer?.name ?? 'Search or add customer',
                  style: TextStyle(
                    color: _customer == null
                        ? AppColors.muted
                        : AppColors.ink,
                  ),
                ),
              ),
            )
          else
            Text(widget.preselected!.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          _label('Follow-up date and time'),
          InkWell(
            onTap: _pickDateTime,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(_dateTime)),
            ),
          ),
          const SizedBox(height: 14),
          _label('Pending amount'),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(prefixText: '\u20b9 '),
          ),
          const SizedBox(height: 14),
          _label('Notes'),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration:
                const InputDecoration(hintText: 'Add a remark for this call'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('Save follow-up'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.muted)),
      );

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (time == null) return;
    setState(() {
      _dateTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickCustomer(
      BuildContext context, List<Customer> customers) async {
    final chosen = await showModalBottomSheet<Customer>(
      context: context,
      backgroundColor: AppColors.paper,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _CustomerPicker(customers: customers),
    );
    if (chosen != null) setState(() => _customer = chosen);
  }

  Future<void> _save() async {
    final tracker = context.read<TrackerProvider>();
    final customer = widget.preselected ?? _customer;
    if (customer == null) return;
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    await tracker.addFollowUp(
      customerId: customer.id,
      scheduledAt: _dateTime,
      pendingAmount: amount,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    if (mounted) Navigator.of(context).pop();
  }
}

class _CustomerPicker extends StatefulWidget {
  final List<Customer> customers;
  const _CustomerPicker({required this.customers});

  @override
  State<_CustomerPicker> createState() => _CustomerPickerState();
}

class _CustomerPickerState extends State<_CustomerPicker> {
  String _query = '';

  bool get _queryLooksLikePhone {
    final digits = _query.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 6;
  }

  List<Customer> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.customers;
    final digits = q.replaceAll(RegExp(r'\D'), '');
    return widget.customers.where((c) {
      final nameMatch = c.name.toLowerCase().contains(q);
      final phoneMatch = c.phone.toLowerCase().contains(q) ||
          (digits.isNotEmpty &&
              c.phone.replaceAll(RegExp(r'\D'), '').contains(digits));
      return nameMatch || phoneMatch;
    }).toList();
  }

  Future<void> _addCustomer() async {
    final initialPhone = _queryLooksLikePhone
        ? _query.replaceAll(RegExp(r'\D'), '')
        : null;
    final initialName =
        (!_queryLooksLikePhone && _query.trim().isNotEmpty) ? _query.trim() : null;

    final created = await showAddCustomerSheet(
      context,
      initialPhone: initialPhone,
      initialName: initialName,
    );
    if (!mounted) return;
    if (created != null) {
      Navigator.pop(context, created);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SizedBox(
        height: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select customer',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              autofocus: true,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                hintText: 'Search by name or phone',
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _addCustomer,
              icon: const Icon(Icons.add, size: 18),
              label: Text(_queryLooksLikePhone
                  ? 'Add customer with this number'
                  : 'Add a new customer instead'),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _query.trim().isEmpty
                                ? 'No customers yet'
                                : 'No customer found',
                            style: const TextStyle(color: AppColors.muted),
                          ),
                          if (_query.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _addCustomer,
                              child: Text(_queryLooksLikePhone
                                  ? 'Add ${_query.replaceAll(RegExp(r'\D'), '')}'
                                  : 'Add "$_query" as new customer'),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final c = filtered[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.softFill,
                            foregroundColor: AppColors.ink,
                            child: Text(c.initials,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                          ),
                          title: Text(c.name),
                          subtitle: Text(c.phone),
                          onTap: () => Navigator.pop(context, c),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
