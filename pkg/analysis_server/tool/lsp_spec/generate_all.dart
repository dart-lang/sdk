// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import 'codegen_dart.dart';
import 'meta_model.dart';

Future<void> main(List<String> arguments) async {
  final args = argParser.parse(arguments);
  var help = args[argHelp] as bool;
  if (help) {
    print(argParser.usage);
    return;
  }

  final script = Platform.script.toFilePath();
  // 3x parent = file -> lsp_spec -> tool -> analysis_server.
  final packageFolder = File(script).parent.parent.parent.path;
  final outFolder = path.join(packageFolder, 'lib', 'lsp_protocol');
  Directory(outFolder).createSync();

  // Collect definitions for types in the model and our custom extensions.
  final specTypes = await getSpecClasses(args);
  final customTypes = getCustomClasses();

  // Record both sets of types in dictionaries for faster lookups, but also so
  // they can reference each other and we can find the definitions during
  // codegen.
  recordTypes(specTypes);
  recordTypes(customTypes);

  // Generate formatted Dart code (as a string) for each set of types.
  final specTypesOutput = generateDartForTypes(specTypes);
  final customTypesOutput = generateDartForTypes(customTypes);

  File(path.join(outFolder, 'protocol_generated.dart')).writeAsStringSync(
      generatedFileHeader(2018, importCustom: true) + specTypesOutput);
  File(path.join(outFolder, 'protocol_custom_generated.dart'))
      .writeAsStringSync(generatedFileHeader(2019) + customTypesOutput);
}

const argDownload = 'download';

const argHelp = 'help';

final argParser = ArgParser()
  ..addFlag(argHelp, hide: true)
  ..addFlag(argDownload,
      negatable: false,
      abbr: 'd',
      help:
          'Download the latest version of the LSP spec before generating types');

final String localLicensePath = path.join(
    path.dirname(Platform.script.toFilePath()), 'lsp_meta_model.license.txt');

final String localSpecPath = path.join(
    path.dirname(Platform.script.toFilePath()), 'lsp_meta_model.json');

final Uri specLicenseUri = Uri.parse(
    'https://microsoft.github.io/language-server-protocol/License.txt');

/// The URI of the version of the LSP meta model to generate from. This should
/// be periodically updated to the latest version.
final Uri specUri = Uri.parse(
    'https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/metaModel/metaModel.json');

Future<void> downloadSpec() async {
  final specResp = await http.get(specUri);
  final licenseResp = await http.get(specLicenseUri);

  assert(specResp.statusCode == 200);
  assert(licenseResp.statusCode == 200);

  await File(localSpecPath).writeAsString(specResp.body);
  await File(localLicensePath).writeAsString(
    'This license is for the ${path.basename(localSpecPath)} file.\n\n'
    '${path.basename(localLicensePath)} downloaded from: $specLicenseUri\n'
    '${path.basename(localSpecPath)} downloaded from: $specUri\n'
    '\n--\n\n'
    '${licenseResp.body}',
  );
}

String generatedFileHeader(int year, {bool importCustom = false}) => '''
// Copyright (c) $year, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/tool/lsp_spec/generate_all.dart".

import 'dart:core' hide deprecated;
import 'dart:core' as core show deprecated;
import 'dart:convert' show JsonEncoder;
import 'package:analysis_server/lsp_protocol/protocol${importCustom ? '_custom' : ''}_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/json_parsing.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart';

const jsonEncoder = JsonEncoder.withIndent('    ');

''';

List<AstNode> getCustomClasses() {
  /// Helper to create an interface type.
  Interface interface(String name, List<Member> fields, {String? baseType}) {
    return Interface(
      name: name,
      baseTypes: [if (baseType != null) Type.identifier(baseType)],
      members: fields,
    );
  }

  /// Helper to create a field.
  Field field(
    String name, {
    String? comment,
    required String type,
    bool array = false,
    bool canBeUndefined = false,
  }) {
    final fieldType =
        array ? ArrayType(Type.identifier(type)) : Type.identifier(type);

    return Field(
      name: name,
      comment: comment,
      type: fieldType,
      allowsNull: false,
      allowsUndefined: canBeUndefined,
    );
  }

  final customTypes = <AstNode>[
    TypeAlias(
      name: 'LSPAny',
      baseType: Type.Any,
    ),
    TypeAlias(
      name: 'LSPObject',
      baseType: Type.Any,
    ),
    // The DocumentFilter more complex in v3.17's meta_model (to allow
    // TextDocumentFilters to be guaranteed to have at least one of language,
    // pattern, scheme) but we only ever use a single type in the server so
    // for compatibility, alias that type to the original TS-spec name.
    // TODO(dantup): Improve this after the TS->JSON Spec migration.
    TypeAlias(
      name: 'DocumentFilter',
      baseType: Type.identifier('TextDocumentFilter2'),
    ),
    // Similarly, the meta_model includes String as an option for
    // DocumentSelector which is deprecated and we never previously supported
    // (because the TypeScript spec did not include it in the type) so preserve
    // that.
    // TODO(dantup): Improve this after the TS->JSON Spec migration.
    TypeAlias(
      name: 'DocumentSelector',
      baseType: ArrayType(Type.identifier('TextDocumentFilterWithScheme')),
    ),
    interface('Message', [
      field('jsonrpc', type: 'string'),
      field('clientRequestTime', type: 'int', canBeUndefined: true),
    ]),
    interface(
      'IncomingMessage',
      [
        field('method', type: 'Method'),
        field('params', type: 'LSPAny', canBeUndefined: true),
      ],
      baseType: 'Message',
    ),
    interface(
      'RequestMessage',
      [
        Field(
          name: 'id',
          type: UnionType([Type.identifier('int'), Type.identifier('string')]),
          allowsNull: false,
          allowsUndefined: false,
        )
      ],
      baseType: 'IncomingMessage',
    ),
    interface(
      'NotificationMessage',
      [],
      baseType: 'IncomingMessage',
    ),
    interface(
      'ResponseMessage',
      [
        Field(
          name: 'id',
          type: UnionType([Type.identifier('int'), Type.identifier('string')]),
          allowsNull: true,
          allowsUndefined: false,
        ),
        field('result', type: 'LSPAny', canBeUndefined: true),
        field('error', type: 'ResponseError', canBeUndefined: true),
      ],
      baseType: 'Message',
    ),
    interface(
      'ResponseError',
      [
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
      ],
    ),
    TypeAlias(
      name: 'DocumentUri',
      baseType: Type.identifier('string'),
    ),

    interface('DartDiagnosticServer', [field('port', type: 'int')]),
    interface('AnalyzerStatusParams', [field('isAnalyzing', type: 'boolean')]),
    interface('PublishClosingLabelsParams', [
      field('uri', type: 'string'),
      field('labels', type: 'ClosingLabel', array: true)
    ]),
    interface('ClosingLabel',
        [field('range', type: 'Range'), field('label', type: 'string')]),
    interface('Element', [
      field('range', type: 'Range', canBeUndefined: true),
      field('name', type: 'string'),
      field('kind', type: 'string'),
      field('parameters', type: 'string', canBeUndefined: true),
      field('typeParameters', type: 'string', canBeUndefined: true),
      field('returnType', type: 'string', canBeUndefined: true),
    ]),
    interface('PublishOutlineParams',
        [field('uri', type: 'string'), field('outline', type: 'Outline')]),
    interface('Outline', [
      field('element', type: 'Element'),
      field('range', type: 'Range'),
      field('codeRange', type: 'Range'),
      field('children', type: 'Outline', array: true, canBeUndefined: true)
    ]),
    interface('PublishFlutterOutlineParams', [
      field('uri', type: 'string'),
      field('outline', type: 'FlutterOutline')
    ]),
    interface('FlutterOutline', [
      field('kind', type: 'string'),
      field('label', type: 'string', canBeUndefined: true),
      field('className', type: 'string', canBeUndefined: true),
      field('variableName', type: 'string', canBeUndefined: true),
      field('attributes',
          type: 'FlutterOutlineAttribute', array: true, canBeUndefined: true),
      field('dartElement', type: 'Element', canBeUndefined: true),
      field('range', type: 'Range'),
      field('codeRange', type: 'Range'),
      field('children',
          type: 'FlutterOutline', array: true, canBeUndefined: true)
    ]),
    interface(
      'FlutterOutlineAttribute',
      [
        field('name', type: 'string'),
        field('label', type: 'string'),
        field('valueRange', type: 'Range', canBeUndefined: true),
      ],
    ),
    interface(
      // Used as a base class for all resolution data classes.
      'CompletionItemResolutionInfo',
      [],
    ),
    interface(
      'DartSuggestionSetCompletionItemResolutionInfo',
      [
        // These fields have short-ish names because they're on the payload
        // for all suggestion-set backed completions.
        field('file', type: 'string'),
        field('offset', type: 'int'),
        field('libId', type: 'int'),
        field('displayUri', type: 'string'),
        field('rOffset', type: 'int'), // replacementOffset
        field('iLength', type: 'int'), // insertLength
        field('rLength', type: 'int'), // replacementLength
      ],
      baseType: 'CompletionItemResolutionInfo',
    ),
    interface(
      'PubPackageCompletionItemResolutionInfo',
      [
        field('packageName', type: 'string'),
      ],
      baseType: 'CompletionItemResolutionInfo',
    ),
    // Custom types for experimental SnippetTextEdits
    // https://github.com/rust-analyzer/rust-analyzer/blob/b35559a2460e7f0b2b79a7029db0c5d4e0acdb44/docs/dev/lsp-extensions.md#snippet-textedit
    interface(
      'SnippetTextEdit',
      [
        field('insertTextFormat', type: 'InsertTextFormat'),
      ],
      baseType: 'TextEdit',
    ),
    // Return type for refactor.validate command.
    interface(
      'ValidateRefactorResult',
      [
        field('valid', type: 'boolean'),
        field('message', type: 'string', canBeUndefined: true),
      ],
    ),
    TypeAlias(
      name: 'TextDocumentEditEdits',
      baseType: ArrayType(
        UnionType([
          Type.identifier('SnippetTextEdit'),
          Type.identifier('AnnotatedTextEdit'),
          Type.identifier('TextEdit'),
        ]),
      ),
    )
  ];
  return customTypes;
}

Future<List<AstNode>> getSpecClasses(ArgResults args) async {
  var download = args[argDownload] as bool;
  if (download) {
    await downloadSpec();
  }

  final file = File(localSpecPath);
  var model = LspMetaModelReader().readFile(file);
  model = LspMetaModelCleaner().cleanModel(model);

  return model.types;
}
