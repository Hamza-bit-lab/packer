import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pack_and_carry/core/models/booking.dart';
import 'package:pack_and_carry/core/models/good.dart';
import 'package:pack_and_carry/core/models/trip.dart';
import 'package:pack_and_carry/core/models/user.dart';
import 'package:pack_and_carry/core/providers/preferences_provider.dart';
import 'package:pack_and_carry/core/services/world_data_service.dart';
import 'package:pack_and_carry/core/widgets/city_field.dart';
import 'package:pack_and_carry/core/widgets/country_field.dart';
import 'package:pack_and_carry/features/auth/providers/auth_provider.dart';
import 'package:pack_and_carry/features/auth/screens/verify_email_screen.dart';
import 'package:pack_and_carry/features/bookings/widgets/booking_card.dart';
import 'package:pack_and_carry/features/feed/screens/trip_comparison_screen.dart';
import 'package:pack_and_carry/features/feed/widgets/good_card.dart';
import 'package:pack_and_carry/features/feed/widgets/trip_card.dart';
import 'package:pack_and_carry/features/shell/screens/main_shell.dart';

User _user({bool verified = false, int completedDeliveries = 0, int id = 1}) => User(
      id: id,
      name: 'Jamie Traveler',
      profilePicUrl: null,
      averageRating: 4.5,
      totalReviews: 12,
      completedDeliveriesCount: completedDeliveries,
      emailVerified: verified,
    );

void main() {
  testWidgets('TripCard renders without layout errors, with and without actions/photo/badge', (tester) async {
    final trip = Trip(
      id: 1,
      fromCity: 'Lahore',
      toCity: 'London',
      departureDateTime: DateTime.now().add(const Duration(days: 3)),
      airlineName: 'PIA',
      maxWeightKg: 20,
      ratePerKg: 5,
      currencyType: 'USD',
      traveler: _user(verified: true),
      photoUrl: 'https://example.com/photo.jpg',
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 380,
          child: TripCard(trip: trip, onEdit: () {}, onDelete: () {}),
        ),
      ),
    ));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Jamie Traveler'), findsOneWidget);
    expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
  });

  testWidgets('GoodCard renders without layout errors, with and without actions/photo/badge', (tester) async {
    final good = Good(
      id: 1,
      fromCity: 'Dubai',
      toCity: 'Karachi',
      itemDescription: 'A small box of documents',
      weightKg: 2,
      offeredReward: 30,
      currencyType: 'USD',
      sender: _user(),
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 380,
          child: GoodCard(good: good),
        ),
      ),
    ));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('A small box of documents'), findsOneWidget);
    expect(find.byIcon(Icons.verified_rounded), findsNothing);
  });

  testWidgets('BookingCard shows the payer and the right tracking action for the traveler', (tester) async {
    final traveler = _user(id: 10, completedDeliveries: 3);
    final sender = _user(id: 20);
    final trip = Trip(
      id: 1,
      fromCity: 'Lahore',
      toCity: 'Berlin',
      departureDateTime: DateTime.now().add(const Duration(days: 3)),
      airlineName: 'PIA',
      maxWeightKg: 20,
      ratePerKg: 5,
      currencyType: 'USD',
      traveler: traveler,
      deliveryMethod: DeliveryMethod.travelerDelivers,
    );
    final good = Good(
      id: 1,
      fromCity: 'Lahore',
      toCity: 'Berlin',
      itemDescription: 'A parcel',
      weightKg: 2,
      offeredReward: 30,
      currencyType: 'USD',
      sender: sender,
    );
    final booking = Booking(
      id: 1,
      status: BookingStatus.accepted,
      estimatedCost: 10,
      payer: Payer.receiver,
      trip: trip,
      good: good,
      sender: sender,
      traveler: traveler,
      senderPhoneNumber: '+15550001111',
      travelerPhoneNumber: '+15550002222',
      inspectionConfirmedAt: null,
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 380,
          child: BookingCard(booking: booking, currentUserId: traveler.id),
        ),
      ),
    ));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Receiver pays'), findsOneWidget);
    expect(find.text('Mark In Transit'), findsOneWidget);
  });

  testWidgets('CityField loads the world dataset and suggests matches as you type', (tester) async {
    // Pre-warm the (cached, singleton) dataset outside the widget tree so the
    // field's own loading spinner — an indeterminate CircularProgressIndicator
    // — isn't still animating by the time we pumpAndSettle, which would
    // otherwise never converge.
    await tester.runAsync(() => WorldDataService.instance.loadCities());

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CityField(
          label: 'From city',
          icon: Icons.flight_takeoff_rounded,
          initialValue: '',
          onChanged: (_) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'Lond');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('London'), findsWidgets);
  });

  testWidgets('CountryField loads the country list and suggests matches as you type', (tester) async {
    await tester.runAsync(() => WorldDataService.instance.loadCountries());

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CountryField(initialValue: '', onChanged: (_) {}),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'Pakis');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Pakistan'), findsWidgets);
  });

  testWidgets('TripComparisonScreen renders multiple columns with a View & Request action', (tester) async {
    final travelerA = _user(id: 10, completedDeliveries: 3);
    final travelerB = _user(id: 11);
    final tripA = Trip(
      id: 1,
      fromCity: 'Lahore',
      toCity: 'Berlin',
      departureDateTime: DateTime.now().add(const Duration(days: 3)),
      airlineName: 'PIA',
      maxWeightKg: 20,
      ratePerKg: 5,
      currencyType: 'USD',
      traveler: travelerA,
    );
    final tripB = Trip(
      id: 2,
      fromCity: 'Lahore',
      toCity: 'Berlin',
      departureDateTime: DateTime.now().add(const Duration(days: 4)),
      airlineName: 'Emirates',
      maxWeightKg: 15,
      ratePerKg: 7,
      currencyType: 'USD',
      traveler: travelerB,
      deliveryMethod: DeliveryMethod.travelerDelivers,
    );

    await tester.pumpWidget(MaterialApp(
      home: TripComparisonScreen(trips: [tripA, tripB]),
    ));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('View & Request'), findsNWidgets(2));
  });

  testWidgets('MainShell renders all 5 tabs without a provider-scoping crash', (tester) async {
    // Regression test: NotificationProvider/InboxProvider must be readable
    // from the Scaffold built inside MainShell's own MultiProvider — using
    // the outer build() context for that Scaffold (instead of the `builder`
    // callback's inner context) throws ProviderNotFoundException at runtime,
    // which `flutter analyze` cannot catch.
    final auth = AuthProvider()
      ..status = AuthStatus.authenticated
      ..user = _user();

    // PreferencesProvider is app-level (provided in main.dart), and the
    // Settings tab reads it — so it has to be in scope here too.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<PreferencesProvider>(
            create: (_) => PreferencesProvider(),
          ),
        ],
        child: const MaterialApp(home: MainShell()),
      ),
    );
    // Not pumpAndSettle: NotificationProvider/InboxProvider poll on a Timer
    // and the screens' network calls never resolve in this offline test, so
    // nothing ever truly settles.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    // The floating pill nav bar shows icons only (no text labels), keyed by
    // tab label rather than icon — some Material icon glyphs collide across
    // "_outlined"/"_rounded" families, so matching by icon can over-count.
    const labels = ['Home', 'My Posts', 'Notifications', 'Inbox', 'Settings'];
    for (final label in labels) {
      expect(find.byKey(ValueKey('nav_tab_$label')), findsOneWidget);
    }

    // Tabs are built lazily (only the selected one mounts its screen), so
    // tap through each to actually exercise its provider access — this is
    // what the regression this test guards against needs to hit.
    for (final label in labels) {
      await tester.tap(find.byKey(ValueKey('nav_tab_$label')));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('VerifyEmailScreen renders the code field and shows the errors state', (tester) async {
    final auth = AuthProvider()
      ..status = AuthStatus.authenticated
      ..user = _user();

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: MaterialApp(home: VerifyEmailScreen(onSkip: () {})),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Verify'), findsOneWidget);
    expect(find.text('Resend code'), findsOneWidget);
    expect(find.text('Skip for now'), findsOneWidget);

    await tester.tap(find.text('Verify'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Enter the 6-digit code.'), findsOneWidget);
  });
}
