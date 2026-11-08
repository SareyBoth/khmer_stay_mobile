import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/app_state.dart';
import '../../core/api/api_client.dart';
import '../../core/mock/mock_data.dart';
import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../startup/startup_screens.dart';
import '../traveler/traveler_shell.dart';

class OwnerShell extends ConsumerWidget {
  const OwnerShell({super.key, required this.tab});
  final String tab;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    final tabs = ['dashboard', 'bookings', 'listings', 'inbox', 'account'];
    final index = tabs.indexOf(tab).clamp(0, tabs.length - 1);
    final newCount = ref.watch(
      appControllerProvider.select((s) => s.newBookingRequestsCount),
    );
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [
          OwnerDashboardScreen(),
          OwnerBookingsScreen(),
          OwnerListingsScreen(),
          InboxScreen(),
          OwnerAccountScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        key: const Key('owner-navigation'),
        selectedIndex: index,
        onDestinationSelected: (value) => context.go('/owner/${tabs[value]}'),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard_rounded),
            label: s.dashboard,
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: newCount > 0,
              label: Text('$newCount'),
              child: const Icon(Icons.event_note_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: newCount > 0,
              label: Text('$newCount'),
              child: const Icon(Icons.event_note_rounded),
            ),
            label: s.bookings,
          ),
          NavigationDestination(
            icon: const Icon(Icons.home_work_outlined),
            selectedIcon: const Icon(Icons.home_work_rounded),
            label: s.listings,
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: const Icon(Icons.chat_bubble_rounded),
            label: s.inbox,
          ),
          NavigationDestination(
            icon: const Icon(Icons.manage_accounts_outlined),
            selectedIcon: const Icon(Icons.manage_accounts_rounded),
            label: s.account,
          ),
        ],
      ),
    );
  }
}

class _OwnerHeader extends StatelessWidget implements PreferredSizeWidget {
  const _OwnerHeader({required this.title, this.actions});
  final String title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) => AppBar(
    toolbarHeight: 80,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.key_rounded, size: 17, color: AppColors.gold),
            const SizedBox(width: 5),
            Text(
              AppLocalizations.of(context).ownerMode,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.gold),
            ),
          ],
        ),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
      ],
    ),
    actions: actions,
  );
}

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);
    final pending = state.bookings
        .where((item) => item.status == BookingStatus.pending)
        .length;
    final earnings = state.bookings
        .where(
          (item) =>
              item.status != BookingStatus.pending &&
              item.status != BookingStatus.cancelled,
        )
        .fold<double>(0, (total, booking) => total + booking.totalUsd);
    final arrivals = state.bookings
        .where((item) => DateUtils.isSameDay(item.start, DateTime.now()))
        .length;
    return Scaffold(
      appBar: _OwnerHeader(
        title: localized(context, 'Good morning, Sophea', 'អរុណសួស្តី Sophea'),
        actions: [
          IconButton(
            onPressed: () {
              ref
                  .read(appControllerProvider.notifier)
                  .clearBookingRequestsBadge();
              context.push('/notifications');
            },
            icon: Badge(
              isLabelVisible: state.newBookingRequestsCount > 0,
              label: Text('${state.newBookingRequestsCount}'),
              child: const Icon(Icons.notifications_none_rounded),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          if (state.newBookingRequestsCount > 0)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Card(
                  color: AppColors.champagne.withValues(alpha: 0.18),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(
                      color: AppColors.champagne,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications_active_rounded,
                          color: AppColors.gold,
                          size: 32,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localized(
                                  context,
                                  'New Booking Request!',
                                  'មានសំណើកក់បន្ទប់ថ្មី!',
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                localized(
                                  context,
                                  'You have ${state.newBookingRequestsCount} new booking request(s) awaiting your review.',
                                  'អ្នកមានសំណើកក់ ${state.newBookingRequestsCount} ថ្មីរង់ចាំការពិនិត្យ។',
                                ),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          onPressed: () {
                            ref
                                .read(appControllerProvider.notifier)
                                .clearBookingRequestsBadge();
                            context.push('/owner/bookings');
                          },
                          child: Text(localized(context, 'View', 'មើល')),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Card(
                color: AppColors.brown,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const StatusBadge(
                              label: 'VERIFICATION · IN REVIEW',
                              color: AppColors.champagne,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              localized(
                                context,
                                'Your listing is live',
                                'ទីតាំងរបស់អ្នកកំពុងដំណើរការ',
                              ),
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              localized(
                                context,
                                'Keep availability fresh to welcome more guests.',
                                'រក្សាកាលបរិច្ឆេទទំនេរឱ្យថ្មី ដើម្បីទទួលភ្ញៀវកាន់តែច្រើន។',
                              ),
                              style: const TextStyle(
                                color: AppColors.sandstone,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.trending_up_rounded,
                        color: AppColors.champagne,
                        size: 48,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SectionHeading(
              title: localized(
                context,
                'Booking overview',
                'ទិដ្ឋភាពទូទៅការកក់',
              ),
              action: s.earnings,
              onTap: () => context.push('/owner/earnings'),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid.count(
              crossAxisCount: MediaQuery.sizeOf(context).width >= 700 ? 4 : 2,
              childAspectRatio:
                  1.25 /
                  MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                StatCard(
                  label: s.earnings,
                  value: formatPrice(earnings, state, compact: true),
                  icon: Icons.payments_outlined,
                ),
                StatCard(
                  label: s.occupancy,
                  value:
                      '${state.bookings.isEmpty ? 0 : (100 * state.bookings.where((item) => item.status != BookingStatus.cancelled).length / state.bookings.length).round()}%',
                  icon: Icons.bed_outlined,
                ),
                StatCard(
                  label: s.bookings,
                  value: '${state.bookings.length}',
                  icon: Icons.event_available_outlined,
                ),
                StatCard(
                  label: s.averageRating,
                  value: mockProperties.isEmpty
                      ? '—'
                      : (mockProperties
                                    .map((item) => item.rating)
                                    .reduce((a, b) => a + b) /
                                mockProperties.length)
                            .toStringAsFixed(2),
                  icon: Icons.star_outline_rounded,
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(child: SectionHeading(title: s.quickActions)),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 106,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                children: [
                  _QuickAction(
                    icon: Icons.add_home_work_outlined,
                    label: s.addProperty,
                    onTap: () => context.push('/owner/property-wizard'),
                  ),
                  _QuickAction(
                    icon: Icons.calendar_month_outlined,
                    label: s.manageCalendar,
                    onTap: () => context.push('/owner/calendar'),
                  ),
                  _QuickAction(
                    icon: Icons.payments_outlined,
                    label: s.updatePrices,
                    onTap: () => context.push('/owner/pricing'),
                  ),
                  _QuickAction(
                    icon: Icons.bed_outlined,
                    label: s.rooms,
                    onTap: () => context.push('/owner/rooms'),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SectionHeading(
              title: localized(context, 'Today', 'ថ្ងៃនេះ'),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.login_rounded),
                        ),
                        title: Text(s.todayArrivals),
                        subtitle: Text('$arrivals guests'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.pending_actions_outlined),
                        ),
                        title: Text(s.pendingRequests),
                        subtitle: Text('$pending'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SectionHeading(
              title: s.recentBookings,
              action: s.viewAll,
              onTap: () => context.go('/owner/bookings'),
            ),
          ),
          SliverList.separated(
            itemCount: state.bookings.length < 3 ? state.bookings.length : 3,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _OwnerBookingCard(
                booking: state.bookings.reversed.elementAt(index),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(end: 10),
    child: SizedBox(
      width: 112,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.gold),
                const SizedBox(height: 8),
                Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class OwnerBookingsScreen extends ConsumerStatefulWidget {
  const OwnerBookingsScreen({super.key});
  @override
  ConsumerState<OwnerBookingsScreen> createState() =>
      _OwnerBookingsScreenState();
}

class _OwnerBookingsScreenState extends ConsumerState<OwnerBookingsScreen> {
  BookingStatus? filter;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final all = ref.watch(
      appControllerProvider.select((state) => state.bookings),
    );
    final items = filter == null
        ? all
        : all.where((item) => item.status == filter).toList();
    final filters = <BookingStatus?, String>{
      null: localized(context, 'All', 'ទាំងអស់'),
      BookingStatus.pending: localized(context, 'New request', 'សំណើថ្មី'),
      BookingStatus.confirmed: localized(context, 'Confirmed', 'បានបញ្ជាក់'),
      BookingStatus.ongoing: localized(context, 'Checked in', 'បានចូលស្នាក់'),
      BookingStatus.past: localized(context, 'Completed', 'បានបញ្ចប់'),
      BookingStatus.cancelled: s.cancelled,
    };
    return Scaffold(
      appBar: _OwnerHeader(
        title: s.bookings,
        actions: [
          IconButton(
            onPressed: () => context.push('/owner/calendar'),
            icon: const Icon(Icons.calendar_month_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: Row(
              children: filters.entries
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ChoiceChip(
                        label: Text(entry.value),
                        selected: filter == entry.key,
                        onSelected: (_) => setState(() => filter = entry.key),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? EmptyState(
                    icon: Icons.event_busy_outlined,
                    title: localized(
                      context,
                      'No bookings in this status',
                      'គ្មានការកក់ក្នុងស្ថានភាពនេះ',
                    ),
                    body: localized(
                      context,
                      'Booking activity will appear here.',
                      'សកម្មភាពការកក់នឹងបង្ហាញនៅទីនេះ។',
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _OwnerBookingCard(booking: items[index], actions: true),
                  ),
          ),
        ],
      ),
    );
  }
}

class _OwnerBookingCard extends ConsumerWidget {
  const _OwnerBookingCard({required this.booking, this.actions = false});
  final Booking booking;
  final bool actions;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final property = mockProperties.firstWhere(
      (item) => item.id == booking.propertyId,
    );
    final locale = Localizations.localeOf(context);
    final color = switch (booking.status) {
      BookingStatus.pending => AppColors.terracotta,
      BookingStatus.cancelled => AppColors.error,
      BookingStatus.past => AppColors.sage,
      _ => AppColors.success,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.sandstone,
                  child: Text(
                    booking.guest.name.isEmpty
                        ? '?'
                        : booking.guest.name.characters.first,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.guest.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        property.name.resolve(locale),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${DateFormat.MMMd(locale.languageCode).format(booking.start)} – ${DateFormat.MMMd(locale.languageCode).format(booking.end)} · ${booking.guests} ${AppLocalizations.of(context).guests}',
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  label: _statusLabel(context, booking.status),
                  color: color,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  booking.reference,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                Text(
                  formatPrice(
                    booking.totalUsd,
                    ref.watch(appControllerProvider),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            if (booking.specialRequest.isNotEmpty) ...[
              const Divider(),
              Text(
                booking.specialRequest,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (actions) ...[
              const Divider(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => context.push('/conversation/c3'),
                    child: Text(localized(context, 'Message', 'ផ្ញើសារ')),
                  ),
                  if (booking.status == BookingStatus.pending) ...[
                    OutlinedButton(
                      onPressed: () => ref
                          .read(appControllerProvider.notifier)
                          .updateBookingStatus(
                            booking.id,
                            BookingStatus.cancelled,
                          ),
                      child: Text(localized(context, 'Decline', 'បដិសេធ')),
                    ),
                    FilledButton(
                      onPressed: () => ref
                          .read(appControllerProvider.notifier)
                          .updateBookingStatus(
                            booking.id,
                            BookingStatus.confirmed,
                          ),
                      child: Text(localized(context, 'Accept', 'ទទួលយក')),
                    ),
                  ] else if (booking.status == BookingStatus.confirmed)
                    FilledButton(
                      onPressed: () => ref
                          .read(appControllerProvider.notifier)
                          .updateBookingStatus(
                            booking.id,
                            BookingStatus.ongoing,
                          ),
                      child: Text(
                        localized(
                          context,
                          'Mark checked in',
                          'សម្គាល់ថាបានចូលស្នាក់',
                        ),
                      ),
                    )
                  else if (booking.status == BookingStatus.ongoing)
                    FilledButton(
                      onPressed: () => ref
                          .read(appControllerProvider.notifier)
                          .updateBookingStatus(booking.id, BookingStatus.past),
                      child: Text(
                        localized(
                          context,
                          'Mark completed',
                          'សម្គាល់ថាបានបញ្ចប់',
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusLabel(BuildContext context, BookingStatus status) =>
      switch (status) {
        BookingStatus.pending => localized(context, 'Pending', 'រង់ចាំ'),
        BookingStatus.confirmed => localized(
          context,
          'Confirmed',
          'បានបញ្ជាក់',
        ),
        BookingStatus.upcoming => AppLocalizations.of(context).upcoming,
        BookingStatus.ongoing => AppLocalizations.of(context).ongoing,
        BookingStatus.past => AppLocalizations.of(context).past,
        BookingStatus.cancelled => AppLocalizations.of(context).cancelled,
      };
}

class OwnerListingsScreen extends StatefulWidget {
  const OwnerListingsScreen({super.key});
  @override
  State<OwnerListingsScreen> createState() => _OwnerListingsScreenState();
}

class _OwnerListingsScreenState extends State<OwnerListingsScreen> {
  final hidden = <String>{};
  String query = '';
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final listings = mockProperties
        .where(
          (item) =>
              !hidden.contains(item.id) &&
              (query.isEmpty ||
                  item.name.en.toLowerCase().contains(query.toLowerCase())),
        )
        .take(4)
        .toList();
    return Scaffold(
      appBar: _OwnerHeader(title: s.listings),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/owner/property-wizard'),
        icon: const Icon(Icons.add_rounded),
        label: Text(s.addProperty),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: TextField(
              onChanged: (value) => setState(() => query = value),
              decoration: InputDecoration(
                hintText: s.search,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.tune_rounded),
                ),
              ),
            ),
          ),
          Expanded(
            child: listings.isEmpty
                ? EmptyState(
                    icon: Icons.home_work_outlined,
                    title: localized(
                      context,
                      'No properties yet',
                      'មិនទាន់មានទីតាំង',
                    ),
                    body: localized(
                      context,
                      'Add your first property to begin hosting.',
                      'បន្ថែមទីតាំងដំបូងរបស់អ្នក ដើម្បីចាប់ផ្តើមទទួលភ្ញៀវ។',
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: listings.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final property = listings[index];
                      return Card(
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                              child: AspectRatio(
                                aspectRatio: 2.2,
                                child: stayImage(
                                  property.image,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          property.name.resolve(
                                            Localizations.localeOf(context),
                                          ),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                      ),
                                      StatusBadge(
                                        label:
                                            property.status ==
                                                ListingStatus.draft
                                            ? s.draft
                                            : s.published,
                                        color:
                                            property.status ==
                                                ListingStatus.draft
                                            ? AppColors.terracotta
                                            : AppColors.success,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.visibility_outlined,
                                        size: 18,
                                      ),
                                      const Text(' 1,284 '),
                                      const SizedBox(width: 12),
                                      const Icon(
                                        Icons.event_available_outlined,
                                        size: 18,
                                      ),
                                      const Text(' 23 '),
                                      const Spacer(),
                                      PopupMenuButton<String>(
                                        onSelected: (value) =>
                                            _action(value, property),
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Text(s.edit),
                                          ),
                                          PopupMenuItem(
                                            value: 'preview',
                                            child: Text(s.preview),
                                          ),
                                          PopupMenuItem(
                                            value: 'pause',
                                            child: Text(
                                              localized(
                                                context,
                                                'Pause',
                                                'ផ្អាក',
                                              ),
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'duplicate',
                                            child: Text(
                                              localized(
                                                context,
                                                'Duplicate',
                                                'ចម្លង',
                                              ),
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Text(
                                              localized(
                                                context,
                                                'Delete',
                                                'លុប',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _action(String action, Property property) async {
    if (action == 'edit') {
      context.push('/owner/property-wizard');
      return;
    }
    if (action == 'preview') {
      context.push('/property/${property.id}');
      return;
    }
    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            localized(context, 'Delete this property?', 'លុបទីតាំងនេះ?'),
          ),
          content: Text(
            localized(
              context,
              'This removes it from the local prototype.',
              'វានឹងត្រូវបានដកចេញពីគំរូក្នុងឧបករណ៍។',
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
      if (confirmed == true) setState(() => hidden.add(property.id));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          action == 'duplicate'
              ? localized(
                  context,
                  'Draft copy created',
                  'បានបង្កើតច្បាប់ចម្លងសេចក្តីព្រាង',
                )
              : localized(context, 'Listing paused', 'ទីតាំងបានផ្អាក'),
        ),
      ),
    );
  }
}

class OwnerAccountScreen extends ConsumerWidget {
  const OwnerAccountScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);
    return Scaffold(
      appBar: _OwnerHeader(title: s.account),
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
                    child: Icon(Icons.person_rounded, size: 34),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sophea',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          localized(
                            context,
                            'Local host · Siem Reap',
                            'ម្ចាស់ទីតាំង · សៀមរាប',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const StatusBadge(label: 'DEMO', color: AppColors.gold),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: Text(s.verification),
            subtitle: Text(s.inReview),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/owner/onboarding'),
          ),
          ListTile(
            leading: const Icon(Icons.business_outlined),
            title: Text(
              localized(context, 'Business information', 'ព័ត៌មានអាជីវកម្ម'),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _demo(context),
          ),
          ListTile(
            leading: const Icon(Icons.policy_outlined),
            title: Text(localized(context, 'Policies', 'គោលការណ៍')),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _demo(context),
          ),
          ListTile(
            leading: const Icon(Icons.rate_review_outlined),
            title: Text(s.reviews),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/owner/reviews'),
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
          ListTile(
            leading: const Icon(Icons.help_outline_rounded),
            title: Text(s.helpCenter),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _demo(context),
          ),
          const LotusDivider(),
          ListTile(
            key: const Key('switch-traveler'),
            leading: const Icon(Icons.explore_outlined),
            title: Text(s.switchTraveler),
            onTap: () async {
              await ref.read(apiClientProvider).logout();
              await ref
                  .read(appControllerProvider.notifier)
                  .setRole(AppRole.traveler);
              if (context.mounted) context.go('/signin');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: Text(s.signOut),
            onTap: () async {
              await ref.read(apiClientProvider).logout();
              if (context.mounted) context.go('/welcome');
            },
          ),
        ],
      ),
    );
  }

  void _demo(BuildContext context) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localized(
              context,
              'Saved locally in demo mode',
              'បានរក្សាទុកក្នុងឧបករណ៍ក្នុងរបៀបសាកល្បង',
            ),
          ),
        ),
      );
}

class OwnerOnboardingScreen extends StatefulWidget {
  const OwnerOnboardingScreen({super.key});
  @override
  State<OwnerOnboardingScreen> createState() => _OwnerOnboardingScreenState();
}

class _OwnerOnboardingScreenState extends State<OwnerOnboardingScreen> {
  int step = 0;
  bool business = false;
  bool uploaded = false;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final titles = [
      localized(
        context,
        'Welcome to hosting',
        'សូមស្វាគមន៍ការធ្វើជាម្ចាស់ផ្ទះ',
      ),
      localized(context, 'Host type', 'ប្រភេទម្ចាស់ផ្ទះ'),
      localized(context, 'Contact details', 'ព័ត៌មានទំនាក់ទំនង'),
      localized(context, 'Identity verification', 'ការផ្ទៀងផ្ទាត់អត្តសញ្ញាណ'),
      localized(context, 'Review submission', 'ពិនិត្យការដាក់ស្នើ'),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(titles[step])),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(value: (step + 1) / titles.length),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: switch (step) {
                  0 => Column(
                    children: [
                      const SizedBox(height: 30),
                      const Icon(
                        Icons.home_work_outlined,
                        size: 72,
                        color: AppColors.gold,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        localized(
                          context,
                          'Share your Cambodia with thoughtful travelers.',
                          'ចែករំលែកកម្ពុជារបស់អ្នកជាមួយអ្នកដំណើរ។',
                        ),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 20),
                      const _Benefit(
                        icon: Icons.payments_outlined,
                        text: 'Clear demo earnings',
                      ),
                      const _Benefit(
                        icon: Icons.calendar_month_outlined,
                        text: 'Simple availability tools',
                      ),
                      const _Benefit(
                        icon: Icons.support_agent_outlined,
                        text: 'Host support preview',
                      ),
                    ],
                  ),
                  1 => Column(
                    children: [
                      ChoiceChip(
                        label: Text(
                          localized(
                            context,
                            'Personal host',
                            'ម្ចាស់ផ្ទះផ្ទាល់ខ្លួន',
                          ),
                        ),
                        selected: !business,
                        onSelected: (_) => setState(() => business = false),
                      ),
                      const SizedBox(height: 12),
                      ChoiceChip(
                        label: Text(
                          localized(
                            context,
                            'Registered business',
                            'អាជីវកម្មចុះបញ្ជី',
                          ),
                        ),
                        selected: business,
                        onSelected: (_) => setState(() => business = true),
                      ),
                    ],
                  ),
                  2 => Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(labelText: s.fullName),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: InputDecoration(labelText: s.phone),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: InputDecoration(labelText: s.email),
                      ),
                    ],
                  ),
                  3 => Column(
                    children: [
                      const Icon(
                        Icons.badge_outlined,
                        size: 64,
                        color: AppColors.gold,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        localized(
                          context,
                          'Add a government ID preview',
                          'បន្ថែមឯកសារអត្តសញ្ញាណសាកល្បង',
                        ),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        localized(
                          context,
                          'Document upload is visual only. No file leaves this device.',
                          'ការផ្ទុកឯកសារគ្រាន់តែជាការបង្ហាញ។ គ្មានឯកសារចាកចេញពីឧបករណ៍នេះទេ។',
                        ),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: () => setState(() => uploaded = true),
                        icon: Icon(
                          uploaded
                              ? Icons.check_rounded
                              : Icons.upload_file_rounded,
                        ),
                        label: Text(
                          uploaded
                              ? localized(
                                  context,
                                  'Document added',
                                  'បានបន្ថែមឯកសារ',
                                )
                              : localized(
                                  context,
                                  'Choose document',
                                  'ជ្រើសរើសឯកសារ',
                                ),
                        ),
                      ),
                    ],
                  ),
                  _ => Column(
                    children: [
                      const Icon(
                        Icons.hourglass_top_rounded,
                        size: 64,
                        color: AppColors.gold,
                      ),
                      const SizedBox(height: 16),
                      StatusBadge(
                        label: s.inReview,
                        color: AppColors.terracotta,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        localized(
                          context,
                          'Your demo profile is ready for review',
                          'ប្រវត្តិសាកល្បងរបស់អ្នករួចរាល់សម្រាប់ការពិនិត្យ',
                        ),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        localized(
                          context,
                          'Verification states include not started, in review, approved, and more information required.',
                          'ស្ថានភាពផ្ទៀងផ្ទាត់រួមមាន មិនទាន់ចាប់ផ្តើម កំពុងពិនិត្យ បានអនុម័ត និងត្រូវការព័ត៌មានបន្ថែម។',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (step > 0)
                    OutlinedButton(
                      onPressed: () => setState(() => step--),
                      child: Text(s.previous),
                    ),
                  if (step > 0) const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        if (step < titles.length - 1) {
                          setState(() => step++);
                        } else {
                          context.pop();
                        }
                      },
                      child: Text(
                        step == titles.length - 1 ? s.done : s.continueLabel,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: CircleAvatar(child: Icon(icon)),
    title: Text(text),
  );
}

class OwnerCalendarScreen extends ConsumerStatefulWidget {
  const OwnerCalendarScreen({super.key});
  @override
  ConsumerState<OwnerCalendarScreen> createState() =>
      _OwnerCalendarScreenState();
}

class _OwnerCalendarScreenState extends ConsumerState<OwnerCalendarScreen> {
  DateTime selected = DateTime(2026, 9, 8);
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final blocked = ref.watch(
      appControllerProvider.select((state) => state.blockedDates),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(s.calendar),
        actions: [
          TextButton(onPressed: _editPrice, child: Text(s.updatePrices)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  localized(context, 'September 2026', 'ខែកញ្ញា ២០២៦'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            mainAxisSpacing: 7,
            crossAxisSpacing: 7,
            children: [
              for (final day in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                Center(
                  child: Text(
                    day,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              for (var i = 0; i < 1; i++) const SizedBox.shrink(),
              for (var day = 1; day <= 30; day++)
                Builder(
                  builder: (context) {
                    final date = DateTime(2026, 9, day);
                    final isSelected = selected == date;
                    final isBlocked = blocked.contains(date);
                    final isBooked = {12, 13, 14, 21, 22}.contains(day);
                    final color = isBlocked
                        ? AppColors.error
                        : isBooked
                        ? AppColors.terracotta
                        : AppColors.success;
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => selected = date),
                      onLongPress: () => ref
                          .read(appControllerProvider.notifier)
                          .toggleBlockedDate(date),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.champagne.withValues(alpha: .38)
                              : Theme.of(context).colorScheme.surface,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.gold
                                : Theme.of(context).colorScheme.outlineVariant,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('$day'),
                            const SizedBox(height: 4),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              StatusBadge(label: s.available, color: AppColors.success),
              StatusBadge(label: s.booked, color: AppColors.terracotta),
              StatusBadge(label: s.blocked, color: AppColors.error),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    DateFormat.yMMMMd().format(selected),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    blocked.contains(selected)
                        ? s.blocked
                        : localized(
                            context,
                            'Available · Base price applies',
                            'ទំនេរ · តម្លៃមូលដ្ឋានត្រូវបានអនុវត្ត',
                          ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.tonal(
                    onPressed: () => ref
                        .read(appControllerProvider.notifier)
                        .toggleBlockedDate(selected),
                    child: Text(
                      blocked.contains(selected)
                          ? localized(context, 'Unblock date', 'បើកកាលបរិច្ឆេទ')
                          : s.blockDates,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editPrice() async {
    final controller = TextEditingController(text: '52');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocalizations.of(context).updatePrices,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: r'$ ',
                labelText: AppLocalizations.of(context).basePrice,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(
                      localized(
                        this.context,
                        'Price saved locally',
                        'តម្លៃបានរក្សាទុកក្នុងឧបករណ៍',
                      ),
                    ),
                  ),
                );
              },
              child: Text(AppLocalizations.of(context).saveChanges),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }
}

class PropertyWizardScreen extends StatefulWidget {
  const PropertyWizardScreen({super.key});
  @override
  State<PropertyWizardScreen> createState() => _PropertyWizardScreenState();
}

class _PropertyWizardScreenState extends State<PropertyWizardScreen> {
  int step = 0;
  final name = TextEditingController();
  final nameKm = TextEditingController();
  final province = TextEditingController();
  final city = TextEditingController();
  final description = TextEditingController();
  final descriptionKm = TextEditingController();
  String propertyType = 'Homestay';
  String? createdPropertyId;
  String imageUrl = '/images/siem-reap-homestay.png';
  bool uploadingPhoto = false;
  List<Map<String, dynamic>> cambodiaProvinces = const [];
  String? provinceCode;
  String? cityId;
  final selectedAmenities = <String>{'Wi-Fi', 'Breakfast'};
  double price = 45;
  final steps = const [
    'Basics',
    'Type',
    'Location',
    'Description',
    'Amenities',
    'House rules',
    'Photos',
    'Rooms',
    'Pricing',
    'Availability',
    'Review',
  ];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLocations());
  }

  Future<void> _loadLocations() async {
    try {
      final api = ProviderScope.containerOf(context).read(apiClientProvider);
      final result = await api.request('/locations/provinces');
      if (!mounted) return;
      setState(() {
        cambodiaProvinces = (result['provinces'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load Cambodia locations: $error')),
        );
      }
    }
  }

  @override
  void dispose() {
    name.dispose();
    nameKm.dispose();
    province.dispose();
    city.dispose();
    description.dispose();
    descriptionKm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return PopScope(
      canPop: step == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(localized(context, 'Add property', 'បន្ថែមទីតាំង')),
          actions: [
            TextButton(onPressed: _saveDraft, child: Text(s.saveDraft)),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    LinearProgressIndicator(value: (step + 1) / steps.length),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('${step + 1}/${steps.length}'),
                        const Spacer(),
                        Text(
                          _stepTitle(context, step),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _content(context, step),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    if (step > 0)
                      OutlinedButton(
                        onPressed: () => setState(() => step--),
                        child: Text(s.previous),
                      ),
                    if (step > 0) const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        key: Key(
                          step == 10 ? 'publish-property' : 'wizard-continue',
                        ),
                        onPressed: _continue,
                        child: Text(step == 10 ? s.publish : s.continueLabel),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _stepTitle(BuildContext context, int value) => [
    AppLocalizations.of(context).propertyBasics,
    AppLocalizations.of(context).propertyType,
    AppLocalizations.of(context).location,
    AppLocalizations.of(context).description,
    AppLocalizations.of(context).amenities,
    AppLocalizations.of(context).houseRules,
    AppLocalizations.of(context).photos,
    AppLocalizations.of(context).rooms,
    AppLocalizations.of(context).pricing,
    AppLocalizations.of(context).availability,
    AppLocalizations.of(context).review,
  ][value];

  Widget _content(BuildContext context, int value) => switch (value) {
    0 => Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          localized(
            context,
            'What should guests call your place?',
            'តើភ្ញៀវគួរហៅទីតាំងរបស់អ្នកថាអ្វី?',
          ),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: name,
          decoration: InputDecoration(
            labelText: localized(context, 'Property name', 'ឈ្មោះទីតាំង'),
            errorText: name.text.trim().isEmpty && step > 0
                ? AppLocalizations.of(context).requiredField
                : null,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: nameKm,
          decoration: InputDecoration(
            labelText: localized(
              context,
              'Khmer property name',
              'ឈ្មោះទីតាំងជាភាសាខ្មែរ',
            ),
          ),
        ),
      ],
    ),
    1 => _ChoiceGrid(
      title: localized(
        context,
        'Choose a property type',
        'ជ្រើសរើសប្រភេទទីតាំង',
      ),
      labels: [
        localized(context, 'Homestay', 'ផ្ទះស្នាក់'),
        localized(context, 'Guesthouse', 'ផ្ទះសំណាក់'),
        localized(context, 'Boutique stay', 'ប៊ូទិក'),
        localized(context, 'Eco lodge', 'ផ្ទះសំណាក់អេកូ'),
      ],
      onChanged: (value) => propertyType = [
        'Homestay',
        'Guesthouse',
        'Boutique stay',
        'Eco lodge',
      ][value],
    ),
    2 => Column(
      key: const ValueKey(2),
      children: [
        DropdownButtonFormField<String>(
          initialValue: provinceCode,
          decoration: InputDecoration(
            labelText: localized(
              context,
              'Province / capital',
              'ខេត្ត / រាជធានី',
            ),
          ),
          items: cambodiaProvinces
              .map(
                (item) => DropdownMenuItem(
                  value: item['code'] as String,
                  child: Text('${item['name']} · ${item['nameKm']}'),
                ),
              )
              .toList(),
          onChanged: (value) {
            final selected = cambodiaProvinces
                .where((item) => item['code'] == value)
                .firstOrNull;
            setState(() {
              provinceCode = value;
              province.text = selected?['name']?.toString() ?? '';
              cityId = null;
              city.clear();
            });
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: cityId,
          decoration: InputDecoration(
            labelText: localized(
              context,
              'City / municipality',
              'ក្រុង / ស្រុក',
            ),
          ),
          items:
              ((cambodiaProvinces
                              .where((item) => item['code'] == provinceCode)
                              .firstOrNull?['cities']
                          as List<dynamic>?) ??
                      const [])
                  .cast<Map<String, dynamic>>()
                  .map(
                    (item) => DropdownMenuItem(
                      value: item['id'] as String,
                      child: Text('${item['name']} · ${item['nameKm']}'),
                    ),
                  )
                  .toList(),
          onChanged: provinceCode == null
              ? null
              : (value) {
                  final cities =
                      ((cambodiaProvinces
                                      .where(
                                        (item) => item['code'] == provinceCode,
                                      )
                                      .firstOrNull?['cities']
                                  as List<dynamic>?) ??
                              const [])
                          .cast<Map<String, dynamic>>();
                  final selected = cities
                      .where((item) => item['id'] == value)
                      .firstOrNull;
                  setState(() {
                    cityId = value;
                    city.text = selected?['name']?.toString() ?? '';
                  });
                },
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: InputDecoration(
            labelText: localized(context, 'Address', 'អាសយដ្ឋាន'),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: AppColors.sandstone,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: Icon(
              Icons.location_pin,
              color: AppColors.terracotta,
              size: 48,
            ),
          ),
        ),
      ],
    ),
    3 => Column(
      key: const ValueKey(3),
      children: [
        TextField(
          controller: description,
          minLines: 5,
          maxLines: 8,
          decoration: InputDecoration(
            labelText: localized(
              context,
              'English description',
              'ការពិពណ៌នាភាសាអង់គ្លេស',
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: descriptionKm,
          minLines: 5,
          maxLines: 8,
          decoration: InputDecoration(
            labelText: localized(
              context,
              'Khmer description',
              'ការពិពណ៌នាភាសាខ្មែរ',
            ),
          ),
        ),
      ],
    ),
    4 => _AmenityPicker(
      selected: selectedAmenities,
      onChanged: () => setState(() {}),
    ),
    5 => Column(
      key: const ValueKey(5),
      children: [
        SwitchListTile(
          value: true,
          onChanged: (_) {},
          title: Text(
            localized(context, 'No smoking indoors', 'ហាមជក់បារីក្នុងផ្ទះ'),
          ),
        ),
        SwitchListTile(
          value: false,
          onChanged: (_) {},
          title: Text(
            localized(context, 'Pets allowed', 'អនុញ្ញាតសត្វចិញ្ចឹម'),
          ),
        ),
        ListTile(
          title: Text(localized(context, 'Check-in time', 'ម៉ោងចូលស្នាក់')),
          trailing: const Text('14:00'),
        ),
        ListTile(
          title: Text(localized(context, 'Check-out time', 'ម៉ោងចាកចេញ')),
          trailing: const Text('11:00'),
        ),
      ],
    ),
    6 => Column(
      key: const ValueKey(6),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          localized(
            context,
            'Arrange your best photo first',
            'រៀបចំរូបថតល្អបំផុតជាមុន',
          ),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 220,
            child: stayImage(
              imageUrl.startsWith('/uploads/')
                  ? '$apiBaseUrl$imageUrl'
                  : 'assets/images/siem_reap_homestay.png',
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: uploadingPhoto ? null : _pickAndUploadPhoto,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text(
            uploadingPhoto
                ? 'Uploading…'
                : localized(context, 'Upload photo', 'ផ្ទុករូបថត'),
          ),
        ),
      ],
    ),
    7 => Column(
      key: const ValueKey(7),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.bed_rounded),
            title: Text(
              localized(context, 'Garden deluxe', 'បន្ទប់ប្រណិតមើលសួន'),
            ),
            subtitle: Text(
              localized(
                context,
                '1 king bed · 2 guests · 3 rooms',
                'គ្រែធំ ១ · ភ្ញៀវ ២ · ៣ បន្ទប់',
              ),
            ),
            trailing: const Icon(Icons.edit_outlined),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => context.push('/owner/rooms'),
          icon: const Icon(Icons.add_rounded),
          label: Text(
            localized(context, 'Add room type', 'បន្ថែមប្រភេទបន្ទប់'),
          ),
        ),
      ],
    ),
    8 => Column(
      key: const ValueKey(8),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${AppLocalizations.of(context).basePrice}: \$${price.round()}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Slider(
          value: price,
          min: 20,
          max: 180,
          divisions: 32,
          onChanged: (value) => setState(() => price = value),
        ),
        TextField(
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).weeklyDiscount,
            suffixText: '%',
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).monthlyDiscount,
            suffixText: '%',
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    ),
    9 => Column(
      key: const ValueKey(9),
      children: [
        SwitchListTile(
          value: true,
          onChanged: (_) {},
          title: Text(
            localized(context, 'Open for booking', 'បើកសម្រាប់ការកក់'),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.calendar_month_outlined),
          title: Text(
            localized(
              context,
              'Select available dates',
              'ជ្រើសរើសកាលបរិច្ឆេទទំនេរ',
            ),
          ),
          subtitle: Text(
            localized(
              context,
              'September 2026 – March 2027',
              'ខែកញ្ញា ២០២៦ – ខែមីនា ២០២៧',
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.nights_stay_outlined),
          title: Text(localized(context, 'Minimum stay', 'ការស្នាក់អប្បបរមា')),
          trailing: const Text('1 night'),
        ),
      ],
    ),
    _ => Column(
      key: const ValueKey(10),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.asset(
            'assets/images/siem_reap_homestay.png',
            height: 220,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          name.text.isEmpty
              ? localized(
                  context,
                  'Your new KhmerStay',
                  'KhmerStay ថ្មីរបស់អ្នក',
                )
              : name.text,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        StatusBadge(
          label: localized(
            context,
            'READY TO PUBLISH · DEMO',
            'រួចរាល់ផ្សព្វផ្សាយ · សាកល្បង',
          ),
          color: AppColors.success,
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () => context.push('/property/angkor-lotus'),
          icon: const Icon(Icons.visibility_outlined),
          label: Text(AppLocalizations.of(context).preview),
        ),
      ],
    ),
  };

  Future<void> _continue() async {
    if (step == 0 && name.text.trim().isEmpty) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).requiredField)),
      );
      return;
    }
    if (step < steps.length - 1) {
      setState(() => step++);
      return;
    }
    try {
      final container = ProviderScope.containerOf(context);
      final id = await _persistProperty();
      if (id == null) return;
      await container
          .read(apiClientProvider)
          .request(
            '/properties/$id/status',
            method: 'POST',
            body: {'status': 'Review pending'},
          );
      await container.read(appControllerProvider.notifier).loadServerData();
      if (mounted) context.go('/owner/listings');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<String?> _persistProperty() async {
    if (name.text.trim().isEmpty || provinceCode == null || cityId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localized(
                context,
                'Enter a name, province and city before saving',
                'សូមបញ្ចូលឈ្មោះ ខេត្ត និងក្រុងមុនពេលរក្សាទុក',
              ),
            ),
          ),
        );
      }
      return null;
    }
    final container = ProviderScope.containerOf(context);
    final api = container.read(apiClientProvider);
    final fields = {
      'name': name.text.trim(),
      'nameKm': nameKm.text.trim().isEmpty
          ? name.text.trim()
          : nameKm.text.trim(),
      'province': province.text.trim(),
      'provinceKm':
          cambodiaProvinces
              .where((item) => item['code'] == provinceCode)
              .firstOrNull?['nameKm']
              ?.toString() ??
          province.text.trim(),
      'provinceCode': provinceCode,
      'city': city.text.trim(),
      'cityKm':
          (((cambodiaProvinces
                              .where((item) => item['code'] == provinceCode)
                              .firstOrNull?['cities']
                          as List<dynamic>?) ??
                      const [])
                  .cast<Map<String, dynamic>>()
                  .where((item) => item['id'] == cityId)
                  .firstOrNull?['nameKm'])
              ?.toString() ??
          city.text.trim(),
      'cityId': cityId,
      'type': propertyType,
      'description': description.text.trim(),
      'descriptionKm': descriptionKm.text.trim(),
      'image': imageUrl,
      'amenities': selectedAmenities.toList(),
    };
    final Map<String, dynamic> result;
    if (createdPropertyId == null) {
      result = await api.request(
        '/properties',
        method: 'POST',
        body: {
          ...fields,
          'roomTypes': [
            {
              'id': '',
              'name': 'Garden deluxe',
              'nameKm': 'បន្ទប់ប្រណិតមើលសួន',
              'bed': '1 king bed',
              'guests': 2,
              'price': price,
              'inventory': 3,
            },
          ],
        },
      );
      createdPropertyId =
          (result['property'] as Map<String, dynamic>)['id'] as String;
    } else {
      result = await api.request(
        '/properties/$createdPropertyId',
        method: 'PATCH',
        body: fields,
      );
    }
    await container.read(appControllerProvider.notifier).loadServerData();
    return createdPropertyId;
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;
      setState(() => uploadingPhoto = true);
      final api = ProviderScope.containerOf(context).read(apiClientProvider);
      final url = await api.uploadImage(await file.readAsBytes(), file.name);
      if (mounted) setState(() => imageUrl = url);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => uploadingPhoto = false);
    }
  }

  Future<void> _saveDraft() async {
    try {
      final id = await _persistProperty();
      if (id != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localized(context, 'Draft saved', 'បានរក្សាទុកសេចក្តីព្រាង'),
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  void _exit() => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        localized(context, 'Save before leaving?', 'រក្សាទុកមុនចាកចេញ?'),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            context.pop();
          },
          child: Text(localized(context, 'Discard', 'បោះបង់')),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(dialogContext);
            await _saveDraft();
            if (mounted) context.pop();
          },
          child: Text(AppLocalizations.of(context).saveDraft),
        ),
      ],
    ),
  );
}

class _ChoiceGrid extends StatefulWidget {
  const _ChoiceGrid({
    required this.title,
    required this.labels,
    required this.onChanged,
  });
  final String title;
  final List<String> labels;
  final ValueChanged<int> onChanged;
  @override
  State<_ChoiceGrid> createState() => _ChoiceGridState();
}

class _ChoiceGridState extends State<_ChoiceGrid> {
  int selected = 0;
  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey(1),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(widget.title, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 18),
      RadioGroup<int>(
        groupValue: selected,
        onChanged: (value) {
          if (value != null) {
            setState(() => selected = value);
            widget.onChanged(value);
          }
        },
        child: Column(
          children: List.generate(
            widget.labels.length,
            (index) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: RadioListTile<int>(
                value: index,
                title: Text(widget.labels[index]),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _AmenityPicker extends StatelessWidget {
  const _AmenityPicker({required this.selected, required this.onChanged});
  final Set<String> selected;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey(4),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        AppLocalizations.of(context).amenities,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children:
            [
                  'Wi-Fi',
                  'Breakfast',
                  'Garden',
                  'Air conditioning',
                  'Parking',
                  'Workspace',
                ]
                .map(
                  (item) => FilterChip(
                    label: Text(item),
                    selected: selected.contains(item),
                    onSelected: (_) {
                      selected.contains(item)
                          ? selected.remove(item)
                          : selected.add(item);
                      onChanged();
                    },
                  ),
                )
                .toList(),
      ),
    ],
  );
}

class RoomsManagementScreen extends StatefulWidget {
  const RoomsManagementScreen({super.key});
  @override
  State<RoomsManagementScreen> createState() => _RoomsManagementScreenState();
}

class _RoomsManagementScreenState extends State<RoomsManagementScreen> {
  final rooms = ['Garden deluxe', 'Family suite'];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppLocalizations.of(context).rooms)),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _editRoom,
      icon: const Icon(Icons.add_rounded),
      label: Text(localized(context, 'Add room', 'បន្ថែមបន្ទប់')),
    ),
    body: ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: rooms.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  index.isEven
                      ? 'assets/images/siem_reap_homestay.png'
                      : 'assets/images/kep_coastal.png',
                  width: 90,
                  height: 88,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rooms[index],
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      localized(
                        context,
                        '1 king bed · 2 guests',
                        'គ្រែធំ ១ · ភ្ញៀវ ២',
                      ),
                    ),
                    const SizedBox(height: 5),
                    const StatusBadge(
                      label: 'AVAILABLE',
                      color: AppColors.success,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    setState(() => rooms.removeAt(index));
                  } else {
                    _editRoom();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(AppLocalizations.of(context).edit),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(localized(context, 'Delete', 'លុប')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _editRoom() async {
    final controller = TextEditingController();
    final value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              localized(context, 'Room details', 'ព័ត៌មានបន្ទប់'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: localized(context, 'Room name', 'ឈ្មោះបន្ទប់'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).basePrice,
                prefixText: r'$ ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(AppLocalizations.of(context).saveChanges),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (value != null && value.trim().isNotEmpty) {
      setState(() => rooms.add(value.trim()));
    }
  }
}

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});
  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  double weekday = 46;
  double weekend = 58;
  bool available = true;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.pricing)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: available,
            onChanged: (value) => setState(() => available = value),
            title: Text(s.availability),
            subtitle: Text(available ? s.available : s.blocked),
          ),
          const Divider(),
          Text(
            '${s.basePrice}: \$${weekday.round()}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            value: weekday,
            min: 20,
            max: 200,
            onChanged: (value) => setState(() => weekday = value),
          ),
          Text(
            '${s.weekendPrice}: \$${weekend.round()}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            value: weekend,
            min: 20,
            max: 220,
            onChanged: (value) => setState(() => weekend = value),
          ),
          TextField(
            decoration: InputDecoration(
              labelText: s.weeklyDiscount,
              suffixText: '%',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              labelText: s.monthlyDiscount,
              suffixText: '%',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              labelText: localized(
                context,
                'Last-minute discount',
                'បញ្ចុះតម្លៃពេលជិតដល់',
              ),
              suffixText: '%',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              labelText: localized(
                context,
                'Minimum stay',
                'ការស្នាក់អប្បបរមា',
              ),
              suffixText: localized(context, 'nights', 'យប់'),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  localized(
                    context,
                    'Pricing saved locally',
                    'តម្លៃបានរក្សាទុកក្នុងឧបករណ៍',
                  ),
                ),
              ),
            ),
            child: Text(s.saveChanges),
          ),
        ],
      ),
    );
  }
}

class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> {
  List<HostPayout> _payouts = [];
  bool _loadingPayouts = true;
  String? _payoutError;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadPayouts);
  }

  Future<void> _loadPayouts() async {
    try {
      final payouts = await ref.read(apiClientProvider).listPayouts();
      if (mounted) {
        setState(() {
          _payouts = payouts;
          _loadingPayouts = false;
          _payoutError = null;
        });
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          _loadingPayouts = false;
          _payoutError = err.toString();
        });
      }
    }
  }

  Future<void> _requestPayoutDialog(
    Booking booking,
    double gross,
    double commission,
    double net,
  ) async {
    final accountController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final messenger = ScaffoldMessenger.of(context);
    final successMessage = localized(
      context,
      'Bakong payout requested successfully!',
      'ការស្នើសុំទូទាត់បាគងទទួលបានជោគជ័យ!',
    );
    bool submitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) {
          final state = ref.watch(appControllerProvider);
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        localized(
                          context,
                          'Request Bakong Payout',
                          'ស្នើសុំការទូទាត់បាគង',
                        ),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.ivory,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.sandstone),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              localized(
                                context,
                                'Booking gross',
                                'ចំណូលសរុបពីការកក់',
                              ),
                            ),
                            Text(
                              formatPrice(gross, state),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              localized(
                                context,
                                'Platform fee (15%)',
                                'កម្រៃសេវា KhmerStay (១៥%)',
                              ),
                              style: const TextStyle(color: AppColors.terracotta),
                            ),
                            Text(
                              '-${formatPrice(commission, state)}',
                              style: const TextStyle(
                                color: AppColors.terracotta,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              localized(
                                context,
                                'Net host payout',
                                'ចំណូលសុទ្ធរបស់ម្ចាស់',
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              formatPrice(net, state),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: accountController,
                    decoration: InputDecoration(
                      labelText: localized(
                        context,
                        'Bakong Account ID or Phone',
                        'លេខសម្គាល់គណនីបាគង ឬលេខទូរស័ព្ទ',
                      ),
                      hintText: 'e.g. sophea@aclb or 012345678',
                      prefixIcon: const Icon(Icons.account_balance_rounded),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return localized(
                          context,
                          'Please enter your Bakong account ID or phone number',
                          'សូមបញ្ចូលលេខសម្គាល់គណនីបាគង ឬលេខទូរស័ព្ទ',
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: submitting
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setModalState(() => submitting = true);
                            try {
                              await ref
                                  .read(apiClientProvider)
                                  .requestPayout(
                                    booking.id,
                                    accountController.text.trim(),
                                  );
                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
                              if (mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(successMessage),
                                  ),
                                );
                                _loadPayouts();
                              }
                            } catch (err) {
                              setModalState(() => submitting = false);
                              if (mounted) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text(err.toString())),
                                );
                              }
                            }
                          },
                    child: submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            localized(
                              context,
                              'Confirm Payout Request',
                              'បញ្ជាក់ការស្នើសុំទូទាត់',
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _badgeColor(String status) {
    switch (status) {
      case 'Paid':
        return AppColors.success;
      case 'Processing':
        return AppColors.gold;
      case 'Declined':
        return AppColors.error;
      case 'Pending':
      default:
        return AppColors.champagne;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);

    // Completed bookings eligible for payout
    final completedBookings = state.bookings
        .where((b) => b.status == BookingStatus.past)
        .toList();

    final eligibleBookings = completedBookings
        .where((b) => !_payouts.any((p) => p.bookingId == b.id))
        .toList();

    final totalCompletedEarnings = completedBookings.fold<double>(
      0,
      (sum, b) => sum + b.totalUsd,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(s.earnings),
        actions: [
          IconButton(
            onPressed: () => _loadPayouts(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  localized(
                    context,
                    'Export is a demo; no file was created.',
                    'ការនាំចេញជាការសាកល្បង; មិនមានឯកសារត្រូវបានបង្កើតទេ។',
                  ),
                ),
              ),
            ),
            icon: const Icon(Icons.ios_share_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPayouts,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              color: AppColors.brown,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localized(
                        context,
                        'Total gross earnings',
                        'ចំណូលសរុបពីការកក់',
                      ),
                      style: const TextStyle(color: AppColors.sandstone),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatPrice(
                        totalCompletedEarnings > 0
                            ? totalCompletedEarnings
                            : 1840,
                        state,
                      ),
                      style: Theme.of(
                        context,
                      ).textTheme.displaySmall?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const StatusBadge(
                      label: '+12.4% VS LAST MONTH',
                      color: AppColors.champagne,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'day',
                  label: Text(localized(context, 'Daily', 'ប្រចាំថ្ងៃ')),
                ),
                ButtonSegment(
                  value: 'week',
                  label: Text(localized(context, 'Weekly', 'ប្រចាំសប្ដាហ៍')),
                ),
                ButtonSegment(
                  value: 'month',
                  label: Text(localized(context, 'Monthly', 'ប្រចាំខែ')),
                ),
              ],
              selected: const {'week'},
              onSelectionChanged: (_) {},
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 210,
              child: CustomPaint(
                painter: _EarningsChartPainter(),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 20),

            // Section 1: Completed Bookings Eligible for Payout
            SectionHeading(
              title: localized(
                context,
                'Eligible for Payout',
                'រួចរាល់សម្រាប់ការទូទាត់',
              ),
            ),
            if (eligibleBookings.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          localized(
                            context,
                            'All completed bookings have been requested for payout.',
                            'ការកក់ដែលបានបញ្ចប់ទាំងអស់ត្រូវបានស្នើសុំទូទាត់រួចរាល់។',
                          ),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...eligibleBookings.map((b) {
                final gross = b.totalUsd;
                final commission = gross * 0.15;
                final net = gross - commission;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                b.roomName.isNotEmpty
                                    ? b.roomName
                                    : 'Booking #${b.reference}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const StatusBadge(
                              label: 'Completed',
                              color: AppColors.success,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${b.guest.name} · ${DateFormat.yMMMd().format(b.start)} - ${DateFormat.yMMMd().format(b.end)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Divider(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${localized(context, 'Gross', 'សរុប')}: ${formatPrice(gross, state)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  '${localized(context, 'KhmerStay Fee (15%)', 'កម្រៃ KhmerStay (១៥%)')}: -${formatPrice(commission, state)}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: AppColors.terracotta),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${localized(context, 'Net Payout', 'ចំណូលសុទ្ធ')}: ${formatPrice(net, state)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                            FilledButton.icon(
                              onPressed: () => _requestPayoutDialog(
                                b,
                                gross,
                                commission,
                                net,
                              ),
                              icon: const Icon(Icons.payments_outlined, size: 18),
                              label: Text(
                                localized(
                                  context,
                                  'Request Bakong Payout',
                                  'ស្នើសុំទូទាត់',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 24),

            // Section 2: Host Payouts Ledger
            SectionHeading(
              title: localized(
                context,
                'Host Payouts Ledger',
                'បញ្ជីស្នើសុំទូទាត់របស់ម្ចាស់',
              ),
            ),
            if (_loadingPayouts)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_payoutError != null)
              Card(
                color: AppColors.error.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _payoutError!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              )
            else if (_payouts.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      localized(
                        context,
                        'No payout requests yet.',
                        'មិនទាន់មានសំណើទូទាត់នៅឡើយទេ។',
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              )
            else
              ..._payouts.map(
                (payout) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor:
                          _badgeColor(payout.status).withValues(alpha: .18),
                      child: Icon(
                        Icons.payments_rounded,
                        color: _badgeColor(payout.status),
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          payout.id,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        StatusBadge(
                          label: payout.status,
                          color: _badgeColor(payout.status),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        if (payout.guestName != null &&
                            payout.guestName!.isNotEmpty)
                          Text('${payout.guestName} · ${payout.propertyName ?? ''}'),
                        Text(
                          '${DateFormat.yMMMd().format(payout.createdAt)} · Bakong: ${payout.bakongAccount}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (payout.reference.isNotEmpty)
                          Text(
                            'Ref: ${payout.reference}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.success),
                          ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              'Gross: ${formatPrice(payout.grossAmount, state)}  ·  Fee: -${formatPrice(payout.commissionAmount, state)}  ·  ',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              'Net: ${formatPrice(payout.netAmount, state)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),
            SectionHeading(
              title: localized(context, 'Transactions', 'ប្រតិបត្តិការ'),
            ),
            ...mockEarnings.reversed.take(6).map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.champagne.withValues(alpha: .22),
                  child: const Icon(Icons.receipt_long_outlined),
                ),
                title: Text(
                  localized(context, 'Stay payout', 'ចំណូលពីការស្នាក់'),
                ),
                subtitle: Text(DateFormat.yMMMd().format(item.date)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatPrice(item.amountUsd, state),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      item.completed
                          ? localized(context, 'Completed', 'បានបញ្ចប់')
                          : localized(context, 'Upcoming', 'នាពេលខាងមុខ'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EarningsChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.sandstone
      ..strokeWidth = 1;
    for (var i = 0; i < 5; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final values = [.28, .52, .43, .72, .58, .86, .76];
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final point = Offset(
        size.width * i / (values.length - 1),
        size.height * (1 - values[i]),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.gold
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class OwnerReviewsScreen extends StatefulWidget {
  const OwnerReviewsScreen({super.key});
  @override
  State<OwnerReviewsScreen> createState() => _OwnerReviewsScreenState();
}

class _OwnerReviewsScreenState extends State<OwnerReviewsScreen> {
  bool responded = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppLocalizations.of(context).reviews)),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: AppLocalizations.of(context).averageRating,
                value: '4.91',
                icon: Icons.star_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                label: localized(context, 'Total reviews', 'ការវាយតម្លៃសរុប'),
                value: '128',
                icon: Icons.rate_review_outlined,
              ),
            ),
          ],
        ),
        SectionHeading(
          title: localized(context, 'Recent guest reviews', 'ការវាយតម្លៃថ្មីៗ'),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    CircleAvatar(child: Text('L')),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Lina Chan',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Icon(Icons.star_rounded, color: AppColors.gold),
                    Text(' 5.0'),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  localized(
                    context,
                    'A calm and beautifully cared-for stay. Sophea was incredibly helpful.',
                    'កន្លែងស្ងប់ស្ងាត់ និងត្រូវបានថែទាំយ៉ាងល្អ។ Sophea បានជួយយ៉ាងខ្លាំង។',
                  ),
                ),
                const SizedBox(height: 12),
                if (responded)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.champagne.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      localized(
                        context,
                        'Owner response: Thank you for staying with us!',
                        'ការឆ្លើយតប៖ សូមអរគុណដែលបានស្នាក់នៅជាមួយយើង!',
                      ),
                    ),
                  )
                else
                  OutlinedButton(
                    onPressed: () => setState(() => responded = true),
                    child: Text(
                      localized(
                        context,
                        'Write public response',
                        'សរសេរការឆ្លើយតបសាធារណៈ',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
