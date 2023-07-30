import 'package:animations/animations.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';
import 'package:paperless_mobile/core/workarounds/colored_chip.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/fullscreen_tags_form.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class TagsFormField extends StatelessWidget {
  final String name;
  final Map<int, Tag> options;
  final TagsQuery? initialValue;
  final bool allowOnlySelection;
  final bool allowCreation;
  final bool allowExclude;

  const TagsFormField({
    super.key,
    required this.options,
    this.initialValue,
    required this.name,
    required this.allowOnlySelection,
    required this.allowCreation,
    required this.allowExclude,
  });

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<TagsQuery?>(
      initialValue: initialValue,
      builder: (field) {
        final values = _generateOptions(context, field.value, field).toList();
        final isEmpty = (field.value is IdsTagsQuery &&
                (field.value as IdsTagsQuery).include.isEmpty) ||
            field.value == null;
        bool anyAssigned = field.value is AnyAssignedTagsQuery;
        return OpenContainer<TagsQuery>(
          middleColor: Theme.of(context).colorScheme.background,
          closedColor: Theme.of(context).colorScheme.background,
          openColor: Theme.of(context).colorScheme.background,
          closedShape: InputBorder.none,
          openElevation: 0,
          closedElevation: 0,
          closedBuilder: (context, openForm) => Container(
              margin: const EdgeInsets.only(top: 6),
              child: GestureDetector(
                onTap: openForm,
                child: InputDecorator(
                  isEmpty: isEmpty,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(12),
                    labelText:
                        '${S.of(context)!.tags}${anyAssigned ? ' (${S.of(context)!.anyAssigned})' : ''}',
                    prefixIcon: const Icon(Icons.label_outline),
                  ),
                  child: SizedBox(
                    height: 32,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 4),
                      itemBuilder: (context, index) => values[index],
                      itemCount: values.length,
                    ),
                  ),
                ),
              )),
          openBuilder: (context, closeForm) => FullscreenTagsForm(
            options: options,
            onSubmit: closeForm,
            initialValue: field.value,
            allowOnlySelection: allowOnlySelection,
            allowCreation: allowCreation &&
                context.watch<LocalUserAccount>().paperlessUser.canCreateTags,
            allowExclude: allowExclude,
          ),
          onClosed: (data) {
            if (data != null) {
              field.didChange(data);
            }
          },
        );
      },
      name: name,
    );
  }

  Iterable<Widget> _generateOptions(
    BuildContext context,
    TagsQuery? query,
    FormFieldState<TagsQuery?> field,
  ) sync* {
    if (query == null) {
      yield Container();
    } else {
      final widgets = query.map(
        ids: (value) => [
          for (var inc in value.include)
            _buildTagIdQueryWidget(context, inc, field, false),
          for (var exc in value.exclude)
            _buildTagIdQueryWidget(context, exc, field, true),
        ],
        anyAssigned: (value) => [
          for (var id in value.tagIds)
            _buildAnyAssignedTagWidget(context, id, field, value),
        ],
        notAssigned: (value) => [_buildNotAssignedTagWidget(context, field)],
      );
      for (var child in widgets) {
        yield child;
      }
    }
  }

  Widget _buildTagIdQueryWidget(
    BuildContext context,
    int id,
    FormFieldState<TagsQuery?> field,
    bool exclude,
  ) {
    assert(field.value is IdsTagsQuery);
    final formValue = field.value as IdsTagsQuery;
    final tag = options[id]!;
    return QueryTagChip(
      onDeleted: () => field.didChange(formValue.copyWith(
        include:
            formValue.include.whereNot((element) => element == id).toList(),
        exclude:
            formValue.exclude.whereNot((element) => element == id).toList(),
      )),
      onSelected: allowExclude
          ? () {
              if (formValue.include.contains(id)) {
                field.didChange(
                  formValue.copyWith(
                    include: formValue.include
                        .whereNot((element) => element == id)
                        .toList(),
                    exclude: [...formValue.exclude, id],
                  ),
                );
              } else if (formValue.exclude.contains(id)) {}
              field.didChange(
                formValue.copyWith(
                  include: [...formValue.include, id],
                  exclude: formValue.exclude
                      .whereNot((element) => element == id)
                      .toList(),
                ),
              );
            }
          : null,
      exclude: exclude,
      backgroundColor: tag.color,
      foregroundColor: tag.textColor,
      labelText: tag.name,
    );
  }

  Widget _buildNotAssignedTagWidget(
    BuildContext context,
    FormFieldState<TagsQuery?> field,
  ) {
    return QueryTagChip(
      onDeleted: () => field.didChange(null),
      exclude: false,
      backgroundColor: Colors.grey,
      foregroundColor: Colors.black,
      labelText: S.of(context)!.notAssigned,
    );
  }

  Widget _buildAnyAssignedTagWidget(
    BuildContext context,
    int e,
    FormFieldState<TagsQuery?> field,
    AnyAssignedTagsQuery query,
  ) {
    return QueryTagChip(
      onDeleted: () {
        final updatedQuery = query.copyWith(
          tagIds: query.tagIds.whereNot((element) => element == e).toList(),
        );
        if (updatedQuery.tagIds.isEmpty) {
          field.didChange(const TagsQuery.ids());
        } else {
          field.didChange(updatedQuery);
        }
      },
      exclude: false,
      backgroundColor: options[e]!.color,
      foregroundColor: options[e]!.textColor,
      labelText: options[e]!.name,
    );
  }
}

typedef TagQueryCallback = void Function(Tag tag);

class QueryTagChip extends StatelessWidget {
  final VoidCallback onDeleted;
  final VoidCallback? onSelected;
  final bool exclude;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String labelText;

  const QueryTagChip({
    super.key,
    required this.onDeleted,
    this.onSelected,
    required this.exclude,
    this.backgroundColor,
    this.foregroundColor,
    required this.labelText,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredChipWrapper(
      child: InputChip(
        labelPadding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 2,
        ),
        padding: const EdgeInsets.all(4),
        selectedColor: backgroundColor,
        visualDensity: const VisualDensity(vertical: -2),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        label: Text(
          labelText,
          style: TextStyle(
            color: foregroundColor,
            decorationColor: foregroundColor,
            decoration: exclude ? TextDecoration.lineThrough : null,
          ),
        ),
        onDeleted: onDeleted,
        onPressed: onSelected,
        deleteIconColor: foregroundColor,
        checkmarkColor: foregroundColor,
        backgroundColor: backgroundColor,
        side: BorderSide.none,
      ),
    );
  }
}
