import 'package:parkgrid/models/booking.dart';

class BookingResult {
  const BookingResult({
    required this.success,
    required this.message,
    this.booking,
  });

  final bool success;
  final String message;
  final Booking? booking;
}
