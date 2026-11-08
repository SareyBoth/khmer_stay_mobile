import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/owner/owner_screens.dart';
import '../features/owner/pricing_live_screen.dart';
import '../features/owner/rooms_live_screen.dart';
import '../features/owner/owner_reviews_live_screen.dart';
import '../features/owner/owner_calendar_live_screen.dart';
import '../features/startup/startup_screens.dart';
import '../features/traveler/traveler_detail_screens.dart';
import '../features/traveler/payment_screen.dart';
import '../features/traveler/traveler_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/setup',
      builder: (context, state) => const PreferenceSetupScreen(),
    ),
    GoRoute(
      path: '/role',
      builder: (context, state) => const RoleSelectionScreen(),
    ),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/signin',
      pageBuilder: (context, state) =>
          _page(state, const AuthScreen(kind: AuthKind.signIn)),
    ),
    GoRoute(
      path: '/phone',
      pageBuilder: (context, state) =>
          _page(state, const AuthScreen(kind: AuthKind.phone)),
    ),
    GoRoute(
      path: '/otp',
      pageBuilder: (context, state) =>
          _page(state, const AuthScreen(kind: AuthKind.otp)),
    ),
    GoRoute(
      path: '/create-account',
      pageBuilder: (context, state) =>
          _page(state, const AuthScreen(kind: AuthKind.create)),
    ),
    GoRoute(
      path: '/forgot',
      pageBuilder: (context, state) =>
          _page(state, const AuthScreen(kind: AuthKind.forgot)),
    ),
    GoRoute(
      path: '/traveler/:tab',
      builder: (context, state) =>
          TravelerShell(tab: state.pathParameters['tab'] ?? 'explore'),
    ),
    GoRoute(
      path: '/owner/:tab',
      builder: (context, state) =>
          OwnerShell(tab: state.pathParameters['tab'] ?? 'dashboard'),
    ),
    GoRoute(
      path: '/search',
      pageBuilder: (context, state) => _page(
        state,
        SearchScreen(initialCategory: state.uri.queryParameters['category']),
      ),
    ),
    GoRoute(
      path: '/property/:id',
      pageBuilder: (context, state) => _page(
        state,
        PropertyDetailsScreen(propertyId: state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/gallery/:id',
      pageBuilder: (context, state) =>
          _page(state, GalleryScreen(propertyId: state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/host/:id',
      pageBuilder: (context, state) =>
          _page(state, HostProfileScreen(ownerId: state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/reviews/:id',
      pageBuilder: (context, state) =>
          _page(state, ReviewsScreen(propertyId: state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/booking/:id',
      pageBuilder: (context, state) => _page(
        state,
        BookingScreen(
          propertyId: state.pathParameters['id']!,
          roomId: state.uri.queryParameters['room'],
        ),
      ),
    ),
    GoRoute(
      path: '/booking-success/:id',
      pageBuilder: (context, state) => _page(
        state,
        BookingSuccessScreen(bookingId: state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/payment/:id',
      pageBuilder: (context, state) =>
          _page(state, PaymentScreen(bookingId: state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/conversation/:id',
      pageBuilder: (context, state) => _page(
        state,
        ConversationScreen(conversationId: state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/notifications',
      pageBuilder: (context, state) =>
          _page(state, const NotificationsScreen()),
    ),
    GoRoute(
      path: '/owner/onboarding',
      pageBuilder: (context, state) =>
          _page(state, const OwnerOnboardingScreen()),
    ),
    GoRoute(
      path: '/owner/calendar',
      pageBuilder: (context, state) =>
          _page(state, const OwnerCalendarLiveScreen()),
    ),
    GoRoute(
      path: '/owner/property-wizard',
      pageBuilder: (context, state) =>
          _page(state, const PropertyWizardScreen()),
    ),
    GoRoute(
      path: '/owner/rooms',
      pageBuilder: (context, state) => _page(state, const RoomsLiveScreen()),
    ),
    GoRoute(
      path: '/owner/pricing',
      pageBuilder: (context, state) => _page(state, const PricingLiveScreen()),
    ),
    GoRoute(
      path: '/owner/earnings',
      pageBuilder: (context, state) => _page(state, const EarningsScreen()),
    ),
    GoRoute(
      path: '/owner/reviews',
      pageBuilder: (context, state) =>
          _page(state, const OwnerReviewsLiveScreen()),
    ),
  ],
);

CustomTransitionPage<void> _page(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(begin: const Offset(.025, .02), end: Offset.zero)
                  .animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          ),
    );
