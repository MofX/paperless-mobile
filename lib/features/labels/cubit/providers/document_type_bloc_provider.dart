import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/repository/state/impl/document_type_repository_state.dart';
import 'package:paperless_mobile/features/labels/cubit/label_cubit.dart';

class DocumentTypeBlocProvider extends StatelessWidget {
  final Widget child;
  const DocumentTypeBlocProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LabelCubit<DocumentType>(
        context.read<LabelRepository<DocumentType>>(),
      ),
      child: child,
    );
  }
}
