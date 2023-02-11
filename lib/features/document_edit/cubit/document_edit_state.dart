part of 'document_edit_cubit.dart';

class DocumentEditState extends Equatable {
  final DocumentModel document;

  final Map<int, Correspondent> correspondents;
  final Map<int, DocumentType> documentTypes;
  final Map<int, StoragePath> storagePaths;
  final Map<int, Tag> tags;

  const DocumentEditState({
    required this.correspondents,
    required this.documentTypes,
    required this.storagePaths,
    required this.tags,
    required this.document,
  });

  @override
  List<Object> get props => [
        correspondents,
        documentTypes,
        storagePaths,
        tags,
        document,
      ];

  DocumentEditState copyWith({
    Map<int, Correspondent>? correspondents,
    Map<int, DocumentType>? documentTypes,
    Map<int, StoragePath>? storagePaths,
    Map<int, Tag>? tags,
    DocumentModel? document,
  }) {
    return DocumentEditState(
      document: document ?? this.document,
      correspondents: correspondents ?? this.correspondents,
      documentTypes: documentTypes ?? this.documentTypes,
      storagePaths: storagePaths ?? this.storagePaths,
      tags: tags ?? this.tags,
    );
  }
}
