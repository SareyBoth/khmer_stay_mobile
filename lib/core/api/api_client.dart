import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../mock/mock_data.dart';
import '../models/app_models.dart';

const configuredApiUrl = String.fromEnvironment('API_BASE_URL');

String get apiBaseUrl {
  if (configuredApiUrl.isNotEmpty) return configuredApiUrl;
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8080';
  }
  return 'http://localhost:8080';
}

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class SseEvent {
  const SseEvent({required this.type, required this.data});
  final String type;
  final dynamic data;

  @override
  String toString() => 'SseEvent(type: $type, data: $data)';
}

class ApiClient {
  ApiClient(this.preferences);
  final SharedPreferences? preferences;

  String? get token => preferences?.getString('apiToken');
  String? get refreshToken => preferences?.getString('refreshToken');

  Future<void> saveTokens({required String token, String? refreshToken}) async {
    await preferences?.setString('apiToken', token);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await preferences?.setString('refreshToken', refreshToken);
    }
  }

  Future<void> setToken(String value) async =>
      preferences?.setString('apiToken', value);

  Future<void> setRefreshToken(String value) async =>
      preferences?.setString('refreshToken', value);

  Future<void> clearTokens() async {
    await preferences?.remove('apiToken');
    await preferences?.remove('refreshToken');
  }

  Future<void> clearToken() async => clearTokens();

  Completer<bool>? _refreshCompleter;

  Future<bool> _refreshTokens() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }
    final completer = Completer<bool>();
    _refreshCompleter = completer;

    try {
      final currentRefreshToken = refreshToken;
      if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
        completer.complete(false);
        return false;
      }
      final client = http.Client();
      late final http.Response response;
      try {
        final req = http.Request('POST', Uri.parse('$apiBaseUrl/auth/refresh'));
        req.headers['Accept'] = 'application/json';
        req.headers['Content-Type'] = 'application/json';
        req.body = jsonEncode({'refreshToken': currentRefreshToken});
        final streamed = await client
            .send(req)
            .timeout(const Duration(seconds: 12));
        response = await http.Response.fromStream(streamed);
      } finally {
        client.close();
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final newToken = decoded['token'] as String?;
        final newRefreshToken = decoded['refreshToken'] as String?;
        if (newToken != null && newToken.isNotEmpty) {
          await saveTokens(token: newToken, refreshToken: newRefreshToken);
          completer.complete(true);
          return true;
        }
      }
      await clearTokens();
      completer.complete(false);
      return false;
    } catch (_) {
      completer.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<Map<String, dynamic>> request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
    bool isRetry = false,
  }) async {
    final client = http.Client();
    late final http.Response response;
    try {
      final request = http.Request(method, Uri.parse('$apiBaseUrl$path'));
      request.headers['Accept'] = 'application/json';
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      if (body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(body);
      }
      final streamed = await client
          .send(request)
          .timeout(const Duration(seconds: 12));
      response = await http.Response.fromStream(streamed);
    } finally {
      client.close();
    }

    if (response.statusCode == 401 &&
        !isRetry &&
        !path.startsWith('/auth/login') &&
        !path.startsWith('/auth/refresh') &&
        refreshToken != null) {
      final refreshed = await _refreshTokens();
      if (refreshed) {
        return request(path, method: method, body: body, isRetry: true);
      }
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        decoded['error']?.toString() ?? 'Server error',
        statusCode: response.statusCode,
      );
    }
    return decoded;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final result = await request(
      '/auth/login',
      method: 'POST',
      body: {'email': email, 'password': password},
    );
    final token = result['token'] as String?;
    final refToken = result['refreshToken'] as String?;
    if (token != null) {
      await saveTokens(token: token, refreshToken: refToken);
    }
    return result;
  }

  Future<Map<String, dynamic>> verifyOtp(
    String email,
    String code,
    String purpose,
  ) async {
    final result = await request(
      '/auth/otp/verify',
      method: 'POST',
      body: {'email': email, 'code': code, 'purpose': purpose},
    );
    final token = result['token'] as String?;
    final refToken = result['refreshToken'] as String?;
    if (token != null) {
      await saveTokens(token: token, refreshToken: refToken);
    }
    return result;
  }

  Future<Map<String, dynamic>> googleLogin(String idToken) async {
    final result = await request(
      '/auth/google',
      method: 'POST',
      body: {'idToken': idToken},
    );
    final token = result['token'] as String?;
    final refToken = result['refreshToken'] as String?;
    if (token != null) {
      await saveTokens(token: token, refreshToken: refToken);
    }
    return result;
  }

  Future<void> logout() async {
    final currentRefreshToken = refreshToken;
    if (token != null) {
      try {
        await request(
          '/auth/logout',
          method: 'POST',
          body: currentRefreshToken != null
              ? {'refreshToken': currentRefreshToken}
              : null,
        );
      } catch (_) {}
    }
    await clearTokens();
  }

  Stream<SseEvent> subscribeToEvents() async* {
    final client = http.Client();
    try {
      final currentToken = token;
      final uri = Uri.parse(
        '$apiBaseUrl/events${currentToken != null ? '?token=$currentToken' : ''}',
      );
      final request = http.Request('GET', uri);
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';
      if (currentToken != null) {
        request.headers['Authorization'] = 'Bearer $currentToken';
      }

      final response = await client.send(request);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        String eventType = 'message';
        final dataLines = <String>[];

        await for (final line
            in response.stream
                .transform(utf8.decoder)
                .transform(const LineSplitter())) {
          final trimmed = line.trimRight();
          if (trimmed.isEmpty) {
            if (dataLines.isNotEmpty) {
              final payload = dataLines.join('\n');
              dynamic parsedData;
              try {
                parsedData = jsonDecode(payload);
              } catch (_) {
                parsedData = payload;
              }
              yield SseEvent(type: eventType, data: parsedData);
              eventType = 'message';
              dataLines.clear();
            }
          } else if (trimmed.startsWith(':')) {
            // Heartbeat/ping
            continue;
          } else if (trimmed.startsWith('event:')) {
            eventType = trimmed.substring(6).trim();
          } else if (trimmed.startsWith('data:')) {
            dataLines.add(trimmed.substring(5).trim());
          }
        }
      }
    } catch (_) {
      // Disconnected or closed
    } finally {
      client.close();
    }
  }

  Stream<SseEvent> connectEventsContinuous({
    Duration retryDelay = const Duration(seconds: 4),
    bool Function()? shouldContinue,
  }) async* {
    while (shouldContinue == null || shouldContinue()) {
      if (token == null) {
        await Future<void>.delayed(retryDelay);
        continue;
      }
      yield* subscribeToEvents();
      await Future<void>.delayed(retryDelay);
    }
  }

  Stream<SseEvent> subscribeToChat() async* {
    final currentToken = token;
    if (currentToken == null || currentToken.isEmpty) return;
    final httpUri = Uri.parse(apiBaseUrl);
    final socketUri = httpUri.replace(
      scheme: httpUri.scheme == 'https' ? 'wss' : 'ws',
      path: '${httpUri.path.replaceFirst(RegExp(r'/$'), '')}/ws',
      queryParameters: {'token': currentToken},
    );
    final channel = WebSocketChannel.connect(socketUri);
    try {
      await channel.ready.timeout(const Duration(seconds: 12));
      await for (final raw in channel.stream) {
        final decoded = jsonDecode(raw.toString());
        if (decoded is Map<String, dynamic>) {
          yield SseEvent(
            type: decoded['type']?.toString() ?? 'message',
            data: decoded['data'],
          );
        }
      }
    } catch (_) {
      // The reconnecting wrapper opens a fresh socket.
    } finally {
      await channel.sink.close();
    }
  }

  Stream<SseEvent> connectChatContinuous({
    Duration retryDelay = const Duration(seconds: 3),
    bool Function()? shouldContinue,
  }) async* {
    while (shouldContinue == null || shouldContinue()) {
      if (token == null) {
        await Future<void>.delayed(retryDelay);
        continue;
      }
      yield* subscribeToChat();
      await Future<void>.delayed(retryDelay);
    }
  }

  Future<List<Property>> fetchProperties({
    String? checkIn,
    String? checkOut,
    int? guests,
    double? minPrice,
    double? maxPrice,
    String? category,
    String? amenities,
    String? q,
    String? provinceCode,
    String? cityId,
  }) async {
    final queryParams = <String, String>{};
    if (checkIn != null && checkIn.isNotEmpty) queryParams['checkIn'] = checkIn;
    if (checkOut != null && checkOut.isNotEmpty) {
      queryParams['checkOut'] = checkOut;
    }
    if (guests != null && guests > 0) {
      queryParams['guests'] = guests.toString();
    }
    if (minPrice != null && minPrice > 0) {
      queryParams['minPrice'] = minPrice.toString();
    }
    if (maxPrice != null && maxPrice > 0) {
      queryParams['maxPrice'] = maxPrice.toString();
    }
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    if (amenities != null && amenities.isNotEmpty) {
      queryParams['amenities'] = amenities;
    }
    if (q != null && q.isNotEmpty) queryParams['q'] = q;
    if (provinceCode != null && provinceCode.isNotEmpty) {
      queryParams['provinceCode'] = provinceCode;
    }
    if (cityId != null && cityId.isNotEmpty) {
      queryParams['cityId'] = cityId;
    }

    final uri = Uri(
      path: '/properties',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final result = await request(uri.toString());
    final properties = result['properties'] as List<dynamic>? ?? [];
    return properties
        .map((item) => propertyFromApi(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<HostPayout>> listPayouts({String? status}) async {
    final query = status != null && status.isNotEmpty ? '?status=$status' : '';
    final result = await request('/payouts$query');
    final payouts = result['payouts'] as List<dynamic>? ?? [];
    return payouts
        .map((item) => HostPayout.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<HostPayout> requestPayout(
    String bookingId,
    String bakongAccount,
  ) async {
    final result = await request(
      '/payouts',
      method: 'POST',
      body: {'bookingId': bookingId, 'bakongAccount': bakongAccount},
    );
    return HostPayout.fromJson(result['payout'] as Map<String, dynamic>);
  }

  Future<double> fetchExchangeRate() async {
    try {
      final result = await request('/currency/rates');
      final rate = (result['rate'] as num?)?.toDouble();
      if (rate != null && rate > 0) return rate;
    } catch (_) {}
    return 4100.0;
  }

  Future<String> uploadImage(List<int> bytes, String filename) async {
    if (bytes.length > 5 << 20) {
      throw ApiException('Image must be 5 MB or smaller');
    }
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$apiBaseUrl/uploads'),
    );
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );
    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 201) {
      throw ApiException(body['error']?.toString() ?? 'Upload failed');
    }
    return body['url'] as String;
  }
}

String _text(dynamic value) => value?.toString() ?? '';
double _number(dynamic value) => value is num ? value.toDouble() : 0;
int _integer(dynamic value) => value is num ? value.toInt() : 0;

Property propertyFromApi(Map<String, dynamic> data) {
  final id = _text(data['id']);
  final existing = mockProperties
      .where((property) => property.id == id)
      .firstOrNull;
  final rawRooms = data['roomTypes'] as List<dynamic>? ?? [];
  final rooms = rawRooms.map((raw) {
    final room = raw as Map<String, dynamic>;
    return RoomType(
      id: _text(room['id']),
      name: LocalizedCopy(_text(room['name']), _text(room['nameKm'])),
      bed: LocalizedCopy(_text(room['bed']), _text(room['bed'])),
      guests: _integer(room['guests']),
      priceUsd: _number(room['price']),
      roomsLeft: _integer(room['inventory']),
    );
  }).toList();
  final status = switch (_text(data['status'])) {
    'Published' => ListingStatus.published,
    'Draft' => ListingStatus.draft,
    'Paused' => ListingStatus.paused,
    _ => ListingStatus.needsChanges,
  };
  final image = _text(data['image']);
  final asset = switch (image) {
    '/images/siem-reap-homestay.png' => 'assets/images/siem_reap_homestay.png',
    '/images/kampot-riverside.png' => 'assets/images/kampot_riverside.png',
    '/images/kep-coastal.png' => 'assets/images/kep_coastal.png',
    '/images/mondulkiri-lodge.png' => 'assets/images/mondulkiri_lodge.png',
    _ =>
      image.startsWith('/uploads/')
          ? '$apiBaseUrl$image'
          : (existing?.image ?? 'assets/images/siem_reap_homestay.png'),
  };
  final province = _text(data['province']);
  final provinceKm = _text(data['provinceKm']);
  final city = _text(data['city']);
  final cityKm = _text(data['cityKm']);
  final englishLocation = city.isNotEmpty && city != province
      ? '$city, $province'
      : province;
  final khmerLocation = cityKm.isNotEmpty && cityKm != provinceKm
      ? '$cityKm, $provinceKm'
      : provinceKm;
  return Property(
    id: id,
    name: LocalizedCopy(_text(data['name']), _text(data['nameKm'])),
    location: LocalizedCopy(englishLocation, khmerLocation),
    type: LocalizedCopy(_text(data['type']), _text(data['type'])),
    description: LocalizedCopy(
      _text(data['description']),
      _text(data['descriptionKm']),
    ),
    image: asset,
    priceUsd: _number(data['price']),
    rating: _number(data['rating']),
    reviewCount: _integer(data['reviewCount']),
    category: _text(data['category']),
    owner:
        existing?.owner ??
        OwnerProfile(
          id: _text(data['ownerId']),
          name: _text(data['owner']),
          story: const LocalizedCopy('', ''),
          yearsHosting: 0,
          responseRate: 0,
        ),
    rooms: rooms,
    amenities: existing?.amenities ?? const [],
    status: status,
    isGuestFavorite: existing?.isGuestFavorite ?? false,
    provinceCode: _text(data['provinceCode']),
    city: LocalizedCopy(city, cityKm),
    cityId: _text(data['cityId']),
    recommendationScore: _number(data['recommendationScore']),
    recommendationReason: _text(data['recommendationReason']),
  );
}

Booking bookingFromApi(Map<String, dynamic> data) => Booking(
  id: _text(data['id']),
  reference: _text(data['id']),
  propertyId: _text(data['propertyId']),
  roomName: _text(data['room']),
  start: DateTime.parse(_text(data['checkIn'])),
  end: DateTime.parse(_text(data['checkOut'])),
  guests: _integer(data['guests']),
  totalUsd: _number(data['total']),
  status: switch (_text(data['status'])) {
    'Pending' || 'New request' => BookingStatus.pending,
    'Confirmed' => BookingStatus.confirmed,
    'Checked in' => BookingStatus.ongoing,
    'Completed' => BookingStatus.past,
    'Cancelled' || 'Declined' => BookingStatus.cancelled,
    _ => BookingStatus.upcoming,
  },
  guest: BookingGuest(
    name: _text(data['guest']),
    email: _text(data['guestEmail']),
    phone: _text(data['guestPhone']),
  ),
  specialRequest: _text(data['specialRequest']),
);
