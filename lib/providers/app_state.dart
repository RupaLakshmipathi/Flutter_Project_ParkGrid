import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:parkgrid/core/constants/app_enums.dart';
import 'package:parkgrid/models/booking.dart';
import 'package:parkgrid/models/parking_location.dart';
import 'package:parkgrid/models/parking_slot.dart';
import 'package:parkgrid/models/user_account.dart';
import 'package:parkgrid/services/booking_logic.dart';
import 'package:parkgrid/services/booking_result.dart';
import 'package:parkgrid/services/demo_data.dart';
import 'package:parkgrid/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class AppState extends ChangeNotifier {
  static const adminEmail = 'admin@parkgrid.app';
  static const adminPassword = 'admin123';
  static const _adminPasswordSalt = 'parkgrid-fixed-admin-v1';

  AppState({required this._storageService});

  final StorageService _storageService;
  final _uuid = const Uuid();
  final _random = Random();

  bool _initialized = false;
  bool _busy = false;
  String? _authError;

  late List<UserAccount> _users;
  UserAccount? _currentUser;
  late List<ParkingLocation> _parkingLocations;
  late List<Booking> _bookings;
  late Map<String, List<String>> _favoritesByUser;

  bool get initialized => _initialized;
  bool get busy => _busy;
  String? get authError => _authError;
  UserAccount? get currentUser => _currentUser;
  List<UserAccount> get customerAccounts =>
      List.unmodifiable(_users.where((user) => user.role == UserRole.user));
  List<ParkingLocation> get parkingLocations =>
      List.unmodifiable(_parkingLocations);
  List<Booking> get bookings => List.unmodifiable(_bookings);
  bool get isAdmin => _currentUser?.role == UserRole.admin;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final snapshot = await _storageService.load();
    if (snapshot == null) {
      _users = _prepareUsers(DemoData.users());
      _parkingLocations = DemoData.parkingLocations();
      _bookings = <Booking>[];
      _favoritesByUser = <String, List<String>>{};
      _currentUser = null;
    } else {
      _users = _prepareUsers(snapshot.users);
      _parkingLocations = snapshot.parkingLocations;
      _bookings = snapshot.bookings;
      _favoritesByUser = snapshot.favoritesByUser;
      _currentUser = _users
          .where((u) => u.id == snapshot.currentUserId)
          .firstOrNull;
    }

    await _persist();
    _initialized = true;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _busy = true;
    _authError = null;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 250));
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      _busy = false;
      _authError = 'Enter an email and password to continue.';
      notifyListeners();
      return false;
    }

    UserAccount? user;
    if (normalizedEmail == adminEmail) {
      user = _users
          .where((account) => account.role == UserRole.admin)
          .firstOrNull;
      if (user == null || !_passwordMatches(user, password)) {
        _busy = false;
        _authError =
            'Admin sign-in requires the configured administrator password.';
        notifyListeners();
        return false;
      }
    } else {
      user = _users
          .where(
            (account) =>
                account.role == UserRole.user &&
                account.email.toLowerCase() == normalizedEmail,
          )
          .firstOrNull;

      if (user == null) {
        final salt = _uuid.v4();
        final guessedName = normalizedEmail.split('@').first.trim();
        user = UserAccount(
          id: _uuid.v4(),
          name: guessedName.isEmpty ? 'Citizen' : guessedName,
          email: normalizedEmail,
          passwordHash: _hashPassword(password, salt),
          passwordSalt: salt,
          role: UserRole.user,
        );
        _users = [..._users, user];
      } else if (!_passwordMatches(user, password)) {
        _busy = false;
        _authError = 'That email is already registered with another password.';
        notifyListeners();
        return false;
      }
    }

    _currentUser = user;
    _busy = false;
    await _persist();
    notifyListeners();
    return true;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _busy = true;
    _authError = null;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 250));
    final normalizedEmail = email.trim().toLowerCase();
    if (name.trim().isEmpty || normalizedEmail.isEmpty || password.isEmpty) {
      _busy = false;
      _authError = 'Name, email, and password are required.';
      notifyListeners();
      return false;
    }
    if (normalizedEmail == adminEmail) {
      _busy = false;
      _authError =
          'The administrator account cannot be registered as a citizen.';
      notifyListeners();
      return false;
    }
    final exists = _users.any((u) => u.email.toLowerCase() == normalizedEmail);
    if (exists) {
      _busy = false;
      _authError = 'Email already exists. Please login.';
      notifyListeners();
      return false;
    }

    final salt = _uuid.v4();
    final account = UserAccount(
      id: _uuid.v4(),
      name: name.trim(),
      email: normalizedEmail,
      passwordHash: _hashPassword(password, salt),
      passwordSalt: salt,
      role: UserRole.user,
    );

    _users = [..._users, account];
    _currentUser = account;
    _busy = false;
    await _persist();
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _currentUser = null;
    await _persist();
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String email,
  }) async {
    final currentUser = _currentUser;
    if (currentUser == null || name.trim().isEmpty) {
      return;
    }
    final normalizedEmail = currentUser.role == UserRole.admin
        ? adminEmail
        : email.trim().toLowerCase();
    if (normalizedEmail.isEmpty ||
        (currentUser.role != UserRole.admin && normalizedEmail == adminEmail) ||
        _users.any(
          (user) =>
              user.id != currentUser.id &&
              user.email.toLowerCase() == normalizedEmail,
        )) {
      return;
    }
    _currentUser = currentUser.copyWith(
      name: name.trim(),
      email: normalizedEmail,
    );
    _users = _users
        .map((user) => user.id == _currentUser!.id ? _currentUser! : user)
        .toList(growable: false);
    await _persist();
    notifyListeners();
  }

  ParkingLocation? parkingById(String parkingId) {
    return _parkingLocations.where((p) => p.id == parkingId).firstOrNull;
  }

  List<Booking> bookingsForCurrentUser() {
    final userId = _currentUser?.id;
    if (userId == null) {
      return <Booking>[];
    }
    return _bookings
        .where((booking) => booking.userId == userId)
        .toList(growable: false)
      ..sort((a, b) => b.startDateTime.compareTo(a.startDateTime));
  }

  List<String> favoriteLocationIdsForCurrentUser() {
    final userId = _currentUser?.id;
    if (userId == null) return const <String>[];
    return List.unmodifiable(_favoritesByUser[userId] ?? const <String>[]);
  }

  String nameForUser(String userId) {
    return accountById(userId)?.name ?? 'ParkGrid customer';
  }

  Booking? upcomingBookingForCurrentUser() {
    final now = DateTime.now();
    final upcoming =
        bookingsForCurrentUser()
            .where((booking) {
              return booking.status != BookingStatus.cancelled &&
                  booking.startDateTime.isAfter(now);
            })
            .toList(growable: false)
          ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

    return upcoming.firstOrNull;
  }

  bool isFavorite(String parkingId) {
    final userId = _currentUser?.id;
    if (userId == null) {
      return false;
    }
    final favorites = _favoritesByUser[userId] ?? <String>[];
    return favorites.contains(parkingId);
  }

  Future<void> toggleFavorite(String parkingId) async {
    final userId = _currentUser?.id;
    if (userId == null) {
      return;
    }

    final favorites = [...?_favoritesByUser[userId]];
    if (favorites.contains(parkingId)) {
      favorites.remove(parkingId);
    } else {
      favorites.add(parkingId);
    }
    _favoritesByUser[userId] = favorites;
    await _persist();
    notifyListeners();
  }

  Future<BookingResult> createBooking({
    required String parkingId,
    required int slotNumber,
    required DateTime startDateTime,
    required int durationHours,
    required String vehicleNumber,
    required PaymentMethod paymentMethod,
  }) async {
    final user = _currentUser;
    if (user == null) {
      return const BookingResult(
        success: false,
        message: 'Please login first.',
      );
    }

    final parking = parkingById(parkingId);
    if (parking == null) {
      return const BookingResult(
        success: false,
        message: 'Parking location missing.',
      );
    }

    if (startDateTime.isBefore(DateTime.now())) {
      return const BookingResult(
        success: false,
        message: 'Booking time must be in the future.',
      );
    }

    final slot = parking.slots.where((s) => s.number == slotNumber).firstOrNull;
    if (slot == null ||
        slot.status == SlotStatus.unavailable ||
        slot.status == SlotStatus.occupied) {
      return const BookingResult(
        success: false,
        message: 'Selected slot is not available.',
      );
    }

    final price = BookingLogic.calculatePrice(
      hourlyRate: parking.hourlyRate,
      durationHours: durationHours,
    );

    final booking = Booking(
      id: 'PG-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
      userId: user.id,
      parkingId: parking.id,
      parkingName: parking.name,
      slotNumber: slotNumber,
      startDateTime: startDateTime,
      durationHours: durationHours,
      totalPrice: price,
      paymentMethod: paymentMethod,
      status: BookingStatus.upcoming,
      vehicleNumber: vehicleNumber.trim().toUpperCase(),
      createdAt: DateTime.now(),
    );

    final overlap = BookingLogic.hasOverlap(
      existingBookings: _bookings,
      candidate: booking,
    );
    if (overlap) {
      return const BookingResult(
        success: false,
        message: 'Slot already reserved for the selected time.',
      );
    }

    _busy = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 900));

    final paymentSucceeded = _random.nextInt(100) >= 15;
    if (!paymentSucceeded) {
      _busy = false;
      notifyListeners();
      return const BookingResult(
        success: false,
        message: 'Payment failed. Please try again.',
      );
    }

    _bookings = [..._bookings, booking];
    _parkingLocations = _parkingLocations
        .map(
          (location) => location.id == parkingId
              ? location.updateSlotStatus(slotNumber, SlotStatus.occupied)
              : location,
        )
        .toList(growable: false);
    _busy = false;
    await _persist();
    notifyListeners();

    return BookingResult(
      success: true,
      message: 'Booking confirmed with ID ${booking.id}',
      booking: booking,
    );
  }

  Future<bool> cancelBooking(String bookingId) async {
    final booking = _bookings.where((b) => b.id == bookingId).firstOrNull;
    if (booking == null) {
      return false;
    }

    if (booking.status == BookingStatus.cancelled) {
      return false;
    }

    if (!booking.startDateTime.isAfter(DateTime.now())) {
      return false;
    }

    _bookings = _bookings
        .map(
          (existing) => existing.id == bookingId
              ? existing.copyWith(status: BookingStatus.cancelled)
              : existing,
        )
        .toList(growable: false);

    final hasOtherActiveBooking = _bookings.any((other) {
      return other.id != bookingId &&
          other.parkingId == booking.parkingId &&
          other.slotNumber == booking.slotNumber &&
          other.status != BookingStatus.cancelled;
    });

    if (!hasOtherActiveBooking) {
      _parkingLocations = _parkingLocations
          .map(
            (location) => location.id == booking.parkingId
                ? location.updateSlotStatus(
                    booking.slotNumber,
                    SlotStatus.available,
                  )
                : location,
          )
          .toList(growable: false);
    }

    await _persist();
    notifyListeners();
    return true;
  }

  Future<bool> addOrUpdateParkingLocation(ParkingLocation location) async {
    if (!isAdmin) {
      return false;
    }

    final exists = _parkingLocations.any((p) => p.id == location.id);
    final previous = parkingById(location.id);
    if (previous != null && location.totalSlots < previous.totalSlots) {
      final removedSlotNumbers = previous.slots
          .where((slot) => slot.number > location.totalSlots)
          .map((slot) => slot.number)
          .toSet();
      if (removedSlotNumbers.any(
        (number) => reservationForSlot(location.id, number) != null,
      )) {
        return false;
      }
    }
    if (exists) {
      _parkingLocations = _parkingLocations
          .map((p) => p.id == location.id ? location : p)
          .toList(growable: false);
    } else {
      _parkingLocations = [..._parkingLocations, location];
    }

    await _persist();
    notifyListeners();
    return true;
  }

  Future<bool> deleteParkingLocation(String parkingId) async {
    if (!isAdmin || parkingById(parkingId) == null) {
      return false;
    }
    final hasActiveBookings = _bookings.any(
      (booking) =>
          booking.parkingId == parkingId &&
          booking.status != BookingStatus.cancelled &&
          booking.status != BookingStatus.completed &&
          booking.endDateTime.isAfter(DateTime.now()),
    );
    if (hasActiveBookings) {
      return false;
    }
    _parkingLocations = _parkingLocations
        .where((location) => location.id != parkingId)
        .toList(growable: false);
    await _persist();
    notifyListeners();
    return true;
  }

  Booking? reservationForSlot(String parkingId, int slotNumber) {
    final now = DateTime.now();
    final reservations =
        _bookings
            .where(
              (booking) =>
                  booking.parkingId == parkingId &&
                  booking.slotNumber == slotNumber &&
                  booking.status != BookingStatus.cancelled &&
                  booking.status != BookingStatus.completed &&
                  booking.endDateTime.isAfter(now),
            )
            .toList(growable: false)
          ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    return reservations.firstOrNull;
  }

  Future<bool> updateSlotStatus({
    required String parkingId,
    required int slotNumber,
    required SlotStatus status,
  }) async {
    if (!isAdmin) {
      return false;
    }

    if (status == SlotStatus.available &&
        reservationForSlot(parkingId, slotNumber) != null) {
      return false;
    }

    _parkingLocations = _parkingLocations
        .map(
          (location) => location.id == parkingId
              ? location.updateSlotStatus(slotNumber, status)
              : location,
        )
        .toList(growable: false);

    await _persist();
    notifyListeners();
    return true;
  }

  int get totalSlots =>
      _parkingLocations.fold<int>(0, (sum, p) => sum + p.totalSlots);

  int get availableSlots =>
      _parkingLocations.fold<int>(0, (sum, p) => sum + p.availableSlots);

  int get totalBookings => _bookings.length;

  List<UserAccount> _prepareUsers(List<UserAccount> storedUsers) {
    final citizens = storedUsers
        .where(
          (user) =>
              user.role == UserRole.user &&
              user.email.trim().toLowerCase() != adminEmail,
        )
        .map((user) {
          if (user.passwordSalt.isNotEmpty) {
            return user.copyWith(email: user.email.trim().toLowerCase());
          }
          final salt = _uuid.v4();
          return user.copyWith(
            email: user.email.trim().toLowerCase(),
            passwordHash: _hashPassword(user.passwordHash, salt),
            passwordSalt: salt,
          );
        })
        .toList(growable: true);

    citizens.add(
      UserAccount(
        id: 'u_admin',
        name: 'ParkGrid Admin',
        email: adminEmail,
        passwordHash: _hashPassword(adminPassword, _adminPasswordSalt),
        passwordSalt: _adminPasswordSalt,
        role: UserRole.admin,
      ),
    );
    return citizens;
  }

  bool _passwordMatches(UserAccount account, String password) {
    return account.passwordHash ==
        _hashPassword(password, account.passwordSalt);
  }

  String _hashPassword(String password, String salt) {
    return sha256.convert(utf8.encode('$salt:$password')).toString();
  }

  UserAccount? accountById(String userId) {
    return _users.where((user) => user.id == userId).firstOrNull;
  }

  Future<bool> addParkingSlots({
    required String parkingId,
    required int count,
  }) async {
    if (!isAdmin || count <= 0) {
      return false;
    }

    final location = parkingById(parkingId);
    if (location == null) {
      return false;
    }

    final nextNumber =
        location.slots.fold<int>(
          0,
          (highest, slot) => slot.number > highest ? slot.number : highest,
        ) +
        1;
    final newSlots = List<ParkingSlot>.generate(
      count,
      (index) =>
          ParkingSlot(number: nextNumber + index, status: SlotStatus.available),
      growable: false,
    );

    _parkingLocations = _parkingLocations
        .map(
          (parking) => parking.id == parkingId
              ? parking.copyWith(slots: [...parking.slots, ...newSlots])
              : parking,
        )
        .toList(growable: false);
    await _persist();
    notifyListeners();
    return true;
  }

  Future<BookingResult> createAdminBooking({
    required String userId,
    required String parkingId,
    required int slotNumber,
    required DateTime startDateTime,
    required int durationHours,
    required String vehicleNumber,
    required PaymentMethod paymentMethod,
  }) async {
    if (!isAdmin) {
      return const BookingResult(
        success: false,
        message: 'Only administrators can create bookings for customers.',
      );
    }

    final customer = accountById(userId);
    if (customer == null || customer.role != UserRole.user) {
      return const BookingResult(
        success: false,
        message: 'Select a valid customer.',
      );
    }

    final parking = parkingById(parkingId);
    if (parking == null) {
      return const BookingResult(
        success: false,
        message: 'Parking location not found.',
      );
    }

    final slot = parking.slots
        .where((item) => item.number == slotNumber)
        .firstOrNull;
    if (slot == null || slot.status != SlotStatus.available) {
      return const BookingResult(
        success: false,
        message: 'Select an available slot.',
      );
    }

    if (durationHours <= 0 || startDateTime.isBefore(DateTime.now())) {
      return const BookingResult(
        success: false,
        message: 'Choose a future start time and a valid duration.',
      );
    }

    final vehicle = vehicleNumber.trim().toUpperCase();
    if (vehicle.isEmpty) {
      return const BookingResult(
        success: false,
        message: 'Enter a vehicle number.',
      );
    }

    final booking = Booking(
      id: 'PG-${_uuid.v4().substring(0, 8).toUpperCase()}',
      userId: customer.id,
      parkingId: parking.id,
      parkingName: parking.name,
      slotNumber: slotNumber,
      startDateTime: startDateTime,
      durationHours: durationHours,
      totalPrice: BookingLogic.calculatePrice(
        hourlyRate: parking.hourlyRate,
        durationHours: durationHours,
      ),
      paymentMethod: paymentMethod,
      status: BookingStatus.upcoming,
      vehicleNumber: vehicle,
      createdAt: DateTime.now(),
    );

    if (BookingLogic.hasOverlap(
      existingBookings: _bookings,
      candidate: booking,
    )) {
      return const BookingResult(
        success: false,
        message: 'That slot is already booked for the selected time.',
      );
    }

    _bookings = [..._bookings, booking];
    _parkingLocations = _parkingLocations
        .map(
          (location) => location.id == parkingId
              ? location.updateSlotStatus(slotNumber, SlotStatus.occupied)
              : location,
        )
        .toList(growable: false);
    await _persist();
    notifyListeners();

    return BookingResult(
      success: true,
      message: 'Booking ${booking.id} created for ${customer.name}.',
      booking: booking,
    );
  }

  Future<void> _persist() async {
    await _storageService.save(
      AppSnapshot(
        users: _users,
        currentUserId: _currentUser?.id,
        parkingLocations: _parkingLocations,
        bookings: _bookings,
        favoritesByUser: _favoritesByUser,
      ),
    );
  }
}
