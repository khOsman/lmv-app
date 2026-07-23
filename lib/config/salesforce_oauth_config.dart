/// Config for the Authorization Code + PKCE flow against the Salesforce
/// "LMV" External Client App. The DM's credentials are entered directly on
/// Salesforce's own hosted community login page (opened via the system
/// browser) - they never pass through this app or our backend.
///
/// No client secret is used here on purpose: this is registered in
/// Salesforce as a native/public client with PKCE required, and embedding a
/// secret in a distributed APK would defeat that protection.
class SalesforceOAuthConfig {
  SalesforceOAuthConfig._();

  // The Consumer Key of the "LMV" External Client App. Not secret by design
  // (OAuth client IDs for public/native clients are meant to be embedded),
  // so it's safe to default here. Override with
  // --dart-define=SF_CLIENT_ID=... if the app is ever repointed at a
  // different Connected/External Client App.
  static const String clientId = String.fromEnvironment(
    'SF_CLIENT_ID',
    defaultValue:
        '3MVG98_Psg5cppyZtiG_mopW_CieqXYH.MM61AUPuo1DZqFzqgmX8kTNrssZ2wvkqkYBsPQ2lAmQ4xM.7NuLI',
  );

  // DMs are Partner Community (Experience Cloud) users - they can only
  // authenticate through the TaroWorks community site. The base org My
  // Domain (taroworks-861.my.salesforce.com) rejects community users
  // outright at login.
  static const String loginBaseUrl = String.fromEnvironment(
    'SF_LOGIN_URL',
    defaultValue: 'https://taroworks-861.my.site.com/taroworks',
  );

  static const String authorizationEndpoint = '$loginBaseUrl/services/oauth2/authorize';
  static const String tokenEndpoint = '$loginBaseUrl/services/oauth2/token';

  // Salesforce's community-hosted OAuth fails to redirect directly to a
  // custom URL scheme (OAUTH_APPROVAL_ERROR_GENERIC, never leaves the
  // browser). Workaround: the actual OAuth redirect_uri is an HTTPS relay
  // page on our own backend, which immediately hands off to the app via
  // the custom scheme below - a plain webpage-to-deep-link hop that
  // Android handles natively. Must match the Callback URL configured on
  // the Salesforce External Client App.
  static const String redirectUrl = String.fromEnvironment(
    'SF_REDIRECT_URL',
    defaultValue: 'https://lmv-server-5nq7.onrender.com/oauthredirect',
  );

  // The custom scheme the relay page's JS redirect hands off to, and that
  // flutter_web_auth_2 waits for. Must match
  // android/app/build.gradle.kts's manifestPlaceholders["appAuthRedirectScheme"].
  static const String callbackUrlScheme = 'com.brac.learnerverificationapp';

  static const List<String> scopes = ['id', 'api', 'refresh_token', 'offline_access'];
}
