import 'package:dio/dio.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_api/src/extensions/dio_exception_extension.dart';
import 'package:paperless_api/src/models/paperless_api_exception.dart';

class PaperlessUserApiV2Impl implements PaperlessUserApi {
  final Dio client;

  PaperlessUserApiV2Impl(this.client);

  @override
  Future<int> findCurrentUserId() async {
    try {
      final response = await client.get(
        "/api/ui_settings/",
        options: Options(
          validateStatus: (status) => status == 200,
        ),
      );
      return response.data['user_id'];
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(ErrorCode.userNotFound),
      );
    }
  }

  @override
  Future<UserModel> findCurrentUser() async {
    try {
      final response = await client.get(
        "/api/ui_settings/",
        options: Options(validateStatus: (status) => status == 200),
      );
      return UserModelV2.fromJson(response.data);
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(ErrorCode.userNotFound),
      );
    }
  }
}
