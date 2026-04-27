import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/search_history_service.dart';

/// ViewModel for [TimetableScreen].
/// Holds search results, selected tab, loading state, and recent-search history.
class TimetableViewModel extends ChangeNotifier {
  int selectedTab = 1; // 0: Teachers, 1: Sections

  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _sections = [];
  bool _loading = false;
  String _searchQuery = '';
  String? _errorMessage;

  // Recent searches loaded from SharedPreferences
  List<RecentSearchEntry> _recentTeachers = [];
  List<RecentSearchEntry> _recentSections = [];

  List<Map<String, dynamic>> get teachers => _teachers;
  List<Map<String, dynamic>> get sections => _sections;
  bool get loading => _loading;
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;

  List<RecentSearchEntry> get recentTeachers => _recentTeachers;
  List<RecentSearchEntry> get recentSections => _recentSections;

  List<RecentSearchEntry> get currentRecent =>
      selectedTab == 0 ? _recentTeachers : _recentSections;

  TimetableViewModel() {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    _recentTeachers = await SearchHistoryService.getEntries('teacher');
    _recentSections = await SearchHistoryService.getEntries('section');
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    // No notifyListeners — just resets the flag silently
  }

  // ---------------------------------------------------------------------------
  // Recent-search helpers
  // ---------------------------------------------------------------------------

  /// Saves an item to recent history and refreshes the local list.
  Future<void> saveToHistory({
    required String id,
    required String name,
    required String type,
  }) async {
    final entry = RecentSearchEntry(
      id: id,
      name: name,
      type: type,
      searchedAt: DateTime.now(),
    );
    await SearchHistoryService.addEntry(entry);
    await _loadHistory();
  }

  /// Removes one recent entry.
  Future<void> removeFromHistory(String id, String type) async {
    await SearchHistoryService.removeEntry(id, type);
    await _loadHistory();
  }

  /// Clears all recent for the current tab.
  Future<void> clearHistory() async {
    final type = selectedTab == 0 ? 'teacher' : 'section';
    await SearchHistoryService.clearAll(type);
    await _loadHistory();
  }

  // ---------------------------------------------------------------------------
  // Search — Sections
  // ---------------------------------------------------------------------------

  /// Fetches sections whose IDs contain [query].
  /// Results are ranked: exact match first, then starts-with, then contains.
  Future<void> fetchSections(String query) async {
    if (selectedTab != 1) return;

    _searchQuery = query;
    final q = query.trim();

    if (q.isEmpty) {
      _sections = [];
      _loading = false;
      notifyListeners();
      return;
    }

    _loading = true;
    notifyListeners();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('timetablestudents')
          .get();

      final lq = q.toLowerCase();

      final all = snapshot.docs
          .where((doc) => doc.id.toLowerCase().contains(lq))
          .map((doc) => {'id': doc.id})
          .toList();

      // Rank: exact → starts-with → contains
      all.sort((a, b) {
        final aId = (a['id'] as String).toLowerCase();
        final bId = (b['id'] as String).toLowerCase();
        int rank(String id) {
          if (id == lq) return 0;
          if (id.startsWith(lq)) return 1;
          return 2;
        }

        return rank(aId).compareTo(rank(bId));
      });

      _sections = all;
    } catch (e) {
      _errorMessage = 'Error fetching sections: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Search — Teachers
  // ---------------------------------------------------------------------------

  /// Fetches teachers whose IDs/names contain [query].
  /// Results are ranked: exact match first, then starts-with, then contains.
  Future<void> fetchTeachers(String query) async {
    if (selectedTab != 0) return;

    _searchQuery = query;
    final q = query.trim();

    if (q.isEmpty) {
      _teachers = [];
      _loading = false;
      notifyListeners();
      return;
    }

    _loading = true;
    notifyListeners();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('timetableTeachers')
          .get();

      final lq = q.toLowerCase();

      final all = snapshot.docs
          .where((doc) => doc.id.toLowerCase().contains(lq))
          .map((doc) => {'id': doc.id, 'name': doc.id})
          .toList();

      // Rank: exact → starts-with → contains
      all.sort((a, b) {
        final aId = (a['id'] as String).toLowerCase();
        final bId = (b['id'] as String).toLowerCase();
        int rank(String id) {
          if (id == lq) return 0;
          if (id.startsWith(lq)) return 1;
          return 2;
        }

        return rank(aId).compareTo(rank(bId));
      });

      _teachers = all;
    } catch (e) {
      _errorMessage = 'Error fetching teachers: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Tab switching
  // ---------------------------------------------------------------------------

  void changeTab(int newTab) {
    if (selectedTab != newTab) {
      selectedTab = newTab;
      _searchQuery = '';
      _sections = [];
      _teachers = [];
      notifyListeners();
    }
  }
}
