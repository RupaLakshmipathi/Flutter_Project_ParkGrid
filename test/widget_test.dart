import 'package:flutter_test/flutter_test.dart';
import 'package:parkgrid/core/app.dart';
import 'package:parkgrid/services/storage_service.dart';

void main() {
  testWidgets('ParkGrid opens on the welcome screen', (tester) async {
    await tester.pumpWidget(
      ParkGridRoot(storageService: InMemoryStorageService()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your next parking spot is closer.'), findsOneWidget);
  });
}
