import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/features/edit_label/view/impl/add_correspondent_page.dart';
import 'package:paperless_mobile/features/edit_label/view/impl/add_document_type_page.dart';
import 'package:paperless_mobile/features/edit_label/view/impl/add_storage_path_page.dart';
import 'package:paperless_mobile/features/edit_label/view/impl/add_tag_page.dart';
import 'package:paperless_mobile/features/edit_label/view/impl/edit_correspondent_page.dart';
import 'package:paperless_mobile/features/edit_label/view/impl/edit_document_type_page.dart';
import 'package:paperless_mobile/features/edit_label/view/impl/edit_storage_path_page.dart';
import 'package:paperless_mobile/features/edit_label/view/impl/edit_tag_page.dart';
import 'package:paperless_mobile/features/labels/view/pages/labels_page.dart';
import 'package:paperless_mobile/features/linked_documents/cubit/linked_documents_cubit.dart';
import 'package:paperless_mobile/features/linked_documents/view/linked_documents_page.dart';
import 'package:paperless_mobile/routes/navigation_keys.dart';
import 'package:paperless_mobile/routes/routes.dart';

part 'labels_route.g.dart';

class LabelsBranch extends StatefulShellBranchData {
  static final GlobalKey<NavigatorState> $navigatorKey = labelsNavigatorKey;
  const LabelsBranch();
}

@TypedGoRoute<LabelsRoute>(
  path: "/labels",
  name: R.labels,
  routes: [
    TypedGoRoute<EditLabelRoute>(
      path: "edit",
      name: R.editLabel,
    ),
    TypedGoRoute<CreateLabelRoute>(
      path: "create",
      name: R.createLabel,
    ),
    TypedGoRoute<LinkedDocumentsRoute>(
      path: "linked-documents",
      name: R.linkedDocuments,
    ),
  ],
)
class LabelsRoute extends GoRouteData {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const LabelsPage();
  }
}

class EditLabelRoute extends GoRouteData {
  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  final Label $extra;

  const EditLabelRoute(this.$extra);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return switch ($extra) {
      Correspondent c => EditCorrespondentPage(correspondent: c),
      DocumentType d => EditDocumentTypePage(documentType: d),
      Tag t => EditTagPage(tag: t),
      StoragePath s => EditStoragePathPage(storagePath: s),
    };
  }
}

class CreateLabelRoute extends GoRouteData {
  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;
  final LabelType $extra;
  final String? name;

  CreateLabelRoute(
    this.$extra, {
    this.name,
  });

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return switch ($extra) {
      LabelType.correspondent => AddCorrespondentPage(initialName: name),
      LabelType.documentType => AddDocumentTypePage(initialName: name),
      LabelType.tag => AddTagPage(initialName: name),
      LabelType.storagePath => AddStoragePathPage(initialName: name),
    };
  }
}

class LinkedDocumentsRoute extends GoRouteData {
  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;
  final DocumentFilter $extra;

  const LinkedDocumentsRoute(this.$extra);
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return BlocProvider(
      create: (context) => LinkedDocumentsCubit(
        $extra,
        context.read(),
        context.read(),
        context.read(),
        context.read(),
      ),
      child: const LinkedDocumentsPage(),
    );
  }
}
