import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum ToastType { success, error, info, warning }

class ToastData {
  ToastData({
    required this.id,
    required this.message,
    required this.type,
    required this.duration,
  });

  final String id;
  final String message;
  final ToastType type;
  final Duration duration;
}

class ToastProvider extends ChangeNotifier {
  final List<ToastData> _toasts = [];

  List<ToastData> get toasts => List.unmodifiable(_toasts);

  void show(
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(milliseconds: 4200),
  }) {
    _toasts.add(
      ToastData(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        message: message,
        type: type,
        duration: duration,
      ),
    );
    notifyListeners();
  }

  void success(String message, {Duration? duration}) =>
      show(message, type: ToastType.success, duration: duration ?? const Duration(milliseconds: 4200));

  void error(String message, {Duration? duration}) =>
      show(message, type: ToastType.error, duration: duration ?? const Duration(milliseconds: 5000));

  void info(String message, {Duration? duration}) =>
      show(message, type: ToastType.info, duration: duration ?? const Duration(milliseconds: 4200));

  void warning(String message, {Duration? duration}) =>
      show(message, type: ToastType.warning, duration: duration ?? const Duration(milliseconds: 4500));

  void dismiss(String id) {
    _toasts.removeWhere((t) => t.id == id);
    notifyListeners();
  }
}

extension ToastContext on BuildContext {
  ToastProvider get toast => read<ToastProvider>();

  void showToast(String message, {ToastType type = ToastType.info}) {
    read<ToastProvider>().show(message, type: type);
  }

  void showSuccess(String message) => read<ToastProvider>().success(message);
  void showError(String message) => read<ToastProvider>().error(message);
  void showInfo(String message) => read<ToastProvider>().info(message);
  void showWarning(String message) => read<ToastProvider>().warning(message);
}
