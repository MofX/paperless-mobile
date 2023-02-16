import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/type/types.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/document_upload/cubit/document_upload_cubit.dart';
import 'package:paperless_mobile/features/edit_label/view/impl/add_correspondent_page.dart';
import 'package:paperless_mobile/features/edit_label/view/impl/add_document_type_page.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/tags_form_field.dart';
import 'package:paperless_mobile/features/labels/view/widgets/label_form_field.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:paperless_mobile/helpers/message_helpers.dart';

class DocumentUploadPreparationPage extends StatefulWidget {
  final Uint8List fileBytes;
  final String? title;
  final String? filename;
  final String? fileExtension;

  const DocumentUploadPreparationPage({
    Key? key,
    required this.fileBytes,
    this.title,
    this.filename,
    this.fileExtension,
  }) : super(key: key);

  @override
  State<DocumentUploadPreparationPage> createState() =>
      _DocumentUploadPreparationPageState();
}

class _DocumentUploadPreparationPageState
    extends State<DocumentUploadPreparationPage> {
  static const fkFileName = "filename";
  static final fileNameDateFormat = DateFormat("yyyy_MM_ddTHH_mm_ss");

  final GlobalKey<FormBuilderState> _formKey = GlobalKey();

  PaperlessValidationErrors _errors = {};
  bool _isUploadLoading = false;
  late bool _syncTitleAndFilename;
  bool _showDatePickerDeleteIcon = false;
  final _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _syncTitleAndFilename = widget.filename == null && widget.title == null;
    initializeDateFormatting();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(S.of(context).prepareDocument),
        bottom: _isUploadLoading
            ? const PreferredSize(
                child: LinearProgressIndicator(),
                preferredSize: Size.fromHeight(4.0))
            : null,
      ),
      floatingActionButton: Visibility(
        visible: MediaQuery.of(context).viewInsets.bottom == 0,
        child: FloatingActionButton.extended(
          onPressed: _onSubmit,
          label: Text(S.of(context).upload),
          icon: const Icon(Icons.upload),
        ),
      ),
      body: BlocBuilder<DocumentUploadCubit, DocumentUploadState>(
        builder: (context, state) {
          return FormBuilder(
            key: _formKey,
            child: ListView(
              children: [
                // Title
                FormBuilderTextField(
                  autovalidateMode: AutovalidateMode.always,
                  name: DocumentModel.titleKey,
                  initialValue:
                      widget.title ?? "scan_${fileNameDateFormat.format(_now)}",
                  validator: FormBuilderValidators.required(),
                  decoration: InputDecoration(
                    labelText: S.of(context).title,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _formKey.currentState?.fields[DocumentModel.titleKey]
                            ?.didChange("");
                        if (_syncTitleAndFilename) {
                          _formKey.currentState?.fields[fkFileName]
                              ?.didChange("");
                        }
                      },
                    ),
                    errorText: _errors[DocumentModel.titleKey],
                  ),
                  onChanged: (value) {
                    final String transformedValue =
                        _formatFilename(value ?? '');
                    if (_syncTitleAndFilename) {
                      _formKey.currentState?.fields[fkFileName]
                          ?.didChange(transformedValue);
                    }
                  },
                ),
                // Filename
                FormBuilderTextField(
                  autovalidateMode: AutovalidateMode.always,
                  readOnly: _syncTitleAndFilename,
                  enabled: !_syncTitleAndFilename,
                  name: fkFileName,
                  decoration: InputDecoration(
                    labelText: S.of(context).fileName,
                    suffixText: widget.fileExtension,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _formKey.currentState?.fields[fkFileName]
                          ?.didChange(''),
                    ),
                  ),
                  initialValue: widget.filename ??
                      "scan_${fileNameDateFormat.format(_now)}",
                ),
                // Synchronize title and filename
                SwitchListTile(
                  value: _syncTitleAndFilename,
                  onChanged: (value) {
                    setState(
                      () => _syncTitleAndFilename = value,
                    );
                    if (_syncTitleAndFilename) {
                      final String transformedValue = _formatFilename(_formKey
                          .currentState
                          ?.fields[DocumentModel.titleKey]
                          ?.value as String);
                      if (_syncTitleAndFilename) {
                        _formKey.currentState?.fields[fkFileName]
                            ?.didChange(transformedValue);
                      }
                    }
                  },
                  title: Text(
                    S.of(context).synchronizeTitleAndFilename,
                  ),
                ),
                // Created at
                FormBuilderDateTimePicker(
                  autovalidateMode: AutovalidateMode.always,
                  format: DateFormat.yMMMMd(),
                  inputType: InputType.date,
                  name: DocumentModel.createdKey,
                  initialValue: null,
                  onChanged: (value) {
                    setState(() => _showDatePickerDeleteIcon = value != null);
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.calendar_month_outlined),
                    labelText: S.of(context).createdAt + " *",
                    suffixIcon: _showDatePickerDeleteIcon
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _formKey.currentState!
                                  .fields[DocumentModel.createdKey]
                                  ?.didChange(null);
                            },
                          )
                        : null,
                  ),
                ),
                // Correspondent
                LabelFormField<Correspondent>(
                  notAssignedSelectable: false,
                  formBuilderState: _formKey.currentState,
                  labelCreationWidgetBuilder: (initialName) =>
                      RepositoryProvider(
                    create: (context) =>
                        context.read<LabelRepository<Correspondent>>(),
                    child: AddCorrespondentPage(initialName: initialName),
                  ),
                  textFieldLabel: S.of(context).correspondent + " *",
                  name: DocumentModel.correspondentKey,
                  labelOptions: state.correspondents,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                // Document type
                LabelFormField<DocumentType>(
                  notAssignedSelectable: false,
                  formBuilderState: _formKey.currentState,
                  labelCreationWidgetBuilder: (initialName) =>
                      RepositoryProvider(
                    create: (context) =>
                        context.read<LabelRepository<DocumentType>>(),
                    child: AddDocumentTypePage(initialName: initialName),
                  ),
                  textFieldLabel: S.of(context).documentType + " *",
                  name: DocumentModel.documentTypeKey,
                  labelOptions: state.documentTypes,
                  prefixIcon: const Icon(Icons.description_outlined),
                ),
                TagFormField(
                  name: DocumentModel.tagsKey,
                  notAssignedSelectable: false,
                  anyAssignedSelectable: false,
                  excludeAllowed: false,
                  selectableOptions: state.tags,
                  //Label: "Tags" + " *",
                ),
                Text(
                  "* " + S.of(context).uploadInferValuesHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                SizedBox(height: 300),
              ].padded(),
            ),
          );
        },
      ),
    );
  }

  void _onSubmit() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final cubit = context.read<DocumentUploadCubit>();
      try {
        setState(() => _isUploadLoading = true);

        final fv = _formKey.currentState!.value;

        final createdAt = fv[DocumentModel.createdKey] as DateTime?;
        final title = fv[DocumentModel.titleKey] as String;
        final docType = fv[DocumentModel.documentTypeKey] as IdQueryParameter;
        final tags = fv[DocumentModel.tagsKey] as IdsTagsQuery;
        final correspondent =
            fv[DocumentModel.correspondentKey] as IdQueryParameter;

        final taskId = await cubit.upload(
          widget.fileBytes,
          filename: _padWithExtension(
            _formKey.currentState?.value[fkFileName],
            widget.fileExtension,
          ),
          title: title,
          documentType: docType.id,
          correspondent: correspondent.id,
          tags: tags.ids,
          createdAt: createdAt,
        );
        showSnackBar(
            context, S.of(context).documentSuccessfullyUploadedProcessing);
        Navigator.pop(context, taskId);
      } on PaperlessServerException catch (error, stackTrace) {
        showErrorMessage(context, error, stackTrace);
      } on PaperlessValidationErrors catch (errors) {
        setState(() => _errors = errors);
      } catch (unknownError, stackTrace) {
        showErrorMessage(
            context, const PaperlessServerException.unknown(), stackTrace);
      } finally {
        setState(() {
          _isUploadLoading = false;
        });
      }
    }
  }

  String _padWithExtension(String source, [String? extension]) {
    final ext = extension ?? '.pdf';
    return source.endsWith(ext) ? source : '$source$ext';
  }

  String _formatFilename(String source) {
    return source.replaceAll(RegExp(r"[\W_]"), "_").toLowerCase();
  }
}
