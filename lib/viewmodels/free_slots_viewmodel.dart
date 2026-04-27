import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_helper.dart';

/// ViewModel for [FreeSlotsScreen].
/// Fetches ALL rooms from Firebase (once) and computes FREE rooms by
/// subtracting the ones occupied in the selected day + period.
class FreeSlotsViewModel extends ChangeNotifier {
  int selectedDay = 0;
  int selectedSlot = 0;
  bool _loading = false;
  List<String> _availableRooms = [];

  /// Cached master set of every room name found anywhere in Firebase.
  Set<String> _allRooms = {};
  bool _allRoomsLoaded = false;

  final DatabaseHelper _dbHelper = DatabaseHelper();

  final List<String> days = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday"
  ];
  final List<String> dayShortNames = ["Mon", "Tue", "Wed", "Thu", "Fri"];

  final List<Map<String, String>> slots = [
    {"label": "S1", "period": "1", "time": "8:30 - 9:55"},
    {"label": "S2", "period": "2", "time": "9:55 - 11:20"},
    {"label": "S3", "period": "3", "time": "11:20 - 12:45"},
    {"label": "S4", "period": "4", "time": "1:40 - 3:05"},
    {"label": "S5", "period": "5", "time": "3:05 - 4:30"},
  ];

  bool get loading => _loading;
  List<String> get availableRooms => _availableRooms;

  FreeSlotsViewModel() {
    fetchAvailableRooms();
  }

  void setDay(int index) {
    selectedDay = index;
    notifyListeners();
    fetchAvailableRooms();
  }

  void setSlot(int index) {
    selectedSlot = index;
    notifyListeners();
    fetchAvailableRooms();
  }

  /// Loads every unique room name from ALL day documents in Firebase.
  /// Only runs once; subsequent calls return immediately.
  Future<void> _ensureAllRoomsLoaded() async {
    if (_allRoomsLoaded) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('timetableFreeSlots')
        .get();

    final Set<String> rooms = {};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data.containsKey('slots')) {
        final slotsList = List<Map<String, dynamic>>.from(data['slots']);
        for (final slot in slotsList) {
          final room = slot['room']?.toString().trim();
          if (room != null && room.isNotEmpty) {
            rooms.add(room);
          }
        }
      }
    }

    _allRooms = rooms;
    _allRoomsLoaded = true;
  }

  /// Fetches occupied rooms for the selected day/period from Firebase,
  /// then computes free rooms = allRooms - occupiedRooms.
  Future<void> fetchAvailableRooms() async {
    _loading = true;
    notifyListeners();

    try {
      // Build master list from Firebase if not done yet
      await _ensureAllRoomsLoaded();

      final selectedDayName = days[selectedDay];
      final selectedPeriod = slots[selectedSlot]["period"];

      final doc = await FirebaseFirestore.instance
          .collection('timetableFreeSlots')
          .doc(selectedDayName)
          .get();

      final Set<String> occupiedRooms = {};

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('slots')) {
          final slotsList = List<Map<String, dynamic>>.from(data['slots']);
          final periodSlots = slotsList
              .where((slot) => slot['period']?.toString() == selectedPeriod);
          for (final slot in periodSlots) {
            final room = slot['room']?.toString().trim();
            if (room != null && room.isNotEmpty) {
              occupiedRooms.add(room);
            }
          }
        }
      }

      // Free rooms = every known room that is NOT occupied right now
      final sorted = _allRooms
          .where((r) => !occupiedRooms.contains(r))
          .toList()
        ..sort(); // alphabetical so list is consistent
      _availableRooms = sorted;
    } catch (e) {
      debugPrint("Error fetching free slots: $e");
      _availableRooms = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
