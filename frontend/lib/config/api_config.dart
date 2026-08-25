import 'package:flutter/foundation.dart' show kIsWeb;

/// Central API base URL configuration.
///
/// How it works:
/// - When running on Web (kIsWeb == true) it detects the page host (Uri.base.host).
///   - If host is `localhost` or empty it will use `http://localhost:3000`.
///   - Otherwise it will use the page host (for example when you open the web app
///     on your phone via http://192.168.1.39:8080 it will use that host for API
///     requests: `http://192.168.1.39:3000`).
/// - When running on mobile/desktop (kIsWeb == false) it returns a placeholder
///   URL that you must replace with your laptop IP running the backend.
///
/// IMPORTANT: Replace `YOUR_LAPTOP_IP` below with your actual laptop IP (e.g.
/// `192.168.1.39`) when testing from a real phone.

class Api {
  // Backend port used by your Node.js server
  static const int backendPort = 3000;

  // Replace this string with your laptop IP when testing from a phone.
  // Example: static const String laptopIp = '192.168.1.39';
  static const String laptopIp = '10.120.242.52';

  static String get baseHost {
    if (kIsWeb) {
      final host = Uri.base.host; // page host
      final scheme = Uri.base.scheme.isNotEmpty ? Uri.base.scheme : 'http';
      if (host == 'localhost' || host == '127.0.0.1' || host.isEmpty) {
        return '$scheme://localhost:$backendPort';
      } else {
        return '$scheme://$host:$backendPort';
      }
    } else {
      // mobile / desktop builds (not web)
      return 'http://$laptopIp:$backendPort';
    }
  }

  /// Append API path segments easily
  static String api(String path) {
    if (path.startsWith('/')) return '$baseHost$path';
    return '$baseHost/$path';
  }
}
