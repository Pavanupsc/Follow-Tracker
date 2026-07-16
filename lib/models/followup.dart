import '../theme/app_theme.dart';

class RescheduleEntry {
  final DateTime from;
  final DateTime to;
  final DateTime changedAt;

  RescheduleEntry({required this.from, required this.to, required this.changedAt});

  Map<String, dynamic> toMap() => {
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
        'changed_at': changedAt.toIso8601String(),
      };

  factory RescheduleEntry.fromMap(Map<String, dynamic> m) => RescheduleEntry(
        from: DateTime.parse(m['from'] as String),
        to: DateTime.parse(m['to'] as String),
        changedAt: DateTime.parse(m['changed_at'] as String),
      );

  /// Hydrates from a `reschedule_history` table row, whose column names
  /// (`from_date` / `to_date`) differ slightly from [toMap]'s shape.
  factory RescheduleEntry.fromRow(Map<String, Object?> row) => RescheduleEntry(
        from: DateTime.parse(row['from_date'] as String),
        to: DateTime.parse(row['to_date'] as String),
        changedAt: DateTime.parse(row['changed_at'] as String),
      );
}

class FollowUp {
  final String id;
  final String customerId;
  DateTime scheduledAt;
  final DateTime originalDate;
  bool completed;
  double pendingAmount;
  double paidAmount;
  String? notes;
  final List<RescheduleEntry> history;
  final String lastModifiedFrom;

  FollowUp({
    required this.id,
    required this.customerId,
    required this.scheduledAt,
    required this.originalDate,
    this.completed = false,
    required this.pendingAmount,
    this.paidAmount = 0,
    this.notes,
    List<RescheduleEntry>? history,
    this.lastModifiedFrom = 'This device',
  }) : history = history ?? [];

  FollowUpStatus get status {
    if (completed) return FollowUpStatus.completed;
    if (scheduledAt.isBefore(DateTime.now())) return FollowUpStatus.overdue;
    return FollowUpStatus.pending;
  }

  void reschedule(DateTime newDate) {
    history.add(RescheduleEntry(
      from: scheduledAt,
      to: newDate,
      changedAt: DateTime.now(),
    ));
    scheduledAt = newDate;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'customer_id': customerId,
        'scheduled_at': scheduledAt.toIso8601String(),
        'original_date': originalDate.toIso8601String(),
        'completed': completed ? 1 : 0,
        'pending_amount': pendingAmount,
        'paid_amount': paidAmount,
        'notes': notes,
        'last_modified_from': lastModifiedFrom,
      };

  factory FollowUp.fromMap(Map<String, dynamic> m) => FollowUp(
        id: m['id'] as String,
        customerId: m['customer_id'] as String,
        scheduledAt: DateTime.parse(m['scheduled_at'] as String),
        originalDate: DateTime.parse(m['original_date'] as String),
        completed: (m['completed'] as int) == 1,
        pendingAmount: (m['pending_amount'] as num).toDouble(),
        paidAmount: (m['paid_amount'] as num).toDouble(),
        notes: m['notes'] as String?,
        lastModifiedFrom: m['last_modified_from'] as String? ?? 'This device',
      );
}

