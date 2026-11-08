import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/app_state.dart';
import '../../core/mock/mock_data.dart';
import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../startup/startup_screens.dart';

class TravelerShell extends StatelessWidget {
  const TravelerShell({super.key, required this.tab});
  final String tab;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final tabs = ['explore', 'wishlists', 'trips', 'inbox', 'profile'];
    final index = tabs.indexOf(tab).clamp(0, tabs.length - 1);
    final pages = [
      const ExploreScreen(),
      const WishlistScreen(),
      const TripsScreen(),
      const InboxScreen(),
      const TravelerProfileScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        key: const Key('traveler-navigation'),
        selectedIndex: index,
        onDestinationSelected: (value) =>
            context.go('/traveler/${tabs[value]}'),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.explore_outlined),
            selectedIcon: const Icon(Icons.explore_rounded),
            label: s.explore,
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_border_rounded),
            selectedIcon: const Icon(Icons.favorite_rounded),
            label: s.wishlists,
          ),
          NavigationDestination(
            icon: const Icon(Icons.luggage_outlined),
            selectedIcon: const Icon(Icons.luggage_rounded),
            label: s.trips,
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: const Icon(Icons.chat_bubble_rounded),
            label: s.inbox,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: s.profile,
          ),
        ],
      ),
    );
  }
}

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    final recommendationIds = ref.watch(
      appControllerProvider.select((state) => state.recommendedPropertyIds),
    );
    final propertiesById = {for (final item in mockProperties) item.id: item};
    final recommended = recommendationIds
        .map((id) => propertiesById[id])
        .whereType<Property>()
        .toList();
    if (recommended.isEmpty) recommended.addAll(mockProperties.take(6));
    return CustomScrollView(
      key: const PageStorageKey('explore-scroll'),
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.greeting, style: Theme.of(context).textTheme.titleMedium),
              Text(s.tagline, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          actions: [
            IconButton(
              tooltip: s.notifications,
              onPressed: () => context.push('/notifications'),
              icon: Badge(child: const Icon(Icons.notifications_none_rounded)),
            ),
            const SizedBox(width: 8),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              elevation: 2,
              shadowColor: AppColors.brown.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                key: const Key('destination-search'),
                borderRadius: BorderRadius.circular(22),
                onTap: () => context.push('/search'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.white,
                        child: Icon(Icons.search_rounded),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.whereGo,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${s.anywhere} · ${s.addDates} · ${s.guests}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.tune_rounded),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: SectionHeading(title: s.categories)),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _Category(
                  icon: Icons.account_balance_outlined,
                  label: localized(context, 'Heritage', 'បេតិកភណ្ឌ'),
                ),
                _Category(
                  icon: Icons.grass_rounded,
                  label: localized(context, 'Countryside', 'ជនបទ'),
                ),
                _Category(
                  icon: Icons.water_rounded,
                  label: localized(context, 'Riverside', 'មាត់ទន្លេ'),
                ),
                _Category(
                  icon: Icons.beach_access_rounded,
                  label: localized(context, 'Beach', 'ឆ្នេរ'),
                ),
                _Category(
                  icon: Icons.landscape_outlined,
                  label: localized(context, 'Mountain', 'ភ្នំ'),
                ),
                _Category(
                  icon: Icons.eco_outlined,
                  label: localized(context, 'Eco stay', 'អេកូ'),
                ),
                _Category(
                  icon: Icons.location_city_outlined,
                  label: localized(context, 'City', 'ទីក្រុង'),
                ),
              ],
            ),
          ),
        ),
        if (mockProperties.isNotEmpty)
          SliverToBoxAdapter(child: SectionHeading(title: s.featured)),
        if (mockProperties.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _FeaturedBanner(
                property: recommended.isNotEmpty
                    ? recommended.first
                    : mockProperties.first,
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: SectionHeading(
            title: s.recommended,
            action: s.viewAll,
            onTap: () => context.push('/search'),
          ),
        ),
        SliverToBoxAdapter(
          child: _PropertyRail(properties: recommended.take(6).toList()),
        ),
        SliverToBoxAdapter(child: SectionHeading(title: s.guestFavorites)),
        SliverToBoxAdapter(
          child: _PropertyRail(
            properties: mockProperties
                .where((item) => item.isGuestFavorite)
                .toList(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 4),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.brown,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.spa_outlined,
                    color: AppColors.champagne,
                    size: 34,
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localized(
                            context,
                            'Travel gently',
                            'ធ្វើដំណើរដោយយកចិត្តទុកដាក់',
                          ),
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          localized(
                            context,
                            'Your booking supports Cambodian hosts and communities.',
                            'ការកក់របស់អ្នកគាំទ្រម្ចាស់ផ្ទះ និងសហគមន៍កម្ពុជា។',
                          ),
                          style: const TextStyle(color: AppColors.sandstone),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: SectionHeading(title: s.countryside)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.crossAxisExtent >= 720
                  ? 3
                  : constraints.crossAxisExtent >= 480
                  ? 2
                  : 1;
              return SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => PropertyCard(
                    property: mockProperties[6 + index],
                    width: double.infinity,
                  ),
                  childCount: mockProperties.length > 6
                      ? mockProperties.length - 6
                      : 0,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisExtent:
                      330 +
                      (150 * (MediaQuery.textScalerOf(context).scale(1) - 1)),
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 16,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Category extends StatelessWidget {
  const _Category({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(end: 8),
    child: ActionChip(
      onPressed: () => context.push('/search?category=$label'),
      avatar: Icon(icon, size: 19),
      label: Text(label),
    ),
  );
}

class _FeaturedBanner extends StatelessWidget {
  const _FeaturedBanner({required this.property});
  final Property property;
  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return AspectRatio(
      aspectRatio: 1.75,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => context.push('/property/${property.id}'),
          child: Stack(
            fit: StackFit.expand,
            children: [
              stayImage(property.image, fit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC211710)],
                  ),
                ),
              ),
              PositionedDirectional(
                start: 20,
                end: 70,
                bottom: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.location.resolve(locale),
                      style: const TextStyle(
                        color: AppColors.champagne,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      property.name.resolve(locale),
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
              PositionedDirectional(
                end: 12,
                top: 12,
                child: FavoriteButton(propertyId: property.id, onImage: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PropertyRail extends StatelessWidget {
  const _PropertyRail({required this.properties});
  final List<Property> properties;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 340 + (140 * (MediaQuery.textScalerOf(context).scale(1) - 1)),
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemBuilder: (context, index) =>
          PropertyCard(property: properties[index]),
      separatorBuilder: (_, _) => const SizedBox(width: 16),
      itemCount: properties.length,
    ),
  );
}

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  final List<String> collections = ['Cambodia dream stays', 'Quiet weekends'];

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final favorites = ref.watch(
      appControllerProvider.select((state) => state.favorites),
    );
    final properties = mockProperties
        .where((item) => favorites.contains(item.id))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(s.wishlists),
        actions: [
          IconButton(
            onPressed: _createCollection,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: properties.isEmpty
          ? EmptyState(
              icon: Icons.favorite_border_rounded,
              title: localized(
                context,
                'Save the stays you love',
                'រក្សាកន្លែងដែលអ្នកពេញចិត្ត',
              ),
              body: localized(
                context,
                'Tap the heart on any stay to find it here.',
                'ចុចរូបបេះដូងលើទីតាំងណាមួយ ដើម្បីមើលវានៅទីនេះ។',
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                for (var index = 0; index < collections.length; index++) ...[
                  _WishlistHeader(
                    title: collections[index],
                    count: index == 0 ? properties.length : 0,
                    onRename: () => _rename(index),
                    onDelete: () => _delete(index),
                  ),
                  if (index == 0)
                    ...properties.map(
                      (property) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CompactPropertyCard(property: property),
                      ),
                    )
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          localized(
                            context,
                            'This collection is ready for your next find.',
                            'បញ្ជីនេះរង់ចាំកន្លែងដែលអ្នកនឹងរកឃើញបន្ទាប់។',
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                ],
              ],
            ),
    );
  }

  Future<void> _createCollection() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localized(context, 'New wishlist', 'បញ្ជីចំណូលចិត្តថ្មី')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: localized(context, 'Name', 'ឈ្មោះ'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(AppLocalizations.of(context).done),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && value.isNotEmpty) {
      setState(() => collections.add(value));
    }
  }

  Future<void> _rename(int index) async {
    final controller = TextEditingController(text: collections[index]);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localized(context, 'Rename wishlist', 'ប្ដូរឈ្មោះបញ្ជី')),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(AppLocalizations.of(context).saveChanges),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && value.isNotEmpty) {
      setState(() => collections[index] = value);
    }
  }

  Future<void> _delete(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          localized(context, 'Delete this wishlist?', 'លុបបញ្ជីនេះ?'),
        ),
        content: Text(
          localized(
            context,
            'Saved stays will remain in your other collections.',
            'កន្លែងដែលបានរក្សាទុកនឹងនៅតែមានក្នុងបញ្ជីផ្សេងទៀត។',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(localized(context, 'Delete', 'លុប')),
          ),
        ],
      ),
    );
    if (confirmed == true) setState(() => collections.removeAt(index));
  }
}

class _WishlistHeader extends StatelessWidget {
  const _WishlistHeader({
    required this.title,
    required this.count,
    required this.onRename,
    required this.onDelete,
  });
  final String title;
  final int count;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            Text(
              '$count ${AppLocalizations.of(context).listings.toLowerCase()}',
            ),
          ],
        ),
      ),
      PopupMenuButton<String>(
        onSelected: (value) => value == 'rename' ? onRename() : onDelete(),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'rename',
            child: Text(localized(context, 'Rename', 'ប្ដូរឈ្មោះ')),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Text(localized(context, 'Delete', 'លុប')),
          ),
        ],
      ),
    ],
  );
}

class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

bool bookingBelongsToTripTab(
  BookingStatus bookingStatus,
  BookingStatus tabStatus,
) {
  if (tabStatus == BookingStatus.upcoming) {
    return bookingStatus == BookingStatus.upcoming ||
        bookingStatus == BookingStatus.pending ||
        bookingStatus == BookingStatus.confirmed;
  }
  return bookingStatus == tabStatus;
}

class _TripsScreenState extends ConsumerState<TripsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final bookings = ref.watch(
      appControllerProvider.select((state) => state.bookings),
    );
    final statuses = [
      BookingStatus.upcoming,
      BookingStatus.ongoing,
      BookingStatus.past,
      BookingStatus.cancelled,
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(s.trips),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: [
            Tab(text: s.upcoming),
            Tab(text: s.ongoing),
            Tab(text: s.past),
            Tab(text: s.cancelled),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          for (final status in statuses)
            Builder(
              builder: (context) {
                final items = bookings
                    .where(
                      (booking) =>
                          bookingBelongsToTripTab(booking.status, status),
                    )
                    .toList();
                if (items.isEmpty) {
                  return EmptyState(
                    icon: Icons.luggage_outlined,
                    title: localized(
                      context,
                      'No trips here yet',
                      'មិនទាន់មានការកក់នៅទីនេះទេ',
                    ),
                    body: localized(
                      context,
                      'Your stays will appear here when the time is right.',
                      'កន្លែងស្នាក់របស់អ្នកនឹងបង្ហាញនៅទីនេះ។',
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) =>
                      _TripCard(booking: items[index]),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _TripCard extends ConsumerWidget {
  const _TripCard({required this.booking});
  final Booking booking;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final property = mockProperties.firstWhere(
      (item) => item.id == booking.propertyId,
    );
    final locale = Localizations.localeOf(context);
    final s = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: stayImage(
                    property.image,
                    width: 104,
                    height: 92,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.name.resolve(locale),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${DateFormat.MMMd(locale.languageCode).format(booking.start)} – ${DateFormat.MMMd(locale.languageCode).format(booking.end)}',
                      ),
                      const SizedBox(height: 5),
                      Text(
                        booking.reference,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(s.demoDirections))),
                    icon: const Icon(Icons.directions_outlined),
                    label: Text(localized(context, 'Directions', 'ទិសដៅ')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () async {
                      final conversation = ref
                          .read(appControllerProvider)
                          .conversations
                          .where(
                            (item) => item.propertyId == booking.propertyId,
                          )
                          .firstOrNull;
                      if (conversation != null) {
                        context.push('/conversation/${conversation.id}');
                        return;
                      }
                      try {
                        final id = await ref
                            .read(appControllerProvider.notifier)
                            .startConversation(
                              type: 'property',
                              propertyId: booking.propertyId,
                            );
                        if (context.mounted) context.push('/conversation/$id');
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.toString())),
                          );
                        }
                      }
                    },
                    child: Text(localized(context, 'Contact', 'ទាក់ទង')),
                  ),
                ),
              ],
            ),
            if (booking.status == BookingStatus.upcoming) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _cancel(context, ref),
                child: Text(localized(context, 'Cancel booking', 'លុបការកក់')),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          localized(context, 'Cancel this booking?', 'លុបការកក់នេះ?'),
        ),
        content: Text(
          localized(
            context,
            'This demo will move the booking to Cancelled.',
            'ការសាកល្បងនេះនឹងផ្លាស់ការកក់ទៅបានលុបចោល។',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(localized(context, 'Confirm', 'បញ្ជាក់')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref
          .read(appControllerProvider.notifier)
          .updateBookingStatus(booking.id, BookingStatus.cancelled);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localized(context, 'Booking cancelled', 'ការកក់បានលុបចោល'),
            ),
          ),
        );
      }
    }
  }
}

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    final conversations = ref.watch(
      appControllerProvider.select((state) => state.conversations),
    );
    return Scaffold(
      appBar: AppBar(title: Text(s.inbox)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: s.search,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
              itemCount: conversations.length,
              separatorBuilder: (_, _) => const Divider(indent: 76),
              itemBuilder: (context, index) {
                final item = conversations[index];
                final property = mockProperties
                    .where((property) => property.id == item.propertyId)
                    .firstOrNull;
                return ListTile(
                  minVerticalPadding: 12,
                  leading: CircleAvatar(
                    backgroundImage: property == null
                        ? null
                        : stayImageProvider(property.image),
                    radius: 27,
                    child: property == null
                        ? const Icon(Icons.support_agent_rounded)
                        : null,
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: TextStyle(
                            fontWeight: item.unread
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (item.unread) const Badge(),
                    ],
                  ),
                  subtitle: Text(
                    item.messages.isEmpty
                        ? localized(
                            context,
                            'Start a conversation',
                            'ចាប់ផ្តើមការសន្ទនា',
                          )
                        : item.messages.last.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => context.push('/conversation/${item.id}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TravelerProfileScreen extends ConsumerWidget {
  const TravelerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.profile)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 34,
                    backgroundColor: AppColors.sandstone,
                    child: Icon(
                      Icons.person_rounded,
                      size: 34,
                      color: AppColors.brown,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dara Sok',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          localized(
                            context,
                            'Verified demo traveler',
                            'អ្នកដំណើរសាកល្បងដែលបានផ្ទៀងផ្ទាត់',
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _editProfile(context),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _SettingsTile(
            icon: Icons.person_outline_rounded,
            title: s.personalInfo,
            onTap: () => _editProfile(context),
          ),
          ListTile(
            leading: const Icon(Icons.translate_rounded),
            title: Text(s.language),
            subtitle: Text(
              state.locale.languageCode == 'km' ? s.khmer : s.english,
            ),
            trailing: const Icon(Icons.swap_horiz_rounded),
            onTap: () => ref
                .read(appControllerProvider.notifier)
                .setLocale(
                  Locale(state.locale.languageCode == 'km' ? 'en' : 'km'),
                ),
          ),
          ListTile(
            leading: const Icon(Icons.payments_outlined),
            title: Text(s.currency),
            subtitle: Text(
              state.currency == CurrencyChoice.khr ? 'KHR · ៛' : 'USD · \$',
            ),
            trailing: Switch(
              value: state.currency == CurrencyChoice.usd,
              onChanged: (value) => ref
                  .read(appControllerProvider.notifier)
                  .setCurrency(value ? CurrencyChoice.usd : CurrencyChoice.khr),
            ),
          ),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: s.notificationSettings,
            onTap: () => context.push('/notifications'),
          ),
          _SettingsTile(
            icon: Icons.shield_outlined,
            title: s.privacySecurity,
            onTap: () => _info(context, s.privacySecurity),
          ),
          _SettingsTile(
            icon: Icons.help_outline_rounded,
            title: s.helpCenter,
            onTap: () async {
              try {
                final id = await ref
                    .read(appControllerProvider.notifier)
                    .startConversation(
                      type: 'support',
                      subject: 'Traveler support',
                    );
                if (context.mounted) context.push('/conversation/$id');
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(error.toString())));
                }
              }
            },
          ),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: s.about,
            onTap: () => _info(context, s.about),
          ),
          const LotusDivider(),
          _SettingsTile(
            key: const Key('switch-owner'),
            icon: Icons.home_work_outlined,
            title: s.switchOwner,
            onTap: () async {
              await ref.read(apiClientProvider).logout();
              await ref
                  .read(appControllerProvider.notifier)
                  .setRole(AppRole.owner);
              if (context.mounted) context.go('/signin');
            },
          ),
          _SettingsTile(
            icon: Icons.logout_rounded,
            title: s.signOut,
            onTap: () => _signOut(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _editProfile(BuildContext context) async {
    final controller = TextEditingController(text: 'Dara Sok');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocalizations.of(context).personalInfo,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).fullName,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).saveChanges),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  void _info(BuildContext context, String title) => showModalBottomSheet<void>(
    context: context,
    builder: (context) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(
            localized(
              context,
              'This section is included as a safe, local demo. No personal data leaves this device.',
              'ផ្នែកនេះជាការសាកល្បងក្នុងឧបករណ៍។ មិនមានទិន្នន័យផ្ទាល់ខ្លួនចាកចេញពីឧបករណ៍នេះទេ។',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).done),
          ),
        ],
      ),
    ),
  );

  void _signOut(BuildContext context, WidgetRef ref) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(AppLocalizations.of(context).signOut),
      content: Text(
        localized(
          context,
          'Return to the demo welcome screen?',
          'ត្រឡប់ទៅទំព័រស្វាគមន៍សាកល្បង?',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context).cancel),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(context);
            await ref.read(apiClientProvider).logout();
            if (context.mounted) context.go('/welcome');
          },
          child: Text(AppLocalizations.of(context).signOut),
        ),
      ],
    ),
  );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    leading: Icon(icon),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}
