import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/trip.dart';
import '../state/mileage_state.dart';
import '../widgets/trip_card.dart';
import 'add_trip_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MileageState>();
    final year = DateTime.now().year;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Strive'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Trip History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: state.load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _YearSummary(state: state, year: year),
                  const SizedBox(height: 8),
                  _PurposeGrid(state: state, year: year),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text('Recent Trips',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      if (state.trips.isNotEmpty)
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const HistoryScreen()),
                          ),
                          child: const Text('See all'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (state.trips.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(Icons.directions_car_outlined,
                                size: 72,
                                color: cs.onSurfaceVariant.withOpacity(0.35)),
                            const SizedBox(height: 16),
                            Text('No trips yet',
                                style: TextStyle(
                                    fontSize: 18, color: cs.onSurfaceVariant)),
                            const SizedBox(height: 8),
                            Text('Tap + to log your first trip',
                                style: TextStyle(
                                    color:
                                        cs.onSurfaceVariant.withOpacity(0.7))),
                          ],
                        ),
                      ),
                    )
                  else
                    ...state.trips.take(5).map((trip) => TripCard(
                          trip: trip,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddTripScreen(existing: trip),
                            ),
                          ),
                          onDelete: () =>
                              context.read<MileageState>().deleteTrip(trip.id),
                        )),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTripScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Trip'),
      ),
    );
  }
}

class _YearSummary extends StatelessWidget {
  final MileageState state;
  final int year;

  const _YearSummary({required this.state, required this.year});

  @override
  Widget build(BuildContext context) {
    final total = state.totalMilesForYear(year);
    final count = state.tripsForYear(year).length;
    final cs = Theme.of(context).colorScheme;

    return Card(
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$year Total',
                      style: TextStyle(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    '${total.toStringAsFixed(1)} miles',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: cs.onPrimaryContainer),
                  ),
                  Text(
                    '$count trip${count == 1 ? '' : 's'}',
                    style: TextStyle(
                        color: cs.onPrimaryContainer.withOpacity(0.7),
                        fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.directions_car,
                size: 56, color: cs.primary.withOpacity(0.35)),
          ],
        ),
      ),
    );
  }
}

class _PurposeGrid extends StatelessWidget {
  final MileageState state;
  final int year;

  const _PurposeGrid({required this.state, required this.year});

  @override
  Widget build(BuildContext context) {
    final byPurpose = state.milesByPurposeForYear(year);
    final entries =
        Trip.purposes.where((p) => (byPurpose[p] ?? 0) > 0).toList();

    if (entries.isEmpty) return const SizedBox.shrink();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.4,
      children: entries.map((p) {
        final miles = byPurpose[p] ?? 0;
        return _PurposeCard(purpose: p, miles: miles);
      }).toList(),
    );
  }
}

class _PurposeCard extends StatelessWidget {
  final String purpose;
  final double miles;

  const _PurposeCard({required this.purpose, required this.miles});

  Color _color(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return switch (purpose) {
      'Business' => cs.primary,
      'Medical' => Colors.red.shade600,
      'Charity' => Colors.green.shade700,
      _ => cs.secondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(purpose,
                style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(
              '${miles.toStringAsFixed(1)} mi',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
