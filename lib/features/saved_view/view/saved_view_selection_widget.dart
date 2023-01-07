import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/bloc/connectivity_cubit.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_state.dart';
import 'package:paperless_mobile/features/documents/view/widgets/selection/confirm_delete_saved_view_dialog.dart';
import 'package:paperless_mobile/features/saved_view/cubit/saved_view_cubit.dart';
import 'package:paperless_mobile/features/saved_view/cubit/saved_view_state.dart';
import 'package:paperless_mobile/features/saved_view/view/add_saved_view_page.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:paperless_mobile/util.dart';
import 'package:shimmer/shimmer.dart';

class SavedViewSelectionWidget extends StatelessWidget {
  final DocumentFilter currentFilter;
  const SavedViewSelectionWidget({
    Key? key,
    required this.height,
    required this.enabled,
    required this.currentFilter,
  }) : super(key: key);

  final double height;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityState>(
      builder: (context, connectivityState) {
        final hasInternetConnection = connectivityState.isConnected;
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BlocBuilder<SavedViewCubit, SavedViewState>(
              builder: (context, state) {
                if (!state.hasLoaded) {
                  return _buildLoadingWidget(context);
                }
                if (state.value.isEmpty) {
                  return Text(S.of(context).savedViewsEmptyStateText);
                }
                return SizedBox(
                  height: height,
                  child: ListView.separated(
                    itemCount: state.value.length,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final view = state.value.values.elementAt(index);
                      return GestureDetector(
                        onLongPress: hasInternetConnection
                            ? () => _onDelete(context, view)
                            : null,
                        child: BlocBuilder<DocumentsCubit, DocumentsState>(
                          builder: (context, docState) {
                            return FilterChip(
                              label: Text(
                                state.value.values.toList()[index].name,
                              ),
                              selected: view.id == docState.selectedSavedViewId,
                              onSelected: enabled && hasInternetConnection
                                  ? (isSelected) =>
                                      _onSelected(isSelected, context, view)
                                  : null,
                            );
                          },
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => const SizedBox(
                      width: 4.0,
                    ),
                  ),
                );
              },
            ),
            BlocBuilder<SavedViewCubit, SavedViewState>(
              builder: (context, state) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      S.of(context).savedViewsLabel,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    BlocBuilder<DocumentsCubit, DocumentsState>(
                      buildWhen: (previous, current) =>
                          previous.filter != current.filter,
                      builder: (context, docState) {
                        return TextButton.icon(
                          icon: const Icon(Icons.add),
                          onPressed: (enabled &&
                                  state.hasLoaded &&
                                  hasInternetConnection)
                              ? () => _onCreatePressed(context, docState.filter)
                              : null,
                          label: Text(S.of(context).savedViewCreateNewLabel),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingWidget(BuildContext context) {
    final r = Random(123456789);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Shimmer.fromColors(
        baseColor: Theme.of(context).brightness == Brightness.light
            ? Colors.grey[300]!
            : Colors.grey[900]!,
        highlightColor: Theme.of(context).brightness == Brightness.light
            ? Colors.grey[100]!
            : Colors.grey[600]!,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 10,
          itemBuilder: (context, index) => FilterChip(
              label: SizedBox(width: r.nextInt((index * 20) + 50).toDouble()),
              onSelected: null),
          separatorBuilder: (context, index) => const SizedBox(width: 4.0),
        ),
      ),
    );
  }

  void _onCreatePressed(BuildContext context, DocumentFilter filter) async {
    final newView = await Navigator.of(context).push<SavedView?>(
      MaterialPageRoute(
        builder: (context) => AddSavedViewPage(
          currentFilter: filter,
        ),
      ),
    );
    if (newView != null) {
      try {
        await context.read<SavedViewCubit>().add(newView);
      } on PaperlessServerException catch (error, stackTrace) {
        showErrorMessage(context, error, stackTrace);
      }
    }
  }

  void _onSelected(
    bool isSelected,
    BuildContext context,
    SavedView view,
  ) async {
    if (isSelected) {
      context.read<DocumentsCubit>().selectView(view.id!);
    } else {
      context.read<DocumentsCubit>().resetFilter();
      context.read<DocumentsCubit>().unselectView();
    }
  }

  void _onDelete(BuildContext context, SavedView view) async {
    {
      final delete = await showDialog<bool>(
            context: context,
            builder: (context) => ConfirmDeleteSavedViewDialog(view: view),
          ) ??
          false;
      if (delete) {
        try {
          context.read<SavedViewCubit>().remove(view);
          if (context.read<DocumentsCubit>().state.selectedSavedViewId ==
              view.id) {
            await context.read<DocumentsCubit>().resetFilter();
          }
        } on PaperlessServerException catch (error, stackTrace) {
          showErrorMessage(context, error, stackTrace);
        }
      }
    }
  }
}
