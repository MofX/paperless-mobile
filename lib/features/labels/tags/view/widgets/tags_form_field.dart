import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/repository/state/impl/tag_repository_state.dart';
import 'package:paperless_mobile/core/workarounds/colored_chip.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/edit_label/view/impl/add_tag_page.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class TagFormField extends StatefulWidget {
  final TagsQuery? initialValue;
  final String name;
  final bool allowCreation;
  final bool notAssignedSelectable;
  final bool anyAssignedSelectable;
  final bool excludeAllowed;
  final Map<int, Tag> selectableOptions;
  final Widget? suggestions;

  const TagFormField({
    super.key,
    required this.name,
    this.initialValue,
    this.allowCreation = true,
    this.notAssignedSelectable = true,
    this.anyAssignedSelectable = true,
    this.excludeAllowed = true,
    required this.selectableOptions,
    this.suggestions,
  });

  @override
  State<TagFormField> createState() => _TagFormFieldState();
}

class _TagFormFieldState extends State<TagFormField> {
  static const _onlyNotAssignedId = -1;
  static const _anyAssignedId = -2;

  late final TextEditingController _textEditingController;
  bool _showCreationSuffixIcon = false;
  bool _showClearSuffixIcon = false;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController()
      ..addListener(() {
        setState(() {
          _showCreationSuffixIcon = widget.selectableOptions.values.where(
            (item) {
              log(item.name
                  .toLowerCase()
                  .startsWith(
                    _textEditingController.text.toLowerCase(),
                  )
                  .toString());
              return item.name.toLowerCase().startsWith(
                    _textEditingController.text.toLowerCase(),
                  );
            },
          ).isEmpty;
        });
        setState(
          () => _showClearSuffixIcon = _textEditingController.text.isNotEmpty,
        );
      });
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.selectableOptions.values.fold<bool>(
            false,
            (previousValue, element) =>
                previousValue || (element.documentCount ?? 0) > 0) ||
        widget.allowCreation;

    return FormBuilderField<TagsQuery>(
      enabled: isEnabled,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TypeAheadField<int>(
              textFieldConfiguration: TextFieldConfiguration(
                enabled: isEnabled,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.label_outline,
                  ),
                  suffixIcon: _buildSuffixIcon(context, field),
                  labelText: S.of(context)!.tags,
                  hintText: S.of(context)!.filterTags,
                ),
                controller: _textEditingController,
              ),
              suggestionsBoxDecoration: SuggestionsBoxDecoration(
                elevation: 4.0,
                shadowColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              suggestionsCallback: (query) {
                final suggestions = widget.selectableOptions.entries
                    .where(
                      (entry) => entry.value.name
                          .toLowerCase()
                          .startsWith(query.toLowerCase()),
                    )
                    .where((entry) =>
                        widget.allowCreation ||
                        (entry.value.documentCount ?? 0) > 0)
                    .map((entry) => entry.key)
                    .toList();
                if (field.value is IdsTagsQuery) {
                  suggestions.removeWhere((element) =>
                      (field.value as IdsTagsQuery).ids.contains(element));
                }
                if (widget.notAssignedSelectable &&
                    field.value is! OnlyNotAssignedTagsQuery) {
                  suggestions.insert(0, _onlyNotAssignedId);
                }
                if (widget.anyAssignedSelectable &&
                    field.value is! AnyAssignedTagsQuery) {
                  suggestions.insert(0, _anyAssignedId);
                }
                return suggestions;
              },
              getImmediateSuggestions: true,
              animationStart: 1,
              itemBuilder: (context, data) {
                late String? title;
                switch (data) {
                  case _onlyNotAssignedId:
                    title = S.of(context)!.notAssigned;
                    break;
                  case _anyAssignedId:
                    title = S.of(context)!.anyAssigned;
                    break;
                  default:
                    title = widget.selectableOptions[data]?.name;
                }

                final tag = widget.selectableOptions[data];
                return ListTile(
                  dense: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  style: ListTileStyle.list,
                  leading: data != _onlyNotAssignedId && data != _anyAssignedId
                      ? Icon(
                          Icons.circle,
                          color: tag?.color,
                        )
                      : null,
                  title: Text(
                    title ?? '',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onBackground),
                  ),
                );
              },
              onSuggestionSelected: (id) {
                if (id == _onlyNotAssignedId) {
                  //Not assigned tag
                  field.didChange(const OnlyNotAssignedTagsQuery());
                  return;
                } else if (id == _anyAssignedId) {
                  field.didChange(const AnyAssignedTagsQuery());
                } else {
                  final tagsQuery = field.value is IdsTagsQuery
                      ? field.value as IdsTagsQuery
                      : const IdsTagsQuery();
                  field.didChange(
                      tagsQuery.withIdQueriesAdded([IncludeTagIdQuery(id)]));
                }
                _textEditingController.clear();
              },
              direction: AxisDirection.up,
            ),
            if (field.value is OnlyNotAssignedTagsQuery) ...[
              _buildNotAssignedTag(field).padded()
            ] else if (field.value is AnyAssignedTagsQuery) ...[
              _buildAnyAssignedTag(field).padded()
            ] else ...[
              if (widget.suggestions != null) widget.suggestions!,
              // field.value is IdsTagsQuery
              Wrap(
                alignment: WrapAlignment.start,
                runAlignment: WrapAlignment.start,
                spacing: 4.0,
                runSpacing: 4.0,
                children: ((field.value as IdsTagsQuery).queries)
                    .map(
                      (query) => _buildTag(
                        field,
                        query,
                        widget.selectableOptions[query.id],
                      ),
                    )
                    .toList(),
              ).padded(),
            ]
          ],
        );
      },
      initialValue: widget.initialValue ?? const IdsTagsQuery(),
      name: widget.name,
    );
  }

  Widget? _buildSuffixIcon(
    BuildContext context,
    FormFieldState<TagsQuery> field,
  ) {
    if (_showCreationSuffixIcon && widget.allowCreation) {
      return IconButton(
        onPressed: () => _onAddTag(context, field),
        icon: const Icon(
          Icons.new_label,
        ),
      );
    }
    if (_showClearSuffixIcon) {
      return IconButton(
        icon: const Icon(Icons.clear),
        onPressed: _textEditingController.clear,
      );
    }
    return null;
  }

  void _onAddTag(BuildContext context, FormFieldState<TagsQuery> field) async {
    final Tag? tag = await Navigator.of(context).push<Tag>(
      MaterialPageRoute(
        builder: (_) => RepositoryProvider(
          create: (context) => context.read<LabelRepository<Tag>>(),
          child: AddTagPage(initialValue: _textEditingController.text),
        ),
      ),
    );
    if (tag != null) {
      final tagsQuery = field.value is IdsTagsQuery
          ? field.value as IdsTagsQuery
          : const IdsTagsQuery();
      field.didChange(
        tagsQuery.withIdQueriesAdded([IncludeTagIdQuery(tag.id!)]),
      );
    }
    _textEditingController.clear();
    // Call has to be delayed as otherwise the framework will not hide the keyboard directly after closing the add page.
    Future.delayed(
      const Duration(milliseconds: 100),
      FocusScope.of(context).unfocus,
    );
  }

  Widget _buildNotAssignedTag(FormFieldState<TagsQuery> field) {
    return ColoredChipWrapper(
      child: InputChip(
        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: BorderSide.none,
        label: Text(
          S.of(context)!.notAssigned,
        ),
        backgroundColor:
            Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
        onDeleted: () => field.didChange(const IdsTagsQuery()),
      ),
    );
  }

  Widget _buildTag(
    FormFieldState<TagsQuery> field,
    TagIdQuery query,
    Tag? tag,
  ) {
    final currentQuery = field.value as IdsTagsQuery;
    final isIncludedTag = currentQuery.includedIds.contains(query.id);
    if (tag == null) {
      return Container();
    }
    return ColoredChipWrapper(
      child: InputChip(
        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: BorderSide.none,
        label: Text(
          tag.name,
          style: TextStyle(
            color: tag.textColor,
            decorationColor: tag.textColor,
            decoration: !isIncludedTag ? TextDecoration.lineThrough : null,
            decorationThickness: 2.0,
          ),
        ),
        onPressed: widget.excludeAllowed
            ? () => field.didChange(currentQuery.withIdQueryToggled(tag.id!))
            : null,
        backgroundColor: tag.color,
        deleteIconColor: tag.textColor,
        onDeleted: () => field.didChange(
          (field.value as IdsTagsQuery).withIdsRemoved([tag.id!]),
        ),
      ),
    );
  }

  Widget _buildAnyAssignedTag(FormFieldState<TagsQuery> field) {
    return ColoredChipWrapper(
      child: InputChip(
        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: BorderSide.none,
        label: Text(S.of(context)!.anyAssigned),
        backgroundColor:
            Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.12),
        onDeleted: () => field.didChange(const IdsTagsQuery()),
      ),
    );
  }
}
