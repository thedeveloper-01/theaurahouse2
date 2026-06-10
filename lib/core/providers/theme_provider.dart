import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_provider.dart';

class ThemeNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  static const String _key = 'is_dark_mode';

  ThemeNotifier(this._prefs) : super(_prefs.getBool(_key) ?? false);

  Future<void> toggleTheme() async {
    state = !state;
    await _prefs.setBool(_key, state);
  }

  Future<void> setTheme(bool isDark) async {
    state = isDark;
    await _prefs.setBool(_key, state);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeNotifier(prefs);
});
