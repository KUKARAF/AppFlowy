import 'dart:convert';
import 'dart:io';

import 'package:appflowy/startup/tasks/deeplink/deeplink_handler.dart';
import 'package:appflowy/user/application/auth/authentik_auth_service.dart';
import 'package:appflowy/user/application/auth/device_id.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:http/http.dart' as http;

const _kRedirectUri = 'appflowy-flutter://login-callback';

/// Handles the Authentik authorization-code callback deep link.
/// Expects a URI with `code` and `state` query parameters.
class AuthentikDeepLinkHandler extends DeepLinkHandler<UserProfilePB> {
  @override
  bool canHandle(Uri uri) =>
      uri.queryParameters.containsKey('code') &&
      uri.queryParameters.containsKey('state');

  @override
  Future<FlowyResult<UserProfilePB, FlowyError>> handle({
    required Uri uri,
    required DeepLinkStateHandler onStateChange,
  }) async {
    onStateChange(this, DeepLinkState.loading);

    final code = uri.queryParameters['code']!;
    final codeVerifier = getPendingCodeVerifier();
    clearPendingCodeVerifier();

    if (codeVerifier == null) {
      onStateChange(this, DeepLinkState.error);
      return FlowyResult.failure(
        FlowyError()
          ..msg =
              'No PKCE code verifier found — did the auth flow start correctly?',
      );
    }

    final tokenResult = await _exchangeCodeForToken(code, codeVerifier);
    if (tokenResult.isFailure) {
      onStateChange(this, DeepLinkState.error);
      return FlowyResult.failure(tokenResult.getFailure());
    }

    late final String accessToken;
    tokenResult.fold(
      (token) { accessToken = token; },
      (_) { },
    );
    final deviceId = await getDeviceId();

    final payload = OauthSignInPB(
      authType: AuthTypePB.Server,
      map: {
        'authentik_access_token': accessToken,
        'device_id': deviceId,
      },
    );

    final result = await UserEventOauthSignIn(payload).send();
    onStateChange(this, DeepLinkState.finish);
    return result;
  }

  Future<FlowyResult<String, FlowyError>> _exchangeCodeForToken(
    String code,
    String codeVerifier,
  ) async {
    final base = Platform.environment['AUTHENTIK_BASE_URL'] ??
        'https://auth.osmosis.page';
    final slug = Platform.environment['AUTHENTIK_APP_SLUG'];
    final clientId = Platform.environment['AUTHENTIK_CLIENT_ID'];

    if (slug == null || slug.isEmpty) {
      return FlowyResult.failure(
        FlowyError()
          ..msg = 'AUTHENTIK_APP_SLUG environment variable not set',
      );
    }
    if (clientId == null || clientId.isEmpty) {
      return FlowyResult.failure(
        FlowyError()
          ..msg = 'AUTHENTIK_CLIENT_ID environment variable not set',
      );
    }

    try {
      final response = await http.post(
        Uri.parse('$base/application/o/$slug/token/'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': _kRedirectUri,
          'client_id': clientId,
          'code_verifier': codeVerifier,
        },
      );

      if (response.statusCode != 200) {
        Log.error(
          'Authentik token exchange failed: ${response.statusCode} ${response.body}',
        );
        return FlowyResult.failure(
          FlowyError()
            ..msg = 'Token exchange failed: ${response.statusCode}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final accessToken = json['access_token'] as String?;
      if (accessToken == null) {
        return FlowyResult.failure(
          FlowyError()..msg = 'No access_token in Authentik response',
        );
      }

      return FlowyResult.success(accessToken);
    } catch (e) {
      Log.error('Authentik token exchange error: $e');
      return FlowyResult.failure(
        FlowyError()..msg = 'Token exchange error: $e',
      );
    }
  }
}
