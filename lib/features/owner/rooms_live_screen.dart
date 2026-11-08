import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_state.dart';
import '../../l10n/app_localizations.dart';

class RoomsLiveScreen extends ConsumerStatefulWidget {
  const RoomsLiveScreen({super.key});
  @override
  ConsumerState<RoomsLiveScreen> createState() => _RoomsLiveScreenState();
}

class _RoomsLiveScreenState extends ConsumerState<RoomsLiveScreen> {
  List<Map<String, dynamic>> properties = [];
  String? selectedId;
  bool loading = true;
  String? error;
  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  Future<void> load() async {
    try {
      final result = await ref.read(apiClientProvider).request('/properties');
      final records = (result['properties'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      if (mounted) {
        setState(() {
          properties = records;
          selectedId ??= records.firstOrNull?['id'] as String?;
          loading = false;
          error = null;
        });
      }
    } catch (cause) {
      if (mounted) {
        setState(() {
          loading = false;
          error = cause.toString();
        });
      }
    }
  }

  Map<String, dynamic>? get selected =>
      properties.where((item) => item['id'] == selectedId).firstOrNull;
  List<Map<String, dynamic>> get rooms => selected == null
      ? []
      : (selected!['roomTypes'] as List<dynamic>).cast<Map<String, dynamic>>();

  Future<void> saveRooms(List<Map<String, dynamic>> updated) async {
    if (updated.isEmpty || selectedId == null) return;
    try {
      final response = await ref
          .read(apiClientProvider)
          .request(
            '/properties/$selectedId',
            method: 'PATCH',
            body: {'roomTypes': updated},
          );
      final saved = response['property'] as Map<String, dynamic>;
      if (mounted) {
        setState(
          () => properties = [
            for (final item in properties)
              if (item['id'] == selectedId) saved else item,
          ],
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rooms saved to the local server')),
        );
      }
      await ref.read(appControllerProvider.notifier).loadServerData();
    } catch (cause) {
      if (mounted) setState(() => error = cause.toString());
    }
  }

  Future<void> editRoom([Map<String, dynamic>? room]) async {
    if (selectedId == null) return;
    final name = TextEditingController(text: room?['name']?.toString() ?? '');
    final bed = TextEditingController(
      text: room?['bed']?.toString() ?? '1 queen bed',
    );
    final guests = TextEditingController(
      text: room?['guests']?.toString() ?? '2',
    );
    final inventory = TextEditingController(
      text: room?['inventory']?.toString() ?? '1',
    );
    final price = TextEditingController(
      text: room?['price']?.toString() ?? '35',
    );
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                room == null ? 'Add room' : 'Edit room',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Room name'),
              ),
              TextField(
                controller: bed,
                decoration: const InputDecoration(labelText: 'Bed'),
              ),
              TextField(
                controller: guests,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Guests'),
              ),
              TextField(
                controller: inventory,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Inventory'),
              ),
              TextField(
                controller: price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Nightly price USD',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  final count = int.tryParse(guests.text) ?? 0;
                  final stock = int.tryParse(inventory.text) ?? 0;
                  final cost = double.tryParse(price.text) ?? 0;
                  if (name.text.trim().isEmpty ||
                      count < 1 ||
                      stock < 1 ||
                      cost <= 0) {
                    return;
                  }
                  Navigator.pop(sheetContext, {
                    'id':
                        room?['id'] ??
                        'room-${DateTime.now().microsecondsSinceEpoch}',
                    'name': name.text.trim(),
                    'nameKm': room?['nameKm'] ?? name.text.trim(),
                    'bed': bed.text.trim(),
                    'guests': count,
                    'inventory': stock,
                    'price': cost,
                  });
                },
                child: Text(AppLocalizations.of(sheetContext).saveChanges),
              ),
            ],
          ),
        ),
      ),
    );
    name.dispose();
    bed.dispose();
    guests.dispose();
    inventory.dispose();
    price.dispose();
    if (result == null) return;
    await saveRooms(
      room == null
          ? [...rooms, result]
          : [
              for (final item in rooms)
                if (item['id'] == room['id']) result else item,
            ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppLocalizations.of(context).rooms)),
    floatingActionButton: selectedId == null
        ? null
        : FloatingActionButton.extended(
            onPressed: () => editRoom(),
            icon: const Icon(Icons.add),
            label: const Text('Add room'),
          ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),
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
                  onChanged: (value) => setState(() => selectedId = value),
                ),
              const SizedBox(height: 16),
              for (final room in rooms)
                Card(
                  child: ListTile(
                    title: Text(room['name'] as String),
                    subtitle: Text(
                      '${room['bed']} · ${room['guests']} guests · ${room['inventory']} available · \$${room['price']}/night',
                    ),
                    onTap: () => editRoom(room),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          editRoom(room);
                        } else if (rooms.length > 1) {
                          saveRooms(
                            rooms
                                .where((item) => item['id'] != room['id'])
                                .toList(),
                          );
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        if (rooms.length > 1)
                          const PopupMenuItem(
                            value: 'remove',
                            child: Text('Remove'),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
  );
}
