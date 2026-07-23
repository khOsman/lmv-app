import 'package:flutter/material.dart';

import '../models/learner.dart';
import '../theme/app_colors.dart';

class StatusChip extends StatelessWidget {
  final VerifyStatus status;

  const StatusChip({super.key, required this.status});

  Color get _color {
    switch (status) {
      case VerifyStatus.verified:
        return AppColors.statusVerified;
      case VerifyStatus.duplicate:
        return AppColors.statusDuplicate;
      case VerifyStatus.pending:
        return AppColors.statusPending;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: _color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
