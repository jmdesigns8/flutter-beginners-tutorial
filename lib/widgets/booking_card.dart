import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';
import '../models/equipment.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final Equipment? equipment;
  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const BookingCard({
    super.key,
    required this.booking,
    required this.equipment,
    required this.isOwner,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = equipment?.color ?? Colors.grey;
    final fmt = DateFormat('MMM d');
    final sameDay = booking.startDate == booking.endDate;
    final dateStr = sameDay
        ? fmt.format(booking.startDate)
        : '${fmt.format(booking.startDate)} – ${fmt.format(booking.endDate)}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      equipment?.name ?? 'Unknown Equipment',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(booking.userName,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13)),
                        const SizedBox(width: 12),
                        Icon(Icons.calendar_today,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(dateStr,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                    if (booking.notes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        booking.notes,
                        style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                            fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (isOwner)
              PopupMenuButton<_Action>(
                onSelected: (action) {
                  if (action == _Action.edit) onEdit?.call();
                  if (action == _Action.delete) onDelete?.call();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: _Action.edit,
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Edit'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: _Action.delete,
                    child: ListTile(
                      leading: Icon(Icons.delete_outline, color: Colors.red),
                      title: Text('Delete',
                          style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

enum _Action { edit, delete }
