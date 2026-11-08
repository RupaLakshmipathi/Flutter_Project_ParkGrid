import 'package:flutter/material.dart';
import 'package:parkgrid/models/parking_location.dart';

class ParkingCard extends StatelessWidget {
  const ParkingCard({
    super.key,
    required this.location,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onTap,
    this.isBestMatch = false,
    this.recommendationReason,
  });

  final ParkingLocation location;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTap;
  final bool isBestMatch;
  final String? recommendationReason;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFDCEBFA), Color(0xFFE8E0FA)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        location.imageEmoji,
                        style: const TextStyle(fontSize: 24),
                      ),
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
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          location.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onFavoriteToggle,
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? const Color(0xFFB76D59) : Colors.grey,
                    ),
                  ),
                ],
              ),
              if (isBestMatch || recommendationReason != null) ...[
                const SizedBox(height: 9),
                Wrap(
                  spacing: 7,
                  runSpacing: 6,
                  children: [
                    if (isBestMatch)
                      _pill('Best Match', color: const Color(0xFFD9F1E6)),
                    if (recommendationReason != null)
                      _pill(
                        recommendationReason!,
                        color: const Color(0xFFFFF0C9),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _pill('₹${location.hourlyRate.toStringAsFixed(0)}/hr'),
                  _pill('~${location.distanceKm.toStringAsFixed(1)} km away'),
                  _pill('${location.availableSlots} slots free'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String text, {Color color = const Color(0xFFE8E0FA)}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
