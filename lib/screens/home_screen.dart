import 'package:flutter/material.dart';
import 'package:parkgrid/core/constants/app_enums.dart';
import 'package:parkgrid/core/theme/app_theme.dart';
import 'package:parkgrid/core/widgets/parking_card.dart';
import 'package:parkgrid/core/widgets/pastel_button.dart';
import 'package:parkgrid/models/parking_location.dart';
import 'package:parkgrid/providers/app_state.dart';
import 'package:parkgrid/screens/bookings_screen.dart';
import 'package:parkgrid/screens/explore_screen.dart';
import 'package:parkgrid/screens/profile_admin_screen.dart';
import 'package:provider/provider.dart';

typedef _HomeScreenState = HomeScreenState;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  void selectTab(int index) {
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (appState.isAdmin) {
      return Scaffold(body: AdminDashboardScreen(appState: appState));
    }
    final pages = [
      const _DashboardTab(),
      const ExploreScreen(),
      const BookingsScreen(),
      const ProfileAdminScreen(),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(key: ValueKey(_index), child: pages[_index]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() {
            _index = value;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  final _searchCtrl = TextEditingController();
  ParkingCategory _category = ParkingCategory.all;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;

    final filtered = _filterList(appState.parkingLocations);

    final upcoming = appState.upcomingBookingForCurrentUser();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi ${user?.name.split(' ').first ?? 'Driver'},',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const Text('Let us find your perfect parking spot.'),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No new notifications.')),
                    );
                  },
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search location or parking name',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ParkingCategory.values
                  .map((category) {
                    return ChoiceChip(
                      label: Text(category.label),
                      selected: _category == category,
                      onSelected: (_) {
                        setState(() {
                          _category = category;
                        });
                      },
                    );
                  })
                  .toList(growable: false),
            ),
            const SizedBox(height: 14),
            if (upcoming != null)
              Card(
                color: AppTheme.lavender.withValues(alpha: 0.45),
                child: ListTile(
                  leading: const Icon(Icons.event_available),
                  title: Text('Upcoming: ${upcoming.parkingName}'),
                  subtitle: Text(
                    'Slot ${upcoming.slotNumber} • ${upcoming.durationHours}h',
                  ),
                ),
              ),
            const SizedBox(height: 10),
            PastelButton(
              label: 'Find Parking',
              icon: Icons.near_me_rounded,
              expanded: true,
              onPressed: () {
                final state = context
                    .findAncestorStateOfType<_HomeScreenState>();
                state?.setState(() {
                  state._index = 1;
                });
              },
            ),
            const SizedBox(height: 18),
            const Text(
              'Nearby Parking',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 10),
            if (filtered.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No parking results for your filters.'),
                ),
              )
            else
              ...filtered.map((location) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ParkingCard(
                    location: location,
                    isFavorite: appState.isFavorite(location.id),
                    onFavoriteToggle: () =>
                        appState.toggleFavorite(location.id),
                    onTap: () {
                      Navigator.of(context)
                          .pushNamed('/details', arguments: location.id);
                    },
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  List<ParkingLocation> _filterList(List<ParkingLocation> source) {
    final query = _searchCtrl.text.trim().toLowerCase();
    return source
        .where((location) {
          final categoryMatches =
              _category == ParkingCategory.all ||
              location.category == _category;
          final queryMatches =
              query.isEmpty ||
              location.name.toLowerCase().contains(query) ||
              location.address.toLowerCase().contains(query);
          return categoryMatches && queryMatches;
        })
        .toList(growable: false);
  }
}
