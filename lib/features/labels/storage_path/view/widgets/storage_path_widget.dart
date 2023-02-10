import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/features/labels/cubit/label_cubit.dart';
import 'package:paperless_mobile/features/labels/cubit/label_state.dart';
import 'package:paperless_mobile/features/labels/cubit/providers/storage_path_bloc_provider.dart';

class StoragePathWidget extends StatelessWidget {
  final int? pathId;
  final Color? textColor;
  final bool isClickable;
  final void Function(int? id)? onSelected;

  const StoragePathWidget({
    Key? key,
    this.pathId,
    this.textColor,
    this.isClickable = true,
    this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoragePathBlocProvider(
      child: AbsorbPointer(
        absorbing: !isClickable,
        child: BlocBuilder<LabelCubit<StoragePath>, LabelState<StoragePath>>(
          builder: (context, state) {
            return GestureDetector(
              onTap: () => onSelected?.call(pathId),
              child: Text(
                state.getLabel(pathId)?.name ?? "-",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: textColor ?? Theme.of(context).colorScheme.primary,
                    ),
              ),
            );
          },
        ),
      ),
    );
  }
}
