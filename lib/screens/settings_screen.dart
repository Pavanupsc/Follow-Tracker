import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _group([
            _row('Theme', 'System default'),
            _row('Currency', '\u20b9 Rupee'),
            _row('Daily reminder', '9:00 am'),
            _row('Backup to Google Drive', 'Connect', isLast: true),
          ]),
          const SizedBox(height: 12),
          _group([
            _row('Export data (CSV)', 'Export'),
            _row('Get support', 'Contact us', isLast: true),
          ]),
        ],
      ),
    );
  }

  Widget _group(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(children: children),
      );

  Widget _row(String k, String v, {bool isLast = false}) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
            Text(v,
                style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.tealDeep)),
          ],
        ),
      );
}
