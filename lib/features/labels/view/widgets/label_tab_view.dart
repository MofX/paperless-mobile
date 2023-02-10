import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/bloc/connectivity_cubit.dart';
import 'package:paperless_mobile/core/translation/matching_algorithm_localization_mapper.dart';
import 'package:paperless_mobile/features/labels/cubit/label_cubit.dart';
import 'package:paperless_mobile/core/widgets/offline_widget.dart';
import 'package:paperless_mobile/features/labels/cubit/label_state.dart';
import 'package:paperless_mobile/features/labels/view/widgets/label_item.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';

class LabelTabView<T extends Label> extends StatelessWidget {
  final DocumentFilter Function(Label) filterBuilder;
  final void Function(T) onEdit;
  final void Function() onAddNew;

  /// Displayed as the subtitle of the [ListTile]
  final Widget Function(T)? contentBuilder;

  /// Displayed as the leading widget of the [ListTile]
  final Widget Function(T)? leadingBuilder;

  /// Shown on empty State
  final String emptyStateDescription;
  final String emptyStateActionButtonLabel;

  const LabelTabView({
    super.key,
    required this.filterBuilder,
    this.contentBuilder,
    this.leadingBuilder,
    required this.onEdit,
    required this.emptyStateDescription,
    required this.onAddNew,
    required this.emptyStateActionButtonLabel,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LabelCubit<T>(
        context.read(),
      ),
      child: BlocBuilder<ConnectivityCubit, ConnectivityState>(
        builder: (context, connectivityState) {
          return BlocBuilder<LabelCubit<T>, LabelState<T>>(
            builder: (context, state) {
              if (!state.isLoaded && !connectivityState.isConnected) {
                return const OfflineWidget();
              }
              final labels = state.labels.values.toList()..sort();
              if (labels.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          emptyStateDescription,
                          textAlign: TextAlign.center,
                        ),
                        TextButton(
                          onPressed: onAddNew,
                          child: Text(emptyStateActionButtonLabel),
                        ),
                      ].padded(),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final l = labels.elementAt(index);
                    return LabelItem<T>(
                      name: l.name,
                      content: contentBuilder?.call(l) ??
                          Text(
                            translateMatchingAlgorithmName(
                                    context, l.matchingAlgorithm) +
                                ((l.match?.isNotEmpty ?? false)
                                    ? ": ${l.match}"
                                    : ""),
                            maxLines: 2,
                          ),
                      onOpenEditPage: onEdit,
                      filterBuilder: filterBuilder,
                      leading: leadingBuilder?.call(l),
                      label: l,
                    );
                  },
                  childCount: labels.length,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
