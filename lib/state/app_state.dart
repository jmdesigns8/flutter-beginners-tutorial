import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/equipment.dart';
import '../models/booking.dart';
import '../models/app_user.dart';

const _uuid = Uuid();

class AppState extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

  List<Equipment> _equipment = [];
  List<Booking> _bookings = [];
  List<AppUser> _users = [AppUser.user1, AppUser.user2];
  AppUser? _currentUser;
  bool _isLoading = true;

  StreamSubscription<QuerySnapshot>? _equipSub;
  StreamSubscription<QuerySnapshot>? _bookSub;
  StreamSubscription<QuerySnapshot>? _usersSub;

  bool _equipLoaded = false;
  bool _bookLoaded = false;
  bool _usersLoaded = false;

  bool get isLoading => _isLoading;
  AppUser? get currentUser => _currentUser;
  List<AppUser> get users => List.unmodifiable(_users);
  List<Equipment> get equipment => _equipment.where((e) => e.isActive).toList();
  List<Equipment> get allEquipment => List.unmodifiable(_equipment);
  List<Booking> get bookings => List.unmodifiable(_bookings);

  AppState() {
    _init();
  }

  @override
  void dispose() {
    _equipSub?.cancel();
    _bookSub?.cancel();
    _usersSub?.cancel();
    super.dispose();
  }

  // ── Startup ───────────────────────────────────────────────────────────────

  Future<void> _init() async {
    await _seedIfNeeded();
    _listenToStreams();
  }

  /// On first launch, seed Firestore with the two users and default equipment.
  Future<void> _seedIfNeeded() async {
    final usersSnap = await _db.collection('users').get();
    if (usersSnap.docs.isEmpty) {
      final batch = _db.batch();
      for (final u in [AppUser.user1, AppUser.user2]) {
        batch.set(_db.collection('users').doc(u.id), u.toJson());
      }
      await batch.commit();
    }

    final equipSnap = await _db.collection('equipment').get();
    if (equipSnap.docs.isEmpty) {
      final batch = _db.batch();
      for (final e in Equipment.defaults) {
        batch.set(_db.collection('equipment').doc(e.id), e.toJson());
      }
      await batch.commit();
    }
  }

  void _listenToStreams() {
    _usersSub = _db.collection('users').snapshots().listen((snap) {
      _users = snap.docs
          .map((d) => AppUser.fromJson(d.data()))
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));

      // Keep currentUser name in sync if it was renamed on the other device.
      if (_currentUser != null) {
        final updated = _userById(_currentUser!.id);
        if (updated != null) _currentUser = updated;
      }

      _usersLoaded = true;
      _checkLoaded();
    });

    _equipSub = _db.collection('equipment').snapshots().listen((snap) {
      _equipment =
          snap.docs.map((d) => Equipment.fromJson(d.data())).toList();
      _equipLoaded = true;
      _checkLoaded();
    });

    _bookSub = _db.collection('bookings').snapshots().listen((snap) {
      _bookings = snap.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data());
        _stampToIso(data);
        return Booking.fromJson(data);
      }).toList();
      _bookLoaded = true;
      _checkLoaded();
    });
  }

  void _checkLoaded() {
    if (_equipLoaded && _bookLoaded && _usersLoaded) {
      _isLoading = false;
    }
    notifyListeners();
  }

  /// Converts Firestore Timestamps → ISO strings so Booking.fromJson works.
  void _stampToIso(Map<String, dynamic> data) {
    for (final key in ['startDate', 'endDate']) {
      if (data[key] is Timestamp) {
        data[key] = (data[key] as Timestamp).toDate().toIso8601String();
      }
    }
  }

  /// Converts ISO string dates → Timestamps for Firestore storage.
  Map<String, dynamic> _toFirestore(Booking b) {
    final data = b.toJson();
    data['startDate'] = Timestamp.fromDate(b.startDate);
    data['endDate'] = Timestamp.fromDate(b.endDate);
    return data;
  }

  // ── Users ─────────────────────────────────────────────────────────────────

  AppUser? _userById(String id) {
    for (final u in _users) {
      if (u.id == id) return u;
    }
    return null;
  }

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

    await _db.collection('users').doc(userId).update({'name': trimmed});

    // Update the userName field on all this user's existing bookings.
    final snap = await _db
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .get();
    if (snap.docs.isNotEmpty) {
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'userName': trimmed});
      }
      await batch.commit();
    }

    // Optimistic local update (stream will confirm shortly).
    if (_currentUser?.id == userId) {
      _currentUser = _currentUser!.copyWith(name: trimmed);
      notifyListeners();
    }
  }

  // ── Equipment ─────────────────────────────────────────────────────────────

  Equipment? equipmentById(String id) {
    for (final e in _equipment) {
      if (e.id == id) return e;
    }
    return null;
  }

  Future<void> addEquipment(String name, int colorValue) async {
    final id = _uuid.v4();
    await _db.collection('equipment').doc(id).set(
          Equipment(id: id, name: name.trim(), colorValue: colorValue).toJson(),
        );
  }

  Future<void> updateEquipment(String id,
      {String? name, int? colorValue}) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name.trim();
    if (colorValue != null) updates['colorValue'] = colorValue;
    await _db.collection('equipment').doc(id).update(updates);
  }

  Future<void> toggleEquipmentActive(String id) async {
    final eq = equipmentById(id);
    if (eq == null) return;
    await _db
        .collection('equipment')
        .doc(id)
        .update({'isActive': !eq.isActive});
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

  String _fmt(DateTime d) => '${d.month}/${d.day}/${d.year}';

  /// Returns null on success, or a user-facing conflict message.
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
    final id = _uuid.v4();
    await _db.collection('bookings').doc(id).set(_toFirestore(Booking(
          id: id,
          equipmentId: equipmentId,
          userId: _currentUser!.id,
          userName: _currentUser!.name,
          startDate: startDate,
          endDate: endDate,
          notes: notes,
        )));
    return null;
  }

  /// Returns null on success, or a user-facing conflict message.
  Future<String?> updateBooking({
    required String bookingId,
    required String equipmentId,
    required DateTime startDate,
    required DateTime endDate,
    String notes = '',
  }) async {
    Booking? existing;
    for (final b in _bookings) {
      if (b.id == bookingId) {
        existing = b;
        break;
      }
    }
    if (existing == null) return 'Booking not found.';

    final c = _conflict(equipmentId, startDate, endDate, excludeId: bookingId);
    if (c != null) {
      final e = equipmentById(equipmentId);
      return '${e?.name ?? 'Equipment'} is already booked by ${c.userName} '
          '(${_fmt(c.startDate)} – ${_fmt(c.endDate)}).';
    }
    await _db.collection('bookings').doc(bookingId).set(_toFirestore(Booking(
          id: bookingId,
          equipmentId: equipmentId,
          userId: existing.userId,
          userName: existing.userName,
          startDate: startDate,
          endDate: endDate,
          notes: notes,
        )));
    return null;
  }

  Future<void> deleteBooking(String id) async {
    await _db.collection('bookings').doc(id).delete();
  }
}
