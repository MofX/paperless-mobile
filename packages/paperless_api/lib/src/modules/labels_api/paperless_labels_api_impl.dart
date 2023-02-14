import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:paperless_api/src/models/labels/correspondent_model.dart';
import 'package:paperless_api/src/models/labels/document_type_model.dart';
import 'package:paperless_api/src/models/labels/storage_path_model.dart';
import 'package:paperless_api/src/models/labels/tag_model.dart';
import 'package:paperless_api/src/models/paperless_server_exception.dart';
import 'package:paperless_api/src/modules/labels_api/paperless_labels_api.dart';
import 'package:paperless_api/src/request_utils.dart';

//Notes:
// Removed content type json header
class PaperlessLabelApiImpl implements PaperlessLabelsApi {
  final Dio _client;

  PaperlessLabelApiImpl(this._client);
  @override
  Future<Correspondent?> getCorrespondent(int id) async {
    return getSingleResult(
      "/api/correspondents/$id/",
      Correspondent.fromJson,
      ErrorCode.correspondentLoadFailed,
      client: _client,
    );
  }

  @override
  Future<Tag?> getTag(int id) async {
    return getSingleResult(
      "/api/tags/$id/",
      Tag.fromJson,
      ErrorCode.tagLoadFailed,
      client: _client,
    );
  }

  @override
  Future<List<Tag>> getTags([Iterable<int>? ids]) async {
    final results = await getCollection(
      "/api/tags/?page=1&page_size=100000",
      Tag.fromJson,
      ErrorCode.tagLoadFailed,
      client: _client,
      minRequiredApiVersion: 2,
    );
    return results
        .where((element) => ids?.contains(element.id) ?? true)
        .toList();
  }

  @override
  Future<DocumentType?> getDocumentType(int id) async {
    return getSingleResult(
      "/api/document_types/$id/",
      DocumentType.fromJson,
      ErrorCode.documentTypeLoadFailed,
      client: _client,
    );
  }

  @override
  Future<List<Correspondent>> getCorrespondents([Iterable<int>? ids]) async {
    final results = await getCollection(
      "/api/correspondents/?page=1&page_size=100000",
      Correspondent.fromJson,
      ErrorCode.correspondentLoadFailed,
      client: _client,
    );

    return results
        .where((element) => ids?.contains(element.id) ?? true)
        .toList();
  }

  @override
  Future<List<DocumentType>> getDocumentTypes([Iterable<int>? ids]) async {
    final results = await getCollection(
      "/api/document_types/?page=1&page_size=100000",
      DocumentType.fromJson,
      ErrorCode.documentTypeLoadFailed,
      client: _client,
    );

    return results
        .where((element) => ids?.contains(element.id) ?? true)
        .toList();
  }

  @override
  Future<Correspondent> saveCorrespondent(Correspondent correspondent) async {
    try {
      final response = await _client.post(
        '/api/correspondents/',
        data: correspondent.toJson(),
      );
      if (response.statusCode == HttpStatus.created) {
        return Correspondent.fromJson(response.data);
      }
      throw PaperlessServerException(
        ErrorCode.correspondentCreateFailed,
        httpStatusCode: response.statusCode,
      );
    } on DioError catch (err) {
      throw err.error!;
    }
  }

  @override
  Future<DocumentType> saveDocumentType(DocumentType type) async {
    try {
      final response = await _client.post(
        '/api/document_types/',
        data: type.toJson(),
      );
      if (response.statusCode == HttpStatus.created) {
        return DocumentType.fromJson(response.data);
      }
      throw PaperlessServerException(
        ErrorCode.documentTypeCreateFailed,
        httpStatusCode: response.statusCode,
      );
    } on DioError catch (err) {
      throw err.error!;
    }
  }

  @override
  Future<Tag> saveTag(Tag tag) async {
    try {
      final response = await _client.post(
        '/api/tags/',
        data: tag.toJson(),
        options: Options(headers: {"Accept": "application/json; version=2"}),
      );
      if (response.statusCode == HttpStatus.created) {
        return Tag.fromJson(response.data);
      }
      throw PaperlessServerException(
        ErrorCode.tagCreateFailed,
        httpStatusCode: response.statusCode,
      );
    } on DioError catch (err) {
      throw err.error!;
    }
  }

  @override
  Future<int> deleteCorrespondent(Correspondent correspondent) async {
    assert(correspondent.id != null);
    try {
      final response =
          await _client.delete('/api/correspondents/${correspondent.id}/');
      if (response.statusCode == HttpStatus.noContent) {
        return correspondent.id!;
      }
      throw PaperlessServerException(
        ErrorCode.unknown,
        httpStatusCode: response.statusCode,
      );
    } on DioError catch (err) {
      throw err.error!;
    }
  }

  @override
  Future<int> deleteDocumentType(DocumentType documentType) async {
    assert(documentType.id != null);
    try {
      final response =
          await _client.delete('/api/document_types/${documentType.id}/');
      if (response.statusCode == HttpStatus.noContent) {
        return documentType.id!;
      }
      throw PaperlessServerException(
        ErrorCode.unknown,
        httpStatusCode: response.statusCode,
      );
    } on DioError catch (err) {
      throw err.error!;
    }
  }

  @override
  Future<int> deleteTag(Tag tag) async {
    assert(tag.id != null);
    try {
      final response = await _client.delete('/api/tags/${tag.id}/');
      if (response.statusCode == HttpStatus.noContent) {
        return tag.id!;
      }
      throw PaperlessServerException(
        ErrorCode.unknown,
        httpStatusCode: response.statusCode,
      );
    } on DioError catch (err) {
      throw err.error!;
    }
  }

  @override
  Future<Correspondent> updateCorrespondent(Correspondent correspondent) async {
    assert(correspondent.id != null);
    try {
      final response = await _client.put(
        '/api/correspondents/${correspondent.id}/',
        data: json.encode(correspondent.toJson()),
      );
      if (response.statusCode == HttpStatus.ok) {
        return Correspondent.fromJson(response.data);
      }
      throw PaperlessServerException(
        ErrorCode.unknown, //TODO: Add correct error code mapping.
        httpStatusCode: response.statusCode,
      );
    } on DioError catch (err) {
      throw err.error!;
    }
  }

  @override
  Future<DocumentType> updateDocumentType(DocumentType documentType) async {
    assert(documentType.id != null);
    try {
      final response = await _client.put(
        '/api/document_types/${documentType.id}/',
        data: documentType.toJson(),
      );
      if (response.statusCode == HttpStatus.ok) {
        return DocumentType.fromJson(response.data);
      }
      throw PaperlessServerException(
        ErrorCode.unknown,
        httpStatusCode: response.statusCode,
      );
    } on DioError catch (err) {
      throw err.error!;
    }
  }

  @override
  Future<Tag> updateTag(Tag tag) async {
    assert(tag.id != null);
    try {
      final response = await _client.put(
        '/api/tags/${tag.id}/',
        options: Options(headers: {"Accept": "application/json; version=2"}),
        data: tag.toJson(),
      );
      if (response.statusCode == HttpStatus.ok) {
        return Tag.fromJson(response.data);
      }
      throw PaperlessServerException(
        ErrorCode.unknown,
        httpStatusCode: response.statusCode,
      );
    } on DioError catch (err) {
      throw err.error!;
    }
  }

  @override
  Future<int> deleteStoragePath(StoragePath path) async {
    assert(path.id != null);
    try {
      final response = await _client.delete('/api/storage_paths/${path.id}/');
      if (response.statusCode == HttpStatus.noContent) {
        return path.id!;
      }
      throw PaperlessServerException(
        ErrorCode.unknown,
        httpStatusCode: response.statusCode,
      );
    } on DioError catch (err) {
      throw err.error!;
    }
  }

  @override
  Future<StoragePath?> getStoragePath(int id) {
    return getSingleResult(
      "/api/storage_paths/$id/",
      StoragePath.fromJson,
      ErrorCode.storagePathLoadFailed,
      client: _client,
    );
  }

  @override
  Future<List<StoragePath>> getStoragePaths([Iterable<int>? ids]) async {
    final results = await getCollection(
      "/api/storage_paths/?page=1&page_size=100000",
      StoragePath.fromJson,
      ErrorCode.storagePathLoadFailed,
      client: _client,
    );

    return results
        .where((element) => ids?.contains(element.id) ?? true)
        .toList();
  }

  @override
  Future<StoragePath> saveStoragePath(StoragePath path) async {
    try {
      final response = await _client.post(
        '/api/storage_paths/',
        data: path.toJson(),
      );
      if (response.statusCode == HttpStatus.created) {
        return StoragePath.fromJson(response.data);
      }
      throw PaperlessServerException(
        ErrorCode.storagePathCreateFailed,
        httpStatusCode: response.statusCode,
      );
    } on DioError catch (err) {
      throw err.error!;
    }
  }

  @override
  Future<StoragePath> updateStoragePath(StoragePath path) async {
    assert(path.id != null);
    try {
      final response = await _client.put(
        '/api/storage_paths/${path.id}/',
        data: path.toJson(),
      );
      if (response.statusCode == HttpStatus.ok) {
        return StoragePath.fromJson(response.data);
      }
      throw const PaperlessServerException(ErrorCode.unknown);
    } on DioError catch (err) {
      throw err.error!;
    }
  }
}
