import 'package:flutter/material.dart';
import 'package:parkgrid/core/constants/app_enums.dart';
import 'package:parkgrid/core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color text;
    late final String label;

    switch (status) {
      case BookingStatus.upcoming:
        bg = AppTheme.powderBlue;
        text = AppTheme.primaryText;
        label = 'Upcoming';
      case BookingStatus.completed:
        bg = AppTheme.softMint;
        text = AppTheme.primaryText;
        label = 'Completed';
      case BookingStatus.cancelled:
        bg = AppTheme.peach;
        text = AppTheme.primaryText;
        label = 'Cancelled';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
