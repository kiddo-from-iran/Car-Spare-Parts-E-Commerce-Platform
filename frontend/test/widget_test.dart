import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/config/app_config.dart';

void main() {
  test('AppConfig exposes API base URL', () {
    expect(AppConfig.apiBaseUrl, isNotEmpty);
  });
}
