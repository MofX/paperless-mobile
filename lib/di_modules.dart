import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:paperless_mobile/core/interceptor/authentication.interceptor.dart';
import 'package:paperless_mobile/core/interceptor/connection_state.interceptor.dart';
import 'package:paperless_mobile/core/interceptor/language_header.interceptor.dart';
import 'package:paperless_mobile/core/interceptor/response_conversion.interceptor.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:http_interceptor/http/http.dart';
import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';

@module
abstract class RegisterModule {
  @singleton
  LocalAuthentication get localAuthentication => LocalAuthentication();
  @singleton
  EncryptedSharedPreferences get encryptedSharedPreferences => EncryptedSharedPreferences();
  @singleton
  SecurityContext get securityContext => SecurityContext();
  @singleton
  Connectivity get connectivity => Connectivity();

  ///
  /// Factory method creating an [HttpClient] with the currently registered [SecurityContext].
  ///
  HttpClient getHttpClient(SecurityContext securityContext) =>
      HttpClient(context: securityContext)..connectionTimeout = const Duration(seconds: 10);

  ///
  /// Factory method creating a [InterceptedClient] on top of the currently registered [HttpClient].
  ///
  BaseClient getBaseClient(
    AuthenticationInterceptor authInterceptor,
    ResponseConversionInterceptor responseConversionInterceptor,
    ConnectionStateInterceptor connectionStateInterceptor,
    LanguageHeaderInterceptor languageHeaderInterceptor,
    HttpClient client,
  ) =>
      InterceptedClient.build(
        interceptors: [
          authInterceptor,
          responseConversionInterceptor,
          connectionStateInterceptor,
          languageHeaderInterceptor
        ],
        client: IOClient(client),
      );

  CacheManager getCacheManager(BaseClient client) =>
      CacheManager(Config('cacheKey', fileService: HttpFileService(httpClient: client)));
}
