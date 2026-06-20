import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/equipment.dart';
import '../state/app_state.dart';

const _palette = [
  Color(0xFFEF5350), // Red
  Color(0xFFFF9800), // Orange
  Color(0xFFFFD600), // Amber
  Color(0xFF4CAF50), // Green
  Color(0xFF2196F3), // Blue
  Color(0xFF9C27B0), // Purple
  Color(0xFF795548), // Brown
  Color(0xFF607D8B), // Blue Grey
  Color(0xFF00BCD4), // Cyan
  Color(0xFFE91E63), // Pink
];

class EquipmentScreen extends StatelessWidget {
  const EquipmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final allEquipment = state.allEquipment;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Equipment'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: allEquipment.isEmpty
          ? const Center(child: Text('No equipment yet. Add some below.'))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: allEquipment.length,
              itemBuilder: (ctx, i) {
                final eq = allEquipment[i];
                final count = state.bookings
                    .where((b) => b.equipmentId == eq.id)
                    .length;
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: eq.isActive
                            ? eq.color
                            : eq.color.withAlpha(80),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.construction,
                        color: Colors.white
                            .withAlpha(eq.isActive ? 230 : 120),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      eq.name,
                      style: TextStyle(
                        decoration: eq.isActive
                            ? null
                            : TextDecoration.lineThrough,
                        color: eq.isActive ? null : Colors.grey,
                      ),
                    ),
                    subtitle: Text(
                        '$count booking${count == 1 ? '' : 's'} total'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Edit',
                          onPressed: () =>
                              _showDialog(context, state, eq),
                        ),
                        Switch(
                          value: eq.isActive,
                          onChanged: (_) =>
                              state.toggleEquipmentActive(eq.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDialog(context, context.read<AppState>(), null),
        icon: const Icon(Icons.add),
        label: const Text('Add Equipment'),
      ),
    );
  }

  void _showDialog(
      BuildContext context, AppState state, Equipment? existing) {
    final nameCtrl = TextEditingController(text: existing?.name);
    int selectedColor = existing?.colorValue ?? _palette.first.value;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title:
              Text(existing == null ? 'Add Equipment' : 'Edit Equipment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Equipment Name',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 20),
                const Text('Color',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _palette
                      .map((c) => GestureDetector(
                            onTap: () =>
                                setInner(() => selectedColor = c.value),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: selectedColor == c.value
                                    ? Border.all(
                                        color: Colors.black87, width: 3)
                                    : null,
                                boxShadow: selectedColor == c.value
                                    ? [
                                        BoxShadow(
                                          color:
                                              c.withAlpha(120),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        )
                                      ]
                                    : null,
                              ),
                              child: selectedColor == c.value
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 20)
                                  : null,
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                if (existing == null) {
                  state.addEquipment(name, selectedColor);
                } else {
                  state.updateEquipment(existing.id,
                      name: name, colorValue: selectedColor);
                }
                Navigator.pop(ctx);
              },
              child: Text(existing == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
