import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_km.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('km'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'KhmerStay'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Stay closer to Cambodia'**
  String get tagline;

  /// No description provided for @demoMode.
  ///
  /// In en, this message translates to:
  /// **'Demo mode'**
  String get demoMode;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @onboardingOneTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover authentic Cambodian stays'**
  String get onboardingOneTitle;

  /// No description provided for @onboardingOneBody.
  ///
  /// In en, this message translates to:
  /// **'Find locally owned homes, thoughtful guesthouses, and quiet escapes across Cambodia.'**
  String get onboardingOneBody;

  /// No description provided for @onboardingTwoTitle.
  ///
  /// In en, this message translates to:
  /// **'Book safely and clearly'**
  String get onboardingTwoTitle;

  /// No description provided for @onboardingTwoBody.
  ///
  /// In en, this message translates to:
  /// **'See transparent prices, flexible choices, and every detail before you reserve.'**
  String get onboardingTwoBody;

  /// No description provided for @onboardingThreeTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect with local property owners'**
  String get onboardingThreeTitle;

  /// No description provided for @onboardingThreeBody.
  ///
  /// In en, this message translates to:
  /// **'Message welcoming hosts and travel with the confidence of local knowledge.'**
  String get onboardingThreeBody;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Your preferences'**
  String get preferences;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @khmer.
  ///
  /// In en, this message translates to:
  /// **'Khmer'**
  String get khmer;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @chooseRole.
  ///
  /// In en, this message translates to:
  /// **'How would you like to explore?'**
  String get chooseRole;

  /// No description provided for @traveler.
  ///
  /// In en, this message translates to:
  /// **'Traveler'**
  String get traveler;

  /// No description provided for @propertyOwner.
  ///
  /// In en, this message translates to:
  /// **'Property owner'**
  String get propertyOwner;

  /// No description provided for @continueTraveler.
  ///
  /// In en, this message translates to:
  /// **'Continue as Traveler'**
  String get continueTraveler;

  /// No description provided for @continueOwner.
  ///
  /// In en, this message translates to:
  /// **'Continue as Property Owner'**
  String get continueOwner;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @wishlists.
  ///
  /// In en, this message translates to:
  /// **'Wishlists'**
  String get wishlists;

  /// No description provided for @trips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get trips;

  /// No description provided for @inbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get inbox;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @bookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookings;

  /// No description provided for @listings.
  ///
  /// In en, this message translates to:
  /// **'Listings'**
  String get listings;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @ownerMode.
  ///
  /// In en, this message translates to:
  /// **'Owner mode'**
  String get ownerMode;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Good morning, Dara'**
  String get greeting;

  /// No description provided for @whereGo.
  ///
  /// In en, this message translates to:
  /// **'Where do you want to go?'**
  String get whereGo;

  /// No description provided for @anywhere.
  ///
  /// In en, this message translates to:
  /// **'Anywhere in Cambodia'**
  String get anywhere;

  /// No description provided for @addDates.
  ///
  /// In en, this message translates to:
  /// **'Add dates'**
  String get addDates;

  /// No description provided for @guests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get guests;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Browse by feeling'**
  String get categories;

  /// No description provided for @featured.
  ///
  /// In en, this message translates to:
  /// **'Featured destination'**
  String get featured;

  /// No description provided for @recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended for you'**
  String get recommended;

  /// No description provided for @nearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby stays'**
  String get nearby;

  /// No description provided for @guestFavorites.
  ///
  /// In en, this message translates to:
  /// **'Guest favorites'**
  String get guestFavorites;

  /// No description provided for @newStays.
  ///
  /// In en, this message translates to:
  /// **'New stays'**
  String get newStays;

  /// No description provided for @countryside.
  ///
  /// In en, this message translates to:
  /// **'Countryside escapes'**
  String get countryside;

  /// No description provided for @beach.
  ///
  /// In en, this message translates to:
  /// **'Beach stays'**
  String get beach;

  /// No description provided for @recentlyViewed.
  ///
  /// In en, this message translates to:
  /// **'Recently viewed'**
  String get recentlyViewed;

  /// No description provided for @perNight.
  ///
  /// In en, this message translates to:
  /// **'night'**
  String get perNight;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'reviews'**
  String get reviews;

  /// No description provided for @guestFavorite.
  ///
  /// In en, this message translates to:
  /// **'Guest favorite'**
  String get guestFavorite;

  /// No description provided for @searchStays.
  ///
  /// In en, this message translates to:
  /// **'Search stays'**
  String get searchStays;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get checkIn;

  /// No description provided for @checkOut.
  ///
  /// In en, this message translates to:
  /// **'Check-out'**
  String get checkOut;

  /// No description provided for @rooms.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get rooms;

  /// No description provided for @adults.
  ///
  /// In en, this message translates to:
  /// **'Adults'**
  String get adults;

  /// No description provided for @children.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get children;

  /// No description provided for @infants.
  ///
  /// In en, this message translates to:
  /// **'Infants'**
  String get infants;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @list.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get list;

  /// No description provided for @staysFound.
  ///
  /// In en, this message translates to:
  /// **'stays found'**
  String get staysFound;

  /// No description provided for @priceRange.
  ///
  /// In en, this message translates to:
  /// **'Price range'**
  String get priceRange;

  /// No description provided for @propertyType.
  ///
  /// In en, this message translates to:
  /// **'Property type'**
  String get propertyType;

  /// No description provided for @amenities.
  ///
  /// In en, this message translates to:
  /// **'Amenities'**
  String get amenities;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @showStays.
  ///
  /// In en, this message translates to:
  /// **'Show matching stays'**
  String get showStays;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No stays match these filters'**
  String get noResults;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @reserve.
  ///
  /// In en, this message translates to:
  /// **'Reserve'**
  String get reserve;

  /// No description provided for @aboutStay.
  ///
  /// In en, this message translates to:
  /// **'About this stay'**
  String get aboutStay;

  /// No description provided for @roomsAvailable.
  ///
  /// In en, this message translates to:
  /// **'Rooms available'**
  String get roomsAvailable;

  /// No description provided for @houseRules.
  ///
  /// In en, this message translates to:
  /// **'House rules'**
  String get houseRules;

  /// No description provided for @cancellation.
  ///
  /// In en, this message translates to:
  /// **'Cancellation policy'**
  String get cancellation;

  /// No description provided for @safety.
  ///
  /// In en, this message translates to:
  /// **'Safety information'**
  String get safety;

  /// No description provided for @localArea.
  ///
  /// In en, this message translates to:
  /// **'Around the area'**
  String get localArea;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @similarStays.
  ///
  /// In en, this message translates to:
  /// **'Similar stays'**
  String get similarStays;

  /// No description provided for @selectRoom.
  ///
  /// In en, this message translates to:
  /// **'Select a room'**
  String get selectRoom;

  /// No description provided for @guestDetails.
  ///
  /// In en, this message translates to:
  /// **'Guest details'**
  String get guestDetails;

  /// No description provided for @reviewPay.
  ///
  /// In en, this message translates to:
  /// **'Review and pay'**
  String get reviewPay;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phone;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @specialRequest.
  ///
  /// In en, this message translates to:
  /// **'Special request'**
  String get specialRequest;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethod;

  /// No description provided for @demoPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment status is recorded with your booking'**
  String get demoPayment;

  /// No description provided for @priceBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Price breakdown'**
  String get priceBreakdown;

  /// No description provided for @cleaningFee.
  ///
  /// In en, this message translates to:
  /// **'Cleaning fee'**
  String get cleaningFee;

  /// No description provided for @serviceFee.
  ///
  /// In en, this message translates to:
  /// **'Service fee'**
  String get serviceFee;

  /// No description provided for @taxes.
  ///
  /// In en, this message translates to:
  /// **'Taxes'**
  String get taxes;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @confirmBooking.
  ///
  /// In en, this message translates to:
  /// **'Continue to payment'**
  String get confirmBooking;

  /// No description provided for @bookingConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Your stay is confirmed'**
  String get bookingConfirmed;

  /// No description provided for @bookingReference.
  ///
  /// In en, this message translates to:
  /// **'Booking reference'**
  String get bookingReference;

  /// No description provided for @viewTrip.
  ///
  /// In en, this message translates to:
  /// **'View trip'**
  String get viewTrip;

  /// No description provided for @returnExplore.
  ///
  /// In en, this message translates to:
  /// **'Return to explore'**
  String get returnExplore;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @ongoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get ongoing;

  /// No description provided for @past.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get past;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllRead;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get personalInfo;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get notificationSettings;

  /// No description provided for @privacySecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy and security'**
  String get privacySecurity;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help center'**
  String get helpCenter;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About KhmerStay'**
  String get about;

  /// No description provided for @switchOwner.
  ///
  /// In en, this message translates to:
  /// **'Switch to owner mode'**
  String get switchOwner;

  /// No description provided for @switchTraveler.
  ///
  /// In en, this message translates to:
  /// **'Switch to traveler mode'**
  String get switchTraveler;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @earnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earnings;

  /// No description provided for @occupancy.
  ///
  /// In en, this message translates to:
  /// **'Occupancy'**
  String get occupancy;

  /// No description provided for @averageRating.
  ///
  /// In en, this message translates to:
  /// **'Average rating'**
  String get averageRating;

  /// No description provided for @todayArrivals.
  ///
  /// In en, this message translates to:
  /// **'Today\'s arrivals'**
  String get todayArrivals;

  /// No description provided for @pendingRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending requests'**
  String get pendingRequests;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// No description provided for @addProperty.
  ///
  /// In en, this message translates to:
  /// **'Add property'**
  String get addProperty;

  /// No description provided for @manageCalendar.
  ///
  /// In en, this message translates to:
  /// **'Manage calendar'**
  String get manageCalendar;

  /// No description provided for @updatePrices.
  ///
  /// In en, this message translates to:
  /// **'Update prices'**
  String get updatePrices;

  /// No description provided for @recentBookings.
  ///
  /// In en, this message translates to:
  /// **'Recent bookings'**
  String get recentBookings;

  /// No description provided for @published.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get published;

  /// No description provided for @draft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draft;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @saveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get saveDraft;

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Publish listing'**
  String get publish;

  /// No description provided for @propertyBasics.
  ///
  /// In en, this message translates to:
  /// **'Property basics'**
  String get propertyBasics;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @pricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get pricing;

  /// No description provided for @availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @booked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get booked;

  /// No description provided for @blocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blocked;

  /// No description provided for @blockDates.
  ///
  /// In en, this message translates to:
  /// **'Block dates'**
  String get blockDates;

  /// No description provided for @basePrice.
  ///
  /// In en, this message translates to:
  /// **'Base nightly price'**
  String get basePrice;

  /// No description provided for @weekendPrice.
  ///
  /// In en, this message translates to:
  /// **'Weekend price'**
  String get weekendPrice;

  /// No description provided for @weeklyDiscount.
  ///
  /// In en, this message translates to:
  /// **'Weekly discount'**
  String get weeklyDiscount;

  /// No description provided for @monthlyDiscount.
  ///
  /// In en, this message translates to:
  /// **'Monthly discount'**
  String get monthlyDiscount;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @verification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verification;

  /// No description provided for @inReview.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get inReview;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @signInPhone.
  ///
  /// In en, this message translates to:
  /// **'Sign in with email code'**
  String get signInPhone;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter verification code'**
  String get otpTitle;

  /// No description provided for @otpHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent to your email'**
  String get otpHint;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// No description provided for @validEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get validEmail;

  /// No description provided for @sixDigits.
  ///
  /// In en, this message translates to:
  /// **'Enter the six-digit email code'**
  String get sixDigits;

  /// No description provided for @demoDirections.
  ///
  /// In en, this message translates to:
  /// **'Directions are a visual demo; live GPS is not enabled.'**
  String get demoDirections;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @unsaved.
  ///
  /// In en, this message translates to:
  /// **'Removed from wishlist'**
  String get unsaved;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'km'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'km':
      return AppLocalizationsKm();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
