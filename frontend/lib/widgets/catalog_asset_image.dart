import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
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

  /// Flutter web on GitHub Pages serves bundled files under `assets/<key>`.
  static String bundledAssetUrl(String assetKey) {
    if (assetKey.startsWith('lib/assets/')) {
      return Uri.base.resolve('assets/$assetKey').toString();
    }
    if (assetKey.startsWith('assets/')) {
      return Uri.base.resolve(assetKey).toString();
    }
    return Uri.base.resolve('assets/$assetKey').toString();
  }

  static String resolveSource(BuildContext context, String source) {
    if (isAssetPath(source)) return source;
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return source;
    }
    if (source.startsWith('/')) {
      return context.read<ApiService>().resolveMediaUrl(source);
    }
    return source;
  }

  Widget _buildAsset(String assetKey) {
    final fallback = error ??
        Icon(
          Icons.image_not_supported_outlined,
          size: (height ?? 48) * 0.5,
          color: Colors.grey,
        );

    if (kIsWeb) {
      return Image.network(
        bundledAssetUrl(assetKey),
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return placeholder ?? const SizedBox.shrink();
        },
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    return Image.asset(
      assetKey,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, __, ___) => fallback,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isAssetPath(source)) {
      return _buildAsset(source);
    }

    final resolved = resolveSource(context, source);
    if (isAssetPath(resolved)) {
      return _buildAsset(resolved);
    }

    return CachedNetworkImage(
      imageUrl: resolved,
      fit: fit,
      width: width,
      height: height,
      placeholder: (_, __) => placeholder ?? const SizedBox.shrink(),
      errorWidget: (_, __, ___) =>
          error ??
          Icon(
            Icons.image_not_supported_outlined,
            size: (height ?? 48) * 0.5,
            color: Colors.grey,
          ),
    );
  }
}
