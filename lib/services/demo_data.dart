import 'package:parkgrid/core/constants/app_enums.dart';
import 'package:parkgrid/models/parking_location.dart';
import 'package:parkgrid/models/parking_slot.dart';
import 'package:parkgrid/models/user_account.dart';

class DemoData {
  static List<UserAccount> users() {
    return const [
      UserAccount(
        id: 'u_demo',
        name: 'Aarav Kumar',
        email: 'user@parkgrid.app',
        passwordHash: 'demo123',
        passwordSalt: '',
        role: UserRole.user,
      ),
      UserAccount(
        id: 'u_admin',
        name: 'Admin Priya',
        email: 'admin@parkgrid.app',
        passwordHash: 'admin123',
        passwordSalt: '',
        role: UserRole.admin,
      ),
    ];
  }

  static List<ParkingLocation> parkingLocations() {
    return [
      ParkingLocation(
        id: 'p1',
        name: 'City Mall Deck',
        address: 'MG Road, Central District',
        category: ParkingCategory.mall,
        hourlyRate: 60,
        distanceKm: 2.4,
        openingHours: '08:00 - 23:00',
        imageEmoji: '🏬',
        amenities: const ['CCTV', 'Covered', 'EV Charging'],
        slots: _slots(total: 18, occupied: [2, 5, 9], blocked: [14]),
      ),
      ParkingLocation(
        id: 'p2',
        name: 'Skyline Office Hub',
        address: 'Tech Park Avenue, Sector 9',
        category: ParkingCategory.office,
        hourlyRate: 75,
        distanceKm: 4.2,
        openingHours: '24 Hours',
        imageEmoji: '🏢',
        amenities: const ['CCTV', 'Valet', 'Covered'],
        slots: _slots(total: 24, occupied: [1, 8, 11, 22], blocked: [19]),
      ),
      ParkingLocation(
        id: 'p3',
        name: 'CarePlus Hospital Park',
        address: 'Lake View Street, Green Block',
        category: ParkingCategory.hospital,
        hourlyRate: 40,
        distanceKm: 1.1,
        openingHours: '24 Hours',
        imageEmoji: '🏥',
        amenities: const ['CCTV', 'Emergency Access', 'Covered'],
        slots: _slots(total: 30, occupied: [3, 7, 12, 17], blocked: [30]),
      ),
      ParkingLocation(
        id: 'p4',
        name: 'Riverside Retail Plaza',
        address: 'Riverside Ring Road',
        category: ParkingCategory.mall,
        hourlyRate: 55,
        distanceKm: 3.0,
        openingHours: '07:00 - 22:00',
        imageEmoji: '🛍️',
        amenities: const ['CCTV', 'EV Charging', 'Car Wash'],
        slots: _slots(total: 16, occupied: [4, 6], blocked: [16]),
      ),
    ];
  }

  static List<ParkingSlot> _slots({
    required int total,
    required List<int> occupied,
    required List<int> blocked,
  }) {
    return List.generate(total, (index) {
      final number = index + 1;
      if (blocked.contains(number)) {
        return ParkingSlot(number: number, status: SlotStatus.unavailable);
      }
      if (occupied.contains(number)) {
        return ParkingSlot(number: number, status: SlotStatus.occupied);
      }
      return ParkingSlot(number: number, status: SlotStatus.available);
    });
  }
}
