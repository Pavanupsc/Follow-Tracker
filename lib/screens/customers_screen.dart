import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/customer.dart';
import '../providers/tracker_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/add_customer_sheet.dart';
import 'customer_detail_screen.dart';

enum _Filter { all, pending, cleared }

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _query = '';
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final tracker = context.watch<TrackerProvider>();
    var customers = tracker.searchCustomers(_query);

    double pendingFor(Customer c) => tracker
        .followUpsFor(c.id, completed: false)
        .fold(0.0, (s, f) => s + f.pendingAmount);

    if (_filter == _Filter.pending) {
      customers = customers.where((c) => pendingFor(c) > 0).toList();
    } else if (_filter == _Filter.cleared) {
      customers = customers.where((c) => pendingFor(c) == 0).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: () => showAddCustomerSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name or phone',
                prefixIcon: Icon(Icons.search, size: 20),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _chip('All', _Filter.all),
                const SizedBox(width: 8),
                _chip('Pending', _Filter.pending),
                const SizedBox(width: 8),
                _chip('Cleared', _Filter.cleared),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: customers.isEmpty
                ? const Center(
                    child: Text('No customers found',
                        style: TextStyle(color: AppColors.muted)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: customers.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.line),
                    itemBuilder: (_, i) {
                      final c = customers[i];
                      final pending = pendingFor(c);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.softFill,
                          foregroundColor: AppColors.ink,
                          child: Text(c.initials,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        title: Text(c.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(c.phone,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.muted)),
                        trailing: pending > 0
                            ? Text(
                                NumberFormat.currency(
                                        locale: 'en_IN',
                                        symbol: '\u20b9',
                                        decimalDigits: 0)
                                    .format(pending),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13),
                              )
                            : const Text('Cleared',
                                style: TextStyle(
                                    color: AppColors.tealDeep,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5)),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                CustomerDetailScreen(customerId: c.id),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, _Filter value) {
    final on = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: on,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: AppColors.ink,
      backgroundColor: AppColors.card,
      side: const BorderSide(color: AppColors.line),
      labelStyle: TextStyle(
        color: on ? AppColors.paper : AppColors.muted,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
