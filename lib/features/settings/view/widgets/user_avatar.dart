import 'package:flutter/material.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';

class UserAvatar extends StatelessWidget {
  final LocalUserAccount account;

  const UserAvatar({
    super.key,
    required this.account,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Colors.primaries[account.id.hashCode % Colors.primaries.length];
    final foregroundColor = backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    return CircleAvatar(
      child: Text((account.paperlessUser.fullName ?? account.paperlessUser.username)
          .split(" ")
          .take(2)
          .map((e) => e.substring(0, 1))
          .map((e) => e.toUpperCase())
          .join("")),
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
    );
  }
}
