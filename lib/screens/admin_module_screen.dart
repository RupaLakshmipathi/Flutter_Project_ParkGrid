import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:parkgrid/core/constants/app_enums.dart';
import 'package:parkgrid/core/theme/app_theme.dart';
import 'package:parkgrid/models/parking_location.dart';
import 'package:parkgrid/models/parking_slot.dart';
import 'package:parkgrid/providers/app_state.dart';
import 'package:provider/provider.dart';

class AdminModuleScreen extends StatefulWidget {
  const AdminModuleScreen({super.key});

  @override
  State<AdminModuleScreen> createState() => _AdminModuleScreenState();
}

class _AdminModuleScreenState extends State<AdminModuleScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _AdminDashboard(onNavigate: (index) => setState(() => _index = index)),
      const _ParkingManagementPage(),
      const _SlotManagementPage(),
      const _BookingManagementPage(),
      const _AdminProfilePage(),
    ];
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(key: ValueKey(_index), child: pages[_index]),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_parking_outlined),
            label: 'Parking',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Slots',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _AdminDashboard extends StatelessWidget {
  const _AdminDashboard({required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final now = DateTime.now();
    var available = 0;
    var reserved = 0;
    var occupied = 0;
    var unavailable = 0;
    for (final location in state.parkingLocations) {
      for (final slot in location.slots) {
        final reservation = state.reservationForSlot(location.id, slot.number);
        if (slot.status == SlotStatus.unavailable) {
          unavailable++;
        } else if (reservation != null &&
            reservation.startDateTime.isAfter(now)) {
          reserved++;
        } else if (slot.status == SlotStatus.occupied || reservation != null) {
          occupied++;
        } else {
          available++;
        }
      }
    }
    final recent = state.bookings.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final totalSlots = state.totalSlots;
    final occupiedRatio = totalSlots == 0
        ? 0.0
        : ((occupied + reserved) / totalSlots).clamp(0.0, 1.0);

    return _PageContent(
      title: 'Admin dashboard',
      subtitle: 'Here is what is happening across ParkGrid.',
      trailing: IconButton(
        tooltip: 'Log out',
        onPressed: () => _logout(context, state),
        icon: const Icon(Icons.logout_rounded),
      ),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 720 ? 3 : 2;
            final spacing = 12.0;
            final width =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;
            final stats = <_DashboardMetric>[
              _DashboardMetric(
                'Locations',
                '${state.parkingLocations.length}',
                Icons.location_on_outlined,
                AppTheme.lavender,
              ),
              _DashboardMetric(
                'Total slots',
                '$totalSlots',
                Icons.grid_view_rounded,
                AppTheme.powderBlue,
              ),
              _DashboardMetric(
                'Available',
                '$available',
                Icons.check_circle_outline_rounded,
                AppTheme.softMint,
              ),
              _DashboardMetric(
                'Reserved',
                '$reserved',
                Icons.event_available_outlined,
                AppTheme.butterYellow,
              ),
              _DashboardMetric(
                'Occupied',
                '$occupied',
                Icons.directions_car_filled_outlined,
                AppTheme.peach,
              ),
              _DashboardMetric(
                'Bookings',
                '${state.totalBookings}',
                Icons.receipt_long_outlined,
                const Color(0xFFE9EEF5),
              ),
            ];
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: stats
                  .map(
                    (metric) => SizedBox(
                      width: width,
                      child: _MetricCard(metric: metric),
                    ),
                  )
                  .toList(growable: false),
            );
          },
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: 'Parking occupancy',
          trailing: Text('${(occupiedRatio * 100).round()}%'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: occupiedRatio,
                  minHeight: 12,
                  backgroundColor: AppTheme.powderBlue,
                  color: AppTheme.accent,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                '$occupied occupied  ·  $reserved reserved  ·  $available available  ·  $unavailable unavailable',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('Quick actions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _QuickAction(
              icon: Icons.add_location_alt_outlined,
              label: 'Add parking',
              onTap: () async {
                final added = await _editParking(context);
                if (added) onNavigate(1);
              },
            ),
            _QuickAction(
              icon: Icons.grid_view_rounded,
              label: 'Manage slots',
              onTap: () => onNavigate(2),
            ),
            _QuickAction(
              icon: Icons.receipt_long_outlined,
              label: 'View bookings',
              onTap: () => onNavigate(3),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Recent bookings', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (recent.isEmpty)
          const _EmptyPanel(
            icon: Icons.event_note_outlined,
            message: 'Bookings created by customers will appear here.',
          )
        else
          ...recent
              .take(4)
              .map((booking) => _BookingTile(booking: booking, compact: true)),
      ],
    );
  }
}

class _ParkingManagementPage extends StatelessWidget {
  const _ParkingManagementPage();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return _PageContent(
      title: 'Parking locations',
      subtitle: 'Manage the places customers can book.',
      trailing: IconButton.filledTonal(
        tooltip: 'Add parking',
        onPressed: () => _editParking(context),
        icon: const Icon(Icons.add),
      ),
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _editParking(context),
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Add parking location'),
          ),
        ),
        const SizedBox(height: 12),
        if (state.parkingLocations.isEmpty)
          const _EmptyPanel(
            icon: Icons.local_parking_outlined,
            message: 'No parking locations yet. Add one to get started.',
          )
        else
          ...state.parkingLocations.map(
            (location) => _ParkingLocationCard(location: location),
          ),
      ],
    );
  }
}

class _ParkingLocationCard extends StatelessWidget {
  const _ParkingLocationCard({required this.location});

  final ParkingLocation location;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Card(
      margin: const EdgeInsets.only(bottom: 11),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 13, 8, 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.powderBlue,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    location.imageEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        location.address,
                        style: const TextStyle(color: AppTheme.accent),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      await _editParking(context, existing: location);
                    } else if (value == 'delete') {
                      await _deleteParking(context, state, location);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit details')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete location'),
                    ),
                  ],
                ),
              ],
            ),
            if (location.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(location.description),
            ],
            const SizedBox(height: 11),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoPill('₹${location.hourlyRate.toStringAsFixed(0)} / hour'),
                _InfoPill('${location.availableSlots} available'),
                _InfoPill('${location.totalSlots} total slots'),
                _InfoPill(location.openingHours),
              ],
            ),
            if (location.amenities.isNotEmpty) ...[
              const SizedBox(height: 9),
              Text(
                location.amenities.join(' · '),
                style: const TextStyle(color: AppTheme.accent, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SlotManagementPage extends StatefulWidget {
  const _SlotManagementPage();

  @override
  State<_SlotManagementPage> createState() => _SlotManagementPageState();
}

class _SlotManagementPageState extends State<_SlotManagementPage> {
  String? _parkingId;
  int _floorIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final locations = state.parkingLocations;
    if (locations.isEmpty) {
      return const _PageContent(
        title: 'Slot management',
        subtitle: 'Select a parking location to manage its slots.',
        children: [
          _EmptyPanel(
            icon: Icons.grid_view_rounded,
            message: 'Add a parking location before creating slots.',
          ),
        ],
      );
    }
    final selectedId = locations.any((location) => location.id == _parkingId)
        ? _parkingId!
        : locations.first.id;
    final location = state.parkingById(selectedId)!;
    return _PageContent(
      title: 'Slot management',
      subtitle: 'Update availability for each parking space.',
      children: [
        DropdownButtonFormField<String>(
          initialValue: selectedId,
          decoration: const InputDecoration(labelText: 'Parking location'),
          items: locations
              .map(
                (item) => DropdownMenuItem(
                  value: item.id,
                  child: Text(item.name, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(growable: false),
          onChanged: (value) => setState(() {
            _parkingId = value;
            _floorIndex = 0;
          }),
        ),
        const SizedBox(height: 13),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.powderBlue.withValues(alpha: .7),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(Icons.local_parking_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text('${location.availableSlots} spaces available'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _FloorSelector(
          floorCount: _floorCount(location),
          selectedIndex: _floorIndex.clamp(0, _floorCount(location) - 1),
          onSelected: (value) => setState(() => _floorIndex = value),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: const [
            _StatusLegend(color: Color(0xFFDCEFE5), label: 'Available'),
            _StatusLegend(color: Color(0xFFFFEBC5), label: 'Reserved'),
            _StatusLegend(color: Color(0xFFFBE4D8), label: 'Occupied'),
            _StatusLegend(color: Color(0xFFE3E7ED), label: 'Unavailable'),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                '${location.totalSlots} numbered slots',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _addSlots(context, location),
              icon: const Icon(Icons.add),
              label: const Text('Add slots'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (location.slots.isEmpty)
          const _EmptyPanel(
            icon: Icons.grid_view_rounded,
            message: 'This location does not have any slots yet.',
          )
        else
          _AdminParkingMap(
            location: location,
            floorIndex: _floorIndex.clamp(0, _floorCount(location) - 1),
            onTapSlot: (slot, status, reservation, floorIndex) =>
                _showSlotDetails(context, location, slot, status, reservation),
          ),
      ],
    );
  }
}

class _FloorSelector extends StatelessWidget {
  const _FloorSelector({
    required this.floorCount,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int floorCount;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: List.generate(floorCount, (index) {
        final selected = index == selectedIndex;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            avatar: selected ? const Icon(Icons.check, size: 16) : null,
            label: Text('${_ordinal(index + 1)} Floor'),
            selected: selected,
            onSelected: (_) => onSelected(index),
            backgroundColor: Colors.white,
            selectedColor: AppTheme.powderBlue,
            side: BorderSide(
              color: selected ? AppTheme.powderBlue : const Color(0xFFE2E5EA),
            ),
          ),
        );
      }),
    ),
  );
}

class _AdminParkingMap extends StatelessWidget {
  const _AdminParkingMap({
    required this.location,
    required this.floorIndex,
    required this.onTapSlot,
  });

  final ParkingLocation location;
  final int floorIndex;
  final void Function(ParkingSlot, String, dynamic, int) onTapSlot;

  @override
  Widget build(BuildContext context) {
    const slotsPerFloor = 12;
    final firstNumber = floorIndex * slotsPerFloor + 1;
    final floorSlots =
        location.slots
            .where(
              (slot) =>
                  slot.number >= firstNumber &&
                  slot.number < firstNumber + slotsPerFloor,
            )
            .toList()
          ..sort((a, b) => a.number.compareTo(b.number));
    final rows = (floorSlots.length / 2).ceil();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(27),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryText.withValues(alpha: .05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: floorSlots.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 38),
              child: Center(child: Text('No slots on this floor yet.')),
            )
          : Column(
              children: List.generate(rows, (rowIndex) {
                final left = floorSlots[rowIndex * 2];
                final rightIndex = rowIndex * 2 + 1;
                final right = rightIndex < floorSlots.length
                    ? floorSlots[rightIndex]
                    : null;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    height: 82,
                    child: Row(
                      children: [
                        Expanded(
                          child: _AdminSlotCard(
                            location: location,
                            slot: left,
                            floorIndex: floorIndex,
                            onTap: onTapSlot,
                          ),
                        ),
                        const _DriveLane(),
                        Expanded(
                          child: right == null
                              ? const SizedBox.shrink()
                              : _AdminSlotCard(
                                  location: location,
                                  slot: right,
                                  floorIndex: floorIndex,
                                  onTap: onTapSlot,
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
    );
  }
}

class _AdminSlotCard extends StatelessWidget {
  const _AdminSlotCard({
    required this.location,
    required this.slot,
    required this.floorIndex,
    required this.onTap,
  });

  final ParkingLocation location;
  final ParkingSlot slot;
  final int floorIndex;
  final void Function(ParkingSlot, String, dynamic, int) onTap;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final reservation = state.reservationForSlot(location.id, slot.number);
    final status = _effectiveSlotStatus(slot, reservation);
    final icon = switch (status) {
      'Reserved' => Icons.event_available_rounded,
      'Occupied' => Icons.directions_car_filled_rounded,
      'Unavailable' => Icons.block_rounded,
      _ => null,
    };
    return InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: () => onTap(slot, status, reservation, floorIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: status == 'Available'
              ? const Color(0xFFFAFBFD)
              : _slotColor(status),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: status == 'Available'
                ? const Color(0xFFD7DEE7)
                : _slotColor(status).withValues(alpha: .9),
            width: 1.4,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: const Color(0xFF568FC7), size: 21),
              const SizedBox(width: 7),
            ],
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _slotName(slot.number, floorIndex),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    status,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriveLane extends StatelessWidget {
  const _DriveLane();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 32,
    child: Column(
      children: [
        Expanded(child: Container(width: 2, color: const Color(0xFFE1E5EA))),
        const Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 18,
          color: Color(0xFFA8B1BC),
        ),
        Expanded(child: Container(width: 2, color: const Color(0xFFE1E5EA))),
      ],
    ),
  );
}

class _BookingManagementPage extends StatefulWidget {
  const _BookingManagementPage();

  @override
  State<_BookingManagementPage> createState() => _BookingManagementPageState();
}

class _BookingManagementPageState extends State<_BookingManagementPage> {
  final _searchController = TextEditingController();
  String _filter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final query = _searchController.text.trim().toLowerCase();
    final bookings = state.bookings.where((booking) {
      final customer = state.nameForUser(booking.userId).toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          booking.id.toLowerCase().contains(query) ||
          customer.contains(query);
      return matchesSearch &&
          (_filter == 'All' || _bookingStatus(booking) == _filter);
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return _PageContent(
      title: 'Bookings',
      subtitle: '${state.totalBookings} total customer reservations.',
      children: [
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Search booking ID or customer',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 11),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['All', 'Upcoming', 'Active', 'Completed', 'Cancelled']
                .map(
                  (filter) => Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        const SizedBox(height: 10),
        if (bookings.isEmpty)
          _EmptyPanel(
            icon: Icons.receipt_long_outlined,
            message: query.isEmpty
                ? 'No bookings match this filter yet.'
                : 'No bookings match “${_searchController.text.trim()}”.',
          )
        else
          ...bookings.map((booking) => _BookingTile(booking: booking)),
      ],
    );
  }
}

class _AdminProfilePage extends StatelessWidget {
  const _AdminProfilePage();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser;
    if (user == null || !state.isAdmin) {
      return const Center(child: Text('Admin profile is unavailable.'));
    }
    return _PageContent(
      title: 'Admin profile',
      subtitle: 'Manage your administrator account.',
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppTheme.lavender,
                  child: Text(
                    _initials(user.name),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(user.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(color: AppTheme.accent),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _editAdminName(context, state),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit name'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        _SectionCard(
          title: 'Account details',
          child: Column(
            children: [
              _ProfileLine(label: 'Role', value: 'Administrator'),
              _ProfileLine(label: 'Email', value: user.email),
              _ProfileLine(
                label: 'Locations managed',
                value: '${state.parkingLocations.length}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () => _logout(context, state),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Log out'),
          ),
        ),
      ],
    );
  }
}

class _BookingTile extends StatelessWidget {
  const _BookingTile({required this.booking, this.compact = false});

  final dynamic booking;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final customer = state.nameForUser(booking.userId);
    final status = _bookingStatus(booking);
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
        onTap: () => _showBookingDetails(context, state, booking),
        leading: CircleAvatar(
          backgroundColor: _bookingColor(status),
          child: Icon(
            Icons.local_parking_outlined,
            color: AppTheme.primaryText,
            size: 20,
          ),
        ),
        title: Text(
          booking.parkingName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          compact
              ? '${booking.id} · $customer'
              : '${booking.id} · $customer · Slot ${booking.slotNumber}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: compact
            ? const Icon(Icons.chevron_right_rounded)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusPill(label: status, color: _bookingColor(status)),
                  const SizedBox(height: 4),
                  Text(
                    '₹${booking.totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  const _PageContent({
    required this.title,
    required this.subtitle,
    required this.children,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: AppTheme.accent)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
      const SizedBox(height: 18),
      ...children,
    ],
  );
}

class _DashboardMetric {
  const _DashboardMetric(this.title, this.value, this.icon, this.color);
  final String title;
  final String value;
  final IconData icon;
  final Color color;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});
  final _DashboardMetric metric;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: metric.color,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        Icon(metric.icon, color: AppTheme.primaryText),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(metric.title, style: const TextStyle(fontSize: 11)),
              Text(
                metric.value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 18),
    label: Text(label),
  );
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.accent, size: 30),
          const SizedBox(height: 9),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _InfoPill extends StatelessWidget {
  const _InfoPill(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppTheme.background,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(label, style: const TextStyle(fontSize: 11)),
  );
}

class _StatusLegend extends StatelessWidget {
  const _StatusLegend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 11)),
    ],
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: const TextStyle(fontSize: 10)),
  );
}

class _ProfileLine extends StatelessWidget {
  const _ProfileLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

Future<bool> _editParking(
  BuildContext context, {
  ParkingLocation? existing,
}) async {
  final state = context.read<AppState>();
  final name = TextEditingController(text: existing?.name ?? '');
  final address = TextEditingController(text: existing?.address ?? '');
  final description = TextEditingController(text: existing?.description ?? '');
  final rate = TextEditingController(
    text: existing?.hourlyRate.toStringAsFixed(0) ?? '50',
  );
  final total = TextEditingController(
    text: existing?.totalSlots.toString() ?? '16',
  );
  final hoursParts = (existing?.openingHours ?? '08:00 - 22:00').split(
    RegExp(r'\s*-\s*'),
  );
  final opening = TextEditingController(
    text: hoursParts.length > 1 ? hoursParts.first : '08:00',
  );
  final closing = TextEditingController(
    text: hoursParts.length > 1 ? hoursParts.last : '22:00',
  );
  var category = existing?.category ?? ParkingCategory.mall;
  final amenities = <String>{...?existing?.amenities};
  final formKey = GlobalKey<FormState>();
  final saved = await showDialog<ParkingLocation>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(existing == null ? 'Add parking' : 'Edit parking'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _FormField(controller: name, label: 'Parking name'),
                  _FormField(controller: address, label: 'Address'),
                  _FormField(
                    controller: description,
                    label: 'Description',
                    maxLines: 2,
                    requiredField: false,
                  ),
                  DropdownButtonFormField<ParkingCategory>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: ParkingCategory.values
                        .where((item) => item != ParkingCategory.all)
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item.label),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => category = value);
                      }
                    },
                  ),
                  const SizedBox(height: 9),
                  _FormField(
                    controller: rate,
                    label: 'Hourly price (₹)',
                    numeric: true,
                    validator: (value) {
                      final parsed = double.tryParse(value ?? '');
                      return parsed == null || parsed <= 0
                          ? 'Enter a valid hourly price'
                          : null;
                    },
                  ),
                  _FormField(
                    controller: total,
                    label: 'Total slots',
                    numeric: true,
                    validator: (value) {
                      final parsed = int.tryParse(value ?? '');
                      return parsed == null || parsed < 1 || parsed > 500
                          ? 'Enter a number from 1 to 500'
                          : null;
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _FormField(
                          controller: opening,
                          label: 'Opens (e.g. 08:00)',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FormField(
                          controller: closing,
                          label: 'Closes (e.g. 22:00)',
                        ),
                      ),
                    ],
                  ),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(top: 10, bottom: 4),
                      child: Text(
                        'Facilities',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  _AmenityEditor(
                    selected: amenities,
                    onChanged: (value, selected) => setDialogState(() {
                      if (selected) {
                        amenities.add(value);
                      } else {
                        amenities.remove(value);
                      }
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final count = int.parse(total.text);
              final oldSlots = <int, ParkingSlot>{
                for (final slot in existing?.slots ?? const <ParkingSlot>[])
                  slot.number: slot,
              };
              final slots = List<ParkingSlot>.generate(count, (index) {
                final number = index + 1;
                return oldSlots[number] ??
                    ParkingSlot(number: number, status: SlotStatus.available);
              }, growable: false);
              Navigator.pop(
                dialogContext,
                ParkingLocation(
                  id:
                      existing?.id ??
                      'p${DateTime.now().millisecondsSinceEpoch}',
                  name: name.text.trim(),
                  address: address.text.trim(),
                  description: description.text.trim(),
                  category: category,
                  hourlyRate: double.parse(rate.text),
                  distanceKm: existing?.distanceKm ?? 1.0,
                  openingHours:
                      '${opening.text.trim()} - ${closing.text.trim()}',
                  imageEmoji: existing?.imageEmoji ?? '🅿️',
                  amenities: amenities.toList(growable: false),
                  slots: slots,
                ),
              );
            },
            child: const Text('Save location'),
          ),
        ],
      ),
    ),
  );
  name.dispose();
  address.dispose();
  description.dispose();
  rate.dispose();
  total.dispose();
  opening.dispose();
  closing.dispose();
  if (saved == null) return false;
  final ok = await state.addOrUpdateParkingLocation(saved);
  if (!ok && context.mounted) {
    _showMessage(
      context,
      'The location could not be changed because it has an active reservation.',
    );
  }
  return ok;
}

class _AmenityEditor extends StatelessWidget {
  const _AmenityEditor({required this.selected, required this.onChanged});
  final Set<String> selected;
  final void Function(String, bool) onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    children:
        ['CCTV', 'EV Charging', 'Security', 'Covered', 'Valet', 'Car Wash']
            .map(
              (item) => FilterChip(
                label: Text(item),
                selected: selected.contains(item),
                onSelected: (value) => onChanged(item, value),
              ),
            )
            .toList(growable: false),
  );
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    this.numeric = false,
    this.maxLines = 1,
    this.requiredField = true,
    this.validator,
  });
  final TextEditingController controller;
  final String label;
  final bool numeric;
  final int maxLines;
  final bool requiredField;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator:
          validator ??
          (value) => requiredField && (value == null || value.trim().isEmpty)
              ? '$label is required'
              : null,
    ),
  );
}

Future<void> _deleteParking(
  BuildContext context,
  AppState state,
  ParkingLocation location,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete parking location?'),
      content: Text('Delete ${location.name}? This removes it from Explore.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  final deleted = await state.deleteParkingLocation(location.id);
  if (context.mounted) {
    _showMessage(
      context,
      deleted
          ? '${location.name} was deleted.'
          : 'This location cannot be deleted while it has an active booking.',
    );
  }
}

Future<void> _addSlots(BuildContext context, ParkingLocation location) async {
  final state = context.read<AppState>();
  final controller = TextEditingController(text: '4');
  final count = await showDialog<int>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Add slots to ${location.name}'),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Number of slots'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final value = int.tryParse(controller.text);
            if (value != null && value > 0 && value <= 500) {
              Navigator.pop(dialogContext, value);
            }
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
  controller.dispose();
  if (count == null) return;
  final added = await state.addParkingSlots(
    parkingId: location.id,
    count: count,
  );
  if (context.mounted && !added) {
    _showMessage(context, 'Slots could not be added.');
  }
}

Future<void> _showSlotDetails(
  BuildContext context,
  ParkingLocation location,
  ParkingSlot slot,
  String status,
  dynamic reservation,
) async {
  final state = context.read<AppState>();
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Slot ${slot.number} · ${location.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _StatusPill(label: status, color: _slotColor(status)),
            if (reservation != null) ...[
              const SizedBox(height: 12),
              Text('Reserved by ${state.nameForUser(reservation.userId)}'),
              Text('Booking ${reservation.id}'),
              Text(
                '${DateFormat.yMMMd().add_jm().format(reservation.startDateTime)} – ${DateFormat.jm().format(reservation.endDateTime)}',
              ),
            ],
            const SizedBox(height: 14),
            if (status == 'Unavailable')
              FilledButton.icon(
                onPressed: reservation != null
                    ? null
                    : () async {
                        final updated = await state.updateSlotStatus(
                          parkingId: location.id,
                          slotNumber: slot.number,
                          status: SlotStatus.available,
                        );
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                        if (!updated && context.mounted) {
                          _showMessage(
                            context,
                            'A slot with an active reservation cannot be made available.',
                          );
                        }
                      },
                icon: const Icon(Icons.settings_backup_restore_rounded),
                label: const Text('Restore slot'),
              )
            else if (reservation == null)
              FilledButton.tonalIcon(
                onPressed: () async {
                  await state.updateSlotStatus(
                    parkingId: location.id,
                    slotNumber: slot.number,
                    status: SlotStatus.unavailable,
                  );
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
                icon: const Icon(Icons.block_outlined),
                label: const Text('Mark unavailable for maintenance'),
              ),
          ],
        ),
      ),
    ),
  );
}

class _BookingStatusDialog extends StatelessWidget {
  const _BookingStatusDialog({required this.booking});
  final dynamic booking;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final customer = state.accountById(booking.userId);
    final start = booking.startDateTime;
    final end = booking.endDateTime;
    return AlertDialog(
      title: const Text('Booking details'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailLine('Booking ID', booking.id),
            _DetailLine('Customer', customer?.name ?? 'ParkGrid customer'),
            _DetailLine('Email', customer?.email ?? '—'),
            _DetailLine('Parking', booking.parkingName),
            _DetailLine('Slot', '${booking.slotNumber}'),
            _DetailLine('Vehicle', booking.vehicleNumber),
            _DetailLine('Booking date', DateFormat.yMMMd().format(start)),
            _DetailLine('Start', DateFormat.yMMMd().add_jm().format(start)),
            _DetailLine('End', DateFormat.yMMMd().add_jm().format(end)),
            _DetailLine('Amount', '₹${booking.totalPrice.toStringAsFixed(2)}'),
            _DetailLine('Payment', '${booking.paymentMethod.label} · Paid'),
            _DetailLine('Status', _bookingStatus(booking)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(label, style: const TextStyle(color: AppTheme.accent)),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

void _showBookingDetails(
  BuildContext context,
  AppState state,
  dynamic booking,
) {
  showDialog<void>(
    context: context,
    builder: (_) => _BookingStatusDialog(booking: booking),
  );
}

Future<void> _editAdminName(BuildContext context, AppState state) async {
  final controller = TextEditingController(text: state.currentUser?.name ?? '');
  final name = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Update admin name'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, controller.text),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  controller.dispose();
  if (name != null && name.trim().isNotEmpty) {
    await state.updateProfile(name: name, email: state.currentUser!.email);
  }
}

Future<void> _logout(BuildContext context, AppState state) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Log out?'),
      content: const Text('You will return to the ParkGrid login screen.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Stay'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Log out'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await state.logout();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
    }
  }
}

String _bookingStatus(dynamic booking) {
  if (booking.status == BookingStatus.cancelled) return 'Cancelled';
  final now = DateTime.now();
  if (!booking.endDateTime.isAfter(now)) return 'Completed';
  if (!booking.startDateTime.isAfter(now)) return 'Active';
  return 'Upcoming';
}

String _effectiveSlotStatus(ParkingSlot slot, dynamic reservation) {
  if (slot.status == SlotStatus.unavailable) return 'Unavailable';
  if (reservation != null &&
      reservation.startDateTime.isAfter(DateTime.now())) {
    return 'Reserved';
  }
  if (slot.status == SlotStatus.occupied || reservation != null) {
    return 'Occupied';
  }
  return 'Available';
}

Color _slotColor(String status) => switch (status) {
  'Available' => const Color(0xFFD9F1E6),
  'Reserved' => const Color(0xFFFFF0C9),
  'Occupied' => const Color(0xFFFBE4D8),
  _ => const Color(0xFFE2E5EA),
};

Color _bookingColor(String status) => switch (status) {
  'Upcoming' => AppTheme.powderBlue,
  'Active' => AppTheme.softMint,
  'Completed' => AppTheme.lavender,
  _ => AppTheme.peach,
};

int _floorCount(ParkingLocation location) {
  final highestSlot = location.slots.fold<int>(
    0,
    (highest, slot) => slot.number > highest ? slot.number : highest,
  );
  return (highestSlot / 12).ceil().clamp(1, 99);
}

String _slotName(int number, int floorIndex) {
  final floorLetter = String.fromCharCode(65 + floorIndex.clamp(0, 25));
  final floorNumber = ((number - 1) % 12) + 1;
  return '$floorLetter-${floorNumber.toString().padLeft(2, '0')}';
}

String _ordinal(int value) {
  if (value % 100 >= 11 && value % 100 <= 13) return '${value}th';
  return switch (value % 10) {
    1 => '${value}st',
    2 => '${value}nd',
    3 => '${value}rd',
    _ => '${value}th',
  };
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty);
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
