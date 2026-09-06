import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsState {
  final ThemeMode themeMode;
  final bool pushNotificationsEnabled;
  final bool emailDigestEnabled;
  final bool soundAlertsEnabled;
  final bool autoAssignInquiries;
  final String activeLanguage;

  const SettingsState({
    this.themeMode = ThemeMode.dark,
    this.pushNotificationsEnabled = true,
    this.emailDigestEnabled = true,
    this.soundAlertsEnabled = true,
    this.autoAssignInquiries = false,
    this.activeLanguage = 'English (US)',
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? pushNotificationsEnabled,
    bool? emailDigestEnabled,
    bool? soundAlertsEnabled,
    bool? autoAssignInquiries,
    String? activeLanguage,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      emailDigestEnabled: emailDigestEnabled ?? this.emailDigestEnabled,
      soundAlertsEnabled: soundAlertsEnabled ?? this.soundAlertsEnabled,
      autoAssignInquiries: autoAssignInquiries ?? this.autoAssignInquiries,
      activeLanguage: activeLanguage ?? this.activeLanguage,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());

  void toggleTheme() {
    state = state.copyWith(
      themeMode: state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void togglePush(bool val) => state = state.copyWith(pushNotificationsEnabled: val);
  void toggleEmailDigest(bool val) => state = state.copyWith(emailDigestEnabled: val);
  void toggleSound(bool val) => state = state.copyWith(soundAlertsEnabled: val);
  void toggleAutoAssign(bool val) => state = state.copyWith(autoAssignInquiries: val);
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
