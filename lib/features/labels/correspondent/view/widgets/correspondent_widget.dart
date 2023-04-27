import 'package:flutter/material.dart';
import 'package:paperless_api/paperless_api.dart';

class CorrespondentWidget extends StatelessWidget {
  final Correspondent? correspondent;
  final void Function(int? id)? onSelected;
  final Color? textColor;
  final bool isClickable;
  final TextStyle? textStyle;

  const CorrespondentWidget({
    Key? key,
    required this.correspondent,
    this.textColor,
    this.isClickable = true,
    this.textStyle,
    this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: !isClickable,
      child: GestureDetector(
        onTap: () => onSelected?.call(correspondent?.id),
        child: Text(
          correspondent?.name ?? "-",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style:
              (textStyle ?? Theme.of(context).textTheme.bodyMedium)?.copyWith(
            color: textColor ?? Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
