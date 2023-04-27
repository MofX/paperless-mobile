import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';

part 'document_upload_state.dart';

class DocumentUploadCubit extends Cubit<DocumentUploadState> {
  final PaperlessDocumentsApi _documentApi;

  final LabelRepository _labelRepository;

  DocumentUploadCubit(this._labelRepository, this._documentApi)
      : super(const DocumentUploadState()) {
    _labelRepository.addListener(
      this,
      onChanged: (labels) {
        emit(state.copyWith(
          correspondents: labels.correspondents,
          documentTypes: labels.documentTypes,
          tags: labels.tags,
        ));
      },
    );
  }

  Future<String?> upload(
    Uint8List bytes, {
    required String filename,
    required String title,
    int? documentType,
    int? correspondent,
    Iterable<int> tags = const [],
    DateTime? createdAt,
  }) async {
    return await _documentApi.create(
      bytes,
      filename: filename,
      title: title,
      correspondent: correspondent,
      documentType: documentType,
      tags: tags,
      createdAt: createdAt,
    );
  }

  @override
  Future<void> close() async {
    _labelRepository.removeListener(this);
    return super.close();
  }
}
