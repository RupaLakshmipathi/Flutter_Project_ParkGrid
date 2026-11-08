import 'package:flutter/material.dart';
import 'package:parkgrid/core/constants/app_enums.dart';
import 'package:parkgrid/core/widgets/parking_card.dart';
import 'package:parkgrid/models/parking_location.dart';
import 'package:parkgrid/providers/app_state.dart';
import 'package:provider/provider.dart';

enum ExploreSort {
  bestMatch,
  priceLowToHigh,
  priceHighToLow,
  distance,
  availability,
}

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  ParkingCategory _category = ParkingCategory.all;
  ExploreSort _sort = ExploreSort.bestMatch;
  RangeValues _priceRange = const RangeValues(20, 120);
  bool _mapView = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final items = _applyFilters(appState.parkingLocations);
    final bestMatch = _bestMatch(items);
    final bestReason = bestMatch == null
        ? null
        : _reasonFor(bestMatch, appState.parkingLocations);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Search parking spots',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      onPressed: () {
                        setState(() {
                          _mapView = !_mapView;
                        });
                      },
                      icon: Icon(_mapView ? Icons.list : Icons.map_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<ParkingCategory>(
                        initialValue: _category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        items: ParkingCategory.values
                            .map(
                              (category) => DropdownMenuItem(
                                value: category,
                                child: Text(category.label),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _category = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<ExploreSort>(
                        initialValue: _sort,
                        decoration: const InputDecoration(labelText: 'Sort By'),
                        items: const [
                          DropdownMenuItem(
                            value: ExploreSort.bestMatch,
                            child: Text('Best match'),
                          ),
                          DropdownMenuItem(
                            value: ExploreSort.availability,
                            child: Text('Availability'),
                          ),
                          DropdownMenuItem(
                            value: ExploreSort.priceLowToHigh,
                            child: Text('Price: Low to High'),
                          ),
                          DropdownMenuItem(
                            value: ExploreSort.priceHighToLow,
                            child: Text('Price: High to Low'),
                          ),
                          DropdownMenuItem(
                            value: ExploreSort.distance,
                            child: Text('Distance: Nearest'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _sort = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price range: ₹${_priceRange.start.round()} - ₹${_priceRange.end.round()} / hr',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    RangeSlider(
                      values: _priceRange,
                      min: 20,
                      max: 150,
                      divisions: 13,
                      labels: RangeLabels(
                        _priceRange.start.round().toString(),
                        _priceRange.end.round().toString(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _priceRange = value;
                        });
                      },
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _searchCtrl.clear();
                        _category = ParkingCategory.all;
                        _sort = ExploreSort.bestMatch;
                        _priceRange = const RangeValues(20, 120);
                      });
                    },
                    icon: const Icon(Icons.filter_alt_off),
                    label: const Text('Clear filters'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? _EmptySearch(
                    onReset: () {
                      setState(() {
                        _searchCtrl.clear();
                        _category = ParkingCategory.all;
                        _priceRange = const RangeValues(20, 120);
                      });
                    },
                  )
                : _mapView
                ? _DemoMapView(
                    items: items,
                    bestMatchId: bestMatch?.id,
                    bestMatchReason: bestReason,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemBuilder: (context, index) {
                      final location = items[index];
                      return ParkingCard(
                        location: location,
                        isBestMatch: location.id == bestMatch?.id,
                        recommendationReason: location.id == bestMatch?.id
                            ? bestReason
                            : null,
                        isFavorite: appState.isFavorite(location.id),
                        onFavoriteToggle: () =>
                            appState.toggleFavorite(location.id),
                        onTap: () {
                          Navigator.of(context)
                              .pushNamed('/details', arguments: location.id);
                        },
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemCount: items.length,
                  ),
          ),
        ],
      ),
    );
  }

  List<ParkingLocation> _applyFilters(List<ParkingLocation> source) {
    final query = _searchCtrl.text.trim().toLowerCase();
    final result = source
        .where((location) {
          final categoryMatches =
              _category == ParkingCategory.all ||
              location.category == _category;
          final queryMatches =
              query.isEmpty ||
              location.name.toLowerCase().contains(query) ||
              location.address.toLowerCase().contains(query);
          final priceMatches =
              location.hourlyRate >= _priceRange.start &&
              location.hourlyRate <= _priceRange.end;

          return categoryMatches && queryMatches && priceMatches;
        })
        .toList(growable: false);

    final best = _bestMatch(result);
    result.sort((a, b) {
      switch (_sort) {
        case ExploreSort.bestMatch:
          if (a.id == best?.id) return -1;
          if (b.id == best?.id) return 1;
          final score = _matchScore(b).compareTo(_matchScore(a));
          return score != 0 ? score : a.hourlyRate.compareTo(b.hourlyRate);
        case ExploreSort.priceLowToHigh:
          return a.hourlyRate.compareTo(b.hourlyRate);
        case ExploreSort.priceHighToLow:
          return b.hourlyRate.compareTo(a.hourlyRate);
        case ExploreSort.distance:
          return a.distanceKm.compareTo(b.distanceKm);
        case ExploreSort.availability:
          return b.availableSlots.compareTo(a.availableSlots);
      }
    });

    return result;
  }

  ParkingLocation? _bestMatch(List<ParkingLocation> locations) {
    final available = locations
        .where((location) => location.availableSlots > 0)
        .toList(growable: false);
    if (available.isEmpty) return null;
    return available.reduce((best, candidate) {
      final comparison = _matchScore(candidate).compareTo(_matchScore(best));
      if (comparison > 0) return candidate;
      if (comparison == 0 && candidate.availableSlots > best.availableSlots) {
        return candidate;
      }
      return best;
    });
  }

  double _matchScore(ParkingLocation location) {
    if (location.availableSlots == 0) return 0;
    final locations = context
        .read<AppState>()
        .parkingLocations
        .where((item) => item.availableSlots > 0)
        .toList(growable: false);
    if (locations.isEmpty) return 0;
    final lowestPrice = locations
        .map((item) => item.hourlyRate)
        .reduce((a, b) => a < b ? a : b);
    final shortestDistance = locations
        .map((item) => item.distanceKm)
        .reduce((a, b) => a < b ? a : b);
    final mostSlots = locations
        .map((item) => item.availableSlots)
        .reduce((a, b) => a > b ? a : b);
    final priceScore = lowestPrice / location.hourlyRate;
    final distanceScore = location.distanceKm <= 0
        ? 1.0
        : shortestDistance / location.distanceKm;
    final availabilityScore = mostSlots == 0
        ? 0.0
        : location.availableSlots / mostSlots;
    return (priceScore + distanceScore + availabilityScore) / 3;
  }

  String _reasonFor(ParkingLocation location, List<ParkingLocation> locations) {
    final available = locations
        .where((item) => item.availableSlots > 0)
        .toList(growable: false);
    final lowestPrice = available
        .map((item) => item.hourlyRate)
        .reduce((a, b) => a < b ? a : b);
    final shortestDistance = available
        .map((item) => item.distanceKm)
        .reduce((a, b) => a < b ? a : b);
    final mostSlots = available
        .map((item) => item.availableSlots)
        .reduce((a, b) => a > b ? a : b);
    final strengths = <(double, String)>[
      (lowestPrice / location.hourlyRate, 'Lowest price'),
      (
        location.distanceKm <= 0 ? 1.0 : shortestDistance / location.distanceKm,
        'Shortest distance',
      ),
      (
        mostSlots == 0 ? 0 : location.availableSlots / mostSlots,
        'More slots available',
      ),
    ]..sort((a, b) => b.$1.compareTo(a.$1));
    return strengths.first.$2;
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 52),
            const SizedBox(height: 8),
            const Text(
              'No parking locations found.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text('Try another filter combination or clear filters.'),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoMapView extends StatelessWidget {
  const _DemoMapView({
    required this.items,
    required this.bestMatchId,
    required this.bestMatchReason,
  });

  final List<ParkingLocation> items;
  final String? bestMatchId;
  final String? bestMatchReason;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final location = items[index];
        final isBestMatch = location.id == bestMatchId;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCEBFA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.place_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(location.address),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 5,
                        children: [
                          Text(
                            '₹${location.hourlyRate.toStringAsFixed(0)}/hr',
                            style: const TextStyle(fontSize: 11),
                          ),
                          Text(
                            '~${location.distanceKm.toStringAsFixed(1)} km',
                            style: const TextStyle(fontSize: 11),
                          ),
                          Text(
                            '${location.availableSlots} free',
                            style: const TextStyle(fontSize: 11),
                          ),
                          if (isBestMatch)
                            const Text(
                              'Best Match',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF17633D),
                              ),
                            ),
                          if (isBestMatch && bestMatchReason != null)
                            Text(
                              bestMatchReason!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF7B5B08),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context)
                        .pushNamed('/details', arguments: location.id);
                  },
                  child: const Text('View'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
