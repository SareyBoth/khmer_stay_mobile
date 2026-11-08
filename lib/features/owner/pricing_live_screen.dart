import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_state.dart';
import '../../l10n/app_localizations.dart';

class PricingLiveScreen extends ConsumerStatefulWidget {
  const PricingLiveScreen({super.key});
  @override
  ConsumerState<PricingLiveScreen> createState() => _PricingLiveScreenState();
}

class _PricingLiveScreenState extends ConsumerState<PricingLiveScreen> {
  List<Map<String, dynamic>> properties = [];
  String? selectedId;
  bool loading = true;
  bool saving = false;
  String? error;
  final prices = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  @override
  void dispose() {
    for (final controller in prices.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> load() async {
    try {
      final response = await ref.read(apiClientProvider).request('/properties');
      final records = (response['properties'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        properties = records;
        selectedId = records.isEmpty ? null : records.first['id'] as String;
        loading = false;
        error = null;
      });
      setPrices();
    } catch (cause) {
      if (mounted) {
        setState(() {
          loading = false;
          error = cause.toString();
        });
      }
    }
  }

  void setPrices() {
    for (final controller in prices.values) {
      controller.dispose();
    }
    prices.clear();
    final property = properties
        .where((item) => item['id'] == selectedId)
        .firstOrNull;
    if (property == null) return;
    for (final raw in (property['roomTypes'] as List<dynamic>)) {
      final room = raw as Map<String, dynamic>;
      prices[room['id'] as String] = TextEditingController(
        text: (room['price'] as num).toString(),
      );
    }
  }

  Future<void> save() async {
    final property = properties
        .where((item) => item['id'] == selectedId)
        .firstOrNull;
    if (property == null) return;
    final rooms = (property['roomTypes'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((room) {
          final price = double.tryParse(prices[room['id']]?.text ?? '') ?? 0;
          return {...room, 'price': price};
        })
        .toList();
    if (rooms.any((room) => (room['price'] as double) <= 0)) {
      setState(() => error = 'Enter a positive price for every room');
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await ref
          .read(apiClientProvider)
          .request(
            '/properties/$selectedId',
            method: 'PATCH',
            body: {'roomTypes': rooms},
          );
      await ref.read(appControllerProvider.notifier).loadServerData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prices saved to the local server')),
        );
      }
    } catch (cause) {
      if (mounted) setState(() => error = cause.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final property = properties
        .where((item) => item['id'] == selectedId)
        .firstOrNull;
    final rooms = property == null
        ? <Map<String, dynamic>>[]
        : (property['roomTypes'] as List<dynamic>).cast<Map<String, dynamic>>();
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).pricing)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                if (properties.isEmpty) const Text('No properties yet'),
                if (properties.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: selectedId,
                    decoration: const InputDecoration(labelText: 'Property'),
                    items: [
                      for (final item in properties)
                        DropdownMenuItem(
                          value: item['id'] as String,
                          child: Text(item['name'] as String),
                        ),
                    ],
                    onChanged: (value) {
                      setState(() => selectedId = value);
                      setPrices();
                    },
                  ),
                const SizedBox(height: 20),
                for (final room in rooms)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextField(
                      controller: prices[room['id']],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: '${room['name']} · nightly price',
                        prefixText: r'$ ',
                      ),
                    ),
                  ),
                if (rooms.isNotEmpty)
                  FilledButton(
                    onPressed: saving ? null : save,
                    child: Text(
                      saving
                          ? 'Saving…'
                          : AppLocalizations.of(context).saveChanges,
                    ),
                  ),
              ],
            ),
    );
  }
}
