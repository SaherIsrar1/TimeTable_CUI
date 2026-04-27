import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A simple model for a recent-search entry.
class RecentSearchEntry {
  final String id;
  final String name; // display name (same as id for sections; full name for teachers)
  final String type; // 'teacher' | 'section'
  final DateTime searchedAt;

  RecentSearchEntry({
    required this.id,
    required this.name,
    required this.type,
    required this.searchedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'searchedAt': searchedAt.toIso8601String(),
      };

  factory RecentSearchEntry.fromJson(Map<String, dynamic> json) =>
      RecentSearchEntry(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        searchedAt: DateTime.parse(json['searchedAt'] as String),
      );
}

/// Persists recent searches using [SharedPreferences].
/// A maximum of [_maxEntries] entries are kept per type.
class SearchHistoryService {
  static const int _maxEntries = 8;
  static const String _teacherKey = 'recent_teachers';
  static const String _sectionKey = 'recent_sections';

  static String _keyFor(String type) =>
      type == 'teacher' ? _teacherKey : _sectionKey;

  /// Adds (or bumps) an entry to the top of the recent list.
  static Future<void> addEntry(RecentSearchEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyFor(entry.type);
    final raw = prefs.getStringList(key) ?? [];

    // Decode, remove duplicates with same id, prepend new entry
    final existing = raw
        .map((s) => RecentSearchEntry.fromJson(
            json.decode(s) as Map<String, dynamic>))
        .where((e) => e.id != entry.id)
        .toList();

    existing.insert(0, entry);
    if (existing.length > _maxEntries) {
      existing.removeRange(_maxEntries, existing.length);
    }

    await prefs.setStringList(
        key, existing.map((e) => json.encode(e.toJson())).toList());
  }

  /// Returns the recent entries for the given type (teacher or section).
  static Future<List<RecentSearchEntry>> getEntries(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyFor(type)) ?? [];
    return raw
        .map((s) => RecentSearchEntry.fromJson(
            json.decode(s) as Map<String, dynamic>))
        .toList();
  }

  /// Removes a single entry.
  static Future<void> removeEntry(String id, String type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyFor(type);
    final raw = prefs.getStringList(key) ?? [];
    final updated = raw
        .map((s) => RecentSearchEntry.fromJson(
            json.decode(s) as Map<String, dynamic>))
        .where((e) => e.id != id)
        .toList();
    await prefs.setStringList(
        key, updated.map((e) => json.encode(e.toJson())).toList());
  }

  /// Clears all recent searches for a given type.
  static Future<void> clearAll(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFor(type));
  }
}
