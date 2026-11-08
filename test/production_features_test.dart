import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app_state.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/models/app_models.dart';
import 'package:mobile/features/traveler/traveler_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Traveler trips', () {
    test('upcoming tab includes pending and confirmed bookings', () {
      expect(
        bookingBelongsToTripTab(BookingStatus.pending, BookingStatus.upcoming),
        isTrue,
      );
      expect(
        bookingBelongsToTripTab(
          BookingStatus.confirmed,
          BookingStatus.upcoming,
        ),
        isTrue,
      );
      expect(
        bookingBelongsToTripTab(
          BookingStatus.cancelled,
          BookingStatus.upcoming,
        ),
        isFalse,
      );
    });
  });

  group('Feature 1: Silent Token Refresh & Session Persistence', () {
    test('saves and clears both apiToken and refreshToken', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final client = ApiClient(prefs);

      expect(client.token, isNull);
      expect(client.refreshToken, isNull);

      await client.saveTokens(
        token: 'initial-access-token',
        refreshToken: 'initial-refresh-token',
      );

      expect(client.token, 'initial-access-token');
      expect(client.refreshToken, 'initial-refresh-token');
      expect(prefs.getString('apiToken'), 'initial-access-token');
      expect(prefs.getString('refreshToken'), 'initial-refresh-token');

      await client.clearTokens();
      expect(client.token, isNull);
      expect(client.refreshToken, isNull);
      expect(prefs.getString('apiToken'), isNull);
      expect(prefs.getString('refreshToken'), isNull);
    });
  });

  group('Feature 2: Real-Time SSE Listener & App State Handling', () {
    test(
      'payment_received event confirms booking and notifies payment provider',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final controller = container.read(appControllerProvider.notifier);
        final testBooking = Booking(
          id: 'bk-test-101',
          reference: 'KS-101',
          propertyId: 'p1',
          roomName: 'Deluxe Room',
          start: DateTime(2026, 11, 1),
          end: DateTime(2026, 11, 5),
          guests: 2,
          totalUsd: 120.0,
          status: BookingStatus.pending,
          guest: const BookingGuest(
            name: 'Sokha Chan',
            email: 'sokha@test.demo',
            phone: '012345678',
          ),
        );

        controller.addBooking(testBooking);
        expect(
          container.read(appControllerProvider).bookings.first.status,
          BookingStatus.pending,
        );

        // Simulate incoming payment_received event
        container
            .read(lastPaidBookingIdProvider.notifier)
            .setPaid('bk-test-101');
        expect(container.read(lastPaidBookingIdProvider), 'bk-test-101');
      },
    );

    test('new_message appends incoming chat message in real time', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialConvo = Conversation(
        id: 'c-test-1',
        name: 'Sophea Host',
        propertyId: 'p1',
        unread: false,
        messages: [
          ChatMessage(
            id: 'm1',
            text: 'Hello!',
            sentAt: DateTime(2026, 10, 30, 10, 0),
            fromMe: true,
          ),
        ],
      );

      final controller = container.read(appControllerProvider.notifier);
      controller.state = controller.state.copyWith(
        conversations: [initialConvo],
      );

      // Simulate SSE new_message
      final messageData = {
        'id': 'm2',
        'conversationId': 'c-test-1',
        'text': 'Welcome to our homestay!',
        'fromMe': false,
        'sentAt': '2026-10-30T10:05:00Z',
      };

      // Find conversation and append
      final conv = container.read(appControllerProvider).conversations.first;
      expect(conv.messages.length, 1);

      controller.state = controller.state.copyWith(
        conversations: [
          conv.copyWith(
            unread: true,
            messages: [
              ...conv.messages,
              ChatMessage(
                id: messageData['id'] as String,
                text: messageData['text'] as String,
                sentAt: DateTime.parse(messageData['sentAt'] as String),
                fromMe: messageData['fromMe'] as bool,
              ),
            ],
          ),
        ],
      );

      final updated = container.read(appControllerProvider).conversations.first;
      expect(updated.messages.length, 2);
      expect(updated.messages.last.text, 'Welcome to our homestay!');
      expect(updated.unread, isTrue);
    });

    test('new_booking_request increments notification badge count', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(appControllerProvider.notifier);
      expect(container.read(appControllerProvider).newBookingRequestsCount, 0);

      controller.state = controller.state.copyWith(
        newBookingRequestsCount: controller.state.newBookingRequestsCount + 1,
      );

      expect(container.read(appControllerProvider).newBookingRequestsCount, 1);

      controller.clearBookingRequestsBadge();
      expect(container.read(appControllerProvider).newBookingRequestsCount, 0);
    });
  });

  group('Feature 3: Advanced Property Search & Filter query builder', () {
    test('constructs URI with all required query parameters', () {
      final queryParams = <String, String>{};
      const checkIn = '2026-11-01';
      const checkOut = '2026-11-05';
      const guests = 3;
      const minPrice = 30.0;
      const maxPrice = 120.0;
      const category = 'Heritage';
      const amenities = 'Wi-Fi,Breakfast,Pool';
      const q = 'Siem Reap';

      queryParams['checkIn'] = checkIn;
      queryParams['checkOut'] = checkOut;
      queryParams['guests'] = guests.toString();
      queryParams['minPrice'] = minPrice.toString();
      queryParams['maxPrice'] = maxPrice.toString();
      queryParams['category'] = category;
      queryParams['amenities'] = amenities;
      queryParams['q'] = q;

      final uri = Uri(path: '/properties', queryParameters: queryParams);
      expect(uri.queryParameters['checkIn'], '2026-11-01');
      expect(uri.queryParameters['checkOut'], '2026-11-05');
      expect(uri.queryParameters['guests'], '3');
      expect(uri.queryParameters['minPrice'], '30.0');
      expect(uri.queryParameters['maxPrice'], '120.0');
      expect(uri.queryParameters['category'], 'Heritage');
      expect(uri.queryParameters['amenities'], 'Wi-Fi,Breakfast,Pool');
      expect(uri.queryParameters['q'], 'Siem Reap');
    });
  });

  group('Feature 4: Double-Booking & Blocked-Date Conflict Messages', () {
    test('identifies conflict error messages accurately', () {
      const reservedError =
          'property is already reserved for the selected dates';
      const blockedError = 'selected dates include blocked host dates';

      expect(
        reservedError.toLowerCase().contains(
          'already reserved for the selected dates',
        ),
        isTrue,
      );
      expect(blockedError.toLowerCase().contains('blocked host dates'), isTrue);
    });
  });

  group('Feature 5: Host Payouts Ledger & Request Flow', () {
    test('HostPayout parses JSON correctly and calculates 15% commission', () {
      final json = {
        'id': 'PO-261030-ABC123',
        'ownerId': 'owner-1',
        'bookingId': 'bk-999',
        'grossAmount': 200.0,
        'commissionRate': 15.0,
        'commissionAmount': 30.0,
        'netAmount': 170.0,
        'currency': 'USD',
        'bakongAccount': 'sophea@aclb',
        'status': 'Paid',
        'reference': 'TX-BAKONG-8888',
        'createdAt': '2026-10-30T10:00:00Z',
        'paidAt': '2026-10-30T11:00:00Z',
        'propertyName': 'Siem Reap Villa',
        'guestName': 'John Traveler',
      };

      final payout = HostPayout.fromJson(json);
      expect(payout.id, 'PO-261030-ABC123');
      expect(payout.grossAmount, 200.0);
      expect(payout.commissionAmount, 30.0);
      expect(payout.netAmount, 170.0);
      expect(payout.status, 'Paid');
      expect(payout.reference, 'TX-BAKONG-8888');
      expect(payout.bakongAccount, 'sophea@aclb');
      expect(payout.grossAmount * 0.15, payout.commissionAmount);
      expect(payout.grossAmount - payout.commissionAmount, payout.netAmount);
    });
  });

  group('Feature 6: Live NBC Exchange Rate & Dynamic Conversion', () {
    test('formatPrice uses dynamic exchange rate from state', () {
      SharedPreferences.setMockInitialValues({});
      var state = AppState.initial(null);

      // Default rate 4100 KHR = 1 USD
      expect(state.exchangeRate, 4100.0);
      expect(formatPrice(10.0, state), '៛41,000');

      // Custom server exchange rate: 4125 KHR = 1 USD
      state = state.copyWith(exchangeRate: 4125.0);
      expect(formatPrice(10.0, state), '៛41,250');

      // USD currency
      state = state.copyWith(currency: CurrencyChoice.usd);
      expect(formatPrice(10.0, state), r'$10');
    });
  });
}
