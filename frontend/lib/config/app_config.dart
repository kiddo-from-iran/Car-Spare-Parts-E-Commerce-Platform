import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Build-time and runtime configuration for API URL and web base href.
class AppConfig {
  static const _envApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// GitHub Pages project site, e.g. /Car-Spare-Parts-E-Commerce-Platform/
  static const webBaseHref = String.fromEnvironment(
    'WEB_BASE_HREF',
    defaultValue: '/',
  );

  static const _defaultLocalApi = 'http://localhost:8000';
  static const _defaultProdApi = 'https://car-spare-parts-api.onrender.com';

  /// Resolved at startup on web via [api-config.json]; compile-time define overrides.
  static String apiBaseUrl = _envApiBaseUrl.isNotEmpty
      ? _envApiBaseUrl
      : (kIsWeb ? _defaultProdApi : _defaultLocalApi);

  static Future<void> loadRuntimeConfig() async {
    if (_envApiBaseUrl.isNotEmpty) {
      apiBaseUrl = _envApiBaseUrl;
      return;
    }

    if (!kIsWeb) {
      apiBaseUrl = _defaultLocalApi;
      return;
    }

    try {
      final configUrl = Uri.base.resolve('api-config.json');
      final response = await http.get(configUrl);
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body is Map) {
          final url = body['apiBaseUrl']?.toString().trim();
          if (url != null && url.isNotEmpty) {
            apiBaseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
            return;
          }
        }
      }
    } catch (_) {
      // Fall back to default production URL.
    }

    apiBaseUrl = _defaultProdApi;
  }
}
