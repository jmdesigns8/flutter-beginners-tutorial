import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/booking.dart';
import '../state/app_state.dart';
import '../widgets/booking_card.dart';
import 'booking_form_screen.dart';
import 'equipment_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final bookingsForDay = state.bookingsForDay(_selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment Checkout'),
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.construction_rounded),
            tooltip: 'Manage Equipment',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EquipmentScreen()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _userMenu(context, state),
              child: CircleAvatar(
                backgroundColor: Colors.white24,
                child: Text(
                  state.currentUser?.initials ?? '?',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Calendar ──────────────────────────────────────────────────
          TableCalendar<Booking>(
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            focusedDay: _focusedDay,
            selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
            onDaySelected: (selected, focused) => setState(() {
              _selectedDay = selected;
              _focusedDay = focused;
            }),
            onPageChanged: (focused) =>
                setState(() => _focusedDay = focused),
            eventLoader: state.bookingsForDay,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withAlpha(100),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, bookings) {
                if (bookings.isEmpty) return null;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: bookings.take(4).map((b) {
                      final eq = state.equipmentById(b.equipmentId);
                      return Container(
                        width: 6,
                        height: 6,
                        margin:
                            const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: eq?.color ?? Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // ── Selected day header ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                Text(
                  DateFormat('EEEE, MMMM d').format(_selectedDay),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Spacer(),
                Text(
                  bookingsForDay.isEmpty
                      ? 'No bookings'
                      : '${bookingsForDay.length} booking${bookingsForDay.length == 1 ? '' : 's'}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),

          // ── Booking list ───────────────────────────────────────────────
          Expanded(
            child: bookingsForDay.isEmpty
                ? _EmptyDay()
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: bookingsForDay.length,
                    itemBuilder: (ctx, i) {
                      final b = bookingsForDay[i];
                      return BookingCard(
                        booking: b,
                        equipment: state.equipmentById(b.equipmentId),
                        isOwner: b.userId == state.currentUser?.id,
                        onEdit: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                BookingFormScreen(existingBooking: b),
                          ),
                        ),
                        onDelete: () => _confirmDelete(context, state, b),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                BookingFormScreen(initialDate: _selectedDay),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Book Equipment'),
      ),
    );
  }

  void _userMenu(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Text(state.currentUser?.initials ?? '?',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    state.currentUser?.name ?? '',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(ctx);
                _renameDialog(context, state);
              },
            ),
            ListTile(
              leading: const Icon(Icons.switch_account_outlined),
              title: const Text('Switch User'),
              onTap: () {
                Navigator.pop(ctx);
                state.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _renameDialog(BuildContext context, AppState state) {
    final ctrl = TextEditingController(text: state.currentUser?.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
              labelText: 'Your name', border: OutlineInputBorder()),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          onSubmitted: (_) => _submitRename(ctx, state, ctrl),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => _submitRename(ctx, state, ctrl),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _submitRename(
      BuildContext ctx, AppState state, TextEditingController ctrl) {
    if (ctrl.text.trim().isEmpty || state.currentUser == null) return;
    state.renameUser(state.currentUser!.id, ctrl.text);
    Navigator.pop(ctx);
  }

  void _confirmDelete(BuildContext context, AppState state, Booking b) {
    final eq = state.equipmentById(b.equipmentId);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Booking?'),
        content: Text(
            'Remove the checkout for ${eq?.name ?? 'this equipment'}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              state.deleteBooking(b.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_available_rounded, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text('All equipment available',
              style: TextStyle(color: Colors.grey[400], fontSize: 15)),
          const SizedBox(height: 4),
          Text('Tap "Book Equipment" to add a checkout',
              style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ],
      ),
    );
  }
}
