class Booking {
  final String id;
  final String equipmentId;
  final String userId;
  final String userName;
  final DateTime startDate;
  final DateTime endDate;
  final String notes;

  Booking({
    required this.id,
    required this.equipmentId,
    required this.userId,
    required this.userName,
    required DateTime startDate,
    required DateTime endDate,
    this.notes = '',
  })  : startDate = _date(startDate),
        endDate = _date(endDate);

  static DateTime _date(DateTime d) => DateTime(d.year, d.month, d.day);

  bool includesDay(DateTime day) {
    final d = _date(day);
    return !d.isBefore(startDate) && !d.isAfter(endDate);
  }

  bool overlapsWith(DateTime start, DateTime end) {
    final s = _date(start);
    final e = _date(end);
    return !endDate.isBefore(s) && !startDate.isAfter(e);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'equipmentId': equipmentId,
        'userId': userId,
        'userName': userName,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'notes': notes,
      };

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as String,
        equipmentId: json['equipmentId'] as String,
        userId: json['userId'] as String,
        userName: json['userName'] as String,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        notes: (json['notes'] as String?) ?? '',
      );
}
