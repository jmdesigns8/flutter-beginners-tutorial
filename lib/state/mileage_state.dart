import 'package:flutter/foundation.dart';
import '../database/trip_database.dart';
import '../models/trip.dart';

class MileageState extends ChangeNotifier {
  List<Trip> _trips = [];
  bool isLoading = true;

  List<Trip> get trips => _trips;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    _trips = await TripDatabase.instance.getAllTrips();
    isLoading = false;
    notifyListeners();
  }

  Future<void> addTrip(Trip trip) async {
    await TripDatabase.instance.insertTrip(trip);
    _trips = [trip, ..._trips];
    _trips.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<void> updateTrip(Trip trip) async {
    await TripDatabase.instance.updateTrip(trip);
    final index = _trips.indexWhere((t) => t.id == trip.id);
    if (index != -1) _trips[index] = trip;
    _trips.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<void> deleteTrip(String id) async {
    await TripDatabase.instance.deleteTrip(id);
    _trips.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  List<Trip> tripsForYear(int year) =>
      _trips.where((t) => t.date.year == year).toList();

  double totalMilesForYear(int year) =>
      tripsForYear(year).fold(0.0, (sum, t) => sum + t.miles);

  Map<String, double> milesByPurposeForYear(int year) {
    final map = <String, double>{};
    for (final purpose in Trip.purposes) {
      map[purpose] = tripsForYear(year)
          .where((t) => t.purpose == purpose)
          .fold(0.0, (sum, t) => sum + t.miles);
    }
    return map;
  }

  double totalMiles() => _trips.fold(0.0, (sum, t) => sum + t.miles);
}
