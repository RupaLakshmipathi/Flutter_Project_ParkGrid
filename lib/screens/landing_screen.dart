import 'package:flutter/material.dart';

import 'package:parkgrid/core/theme/app_theme.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _featuresController = PageController();
  int _featureIndex = 0;

  static const _features = [
    (
      icon: Icons.location_on_outlined,
      title: 'Find a nearby spot',
      body: 'Browse parking locations and see open spaces before you arrive.',
      color: AppTheme.lavender,
    ),
    (
      icon: Icons.event_available_outlined,
      title: 'Reserve in a few taps',
      body: 'Choose a location, pick an available slot, and plan your arrival.',
      color: AppTheme.peach,
    ),
    (
      icon: Icons.bookmark_border_rounded,
      title: 'Keep every booking handy',
      body: 'Your bookings stay saved on this device for your next visit.',
      color: AppTheme.butterYellow,
    ),
  ];

  @override
  void dispose() {
    _featuresController.dispose();
    super.dispose();
  }

  void _openSignIn() => Navigator.of(context).pushNamed('/auth');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.powderBlue, AppTheme.softMint, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _brandHeader(),
                    const SizedBox(height: 28),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: _intro(),
                      ),
                    ),
                    const SizedBox(height: 26),
                    _featureCarousel(),
                    const SizedBox(height: 22),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          onPressed: _openSignIn,
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text('Get started'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _openSignIn,
                          icon: const Icon(Icons.login_rounded),
                          label: const Text('I already have an account'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Citizens can start with any email and password. No email verification is required.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _brandHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.softMint,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.local_parking_rounded,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ParkGrid',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            Text('Smart parking, made easy'),
          ],
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: _openSignIn,
          icon: const Icon(Icons.person_outline),
          label: const Text('Sign in'),
        ),
      ],
    );
  }

  Widget _intro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppTheme.butterYellow,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'FIND  ·  RESERVE  ·  PARK',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Your next parking spot is closer.',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontSize: 40),
        ),
        const SizedBox(height: 12),
        const Text(
          'Find convenient parking, choose a space, and keep your plans moving.',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 16),
        const Row(
          children: [
            Icon(Icons.check_circle_outline, size: 19),
            SizedBox(width: 8),
            Expanded(
              child: Text('Simple reservations with clear slot availability'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _featureCarousel() {
    final feature = _features[_featureIndex];
    return Card(
      color: feature.color,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            SizedBox(
              height: 108,
              child: PageView.builder(
                controller: _featuresController,
                itemCount: _features.length,
                onPageChanged: (index) => setState(() => _featureIndex = index),
                itemBuilder: (context, index) {
                  final item = _features[index];
                  return Row(
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(item.icon, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(item.body),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_features.length, (index) {
                return InkWell(
                  onTap: () => _featuresController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: index == _featureIndex ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryText.withValues(
                        alpha: index == _featureIndex ? 0.72 : 0.28,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
