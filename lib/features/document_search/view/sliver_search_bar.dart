import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:paperless_mobile/core/config/hive/hive_config.dart';
import 'package:paperless_mobile/core/database/tables/global_settings.dart';
import 'package:paperless_mobile/core/database/tables/local_user_app_state.dart';
import 'package:paperless_mobile/core/delegate/customizable_sliver_persistent_header_delegate.dart';
import 'package:paperless_mobile/features/document_search/cubit/document_search_cubit.dart';
import 'package:paperless_mobile/features/document_search/view/document_search_bar.dart';

class SliverSearchBar extends StatelessWidget {
  final bool floating;
  final bool pinned;
  const SliverSearchBar({
    super.key,
    this.floating = false,
    this.pinned = false,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser =
        Hive.box<GlobalSettings>(HiveBoxes.globalSettings).getValue()!.currentLoggedInUser;

    return SliverPersistentHeader(
      floating: floating,
      pinned: pinned,
      delegate: CustomizableSliverPersistentHeaderDelegate(
        minExtent: kToolbarHeight,
        maxExtent: kToolbarHeight,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          child: BlocProvider(
            create: (context) => DocumentSearchCubit(
              context.read(),
              context.read(),
              context.read(),
              Hive.box<LocalUserAppState>(HiveBoxes.localUserAppState).get(currentUser)!,
            ),
            child: const DocumentSearchBar(),
          ),
        ),
      ),
    );
  }
}
