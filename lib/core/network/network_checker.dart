import 'package:connectivity_plus/connectivity_plus.dart';
import 'api_exception.dart';

/// Checks internet connectivity before any API call is made.
/// Throws [ApiException.noInternet] if offline.
class NetworkChecker {
  NetworkChecker._();

  static final Connectivity _connectivity = Connectivity();

  /// Returns true if there's an active network connection.
  static Future<bool> hasInternet() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);
  }

  /// Throws [ApiException.noInternet] if there's no connection.
  /// Call this at the start of every service method.
  static Future<void> assertConnected() async {
    if (!await hasInternet()) {
      throw ApiException.noInternet();
    }
  }
}
