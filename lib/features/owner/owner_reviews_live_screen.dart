import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_state.dart';
import '../startup/startup_screens.dart';

class OwnerReviewsLiveScreen extends ConsumerStatefulWidget {
  const OwnerReviewsLiveScreen({super.key});

  @override
  ConsumerState<OwnerReviewsLiveScreen> createState() =>
      _OwnerReviewsLiveScreenState();
}

class _OwnerReviewsLiveScreenState
    extends ConsumerState<OwnerReviewsLiveScreen> {
  List<Map<String, dynamic>> reviews = [];
  Map<String, String> propertyNames = {};
  String? error;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  Future<void> load() async {
    try {
      final api = ref.read(apiClientProvider);
      final propertiesResult = await api.request('/properties');
      final reviewResult = await api.request('/reviews');
      final properties = (propertiesResult['properties'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final names = {
        for (final property in properties)
          property['id'] as String: property['name'] as String,
      };
      final items = (reviewResult['reviews'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((item) => names.containsKey(item['propertyId']))
          .toList();
      if (!mounted) return;
      setState(() {
        propertyNames = names;
        reviews = items;
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

  Future<void> respond(Map<String, dynamic> review) async {
    final controller = TextEditingController(
      text: review['response'] as String? ?? '',
    );
    final response = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          localized(context, 'Public response', 'ការឆ្លើយតបជាសាធារណៈ'),
        ),
        content: TextField(
          controller: controller,
          maxLines: 4,
          maxLength: 2000,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (response == null || response.length < 2) return;
    try {
      await ref
          .read(apiClientProvider)
          .request(
            '/reviews/${review['id']}/response',
            method: 'POST',
            body: {'response': response},
          );
      await load();
    } catch (cause) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(cause.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final average = reviews.isEmpty
        ? '—'
        : (reviews.fold<int>(0, (sum, item) => sum + (item['rating'] as int)) /
                  reviews.length)
              .toStringAsFixed(1);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          localized(context, 'Guest reviews', 'ការវាយតម្លៃរបស់ភ្ញៀវ'),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!))
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    '${reviews.length} reviews · $average ★',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  if (reviews.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No guest reviews yet.'),
                    ),
                  for (final review in reviews)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              review['author'] as String,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(propertyNames[review['propertyId']] ?? ''),
                            Text('${review['rating']} ★'),
                            const SizedBox(height: 8),
                            Text(review['comment'] as String),
                            if ((review['response'] as String).isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text('Your response: ${review['response']}'),
                            ],
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => respond(review),
                                child: Text(
                                  (review['response'] as String).isEmpty
                                      ? 'Respond'
                                      : 'Edit response',
                                ),
                              ),
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
