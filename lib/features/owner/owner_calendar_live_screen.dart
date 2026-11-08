import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/app_state.dart';
import '../startup/startup_screens.dart';

class OwnerCalendarLiveScreen extends ConsumerStatefulWidget {
  const OwnerCalendarLiveScreen({super.key});

  @override
  ConsumerState<OwnerCalendarLiveScreen> createState() =>
      _OwnerCalendarLiveScreenState();
}

class _OwnerCalendarLiveScreenState
    extends ConsumerState<OwnerCalendarLiveScreen> {
  DateTime selected = DateUtils.dateOnly(DateTime.now());
  List<Map<String, dynamic>> properties = [];
  List<Map<String, dynamic>> bookings = [];
  Set<String> blocked = {};
  String? propertyId;
  String? error;
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  Future<void> load() async {
    try {
      final api = ref.read(apiClientProvider);
      final results = await Future.wait([
        api.request('/properties'),
        api.request('/blocked-dates'),
        api.request('/bookings'),
      ]);
      if (!mounted) return;
      final items = (results[0]['properties'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      setState(() {
        properties = items;
        propertyId = items.any((item) => item['id'] == propertyId)
            ? propertyId
            : (items.firstOrNull?['id'] as String?);
        blocked = (results[1]['blockedDates'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .where((item) => item['propertyId'] == propertyId)
            .map((item) => item['date'] as String)
            .toSet();
        bookings = (results[2]['bookings'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
        loading = false;
        error = null;
      });
    } catch (cause) {
      if (!mounted) return;
      setState(() {
        error = cause.toString();
        loading = false;
      });
    }
  }

  Future<void> selectProperty(String id) async {
    setState(() {
      propertyId = id;
      loading = true;
    });
    await load();
  }

  Future<void> toggle() async {
    final id = propertyId;
    if (id == null) return;
    final date = DateFormat('yyyy-MM-dd').format(selected);
    setState(() => saving = true);
    try {
      await ref
          .read(apiClientProvider)
          .request(
            '/blocked-dates',
            method: 'POST',
            body: {
              'propertyId': id,
              'date': date,
              'blocked': !blocked.contains(date),
            },
          );
      await load();
    } catch (cause) {
      if (mounted) setState(() => error = cause.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('yyyy-MM-dd').format(selected);
    final occupied = bookings
        .where(
          (booking) =>
              booking['propertyId'] == propertyId &&
              booking['status'] != 'Cancelled' &&
              booking['status'] != 'Declined' &&
              (booking['checkIn'] as String).compareTo(date) <= 0 &&
              (booking['checkOut'] as String).compareTo(date) > 0,
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          localized(context, 'Availability calendar', 'ប្រតិទិនភាពទំនេរ'),
        ),
        actions: [
          TextButton(
            onPressed: () => context.push('/owner/pricing'),
            child: Text(localized(context, 'Pricing', 'តម្លៃ')),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  if (properties.isEmpty)
                    const Text('Add a property before managing availability.')
                  else ...[
                    DropdownButtonFormField<String>(
                      initialValue: propertyId,
                      decoration: const InputDecoration(labelText: 'Property'),
                      items: [
                        for (final property in properties)
                          DropdownMenuItem(
                            value: property['id'] as String,
                            child: Text(property['name'] as String),
                          ),
                      ],
                      onChanged: (id) {
                        if (id != null) selectProperty(id);
                      },
                    ),
                    const SizedBox(height: 16),
                    CalendarDatePicker(
                      initialDate: selected,
                      firstDate: DateUtils.dateOnly(DateTime.now()),
                      lastDate: DateUtils.dateOnly(
                        DateTime.now(),
                      ).add(const Duration(days: 730)),
                      onDateChanged: (value) =>
                          setState(() => selected = value),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      DateFormat.yMMMMd().format(selected),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(blocked.contains(date) ? 'Blocked' : 'Available'),
                    if (occupied.isNotEmpty)
                      Text('${occupied.length} booking(s) include this date.'),
                    const SizedBox(height: 16),
                    FilledButton.tonal(
                      onPressed: saving ? null : toggle,
                      child: Text(
                        blocked.contains(date) ? 'Unblock date' : 'Block date',
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
