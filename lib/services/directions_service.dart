// DirectionsService: minimal cross-platform launcher for map navigation.
// iOS: uses Apple Maps via `maps://` scheme. Android: uses `geo:` intent.
// Falls back to Google Maps web URL if native handlers are unavailable.
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
}
