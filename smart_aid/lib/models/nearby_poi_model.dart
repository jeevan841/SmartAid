class NearbyPOIModel {
  final double lat;
  final double lon;
  final String name;
  final String category;

  NearbyPOIModel({
    required this.lat,
    required this.lon,
    required this.name,
    required this.category,
  });

  factory NearbyPOIModel.fromJson(Map<String, dynamic> json, String amenityCategory) {
    return NearbyPOIModel(
      lat: (json['lat'] ?? json['center']?['lat'] ?? 0.0) * 1.0,
      lon: (json['lon'] ?? json['center']?['lon'] ?? 0.0) * 1.0,
      name: json['tags']?['name'] ?? 'Unknown Facility',
      category: amenityCategory,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lon': lon,
      'name': name,
      'category': category,
    };
  }

  NearbyPOIModel copyWith({
    double? lat,
    double? lon,
    String? name,
    String? category,
  }) {
    return NearbyPOIModel(
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      name: name ?? this.name,
      category: category ?? this.category,
    );
  }
}
