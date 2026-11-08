import 'package:parkgrid/core/constants/app_enums.dart';
import 'package:parkgrid/models/booking.dart';

class BookingLogic {
  static double calculatePrice({
    required double hourlyRate,
    required int durationHours,
  }) {
    if (durationHours <= 0) {
      throw ArgumentError('Duration must be at least 1 hour.');
    }
    return hourlyRate * durationHours;
  }

  static bool hasOverlap({
    required List<Booking> existingBookings,
    required Booking candidate,
  }) {
    for (final booking in existingBookings) {
      if (booking.status == BookingStatus.cancelled) {
        continue;
      }
      if (booking.parkingId != candidate.parkingId ||
          booking.slotNumber != candidate.slotNumber) {
        continue;
      }

      final overlaps = candidate.startDateTime.isBefore(booking.endDateTime) &&
          booking.startDateTime.isBefore(candidate.endDateTime);
      if (overlaps) {
        return true;
      }
    }
    return false;
  }
}
