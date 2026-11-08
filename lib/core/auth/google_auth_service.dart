import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../api/api_client.dart';

const googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
const googleIosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

class GoogleAuthService {
  GoogleAuthService._();

  static final GoogleAuthService instance = GoogleAuthService._();
  final GoogleSignIn _google = GoogleSignIn.instance;
  bool _initialized = false;

  Future<void> _initialize() async {
    if (_initialized) return;
    if (googleServerClientId.isEmpty) {
      throw ApiException(
        'Google sign-in needs GOOGLE_SERVER_CLIENT_ID at build time.',
      );
    }
    await _google.initialize(
      clientId:
          defaultTargetPlatform == TargetPlatform.iOS &&
              googleIosClientId.isNotEmpty
          ? googleIosClientId
          : null,
      serverClientId: googleServerClientId,
    );
    _initialized = true;
  }

  Future<Map<String, dynamic>> authenticate(ApiClient api) async {
    await _initialize();
    if (!_google.supportsAuthenticate()) {
      throw ApiException('Google sign-in is not supported on this device.');
    }
    try {
      final account = await _google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw ApiException(
          'Google did not return an identity token. Check the OAuth client configuration.',
        );
      }
      return api.googleLogin(idToken);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw ApiException('Google sign-in was cancelled.');
      }
      throw ApiException(error.description ?? 'Google sign-in failed.');
    }
  }

  Future<void> signOut() async {
    if (_initialized) await _google.signOut();
  }
}
