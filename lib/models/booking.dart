import 'package:parkgrid/core/constants/app_enums.dart';

class Booking {
  const Booking({
    required this.id,
    required this.userId,
    required this.parkingId,
    required this.parkingName,
    required this.slotNumber,
    required this.startDateTime,
    required this.durationHours,
    required this.totalPrice,
    required this.paymentMethod,
    required this.status,
    required this.vehicleNumber,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String parkingId;
  final String parkingName;
  final int slotNumber;
  final DateTime startDateTime;
  final int durationHours;
  final double totalPrice;
  final PaymentMethod paymentMethod;
  final BookingStatus status;
  final String vehicleNumber;
  final DateTime createdAt;

  DateTime get endDateTime => startDateTime.add(Duration(hours: durationHours));

  Booking copyWith({
    String? id,
    String? userId,
    String? parkingId,
    String? parkingName,
    int? slotNumber,
    DateTime? startDateTime,
    int? durationHours,
    double? totalPrice,
    PaymentMethod? paymentMethod,
    BookingStatus? status,
    String? vehicleNumber,
    DateTime? createdAt,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      parkingId: parkingId ?? this.parkingId,
      parkingName: parkingName ?? this.parkingName,
      slotNumber: slotNumber ?? this.slotNumber,
      startDateTime: startDateTime ?? this.startDateTime,
      durationHours: durationHours ?? this.durationHours,
      totalPrice: totalPrice ?? this.totalPrice,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'parkingId': parkingId,
      'parkingName': parkingName,
      'slotNumber': slotNumber,
      'startDateTime': startDateTime.toIso8601String(),
      'durationHours': durationHours,
      'totalPrice': totalPrice,
      'paymentMethod': paymentMethod.name,
      'status': status.name,
      'vehicleNumber': vehicleNumber,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      userId: json['userId'] as String,
      parkingId: json['parkingId'] as String,
      parkingName: json['parkingName'] as String,
      slotNumber: json['slotNumber'] as int,
      startDateTime: DateTime.parse(json['startDateTime'] as String),
      durationHours: json['durationHours'] as int,
      totalPrice: (json['totalPrice'] as num).toDouble(),
      paymentMethod: PaymentMethod.values.byName(json['paymentMethod'] as String),
      status: BookingStatus.values.byName(json['status'] as String),
      vehicleNumber: json['vehicleNumber'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
