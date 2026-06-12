import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../repositories/places_repository.dart';
import '../models/place_model.dart';

class NearbyHospitalsScreen extends StatefulWidget {
  const NearbyHospitalsScreen({super.key});

  @override
  State<NearbyHospitalsScreen> createState() => _NearbyHospitalsScreenState();
}

class _NearbyHospitalsScreenState extends State<NearbyHospitalsScreen> {
  LatLng? _currentLocation;
  List<Marker> _poiMarkers = [];
  bool _isLoading = true;
  String _selectedCategory = 'hospital'; // default category

  final Map<String, IconData> _categoryIcons = {
    'hospital': Icons.local_hospital,
    'clinic': Icons.medical_services,
    'pharmacy': Icons.local_pharmacy,
  };

  final Map<String, String> _categoryLabels = {
    'hospital': 'Hospitals',
    'clinic': 'Clinics',
    'pharmacy': 'Pharmacies',
  };

  @override
  void initState() {
    super.initState();
    _initLocationAndFetchPOIs();
  }

  Future<void> _initLocationAndFetchPOIs() async {
    try {
      setState(() => _isLoading = true);

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services disabled.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions permanently denied.');
      } 

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      
      _currentLocation = LatLng(position.latitude, position.longitude);
      debugPrint('GPS coordinates successfully retrieved: lat=${position.latitude}, lon=${position.longitude}');
      
    } catch (e) {
      debugPrint('GPS acquisition error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location unavailable. Using default (New Delhi).')),
        );
      }
      _currentLocation = const LatLng(28.6139, 77.2090);
    }

    if (_currentLocation != null) {
      await _fetchRealPOIsWithRetry(_currentLocation!, _selectedCategory);
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchRealPOIsWithRetry(LatLng center, String amenity, {int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final placesRepo = context.read<PlacesRepository>();
        final places = await placesRepo.fetchNearbyPlaces(center.latitude, center.longitude, amenity);
        
        if (mounted) {
          setState(() {
            _poiMarkers = places.map((place) {
              return Marker(
                point: LatLng(place.lat, place.lon),
                width: 60,
                height: 60,
                child: GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) => Container(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_categoryIcons[amenity], size: 48, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(height: 16),
                            Text(place.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            const SizedBox(height: 8),
                            Text('Category: ${_categoryLabels[amenity]}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Icon(
                    _categoryIcons[amenity], 
                    color: Theme.of(context).colorScheme.primary, 
                    size: 40,
                  ),
                ),
              );
            }).toList();
          });
        }
        return; // Success
      } catch (e) {
        debugPrint('Attempt $attempt to fetch POIs failed: $e');
        if (attempt == maxRetries) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Nearby medical places are temporarily unavailable.')),
            );
          }
        } else {
          await Future.delayed(Duration(seconds: 2 * attempt)); // Exponential backoff
        }
      }
    }
  }

  void _onCategoryTapped(String category) {
    if (_selectedCategory == category) return;
    setState(() {
      _selectedCategory = category;
      _isLoading = true; // Show indicator
    });
    _fetchRealPOIsWithRetry(_currentLocation!, category).then((_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Medical Map'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Category Toggle Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _categoryLabels.keys.map((key) {
                final isSelected = _selectedCategory == key;
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return ChoiceChip(
                  label: Text(_categoryLabels[key]!, style: TextStyle(color: isSelected ? (isDark ? Colors.tealAccent : Theme.of(context).colorScheme.primary) : (isDark ? Colors.grey.shade300 : Colors.black87))),
                  selected: isSelected,
                  onSelected: (_) => _onCategoryTapped(key),
                  selectedColor: isDark ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2) : Theme.of(context).colorScheme.primaryContainer,
                  backgroundColor: isDark ? Colors.grey.shade800 : null,
                  avatar: Icon(_categoryIcons[key], size: 18, color: isSelected ? (isDark ? Colors.tealAccent : Theme.of(context).colorScheme.primary) : Colors.grey),
                );
              }).toList(),
            ),
          ),
          
          // Map Area
          Expanded(
            child: _isLoading && _currentLocation == null
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                  options: MapOptions(
                    initialCenter: _currentLocation ?? const LatLng(28.6139, 77.2090),
                    initialZoom: 13.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.smart_aid',
                    ),
                    if (_isLoading)
                      const Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    MarkerLayer(
                      markers: [
                        if (_currentLocation != null)
                          Marker(
                            point: _currentLocation!,
                            width: 80,
                            height: 80,
                            child: const Icon(Icons.person_pin_circle, color: Colors.red, size: 40),
                          ),
                        ..._poiMarkers,
                      ],
                    ),
                  ],
                ),
          ),
        ],
      ),
    );
  }
}
