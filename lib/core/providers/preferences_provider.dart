import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small app-wide preferences, saved locally.
class PreferencesProvider extends ChangeNotifier {
  static const _currencyPrefsKey = 'preferred_currency';

  String? _currency;
  String? get currency => _currency;

  PreferencesProvider() {
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_currencyPrefsKey);
    if (stored != null && stored != _currency) {
      _currency = stored;
      notifyListeners();
    }
  }

  Future<void> setCurrency(String currency) async {
    if (_currency == currency) return;
    _currency = currency;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyPrefsKey, currency);
  }
}
