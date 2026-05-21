import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/startup/tasks/appflowy_cloud_task.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:crypto/crypto.dart';
import 'package:url_launcher/url_launcher.dart';

const _kRedirectUri = 'appflowy-flutter://login-callback';

/// Holds the PKCE code verifier between the authorization request and the callback.
String? _pendingCodeVerifier;

String? getPendingCodeVerifier() => _pendingCodeVerifier;
void clearPendingCodeVerifier() => _pendingCodeVerifier = null;

class AuthentikAuthService implements AuthService {
  late final String _base;
  late final String _slug;
  late final String _clientId;

  AuthentikAuthService() {
    _base = Platform.environment['AUTHENTIK_BASE_URL'] ??
        'https://auth.osmosis.page';
    _slug = Platform.environment['AUTHENTIK_APP_SLUG'] ??
        _throwMissing('AUTHENTIK_APP_SLUG');
    _clientId = Platform.environment['AUTHENTIK_CLIENT_ID'] ??
        _throwMissing('AUTHENTIK_CLIENT_ID');
  }

  static Never _throwMissing(String varName) {
    throw StateError(
      'Required environment variable not set: $varName. '
      'Set it before launching the app.',
    );
  }

  @override
  Future<FlowyResult<UserProfilePB, FlowyError>> signUpWithOAuth({
    required String platform,
    Map<String, String> params = const {},
  }) async {

    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _computeCodeChallenge(codeVerifier);
    final state = _generateState();

    _pendingCodeVerifier = codeVerifier;

    final uri = Uri.parse(
      '$_base/application/o/$_slug/authorize/'
      '?response_type=code'
      '&client_id=$_clientId'
      '&redirect_uri=${Uri.encodeComponent(_kRedirectUri)}'
      '&scope=${Uri.encodeComponent("openid profile email offline_access")}'
      '&code_challenge=$codeChallenge'
      '&code_challenge_method=S256'
      '&state=$state',
    );

    final launched = await afLaunchUri(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_self',
    );

    final completer = Completer<FlowyResult<UserProfilePB, FlowyError>>();
    if (launched) {
      if (getIt.isRegistered<AppFlowyCloudDeepLink>()) {
        getIt<AppFlowyCloudDeepLink>().registerCompleter(completer);
      } else {
        completer.complete(
          FlowyResult.failure(
            FlowyError()..msg = 'AppFlowyCloudDeepLink is not registered',
          ),
        );
      }
    } else {
      _pendingCodeVerifier = null;
      completer.complete(
        FlowyResult.failure(FlowyError()..msg = 'Failed to launch Authentik'),
      );
    }

    return completer.future;
  }

  @override
  Future<void> signOut() async {
    await UserBackendService.signOut();
  }

  @override
  Future<FlowyResult<UserProfilePB, FlowyError>> getUser() async {
    return UserBackendService.getCurrentUserProfile();
  }

  // ── Unsupported methods ────────────────────────────────────────────

  @override
  Future<FlowyResult<GotrueTokenResponsePB, FlowyError>>
      signInWithEmailPassword({
    required String email,
    required String password,
    Map<String, String> params = const {},
  }) =>
          throw UnimplementedError('Email/password login is disabled');

  @override
  Future<FlowyResult<UserProfilePB, FlowyError>> signUp({
    required String name,
    required String email,
    required String password,
    Map<String, String> params = const {},
  }) =>
      throw UnimplementedError('Direct sign-up is disabled');

  @override
  Future<FlowyResult<UserProfilePB, FlowyError>> signUpAsGuest({
    Map<String, String> params = const {},
  }) =>
      throw UnimplementedError('Guest sign-in is disabled');

  @override
  Future<FlowyResult<void, FlowyError>> signInWithMagicLink({
    required String email,
    Map<String, String> params = const {},
  }) =>
      throw UnimplementedError('Magic link sign-in is disabled');

  @override
  Future<FlowyResult<GotrueTokenResponsePB, FlowyError>> signInWithPasscode({
    required String email,
    required String passcode,
  }) =>
      throw UnimplementedError('Passcode sign-in is disabled');
}

// ── PKCE helpers ────────────────────────────────────────────────────

String _generateCodeVerifier() {
  final rand = Random.secure();
  final bytes = List<int>.generate(64, (_) => rand.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}

String _computeCodeChallenge(String verifier) {
  final bytes = utf8.encode(verifier);
  final digest = sha256.convert(bytes);
  return base64UrlEncode(digest.bytes).replaceAll('=', '');
}

String _generateState() {
  final rand = Random.secure();
  final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}
