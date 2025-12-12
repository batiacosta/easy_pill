import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/directions_service.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({Key? key}) : super(key: key);

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  
  Position? _currentPosition;
  List<HealthLocation> _nearbyLocations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      setState(() => _isLoading = true);
      
      // Get current position
      final position = await _locationService.getCurrentLocation();
      
      if (position == null) {
        setState(() {
          _errorMessage = 'Unable to get your location. Please check permissions.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _currentPosition = position;
      });

      // Fetch nearby health facilities from Overpass API
      final facilities = await _locationService.getNearbyHealthFacilities(
        latitude: position.latitude,
        longitude: position.longitude,
        radius: 5000, // 5 km radius
      );

      // Calculate distances and sort
      _calculateNearbyLocations(facilities);

      // Center map on current location after widget is rendered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(
            LatLng(position.latitude, position.longitude),
            15.0,
          );
        }
      });

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error initializing location: $e');
      setState(() {
        _errorMessage = 'Error loading location. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _calculateNearbyLocations(List<HealthLocation> facilities) {
    if (_currentPosition == null) return;

    final locations = List<HealthLocation>.from(facilities);
    
    // Sort by distance
    locations.sort((a, b) {
      final distA = _locationService.calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        a.latitude,
        a.longitude,
      );
      
      final distB = _locationService.calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        b.latitude,
        b.longitude,
      );
      
      return distA.compareTo(distB);
    });

    setState(() => _nearbyLocations = locations);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Nearby Hospitals & Pharmacies'),
          backgroundColor: const Color(0xFF1E1E1E),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF9B51E0)),
        ),
        backgroundColor: const Color(0xFF121212),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Nearby Hospitals & Pharmacies'),
          backgroundColor: const Color(0xFF1E1E1E),
        ),
        body: Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Color(0xFFE0E0E0)),
            textAlign: TextAlign.center,
          ),
        ),
        backgroundColor: const Color(0xFF121212),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Hospitals & Pharmacies'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
      ),
      body: _currentPosition == null
          ? const Center(
              child: Text(
                'Unable to load map',
                style: TextStyle(color: Color(0xFFE0E0E0)),
              ),
            )
          : Stack(
              children: [
                // Map
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    initialZoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      retinaMode: true,
                      userAgentPackageName: 'com.easy_pill.app',
                    ),
                    // Current user location marker
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          ),
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF9B51E0),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.person_pin_circle,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        // Hospital and pharmacy markers
                        ..._nearbyLocations.map(
                          (location) => Marker(
                            point: LatLng(location.latitude, location.longitude),
                            width: 40,
                            height: 40,
                            child: GestureDetector(
                              onTap: () => _showLocationDetails(location),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: location.type == 'hospital'
                                      ? Colors.red
                                      : Colors.green,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  location.type == 'hospital'
                                      ? Icons.local_hospital
                                      : Icons.local_pharmacy,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // List of nearby locations at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: const Color(0xFF1E1E1E),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF828282),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(
                          height: 300,
                          child: ListView.builder(
                            itemCount: _nearbyLocations.length,
                            itemBuilder: (context, index) {
                              final location = _nearbyLocations[index];
                              final distance = _currentPosition != null
                                  ? _locationService.calculateDistance(
                                      _currentPosition!.latitude,
                                      _currentPosition!.longitude,
                                      location.latitude,
                                      location.longitude,
                                    )
                                  : 0.0;

                              return _buildLocationCard(location, distance);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      backgroundColor: const Color(0xFF121212),
    );
  }

  Widget _buildLocationCard(HealthLocation location, double distance) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF2C2C2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            location.type == 'hospital'
                                ? Icons.local_hospital
                                : Icons.local_pharmacy,
                            color: location.type == 'hospital'
                                ? Colors.red
                                : Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              location.name,
                              style: const TextStyle(
                                color: Color(0xFFE0E0E0),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${distance.toStringAsFixed(1)} km away',
                        style: const TextStyle(
                          color: Color(0xFF9B51E0),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (location.rating != null)
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        location.rating!.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Color(0xFFE0E0E0),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (location.address != null) ...[
              const SizedBox(height: 8),
              Text(
                location.address!,
                style: const TextStyle(
                  color: Color(0xFF828282),
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => DirectionsService.launchDefaultMapsApp(
                      destinationLat: location.latitude,
                      destinationLng: location.longitude,
                      destinationName: location.name,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9B51E0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.directions, size: 18),
                    label: const Text('Open in Maps'),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  void _showLocationDetails(HealthLocation location) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        color: const Color(0xFF1E1E1E),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              location.name,
              style: const TextStyle(
                color: Color(0xFFE0E0E0),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (location.address != null) ...[
              Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF9B51E0)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      location.address!,
                      style: const TextStyle(color: Color(0xFFE0E0E0)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (location.phone != null) ...[
              Row(
                children: [
                  const Icon(Icons.phone, color: Color(0xFF9B51E0)),
                  const SizedBox(width: 8),
                  Text(
                    location.phone!,
                    style: const TextStyle(color: Color(0xFFE0E0E0)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  DirectionsService.launchDefaultMapsApp(
                    destinationLat: location.latitude,
                    destinationLng: location.longitude,
                    destinationName: location.name,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9B51E0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                icon: const Icon(Icons.directions),
                label: const Text('Open in Maps'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
