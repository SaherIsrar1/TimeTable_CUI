import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

/// State for the notification setup flow.
/// Persists the selected role + id to SharedPreferences so the
/// user doesn't have to re-configure after an app restart.
///
/// On every app launch, if a saved profile exists, notifications are
/// automatically re-scheduled for the next 4 weeks to ensure
/// continuous delivery even after reboot / app kill.
class NotificationViewModel extends ChangeNotifier {
  static const _keyRole = 'notif_role';
  static const _keyId = 'notif_id';

  String? _savedRole; // 'student' | 'teacher' | null
  String? _savedId; // sectionId or teacherId

  bool _isLoading = false;
  String? _errorMessage;
  int _pendingCount = 0;

  String? get savedRole => _savedRole;
  String? get savedId => _savedId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get pendingCount => _pendingCount;

  /// Whether the user has an active notification profile.
  bool get isActive => _savedRole != null && _savedId != null;

  /// Human-readable label for dashboard button badge.
  String get activeLabel {
    if (!isActive) return '';
    final roleIcon = _savedRole == 'teacher' ? '👨‍🏫' : '🎓';
    return '$roleIcon $_savedId';
  }

  NotificationViewModel() {
    _loadAndReschedule();
  }

  // ── Persistence ─────────────────────────────────────────────────────────

  /// Loads the saved profile AND automatically re-schedules notifications
  /// if a profile is found. This runs on every app startup.
  Future<void> _loadAndReschedule() async {
    final prefs = await SharedPreferences.getInstance();
    _savedRole = prefs.getString(_keyRole);
    _savedId = prefs.getString(_keyId);
    notifyListeners();

    // Auto-reschedule if a profile is saved
    if (_savedRole != null && _savedId != null) {
      debugPrint('[NotificationVM] Saved profile found: $_savedRole / $_savedId — re-scheduling...');
      await _rescheduleFromFirestore(_savedRole!, _savedId!);
    } else {
      debugPrint('[NotificationVM] No saved profile, skipping reschedule.');
    }
  }

  /// Re-fetches timetable from Firestore and schedules notifications.
  /// Used both on startup and when manually activating.
  Future<bool> _rescheduleFromFirestore(String role, String id) async {
    try {
      final collection =
          role == 'student' ? 'timetablestudents' : 'timetableTeachers';

      final doc = await FirebaseFirestore.instance
          .collection(collection)
          .doc(id)
          .get();

      if (!doc.exists || doc.data() == null) {
        debugPrint('[NotificationVM] No timetable doc for "$id" — skipping.');
        return false;
      }

      final timetableData = doc.data()!;

      await NotificationService.scheduleWeeklyNotifications(
        role: role,
        displayName: id,
        timetableData: timetableData,
      );

      // Check how many are actually pending
      final pending = await NotificationService.getPendingNotifications();
      _pendingCount = pending.length;
      debugPrint('[NotificationVM] Pending notifications: $_pendingCount');
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('[NotificationVM] Reschedule error: $e');
      return false;
    }
  }

  Future<void> _saveProfile(String role, String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRole, role);
    await prefs.setString(_keyId, id);
    _savedRole = role;
    _savedId = id;
  }

  Future<void> _clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRole);
    await prefs.remove(_keyId);
    _savedRole = null;
    _savedId = null;
    _pendingCount = 0;
  }

  // ── Public API ───────────────────────────────────────────────────────────

  /// Fetches the full timetable for [id], schedules all notifications,
  /// then persists the profile. Called after user confirms their selection.
  Future<bool> activateNotifications({
    required String role,
    required String id,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Request permission
      final granted = await NotificationService.requestPermission();
      if (!granted) {
        _errorMessage =
            'Notification permission denied. Please enable it in Settings.';
        return false;
      }

      // 2. Schedule notifications from Firestore
      final success = await _rescheduleFromFirestore(role, id);

      if (!success) {
        _errorMessage = 'No timetable found for "$id". Please check the name.';
        return false;
      }

      // 3. Fire a test notification so the user sees it works immediately
      await NotificationService.showTestNotification();

      // 4. Save profile
      await _saveProfile(role, id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to set notifications: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cancels all notifications and clears the saved profile.
  Future<void> clearNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      await NotificationService.cancelAll();
      await _clearProfile();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Manually trigger a re-schedule (e.g. from settings screen).
  Future<void> forceReschedule() async {
    if (_savedRole == null || _savedId == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      await _rescheduleFromFirestore(_savedRole!, _savedId!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
