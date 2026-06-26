import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/trip.dart';
import '../state/mileage_state.dart';

class AddTripScreen extends StatefulWidget {
  final Trip? existing;

  const AddTripScreen({super.key, this.existing});

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _date;
  late TextEditingController _fromCtrl;
  late TextEditingController _toCtrl;
  late TextEditingController _milesCtrl;
  late TextEditingController _notesCtrl;
  late String _purpose;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _date = t?.date ?? DateTime.now();
    _fromCtrl = TextEditingController(text: t?.fromLocation ?? '');
    _toCtrl = TextEditingController(text: t?.toLocation ?? '');
    _milesCtrl = TextEditingController(
        text: t == null
            ? ''
            : (t.miles % 1 == 0
                ? t.miles.toInt().toString()
                : t.miles.toString()));
    _notesCtrl = TextEditingController(text: t?.notes ?? '');
    _purpose = t?.purpose ?? 'Business';
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _milesCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final state = context.read<MileageState>();
    final isEdit = widget.existing != null;

    final trip = Trip(
      id: widget.existing?.id ?? const Uuid().v4(),
      date: _date,
      fromLocation: _fromCtrl.text.trim(),
      toLocation: _toCtrl.text.trim(),
      miles: double.parse(_milesCtrl.text.trim()),
      purpose: _purpose,
      notes: _notesCtrl.text.trim(),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    if (isEdit) {
      await state.updateTrip(trip);
    } else {
      await state.addTrip(trip);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Trip' : 'Add Trip'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SectionLabel('Date'),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Theme.of(context).colorScheme.outline, width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('EEEE, MMMM d, y').format(_date),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_drop_down,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _SectionLabel('Miles Driven'),
            TextFormField(
              controller: _milesCtrl,
              decoration: const InputDecoration(
                hintText: '0.0',
                prefixIcon: Icon(Icons.speed),
                suffixText: 'miles',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter miles';
                final n = double.tryParse(v.trim());
                if (n == null || n <= 0) return 'Enter a valid distance';
                return null;
              },
              autofocus: !isEdit,
            ),
            const SizedBox(height: 20),
            _SectionLabel('Purpose'),
            DropdownButtonFormField<String>(
              value: _purpose,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.label_outline),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              items: Trip.purposes
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => _purpose = v!),
            ),
            const SizedBox(height: 20),
            _SectionLabel('Locations (optional)'),
            TextFormField(
              controller: _fromCtrl,
              decoration: const InputDecoration(
                labelText: 'From',
                hintText: 'Starting location',
                prefixIcon: Icon(Icons.trip_origin),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _toCtrl,
              decoration: const InputDecoration(
                labelText: 'To',
                hintText: 'Destination',
                prefixIcon: Icon(Icons.place),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
            ),
            const SizedBox(height: 20),
            _SectionLabel('Notes (optional)'),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                hintText: 'Client name, purpose details...',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(isEdit ? 'Save Changes' : 'Add Trip',
                      style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600)),
      );
}
