import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/place_model.dart';

class PlacesRepository {
  Future<List<PlaceModel>> fetchNearbyPlaces(double lat, double lon, String amenity) async {
    final overpassUrl = 'https://overpass-api.de/api/interpreter';
    final query = '''
      [out:json][timeout:25];
      (
        node["amenity"="$amenity"](around:5000, $lat, $lon);
        way["amenity"="$amenity"](around:5000, $lat, $lon);
        relation["amenity"="$amenity"](around:5000, $lat, $lon);
      );
      out center;
    ''';

    final response = await http.post(
      Uri.parse(overpassUrl),
      headers: {
        'User-Agent': 'SmartAID/1.0',
        'Accept': 'application/json',
      },
      body: {
        'data': query,
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final elements = data['elements'] as List;
      
      return elements.map((e) {
        final dLat = (e['lat'] ?? e['center']['lat']) * 1.0;
        final dLon = (e['lon'] ?? e['center']['lon']) * 1.0;
        final name = e['tags']?['name'] ?? 'Unknown Facility';
        return PlaceModel(lat: dLat, lon: dLon, name: name, amenity: amenity);
      }).toList();
    } else {
      debugPrint('PlacesRepository Error: HTTP ${response.statusCode}');
      throw Exception('Failed to fetch nearby places (HTTP ${response.statusCode})');
    }
  }
}
