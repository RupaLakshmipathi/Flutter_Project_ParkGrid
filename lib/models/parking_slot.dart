import 'package:parkgrid/core/constants/app_enums.dart';

class ParkingSlot {
  const ParkingSlot({
    required this.number,
    required this.status,
  });

  final int number;
  final SlotStatus status;

  bool get isSelectable => status == SlotStatus.available;

  ParkingSlot copyWith({
    int? number,
    SlotStatus? status,
  }) {
    return ParkingSlot(
      number: number ?? this.number,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'status': status.name,
    };
  }

  factory ParkingSlot.fromJson(Map<String, dynamic> json) {
    return ParkingSlot(
      number: json['number'] as int,
      status: SlotStatus.values.byName(json['status'] as String),
    );
  }
}
