import 'package:flutter/material.dart';

enum BottomNavigationPage { home, user, settings }

extension BottomNavigationPageExtension on BottomNavigationPage {
  String get nameTab {
    switch (this) {
      case BottomNavigationPage.home:
        return 'Home';
      case BottomNavigationPage.user:
        return 'User';
      case BottomNavigationPage.settings:
        return 'Settings';
    }
  }

  IconData get activeIcon {
    switch (this) {
      case BottomNavigationPage.home:
        return Icons.home;
      case BottomNavigationPage.user:
        return Icons.home;
      case BottomNavigationPage.settings:
        return Icons.home;
    }
  }

  IconData get inactiveIcon {
    switch (this) {
      case BottomNavigationPage.home:
        return Icons.home_outlined;
      case BottomNavigationPage.user:
        return Icons.home_outlined;
      case BottomNavigationPage.settings:
        return Icons.home_outlined;
    }
  }

  IconData getIcon(bool isSelected) {
    return isSelected ? activeIcon : inactiveIcon;
  }
}
