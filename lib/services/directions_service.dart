import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class DirectionsService {
  static Future<void> launchDirections({
    required double destinationLat,
    required double destinationLng,
    required String destinationName,
  }) async {
    try {
      // Show options to user
      final selectedApp = await _showDirectionsOptions();
      
      if (selectedApp == null) return;

      switch (selectedApp) {
        case 'google_maps':
          await _launchGoogleMaps(destinationLat, destinationLng, destinationName);
          break;
        case 'waze':
          await _launchWaze(destinationLat, destinationLng);
          break;
        case 'apple_maps':
          await _launchAppleMaps(destinationLat, destinationLng, destinationName);
          break;
        case 'default':
          await _launchDefaultMaps(destinationLat, destinationLng, destinationName);
          break;
      }
    } catch (e) {
      debugPrint('Error launching directions: $e');
      rethrow;
    }
  }

  static Future<String?> _showDirectionsOptions() async {
    // This will be called from the widget to show a bottom sheet
    // with direction options
    return null; // Placeholder - will be called from UI
  }

  static Future<void> _launchGoogleMaps(
    double lat,
    double lng,
    String label,
  ) async {
    final String url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=$label';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        // Fallback to basic Google Maps URL
        final fallback = 'https://maps.google.com/?q=$lat,$lng';
        if (await canLaunchUrl(Uri.parse(fallback))) {
          await launchUrl(Uri.parse(fallback), mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      debugPrint('Error launching Google Maps: $e');
    }
  }

  static Future<void> _launchWaze(double lat, double lng) async {
    final String url = 'https://waze.com/ul?ll=$lat,$lng&navigate=yes';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching Waze: $e');
    }
  }

  static Future<void> _launchAppleMaps(
    double lat,
    double lng,
    String label,
  ) async {
    final String url = 'maps://maps.apple.com/?daddr=$lat,$lng&q=$label';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching Apple Maps: $e');
    }
  }

  static Future<void> _launchDefaultMaps(
    double lat,
    double lng,
    String label,
  ) async {
    final String url = 'geo:$lat,$lng?q=$label';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching default maps: $e');
    }
  }

  /// Show dialog for user to select which maps app to use
  static Future<String?> showMapsSelector(BuildContext context) async {
    return showModalBottomSheet<String>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose Navigation App',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Google Maps'),
              onTap: () => Navigator.pop(context, 'google_maps'),
            ),
            ListTile(
              leading: const Icon(Icons.navigation),
              title: const Text('Waze'),
              onTap: () => Navigator.pop(context, 'waze'),
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Default Maps App'),
              onTap: () => Navigator.pop(context, 'default'),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Launch directions with selected app from widget
  static Future<void> launchWithSelectedApp(
    BuildContext context, {
    required double destinationLat,
    required double destinationLng,
    required String destinationName,
  }) async {
    final selectedApp = await showMapsSelector(context);
    
    if (selectedApp == null) return;

    switch (selectedApp) {
      case 'google_maps':
        await _launchGoogleMaps(destinationLat, destinationLng, destinationName);
        break;
      case 'waze':
        await _launchWaze(destinationLat, destinationLng);
        break;
      case 'default':
        await _launchDefaultMaps(destinationLat, destinationLng, destinationName);
        break;
    }
  }
}
