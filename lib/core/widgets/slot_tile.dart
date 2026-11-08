import 'package:flutter/material.dart';
import 'package:parkgrid/core/constants/app_enums.dart';

class SlotTile extends StatelessWidget {
  const SlotTile({
    super.key,
    required this.number,
    required this.status,
    required this.onTap,
  });

  final int number;
  final SlotStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final config = _style(status);

    return InkWell(
      onTap: status == SlotStatus.available ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: config.$1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: config.$2),
        ),
        alignment: Alignment.center,
        child: Text(
          number.toString(),
          style: TextStyle(color: config.$3, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  (Color, Color, Color) _style(SlotStatus status) {
    switch (status) {
      case SlotStatus.available:
        return (
          const Color(0xFFD9F1E6),
          const Color(0xFF9ED6BB),
          const Color(0xFF17633D),
        );
      case SlotStatus.selected:
        return (
          const Color(0xFFE8E0FA),
          const Color(0xFFBDADE8),
          const Color(0xFF493580),
        );
      case SlotStatus.occupied:
        return (
          const Color(0xFFFBE4D8),
          const Color(0xFFE7B7A0),
          const Color(0xFF7B3F24),
        );
      case SlotStatus.unavailable:
        return (
          const Color(0xFFDCEBFA),
          const Color(0xFFB9CDE2),
          const Color(0xFF465E78),
        );
    }
  }
}
