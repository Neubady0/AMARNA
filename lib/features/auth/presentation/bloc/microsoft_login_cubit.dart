import 'package:aad_oauth/aad_oauth.dart';
import 'package:aad_oauth/model/config.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import 'package:amarnamovil/features/auth/data/data_sources/microsoft_api.dart';
import 'package:amarnamovil/features/auth/data/data_sources/auth_service.dart';
import 'microsoft_login_state.dart';

class AuthCubit extends Cubit<AuthState> {
  late AadOAuth oauth;

  AuthCubit() : super(AuthInitial()) {
    final Config config = Config(
      tenant: '481fa64d-78ed-4ec6-ba40-c327c2b194f6',
      clientId: '909fa834-268c-4e58-95e9-f9a81c892146',
      scope: 'openid profile offline_access User.Read',
      redirectUri: 'https://login.microsoftonline.com/common/oauth2/nativeclient',
      navigatorKey: navigatorKey,
    );
    oauth = AadOAuth(config);
  }

  Future<void> login() async {
    emit(AuthLoading());
    try {
      await oauth.login();
      final accessToken = await oauth.getAccessToken();

      if (accessToken == null) {
        emit(AuthError("Access token is null. Login failed."));
        return;
      }

      try {
        Response jsonResponse = await MicrosoftAPI().getUserDetails(token: accessToken);
        final Map<String, dynamic> userData = jsonResponse.data;
        
        final String name = userData['displayName'] ?? 'Name Not Available';
        final String email = userData['mail'] ?? userData['userPrincipalName'] ?? 'Email Not Available';
        final String mobilePhone = userData['mobilePhone'] ?? 'MobilePhone Not Available';
        final String jobTitle = userData['jobTitle'] ?? 'JobTitle Not Available';
        final String officeLocation = userData['officeLocation'] ?? 'OfficeLocation Not Available';
        final String department = userData['department'] ?? 'Department Not Available';

        Uint8List? photo;
        try {
          Response photoResponse = await MicrosoftAPI().getProfileImage(token: accessToken);
          if (photoResponse.data != null && photoResponse.data is List<int>) {
            photo = Uint8List.fromList(photoResponse.data);
          }
        } catch (e) {
          debugPrint("Profile photo not available or error fetching: $e");
        }

        emit(AuthSuccess(photo, name, email, mobilePhone, jobTitle, officeLocation, department));
      } catch (apiError) {
        debugPrint("Error fetching user details: $apiError");
        emit(AuthError("Failed to fetch user details."));
      }
    } catch (e) {
      debugPrint("Login Error: $e");
      emit(AuthError("Login failed. Please try again."));
    }
  }

  Future<void> logout() async {
    try {
      await oauth.logout();
      emit(AuthInitial());
    } catch (e) {
      emit(AuthError("Logout failed. Please try again."));
    }
  }
}
