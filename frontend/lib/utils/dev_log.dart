import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class DevLog {
  static void otp({required String phone, required String code, required String purpose}) {
    final message = '[OTP] purpose=$purpose phone=$phone code=$code';
    developer.log(message, name: 'Montakhab.Auth');
    if (kDebugMode) {
      // Flutter web forwards print/debugPrint to the browser DevTools console.
      debugPrint(message);
    }
  }
}
