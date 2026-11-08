import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:parkgrid/core/theme/app_theme.dart';
import 'package:parkgrid/providers/app_state.dart';
import 'package:parkgrid/screens/booking_payment_screen.dart';
import 'package:parkgrid/screens/home_screen.dart';
import 'package:parkgrid/screens/landing_screen.dart';
import 'package:parkgrid/screens/parking_details_screen.dart';
import 'package:parkgrid/screens/slot_selection_screen.dart';
import 'package:parkgrid/screens/splash_login_screen.dart';
import 'package:parkgrid/services/storage_service.dart';
import 'package:provider/provider.dart';

class ParkGridRoot extends StatefulWidget {
  const ParkGridRoot({super.key, this.storageService});

  final StorageService? storageService;

  @override
  State<ParkGridRoot> createState() => _ParkGridRootState();
}

class _ParkGridRootState extends State<ParkGridRoot> {
  late final AppState _appState;
  late final Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _appState = AppState(
      storageService: widget.storageService ?? HiveStorageService(),
    );
    _initialization = _initialize();
  }

  Future<void> _initialize() async {
    if (widget.storageService == null) {
      await Hive.initFlutter();
    }
    await _appState.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _appState,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ParkGrid',
        theme: AppTheme.build(),
        routes: const <String, WidgetBuilder>{},
        initialRoute: '/',
        home: FutureBuilder<void>(
          future: _initialization,
          builder: (context, snapshot) {
            final appState = context.read<AppState>();
            if (snapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'ParkGrid could not start.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }

            if (snapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return appState.currentUser == null
                ? const LandingScreen()
                : const HomeScreen();
          },
        ),
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/auth':
              return _fadeRoute(const SplashLoginScreen(), settings);
            case '/home':
              return _fadeRoute(const HomeScreen(), settings);
            case '/details':
              final parkingId = settings.arguments as String;
              return _fadeRoute(
                ParkingDetailsScreen(parkingId: parkingId),
                settings,
              );
            case '/slots':
              final parkingId = settings.arguments as String;
              return _fadeRoute(
                SlotSelectionScreen(parkingId: parkingId),
                settings,
              );
            case '/booking':
              final args = settings.arguments as BookingScreenArgs;
              return _fadeRoute(BookingPaymentScreen(args: args), settings);
            default:
              return _fadeRoute(const SplashLoginScreen(), settings);
          }
        },
      ),
    );
  }

  PageRouteBuilder<dynamic> _fadeRoute(Widget child, RouteSettings settings) {
    return PageRouteBuilder<dynamic>(
      settings: settings,
      pageBuilder: (_, _, _) => child,
      transitionsBuilder: (_, animation, _, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 280),
    );
  }
}
