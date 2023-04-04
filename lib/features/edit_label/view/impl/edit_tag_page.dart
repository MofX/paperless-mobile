import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/widgets/form_builder_fields/form_builder_color_picker.dart';
import 'package:paperless_mobile/features/edit_label/cubit/edit_label_cubit.dart';
import 'package:paperless_mobile/features/edit_label/view/edit_label_page.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class EditTagPage extends StatelessWidget {
  final Tag tag;

  const EditTagPage({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EditLabelCubit(
        context.read(),
      ),
      child: EditLabelPage<Tag>(
        label: tag,
        fromJsonT: Tag.fromJson,
        onSubmit: (context, label) =>
            context.read<EditLabelCubit>().addTag(label),
        onDelete: (context, label) =>
            context.read<EditLabelCubit>().removeTag(label),
        additionalFields: [
          FormBuilderColorPickerField(
            initialValue: tag.color,
            name: Tag.colorKey,
            decoration: InputDecoration(
              label: Text(S.of(context)!.color),
            ),
            colorPickerType: ColorPickerType.blockPicker,
          ),
          FormBuilderCheckbox(
            initialValue: tag.isInboxTag,
            name: Tag.isInboxTagKey,
            title: Text(S.of(context)!.inboxTag),
          ),
        ],
      ),
    );
  }
}
