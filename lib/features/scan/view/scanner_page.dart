import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math';

import 'package:edge_detection/edge_detection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/bloc/connectivity_cubit.dart';
import 'package:paperless_mobile/core/global/constants.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/repository/provider/label_repositories_provider.dart';
import 'package:paperless_mobile/core/repository/state/impl/correspondent_repository_state.dart';
import 'package:paperless_mobile/core/repository/state/impl/document_type_repository_state.dart';
import 'package:paperless_mobile/core/repository/state/impl/tag_repository_state.dart';
import 'package:paperless_mobile/core/service/file_service.dart';
import 'package:paperless_mobile/core/store/local_vault.dart';
import 'package:paperless_mobile/core/widgets/hint_card.dart';
import 'package:paperless_mobile/core/widgets/offline_banner.dart';
import 'package:paperless_mobile/features/document_upload/cubit/document_upload_cubit.dart';
import 'package:paperless_mobile/features/document_upload/view/document_upload_preparation_page.dart';
import 'package:paperless_mobile/features/documents/view/pages/document_view.dart';
import 'package:paperless_mobile/features/home/view/widget/info_drawer.dart';
import 'package:paperless_mobile/features/scan/bloc/document_scanner_cubit.dart';
import 'package:paperless_mobile/features/scan/view/widgets/grid_image_item_widget.dart';
import 'package:paperless_mobile/features/tasks/cubit/task_status_cubit.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:paperless_mobile/util.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({Key? key}) : super(key: key);

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityState>(
      builder: (context, connectedState) {
        return Scaffold(
          drawer: const InfoDrawer(),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _openDocumentScanner(context),
            child: const Icon(Icons.add_a_photo_outlined),
          ),
          appBar: _buildAppBar(context, connectedState.isConnected),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildBody(connectedState.isConnected),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context, bool isConnected) {
    return AppBar(
      title: Text(S.of(context).documentScannerPageTitle),
      bottom: !isConnected ? const OfflineBanner() : null,
      actions: [
        BlocBuilder<DocumentScannerCubit, List<File>>(
          builder: (context, state) {
            return IconButton(
              onPressed: state.isNotEmpty
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => DocumentView(
                            documentBytes: _assembleFileBytes(
                              state,
                              forcePdf: true,
                            ).then((file) => file.bytes),
                          ),
                        ),
                      )
                  : null,
              icon: const Icon(Icons.preview),
              tooltip: S.of(context).documentScannerPageResetButtonTooltipText,
            );
          },
        ),
        BlocBuilder<DocumentScannerCubit, List<File>>(
          builder: (context, state) {
            return IconButton(
              onPressed: state.isEmpty ? null : () => _reset(context),
              icon: const Icon(Icons.delete_sweep),
              tooltip: S.of(context).documentScannerPageResetButtonTooltipText,
            );
          },
        ),
        BlocBuilder<DocumentScannerCubit, List<File>>(
          builder: (context, state) {
            return IconButton(
              onPressed: state.isEmpty || !isConnected
                  ? null
                  : () => _onPrepareDocumentUpload(context),
              icon: const Icon(Icons.done),
              tooltip: S.of(context).documentScannerPageUploadButtonTooltip,
            );
          },
        ),
      ],
    );
  }

  void _openDocumentScanner(BuildContext context) async {
    final isGranted = await askForPermission(Permission.camera);
    if (!isGranted) {
      return;
    }
    final file = await FileService.allocateTemporaryFile(
      PaperlessDirectoryType.scans,
      extension: 'jpeg',
    );
    if (kDebugMode) {
      dev.log('[ScannerPage] Created temporary file: ${file.path}');
    }

    final success = await EdgeDetection.detectEdge(file.path);
    if (!success) {
      if (kDebugMode) {
        dev.log(
            '[ScannerPage] Scan either not successful or canceled by user.');
      }
      return;
    }
    if (kDebugMode) {
      dev.log('[ScannerPage] Wrote image to temporary file: ${file.path}');
    }
    context.read<DocumentScannerCubit>().addScan(file);
  }

  void _onPrepareDocumentUpload(BuildContext context) async {
    final file = await _assembleFileBytes(
      context.read<DocumentScannerCubit>().state,
    );
    final taskId = await Navigator.of(context).push<String?>(
      MaterialPageRoute(
        builder: (_) => LabelRepositoriesProvider(
          child: BlocProvider(
            create: (context) => DocumentUploadCubit(
              localVault: context.read<LocalVault>(),
              documentApi: context.read<PaperlessDocumentsApi>(),
              correspondentRepository: context.read<
                  LabelRepository<Correspondent,
                      CorrespondentRepositoryState>>(),
              documentTypeRepository: context.read<
                  LabelRepository<DocumentType, DocumentTypeRepositoryState>>(),
              tagRepository:
                  context.read<LabelRepository<Tag, TagRepositoryState>>(),
            ),
            child: DocumentUploadPreparationPage(
              fileBytes: file.bytes,
              fileExtension: file.extension,
            ),
          ),
        ),
      ),
    );
    if (taskId != null) {
      // For paperless version older than 1.11.3, task id will always be null!
      context.read<DocumentScannerCubit>().reset();
      context.read<TaskStatusCubit>().listenToTaskChanges(taskId);
    }
  }

  Widget _buildBody(bool isConnected) {
    return BlocBuilder<DocumentScannerCubit, List<File>>(
      builder: (context, scans) {
        if (scans.isNotEmpty) {
          return _buildImageGrid(scans);
        }
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  S.of(context).documentScannerPageEmptyStateText,
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  child:
                      Text(S.of(context).documentScannerPageAddScanButtonLabel),
                  onPressed: () => _openDocumentScanner(context),
                ),
                Text(S.of(context).documentScannerPageOrText),
                TextButton(
                  child: Text(S
                      .of(context)
                      .documentScannerPageUploadFromThisDeviceButtonLabel),
                  onPressed: isConnected ? _onUploadFromFilesystem : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageGrid(List<File> scans) {
    return GridView.builder(
        itemCount: scans.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1 / sqrt(2),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          return GridImageItemWidget(
            file: scans[index],
            onDelete: () async {
              try {
                context.read<DocumentScannerCubit>().removeScan(index);
              } on PaperlessServerException catch (error, stackTrace) {
                showErrorMessage(context, error, stackTrace);
              }
            },
            index: index,
            totalNumberOfFiles: scans.length,
          );
        });
  }

  void _reset(BuildContext context) {
    try {
      context.read<DocumentScannerCubit>().reset();
    } on PaperlessServerException catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    }
  }

  void _onUploadFromFilesystem() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: supportedFileExtensions,
      withData: true,
      allowMultiple: false,
    );
    if (result?.files.single.path != null) {
      File file = File(result!.files.single.path!);
      if (!supportedFileExtensions
          .contains(file.path.split('.').last.toLowerCase())) {
        showErrorMessage(
          context,
          const PaperlessServerException(ErrorCode.unsupportedFileFormat),
        );
        return;
      }
      final filename = extractFilenameFromPath(file.path);
      final extension = p.extension(file.path);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LabelRepositoriesProvider(
            child: BlocProvider(
              create: (context) => DocumentUploadCubit(
                localVault: context.read<LocalVault>(),
                documentApi: context.read<PaperlessDocumentsApi>(),
                correspondentRepository: context.read<
                    LabelRepository<Correspondent,
                        CorrespondentRepositoryState>>(),
                documentTypeRepository: context.read<
                    LabelRepository<DocumentType,
                        DocumentTypeRepositoryState>>(),
                tagRepository:
                    context.read<LabelRepository<Tag, TagRepositoryState>>(),
              ),
              child: DocumentUploadPreparationPage(
                fileBytes: file.readAsBytesSync(),
                filename: filename,
                fileExtension: extension,
                title: filename,
              ),
            ),
          ),
        ),
      );
    }
  }

  ///
  /// Returns the file bytes of either a single file or multiple images concatenated into a single pdf.
  ///
  Future<AssembledFile> _assembleFileBytes(
    final List<File> files, {
    bool forcePdf = false,
  }) async {
    assert(files.isNotEmpty);
    if (files.length == 1 && !forcePdf) {
      final ext = p.extension(files.first.path);
      return AssembledFile(ext, files.first.readAsBytesSync());
    }
    final doc = pw.Document();
    for (final file in files) {
      final img = pw.MemoryImage(file.readAsBytesSync());
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(
            img.width!.toDouble(),
            img.height!.toDouble(),
          ),
          build: (context) => pw.Image(img),
        ),
      );
    }
    return AssembledFile('.pdf', await doc.save());
  }
}

class AssembledFile {
  final String extension;
  final Uint8List bytes;

  AssembledFile(this.extension, this.bytes);
}
