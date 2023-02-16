import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/repository/state/impl/document_type_repository_state.dart';
import 'package:paperless_mobile/features/edit_label/cubit/edit_label_cubit.dart';
import 'package:paperless_mobile/features/edit_label/view/add_label_page.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class AddDocumentTypePage extends StatelessWidget {
  final String? initialName;
  const AddDocumentTypePage({
    super.key,
    this.initialName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EditLabelCubit<DocumentType>(
        context.read<LabelRepository<DocumentType>>(),
      ),
      child: AddLabelPage<DocumentType>(
        pageTitle: Text(S.of(context)!.addDocumentType),
        fromJsonT: DocumentType.fromJson,
        initialName: initialName,
      ),
    );
  }
}
