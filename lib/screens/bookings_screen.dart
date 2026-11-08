import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:parkgrid/core/constants/app_enums.dart';
import 'package:parkgrid/core/widgets/status_badge.dart';
import 'package:parkgrid/models/booking.dart';
import 'package:parkgrid/providers/app_state.dart';
import 'package:provider/provider.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isAdmin = appState.isAdmin;
    final bookings =
        (isAdmin ? appState.bookings : appState.bookingsForCurrentUser())
            .toList()
          ..sort((a, b) => b.startDateTime.compareTo(a.startDateTime));

    final upcoming = bookings
        .where((booking) {
          return _effectiveStatus(booking) == BookingStatus.upcoming;
        })
        .toList(growable: false);
    final past = bookings
        .where((booking) {
          return _effectiveStatus(booking) != BookingStatus.upcoming;
        })
        .toList(growable: false);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            isAdmin ? 'All Bookings' : 'My Bookings',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
          ),
          if (isAdmin) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _showCreateAdminBookingDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add booking for customer'),
            ),
          ],
          const SizedBox(height: 12),
          if (bookings.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.local_parking_outlined, size: 48),
                    const SizedBox(height: 10),
                    Text(
                      isAdmin ? 'No bookings yet' : 'No bookings yet',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isAdmin
                          ? 'Add a booking here or make a reservation from Explore.'
                          : 'Reserve a slot from Home or Explore to see it here.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          if (upcoming.isNotEmpty) ...[
            const Text(
              'Upcoming',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...upcoming.map((booking) => _BookingCard(booking: booking)),
            const SizedBox(height: 12),
          ],
          if (past.isNotEmpty) ...[
            const Text('Past', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...past.map((booking) => _BookingCard(booking: booking)),
          ],
        ],
      ),
    );
  }

  BookingStatus _effectiveStatus(Booking booking) {
    if (booking.status == BookingStatus.cancelled) {
      return BookingStatus.cancelled;
    }
    if (DateTime.now().isAfter(booking.endDateTime)) {
      return BookingStatus.completed;
    }
    return BookingStatus.upcoming;
  }
}

Future<void> _showCreateAdminBookingDialog(BuildContext context) async {
  final appState = context.read<AppState>();
  if (!appState.isAdmin) {
    return;
  }

  final customers = appState.customerAccounts;
  final locations = appState.parkingLocations;
  if (customers.isEmpty || locations.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add a customer and parking location first.'),
      ),
    );
    return;
  }

  final formKey = GlobalKey<FormState>();
  final vehicleCtrl = TextEditingController();
  var customerId = customers.first.id;
  var parkingId = locations.first.id;
  var selectedSlotNumber = locations.first.slots
      .where((slot) => slot.status == SlotStatus.available)
      .firstOrNull
      ?.number;
  final initialStart = DateTime.now().add(const Duration(hours: 2));
  var startDateTime = DateTime(
    initialStart.year,
    initialStart.month,
    initialStart.day,
    initialStart.hour,
  );
  var durationHours = 2;
  var paymentMethod = PaymentMethod.upi;
  String? submissionError;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final selectedLocation = locations.firstWhere(
            (location) => location.id == parkingId,
          );
          final availableSlots = selectedLocation.slots
              .where((slot) => slot.status == SlotStatus.available)
              .toList(growable: false);

          return AlertDialog(
            title: const Text('Create customer booking'),
            content: SizedBox(
              width: 440,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: customerId,
                        decoration: const InputDecoration(
                          labelText: 'Customer',
                        ),
                        items: customers
                            .map(
                              (customer) => DropdownMenuItem(
                                value: customer.id,
                                child: Text(customer.name),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => customerId = value);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: parkingId,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                        ),
                        items: locations
                            .map(
                              (location) => DropdownMenuItem(
                                value: location.id,
                                child: Text(location.name),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          final nextLocation = locations.firstWhere(
                            (location) => location.id == value,
                          );
                          setDialogState(() {
                            parkingId = value;
                            selectedSlotNumber = nextLocation.slots
                                .where(
                                  (slot) => slot.status == SlotStatus.available,
                                )
                                .firstOrNull
                                ?.number;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        initialValue:
                            availableSlots.any(
                              (slot) => slot.number == selectedSlotNumber,
                            )
                            ? selectedSlotNumber
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Available slot',
                        ),
                        items: availableSlots
                            .map(
                              (slot) => DropdownMenuItem(
                                value: slot.number,
                                child: Text('Slot #${slot.number}'),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: availableSlots.isEmpty
                            ? null
                            : (value) {
                                setDialogState(
                                  () => selectedSlotNumber = value,
                                );
                              },
                      ),
                      if (availableSlots.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text('This location has no available slots.'),
                        ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: vehicleCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle number',
                          hintText: 'For example, KA 01 AB 1234',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Enter a vehicle number.'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: dialogContext,
                                  initialDate: startDateTime,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                );
                                if (picked != null && dialogContext.mounted) {
                                  setDialogState(() {
                                    startDateTime = DateTime(
                                      picked.year,
                                      picked.month,
                                      picked.day,
                                      startDateTime.hour,
                                      startDateTime.minute,
                                    );
                                  });
                                }
                              },
                              icon: const Icon(Icons.calendar_month_outlined),
                              label: Text(
                                DateFormat('dd MMM yyyy').format(startDateTime),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: dialogContext,
                                  initialTime: TimeOfDay.fromDateTime(
                                    startDateTime,
                                  ),
                                );
                                if (picked != null && dialogContext.mounted) {
                                  setDialogState(() {
                                    startDateTime = DateTime(
                                      startDateTime.year,
                                      startDateTime.month,
                                      startDateTime.day,
                                      picked.hour,
                                      picked.minute,
                                    );
                                  });
                                }
                              },
                              icon: const Icon(Icons.schedule_outlined),
                              label: Text(
                                TimeOfDay.fromDateTime(startDateTime)
                                    .format(dialogContext),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        initialValue: durationHours,
                        decoration: const InputDecoration(
                          labelText: 'Duration',
                        ),
                        items: List.generate(12, (index) => index + 1)
                            .map(
                              (hours) => DropdownMenuItem(
                                value: hours,
                                child: Text(
                                  '$hours hour${hours == 1 ? '' : 's'}',
                                ),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => durationHours = value);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<PaymentMethod>(
                        initialValue: paymentMethod,
                        decoration: const InputDecoration(
                          labelText: 'Payment method',
                        ),
                        items: PaymentMethod.values
                            .map(
                              (method) => DropdownMenuItem(
                                value: method,
                                child: Text(method.label),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => paymentMethod = value);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Estimated total: ₹${(selectedLocation.hourlyRate * durationHours).toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (submissionError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          submissionError!,
                          style: TextStyle(
                            color: Theme.of(dialogContext).colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) {
                    return;
                  }
                  if (selectedSlotNumber == null) {
                    setDialogState(() {
                      submissionError =
                          'Add an available slot before creating a booking.';
                    });
                    return;
                  }

                  final result = await appState.createAdminBooking(
                    userId: customerId,
                    parkingId: parkingId,
                    slotNumber: selectedSlotNumber!,
                    startDateTime: startDateTime,
                    durationHours: durationHours,
                    vehicleNumber: vehicleCtrl.text,
                    paymentMethod: paymentMethod,
                  );
                  if (!dialogContext.mounted) {
                    return;
                  }
                  if (!result.success) {
                    setDialogState(() => submissionError = result.message);
                    return;
                  }

                  Navigator.of(dialogContext).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(result.message)));
                  }
                },
                icon: const Icon(Icons.check),
                label: const Text('Create booking'),
              ),
            ],
          );
        },
      );
    },
  );

  vehicleCtrl.dispose();
}

class _BookingCard extends StatefulWidget {
  const _BookingCard({required this.booking});

  final Booking booking;

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _startClockIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _BookingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.booking.id != widget.booking.id ||
        oldWidget.booking.status != widget.booking.status ||
        oldWidget.booking.endDateTime != widget.booking.endDateTime) {
      _clock?.cancel();
      _clock = null;
      _startClockIfNeeded();
    }
  }

  void _startClockIfNeeded() {
    if (_clock != null ||
        widget.booking.status == BookingStatus.cancelled ||
        !DateTime.now().isBefore(widget.booking.endDateTime)) {
      return;
    }
    _clock = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (widget.booking.status == BookingStatus.cancelled ||
          !DateTime.now().isBefore(widget.booking.endDateTime)) {
        timer.cancel();
        _clock = null;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final appState = context.read<AppState>();
    final isAdmin = appState.isAdmin;
    final now = DateTime.now();
    final effectiveStatus = booking.status == BookingStatus.cancelled
        ? BookingStatus.cancelled
        : now.isAfter(booking.endDateTime)
        ? BookingStatus.completed
        : BookingStatus.upcoming;
    final isActive =
        !now.isBefore(booking.startDateTime) &&
        now.isBefore(booking.endDateTime) &&
        booking.status != BookingStatus.cancelled;
    final countdown = isActive
        ? booking.endDateTime.difference(now)
        : booking.startDateTime.difference(now);
    final totalDuration = booking.endDateTime.difference(booking.startDateTime);
    final warning =
        isActive &&
        (countdown <= const Duration(minutes: 15) ||
            countdown.inSeconds <= totalDuration.inSeconds ~/ 5);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.parkingName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                StatusBadge(status: effectiveStatus),
              ],
            ),
            if (effectiveStatus == BookingStatus.upcoming) ...[
              const SizedBox(height: 10),
              _ExpiryBanner(
                remaining: countdown.isNegative ? Duration.zero : countdown,
                isActive: isActive,
                warning: warning,
                progress: isActive && totalDuration.inSeconds > 0
                    ? (countdown.inSeconds / totalDuration.inSeconds).clamp(
                        0.0,
                        1.0,
                      )
                    : null,
              ),
              const SizedBox(height: 8),
            ],
            Text('Booking ID: ${booking.id}'),
            if (isAdmin)
              Text(
                'Customer: ${appState.accountById(booking.userId)?.name ?? 'Unknown customer'}',
              ),
            Text('Slot: #${booking.slotNumber}'),
            Text(
              'Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(booking.startDateTime)}',
            ),
            Text('Duration: ${booking.durationHours} hour(s)'),
            Text('Price: ₹${booking.totalPrice.toStringAsFixed(0)}'),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Booking Details'),
                          content: Text(
                            '${isAdmin ? 'Customer: ${appState.accountById(booking.userId)?.name ?? 'Unknown customer'}\n' : ''}'
                            'Location: ${booking.parkingName}\n'
                            'Slot: ${booking.slotNumber}\n'
                            'Vehicle: ${booking.vehicleNumber}\n'
                            'Payment: ${booking.paymentMethod.label}\n'
                            'Reference: ${booking.id}',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('View'),
                ),
                const SizedBox(width: 8),
                if (effectiveStatus == BookingStatus.upcoming)
                  TextButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Cancel Booking?'),
                            content: const Text(
                              'This will release the slot back to availability.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('No'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Yes, Cancel'),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirm != true) {
                        return;
                      }

                      final ok = await appState.cancelBooking(booking.id);
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Booking cancelled successfully.'
                                : 'Unable to cancel this booking.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpiryBanner extends StatelessWidget {
  const _ExpiryBanner({
    required this.remaining,
    required this.isActive,
    required this.warning,
    required this.progress,
  });

  final Duration remaining;
  final bool isActive;
  final bool warning;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final color = warning ? const Color(0xFFB54732) : const Color(0xFF315D7D);
    final background = warning
        ? const Color(0xFFFBE4D8)
        : const Color(0xFFDCEBFA);
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: warning
            ? Border.all(color: color.withValues(alpha: .35))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                warning ? Icons.warning_amber_rounded : Icons.timer_outlined,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${isActive ? 'Parking expires in' : 'Parking starts in'} '
                  '${_durationLabel(remaining)}',
                  style: TextStyle(fontWeight: FontWeight.w700, color: color),
                ),
              ),
              if (warning)
                const Text('Ending soon', style: TextStyle(fontSize: 11)),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.white,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _durationLabel(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')} minutes';
  }
}
