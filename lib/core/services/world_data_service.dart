import 'dart:convert';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart' show rootBundle;

/// A city with its country, to tell same-named cities apart.
class CityEntry {
  const CityEntry({required this.city, required this.country});

  final String city;
  final String country;

  String get label => '$city, $country';
}

typedef _WorldData = (List<String> countries, List<CityEntry> cities);

/// Loads the bundled world countries/cities dataset into simple lists.
class WorldDataService {
  WorldDataService._();

  static final WorldDataService instance = WorldDataService._();

  static const _assetPath =
      'packages/country_state_city_picker/lib/assets/country.json';

  List<String>? _countries;
  List<CityEntry>? _cities;
  Future<void>? _loading;

  Future<List<String>> loadCountries() async {
    await _ensureLoaded();
    return _countries!;
  }

  Future<List<CityEntry>> loadCities() async {
    await _ensureLoaded();
    return _cities!;
  }

  Future<void> _ensureLoaded() {
    if (_countries != null && _cities != null) return Future.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    // Decoded on a background isolate; it's ~7.5MB and froze the main one.
    final raw = await rootBundle.loadString(_assetPath);
    final (countries, cities) = await compute(_parseWorldData, raw);
    _countries = countries;
    _cities = cities;
  }
}

_WorldData _parseWorldData(String raw) {
  final data = jsonDecode(raw) as List<dynamic>;

  final countries = <String>[];
  final cities = <CityEntry>[];
  final seenCities = <String>{};

  for (final entry in data) {
    final country = entry as Map<String, dynamic>;
    final countryName = country['name'] as String?;
    if (countryName == null || countryName.isEmpty) continue;

    countries.add(countryName);

    final states = country['state'] as List<dynamic>? ?? const [];
    for (final stateEntry in states) {
      final cityList =
          (stateEntry as Map<String, dynamic>)['city'] as List<dynamic>? ??
          const [];
      for (final cityEntry in cityList) {
        final cityName = (cityEntry as Map<String, dynamic>)['name'] as String?;
        if (cityName == null || cityName.isEmpty) continue;

        final key = '$cityName|$countryName';
        if (seenCities.add(key)) {
          cities.add(CityEntry(city: cityName, country: countryName));
        }
      }
    }
  }

  countries.sort();
  return (countries, cities);
}
