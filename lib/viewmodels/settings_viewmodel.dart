import 'package:flutter/material.dart';

/// ViewModel for [ProfileSettingsScreen].
/// Holds UI preference toggles.
class SettingsViewModel extends ChangeNotifier {
  bool isDarkMode = false;
  bool notifications = true;

  void toggleDarkMode(bool value) {
    isDarkMode = value;
    notifyListeners();
  }

  void toggleNotifications(bool value) {
    notifications = value;
    notifyListeners();
  }
}
