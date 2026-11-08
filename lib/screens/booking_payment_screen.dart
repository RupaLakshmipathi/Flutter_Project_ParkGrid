import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:parkgrid/core/constants/app_enums.dart';
import 'package:parkgrid/core/theme/app_theme.dart';
import 'package:parkgrid/core/widgets/pastel_button.dart';
import 'package:parkgrid/providers/app_state.dart';
import 'package:parkgrid/services/booking_logic.dart';
import 'package:provider/provider.dart';

class BookingScreenArgs {
  const BookingScreenArgs({required this.parkingId, required this.slotNumber});

  final String parkingId;
  final int slotNumber;
}

class BookingPaymentScreen extends StatefulWidget {
  const BookingPaymentScreen({super.key, required this.args});

  final BookingScreenArgs args;

  @override
  State<BookingPaymentScreen> createState() => _BookingPaymentScreenState();
}

class _BookingPaymentScreenState extends State<BookingPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleCtrl = TextEditingController();

  DateTime? _date;
  TimeOfDay? _time;
  int _durationHours = 2;
  PaymentMethod _paymentMethod = PaymentMethod.upi;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().add(const Duration(hours: 1));
    _date = DateTime(now.year, now.month, now.day);
    _time = TimeOfDay(hour: now.hour, minute: 0);
  }

  @override
  void dispose() {
    _vehicleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final parking = appState.parkingById(widget.args.parkingId);

    if (parking == null) {
      return const Scaffold(body: Center(child: Text('Parking not found.')));
    }

    final price = BookingLogic.calculatePrice(
      hourlyRate: parking.hourlyRate,
      durationHours: _durationHours,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Booking & Payment')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionCard(
              title: 'Booking Details',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    parking.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text('Slot #${widget.args.slotNumber}'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_today_outlined),
                          label: Text(
                            _date == null
                                ? 'Select Date'
                                : DateFormat('EEE, dd MMM').format(_date!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickTime,
                          icon: const Icon(Icons.access_time),
                          label: Text(
                            _time == null
                                ? 'Select Time'
                                : _time!.format(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: _durationHours,
                    decoration: const InputDecoration(
                      labelText: 'Duration (hours)',
                    ),
                    items: List.generate(
                      12,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1} hour(s)'),
                      ),
                    ),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _durationHours = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _vehicleCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Registration Number',
                      hintText: 'KA01AB1234',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length < 6) {
                        return 'Enter a valid vehicle number';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _SectionCard(
              title: 'Demo Payment',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select payment mode'),
                  const SizedBox(height: 8),
                  SegmentedButton<PaymentMethod>(
                    segments: PaymentMethod.values
                        .map(
                          (method) => ButtonSegment(
                            value: method,
                            label: Text(method.label),
                          ),
                        )
                        .toList(growable: false),
                    selected: {_paymentMethod},
                    onSelectionChanged: (value) {
                      setState(() {
                        _paymentMethod = value.first;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This is a safe demo payment flow. No real card or wallet details are collected.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _SectionCard(
              title: 'Booking Summary',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _summaryRow('Location', parking.name),
                  _summaryRow('Slot', '#${widget.args.slotNumber}'),
                  _summaryRow('Duration', '$_durationHours hour(s)'),
                  _summaryRow(
                    'Rate',
                    '₹${parking.hourlyRate.toStringAsFixed(0)}/hr',
                  ),
                  const Divider(height: 18),
                  _summaryRow(
                    'Total',
                    '₹${price.toStringAsFixed(0)}',
                    bold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PastelButton(
              label: appState.busy ? 'Processing...' : 'Confirm Booking',
              icon: Icons.check_circle_outline,
              expanded: true,
              onPressed: appState.busy ? null : () => _confirmBooking(context),
            ),
            if (appState.busy)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 120)),
      initialDate: _date ?? now,
    );

    if (picked != null) {
      setState(() {
        _date = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _time = picked;
      });
    }
  }

  Future<void> _confirmBooking(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_date == null || _time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select date and time to continue.')),
      );
      return;
    }

    final startDateTime = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    );

    if (startDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking must be in the future.')),
      );
      return;
    }

    final appState = context.read<AppState>();
    final result = await appState.createBooking(
      parkingId: widget.args.parkingId,
      slotNumber: widget.args.slotNumber,
      startDateTime: startDateTime,
      durationHours: _durationHours,
      vehicleNumber: _vehicleCtrl.text,
      paymentMethod: _paymentMethod,
    );

    if (!mounted) {
      return;
    }

    if (result.success) {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            icon: const Icon(Icons.check_circle, color: AppTheme.primaryText),
            title: const Text('Booking Successful'),
            content: Text(result.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Great!'),
              ),
            ],
          );
        },
      );
      if (mounted) {
        Navigator.of(context)
            .popUntil((route) => route.settings.name == '/home');
      }
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(result.message)));
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    final textStyle = TextStyle(
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      fontSize: bold ? 15 : 14,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: textStyle)),
          Text(value, style: textStyle),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
