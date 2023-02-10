import 'package:flutter/material.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/features/documents/cubit/documents_state.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class BulkDeleteConfirmationDialog extends StatelessWidget {
  final DocumentsState state;
  const BulkDeleteConfirmationDialog({
    Key? key,
    required this.state,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    assert(state.selection.isNotEmpty);
    return AlertDialog(
      title: Text(S.of(context).documentsPageSelectionBulkDeleteDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            //TODO: use plurals, didn't use because of crash... investigate later.
            state.selection.length == 1
                ? S
                    .of(context)
                    .documentsPageSelectionBulkDeleteDialogWarningTextOne
                : S
                    .of(context)
                    .documentsPageSelectionBulkDeleteDialogWarningTextMany,
          ),
          const SizedBox(height: 16),
          ...state.selection.map(_buildBulletPoint).toList(),
          const SizedBox(height: 16),
          Text(
              S.of(context).documentsPageSelectionBulkDeleteDialogContinueText),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(S.of(context).genericActionCancelLabel),
        ),
        TextButton(
          style: ButtonStyle(
            foregroundColor:
                MaterialStateProperty.all(Theme.of(context).colorScheme.error),
          ),
          onPressed: () {
            Navigator.pop(context, true);
          },
          child: Text(S.of(context).genericActionDeleteLabel),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(DocumentModel doc) {
    return ListTile(
      dense: true,
      title: Text(
        doc.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
