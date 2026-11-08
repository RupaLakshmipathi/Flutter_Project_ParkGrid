import 'package:flutter/material.dart';
import 'package:parkgrid/core/constants/app_enums.dart';
import 'package:parkgrid/core/theme/app_theme.dart';
import 'package:parkgrid/models/parking_location.dart';
import 'package:parkgrid/models/parking_slot.dart';
import 'package:parkgrid/providers/app_state.dart';
import 'package:parkgrid/screens/home_screen.dart';
import 'package:provider/provider.dart';

class ProfileAdminScreen extends StatelessWidget {
  const ProfileAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;
    if (user == null) {
      return const SafeArea(child: Center(child: Text('Please login again.')));
    }
    if (appState.isAdmin) {
      return const SafeArea(
        child: Center(child: Text('Admin dashboard is available on Home.')),
      );
    }
    return _CitizenProfile(appState: appState);
  }
}

class _CitizenProfile extends StatelessWidget {
  const _CitizenProfile({required this.appState});
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final user = appState.currentUser!;
    final favorites = appState.favoriteLocationIdsForCurrentUser();
    final vehicles = appState
        .bookingsForCurrentUser()
        .map((booking) => booking.vehicleNumber)
        .toSet();
    return SafeArea(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 26),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.powderBlue, AppTheme.softMint],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.white,
                  child: Text(
                    _initials(user.name),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryText,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  user.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 25,
                    color: AppTheme.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(color: AppTheme.accent),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _showEditProfile(context),
                  child: const Text('Edit profile'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _ProfileAction(
            icon: Icons.directions_car_outlined,
            title: 'My vehicles',
            detail:
                '${vehicles.length} ${vehicles.length == 1 ? 'vehicle' : 'vehicles'}',
            onTap: () => _showVehicles(context, vehicles),
          ),
          _ProfileAction(
            icon: Icons.favorite_border_rounded,
            title: 'Favorites',
            detail: '${favorites.length} saved',
            onTap: () => _showFavorites(context, appState),
          ),
          _ProfileAction(
            icon: Icons.calendar_month_outlined,
            title: 'Book a spot',
            onTap: () => context
                .findAncestorStateOfType<HomeScreenState>()
                ?.selectTab(1),
          ),
          _ProfileAction(
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () => _showSettings(context),
          ),
          _ProfileAction(
            icon: Icons.notifications_none_rounded,
            title: 'Help & support',
            onTap: () => _showSupport(context),
          ),
          const SizedBox(height: 4),
          const Divider(indent: 20, endIndent: 20, height: 1),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 7,
            ),
            leading: _iconBox(Icons.logout_rounded, AppTheme.powderBlue),
            title: const Text(
              'Log out',
              style: TextStyle(
                color: Color(0xFFD45E5E),
                fontWeight: FontWeight.w700,
              ),
            ),
            onTap: () => _logout(context, appState),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.title,
    this.detail,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String? detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 7),
        leading: _iconBox(icon, AppTheme.powderBlue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (detail != null) ...[
              Text(
                detail!,
                style: const TextStyle(color: AppTheme.accent, fontSize: 12),
              ),
              const SizedBox(width: 10),
            ],
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
        onTap: onTap,
      ),
      const Divider(indent: 24, endIndent: 24, height: 1),
    ],
  );
}

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key, required this.appState});
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final bookingsToday = appState.bookings
        .where((b) => DateUtils.isSameDay(b.createdAt, today))
        .length;
    final revenue = appState.bookings
        .where((b) => b.status != BookingStatus.cancelled)
        .fold<double>(0, (sum, booking) => sum + booking.totalPrice);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
        children: [
          const Text(
            'Parking management',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _logout(context, appState),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Log out'),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 14) / 2;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _MetricCard(
                    width: width,
                    title: 'Locations',
                    value: '${appState.parkingLocations.length}',
                    detail: 'Parking sites',
                    icon: Icons.location_on_outlined,
                    color: AppTheme.lavender,
                  ),
                  _MetricCard(
                    width: width,
                    title: 'Total slots',
                    value: '${appState.totalSlots}',
                    detail: '${appState.availableSlots} available',
                    icon: Icons.directions_car_outlined,
                    color: AppTheme.softMint,
                  ),
                  _MetricCard(
                    width: width,
                    title: 'Bookings',
                    value: '${appState.totalBookings}',
                    detail: '$bookingsToday today',
                    icon: Icons.calendar_month_outlined,
                    color: AppTheme.powderBlue,
                  ),
                  _MetricCard(
                    width: width,
                    title: 'Revenue',
                    value: '₹${_compactAmount(revenue)}',
                    detail: 'Demo total',
                    icon: Icons.credit_card_outlined,
                    color: AppTheme.peach,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 58,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5BB8AE),
                foregroundColor: Colors.white,
              ),
              onPressed: () => _showAddLocation(context),
              icon: const Icon(Icons.add),
              label: const Text(
                'Add parking location',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Parking locations',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          if (appState.parkingLocations.isEmpty)
            const _EmptyPanel(
              message:
                  'No parking locations yet. Add your first location above.',
            )
          else
            ...appState.parkingLocations.map(
              (location) => _AdminLocationCard(location: location),
            ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.width,
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
  });
  final double width;
  final String title;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: 110,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      children: [
        Icon(icon, size: 25, color: AppTheme.primaryText),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryText,
                ),
              ),
              Text(
                detail,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 10, color: AppTheme.accent),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _AdminLocationCard extends StatelessWidget {
  const _AdminLocationCard({required this.location});
  final ParkingLocation location;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 9),
    child: ListTile(
      leading: _iconBox(Icons.directions_car_outlined, AppTheme.powderBlue),
      title: Text(
        location.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${location.availableSlots} available · ${location.totalSlots} total',
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'edit') _showAddLocation(context, existing: location);
          if (value == 'slots') _showAddSlots(context, location);
          if (value == 'status') _showSlotStatusSheet(context, location);
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('Edit location')),
          PopupMenuItem(value: 'slots', child: Text('Add slots')),
          PopupMenuItem(value: 'status', child: Text('Update slot status')),
        ],
      ),
    ),
  );
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(18), child: Text(message)),
  );
}

Widget _iconBox(IconData icon, Color color) => Container(
  width: 48,
  height: 48,
  decoration: BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(14),
  ),
  child: Icon(icon, color: AppTheme.primaryText),
);

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'PG';
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}

String _compactAmount(double amount) => amount >= 1000
    ? '${(amount / 1000).toStringAsFixed(amount >= 10000 ? 0 : 1)}k'
    : amount.toStringAsFixed(0);

Future<void> _logout(BuildContext context, AppState appState) async {
  await appState.logout();
  if (context.mounted) {
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }
}

Future<void> _showEditProfile(BuildContext context) async {
  final state = context.read<AppState>();
  final user = state.currentUser;
  if (user == null) return;
  final name = TextEditingController(text: user.name);
  final email = TextEditingController(text: user.email);
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Edit profile'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: email,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            await state.updateProfile(name: name.text, email: email.text);
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
  name.dispose();
  email.dispose();
}

void _showVehicles(BuildContext context, Set<String> vehicles) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('My vehicles'),
      content: Text(
        vehicles.isEmpty
            ? 'Vehicles you book with will appear here.'
            : vehicles.join('\n'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

void _showFavorites(BuildContext context, AppState appState) {
  final locations = appState
      .favoriteLocationIdsForCurrentUser()
      .map(appState.parkingById)
      .whereType<ParkingLocation>()
      .toList();
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Favorites'),
      content: Text(
        locations.isEmpty
            ? 'Your saved parking locations will appear here.'
            : locations.map((location) => location.name).join('\n'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

void _showSettings(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Settings'),
      content: const Text(
        'ParkGrid uses the current device settings. More preferences will be available here soon.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

void _showSupport(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Help & support'),
      content: const Text(
        'For help with a reservation, open Booking history and check your booking details.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

Future<void> _showAddLocation(
  BuildContext context, {
  ParkingLocation? existing,
}) async {
  final state = context.read<AppState>();
  final name = TextEditingController(text: existing?.name ?? '');
  final address = TextEditingController(text: existing?.address ?? '');
  final rate = TextEditingController(
    text: existing?.hourlyRate.toStringAsFixed(0) ?? '50',
  );
  final distance = TextEditingController(
    text: existing?.distanceKm.toStringAsFixed(1) ?? '1.0',
  );
  var category = existing?.category ?? ParkingCategory.mall;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(
          existing == null ? 'Add parking location' : 'Edit location',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: address,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              TextField(
                controller: rate,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Hourly rate'),
              ),
              TextField(
                controller: distance,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Approx. distance (km)',
                ),
              ),
              DropdownButtonFormField<ParkingCategory>(
                initialValue: category,
                items: ParkingCategory.values
                    .where((c) => c != ParkingCategory.all)
                    .map(
                      (c) => DropdownMenuItem(value: c, child: Text(c.label)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => category = value);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final hourlyRate = double.tryParse(rate.text);
              final distanceKm = double.tryParse(distance.text);
              if (name.text.trim().isEmpty ||
                  address.text.trim().isEmpty ||
                  hourlyRate == null ||
                  hourlyRate <= 0 ||
                  distanceKm == null ||
                  distanceKm <= 0) {
                return;
              }
              final location = ParkingLocation(
                id: existing?.id ?? 'p${DateTime.now().millisecondsSinceEpoch}',
                name: name.text.trim(),
                address: address.text.trim(),
                category: category,
                hourlyRate: hourlyRate,
                distanceKm: distanceKm,
                openingHours: existing?.openingHours ?? '24 Hours',
                imageEmoji: existing?.imageEmoji ?? 'P',
                amenities: existing?.amenities ?? const ['CCTV', 'Covered'],
                slots:
                    existing?.slots ??
                    List.generate(
                      16,
                      (i) => ParkingSlot(
                        number: i + 1,
                        status: SlotStatus.available,
                      ),
                    ),
              );
              await state.addOrUpdateParkingLocation(location);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
  name.dispose();
  address.dispose();
  rate.dispose();
  distance.dispose();
}

Future<void> _showAddSlots(
  BuildContext context,
  ParkingLocation location,
) async {
  final state = context.read<AppState>();
  final count = TextEditingController(text: '4');
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Add slots to ${location.name}'),
      content: TextField(
        controller: count,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Number of slots'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final value = int.tryParse(count.text);
            if (value == null || value < 1 || value > 100) return;
            await state.addParkingSlots(parkingId: location.id, count: value);
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          },
          child: const Text('Add slots'),
        ),
      ],
    ),
  );
  count.dispose();
}

Future<void> _showSlotStatusSheet(
  BuildContext context,
  ParkingLocation location,
) async {
  final state = context.read<AppState>();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              location.name,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: location.slots
                  .take(24)
                  .map(
                    (slot) => PopupMenuButton<SlotStatus>(
                      onSelected: (value) => state.updateSlotStatus(
                        parkingId: location.id,
                        slotNumber: slot.number,
                        status: value,
                      ),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: SlotStatus.available,
                          child: Text('Available'),
                        ),
                        PopupMenuItem(
                          value: SlotStatus.occupied,
                          child: Text('Occupied'),
                        ),
                        PopupMenuItem(
                          value: SlotStatus.unavailable,
                          child: Text('Unavailable'),
                        ),
                      ],
                      child: Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppTheme.powderBlue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${slot.number}'),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    ),
  );
}
