import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../config/salesforce_oauth_config.dart';
import 'api_client.dart';
import 'api_exception.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final _client = ApiClient.instance;

  /// Opens Salesforce's own hosted community login page (Authorization Code
  /// + PKCE, via the system browser) so the DM's credentials never touch
  /// this app or our backend. PKCE is done manually here (rather than via
  /// flutter_appauth's convenience method) because Salesforce's
  /// community-hosted OAuth can't redirect directly to a custom URL scheme -
  /// it redirects to an HTTPS relay page on our backend instead, which then
  /// hands off to this app via [SalesforceOAuthConfig.callbackUrlScheme].
  /// On success, hands the resulting Salesforce session to POST
  /// /auth/session, which returns our own opaque session token.
  Future<String> login() async {
    if (ApiConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      await _client.saveToken('mock-dm-token');
      await _client.saveDmName('Demo DM');
      await _client.saveDmUsername('demo.dm@example.com');
      return 'Demo DM';
    }

    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _codeChallengeFor(codeVerifier);
    final state = _generateCodeVerifier();

    final authorizeUri = Uri.parse(SalesforceOAuthConfig.authorizationEndpoint).replace(
      queryParameters: {
        'response_type': 'code',
        'client_id': SalesforceOAuthConfig.clientId,
        'redirect_uri': SalesforceOAuthConfig.redirectUrl,
        'scope': SalesforceOAuthConfig.scopes.join(' '),
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'state': state,
      },
    );

    final String resultUrl;
    try {
      resultUrl = await FlutterWebAuth2.authenticate(
        url: authorizeUri.toString(),
        callbackUrlScheme: SalesforceOAuthConfig.callbackUrlScheme,
      );
    } catch (e) {
      throw ApiException('Login was cancelled or failed to open: $e');
    }

    final resultParams = Uri.parse(resultUrl).queryParameters;
    if (resultParams['error'] != null) {
      throw ApiException(
        'Salesforce login failed: ${resultParams['error_description'] ?? resultParams['error']}',
      );
    }
    if (resultParams['state'] != state) {
      throw const ApiException('Login response did not match this request. Please try again.');
    }
    final code = resultParams['code'];
    if (code == null) {
      throw const ApiException('Salesforce did not return an authorization code.');
    }

    final tokenRes = await http.post(
      Uri.parse(SalesforceOAuthConfig.tokenEndpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'client_id': SalesforceOAuthConfig.clientId,
        'redirect_uri': SalesforceOAuthConfig.redirectUrl,
        'code_verifier': codeVerifier,
      },
    );
    final tokenData = jsonDecode(tokenRes.body) as Map<String, dynamic>;
    if (tokenRes.statusCode != 200) {
      throw ApiException(
        'Salesforce token exchange failed: ${tokenData['error_description'] ?? tokenData['error'] ?? tokenRes.statusCode}',
      );
    }

    final sfAccessToken = tokenData['access_token'] as String?;
    final instanceUrl = tokenData['instance_url'] as String?;
    if (sfAccessToken == null || instanceUrl == null) {
      throw const ApiException('Salesforce login did not return a valid session.');
    }

    final data = await _client.post(
      '/auth/session',
      body: {'accessToken': sfAccessToken, 'instanceUrl': instanceUrl},
      withAuth: false,
    );
    final token = data is Map ? data['token'] as String? : null;
    if (token == null) {
      throw const ApiException('Login response did not include a session token.');
    }
    await _client.saveToken(token);
    final dmName = (data['dmName'] as String?) ?? 'DM';
    await _client.saveDmName(dmName);
    final dmUsername = data['dmUsername'] as String?;
    if (dmUsername != null) await _client.saveDmUsername(dmUsername);
    return dmName;
  }

  Future<bool> isLoggedIn() async => (await _client.readToken()) != null;

  Future<String?> getDmName() => _client.readDmName();

  Future<String?> getDmUsername() => _client.readDmUsername();

  Future<void> logout() => _client.clearToken();

  String _generateCodeVerifier() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  String _codeChallengeFor(String codeVerifier) {
    final digest = sha256.convert(ascii.encode(codeVerifier));
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }
}
