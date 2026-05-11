import 'package:dio/dio.dart';

class MicrosoftAPI {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://graph.microsoft.com/v1.0',
  ));

  Future<Response> getUserDetails({required String token}) async {
    return await _dio.get(
      '/me',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  Future<Response> getProfileImage({required String token}) async {
    return await _dio.get(
      '/me/photo/\$value',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
        responseType: ResponseType.bytes,
      ),
    );
  }
}
