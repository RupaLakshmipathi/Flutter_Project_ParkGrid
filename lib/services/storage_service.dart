import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:parkgrid/models/booking.dart';
import 'package:parkgrid/models/parking_location.dart';
import 'package:parkgrid/models/user_account.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSnapshot {
  const AppSnapshot({
    required this.users,
    required this.currentUserId,
    required this.parkingLocations,
    required this.bookings,
    required this.favoritesByUser,
  });

  final List<UserAccount> users;
  final String? currentUserId;
  final List<ParkingLocation> parkingLocations;
  final List<Booking> bookings;
  final Map<String, List<String>> favoritesByUser;

  Map<String, dynamic> toJson() {
    return {
      'users': users.map((user) => user.toJson()).toList(growable: false),
      'currentUserId': currentUserId,
      'parkingLocations': parkingLocations
          .map((parking) => parking.toJson())
          .toList(growable: false),
      'bookings': bookings
          .map((booking) => booking.toJson())
          .toList(growable: false),
      'favoritesByUser': favoritesByUser,
    };
  }

  factory AppSnapshot.fromJson(Map<String, dynamic> json) {
    final favoritesRaw =
        (json['favoritesByUser'] as Map<String, dynamic>? ?? {});
    return AppSnapshot(
      users: (json['users'] as List<dynamic>)
          .map((user) => UserAccount.fromJson(user as Map<String, dynamic>))
          .toList(growable: false),
      currentUserId: json['currentUserId'] as String?,
      parkingLocations: (json['parkingLocations'] as List<dynamic>)
          .map(
            (parking) =>
                ParkingLocation.fromJson(parking as Map<String, dynamic>),
          )
          .toList(growable: false),
      bookings: (json['bookings'] as List<dynamic>)
          .map((booking) => Booking.fromJson(booking as Map<String, dynamic>))
          .toList(growable: false),
      favoritesByUser: favoritesRaw.map(
        (key, value) => MapEntry(key, (value as List<dynamic>).cast<String>()),
      ),
    );
  }
}

abstract class StorageService {
  Future<AppSnapshot?> load();

  Future<void> save(AppSnapshot snapshot);
}

class SharedPrefsStorageService implements StorageService {
  static const _snapshotKey = 'parkgrid_snapshot_v1';

  @override
  Future<AppSnapshot?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_snapshotKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return AppSnapshot.fromJson(decoded);
  }

  @override
  Future<void> save(AppSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_snapshotKey, jsonEncode(snapshot.toJson()));
  }
}

class HiveStorageService implements StorageService {
  HiveStorageService();

  static const _boxName = 'parkgrid_database';
  static const _snapshotKey = 'app_snapshot_v1';
  static const _legacySnapshotKey = 'parkgrid_snapshot_v1';

  late final Future<Box<String>> _boxFuture = Hive.openBox<String>(_boxName);

  @override
  Future<AppSnapshot?> load() async {
    final box = await _boxFuture;
    final stored = box.get(_snapshotKey);
    if (stored != null && stored.isNotEmpty) {
      return AppSnapshot.fromJson(jsonDecode(stored) as Map<String, dynamic>);
    }

    // Migrate the earlier SharedPreferences snapshot into Hive once.
    final preferences = await SharedPreferences.getInstance();
    final legacy = preferences.getString(_legacySnapshotKey);
    if (legacy == null || legacy.isEmpty) {
      return null;
    }

    await box.put(_snapshotKey, legacy);
    await preferences.remove(_legacySnapshotKey);
    return AppSnapshot.fromJson(jsonDecode(legacy) as Map<String, dynamic>);
  }

  @override
  Future<void> save(AppSnapshot snapshot) async {
    final box = await _boxFuture;
    await box.put(_snapshotKey, jsonEncode(snapshot.toJson()));
  }
}

class InMemoryStorageService implements StorageService {
  AppSnapshot? _snapshot;

  @override
  Future<AppSnapshot?> load() async => _snapshot;

  @override
  Future<void> save(AppSnapshot snapshot) async {
    _snapshot = snapshot;
  }
}
