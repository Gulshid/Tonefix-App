import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._prefs) : super(ThemeMode.system) {
    _loadTheme();
  }

  final SharedPreferences _prefs;
  static const _key = 'theme_mode';

  void _loadTheme() {
    final saved = _prefs.getString(_key);
    if (saved == 'light') emit(ThemeMode.light);
    if (saved == 'dark') emit(ThemeMode.dark);
  }

  void setLight() {
    _prefs.setString(_key, 'light');
    emit(ThemeMode.light);
  }

  void setDark() {
    _prefs.setString(_key, 'dark');
    emit(ThemeMode.dark);
  }

  void setSystem() {
    _prefs.setString(_key, 'system');
    emit(ThemeMode.system);
  }

  void toggle() {
    if (state == ThemeMode.light) {
      setDark();
    } else {
      setLight();
    }
  }
}
