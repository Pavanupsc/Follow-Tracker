import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/customer.dart';
import '../models/followup.dart';
import '../theme/app_theme.dart';

class FollowUpCard extends StatelessWidget {
  final FollowUp followUp;
  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback? onCall;
  final VoidCallback? onSnooze;
  final VoidCallback? onComplete;
  final bool showCustomerName;

  const FollowUpCard({
    super.key,
    required this.followUp,
    required this.customer,
    required this.onTap,
    this.onCall,
    this.onSnooze,
    this.onComplete,
    this.showCustomerName = true,
  });

  @override
  Widget build(BuildContext context) {
    final amount = NumberFormat.currency(
            locale: 'en_IN', symbol: '\u20b9', decimalDigits: 0)
        .format(followUp.pendingAmount);
    final time = DateFormat('hh:mm a').format(followUp.scheduledAt);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showCustomerName)
                    Text(customer.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14.5)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(time,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.muted)),
                      const Text('  \u00b7  ',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.muted)),
                      Container(
                        padding: const EdgeInsets.only(bottom: 2),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: AppColors.amber, width: 2),
                          ),
                        ),
                        child: Text(amount,
                            style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!followUp.completed) ...[
              _pill(Icons.call_rounded, AppColors.tealBg, AppColors.tealDeep,
                  onCall),
              const SizedBox(width: 6),
              _pill(Icons.update_rounded, AppColors.violetBg,
                  AppColors.violet, onSnooze),
              const SizedBox(width: 6),
              _pill(Icons.check_rounded, AppColors.teal, Colors.white,
                  onComplete),
            ] else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: FollowUpStatus.completed.bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Completed',
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: FollowUpStatus.completed.fg)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _pill(IconData icon, Color bg, Color fg, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, size: 16, color: fg),
      ),
    );
  }
}
