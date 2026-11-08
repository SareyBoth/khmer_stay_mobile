import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/app.dart';
import 'package:mobile/app/app_state.dart';
import 'package:mobile/core/mock/mock_data.dart';
import 'package:mobile/core/models/app_models.dart';
import 'package:mobile/features/owner/owner_screens.dart';
import 'package:mobile/features/startup/startup_screens.dart';
import 'package:mobile/features/traveler/traveler_detail_screens.dart';
import 'package:mobile/features/traveler/traveler_shell.dart';
import 'package:mobile/l10n/app_localizations.dart';

Widget _localizedApp({required Widget home}) => ProviderScope(
  child: MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: home,
  ),
);

Widget _routerApp(GoRouter router) => ProviderScope(
  child: MaterialApp.router(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    routerConfig: router,
  ),
);

void main() {
  testWidgets('app launches into the KhmerStay startup journey', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    expect(find.text('KhmerStay'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('onboarding advances to preference setup', (tester) async {
    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (_, _) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/setup',
          builder: (_, _) => const Scaffold(key: Key('setup-destination')),
        ),
      ],
    );
    await tester.pumpWidget(_routerApp(router));
    for (var index = 0; index < 3; index++) {
      await tester.tap(find.byKey(const Key('onboarding-next')));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const Key('setup-destination')), findsOneWidget);
    router.dispose();
  });

  testWidgets('traveler bottom navigation changes tab', (tester) async {
    final router = GoRouter(
      initialLocation: '/traveler/explore',
      routes: [
        GoRoute(
          path: '/traveler/:tab',
          builder: (_, state) =>
              TravelerShell(tab: state.pathParameters['tab']!),
        ),
      ],
    );
    await tester.pumpWidget(_routerApp(router));
    expect(
      tester
          .widget<NavigationBar>(find.byKey(const Key('traveler-navigation')))
          .selectedIndex,
      0,
    );
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('traveler-navigation')),
        matching: find.byIcon(Icons.favorite_border_rounded),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<NavigationBar>(find.byKey(const Key('traveler-navigation')))
          .selectedIndex,
      1,
    );
    router.dispose();
  });

  testWidgets('owner bottom navigation changes tab', (tester) async {
    final router = GoRouter(
      initialLocation: '/owner/dashboard',
      routes: [
        GoRoute(
          path: '/owner/:tab',
          builder: (_, state) => OwnerShell(tab: state.pathParameters['tab']!),
        ),
      ],
    );
    await tester.pumpWidget(_routerApp(router));
    expect(
      tester
          .widget<NavigationBar>(find.byKey(const Key('owner-navigation')))
          .selectedIndex,
      0,
    );
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('owner-navigation')),
        matching: find.byIcon(Icons.event_note_outlined),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<NavigationBar>(find.byKey(const Key('owner-navigation')))
          .selectedIndex,
      1,
    );
    router.dispose();
  });

  testWidgets('search filters local properties by destination', (tester) async {
    await tester.pumpWidget(_localizedApp(home: const SearchScreen()));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.enterText(find.byKey(const Key('search-field')), 'Kep');
    await tester.pump();
    expect(find.text('Kep Seabreeze Homestay'), findsOneWidget);
    expect(find.text('Angkor Lotus Heritage Stay'), findsNothing);
  });

  testWidgets('representative traveler and owner screens fit target sizes', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    for (final size in const [
      Size(360, 800),
      Size(390, 844),
      Size(430, 932),
      Size(800, 1024),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        _localizedApp(home: const TravelerShell(tab: 'explore')),
      );
      await tester.pump();
      await tester.pumpWidget(
        _localizedApp(home: const OwnerDashboardScreen()),
      );
      await tester.pump();
      await tester.pumpWidget(
        _localizedApp(
          home: const PropertyDetailsScreen(propertyId: 'angkor-lotus'),
        ),
      );
      await tester.pump();
      await tester.pumpWidget(
        _localizedApp(home: const BookingScreen(propertyId: 'angkor-lotus')),
      );
      await tester.pump();
    }
  });

  testWidgets('key journeys remain readable at 200 percent text scaling', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    for (final screen in const <Widget>[
      PreferenceSetupScreen(),
      TravelerProfileScreen(),
      OwnerDashboardScreen(),
      PropertyDetailsScreen(propertyId: 'angkor-lotus'),
    ]) {
      await tester.pumpWidget(_localizedApp(home: screen));
      await tester.pump();
    }
  });

  test('language and currency switch in local state', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container
        .read(appControllerProvider.notifier)
        .setLocale(const Locale('en'));
    await container
        .read(appControllerProvider.notifier)
        .setCurrency(CurrencyChoice.usd);
    expect(container.read(appControllerProvider).locale.languageCode, 'en');
    expect(container.read(appControllerProvider).currency, CurrencyChoice.usd);
  });

  test('guest starts without personal bookings or favorites', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(appControllerProvider).favorites, isEmpty);
    expect(container.read(appControllerProvider).bookings, isEmpty);
    expect(container.read(appControllerProvider).conversations, isEmpty);
  });

  test('mock booking completion adds an upcoming trip', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final before = container.read(appControllerProvider).bookings.length;
    final booking = Booking(
      id: 'test-booking',
      reference: 'KHS-TEST',
      propertyId: mockProperties.first.id,
      roomName: 'Garden deluxe',
      start: DateTime(2026, 12, 1),
      end: DateTime(2026, 12, 3),
      guests: 2,
      totalUsd: 120,
      status: BookingStatus.upcoming,
      guest: const BookingGuest(
        name: 'Demo Guest',
        email: 'demo@example.com',
        phone: '012345678',
      ),
    );
    container.read(appControllerProvider.notifier).addBooking(booking);
    expect(container.read(appControllerProvider).bookings.length, before + 1);
    expect(
      container.read(appControllerProvider).bookings.first.id,
      'test-booking',
    );
  });

  test('role switching changes active mode', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(appControllerProvider.notifier).setRole(AppRole.owner);
    expect(container.read(appControllerProvider).role, AppRole.owner);
    await container
        .read(appControllerProvider.notifier)
        .setRole(AppRole.traveler);
    expect(container.read(appControllerProvider).role, AppRole.traveler);
  });
}
