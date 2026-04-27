import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/database_helper.dart';

/// ViewModel for [TeacherDetailsScreen].
/// Holds selected day, class list, loading state, and all
/// time-calculation helpers. Logic identical to original _TeacherDetailsScreenState.
class TeacherDetailsViewModel extends ChangeNotifier {
  final String teacherId;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  String _selectedDay = "Monday";
  List<Map<String, dynamic>> _classes = [];
  bool _loading = false;
  Timer? _timer;

  final List<String> days = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday"
  ];

  // Period → 24-hour time range
  final Map<String, String> periodToTime = {
    "1": "08:30 - 09:55",
    "2": "09:55 - 11:20",
    "3": "11:20 - 12:45",
    "4": "13:40 - 15:05",
    "5": "15:05 - 16:30",
  };

  String get selectedDay => _selectedDay;
  List<Map<String, dynamic>> get classes => _classes;
  bool get loading => _loading;

  TeacherDetailsViewModel({required this.teacherId}) {
    _initialize();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initialize() {
    final today = DateFormat('EEEE').format(DateTime.now());
    _selectedDay = days.contains(today) ? today : "Monday";

    _loadFromCache();
    _fetchDayDataInBackground();

    // Refresh every second when viewing today's schedule (for live countdown)
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_selectedDay == DateFormat('EEEE').format(DateTime.now())) {
        notifyListeners();
      }
    });
  }

  void setDay(String day) {
    if (_selectedDay != day) {
      _selectedDay = day;
      notifyListeners();
      _loadFromCache();
      _fetchDayDataInBackground();
    }
  }

  Future<void> _loadFromCache() async {
    try {
      final cached = await _dbHelper.getTimetable(teacherId, 'teacher');
      if (cached != null && cached.containsKey(_selectedDay)) {
        final dayClasses = cached[_selectedDay];
        if (dayClasses != null) {
          _classes = List<Map<String, dynamic>>.from(dayClasses);
          _sortClasses();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Error loading from cache: $e");
    }
  }

  Future<void> _fetchDayDataInBackground() async {
    try {
      final isFresh =
          await _dbHelper.isCacheFresh(teacherId, 'teacher', minutesThreshold: 5);
      if (isFresh) {
        debugPrint("Using fresh cache, skipping Firebase fetch");
        return;
      }

      final hasCache = await _dbHelper.hasCache(teacherId, 'teacher');
      if (!hasCache) {
        _loading = true;
        notifyListeners();
      }

      final doc = await FirebaseFirestore.instance
          .collection('timetableTeachers')
          .doc(teacherId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          await _dbHelper.insertOrUpdateTimetable(teacherId, 'teacher', data);
          if (data.containsKey(_selectedDay)) {
            final dayClasses = data[_selectedDay];
            if (dayClasses != null) {
              _classes = List<Map<String, dynamic>>.from(dayClasses);
              _sortClasses();
            }
          } else {
            _classes = [];
          }
        }
      } else {
        _classes = [];
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _sortClasses() {
    _classes.sort((a, b) {
      final periodA = a['period']?.toString() ?? '';
      final periodB = b['period']?.toString() ?? '';
      if (periodA.isEmpty || periodB.isEmpty) return 0;
      try {
        return int.parse(periodA).compareTo(int.parse(periodB));
      } catch (_) {
        return 0;
      }
    });
  }

  // ── Time helpers (same logic as original) ────────────────────────────────

  String getTimeFromPeriod(String period) => periodToTime[period] ?? '';

  String getDisplayTimeFromPeriod(String period) {
    final time24 = periodToTime[period] ?? '';
    if (time24.isEmpty) return '';
    final parts = time24.split(' - ');
    if (parts.length == 2) {
      return '${_formatTimeTo12Hour(parts[0].trim())} - ${_formatTimeTo12Hour(parts[1].trim())}';
    }
    return time24;
  }

  String _formatTimeTo12Hour(String time24) {
    try {
      final time = DateFormat('HH:mm').parse(time24);
      return DateFormat('h:mm a').format(time);
    } catch (_) {
      return time24;
    }
  }

  String calculateDuration(String timeRange) {
    try {
      if (!timeRange.contains('-')) return '';
      final parts = timeRange.split('-');
      final now = DateTime.now();
      final start = _parseTimeWithContext(parts[0].trim(), now);
      final end = _parseTimeWithContext(parts[1].trim(), now);
      return _formatDuration(end.difference(start));
    } catch (_) {
      return '';
    }
  }

  String getStatus(String timeRange) {
    final today = DateFormat('EEEE').format(DateTime.now());
    if (_selectedDay != today) return '';
    try {
      if (!timeRange.contains('-')) return '';
      final parts = timeRange.split('-');
      final now = DateTime.now();
      final start = _parseTimeWithContext(parts[0].trim(), now);
      final end = _parseTimeWithContext(parts[1].trim(), now);
      if (now.isAfter(end)) return "Completed";
      if (now.isAfter(start) && now.isBefore(end)) {
        return "Remaining ${_formatDuration(end.difference(now), includeSeconds: true)}";
      }
      if (now.isBefore(start)) {
        return "Starts in ${_formatDuration(start.difference(now), includeSeconds: true)}";
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  bool isOngoing(String timeRange) {
    final today = DateFormat('EEEE').format(DateTime.now());
    if (_selectedDay != today) return false;
    try {
      if (!timeRange.contains('-')) return false;
      final parts = timeRange.split('-');
      final now = DateTime.now();
      final start = _parseTimeWithContext(parts[0].trim(), now);
      final end = _parseTimeWithContext(parts[1].trim(), now);
      return now.isAfter(start) && now.isBefore(end);
    } catch (_) {
      return false;
    }
  }

  String _formatDuration(Duration duration, {bool includeSeconds = false}) {
    String result = '';
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    if (hours > 0) result += '${hours}H ';
    if (minutes > 0) result += '${minutes}Min ';
    if (includeSeconds && seconds > 0 && hours == 0) result += '${seconds}s';
    return result.trim();
  }

  DateTime _parseTimeWithContext(String timeStr, DateTime date) {
    try {
      final time = DateFormat('HH:mm').parse(timeStr);
      return DateTime(date.year, date.month, date.day, time.hour, time.minute);
    } catch (_) {
      return date;
    }
  }
}
