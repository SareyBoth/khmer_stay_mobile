import 'package:flutter/widgets.dart';

enum AppRole { traveler, owner }

enum CurrencyChoice { khr, usd }

enum BookingStatus { upcoming, ongoing, past, cancelled, pending, confirmed }

enum ListingStatus { published, draft, paused, needsChanges }

@immutable
class LocalizedCopy {
  const LocalizedCopy(this.en, this.km);

  final String en;
  final String km;

  String resolve(Locale locale) => locale.languageCode == 'km' ? km : en;
}

@immutable
class Amenity {
  const Amenity({required this.label, required this.icon});

  final LocalizedCopy label;
  final IconData icon;
}

@immutable
class RoomType {
  const RoomType({
    required this.id,
    required this.name,
    required this.bed,
    required this.guests,
    required this.priceUsd,
    required this.roomsLeft,
  });

  final String id;
  final LocalizedCopy name;
  final LocalizedCopy bed;
  final int guests;
  final double priceUsd;
  final int roomsLeft;
}

@immutable
class OwnerProfile {
  const OwnerProfile({
    required this.id,
    required this.name,
    required this.story,
    required this.yearsHosting,
    required this.responseRate,
  });

  final String id;
  final String name;
  final LocalizedCopy story;
  final int yearsHosting;
  final int responseRate;
}

@immutable
class Review {
  const Review({
    required this.id,
    required this.author,
    required this.rating,
    required this.date,
    required this.comment,
  });

  final String id;
  final String author;
  final double rating;
  final DateTime date;
  final LocalizedCopy comment;
}

@immutable
class Property {
  const Property({
    required this.id,
    required this.name,
    required this.location,
    required this.type,
    required this.description,
    required this.image,
    required this.priceUsd,
    required this.rating,
    required this.reviewCount,
    required this.category,
    required this.owner,
    required this.rooms,
    required this.amenities,
    required this.status,
    this.isGuestFavorite = false,
    this.provinceCode = '',
    this.city = const LocalizedCopy('', ''),
    this.cityId = '',
    this.recommendationScore = 0,
    this.recommendationReason = '',
  });

  final String id;
  final LocalizedCopy name;
  final LocalizedCopy location;
  final LocalizedCopy type;
  final LocalizedCopy description;
  final String image;
  final double priceUsd;
  final double rating;
  final int reviewCount;
  final String category;
  final OwnerProfile owner;
  final List<RoomType> rooms;
  final List<Amenity> amenities;
  final ListingStatus status;
  final bool isGuestFavorite;
  final String provinceCode;
  final LocalizedCopy city;
  final String cityId;
  final double recommendationScore;
  final String recommendationReason;
}

@immutable
class BookingGuest {
  const BookingGuest({
    required this.name,
    required this.email,
    required this.phone,
  });

  final String name;
  final String email;
  final String phone;
}

@immutable
class Booking {
  const Booking({
    required this.id,
    required this.reference,
    required this.propertyId,
    required this.roomName,
    required this.start,
    required this.end,
    required this.guests,
    required this.totalUsd,
    required this.status,
    required this.guest,
    this.specialRequest = '',
  });

  final String id;
  final String reference;
  final String propertyId;
  final String roomName;
  final DateTime start;
  final DateTime end;
  final int guests;
  final double totalUsd;
  final BookingStatus status;
  final BookingGuest guest;
  final String specialRequest;

  Booking copyWith({BookingStatus? status}) => Booking(
    id: id,
    reference: reference,
    propertyId: propertyId,
    roomName: roomName,
    start: start,
    end: end,
    guests: guests,
    totalUsd: totalUsd,
    status: status ?? this.status,
    guest: guest,
    specialRequest: specialRequest,
  );
}

@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.sentAt,
    required this.fromMe,
  });

  final String id;
  final String text;
  final DateTime sentAt;
  final bool fromMe;
}

@immutable
class Conversation {
  const Conversation({
    required this.id,
    required this.name,
    required this.propertyId,
    required this.unread,
    required this.messages,
    this.kind = 'property',
    this.subject = '',
  });

  final String id;
  final String name;
  final String propertyId;
  final bool unread;
  final List<ChatMessage> messages;
  final String kind;
  final String subject;

  Conversation copyWith({bool? unread, List<ChatMessage>? messages}) =>
      Conversation(
        id: id,
        name: name,
        propertyId: propertyId,
        unread: unread ?? this.unread,
        messages: messages ?? this.messages,
        kind: kind,
        subject: subject,
      );
}

@immutable
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    this.read = false,
  });

  final String id;
  final LocalizedCopy title;
  final LocalizedCopy body;
  final DateTime time;
  final IconData icon;
  final bool read;

  NotificationItem copyWith({bool? read}) => NotificationItem(
    id: id,
    title: title,
    body: body,
    time: time,
    icon: icon,
    read: read ?? this.read,
  );
}

@immutable
class OwnerDashboardStats {
  const OwnerDashboardStats({
    required this.earningsUsd,
    required this.occupancy,
    required this.bookings,
    required this.rating,
  });

  final double earningsUsd;
  final double occupancy;
  final int bookings;
  final double rating;
}

@immutable
class EarningTransaction {
  const EarningTransaction({
    required this.id,
    required this.propertyId,
    required this.date,
    required this.amountUsd,
    required this.completed,
  });

  final String id;
  final String propertyId;
  final DateTime date;
  final double amountUsd;
  final bool completed;
}

@immutable
class HostPayout {
  const HostPayout({
    required this.id,
    required this.ownerId,
    required this.bookingId,
    required this.grossAmount,
    required this.commissionRate,
    required this.commissionAmount,
    required this.netAmount,
    required this.currency,
    required this.bakongAccount,
    required this.status,
    required this.reference,
    required this.createdAt,
    this.paidAt,
    this.propertyName,
    this.guestName,
  });

  final String id;
  final String ownerId;
  final String bookingId;
  final double grossAmount;
  final double commissionRate;
  final double commissionAmount;
  final double netAmount;
  final String currency;
  final String bakongAccount;
  final String status; // Pending, Processing, Paid, Declined
  final String reference;
  final DateTime createdAt;
  final DateTime? paidAt;
  final String? propertyName;
  final String? guestName;

  factory HostPayout.fromJson(Map<String, dynamic> json) => HostPayout(
    id: json['id']?.toString() ?? '',
    ownerId: json['ownerId']?.toString() ?? '',
    bookingId: json['bookingId']?.toString() ?? '',
    grossAmount: (json['grossAmount'] as num?)?.toDouble() ?? 0,
    commissionRate: (json['commissionRate'] as num?)?.toDouble() ?? 15,
    commissionAmount: (json['commissionAmount'] as num?)?.toDouble() ?? 0,
    netAmount: (json['netAmount'] as num?)?.toDouble() ?? 0,
    currency: json['currency']?.toString() ?? 'USD',
    bakongAccount: json['bakongAccount']?.toString() ?? '',
    status: json['status']?.toString() ?? 'Pending',
    reference: json['reference']?.toString() ?? '',
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
        : DateTime.now(),
    paidAt: json['paidAt'] != null
        ? DateTime.tryParse(json['paidAt'].toString())
        : null,
    propertyName: json['propertyName']?.toString(),
    guestName: json['guestName']?.toString(),
  );
}
