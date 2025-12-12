import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:math';

class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() => _instance;

  LocationService._internal();

  /// Check and request location permissions
  Future<bool> requestLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        final result = await Geolocator.requestPermission();
        return result == LocationPermission.whileInUse || 
               result == LocationPermission.always;
      }
      
      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission denied permanently. Opening settings.');
        await Geolocator.openLocationSettings();
        return false;
      }
      
      return permission == LocationPermission.whileInUse || 
             permission == LocationPermission.always;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return false;
    }
  }

  /// Get current user location
  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        debugPrint('Location permission not granted');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      debugPrint('Current location: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  /// Calculate distance between two points in kilometers
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  /// Fetch nearby hospitals and pharmacies using Overpass API (OpenStreetMap)
  /// [radius] is in meters (default 5000m = 5km)
  Future<List<HealthLocation>> getNearbyHealthFacilities({
    required double latitude,
    required double longitude,
    int radius = 5000,
  }) async {
    try {
      debugPrint('Fetching health facilities near $latitude, $longitude');
      
      // Overpass API query to get hospitals and pharmacies
      final overpassUrl = Uri.parse('https://overpass-api.de/api/interpreter');
      
      // Create bounding box around the center point
      final latOffset = radius / 111000.0; // 1 degree of latitude ≈ 111 km
      final lonOffset = radius / (111000.0 * cos(latitude.abs() * pi / 180.0));
      
      final south = latitude - latOffset;
      final north = latitude + latOffset;
      final west = longitude - lonOffset;
      final east = longitude + lonOffset;
      
      // Overpass QL query for hospitals and pharmacies
      final query = '''
      [bbox:$south,$west,$north,$east];
      (
        node["amenity"="hospital"];
        way["amenity"="hospital"];
        relation["amenity"="hospital"];
        node["amenity"="pharmacy"];
        way["amenity"="pharmacy"];
        relation["amenity"="pharmacy"];
      );
      out center;
      ''';

      final response = await http.post(
        overpassUrl,
        body: query,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        debugPrint('Overpass API error: ${response.statusCode}');
        return [];
      }

      return _parseOverpassResponse(response.body);
    } catch (e) {
      debugPrint('Error fetching health facilities: $e');
      return [];
    }
  }

  /// Parse Overpass API XML/JSON response
  List<HealthLocation> _parseOverpassResponse(String responseBody) {
    final locations = <HealthLocation>[];
    
    try {
      // Simple XML parsing for Overpass API response
      // Looking for <node> and <way> elements with amenity tags
      final nodeRegex = RegExp(
        r'<(?:node|way|relation)\s+id="(\d+)"[^>]*lat="([\d.-]+)"[^>]*lon="([\d.-]+)"[^>]*>.*?(?=<\/(?:node|way|relation)>)',
        caseSensitive: false,
        dotAll: true,
      );

      final tagRegex = RegExp(
        r'<tag\s+k="([^"]*)"[^>]*v="([^"]*)"\s*\/>',
        caseSensitive: false,
      );

      // Alternative: parse center coordinates for ways/relations
      final centerRegex = RegExp(
        r'<center\s+lat="([\d.-]+)"[^>]*lon="([\d.-]+)"[^>]*\/>',
        caseSensitive: false,
      );

      final elements = RegExp(
        r'<(node|way|relation)\s+id="(\d+)"[^>]*>.*?(?=<\/\1>)',
        caseSensitive: false,
        dotAll: true,
      ).allMatches(responseBody);

      for (final match in elements) {
        final elementBody = match.group(0) ?? '';
        final id = match.group(2) ?? 'unknown';
        
        double? lat, lon;
        String? name, amenityType;
        final tags = <String, String>{};

        // Extract lat/lon from node or center
        final nodeCoords = RegExp(
          r'<node[^>]*lat="([\d.-]+)"[^>]*lon="([\d.-]+)"',
          caseSensitive: false,
        ).firstMatch(elementBody);
        
        if (nodeCoords != null) {
          lat = double.tryParse(nodeCoords.group(1) ?? '0');
          lon = double.tryParse(nodeCoords.group(2) ?? '0');
        } else {
          final centerCoords = centerRegex.firstMatch(elementBody);
          if (centerCoords != null) {
            lat = double.tryParse(centerCoords.group(1) ?? '0');
            lon = double.tryParse(centerCoords.group(2) ?? '0');
          }
        }

        // Extract tags
        for (final tagMatch in tagRegex.allMatches(elementBody)) {
          final key = tagMatch.group(1) ?? '';
          final value = tagMatch.group(2) ?? '';
          tags[key] = value;
        }

        // Get amenity type and name
        amenityType = tags['amenity'];
        name = tags['name'] ?? tags['operator'] ?? 'Unnamed $amenityType';

        if (lat != null && lon != null && amenityType != null) {
          final location = HealthLocation(
            id: id,
            name: name,
            type: amenityType == 'hospital' ? 'hospital' : 'pharmacy',
            latitude: lat,
            longitude: lon,
            address: tags['addr:full'] ?? 
                     _formatAddress(
                       tags['addr:street'],
                       tags['addr:housenumber'],
                       tags['addr:city'],
                       tags['addr:postcode'],
                     ),
            phone: tags['phone'] ?? tags['contact:phone'],
            website: tags['website'] ?? tags['contact:website'],
          );
          
          locations.add(location);
          debugPrint('Found: ${location.name} (${location.type})');
        }
      }

      debugPrint('Parsed ${locations.length} health facilities');
      return locations;
    } catch (e) {
      debugPrint('Error parsing Overpass response: $e');
      return [];
    }
  }

  /// Format address from components
  String? _formatAddress(
    String? street,
    String? housenumber,
    String? city,
    String? postcode,
  ) {
    final parts = <String>[];
    
    if (housenumber != null && street != null) {
      parts.add('$street $housenumber');
    } else if (street != null) {
      parts.add(street);
    }
    
    if (postcode != null && city != null) {
      parts.add('$postcode $city');
    } else if (city != null) {
      parts.add(city);
    }
    
    return parts.isNotEmpty ? parts.join(', ') : null;
  }
}

/// Model for hospital/pharmacy location
class HealthLocation {
  final String id;
  final String name;
  final String type; // 'hospital' or 'pharmacy'
  final double latitude;
  final double longitude;
  final String? address;
  final String? phone;
  final String? website;
  final double? rating;

  HealthLocation({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.address,
    this.phone,
    this.website,
    this.rating,
  });

  factory HealthLocation.fromJson(Map<String, dynamic> json) {
    return HealthLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'phone': phone,
      'website': website,
      'rating': rating,
    };
  }
}
