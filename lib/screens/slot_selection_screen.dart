import 'package:flutter/material.dart';
import 'package:parkgrid/core/constants/app_enums.dart';
import 'package:parkgrid/core/theme/app_theme.dart';
import 'package:parkgrid/models/parking_slot.dart';
import 'package:parkgrid/providers/app_state.dart';
import 'package:parkgrid/screens/booking_payment_screen.dart';
import 'package:provider/provider.dart';

class SlotSelectionScreen extends StatefulWidget {
  const SlotSelectionScreen({super.key, required this.parkingId});

  final String parkingId;

  @override
  State<SlotSelectionScreen> createState() => _SlotSelectionScreenState();
}

class _SlotSelectionScreenState extends State<SlotSelectionScreen> {
  int? _selectedSlot;
  int _selectedFloor = 0;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final parking = appState.parkingById(widget.parkingId);
    if (parking == null) {
      return const Scaffold(body: Center(child: Text('Parking not found.')));
    }

    const slotsPerFloor = 12;
    final floorCount = (parking.totalSlots / slotsPerFloor)
        .ceil()
        .clamp(1, 99)
        .toInt();
    final floorStart = _selectedFloor * slotsPerFloor + 1;
    final floorEnd = floorStart + slotsPerFloor;
    final floorSlots = parking.slots
        .where((slot) => slot.number >= floorStart && slot.number < floorEnd)
        .toList(growable: false);
    final selected = parking.slots
        .where((slot) => slot.number == _selectedSlot)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Choose your parking spot')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          parking.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 3),
                        Text('${parking.availableSlots} spaces available'),
                      ],
                    ),
                  ),
                  const Icon(Icons.directions_car_outlined),
                ],
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: floorCount,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) => ChoiceChip(
                  label: Text(_floorLabel(index)),
                  selected: _selectedFloor == index,
                  onSelected: (_) => setState(() {
                    _selectedFloor = index;
                    _selectedSlot = null;
                  }),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 9, 18, 9),
              child: Wrap(
                spacing: 14,
                runSpacing: 5,
                children: const [
                  _SlotLegend(color: AppTheme.softMint, label: 'Available'),
                  _SlotLegend(color: AppTheme.powderBlue, label: 'Selected'),
                  _SlotLegend(color: AppTheme.peach, label: 'Occupied'),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: floorSlots.isEmpty
                    ? const Center(child: Text('No spaces on this floor yet.'))
                    : ListView.separated(
                        itemCount: (floorSlots.length / 2).ceil(),
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, rowIndex) {
                          final leftIndex = rowIndex * 2;
                          final left = floorSlots[leftIndex];
                          final right = leftIndex + 1 < floorSlots.length
                              ? floorSlots[leftIndex + 1]
                              : null;
                          return SizedBox(
                            height: 72,
                            child: Row(
                              children: [
                                Expanded(
                                  child: _ParkingSpot(
                                    number: left.number,
                                    floor: _selectedFloor,
                                    status: _statusFor(left),
                                    onTap: () => _select(left),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const _DriveLane(),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: right == null
                                      ? const SizedBox.shrink()
                                      : _ParkingSpot(
                                          number: right.number,
                                          floor: _selectedFloor,
                                          status: _statusFor(right),
                                          onTap: () => _select(right),
                                        ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: Column(
                children: [
                  if (_selectedSlot != null && selected != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Selected ${_slotLabel(_selectedSlot!, _selectedFloor)}'
                        ' · ₹${parking.hourlyRate.toStringAsFixed(0)} / hour',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2875F0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      onPressed: _selectedSlot == null
                          ? null
                          : () => Navigator.of(context).pushNamed(
                              '/booking',
                              arguments: BookingScreenArgs(
                                parkingId: parking.id,
                                slotNumber: _selectedSlot!,
                              ),
                            ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Book a Place  ›››',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            Icons.directions_car_filled_rounded,
                            color: Colors.white.withValues(alpha: .9),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SlotStatus _statusFor(ParkingSlot slot) {
    if (_selectedSlot == slot.number) return SlotStatus.selected;
    return slot.status;
  }

  void _select(ParkingSlot slot) {
    if (slot.status != SlotStatus.available) return;
    setState(() => _selectedSlot = slot.number);
  }

  String _floorLabel(int floor) => switch (floor) {
    0 => '1st Floor',
    1 => '2nd Floor',
    2 => '3rd Floor',
    _ => 'Floor ${floor + 1}',
  };

  String _slotLabel(int number, int floor) {
    final prefix = String.fromCharCode('A'.codeUnitAt(0) + floor);
    return '$prefix-${number.toString().padLeft(2, '0')}';
  }
}

class _ParkingSpot extends StatelessWidget {
  const _ParkingSpot({
    required this.number,
    required this.floor,
    required this.status,
    required this.onTap,
  });

  final int number;
  final int floor;
  final SlotStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final available = status == SlotStatus.available;
    final selected = status == SlotStatus.selected;
    final occupied = status == SlotStatus.occupied;
    final fill = selected
        ? AppTheme.powderBlue
        : available
        ? const Color(0xFFF9FBFD)
        : occupied
        ? AppTheme.peach
        : const Color(0xFFEDEFF5);
    final border = selected
        ? const Color(0xFF2875F0)
        : available
        ? const Color(0xFFD3DCE6)
        : occupied
        ? const Color(0xFFE8B9A0)
        : const Color(0xFFCCD3DC);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: available || selected ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 7),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: selected ? 1.7 : 1.2),
          ),
          child: occupied
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.directions_car_filled_rounded,
                      color: Color(0xFF42A5F5),
                      size: 40,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selected
                          ? 'Selected'
                          : available
                          ? 'Available'
                          : 'Unavailable',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String get _label {
    final prefix = String.fromCharCode('A'.codeUnitAt(0) + floor);
    return '$prefix-${number.toString().padLeft(2, '0')}';
  }
}

class _DriveLane extends StatelessWidget {
  const _DriveLane();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 2, height: 18, color: const Color(0xFFDCE2E9)),
          const Icon(
            Icons.keyboard_arrow_down,
            size: 20,
            color: Color(0xFF98A6B5),
          ),
          Container(width: 2, height: 18, color: const Color(0xFFDCE2E9)),
        ],
      ),
    );
  }
}

class _SlotLegend extends StatelessWidget {
  const _SlotLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
