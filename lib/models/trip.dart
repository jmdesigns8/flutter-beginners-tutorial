class Trip {
  final String id;
  final DateTime date;
  final String fromLocation;
  final String toLocation;
  final double miles;
  final String purpose;
  final String notes;
  final DateTime createdAt;

  const Trip({
    required this.id,
    required this.date,
    required this.fromLocation,
    required this.toLocation,
    required this.miles,
    required this.purpose,
    required this.notes,
    required this.createdAt,
  });

  static const purposes = ['Business', 'Personal', 'Medical', 'Charity'];

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.millisecondsSinceEpoch,
        'from_location': fromLocation,
        'to_location': toLocation,
        'miles': miles,
        'purpose': purpose,
        'notes': notes,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Trip.fromMap(Map<String, dynamic> map) => Trip(
        id: map['id'] as String,
        date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
        fromLocation: map['from_location'] as String? ?? '',
        toLocation: map['to_location'] as String? ?? '',
        miles: (map['miles'] as num).toDouble(),
        purpose: map['purpose'] as String? ?? 'Personal',
        notes: map['notes'] as String? ?? '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );

  Trip copyWith({
    String? id,
    DateTime? date,
    String? fromLocation,
    String? toLocation,
    double? miles,
    String? purpose,
    String? notes,
    DateTime? createdAt,
  }) =>
      Trip(
        id: id ?? this.id,
        date: date ?? this.date,
        fromLocation: fromLocation ?? this.fromLocation,
        toLocation: toLocation ?? this.toLocation,
        miles: miles ?? this.miles,
        purpose: purpose ?? this.purpose,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
      );
}
