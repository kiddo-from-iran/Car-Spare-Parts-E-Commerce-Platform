/// Build-time configuration (see `--dart-define` in CI / GitHub Pages deploy).
class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// GitHub Pages project site, e.g. /Car-Spare-Parts-E-Commerce-Platform/
  static const webBaseHref = String.fromEnvironment(
    'WEB_BASE_HREF',
    defaultValue: '/',
  );
}
