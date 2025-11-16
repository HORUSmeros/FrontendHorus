class AppConfig {
  AppConfig._();

  static final AppConfig instance = AppConfig._();

  // Default to the Azure backend that exposes the Swagger UI at
  // https://app-251115234629.azurewebsites.net/swagger/index.html.
  static const String _defaultBaseUrl =
      'https://app-251116050802.azurewebsites.net';

  final String backendBaseUrl = const String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: _defaultBaseUrl,
  );

  String get normalizedBackendBaseUrl {
    final trimmed = backendBaseUrl.trim();
    if (trimmed.isEmpty) {
      return _defaultBaseUrl;
    }
    return trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
  }
}
