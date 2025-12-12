import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class DirectionsService {
  /// Launch using the platform default maps app without showing any selector.
  /// On iOS: uses the `maps://` URL scheme (Apple Maps). On Android: `geo:` scheme.
  static Future<void> launchDefaultMapsApp({
    required double destinationLat,
    required double destinationLng,
    required String destinationName,
  }) async {
    try {
      // iOS uses Apple Maps by default
      final appleUrl = Uri.parse('maps://maps.apple.com/?daddr=$destinationLat,$destinationLng&q=$destinationName');
      // Android geo intent (opens default maps app and shows native app sheet if multiple handlers)
      final androidUrl = Uri.parse('geo:$destinationLat,$destinationLng?q=$destinationName');

      // Try platform-specific first, then fallback to Google Maps web
      if (await canLaunchUrl(appleUrl)) {
        await launchUrl(appleUrl, mode: LaunchMode.externalApplication);
        return;
      }
      if (await canLaunchUrl(androidUrl)) {
        await launchUrl(androidUrl, mode: LaunchMode.externalApplication);
        return;
      }
      final webFallback = Uri.parse('https://maps.google.com/?q=$destinationLat,$destinationLng');
      if (await canLaunchUrl(webFallback)) {
        await launchUrl(webFallback, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching default maps app: $e');
    }
  }
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
              'Open in Maps',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Open default map app'),
              onTap: () => Navigator.pop(context, 'default'),
            ),
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
    if (selectedApp == 'default') {
      await launchDefaultMapsApp(
        destinationLat: destinationLat,
        destinationLng: destinationLng,
        destinationName: destinationName,
      );
    }
  }
}
