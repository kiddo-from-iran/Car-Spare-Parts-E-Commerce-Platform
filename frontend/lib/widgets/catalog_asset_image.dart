import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';

/// Renders a smart-catalog image from a local asset path or remote URL.
class CatalogAssetImage extends StatelessWidget {
  const CatalogAssetImage({
    super.key,
    required this.source,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.placeholder,
    this.error,
  });

  final String source;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? error;

  static bool isAssetPath(String source) =>
      source.startsWith('lib/assets/') || source.startsWith('assets/');

  static String resolveSource(BuildContext context, String source) {
    if (isAssetPath(source)) return source;
    if (source.startsWith('http://') || source.startsWith('https://')) return source;
    if (source.startsWith('/')) {
      return context.read<ApiService>().resolveMediaUrl(source);
    }
    return source;
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveSource(context, source);
    if (isAssetPath(resolved)) {
      return Image.asset(
        resolved,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) =>
            error ?? Icon(Icons.directions_car_outlined, size: (height ?? 48) * 0.5, color: Colors.grey),
      );
    }

    return CachedNetworkImage(
      imageUrl: resolved,
      fit: fit,
      width: width,
      height: height,
      placeholder: (_, __) => placeholder ?? const SizedBox.shrink(),
      errorWidget: (_, __, ___) =>
          error ?? Icon(Icons.directions_car_outlined, size: (height ?? 48) * 0.5, color: Colors.grey),
    );
  }
}
