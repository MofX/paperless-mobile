// ignore_for_file: non_constant_identifier_names

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:paperless_api/src/converters/local_date_time_json_converter.dart';
import 'package:paperless_api/src/models/search_hit.dart';

part 'document_model.g.dart';

@LocalDateTimeJsonConverter()
@JsonSerializable(fieldRename: FieldRename.snake)
class DocumentModel extends Equatable {
  static const idKey = 'id';
  static const titleKey = 'title';
  static const contentKey = 'content';
  static const archivedFileNameKey = 'archived_file_name';
  static const asnKey = 'archive_serial_number';
  static const createdKey = 'created';
  static const modifiedKey = 'modified';
  static const addedKey = 'added';
  static const correspondentKey = 'correspondent';
  static const originalFileNameKey = 'original_file_name';
  static const documentTypeKey = 'document_type';
  static const tagsKey = 'tags';
  static const storagePathKey = 'storage_path';

  final int id;
  final String title;
  final String? content;
  final Iterable<int> tags;
  final int? documentType;
  final int? correspondent;
  final int? storagePath;
  final DateTime created;
  final DateTime modified;
  final DateTime added;
  final int? archiveSerialNumber;
  final String originalFileName;
  final String? archivedFileName;

  @JsonKey(
    name: '__search_hit__',
    includeIfNull: false,
  )
  final SearchHit? searchHit;

  const DocumentModel({
    required this.id,
    required this.title,
    this.content,
    this.tags = const <int>[],
    required this.documentType,
    required this.correspondent,
    required this.created,
    required this.modified,
    required this.added,
    this.archiveSerialNumber,
    required this.originalFileName,
    this.archivedFileName,
    this.storagePath,
    this.searchHit,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) =>
      _$DocumentModelFromJson(json);

  Map<String, dynamic> toJson() => _$DocumentModelToJson(this);

  DocumentModel copyWith({
    String? title,
    String? content,
    Iterable<int>? tags,
    int? Function()? documentType,
    int? Function()? correspondent,
    int? Function()? storagePath,
    DateTime? created,
    DateTime? modified,
    DateTime? added,
    int? archiveSerialNumber,
    String? originalFileName,
    String? archivedFileName,
  }) {
    return DocumentModel(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      documentType:
          documentType != null ? documentType.call() : this.documentType,
      correspondent:
          correspondent != null ? correspondent.call() : this.correspondent,
      storagePath: storagePath != null ? storagePath.call() : this.storagePath,
      tags: tags ?? this.tags,
      created: created ?? this.created,
      modified: modified ?? this.modified,
      added: added ?? this.added,
      originalFileName: originalFileName ?? this.originalFileName,
      archiveSerialNumber: archiveSerialNumber ?? this.archiveSerialNumber,
      archivedFileName: archivedFileName ?? this.archivedFileName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        content.hashCode,
        tags,
        documentType,
        storagePath,
        correspondent,
        created,
        modified,
        added,
        archiveSerialNumber,
        originalFileName,
        archivedFileName,
        storagePath,
      ];
}
