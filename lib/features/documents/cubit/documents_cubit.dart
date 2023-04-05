import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/notifier/document_changed_notifier.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/features/paged_document_view/cubit/document_paging_bloc_mixin.dart';
import 'package:paperless_mobile/features/paged_document_view/cubit/paged_documents_state.dart';
import 'package:paperless_mobile/features/settings/model/view_type.dart';

part 'documents_cubit.g.dart';
part 'documents_state.dart';

class DocumentsCubit extends HydratedCubit<DocumentsState>
    with DocumentPagingBlocMixin {
  @override
  final PaperlessDocumentsApi api;

  final LabelRepository _labelRepository;

  @override
  final DocumentChangedNotifier notifier;

  DocumentsCubit(this.api, this.notifier, this._labelRepository)
      : super(DocumentsState(
          correspondents: _labelRepository.state.correspondents,
          documentTypes: _labelRepository.state.documentTypes,
          storagePaths: _labelRepository.state.storagePaths,
          tags: _labelRepository.state.tags,
        )) {
    notifier.addListener(
      this,
      onUpdated: (document) {
        replace(document);
        emit(
          state.copyWith(
            selection: state.selection
                .map((e) => e.id == document.id ? document : e)
                .toList(),
          ),
        );
      },
      onDeleted: (document) {
        remove(document);
        emit(
          state.copyWith(
            selection:
                state.selection.where((e) => e.id != document.id).toList(),
          ),
        );
      },
    );
    _labelRepository.addListener(
      this,
      onChanged: (labels) => emit(
        state.copyWith(
          correspondents: labels.correspondents,
          documentTypes: labels.documentTypes,
          storagePaths: labels.storagePaths,
          tags: labels.tags,
        ),
      ),
    );
  }

  Future<void> bulkDelete(List<DocumentModel> documents) async {
    debugPrint("[DocumentsCubit] bulkRemove");
    await api.bulkAction(
      BulkDeleteAction(documents.map((doc) => doc.id)),
    );
    for (final deletedDoc in documents) {
      notifier.notifyDeleted(deletedDoc);
    }
    await reload();
  }

  void toggleDocumentSelection(DocumentModel model) {
    debugPrint("[DocumentsCubit] toggleSelection");
    if (state.selectedIds.contains(model.id)) {
      emit(
        state.copyWith(
          selection: state.selection
              .where((element) => element.id != model.id)
              .toList(),
        ),
      );
    } else {
      emit(state.copyWith(selection: [...state.selection, model]));
    }
  }

  void resetSelection() {
    debugPrint("[DocumentsCubit] resetSelection");
    emit(state.copyWith(selection: []));
  }

  void reset() {
    debugPrint("[DocumentsCubit] reset");
    emit(const DocumentsState());
  }

  Future<Iterable<String>> autocomplete(String query) async {
    final res = await api.autocomplete(query);
    return res;
  }

  @override
  DocumentsState? fromJson(Map<String, dynamic> json) {
    return DocumentsState.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(DocumentsState state) {
    return state.toJson();
  }

  @override
  Future<void> close() {
    notifier.removeListener(this);
    _labelRepository.removeListener(this);
    return super.close();
  }

  void setViewType(ViewType viewType) {
    emit(state.copyWith(viewType: viewType));
  }
}
