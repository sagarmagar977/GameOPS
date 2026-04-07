import 'package:flutter/foundation.dart';

const String _defaultHostedApiBaseUrl = 'https://gameops-eyyv.onrender.com/api';
const String _defaultLocalApiBaseUrl = 'http://localhost:4000/api';

String get apiBaseUrl {
  const override = String.fromEnvironment('API_BASE_URL');
  if (override.isNotEmpty) {
    return override;
  }

  // Use the hosted backend by default so physical devices and web builds work
  // without extra configuration. Local URLs are still available via override.
  if (kIsWeb) {
    return _defaultHostedApiBaseUrl;
  }

  if (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS) {
    return _defaultHostedApiBaseUrl;
  }

  // Desktop local development can still talk to a locally running backend.
  return _defaultLocalApiBaseUrl;
}
