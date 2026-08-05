// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import 'codegen_dart.dart';
import 'custom/completion.dart';
import 'custom/dart_migrate.dart';
import 'custom/editable_arguments.dart';
import 'custom/interactive_forms.dart';
import 'custom/interactive_refactors.dart';
import 'custom/outlines.dart';
import 'custom/widget_preview.dart';
import 'meta_model.dart';
import 'utils.dart';

Future<void> main(List<String> arguments) async {
  var args = argParser.parse(arguments);
  var help = args[argHelp] as bool;
  if (help) {
    print(argParser.usage);
    return;
  }

  var outFolder = path.join(languageServerProtocolPackagePath, 'lib');
  Directory(outFolder).createSync();

  // Collect definitions for types in the model and our custom extensions.
  var specTypes = await getSpecClasses(args);
  var customTypes = getCustomClasses();

  // Record both sets of types in dictionaries for faster lookups, but also so
  // they can reference each other and we can find the definitions during
  // codegen.
  recordTypes(specTypes);
  recordTypes(customTypes);

  // Generate formatted Dart code (as a string) for each set of types.
  var specTypesOutput = generateDartForTypes(specTypes);
  var customTypesOutput = generateDartForTypes(customTypes);

  File(path.join(outFolder, 'protocol_generated.dart')).writeAsStringSync(
    generatedFileHeader(2018, importCustom: true) + specTypesOutput,
  );
  File(path.join(outFolder, 'protocol_custom_generated.dart'))
      .writeAsStringSync(generatedFileHeader(2019) + customTypesOutput);
}

const argDownload = 'download';

const argHelp = 'help';

final argParser = ArgParser()
  ..addFlag(argHelp, hide: true)
  ..addFlag(
    argDownload,
    negatable: false,
    abbr: 'd',
    help: 'Download the latest version of the LSP spec before generating types',
  );

final String languageServerProtocolPackagePath = path.join(
  sdkRootPath,
  'third_party',
  'pkg',
  'language_server_protocol',
);

final String licenseComment =
    LineSplitter.split(File(localLicensePath).readAsStringSync())
        .skipWhile(
          (line) => line != 'Files: lib/protocol_custom_generated.dart, lib/protocol_generated.dart',
        )
        .skip(2)
        .map((line) => line.isEmpty ? '//' : '// $line')
        .join('\n');

final String localLicensePath = '$languageServerProtocolPackagePath/LICENSE';
final String localSpecPath =
    '$languageServerProtocolPackagePath/lsp_meta_model.json';
final String lspPackageReadmePath =
    '$languageServerProtocolPackagePath/README.md';

final String sdkRootPath = File(Platform.script.toFilePath())
    .parent
    .parent
    .parent
    .parent
    .parent
    .path;

final Uri specLicenseUri = Uri.parse(
  'https://microsoft.github.io/language-server-protocol/License-code.txt',
);

/// The URI of the version of the LSP meta model to generate from. This should
/// be periodically updated to the latest version.
final Uri specUri = Uri.parse(
  'https://microsoft.github.io/language-server-protocol/specifications/lsp/3.18/metaModel/metaModel.json',
);

Future<void> downloadSpec() async {
  var specResp = await http.get(specUri);
  var licenseResp = await http.get(specLicenseUri);

  assert(specResp.statusCode == 200);
  assert(licenseResp.statusCode == 200);

  await File(lspPackageReadmePath).writeAsString('''
The language server protocol

The contents of LICENSE is downloaded from:

$specLicenseUri

The file lsp_meta_model.json is downloaded from:

$specUri
''');
  var dartSdkLicense = await File('$sdkRootPath/LICENSE').readAsString();
  await File(localSpecPath).writeAsString(specResp.body);
  await File(localLicensePath).writeAsString('''
$dartSdkLicense

------------------

Files: lsp_meta_model.json
Files: lib/protocol_custom_generated.dart, lib/protocol_generated.dart

${licenseResp.body}
''');
}

String generatedFileHeader(int year, {bool importCustom = false}) =>
    '''
$licenseComment

// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/tool/lsp_spec/generate_all.dart".

// ignore_for_file: constant_identifier_names

import 'dart:convert' show JsonEncoder;

import 'package:collection/collection.dart';
import 'package:language_server_protocol/json_parsing.dart';
import 'package:language_server_protocol/protocol${importCustom ? '_custom' : ''}_generated.dart';
import 'package:language_server_protocol/protocol_special.dart';

const jsonEncoder = JsonEncoder.withIndent('    ');

''';

List<LspEntity> getCustomClasses() {
  var customTypes = <LspEntity>[
    TypeAlias(
      name: 'LSPAny',
      baseType: TypeReference.lspAny,
      renameReferences: false,
    ),
    TypeAlias(
      name: 'LSPObject',
      baseType: TypeReference.lspObject,
      renameReferences: false,
    ),
    // The DocumentFilter more complex in v3.17's meta_model (to allow
    // TextDocumentFilters to be guaranteed to have at least one of language,
    // pattern, scheme) but we only ever use a single type in the server so
    // for compatibility, alias that type to the original TS-spec name.
    // TODO(dantup): Improve this after the TS->JSON Spec migration.
    TypeAlias(
      name: 'DocumentFilter',
      baseType: TypeReference('TextDocumentFilterScheme'),
      renameReferences: true,
    ),
    // Similarly, the meta_model includes String as an option for
    // DocumentSelector which is deprecated and we never previously supported
    // (because the TypeScript spec did not include it in the type) so preserve
    // that.
    // TODO(dantup): Improve this after the TS->JSON Spec migration.
    TypeAlias(
      name: 'DocumentSelector',
      baseType: ArrayType(TypeReference('TextDocumentFilterScheme')),
      renameReferences: true,
    ),
    interface('Message', [
      field('jsonrpc', type: 'string'),
      field('clientRequestTime', type: 'int', canBeUndefined: true),
    ]),
    interface('IncomingMessage', [
      field('method', type: 'Method'),
      field('params', type: 'LSPAny', canBeUndefined: true),
    ], baseType: 'Message'),
    interface('RequestMessage', [
      Field(
        name: 'id',
        type: UnionType([TypeReference.int, TypeReference.string]),
        allowsNull: false,
        allowsUndefined: false,
      ),
    ], baseType: 'IncomingMessage'),
    interface('NotificationMessage', [], baseType: 'IncomingMessage'),
    interface('ResponseMessage', [
      Field(
        name: 'id',
        type: UnionType([TypeReference.int, TypeReference.string]),
        allowsNull: true,
        allowsUndefined: false,
      ),
      field('result', type: 'LSPAny', canBeUndefined: true),
      field('error', type: 'ResponseError', canBeUndefined: true),
    ], baseType: 'Message'),
    interface('ResponseError', [
      field('code', type: 'ErrorCodes'),
      field('message', type: 'string'),
      // This is Object? normally, but since this class can be serialized
      // we will crash if it data is set to something that can't be converted to
      // JSON (for ex. Uri) so this forces anyone setting this to convert to a
      // String.
      field(
        'data',
        type: 'string',
        canBeUndefined: true,
        comment:
            'A string that contains additional information about the error. '
            'Can be omitted.',
      ),
    ]),
    TypeAlias(
      name: 'DocumentUri',
      baseType: TypeReference('Uri'),
      renameReferences: false,
    ),
    // The LSP Spec uses "URI" but since that's fairly generic and will show up
    // everywhere in code completion, we rename it to "LspUri" before using
    // a typedef onto the Dart URI class.
    TypeAlias(
      name: 'URI',
      baseType: TypeReference('LSPUri'),
      renameReferences: true,
    ),
    TypeAlias(
      name: 'LSPUri',
      baseType: TypeReference('Uri'),
      renameReferences: false,
    ),

    interface('ConnectToDtdParams', [
      field('uri', type: 'Uri'),
      field(
        'registerExperimentalHandlers',
        type: 'boolean',
        canBeUndefined: true,
        comment:
            'Whether to register experimental LSP handlers with DTD. '
            'This should not be set by clients automatically but opt-in for '
            'users that are developing/testing incomplete functionality.',
      ),
    ]),
    interface('DartDiagnosticServer', [field('port', type: 'int')]),
    interface('AnalyzerStatusParams', [field('isAnalyzing', type: 'boolean')]),
    interface('PublishClosingLabelsParams', [
      field('uri', type: 'Uri'),
      field('labels', type: 'ClosingLabel', array: true),
    ]),
    interface('OpenUriParams', [field('uri', type: 'Uri')]),
    interface('ClosingLabel', [
      field('range', type: 'Range'),
      field('label', type: 'string'),
    ]),

    // Custom types for experimental (legacy) SnippetTextEdits
    // https://github.com/rust-analyzer/rust-analyzer/blob/b35559a2460e7f0b2b79a7029db0c5d4e0acdb44/docs/dev/lsp-extensions.md#snippet-textedit
    interface(
      'LegacySnippetTextEdit',
      [field('insertTextFormat', type: 'InsertTextFormat')],
      baseType: 'TextEdit',
      comment:
          'A custom TextEdit that supports snippets according to the '
          'specification at '
          'https://github.com/rust-analyzer/rust-analyzer/blob/b35559a2460e7f0b2b79a7029db0c5d4e0acdb44/docs/dev/lsp-extensions.md#snippet-textedit'
          '. LSP v3.18 introduced standard (but slightly different) support '
          'for SnippetTextEdits which replaces this. This will soon be removed.',
    ),
    // Return type for refactor.validate command.
    interface('ValidateRefactorResult', [
      field('valid', type: 'boolean'),
      field('message', type: 'string', canBeUndefined: true),
    ]),
    interface('TypeHierarchyItemInfo', [
      field(
        'ref',
        type: 'string',
        comment:
            'The ElementLocation for this element, used to re-locate the '
            'element when subtypes/supertypes are '
            'fetched later.',
      ),
    ]),

    TypeAlias(
      name: 'TextDocumentEditEdits',
      baseType: ArrayType(
        UnionType([
          TypeReference('LegacySnippetTextEdit'),
          TypeReference('SnippetTextEdit'),
          TypeReference('AnnotatedTextEdit'),
          TypeReference('TextEdit'),
        ]),
      ),
      renameReferences: false,
    ),

    // Types for `dart/textDocument/summary`.
    interface('DartTextDocumentSummaryParams', [
      field('uri', type: 'DocumentUri'),
    ]),
    interface('DocumentSummary', [
      field('summary', type: 'String', canBeNull: true),
    ]),

    // Strongly typed classes for `completionItem/resolve`.
    ...completionResolutionClasses,

    // Support for the Outline notifications.
    ...outlineClasses,

    // Support for the Flutter Widget Preview.
    ...flutterWidgetPreviewClasses,

    // Support for Editable Arguments used by the Property Editor.
    ...editableArgumentsClasses,

    // Support for `dart/workspace/migrate`.
    ...dartMigrateClasses,

    // Support for the original (Dart-specific) interactive-refactors.
    ...interactiveRefactorsClasses,

    // Support for Interactive Forms.
    ...interactiveFormClasses,
  ];
  return customTypes;
}

Future<List<LspEntity>> getSpecClasses(ArgResults args) async {
  var download = args[argDownload] as bool;
  if (download) {
    await downloadSpec();
  }

  var file = File(localSpecPath);
  var model = LspMetaModelReader().readFile(file);
  model = LspMetaModelCleaner().cleanModel(model);

  return model.types;
}
