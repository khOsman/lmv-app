/// Base URL for the Node/Express backend at D:\lmv_server\app.js,
/// which handles the Salesforce OAuth + query logic this API wraps.
///
/// - Android emulator reaches the host machine via 10.0.2.2, not localhost.
/// - iOS simulator / desktop / web can use localhost directly.
/// - A physical device needs the host machine's LAN IP.
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://lmv-server-5nq7.onrender.com/',
  );

  /// While true, [AuthService] and [LearnerService] serve in-memory dummy
  /// data instead of calling the backend. The real endpoints are live now,
  /// so this defaults off; force it back on for UI-only work with
  /// `flutter run --dart-define=USE_MOCK_DATA=true`.
  static const bool useMockData = bool.fromEnvironment('USE_MOCK_DATA', defaultValue: false);
}
