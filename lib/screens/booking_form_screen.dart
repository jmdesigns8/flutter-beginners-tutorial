import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/booking.dart';
import '../state/app_state.dart';

class BookingFormScreen extends StatefulWidget {
  final Booking? existingBooking;
  final DateTime? initialDate;

  const BookingFormScreen({
    super.key,
    this.existingBooking,
    this.initialDate,
  });

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  String? _equipmentId;
  late DateTime _startDate;
  late DateTime _endDate;
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final base = widget.initialDate ?? DateTime.now();
    final today = DateTime(base.year, base.month, base.day);
    if (widget.existingBooking case final b?) {
      _equipmentId = b.equipmentId;
      _startDate = b.startDate;
      _endDate = b.endDate;
      _notesCtrl.text = b.notes;
    } else {
      _startDate = today;
      _endDate = today;
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isEditing = widget.existingBooking != null;
    final fmt = DateFormat('EEE, MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Booking' : 'New Booking'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Equipment selector ──────────────────────────────────────────
          _SectionCard(
            title: 'Equipment',
            child: Column(
              children: state.equipment.map((eq) {
                return RadioListTile<String>(
                  value: eq.id,
                  groupValue: _equipmentId,
                  onChanged: (v) => setState(() => _equipmentId = v),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: eq.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(eq.name),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // ── Date range ─────────────────────────────────────────────────
          _SectionCard(
            title: 'Dates',
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event),
                  title: const Text('Start Date'),
                  subtitle: Text(fmt.format(_startDate)),
                  onTap: () => _pickDate(isStart: true),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event),
                  title: const Text('End Date'),
                  subtitle: Text(fmt.format(_endDate)),
                  onTap: () => _pickDate(isStart: false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Notes ──────────────────────────────────────────────────────
          _SectionCard(
            title: 'Notes (optional)',
            child: TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                hintText: 'Jobsite, purpose, special instructions…',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 3,
            ),
          ),
          const SizedBox(height: 24),

          FilledButton(
            onPressed: _saving ? null : () => _save(context, state),
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52)),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
                    isEditing ? 'Update Booking' : 'Create Booking',
                    style: const TextStyle(fontSize: 16),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = picked;
        if (_startDate.isAfter(_endDate)) _startDate = _endDate;
      }
    });
  }

  Future<void> _save(BuildContext context, AppState state) async {
    if (_equipmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a piece of equipment.')),
      );
      return;
    }

    setState(() => _saving = true);

    final String? error;
    if (widget.existingBooking != null) {
      error = await state.updateBooking(
        bookingId: widget.existingBooking!.id,
        equipmentId: _equipmentId!,
        startDate: _startDate,
        endDate: _endDate,
        notes: _notesCtrl.text.trim(),
      );
    } else {
      error = await state.addBooking(
        equipmentId: _equipmentId!,
        startDate: _startDate,
        endDate: _endDate,
        notes: _notesCtrl.text.trim(),
      );
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (error != null) {
      _showConflict(context, error);
    } else {
      Navigator.pop(context);
    }
  }

  void _showConflict(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_rounded,
            color: Colors.orange, size: 40),
        title: const Text('Booking Conflict'),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
