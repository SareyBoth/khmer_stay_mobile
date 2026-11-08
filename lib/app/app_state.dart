import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/mock/mock_data.dart';
import '../core/models/app_models.dart';
import '../core/api/api_client.dart';

final preferencesProvider = Provider<SharedPreferences?>((ref) => null);
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(preferencesProvider)),
);

class LastPaidBookingNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setPaid(String? id) => state = id;
}

final lastPaidBookingIdProvider =
    NotifierProvider<LastPaidBookingNotifier, String?>(
      LastPaidBookingNotifier.new,
    );

class AppState {
  const AppState({
    required this.onboardingComplete,
    required this.locale,
    required this.currency,
    required this.role,
    required this.favorites,
    required this.bookings,
    required this.conversations,
    required this.readNotificationIds,
    required this.blockedDates,
    required this.recommendedPropertyIds,
    this.exchangeRate = 4100.0,
    this.newBookingRequestsCount = 0,
  });

  factory AppState.initial(SharedPreferences? preferences) => AppState(
    onboardingComplete: preferences?.getBool('onboardingComplete') ?? false,
    locale: Locale(preferences?.getString('language') ?? 'km'),
    currency: CurrencyChoice.values.firstWhere(
      (value) => value.name == (preferences?.getString('currency') ?? 'khr'),
      orElse: () => CurrencyChoice.khr,
    ),
    role: AppRole.values.firstWhere(
      (value) => value.name == (preferences?.getString('role') ?? 'traveler'),
      orElse: () => AppRole.traveler,
    ),
    favorites: const {},
    bookings: const [],
    conversations: const [],
    readNotificationIds: const {},
    blockedDates: const {},
    recommendedPropertyIds: const [],
    exchangeRate: 4100.0,
    newBookingRequestsCount: 0,
  );

  final bool onboardingComplete;
  final Locale locale;
  final CurrencyChoice currency;
  final AppRole role;
  final Set<String> favorites;
  final List<Booking> bookings;
  final List<Conversation> conversations;
  final Set<String> readNotificationIds;
  final Set<DateTime> blockedDates;
  final List<String> recommendedPropertyIds;
  final double exchangeRate;
  final int newBookingRequestsCount;

  AppState copyWith({
    bool? onboardingComplete,
    Locale? locale,
    CurrencyChoice? currency,
    AppRole? role,
    Set<String>? favorites,
    List<Booking>? bookings,
    List<Conversation>? conversations,
    Set<String>? readNotificationIds,
    Set<DateTime>? blockedDates,
    List<String>? recommendedPropertyIds,
    double? exchangeRate,
    int? newBookingRequestsCount,
  }) => AppState(
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    locale: locale ?? this.locale,
    currency: currency ?? this.currency,
    role: role ?? this.role,
    favorites: favorites ?? this.favorites,
    bookings: bookings ?? this.bookings,
    conversations: conversations ?? this.conversations,
    readNotificationIds: readNotificationIds ?? this.readNotificationIds,
    blockedDates: blockedDates ?? this.blockedDates,
    recommendedPropertyIds:
        recommendedPropertyIds ?? this.recommendedPropertyIds,
    exchangeRate: exchangeRate ?? this.exchangeRate,
    newBookingRequestsCount:
        newBookingRequestsCount ?? this.newBookingRequestsCount,
  );
}

class AppController extends Notifier<AppState> {
  SharedPreferences? get _preferences => ref.read(preferencesProvider);
  ApiClient get _api => ref.read(apiClientProvider);
  StreamSubscription<SseEvent>? _sseSubscription;
  StreamSubscription<SseEvent>? _chatSubscription;

  @override
  AppState build() {
    ref.onDispose(() {
      _sseSubscription?.cancel();
      _chatSubscription?.cancel();
    });
    return AppState.initial(ref.watch(preferencesProvider));
  }

  Future<void> loadServerData() async {
    try {
      final rate = await _api.fetchExchangeRate();
      state = state.copyWith(exchangeRate: rate);
    } catch (_) {}

    final propertyResult = await _api.request('/properties');
    final converted = (propertyResult['properties'] as List<dynamic>)
        .map((item) => propertyFromApi(item as Map<String, dynamic>))
        .toList();
    mockProperties
      ..clear()
      ..addAll(converted);
    if (_api.token == null) {
      _sseSubscription?.cancel();
      _sseSubscription = null;
      _chatSubscription?.cancel();
      _chatSubscription = null;
      state = state.copyWith(
        bookings: const [],
        favorites: const {},
        conversations: const [],
        blockedDates: const {},
        recommendedPropertyIds: const [],
        newBookingRequestsCount: 0,
      );
      return;
    }

    _startSse();
    _startChatSocket();

    final bookingResult = await _api.request('/bookings');
    final favoriteResult = state.role == AppRole.traveler
        ? await _api.request('/favorites')
        : <String, dynamic>{'propertyIds': <dynamic>[]};
    final recommendationResult = state.role == AppRole.traveler
        ? await _api.request('/recommendations?limit=12')
        : <String, dynamic>{'properties': <dynamic>[]};
    final conversationResult = await _api.request('/conversations');
    final rawConversations =
        conversationResult['conversations'] as List<dynamic>;
    final conversations = await Future.wait(
      rawConversations.map((raw) async {
        final item = raw as Map<String, dynamic>;
        final id = item['id'] as String;
        final response = await _api.request('/conversations/$id/messages');
        final messages = (response['messages'] as List<dynamic>).map((
          rawMessage,
        ) {
          final message = rawMessage as Map<String, dynamic>;
          return ChatMessage(
            id: message['id'] as String,
            text: message['text'] as String,
            sentAt: DateTime.parse(message['sentAt'] as String),
            fromMe: message['fromMe'] as bool,
          );
        }).toList();
        return Conversation(
          id: id,
          name: state.role == AppRole.owner
              ? item['travelerName']?.toString() ?? 'Traveler'
              : item['ownerName']?.toString() ?? 'KhmerStay support',
          propertyId: item['propertyId']?.toString() ?? '',
          kind: item['kind']?.toString() ?? 'property',
          subject: item['subject']?.toString() ?? '',
          unread: (item['unreadCount'] as num? ?? 0) > 0,
          messages: messages,
        );
      }),
    );
    final blockedResult = state.role == AppRole.owner
        ? await _api.request('/blocked-dates')
        : null;

    state = state.copyWith(
      bookings: (bookingResult['bookings'] as List<dynamic>)
          .map((item) => bookingFromApi(item as Map<String, dynamic>))
          .toList(),
      favorites: (favoriteResult['propertyIds'] as List<dynamic>)
          .map((item) => item.toString())
          .toSet(),
      conversations: conversations,
      blockedDates: blockedResult == null
          ? const {}
          : (blockedResult['blockedDates'] as List<dynamic>)
                .map(
                  (item) => DateTime.parse(
                    (item as Map<String, dynamic>)['date'] as String,
                  ),
                )
                .toSet(),
      recommendedPropertyIds:
          (recommendationResult['properties'] as List<dynamic>)
              .map((item) => (item as Map<String, dynamic>)['id'].toString())
              .toList(),
    );
  }

  void _startSse() {
    _sseSubscription?.cancel();
    if (_api.token == null) return;
    _sseSubscription = _api
        .connectEventsContinuous(shouldContinue: () => _api.token != null)
        .listen((event) {
          _handleSseEvent(event);
        }, onError: (_) {});
  }

  void _startChatSocket() {
    _chatSubscription?.cancel();
    if (_api.token == null) return;
    _chatSubscription = _api
        .connectChatContinuous(shouldContinue: () => _api.token != null)
        .listen((event) {
          if (event.type == 'new_message') {
            _onNewMessage(event.data);
          }
        }, onError: (_) {});
  }

  void _handleSseEvent(SseEvent event) {
    switch (event.type) {
      case 'payment_received':
        _onPaymentReceived(event.data);
      case 'booking_updated':
        _onBookingUpdated(event.data);
      case 'new_booking_request':
        _onNewBookingRequest(event.data);
    }
  }

  void _onPaymentReceived(dynamic data) {
    String bookingId = '';
    if (data is Map<String, dynamic>) {
      bookingId = (data['id'] ?? data['bookingId'] ?? data['ID'] ?? '')
          .toString();
    }
    if (bookingId.isNotEmpty) {
      ref.read(lastPaidBookingIdProvider.notifier).setPaid(bookingId);
      state = state.copyWith(
        bookings: [
          for (final b in state.bookings)
            if (b.id == bookingId)
              b.copyWith(status: BookingStatus.confirmed)
            else
              b,
        ],
      );
    }
  }

  void _onNewMessage(dynamic data) {
    if (data is! Map<String, dynamic>) return;
    final id = (data['id'] ?? '').toString();
    final text = (data['text'] ?? data['body'] ?? '').toString();
    final sentAtStr = data['sentAt'] ?? data['createdAt'];
    final sentAt = sentAtStr != null
        ? DateTime.tryParse(sentAtStr.toString()) ?? DateTime.now()
        : DateTime.now();
    final fromMe = data['fromMe'] == true;
    final convId = (data['conversationId'] ?? '').toString();

    final chatMsg = ChatMessage(
      id: id.isNotEmpty ? id : 'msg-${DateTime.now().microsecondsSinceEpoch}',
      text: text,
      sentAt: sentAt,
      fromMe: fromMe,
    );

    bool matched = false;
    final updatedConvs = <Conversation>[];
    for (final conv in state.conversations) {
      if ((convId.isNotEmpty && conv.id == convId) ||
          (convId.isEmpty && state.conversations.length == 1)) {
        matched = true;
        final alreadyHas = conv.messages.any(
          (m) =>
              m.id == chatMsg.id ||
              (m.text == chatMsg.text &&
                  m.fromMe == chatMsg.fromMe &&
                  m.sentAt.difference(chatMsg.sentAt).inSeconds.abs() < 2),
        );
        if (!alreadyHas) {
          updatedConvs.add(
            conv.copyWith(
              unread: !fromMe,
              messages: [...conv.messages, chatMsg],
            ),
          );
        } else {
          updatedConvs.add(conv);
        }
      } else {
        updatedConvs.add(conv);
      }
    }

    if (matched) {
      state = state.copyWith(conversations: updatedConvs);
    } else {
      _reloadConversations();
    }
  }

  Future<void> _reloadConversations() async {
    if (_api.token == null) return;
    try {
      final conversationResult = await _api.request('/conversations');
      final rawConversations =
          conversationResult['conversations'] as List<dynamic>;
      final conversations = await Future.wait(
        rawConversations.map((raw) async {
          final item = raw as Map<String, dynamic>;
          final id = item['id'] as String;
          final response = await _api.request('/conversations/$id/messages');
          final messages = (response['messages'] as List<dynamic>).map((
            rawMessage,
          ) {
            final message = rawMessage as Map<String, dynamic>;
            return ChatMessage(
              id: message['id'] as String,
              text: message['text'] as String,
              sentAt: DateTime.parse(message['sentAt'] as String),
              fromMe: message['fromMe'] as bool,
            );
          }).toList();
          return Conversation(
            id: id,
            name: state.role == AppRole.owner
                ? item['travelerName']?.toString() ?? 'Traveler'
                : item['ownerName']?.toString() ?? 'KhmerStay support',
            propertyId: item['propertyId']?.toString() ?? '',
            kind: item['kind']?.toString() ?? 'property',
            subject: item['subject']?.toString() ?? '',
            unread: (item['unreadCount'] as num? ?? 0) > 0,
            messages: messages,
          );
        }),
      );
      state = state.copyWith(conversations: conversations);
    } catch (_) {}
  }

  void _onBookingUpdated(dynamic data) {
    if (data is! Map<String, dynamic>) return;
    try {
      final updatedBooking = bookingFromApi(data);
      final exists = state.bookings.any((b) => b.id == updatedBooking.id);
      state = state.copyWith(
        bookings: exists
            ? [
                for (final b in state.bookings)
                  if (b.id == updatedBooking.id) updatedBooking else b,
              ]
            : [updatedBooking, ...state.bookings],
      );
    } catch (_) {}
  }

  void _onNewBookingRequest(dynamic data) {
    state = state.copyWith(
      newBookingRequestsCount: state.newBookingRequestsCount + 1,
    );
    if (data is Map<String, dynamic>) {
      try {
        final newBooking = bookingFromApi(data);
        if (!state.bookings.any((b) => b.id == newBooking.id)) {
          state = state.copyWith(bookings: [newBooking, ...state.bookings]);
        }
      } catch (_) {}
    }
  }

  void clearBookingRequestsBadge() {
    state = state.copyWith(newBookingRequestsCount: 0);
  }

  Future<void> refreshExchangeRate() async {
    try {
      final rate = await _api.fetchExchangeRate();
      state = state.copyWith(exchangeRate: rate);
    } catch (_) {}
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(onboardingComplete: true);
    await _preferences?.setBool('onboardingComplete', true);
  }

  Future<void> setLocale(Locale locale) async {
    state = state.copyWith(locale: locale);
    await _preferences?.setString('language', locale.languageCode);
  }

  Future<void> setCurrency(CurrencyChoice currency) async {
    state = state.copyWith(currency: currency);
    await _preferences?.setString('currency', currency.name);
  }

  Future<void> setRole(AppRole role) async {
    state = state.copyWith(role: role);
    await _preferences?.setString('role', role.name);
  }

  Future<void> toggleFavorite(String propertyId) async {
    final next = {...state.favorites};
    if (next.contains(propertyId)) {
      await _api.request('/favorites/$propertyId', method: 'DELETE');
      next.remove(propertyId);
    } else {
      await _api.request('/favorites/$propertyId', method: 'POST');
      next.add(propertyId);
    }
    state = state.copyWith(favorites: next);
  }

  Future<void> trackPropertyView(String propertyId) async {
    if (_api.token == null || state.role != AppRole.traveler) return;
    await _api.request(
      '/recommendations/events',
      method: 'POST',
      body: {'propertyId': propertyId, 'eventType': 'view'},
    );
  }

  void addBooking(Booking booking) {
    state = state.copyWith(bookings: [booking, ...state.bookings]);
  }

  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    final serverStatus = switch (status) {
      BookingStatus.confirmed => 'Confirmed',
      BookingStatus.ongoing => 'Checked in',
      BookingStatus.past => 'Completed',
      BookingStatus.cancelled => 'Cancelled',
      BookingStatus.pending => 'Pending',
      BookingStatus.upcoming => 'Confirmed',
    };
    await _api.request(
      '/bookings/$bookingId/status',
      method: 'POST',
      body: {'status': serverStatus},
    );
    state = state.copyWith(
      bookings: [
        for (final booking in state.bookings)
          if (booking.id == bookingId)
            booking.copyWith(status: status)
          else
            booking,
      ],
    );
  }

  Future<void> sendMessage(String conversationId, String message) async {
    if (message.trim().isEmpty) return;
    final conversation = state.conversations
        .where((item) => item.id == conversationId)
        .firstOrNull;
    final result = await _api.request(
      '/conversations/$conversationId/messages',
      method: 'POST',
      body: {
        'text': message.trim(),
        'propertyId': conversation?.propertyId ?? '',
      },
    );
    final saved = result['message'] as Map<String, dynamic>;
    state = state.copyWith(
      conversations: [
        for (final conversation in state.conversations)
          if (conversation.id == conversationId)
            conversation.copyWith(
              unread: false,
              messages: [
                ...conversation.messages,
                ChatMessage(
                  id:
                      saved['id']?.toString() ??
                      'local-${DateTime.now().microsecondsSinceEpoch}',
                  text: saved['text']?.toString() ?? message.trim(),
                  sentAt:
                      DateTime.tryParse(saved['sentAt']?.toString() ?? '') ??
                      DateTime.now(),
                  fromMe: true,
                ),
              ],
            )
          else
            conversation,
      ],
    );
  }

  void markConversationRead(String conversationId) {
    unawaited(
      _api
          .request('/conversations/$conversationId/read', method: 'POST')
          .catchError((_) => <String, dynamic>{}),
    );
    state = state.copyWith(
      conversations: [
        for (final conversation in state.conversations)
          if (conversation.id == conversationId)
            conversation.copyWith(unread: false)
          else
            conversation,
      ],
    );
  }

  Future<String> startConversation({
    required String type,
    String propertyId = '',
    String subject = '',
  }) async {
    final result = await _api.request(
      '/conversations',
      method: 'POST',
      body: {'type': type, 'propertyId': propertyId, 'subject': subject},
    );
    final conversation = result['conversation'] as Map<String, dynamic>;
    final id = conversation['id']!.toString();
    await _reloadConversations();
    return id;
  }

  Future<void> markNotificationRead(String id) async {
    await _api.request('/notifications/$id/read', method: 'POST');
    state = state.copyWith(
      readNotificationIds: {...state.readNotificationIds, id},
    );
  }

  void markAllNotificationsRead() {
    state = state.copyWith(
      readNotificationIds: {'n1', 'n2', 'n3', 'n4', 'n5', 'n6'},
    );
  }

  Future<void> toggleBlockedDate(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    final next = {...state.blockedDates};
    final blocked = !next.contains(normalized);
    final propertyId = mockProperties.firstOrNull?.id;
    if (propertyId == null) return;
    await _api.request(
      '/blocked-dates',
      method: 'POST',
      body: {
        'propertyId': propertyId,
        'date': DateFormat('yyyy-MM-dd').format(normalized),
        'blocked': blocked,
      },
    );
    blocked ? next.add(normalized) : next.remove(normalized);
    state = state.copyWith(blockedDates: next);
  }
}

final appControllerProvider = NotifierProvider<AppController, AppState>(
  AppController.new,
);

String formatPrice(double usd, AppState state, {bool compact = false}) {
  if (state.currency == CurrencyChoice.usd) {
    return NumberFormat.currency(
      symbol: r'$',
      decimalDigits: usd % 1 == 0 ? 0 : 2,
    ).format(usd);
  }
  final rate = state.exchangeRate > 0 ? state.exchangeRate : 4100.0;
  final value = usd * rate;
  return compact
      ? '៛${NumberFormat.compact(locale: 'en').format(value)}'
      : '៛${NumberFormat('#,##0').format(value)}';
}
