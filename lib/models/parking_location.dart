import 'package:parkgrid/core/constants/app_enums.dart';
import 'package:parkgrid/models/parking_slot.dart';

class ParkingLocation {
  const ParkingLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.category,
    required this.hourlyRate,
    this.distanceKm = 1.0,
    required this.openingHours,
    required this.imageEmoji,
    required this.amenities,
    required this.slots,
  });

  final String id;
  final String name;
  final String address;
  final ParkingCategory category;
  final double hourlyRate;

  /// Approximate distance in kilometres from the driver's current area.
  /// Demo data uses sample distances until a maps/location service is connected.
  final double distanceKm;
  final String openingHours;
  final String imageEmoji;
  final List<String> amenities;
  final List<ParkingSlot> slots;

  int get totalSlots => slots.length;

  int get availableSlots =>
      slots.where((slot) => slot.status == SlotStatus.available).length;

  ParkingLocation copyWith({
    String? id,
    String? name,
    String? address,
    ParkingCategory? category,
    double? hourlyRate,
    double? distanceKm,
    String? openingHours,
    String? imageEmoji,
    List<String>? amenities,
    List<ParkingSlot>? slots,
  }) {
    return ParkingLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      category: category ?? this.category,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      distanceKm: distanceKm ?? this.distanceKm,
      openingHours: openingHours ?? this.openingHours,
      imageEmoji: imageEmoji ?? this.imageEmoji,
      amenities: amenities ?? this.amenities,
      slots: slots ?? this.slots,
    );
  }

  ParkingLocation updateSlotStatus(int slotNumber, SlotStatus newStatus) {
    final updatedSlots = slots
        .map(
          (slot) => slot.number == slotNumber
              ? slot.copyWith(status: newStatus)
              : slot,
        )
        .toList(growable: false);
    return copyWith(slots: updatedSlots);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'category': category.name,
      'hourlyRate': hourlyRate,
      'distanceKm': distanceKm,
      'openingHours': openingHours,
      'imageEmoji': imageEmoji,
      'amenities': amenities,
      'slots': slots.map((slot) => slot.toJson()).toList(growable: false),
    };
  }

  factory ParkingLocation.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    return ParkingLocation(
      id: id,
      name: json['name'] as String,
      address: json['address'] as String,
      category: ParkingCategory.values.byName(json['category'] as String),
      hourlyRate: (json['hourlyRate'] as num).toDouble(),
      distanceKm:
          (json['distanceKm'] as num?)?.toDouble() ?? _legacyDistanceFor(id),
      openingHours: json['openingHours'] as String,
      imageEmoji: json['imageEmoji'] as String,
      amenities: (json['amenities'] as List<dynamic>).cast<String>(),
      slots: (json['slots'] as List<dynamic>)
          .map((slot) => ParkingSlot.fromJson(slot as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  static double _legacyDistanceFor(String id) {
    return switch (id) {
      'p1' => 2.4,
      'p2' => 4.2,
      'p3' => 1.1,
      'p4' => 3.0,
      _ => 1.0,
    };
  }
}
