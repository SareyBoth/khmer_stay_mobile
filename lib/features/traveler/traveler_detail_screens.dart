import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/app_state.dart';
import '../../core/api/api_client.dart';
import '../../core/mock/mock_data.dart';
import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../startup/startup_screens.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialCategory});
  final String? initialCategory;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _query = TextEditingController();
  DateTimeRange? _dates;
  int _adults = 2;
  int _children = 0;
  int _rooms = 1;
  double _minPrice = 0;
  double _maxPrice = 90;
  double _minRating = 0;
  String? _type;
  final Set<String> _selectedAmenities = {};
  String? _provinceCode;
  String? _cityId;
  String _sort = 'recommended';
  bool _map = false;
  bool _loading = true;
  List<Property>? _serverProperties;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _type = widget.initialCategory;
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _loading = false);
    });
    _query.addListener(_refresh);
  }

  void _refresh() {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _fetchPropertiesFromServer();
    });
  }

  Future<void> _fetchPropertiesFromServer() async {
    final term = _query.text.trim();
    final checkIn = _dates != null
        ? DateFormat('yyyy-MM-dd').format(_dates!.start)
        : null;
    final checkOut = _dates != null
        ? DateFormat('yyyy-MM-dd').format(_dates!.end)
        : null;
    final guests = _adults + _children;
    final amenities = _selectedAmenities.isEmpty
        ? null
        : _selectedAmenities.join(',');

    try {
      final properties = await ref
          .read(apiClientProvider)
          .fetchProperties(
            q: term.isEmpty ? null : term,
            checkIn: checkIn,
            checkOut: checkOut,
            guests: guests > 0 ? guests : null,
            minPrice: _minPrice > 0 ? _minPrice : null,
            maxPrice: _maxPrice < 500 ? _maxPrice : null,
            category: _type,
            amenities: amenities,
            provinceCode: _provinceCode,
            cityId: _cityId,
          );
      if (mounted) {
        setState(() {
          _serverProperties = properties;
        });
      }
    } catch (_) {
      // Offline fallback
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.removeListener(_refresh);
    _query.dispose();
    super.dispose();
  }

  List<Property> get _results {
    final term = _query.text.trim().toLowerCase();
    final locale = Localizations.localeOf(context);
    final source = _serverProperties ?? mockProperties;
    final items = source.where((property) {
      final matchesTerm =
          term.isEmpty ||
          property.name.en.toLowerCase().contains(term) ||
          property.name.km.contains(term) ||
          property.location.en.toLowerCase().contains(term) ||
          property.location.km.contains(term);
      final matchesType =
          _type == null ||
          property.category.toLowerCase() == _type!.toLowerCase() ||
          property.type
              .resolve(locale)
              .toLowerCase()
              .contains(_type!.toLowerCase());
      final matchesProvince =
          _provinceCode == null || property.provinceCode == _provinceCode;
      final matchesCity = _cityId == null || property.cityId == _cityId;
      final matchesPrice =
          property.priceUsd >= _minPrice && property.priceUsd <= _maxPrice;
      final matchesRating = property.rating >= _minRating;
      final matchesAmenities =
          _selectedAmenities.isEmpty ||
          _selectedAmenities.every(
            (a) => property.amenities.any(
              (pa) =>
                  pa.label.en.toLowerCase() == a.toLowerCase() ||
                  pa.label.km.contains(a),
            ),
          );
      return matchesTerm &&
          matchesType &&
          matchesProvince &&
          matchesCity &&
          matchesPrice &&
          matchesRating &&
          matchesAmenities;
    }).toList();
    switch (_sort) {
      case 'low':
        items.sort((a, b) => a.priceUsd.compareTo(b.priceUsd));
      case 'high':
        items.sort((a, b) => b.priceUsd.compareTo(a.priceUsd));
      case 'rated':
        items.sort((a, b) => b.rating.compareTo(a.rating));
      case 'reviewed':
        items.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final results = _results;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          key: const Key('search-field'),
          controller: _query,
          autofocus: false,
          decoration: InputDecoration(
            hintText: s.destination,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            fillColor: Colors.transparent,
            suffixIcon: _query.text.isEmpty
                ? null
                : IconButton(
                    onPressed: _query.clear,
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                ActionChip(
                  avatar: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(
                    _dates == null
                        ? s.addDates
                        : '${DateFormat.MMMd().format(_dates!.start)} – ${DateFormat.MMMd().format(_dates!.end)}',
                  ),
                  onPressed: _pickDates,
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.people_outline_rounded, size: 18),
                  label: Text(
                    '${_adults + _children} ${s.guests} · $_rooms ${s.rooms}',
                  ),
                  onPressed: _pickGuests,
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.tune_rounded, size: 18),
                  label: Text(s.filters),
                  onPressed: _showFilters,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${results.length} ${s.staysFound}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _showSort,
                  tooltip: s.sort,
                  icon: const Icon(Icons.swap_vert_rounded),
                ),
                const SizedBox(width: 8),
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: false,
                      icon: const Icon(Icons.view_list_rounded),
                      tooltip: s.list,
                    ),
                    ButtonSegment(
                      value: true,
                      icon: const Icon(Icons.map_outlined),
                      tooltip: s.map,
                    ),
                  ],
                  selected: {_map},
                  onSelectionChanged: (value) =>
                      setState(() => _map = value.first),
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _loading
                  ? const _SearchSkeleton(key: ValueKey('loading'))
                  : results.isEmpty
                  ? EmptyState(
                      key: const ValueKey('empty'),
                      icon: Icons.search_off_rounded,
                      title: s.noResults,
                      body: localized(
                        context,
                        'Try clearing a filter or searching another Cambodian destination.',
                        'សូមសម្អាតតម្រង ឬស្វែងរកគោលដៅផ្សេងក្នុងកម្ពុជា។',
                      ),
                    )
                  : _map
                  ? _MockMap(key: const ValueKey('map'), properties: results)
                  : LayoutBuilder(
                      key: const ValueKey('list'),
                      builder: (context, constraints) {
                        final tablet = constraints.maxWidth >= 620;
                        if (tablet) {
                          final textScale = MediaQuery.textScalerOf(
                            context,
                          ).scale(1);
                          return GridView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                            gridDelegate:
                                SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 360,
                                  mainAxisExtent: 330 + (140 * (textScale - 1)),
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 20,
                                ),
                            itemCount: results.length,
                            itemBuilder: (context, index) => PropertyCard(
                              property: results[index],
                              width: double.infinity,
                            ),
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                          itemCount: results.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) =>
                              CompactPropertyCard(property: results[index]),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDates() async {
    final now = DateTime(2026, 9, 4);
    final result = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(2027, 9, 4),
      initialDateRange: _dates,
      helpText: AppLocalizations.of(context).addDates,
    );
    if (result != null) {
      setState(() => _dates = result);
      _fetchPropertiesFromServer();
    }
  }

  Future<void> _pickGuests() async {
    var adults = _adults;
    var children = _children;
    var rooms = _rooms;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final s = AppLocalizations.of(context);
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(s.guests, style: Theme.of(context).textTheme.titleLarge),
                GuestStepper(
                  label: s.adults,
                  value: adults,
                  onChanged: (value) =>
                      setModalState(() => adults = value.clamp(1, 12)),
                ),
                GuestStepper(
                  label: s.children,
                  value: children,
                  onChanged: (value) =>
                      setModalState(() => children = value.clamp(0, 12)),
                ),
                GuestStepper(
                  label: s.rooms,
                  value: rooms,
                  onChanged: (value) =>
                      setModalState(() => rooms = value.clamp(1, 6)),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _adults = adults;
                      _children = children;
                      _rooms = rooms;
                    });
                    _fetchPropertiesFromServer();
                    Navigator.pop(context);
                  },
                  child: Text(s.apply),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showFilters() async {
    var min = _minPrice;
    var max = _maxPrice;
    var rating = _minRating;
    var type = _type;
    var provinceCode = _provinceCode;
    var cityId = _cityId;
    final selectedAmenities = Set<String>.from(_selectedAmenities);
    final provinces = <String, String>{
      for (final property in mockProperties)
        if (property.provinceCode.isNotEmpty)
          property.provinceCode: property.location.en.split(',').last.trim(),
    };
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final s = AppLocalizations.of(context);
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.filters,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      TextButton(
                        onPressed: () => setModalState(() {
                          min = 0;
                          max = 90;
                          rating = 0;
                          type = null;
                          provinceCode = null;
                          cityId = null;
                          selectedAmenities.clear();
                        }),
                        child: Text(s.clearAll),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: provinceCode,
                    decoration: InputDecoration(
                      labelText: localized(
                        context,
                        'Province / capital',
                        'ខេត្ត / រាជធានី',
                      ),
                    ),
                    items: provinces.entries
                        .map(
                          (entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setModalState(() {
                      provinceCode = value;
                      cityId = null;
                    }),
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
                        <String, String>{
                              for (final property in mockProperties)
                                if (property.cityId.isNotEmpty &&
                                    (provinceCode == null ||
                                        property.provinceCode == provinceCode))
                                  property.cityId: property.city.en,
                            }.entries
                            .map(
                              (entry) => DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                            )
                            .toList(),
                    onChanged: (value) => setModalState(() => cityId = value),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.priceRange,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  RangeSlider(
                    values: RangeValues(min, max),
                    min: 0,
                    max: 150,
                    divisions: 15,
                    labels: RangeLabels('\$${min.round()}', '\$${max.round()}'),
                    onChanged: (values) => setModalState(() {
                      min = values.start;
                      max = values.end;
                    }),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('\$${min.round()}'),
                      Text('≤ \$${max.round()}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.propertyType,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        [
                              'Heritage',
                              'Riverside',
                              'Beach',
                              'Mountain',
                              'Eco stay',
                              'City',
                            ]
                            .map(
                              (item) => ChoiceChip(
                                label: Text(item),
                                selected: type == item,
                                onSelected: (value) => setModalState(
                                  () => type = value ? item : null,
                                ),
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localized(context, 'Amenities', 'សេវាកម្ម / បរិក្ខារ'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        [
                              'Wi-Fi',
                              'Breakfast',
                              'Pool',
                              'Air conditioning',
                              'Kitchen',
                              'Free parking',
                            ]
                            .map(
                              (amenity) => FilterChip(
                                label: Text(amenity),
                                selected: selectedAmenities.contains(amenity),
                                onSelected: (selected) => setModalState(() {
                                  if (selected) {
                                    selectedAmenities.add(amenity);
                                  } else {
                                    selectedAmenities.remove(amenity);
                                  }
                                }),
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.rating,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Wrap(
                    spacing: 8,
                    children: [0.0, 4.7, 4.8, 4.9]
                        .map(
                          (value) => ChoiceChip(
                            label: Text(
                              value == 0
                                  ? localized(context, 'Any', 'ទាំងអស់')
                                  : '$value+ ★',
                            ),
                            selected: rating == value,
                            onSelected: (_) =>
                                setModalState(() => rating = value),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _minPrice = min;
                        _maxPrice = max;
                        _minRating = rating;
                        _type = type;
                        _provinceCode = provinceCode;
                        _cityId = cityId;
                        _selectedAmenities
                          ..clear()
                          ..addAll(selectedAmenities);
                      });
                      _fetchPropertiesFromServer();
                      Navigator.pop(context);
                    },
                    child: Text(s.showStays),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showSort() async {
    final s = AppLocalizations.of(context);
    final options = {
      'recommended': s.recommended,
      'low': localized(context, 'Price: low to high', 'តម្លៃ៖ ទាបទៅខ្ពស់'),
      'high': localized(context, 'Price: high to low', 'តម្លៃ៖ ខ្ពស់ទៅទាប'),
      'rated': localized(context, 'Highest rated', 'ពិន្ទុខ្ពស់បំផុត'),
      'reviewed': localized(context, 'Most reviewed', 'ការវាយតម្លៃច្រើនបំផុត'),
    };
    final value = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(s.sort, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              RadioGroup<String>(
                groupValue: _sort,
                onChanged: (value) => Navigator.pop(context, value),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final entry in options.entries)
                      RadioListTile<String>(
                        value: entry.key,
                        title: Text(entry.value),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (value != null) setState(() => _sort = value);
  }
}

class _SearchSkeleton extends StatelessWidget {
  const _SearchSkeleton({super.key});
  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.all(20),
    itemCount: 4,
    itemBuilder: (context, index) => Container(
      height: 112,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );
}

class _MockMap extends ConsumerStatefulWidget {
  const _MockMap({super.key, required this.properties});
  final List<Property> properties;
  @override
  ConsumerState<_MockMap> createState() => _MockMapState();
}

class _MockMapState extends ConsumerState<_MockMap> {
  int selected = 0;
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final count = widget.properties.length.clamp(1, 6);
    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _MapPainter())),
        for (var index = 0; index < count; index++)
          Positioned(
            left:
                30.0 +
                ((index * 63) % (MediaQuery.sizeOf(context).width - 110)),
            top: 45.0 + ((index * 91) % 310),
            child: ChoiceChip(
              selected: selected == index,
              label: Text(
                formatPrice(
                  widget.properties[index].priceUsd,
                  state,
                  compact: true,
                ),
              ),
              onSelected: (_) => setState(() => selected = index),
            ),
          ),
        Positioned(
          right: 16,
          top: 16,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'zoom-in',
                onPressed: () {},
                child: const Icon(Icons.add_rounded),
              ),
              const SizedBox(height: 6),
              FloatingActionButton.small(
                heroTag: 'zoom-out',
                onPressed: () {},
                child: const Icon(Icons.remove_rounded),
              ),
            ],
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: CompactPropertyCard(property: widget.properties[selected]),
        ),
        Positioned(
          left: 16,
          top: 16,
          child: StatusBadge(
            label: localized(context, 'VISUAL MAP DEMO', 'ផែនទីសាកល្បង'),
            color: AppColors.brown,
          ),
        ),
      ],
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFE6E0D0),
    );
    final road = Paint()
      ..color = const Color(0xFFFFF9ED)
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke;
    final thin = Paint()
      ..color = const Color(0xFFC7D3C1)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 7; i++) {
      final y = size.height * (i + 1) / 8;
      canvas.drawPath(
        Path()
          ..moveTo(-20, y)
          ..cubicTo(
            size.width * .25,
            y - 55,
            size.width * .62,
            y + 70,
            size.width + 20,
            y - 20,
          ),
        i.isEven ? road : thin,
      );
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .7, size.height * .22),
        width: 130,
        height: 230,
      ),
      Paint()..color = const Color(0xFFB9CEC7),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PropertyDetailsScreen extends ConsumerWidget {
  const PropertyDetailsScreen({super.key, required this.propertyId});
  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final property = mockProperties.firstWhere((item) => item.id == propertyId);
    final locale = Localizations.localeOf(context);
    final state = ref.watch(appControllerProvider);
    final s = AppLocalizations.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 330,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(6),
              child: IconButton.filledTonal(
                onPressed: context.pop,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            actions: [
              IconButton.filledTonal(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      localized(
                        context,
                        'Demo link copied',
                        'បានចម្លងតំណសាកល្បង',
                      ),
                    ),
                  ),
                ),
                icon: const Icon(Icons.ios_share_rounded),
              ),
              FavoriteButton(propertyId: property.id, onImage: true),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: GestureDetector(
                onTap: () => context.push('/gallery/${property.id}'),
                child: Hero(
                  tag: 'property-${property.id}',
                  child: stayImage(property.image, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 124),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (property.isGuestFavorite)
                    StatusBadge(label: s.guestFavorite, color: AppColors.gold),
                  const SizedBox(height: 10),
                  Text(
                    property.name.resolve(locale),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.gold,
                            size: 20,
                          ),
                          Flexible(
                            child: Text(
                              ' ${property.rating} · ${property.reviewCount} ${s.reviews}',
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_outlined, size: 18),
                          Flexible(
                            child: Text(property.location.resolve(locale)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(14),
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.sandstone,
                        child: Icon(Icons.person_rounded),
                      ),
                      title: Text(
                        localized(
                          context,
                          'Hosted by ${property.owner.name}',
                          'ទទួលស្វាគមន៍ដោយ ${property.owner.name}',
                        ),
                      ),
                      subtitle: Text(
                        localized(
                          context,
                          '${property.owner.yearsHosting} years hosting · ${property.owner.responseRate}% response rate',
                          'ធ្វើជាម្ចាស់ផ្ទះ ${property.owner.yearsHosting} ឆ្នាំ · ឆ្លើយតប ${property.owner.responseRate}%',
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/host/${property.owner.id}'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        final conversationId = await ref
                            .read(appControllerProvider.notifier)
                            .startConversation(
                              type: 'property',
                              propertyId: property.id,
                            );
                        if (context.mounted) {
                          context.push('/conversation/$conversationId');
                        }
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.toString())),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: Text(
                      localized(context, 'Message host', 'ផ្ញើសារទៅម្ចាស់ផ្ទះ'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    s.aboutStay,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    property.description.resolve(locale),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const LotusDivider(),
                  SectionHeading(title: s.roomsAvailable),
                  ...property.rooms.map(
                    (room) => _RoomOption(
                      property: property,
                      room: room,
                      state: state,
                    ),
                  ),
                  SectionHeading(
                    title: s.amenities,
                    action: s.viewAll,
                    onTap: () => _showAmenities(context, property),
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: property.amenities
                        .take(6)
                        .map(
                          (amenity) => Chip(
                            avatar: Icon(amenity.icon, size: 18),
                            label: Text(amenity.label.resolve(locale)),
                          ),
                        )
                        .toList(),
                  ),
                  SectionHeading(title: s.houseRules),
                  _InfoRows(
                    items: [
                      (
                        Icons.login_rounded,
                        localized(
                          context,
                          'Check-in after 2:00 PM',
                          'ចូលស្នាក់បន្ទាប់ពីម៉ោង ២ រសៀល',
                        ),
                      ),
                      (
                        Icons.logout_rounded,
                        localized(
                          context,
                          'Check-out before 11:00 AM',
                          'ចាកចេញមុនម៉ោង ១១ ព្រឹក',
                        ),
                      ),
                      (
                        Icons.smoke_free_rounded,
                        localized(
                          context,
                          'No smoking indoors',
                          'ហាមជក់បារីក្នុងផ្ទះ',
                        ),
                      ),
                    ],
                  ),
                  SectionHeading(title: s.cancellation),
                  Text(
                    localized(
                      context,
                      'Free cancellation up to five days before check-in. Demo terms apply.',
                      'លុបដោយឥតគិតថ្លៃរហូតដល់ ៥ ថ្ងៃមុនចូលស្នាក់។ លក្ខខណ្ឌសាកល្បងត្រូវបានអនុវត្ត។',
                    ),
                  ),
                  SectionHeading(title: s.localArea),
                  Container(
                    height: 190,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(painter: _MapPainter()),
                        ),
                        const Center(
                          child: Icon(
                            Icons.location_pin,
                            color: AppColors.terracotta,
                            size: 46,
                          ),
                        ),
                        Positioned(
                          left: 12,
                          top: 12,
                          child: StatusBadge(
                            label: localized(
                              context,
                              'STATIC PREVIEW',
                              'ទិដ្ឋភាពសាកល្បង',
                            ),
                            color: AppColors.brown,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SectionHeading(
                    title: s.reviews,
                    action: s.viewAll,
                    onTap: () => context.push('/reviews/${property.id}'),
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.star_rounded, color: AppColors.gold),
                              SizedBox(width: 5),
                              Text(
                                '5.0',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            localized(
                              context,
                              'A peaceful stay with thoughtful details. Our host shared wonderful local tips.',
                              'កន្លែងស្ងប់ស្ងាត់ និងមានការយកចិត្តទុកដាក់។ ម្ចាស់ផ្ទះបានចែករំលែកព័ត៌មានក្នុងស្រុកដ៏ល្អ។',
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Lina · August 2026',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SectionHeading(title: s.similarStays),
                  SizedBox(
                    height:
                        340 +
                        (140 * (MediaQuery.textScalerOf(context).scale(1) - 1)),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      separatorBuilder: (_, _) => const SizedBox(width: 14),
                      itemBuilder: (context, index) => PropertyCard(
                        property:
                            mockProperties[(mockProperties.indexOf(property) +
                                    index +
                                    1) %
                                mockProperties.length],
                        width: 260,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Builder(
            builder: (context) {
              final price = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${formatPrice(property.priceUsd, state)} / ${s.perNight}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    s.addDates,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              );
              final button = FilledButton(
                key: const Key('reserve-button'),
                onPressed: () => context.push('/booking/${property.id}'),
                child: Text(s.reserve),
              );
              if (MediaQuery.textScalerOf(context).scale(1) > 1.3) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [price, const SizedBox(height: 8), button],
                );
              }
              return Row(
                children: [
                  Expanded(child: price),
                  button,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showAmenities(BuildContext context, Property property) =>
      showModalBottomSheet<void>(
        context: context,
        builder: (context) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).amenities,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              for (final amenity in property.amenities)
                ListTile(
                  leading: Icon(amenity.icon),
                  title: Text(
                    amenity.label.resolve(Localizations.localeOf(context)),
                  ),
                ),
            ],
          ),
        ),
      );
}

class _InfoRows extends StatelessWidget {
  const _InfoRows({required this.items});
  final List<(IconData, String)> items;
  @override
  Widget build(BuildContext context) => Column(
    children: items
        .map(
          (item) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(item.$1),
            title: Text(item.$2),
          ),
        )
        .toList(),
  );
}

class _RoomOption extends StatelessWidget {
  const _RoomOption({
    required this.property,
    required this.room,
    required this.state,
  });

  final Property property;
  final RoomType room;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final s = AppLocalizations.of(context);
    final image = Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.sandstone,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.bed_rounded, size: 34),
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          room.name.resolve(locale),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text('${room.bed.resolve(locale)} · ${room.guests} ${s.guests}'),
        Text(
          formatPrice(room.priceUsd, state),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
    final button = FilledButton.tonal(
      onPressed: () => context.push('/booking/${property.id}?room=${room.id}'),
      child: Text(localized(context, 'Select', 'ជ្រើសរើស')),
    );
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: largeText
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      image,
                      const SizedBox(width: 14),
                      Expanded(child: details),
                    ],
                  ),
                  const SizedBox(height: 12),
                  button,
                ],
              )
            : Row(
                children: [
                  image,
                  const SizedBox(width: 14),
                  Expanded(child: details),
                  button,
                ],
              ),
      ),
    );
  }
}

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key, required this.propertyId});
  final String propertyId;
  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  int current = 0;
  @override
  Widget build(BuildContext context) {
    final property = mockProperties.firstWhere(
      (item) => item.id == widget.propertyId,
    );
    final images = [
      property.image,
      ...mockProperties
          .where((item) => item.image != property.image)
          .map((item) => item.image)
          .take(3),
    ];
    return Scaffold(
      backgroundColor: AppColors.brown,
      appBar: AppBar(
        backgroundColor: AppColors.brown,
        foregroundColor: Colors.white,
        title: Text('${current + 1} / ${images.length}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              itemCount: images.length,
              onPageChanged: (value) => setState(() => current = value),
              itemBuilder: (context, index) => InteractiveViewer(
                child: Center(
                  child: stayImage(images[index], fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: SizedBox(
              height: 92,
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) => Container(
                  width: 72,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: current == index
                          ? AppColors.champagne
                          : Colors.transparent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: stayImage(images[index], fit: BoxFit.cover),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HostProfileScreen extends StatelessWidget {
  const HostProfileScreen({super.key, required this.ownerId});
  final String ownerId;
  @override
  Widget build(BuildContext context) {
    final properties = mockProperties
        .where((item) => item.owner.id == ownerId)
        .toList();
    final owner =
        properties.firstOrNull?.owner ??
        mockOwners.where((item) => item.id == ownerId).firstOrNull;
    if (owner == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(localized(context, 'Host profile', 'ប្រវត្តិម្ចាស់ផ្ទះ')),
        ),
        body: Center(
          child: Text(
            localized(context, 'Host not found', 'រកមិនឃើញម្ចាស់ផ្ទះ'),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(localized(context, 'Host profile', 'ប្រវត្តិម្ចាស់ផ្ទះ')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 42,
                backgroundColor: AppColors.sandstone,
                child: Icon(Icons.person_rounded, size: 42),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      owner.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    StatusBadge(
                      label: localized(
                        context,
                        'VERIFIED DEMO HOST',
                        'ម្ចាស់ផ្ទះសាកល្បង',
                      ),
                      color: AppColors.success,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: localized(
                    context,
                    'Years hosting',
                    'ឆ្នាំជាម្ចាស់ផ្ទះ',
                  ),
                  value: '${owner.yearsHosting}',
                  icon: Icons.home_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: localized(context, 'Response rate', 'អត្រាឆ្លើយតប'),
                  value: '${owner.responseRate}%',
                  icon: Icons.chat_outlined,
                ),
              ),
            ],
          ),
          SectionHeading(
            title: localized(context, 'Owner story', 'រឿងរ៉ាវម្ចាស់ផ្ទះ'),
          ),
          Text(
            owner.story.resolve(Localizations.localeOf(context)),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          SectionHeading(
            title: localized(
              context,
              '${owner.name}’s properties',
              'ទីតាំងរបស់ ${owner.name}',
            ),
          ),
          ...properties.map(
            (property) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CompactPropertyCard(property: property),
            ),
          ),
        ],
      ),
    );
  }
}

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key, required this.propertyId});
  final String propertyId;
  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  double rating = 5;
  final review = TextEditingController();
  List<Map<String, dynamic>> reviews = [];
  bool loadingReviews = true;
  @override
  void initState() {
    super.initState();
    Future.microtask(_loadReviews);
  }

  Future<void> _loadReviews() async {
    try {
      final api = ProviderScope.containerOf(context).read(apiClientProvider);
      final result = await api.request(
        '/reviews?propertyId=${Uri.encodeComponent(widget.propertyId)}',
      );
      if (mounted) {
        setState(() {
          reviews = (result['reviews'] as List<dynamic>)
              .cast<Map<String, dynamic>>();
          loadingReviews = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => loadingReviews = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  void dispose() {
    review.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final property = mockProperties.firstWhere(
      (item) => item.id == widget.propertyId,
    );
    final s = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.reviews)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  property.rating.toStringAsFixed(2),
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 6),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: AppColors.gold),
                    Icon(Icons.star_rounded, color: AppColors.gold),
                    Icon(Icons.star_rounded, color: AppColors.gold),
                    Icon(Icons.star_rounded, color: AppColors.gold),
                    Icon(Icons.star_half_rounded, color: AppColors.gold),
                  ],
                ),
                Text('${property.reviewCount} ${s.reviews}'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const LotusDivider(),
          if (loadingReviews) const Center(child: CircularProgressIndicator()),
          if (!loadingReviews && reviews.isEmpty)
            const Center(child: Text('No reviews yet')),
          ...reviews.map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(child: Icon(Icons.person_outline)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item['author']?.toString() ?? 'Traveler',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.gold,
                          size: 18,
                        ),
                        Text(' ${item['rating']}'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(item['comment']?.toString() ?? ''),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _leaveReview,
            icon: const Icon(Icons.rate_review_outlined),
            label: Text(
              localized(context, 'Leave a review', 'សរសេរការវាយតម្លៃ'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveReview() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
                localized(
                  context,
                  'Share your experience',
                  'ចែករំលែកបទពិសោធន៍',
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => IconButton(
                    onPressed: () => setModalState(() => rating = index + 1),
                    icon: Icon(
                      index < rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ),
              TextField(
                controller: review,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: localized(
                    context,
                    'Your review',
                    'ការវាយតម្លៃរបស់អ្នក',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      localized(
                        context,
                        'Photo preview is demo-only',
                        'ទិដ្ឋភាពរូបថតគឺសាកល្បងប៉ុណ្ណោះ',
                      ),
                    ),
                  ),
                ),
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(
                  localized(context, 'Add photo preview', 'បន្ថែមរូបថតសាកល្បង'),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  try {
                    final api = ProviderScope.containerOf(
                      this.context,
                    ).read(apiClientProvider);
                    await api.request(
                      '/reviews',
                      method: 'POST',
                      body: {
                        'propertyId': widget.propertyId,
                        'rating': rating.round(),
                        'comment': review.text.trim(),
                      },
                    );
                    if (!mounted || !context.mounted) return;
                    Navigator.pop(context);
                    review.clear();
                    await _loadReviews();
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error.toString())));
                    }
                  }
                },
                child: Text(AppLocalizations.of(context).send),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key, required this.propertyId, this.roomId});
  final String propertyId;
  final String? roomId;
  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  int step = 0;
  int room = 0;
  int guests = 2;
  DateTimeRange dates = DateTimeRange(
    start: DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 1)),
    end: DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 4)),
  );
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final request = TextEditingController();
  bool agreed = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadGuestDetails);
    if (widget.roomId != null) {
      final property = mockProperties.firstWhere(
        (item) => item.id == widget.propertyId,
      );
      final index = property.rooms.indexWhere(
        (item) => item.id == widget.roomId,
      );
      if (index >= 0) room = index;
    }
  }

  Future<void> _loadGuestDetails() async {
    if (!mounted) return;
    if (ref.read(apiClientProvider).token == null) return;
    try {
      final result = await ref.read(apiClientProvider).request('/auth/me');
      if (!mounted) return;
      final user = result['user'] as Map<String, dynamic>;
      if (name.text.isEmpty) name.text = user['name']?.toString() ?? '';
      if (email.text.isEmpty) email.text = user['email']?.toString() ?? '';
    } catch (_) {
      // The form remains editable if the saved session has expired.
    }
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    request.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final property = mockProperties.firstWhere(
      (item) => item.id == widget.propertyId,
    );
    final s = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final titles = [
      s.selectRoom,
      s.addDates,
      s.guests,
      s.guestDetails,
      s.reviewPay,
    ];
    return Scaffold(
      appBar: AppBar(title: Text(titles[step])),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(
                  titles.length,
                  (index) => Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 4,
                      margin: const EdgeInsetsDirectional.only(end: 4),
                      decoration: BoxDecoration(
                        color: index <= step
                            ? AppColors.gold
                            : AppColors.sandstone,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: switch (step) {
                    0 => RadioGroup<int>(
                      groupValue: room,
                      onChanged: (value) {
                        if (value != null) setState(() => room = value);
                      },
                      child: Column(
                        key: const ValueKey(0),
                        children: List.generate(property.rooms.length, (index) {
                          final item = property.rooms[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: RadioListTile<int>(
                              value: index,
                              title: Text(item.name.resolve(locale)),
                              subtitle: Text(
                                '${item.bed.resolve(locale)} · ${formatPrice(item.priceUsd, ref.watch(appControllerProvider))}',
                              ),
                              secondary: const Icon(Icons.bed_outlined),
                            ),
                          );
                        }),
                      ),
                    ),
                    1 => Column(
                      key: const ValueKey(1),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SummaryTile(
                          icon: Icons.login_rounded,
                          label: s.checkIn,
                          value: DateFormat.yMMMd(
                            locale.languageCode,
                          ).format(dates.start),
                        ),
                        const SizedBox(height: 12),
                        _SummaryTile(
                          icon: Icons.logout_rounded,
                          label: s.checkOut,
                          value: DateFormat.yMMMd(
                            locale.languageCode,
                          ).format(dates.end),
                        ),
                        const SizedBox(height: 18),
                        OutlinedButton.icon(
                          onPressed: _changeDates,
                          icon: const Icon(Icons.calendar_month_outlined),
                          label: Text(
                            localized(
                              context,
                              'Change dates',
                              'ប្ដូរកាលបរិច្ឆេទ',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            '${dates.duration.inDays} ${localized(context, 'nights selected', 'យប់បានជ្រើសរើស')}',
                          ),
                        ),
                      ],
                    ),
                    2 => Column(
                      key: const ValueKey(2),
                      children: [
                        GuestStepper(
                          label: s.adults,
                          subtitle: localized(
                            context,
                            'Age 13 or above',
                            'អាយុ ១៣ ឆ្នាំឡើង',
                          ),
                          value: guests,
                          onChanged: (value) =>
                              setState(() => guests = value.clamp(1, 12)),
                        ),
                        GuestStepper(
                          label: s.children,
                          subtitle: localized(
                            context,
                            'Age 2–12',
                            'អាយុ ២–១២ ឆ្នាំ',
                          ),
                          value: 0,
                          onChanged: (_) {},
                        ),
                        GuestStepper(
                          label: s.infants,
                          subtitle: localized(
                            context,
                            'Under age 2',
                            'អាយុក្រោម ២ ឆ្នាំ',
                          ),
                          value: 0,
                          onChanged: (_) {},
                        ),
                      ],
                    ),
                    3 => Form(
                      key: formKey,
                      child: Column(
                        key: const ValueKey(3),
                        children: [
                          TextFormField(
                            controller: name,
                            decoration: InputDecoration(labelText: s.fullName),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? s.requiredField
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: phone,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(labelText: s.phone),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? s.requiredField
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(labelText: s.email),
                            validator: (value) =>
                                value == null || !value.contains('@')
                                ? s.validEmail
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            initialValue: localized(
                              context,
                              'Cambodia',
                              'កម្ពុជា',
                            ),
                            decoration: InputDecoration(labelText: s.country),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: request,
                            minLines: 2,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: s.specialRequest,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _ => _PaymentReview(
                      property: property,
                      room: property.rooms[room],
                      dates: dates,
                      guests: guests,
                      agreed: agreed,
                      onAgreed: (value) => setState(() => agreed = value),
                    ),
                  },
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
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
                        step == 4 ? 'confirm-booking' : 'booking-continue',
                      ),
                      onPressed: step == 4 && !agreed ? null : _next,
                      child: Text(
                        step == 4 ? s.confirmBooking : s.continueLabel,
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

  Future<void> _changeDates() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final value = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 730)),
      initialDateRange: dates,
    );
    if (value != null) setState(() => dates = value);
  }

  Future<void> _next() async {
    if (step == 3 && !(formKey.currentState?.validate() ?? false)) return;
    if (step < 4) {
      setState(() => step++);
      return;
    }
    final property = mockProperties.firstWhere(
      (item) => item.id == widget.propertyId,
    );
    final selectedRoom = property.rooms[room];
    final totalUsd = selectedRoom.priceUsd * dates.duration.inDays;
    try {
      final response = await ref
          .read(apiClientProvider)
          .request(
            '/bookings',
            method: 'POST',
            body: {
              'propertyId': property.id,
              'roomId': selectedRoom.id,
              'room': selectedRoom.name.en,
              'checkIn': DateFormat('yyyy-MM-dd').format(dates.start),
              'checkOut': DateFormat('yyyy-MM-dd').format(dates.end),
              'guests': guests,
              'total': totalUsd,
              'currency': 'USD',
              'guest': name.text.trim(),
              'guestEmail': email.text.trim(),
              'guestPhone': phone.text.trim(),
              'specialRequest': request.text.trim(),
            },
          );
      final booking = bookingFromApi(
        response['booking'] as Map<String, dynamic>,
      );
      ref.read(appControllerProvider.notifier).addBooking(booking);
      if (mounted) context.go('/payment/${booking.id}');
    } catch (error) {
      if (!mounted) return;
      final errorMsg = error.toString().toLowerCase();
      if (errorMsg.contains('already reserved for the selected dates') ||
          errorMsg.contains('already reserved')) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            icon: const Icon(
              Icons.event_busy_rounded,
              color: AppColors.terracotta,
              size: 40,
            ),
            title: Text(
              localized(context, 'Dates Unavailable', 'កាលបរិច្ឆេទមិនទំនេរទេ'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(
              localized(
                context,
                'This property is already reserved for the selected dates. Please choose different dates to continue your stay.',
                'កន្លែងស្នាក់នេះត្រូវបានកក់រួចហើយសម្រាប់កាលបរិច្ឆេទដែលបានជ្រើសរើស។ សូមជ្រើសរើសកាលបរិច្ឆេទផ្សេងទៀតដើម្បីបន្ត។',
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  setState(() => step = 1);
                },
                child: Text(
                  localized(
                    context,
                    'Pick Different Dates',
                    'ជ្រើសកាលបរិច្ឆេទថ្មី',
                  ),
                ),
              ),
            ],
          ),
        );
      } else if (errorMsg.contains(
            'selected dates include blocked host dates',
          ) ||
          errorMsg.contains('blocked host dates')) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            icon: const Icon(
              Icons.block_rounded,
              color: AppColors.terracotta,
              size: 40,
            ),
            title: Text(
              localized(
                context,
                'Host Blocked Dates',
                'កាលបរិច្ឆេទត្រូវបានបិទដោយម្ចាស់',
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(
              localized(
                context,
                'The host has marked one or more of these dates as unavailable. Please select alternative dates for your stay.',
                'ម្ចាស់កន្លែងស្នាក់បានបិទកាលបរិច្ឆេទមួយចំនួនមិនឱ្យកក់។ សូមជ្រើសរើសកាលបរិច្ឆេទផ្សេងទៀត។',
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  setState(() => step = 1);
                },
                child: Text(
                  localized(
                    context,
                    'Select Other Dates',
                    'ជ្រើសកាលបរិច្ឆេទផ្សេង',
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: Icon(icon, color: AppColors.gold),
      title: Text(label),
      subtitle: Text(value, style: Theme.of(context).textTheme.titleMedium),
    ),
  );
}

class _PaymentReview extends ConsumerWidget {
  const _PaymentReview({
    required this.property,
    required this.room,
    required this.dates,
    required this.guests,
    required this.agreed,
    required this.onAgreed,
  });
  final Property property;
  final RoomType room;
  final DateTimeRange dates;
  final int guests;
  final bool agreed;
  final ValueChanged<bool> onAgreed;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final s = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final nights = dates.duration.inDays;
    final subtotal = room.priceUsd * nights;
    final total = subtotal;
    return Column(
      key: const ValueKey(4),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CompactPropertyCard(
          property: property,
          trailing: const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),
        SectionHeading(title: s.priceBreakdown),
        _PriceLine(
          label: '${formatPrice(room.priceUsd, state)} × $nights ${s.perNight}',
          value: formatPrice(subtotal, state),
        ),
        const Divider(height: 28),
        _PriceLine(
          label: s.total,
          value: formatPrice(total, state),
          strong: true,
        ),
        SectionHeading(title: s.paymentMethod),
        Card(
          child: ListTile(
            leading: const Icon(Icons.qr_code_rounded),
            title: const Text('KHQR'),
            subtitle: Text(
              localized(
                context,
                'Payment instructions appear after you create the booking.',
                'ការណែនាំអំពីការទូទាត់នឹងបង្ហាញបន្ទាប់ពីបង្កើតការកក់។',
              ),
            ),
          ),
        ),
        CheckboxListTile(
          value: agreed,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          onChanged: (value) => onAgreed(value ?? false),
          title: Text(
            localized(
              context,
              'I agree to the house rules and demo cancellation policy.',
              'ខ្ញុំយល់ព្រមតាមច្បាប់ផ្ទះ និងគោលការណ៍លុបចោលសាកល្បង។',
            ),
          ),
        ),
        Text(
          '${DateFormat.MMMd(locale.languageCode).format(dates.start)} – ${DateFormat.MMMd(locale.languageCode).format(dates.end)} · $guests ${s.guests}',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({
    required this.label,
    required this.value,
    this.strong = false,
  });
  final String label;
  final String value;
  final bool strong;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: strong ? const TextStyle(fontWeight: FontWeight.w700) : null,
          ),
        ),
        Text(
          value,
          style: strong ? Theme.of(context).textTheme.titleMedium : null,
        ),
      ],
    ),
  );
}

class BookingSuccessScreen extends ConsumerWidget {
  const BookingSuccessScreen({super.key, required this.bookingId});
  final String bookingId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ref
        .watch(appControllerProvider)
        .bookings
        .firstWhere(
          (item) => item.id == bookingId,
          orElse: () => ref.watch(appControllerProvider).bookings.first,
        );
    final property = mockProperties.firstWhere(
      (item) => item.id == booking.propertyId,
    );
    final s = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: Color(0x193C7A57),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 46,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                s.bookingConfirmed,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                s.demoPayment,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.terracotta),
              ),
              const SizedBox(height: 24),
              CompactPropertyCard(
                property: property,
                trailing: const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _PriceLine(
                        label: s.bookingReference,
                        value: booking.reference,
                        strong: true,
                      ),
                      _PriceLine(label: s.guests, value: '${booking.guests}'),
                      _PriceLine(
                        label: s.total,
                        value: formatPrice(booking.totalUsd, state),
                        strong: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => _receipt(context, booking, property),
                icon: const Icon(Icons.receipt_long_outlined),
                label: Text(
                  localized(
                    context,
                    'View mock receipt',
                    'មើលបង្កាន់ដៃសាកល្បង',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: () => context.go('/traveler/trips'),
                child: Text(s.viewTrip),
              ),
              TextButton(
                onPressed: () => context.go('/traveler/explore'),
                child: Text(s.returnExplore),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _receipt(BuildContext context, Booking booking, Property property) =>
      showModalBottomSheet<void>(
        context: context,
        builder: (context) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const KhmerStayLogo(compact: true),
              const LotusDivider(),
              Text(
                localized(context, 'DEMONSTRATION RECEIPT', 'បង្កាន់ដៃសាកល្បង'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Text(booking.reference),
              Text(property.name.resolve(Localizations.localeOf(context))),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context).demoPayment,
                style: const TextStyle(color: AppColors.terracotta),
              ),
            ],
          ),
        ),
      );
}

class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key, required this.conversationId});
  final String conversationId;
  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final message = TextEditingController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref
          .read(appControllerProvider.notifier)
          .markConversationRead(widget.conversationId),
    );
  }

  @override
  void dispose() {
    message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversation = ref
        .watch(appControllerProvider)
        .conversations
        .firstWhere((item) => item.id == widget.conversationId);
    final property = mockProperties
        .where((item) => item.id == conversation.propertyId)
        .firstOrNull;
    final locale = Localizations.localeOf(context);
    final s = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(conversation.name),
            Text(
              property?.name.resolve(locale) ?? conversation.subject,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'report',
                child: Text(
                  localized(
                    context,
                    'Report conversation',
                    'រាយការណ៍ការសន្ទនា',
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'block',
                child: Text(
                  localized(context, 'Block contact', 'បិទទំនាក់ទំនង'),
                ),
              ),
            ],
            onSelected: (value) => _confirm(context, value),
          ),
        ],
      ),
      body: Column(
        children: [
          Material(
            color: AppColors.champagne.withValues(alpha: .16),
            child: property == null
                ? ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.support_agent_rounded),
                    ),
                    title: Text(conversation.subject),
                    subtitle: Text(
                      localized(
                        context,
                        'Private support with KhmerStay',
                        'ការគាំទ្រឯកជនជាមួយ KhmerStay',
                      ),
                    ),
                  )
                : ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: stayImage(
                        property.image,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(property.name.resolve(locale)),
                    subtitle: Text(
                      localized(
                        context,
                        'Property conversation',
                        'ការសន្ទនាអំពីកន្លែងស្នាក់នៅ',
                      ),
                    ),
                  ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: conversation.messages
                  .map((item) => MessageBubble(message: item))
                  .toList(),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          localized(
                            context,
                            'Attachments are visual-only in this demo.',
                            'ឯកសារភ្ជាប់គ្រាន់តែជាការបង្ហាញក្នុងការសាកល្បងនេះ។',
                          ),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.attach_file_rounded),
                  ),
                  Expanded(
                    child: TextField(
                      controller: message,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(hintText: s.messages),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () {
                      ref
                          .read(appControllerProvider.notifier)
                          .sendMessage(widget.conversationId, message.text);
                      message.clear();
                    },
                    icon: const Icon(Icons.send_rounded),
                    tooltip: s.send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirm(BuildContext context, String action) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        action == 'report'
            ? localized(context, 'Report conversation?', 'រាយការណ៍ការសន្ទនា?')
            : localized(context, 'Block this contact?', 'បិទទំនាក់ទំនងនេះ?'),
      ),
      content: Text(
        localized(
          context,
          'This is a local demonstration. No report will be sent.',
          'នេះជាការសាកល្បងក្នុងឧបករណ៍។ មិនមានរបាយការណ៍ត្រូវបានផ្ញើទេ។',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context).cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context).done),
        ),
      ],
    ),
  );
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});
  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool loading = true;
  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    try {
      final result = await ref
          .read(apiClientProvider)
          .request('/notifications');
      if (mounted) {
        setState(() {
          notifications = (result['notifications'] as List<dynamic>)
              .cast<Map<String, dynamic>>();
          loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final read = ref.watch(
      appControllerProvider.select((state) => state.readNotificationIds),
    );
    final items = notifications
        .map(
          (item) => (
            item['id'] as String,
            item['category'] == 'message'
                ? Icons.chat_bubble_outline_rounded
                : Icons.notifications_none_rounded,
            item['title']?.toString() ?? '',
            item['body']?.toString() ?? '',
          ),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(s.notifications),
        actions: [
          TextButton(
            onPressed: () async {
              for (final item in notifications.where(
                (item) => item['read'] != true,
              )) {
                await ref
                    .read(appControllerProvider.notifier)
                    .markNotificationRead(item['id'] as String);
                item['read'] = true;
              }
              if (mounted) setState(() {});
            },
            child: Text(s.markAllRead),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(indent: 70),
              itemBuilder: (context, index) {
                final item = items[index];
                final isRead =
                    read.contains(item.$1) ||
                    notifications[index]['read'] == true;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  tileColor: isRead
                      ? null
                      : AppColors.champagne.withValues(alpha: .1),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.champagne.withValues(alpha: .25),
                    child: Icon(item.$2, color: AppColors.brown),
                  ),
                  title: Text(
                    item.$3,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(item.$4),
                  trailing: isRead ? null : const Badge(),
                  onTap: () async {
                    try {
                      await ref
                          .read(appControllerProvider.notifier)
                          .markNotificationRead(item.$1);
                      if (mounted) {
                        setState(() => notifications[index]['read'] = true);
                      }
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error.toString())),
                        );
                      }
                    }
                  },
                );
              },
            ),
    );
  }
}
