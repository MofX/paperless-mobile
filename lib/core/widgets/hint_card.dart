import 'package:flutter/material.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class HintCard extends StatelessWidget {
  final String hintText;
  final double elevation;
  final IconData hintIcon;
  final VoidCallback? onHintAcknowledged;
  final bool show;
  const HintCard({
    super.key,
    required this.hintText,
    this.onHintAcknowledged,
    this.elevation = 1,
    this.show = true,
    this.hintIcon = Icons.tips_and_updates_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      sizeCurve: Curves.elasticOut,
      crossFadeState:
          show ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      secondChild: const SizedBox.shrink(),
      duration: const Duration(milliseconds: 500),
      firstChild: Card(
        elevation: elevation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              hintIcon,
              color: Theme.of(context).hintColor,
            ).padded(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  hintText,
                  softWrap: true,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            if (onHintAcknowledged != null)
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton(
                  child: Text(S.of(context)!.gotIt),
                  onPressed: onHintAcknowledged,
                ),
              )
            else
              const Padding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ).padded(),
      ).padded(),
    );
  }
}
