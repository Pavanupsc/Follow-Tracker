import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../db/database_helper.dart';
import '../models/customer.dart';
import '../models/followup.dart';
import '../theme/app_theme.dart';

const _uuid = Uuid();

class TrackerProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;

  List<Customer> _customers = [];
  List<FollowUp> _followUps = [];
  bool _loading = true;

  List<Customer> get customers => List.unmodifiable(_customers);
  List<FollowUp> get followUps => List.unmodifiable(_followUps);
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _customers = await _db.getCustomers();
    _followUps = await _db.getAllFollowUps();
    _loading = false;
    notifyListeners();
  }

  // ---------- Derived views ----------

  double get totalPending => _followUps
      .where((f) => !f.completed)
      .fold(0.0, (sum, f) => sum + f.pendingAmount);

  int get todayCount {
    final now = DateTime.now();
    return _followUps
        .where((f) =>
            !f.completed &&
            f.scheduledAt.year == now.year &&
            f.scheduledAt.month == now.month &&
            f.scheduledAt.day == now.day)
        .length;
  }

  int get overdueCount =>
      _followUps.where((f) => f.status == FollowUpStatus.overdue).length;

  List<FollowUp> get upcomingFollowUps {
    final list = _followUps.where((f) => !f.completed).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return list;
  }

  Customer customerFor(FollowUp f) =>
      _customers.firstWhere((c) => c.id == f.customerId);

  List<FollowUp> followUpsFor(String customerId, {required bool completed}) =>
      _followUps
          .where((f) => f.customerId == customerId && f.completed == completed)
          .toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  List<Customer> searchCustomers(String query) {
    if (query.trim().isEmpty) return customers;
    final q = query.toLowerCase();
    return _customers
        .where((c) =>
            c.name.toLowerCase().contains(q) || c.phone.contains(q))
        .toList();
  }

  // ---------- Mutations ----------

  Future<Customer> addCustomer(
      {required String name, required String phone, String? address}) async {
    final c = Customer(
      id: _uuid.v4(),
      name: name.trim(),
      phone: phone.trim(),
      address: (address == null || address.trim().isEmpty)
          ? null
          : address.trim(),
      createdAt: DateTime.now(),
    );
    await _db.insertCustomer(c);
    _customers.add(c);
    notifyListeners();
    return c;
  }

  Future<void> updateCustomer(Customer c) async {
    await _db.updateCustomer(c);
    final i = _customers.indexWhere((x) => x.id == c.id);
    if (i != -1) _customers[i] = c;
    notifyListeners();
  }

  Future<void> deleteCustomer(String id) async {
    await _db.deleteCustomer(id);
    _customers.removeWhere((c) => c.id == id);
    _followUps.removeWhere((f) => f.customerId == id);
    notifyListeners();
  }

  Future<FollowUp> addFollowUp({
    required String customerId,
    required DateTime scheduledAt,
    required double pendingAmount,
    String? notes,
  }) async {
    final f = FollowUp(
      id: _uuid.v4(),
      customerId: customerId,
      scheduledAt: scheduledAt,
      originalDate: scheduledAt,
      pendingAmount: pendingAmount,
      notes: notes,
    );
    await _db.insertFollowUp(f);
    _followUps.add(f);
    notifyListeners();
    return f;
  }

  Future<void> rescheduleFollowUp(String id, DateTime newDate) async {
    final f = _followUps.firstWhere((x) => x.id == id);
    f.reschedule(newDate);
    await _db.updateFollowUp(f);
    notifyListeners();
  }

  Future<void> updateAmounts(String id,
      {required double pendingAmount, required double paidAmount}) async {
    final f = _followUps.firstWhere((x) => x.id == id);
    f.pendingAmount = pendingAmount;
    f.paidAmount = paidAmount;
    await _db.updateFollowUp(f);
    notifyListeners();
  }

  Future<void> updateNotes(String id, String notes) async {
    final f = _followUps.firstWhere((x) => x.id == id);
    f.notes = notes;
    await _db.updateFollowUp(f);
    notifyListeners();
  }

  Future<void> markCompleted(String id, {bool completed = true}) async {
    final f = _followUps.firstWhere((x) => x.id == id);
    f.completed = completed;
    await _db.updateFollowUp(f);
    notifyListeners();
  }

  Future<void> deleteFollowUp(String id) async {
    await _db.deleteFollowUp(id);
    _followUps.removeWhere((f) => f.id == id);
    notifyListeners();
  }
}
