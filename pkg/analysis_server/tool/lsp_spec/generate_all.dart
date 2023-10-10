// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
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

  final outFolder = path.join(languageServerProtocolPackagePath, 'lib');
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

final String languageServerProtocolPackagePath =
    '$sdkRootPath/third_party/pkg/language_server_protocol';

final String licenseComment = LineSplitter.split(
        File(localLicensePath).readAsStringSync())
    .skipWhile((line) =>
        line !=
        'Files: lib/protocol_custom_generated.dart, lib/protocol_generated.dart')
    .skip(2)
    .map((line) => line.isEmpty ? '//' : '// $line')
    .join('\n');

final String localLicensePath = '$languageServerProtocolPackagePath/LICENSE';
final String localSpecPath =
    '$languageServerProtocolPackagePath/lsp_meta_model.json';

final String sdkRootPath =
    File(Platform.script.toFilePath()).parent.parent.parent.parent.parent.path;

final Uri specLicenseUri = Uri.parse(
    'https://microsoft.github.io/language-server-protocol/License-code.txt');

/// The URI of the version of the LSP meta model to generate from. This should
/// be periodically updated to the latest version.
final Uri specUri = Uri.parse(
    'https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/metaModel/metaModel.json');

Future<void> downloadSpec() async {
  final specResp = await http.get(specUri);
  final licenseResp = await http.get(specLicenseUri);

  assert(specResp.statusCode == 200);
  assert(licenseResp.statusCode == 200);

  final dartSdkLicense = await File('$sdkRootPath/LICENSE').readAsString();
  await File(localSpecPath).writeAsString(specResp.body);
  await File(localLicensePath).writeAsString('''
$dartSdkLicense

------------------

Files: lsp_meta_model.json
Files: lib/protocol_custom_generated.dart, lib/protocol_generated.dart

${licenseResp.body}
''');
}

String generatedFileHeader(int year, {bool importCustom = false}) => '''
$licenseComment

// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/tool/lsp_spec/generate_all.dart".

import 'dart:convert' show JsonEncoder;

import 'package:collection/collection.dart';
import 'package:language_server_protocol/json_parsing.dart';
import 'package:language_server_protocol/protocol_special.dart';
import 'package:language_server_protocol/protocol${importCustom ? '_custom' : ''}_generated.dart';

const jsonEncoder = JsonEncoder.withIndent('    ');

''';

List<LspEntity> getCustomClasses() {
  /// Helper to create an interface type.
  Interface interface(String name, List<Member> fields,
      {String? baseType, String? comment, bool abstract = false}) {
    return Interface(
      name: name,
      abstract: abstract,
      comment: comment,
      baseTypes: [if (baseType != null) TypeReference(baseType)],
      members: fields,
    );
  }

  /// Helper to create a field.
  Field field(
    String name, {
    String? comment,
    required String type,
    bool array = false,
    bool literal = false,
    bool canBeNull = false,
    bool canBeUndefined = false,
  }) {
    final fieldType = array
        ? ArrayType(TypeReference(type))
        : literal
            ? LiteralType(TypeReference.string, type)
            : TypeReference(type);

    return Field(
      name: name,
      comment: comment,
      type: fieldType,
      allowsNull: canBeNull,
      allowsUndefined: canBeUndefined,
    );
  }

  final customTypes = <LspEntity>[
    TypeAlias(
      name: 'LSPAny',
      baseType: TypeReference.LspAny,
      isRename: false,
    ),
    TypeAlias(
      name: 'LSPObject',
      baseType: TypeReference.LspObject,
      isRename: false,
    ),
    // The DocumentFilter more complex in v3.17's meta_model (to allow
    // TextDocumentFilters to be guaranteed to have at least one of language,
    // pattern, scheme) but we only ever use a single type in the server so
    // for compatibility, alias that type to the original TS-spec name.
    // TODO(dantup): Improve this after the TS->JSON Spec migration.
    TypeAlias(
      name: 'DocumentFilter',
      baseType: TypeReference('TextDocumentFilter2'),
      isRename: true,
    ),
    // Similarly, the meta_model includes String as an option for
    // DocumentSelector which is deprecated and we never previously supported
    // (because the TypeScript spec did not include it in the type) so preserve
    // that.
    // TODO(dantup): Improve this after the TS->JSON Spec migration.
    TypeAlias(
      name: 'DocumentSelector',
      baseType: ArrayType(TypeReference('TextDocumentFilterWithScheme')),
      isRename: true,
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
          type: UnionType([TypeReference.int, TypeReference.string]),
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
          type: UnionType([TypeReference.int, TypeReference.string]),
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
      baseType: TypeReference('Uri'),
      isRename: false,
    ),
    // The LSP Spec uses "URI" but since that's fairly generic and will show up
    // everywhere in code completion, we rename it to "LspUri" before using
    // a typedef onto the Dart URI class.
    TypeAlias(
      name: 'URI',
      baseType: TypeReference('LSPUri'),
      isRename: true,
    ),
    TypeAlias(
      name: 'LSPUri',
      baseType: TypeReference('Uri'),
      isRename: false,
    ),

    interface('DartDiagnosticServer', [field('port', type: 'int')]),
    interface('AnalyzerStatusParams', [field('isAnalyzing', type: 'boolean')]),
    interface('PublishClosingLabelsParams', [
      field('uri', type: 'Uri'),
      field('labels', type: 'ClosingLabel', array: true),
    ]),
    interface('OpenUriParams', [
      field('uri', type: 'Uri'),
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
        [field('uri', type: 'Uri'), field('outline', type: 'Outline')]),
    interface('Outline', [
      field('element', type: 'Element'),
      field('range', type: 'Range'),
      field('codeRange', type: 'Range'),
      field('children', type: 'Outline', array: true, canBeUndefined: true),
    ]),
    interface('PublishFlutterOutlineParams', [
      field('uri', type: 'Uri'),
      field('outline', type: 'FlutterOutline'),
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
          type: 'FlutterOutline', array: true, canBeUndefined: true),
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
      'DartCompletionResolutionInfo',
      [
        field(
          'file',
          type: 'string',
          comment: 'The file where the completion is being inserted.\n\n'
              'This is used to compute where to add the import.',
        ),
        field(
          'importUris',
          type: 'string',
          array: true,
          comment: 'The URIs to be imported if this completion is selected.',
        ),
        field(
          'ref',
          type: 'string',
          canBeUndefined: true,
          comment: 'The ElementLocation of the item being completed.\n\n'
              'This is used to provide documentation in the resolved response.',
        ),
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
    interface(
      'TypeHierarchyAnchor',
      [
        field(
          'ref',
          type: 'string',
          comment: 'The ElementLocation for this anchor element.',
        ),
        field(
          'path',
          type: 'int',
          array: true,
          comment: 'Indices used to navigate from this anchor to the element.',
        ),
      ],
    ),
    interface(
      'TypeHierarchyItemInfo',
      [
        field(
          'ref',
          type: 'string',
          comment:
              'The ElementLocation for this element, used to re-locate the '
              'element when subtypes/supertypes are '
              'fetched later.',
        ),
        field(
          'anchor',
          type: 'TypeHierarchyAnchor',
          comment:
              'An anchor element that can be used to navigate to this element '
              'preserving type arguments.',
          canBeUndefined: true,
        ),
      ],
    ),
    TypeAlias(
      name: 'TextDocumentEditEdits',
      baseType: ArrayType(
        UnionType([
          TypeReference('SnippetTextEdit'),
          TypeReference('AnnotatedTextEdit'),
          TypeReference('TextEdit'),
        ]),
      ),
      isRename: false,
    ),
    //
    // Command parameter support
    //
    interface(
      'CommandParameter',
      [
        field(
          'parameterLabel',
          type: 'String',
          comment:
              'A human-readable label to be displayed in the UI affordance '
              'used to prompt the user for the value of the parameter.',
        ),
        AbstractGetter(
          name: 'kind',
          type: TypeReference.string,
          comment: 'The kind of this parameter. The client may use different '
              'UIs based on this value.',
        ),
        AbstractGetter(
          name: 'defaultValue',
          type: TypeReference.LspAny,
          comment: 'An optional default value for the parameter. The type of '
              'this value may vary between parameter kinds but must always be '
              'something that can be converted directly to/from JSON.',
        ),
      ],
      abstract: true,
      comment: 'Information about one of the arguments needed by the command.'
          '\n\n'
          'A list of parameters is sent in the `data` field of the '
          '`CodeAction` returned by the server. The values of the parameters '
          'should appear in the `args` field of the `Command` sent to the '
          'server in the same order as the corresponding parameters.',
    ),
    interface(
      'SaveUriCommandParameter',
      [
        field(
          'kind',
          type: 'saveUri',
          literal: true,
        ),
        field(
          'defaultValue',
          type: 'String',
          canBeNull: true,
          canBeUndefined: true,
          comment: 'An optional default URI for the parameter.',
        ),
        field(
          'parameterTitle',
          type: 'String',
          comment: 'A title that may be displayed on a file dialog.',
        ),
        field(
          'actionLabel',
          type: 'String',
          comment: 'A label for the file dialogs action button.',
        ),
        Field(
          name: 'filters',
          type: MapType(TypeReference.string, ArrayType(TypeReference.string)),
          allowsNull: true,
          allowsUndefined: true,
          comment: 'A set of file filters for a file dialog. '
              'Keys of the map are textual names ("Dart") and the value '
              'is a list of file extensions (["dart"]).',
        ),
      ],
      baseType: 'CommandParameter',
      comment: 'Information about a Save URI argument needed by the command.',
    ),
  ];
  return customTypes;
}

Future<List<LspEntity>> getSpecClasses(ArgResults args) async {
  var download = args[argDownload] as bool;
  if (download) {
    await downloadSpec();
  }

  final file = File(localSpecPath);
  var model = LspMetaModelReader().readFile(file);
  model = LspMetaModelCleaner().cleanModel(model);

  return model.types;
}

class AbstractGetter extends Member {
  // ignore:unreachable_from_main
  final TypeBase type;

  AbstractGetter({
    required super.name,
    super.comment,
    required this.type,
  });
}
