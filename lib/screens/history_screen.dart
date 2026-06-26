import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/trip.dart';
import '../state/mileage_state.dart';
import '../widgets/trip_card.dart';
import 'add_trip_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filter = 'All';
  int _year = DateTime.now().year;

  List<Trip> _filtered(List<Trip> trips) {
    return trips.where((t) {
      final yearMatch = t.date.year == _year;
      final purposeMatch = _filter == 'All' || t.purpose == _filter;
      return yearMatch && purposeMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MileageState>();
    final filtered = _filtered(state.trips);
    final totalMiles = filtered.fold(0.0, (s, t) => s + t.miles);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History'),
        centerTitle: true,
        actions: [
          _YearPicker(
            year: _year,
            onChanged: (y) => setState(() => _year = y),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: cs.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', ...Trip.purposes].map((p) {
                      final selected = _filter == p;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(p),
                          selected: selected,
                          onSelected: (_) => setState(() => _filter = p),
                          selectedColor: cs.primaryContainer,
                          checkmarkColor: cs.primary,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (filtered.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: Text(
                      '${filtered.length} trip${filtered.length == 1 ? '' : 's'} · ${totalMiles.toStringAsFixed(1)} miles',
                      style: TextStyle(
                          color: cs.onSurfaceVariant, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.directions_car_outlined,
                            size: 64,
                            color: cs.onSurfaceVariant.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Text('No trips for $_year',
                            style: TextStyle(
                                color: cs.onSurfaceVariant, fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final trip = filtered[i];
                      return TripCard(
                        trip: trip,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddTripScreen(existing: trip),
                          ),
                        ),
                        onDelete: () =>
                            context.read<MileageState>().deleteTrip(trip.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _YearPicker extends StatelessWidget {
  final int year;
  final ValueChanged<int> onChanged;

  const _YearPicker({required this.year, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().year;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Previous year',
          onPressed: year > 2000 ? () => onChanged(year - 1) : null,
        ),
        Text('$year',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Next year',
          onPressed: year < now ? () => onChanged(year + 1) : null,
        ),
      ],
    );
  }
}
