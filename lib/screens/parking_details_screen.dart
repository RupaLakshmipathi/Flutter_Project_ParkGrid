import 'package:flutter/material.dart';
import 'package:parkgrid/core/theme/app_theme.dart';
import 'package:parkgrid/core/widgets/pastel_button.dart';
import 'package:parkgrid/providers/app_state.dart';
import 'package:provider/provider.dart';

class ParkingDetailsScreen extends StatelessWidget {
  const ParkingDetailsScreen({super.key, required this.parkingId});

  final String parkingId;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final parking = appState.parkingById(parkingId);

    if (parking == null) {
      return const Scaffold(body: Center(child: Text('Parking not found.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Details'),
        actions: [
          IconButton(
            onPressed: () => appState.toggleFavorite(parking.id),
            icon: Icon(
              appState.isFavorite(parking.id)
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: appState.isFavorite(parking.id) ? AppTheme.peach : null,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 170,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.powderBlue, AppTheme.lavender],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: Text(
                parking.imageEmoji,
                style: const TextStyle(fontSize: 72),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(parking.name, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(parking.address),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('₹${parking.hourlyRate.toStringAsFixed(0)}/hour'),
              _chip(parking.openingHours),
              _chip('${parking.totalSlots} total slots'),
              _chip('${parking.availableSlots} available now'),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Amenities',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          const SizedBox(height: 8),
          ...parking.amenities.map(
            (amenity) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(amenity),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          PastelButton(
            label: 'Select Parking Slot',
            icon: Icons.grid_view_rounded,
            onPressed: () {
              Navigator.of(context).pushNamed('/slots', arguments: parking.id);
            },
            expanded: true,
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.lavender,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
