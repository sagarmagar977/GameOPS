import 'package:flutter/foundation.dart';

const String _defaultHostedApiBaseUrl = 'https://gameops-eyyv.onrender.com/api';
const String _defaultAndroidLocalApiBaseUrl = 'http://10.0.2.2:4000/api';
const String _defaultLocalApiBaseUrl = 'http://localhost:4000/api';

List<String> get apiBaseUrls {
  const override = String.fromEnvironment('API_BASE_URL');
  if (override.isNotEmpty) {
    return [override];
  }

  // Web and desktop can usually talk to localhost directly, so prefer that and
  // fall back to the hosted API when the local backend is unavailable.
  if (kIsWeb) {
    return [_defaultLocalApiBaseUrl, _defaultHostedApiBaseUrl];
  }

  if (defaultTargetPlatform == TargetPlatform.android) {
    return [_defaultAndroidLocalApiBaseUrl, _defaultHostedApiBaseUrl];
  }

  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return [_defaultLocalApiBaseUrl, _defaultHostedApiBaseUrl];
  }

  return [_defaultLocalApiBaseUrl, _defaultHostedApiBaseUrl];
}
