import 'package:dio/dio.dart';
import 'package:paperless_api/src/extensions/dio_exception_extension.dart';
import 'package:paperless_api/src/models/paperless_api_exception.dart';
import 'package:paperless_api/src/models/paperless_server_information_model.dart';
import 'package:paperless_api/src/models/paperless_server_statistics_model.dart';
import 'package:paperless_api/src/models/paperless_ui_settings_model.dart';

import 'paperless_server_stats_api.dart';

///
/// API for retrieving information about paperless server state,
/// such as version number, and statistics including documents in
/// inbox and total number of documents.
///
class PaperlessServerStatsApiImpl implements PaperlessServerStatsApi {
  final Dio client;

  PaperlessServerStatsApiImpl(this.client);

  @override
  Future<PaperlessServerInformationModel> getServerInformation() async {
    try {
      final response = await client.get(
        "/api/remote_version/",
        options: Options(validateStatus: (status) => status == 200),
      );
      final version = response.data["version"] as String;
      final updateAvailable = response.data["update_available"] as bool;
      return PaperlessServerInformationModel(
        apiVersion: int.parse(response.headers.value('x-api-version')!),
        version: version,
        isUpdateAvailable: updateAvailable,
      );
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(
          ErrorCode.serverInformationLoadFailed,
        ),
      );
    }
  }

  @override
  Future<PaperlessServerStatisticsModel> getServerStatistics() async {
    try {
      final response = await client.get(
        '/api/statistics/',
        options: Options(validateStatus: (status) => status == 200),
      );
      return PaperlessServerStatisticsModel.fromJson(response.data);
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(
          ErrorCode.serverStatisticsLoadFailed,
        ),
      );
    }
  }

  @override
  Future<PaperlessUiSettingsModel> getUiSettings() async {
    try {
      final response = await client.get(
        "/api/ui_settings/",
        options: Options(validateStatus: (status) => status == 200),
      );
      return PaperlessUiSettingsModel.fromJson(response.data);
    } on DioException catch (exception) {
      throw exception.unravel(
        orElse: const PaperlessApiException(ErrorCode.uiSettingsLoadFailed),
      );
    }
  }
}
