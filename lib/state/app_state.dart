import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/equipment.dart';
import '../models/booking.dart';
import '../models/app_user.dart';

const _uuid = Uuid();

class AppState extends ChangeNotifier {
  List<Equipment> _equipment = [];
  List<Booking> _bookings = [];
  List<AppUser> _users = [AppUser.user1, AppUser.user2];
  AppUser? _currentUser;
  bool _isLoading = true;

  bool get isLoading => _isLoading;
  AppUser? get currentUser => _currentUser;
  List<AppUser> get users => List.unmodifiable(_users);
  List<Equipment> get equipment => _equipment.where((e) => e.isActive).toList();
  List<Equipment> get allEquipment => List.unmodifiable(_equipment);
  List<Booking> get bookings => List.unmodifiable(_bookings);

  AppState() {
    _load();
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final usersStr = prefs.getString('users');
    if (usersStr != null) {
      final list = jsonDecode(usersStr) as List;
      _users = list.map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
    }

    final equipStr = prefs.getString('equipment');
    if (equipStr != null) {
      final list = jsonDecode(equipStr) as List;
      _equipment = list.map((e) => Equipment.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      _equipment = List.from(Equipment.defaults);
      await _save('equipment', _equipment.map((e) => e.toJson()).toList());
    }

    final bookStr = prefs.getString('bookings');
    if (bookStr != null) {
      final list = jsonDecode(bookStr) as List;
      _bookings = list.map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _save(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(value));
  }

  Future<void> _saveUsers() =>
      _save('users', _users.map((u) => u.toJson()).toList());
  Future<void> _saveEquipment() =>
      _save('equipment', _equipment.map((e) => e.toJson()).toList());
  Future<void> _saveBookings() =>
      _save('bookings', _bookings.map((b) => b.toJson()).toList());

  // ── Users ─────────────────────────────────────────────────────────────────

  void setCurrentUser(AppUser user) {
    _currentUser = user;
    notifyListeners();
  }

  void signOut() {
    _currentUser = null;
    notifyListeners();
  }

  Future<void> renameUser(String userId, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    _users = [
      for (final u in _users) u.id == userId ? u.copyWith(name: trimmed) : u
    ];
    if (_currentUser?.id == userId) {
      _currentUser = _currentUser!.copyWith(name: trimmed);
    }
    // Keep booking userName in sync
    _bookings = [
      for (final b in _bookings)
        b.userId == userId
            ? Booking(
                id: b.id,
                equipmentId: b.equipmentId,
                userId: b.userId,
                userName: trimmed,
                startDate: b.startDate,
                endDate: b.endDate,
                notes: b.notes,
              )
            : b
    ];
    await Future.wait([_saveUsers(), _saveBookings()]);
    notifyListeners();
  }

  // ── Equipment ─────────────────────────────────────────────────────────────

  Equipment? equipmentById(String id) {
    for (final e in _equipment) {
      if (e.id == id) return e;
    }
    return null;
  }

  Future<void> addEquipment(String name, int colorValue) async {
    _equipment.add(
      Equipment(id: _uuid.v4(), name: name.trim(), colorValue: colorValue),
    );
    await _saveEquipment();
    notifyListeners();
  }

  Future<void> updateEquipment(String id, {String? name, int? colorValue}) async {
    _equipment = [
      for (final e in _equipment)
        e.id == id ? e.copyWith(name: name, colorValue: colorValue) : e
    ];
    await _saveEquipment();
    notifyListeners();
  }

  Future<void> toggleEquipmentActive(String id) async {
    _equipment = [
      for (final e in _equipment)
        e.id == id ? e.copyWith(isActive: !e.isActive) : e
    ];
    await _saveEquipment();
    notifyListeners();
  }

  // ── Bookings ──────────────────────────────────────────────────────────────

  List<Booking> bookingsForDay(DateTime day) =>
      _bookings.where((b) => b.includesDay(day)).toList();

  Booking? _conflict(String equipmentId, DateTime start, DateTime end,
      {String? excludeId}) {
    for (final b in _bookings) {
      if (b.id == excludeId) continue;
      if (b.equipmentId == equipmentId && b.overlapsWith(start, end)) return b;
    }
    return null;
  }

  String _fmt(DateTime d) =>
      '${d.month}/${d.day}/${d.year}';

  /// Returns null on success, or a user-facing error string on conflict.
  Future<String?> addBooking({
    required String equipmentId,
    required DateTime startDate,
    required DateTime endDate,
    String notes = '',
  }) async {
    if (_currentUser == null) return 'No user selected.';
    final c = _conflict(equipmentId, startDate, endDate);
    if (c != null) {
      final e = equipmentById(equipmentId);
      return '${e?.name ?? 'Equipment'} is already booked by ${c.userName} '
          '(${_fmt(c.startDate)} – ${_fmt(c.endDate)}).';
    }
    _bookings.add(Booking(
      id: _uuid.v4(),
      equipmentId: equipmentId,
      userId: _currentUser!.id,
      userName: _currentUser!.name,
      startDate: startDate,
      endDate: endDate,
      notes: notes,
    ));
    await _saveBookings();
    notifyListeners();
    return null;
  }

  /// Returns null on success, or a user-facing error string on conflict.
  Future<String?> updateBooking({
    required String bookingId,
    required String equipmentId,
    required DateTime startDate,
    required DateTime endDate,
    String notes = '',
  }) async {
    final c = _conflict(equipmentId, startDate, endDate, excludeId: bookingId);
    if (c != null) {
      final e = equipmentById(equipmentId);
      return '${e?.name ?? 'Equipment'} is already booked by ${c.userName} '
          '(${_fmt(c.startDate)} – ${_fmt(c.endDate)}).';
    }
    _bookings = [
      for (final b in _bookings)
        b.id == bookingId
            ? Booking(
                id: b.id,
                equipmentId: equipmentId,
                userId: b.userId,
                userName: b.userName,
                startDate: startDate,
                endDate: endDate,
                notes: notes,
              )
            : b
    ];
    await _saveBookings();
    notifyListeners();
    return null;
  }

  Future<void> deleteBooking(String id) async {
    _bookings.removeWhere((b) => b.id == id);
    await _saveBookings();
    notifyListeners();
  }
}
