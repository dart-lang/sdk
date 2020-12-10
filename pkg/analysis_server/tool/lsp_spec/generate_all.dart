// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analysis_server/src/utilities/strings.dart';
import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import 'codegen_dart.dart';
import 'markdown.dart';
import 'typescript.dart';
import 'typescript_parser.dart';

Future<void> main(List<String> arguments) async {
  final args = argParser.parse(arguments);
  if (args[argHelp]) {
    print(argParser.usage);
    return;
  }

  final script = Platform.script.toFilePath();
  // 3x parent = file -> lsp_spec -> tool -> analysis_server.
  final packageFolder = File(script).parent.parent.parent.path;
  final outFolder = path.join(packageFolder, 'lib', 'lsp_protocol');
  Directory(outFolder).createSync();

  // Collect definitions for types in the spec and our custom extensions.
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

final String localSpecPath = path.join(
    path.dirname(Platform.script.toFilePath()), 'lsp_specification.md');

final Uri specLicenseUri = Uri.parse(
    'https://raw.githubusercontent.com/Microsoft/language-server-protocol/gh-pages/License.txt');

/// The URI of the version of the spec to generate from. This should be periodically updated as
/// there's no longer a stable URI for the latest published version.
final Uri specUri = Uri.parse(
    'https://raw.githubusercontent.com/microsoft/language-server-protocol/gh-pages/_specifications/specification-3-16.md');

/// Pattern to extract inline types from the `result: {xx, yy }` notes in the spec.
/// Doesn't parse past full stops as some of these have english sentences tagged on
/// the end that we don't want to parse.
final _resultsInlineTypesPattern = RegExp(r'''\* result:[^\.{}]*({[^\.`]*})''');

Future<void> downloadSpec() async {
  final specResp = await http.get(specUri);
  final licenseResp = await http.get(specLicenseUri);
  final text = [
    '''
This is an unmodified copy of the Language Server Protocol Specification,
downloaded from $specUri. It is the version of the specification that was
used to generate a portion of the Dart code used to support the protocol.

To regenerate the generated code, run the script in
"analysis_server/tool/lsp_spec/generate_all.dart" with no arguments. To
download the latest version of the specification before regenerating the
code, run the same script with an argument of "--download".''',
    licenseResp.body,
    specResp.body
  ];
  return File(localSpecPath).writeAsString(text.join('\n\n---\n\n'));
}

Namespace extractMethodsEnum(String spec) {
  Const toConstant(String value) {
    final comment = Comment(
        Token(TokenType.COMMENT, '''Constant for the '$value' method.'''));

    // Generate a safe name for the member from the string. Those that start with
    // $/ will have the prefix removed and all slashes should be replaced with
    // underscores.
    final safeMemberName = value.replaceAll(r'$/', '').replaceAll('/', '_');

    return Const(
      comment,
      Token.identifier(safeMemberName),
      Type.identifier('string'),
      Token(TokenType.STRING, "'$value'"),
    );
  }

  final comment = Comment(Token(TokenType.COMMENT,
      'Valid LSP methods known at the time of code generation from the spec.'));
  final methodConstants = extractMethodNames(spec).map(toConstant).toList();

  return Namespace(comment, Token.identifier('Method'), methodConstants);
}

/// Extract inline types found directly in the `results:` sections of the spec
/// that are not declared with their own names elsewhere.
List<AstNode> extractResultsInlineTypes(String spec) {
  InlineInterface toInterface(String typeDef) {
    // The definition passed here will be a bare inline type, such as:
    //
    //     { range: Range, placeholder: string }
    //
    // In order to parse this, we'll just format it as a type alias and then
    // run it through the standard parsing code.
    final typeAlias = 'type temp = ${typeDef.replaceAll(',', ';')};';

    final parsed = parseString(typeAlias);

    // Extract the InlineInterface that was created.
    InlineInterface interface = parsed.firstWhere((t) => t is InlineInterface);

    // Create a new name based on the fields.
    var newName = interface.members.map((m) => capitalize(m.name)).join('And');

    return InlineInterface(newName, interface.members);
  }

  return _resultsInlineTypesPattern
      .allMatches(spec)
      .map((m) => m.group(1).trim())
      .toList()
      .map(toInterface)
      .toList();
}

String generatedFileHeader(int year, {bool importCustom = false}) => '''
// Copyright (c) $year, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/tool/lsp_spec/generate_all.dart".

// ignore_for_file: annotate_overrides
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: unnecessary_brace_in_string_interps
// ignore_for_file: unused_import
// ignore_for_file: unused_shown_name

import 'dart:core' hide deprecated;
import 'dart:core' as core show deprecated;
import 'dart:convert' show JsonEncoder;
import 'package:analysis_server/lsp_protocol/protocol${importCustom ? '_custom' : ''}_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/json_parsing.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart'
    show listEqual, mapEqual;
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:meta/meta.dart';

const jsonEncoder = JsonEncoder.withIndent('    ');

''';

List<AstNode> getCustomClasses() {
  Interface interface(String name, List<Member> fields, {String baseType}) {
    return Interface(
      null,
      Token.identifier(name),
      [],
      [if (baseType != null) Type.identifier(baseType)],
      fields,
    );
  }

  Field field(String name,
      {String type, array = false, canBeNull = false, canBeUndefined = false}) {
    var fieldType =
        array ? ArrayType(Type.identifier(type)) : Type.identifier(type);

    return Field(
        null, Token.identifier(name), fieldType, canBeNull, canBeUndefined);
  }

  final customTypes = <AstNode>[
    interface('DartDiagnosticServer', [field('port', type: 'number')]),
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
      'CompletionItemResolutionInfo',
      [
        field('file', type: 'string'),
        field('offset', type: 'number'),
      ],
    ),
    interface(
      'DartCompletionItemResolutionInfo',
      [
        field('libId', type: 'number'),
        field('displayUri', type: 'string'),
        field('rOffset', type: 'number'),
        field('rLength', type: 'number'),
      ],
      baseType: 'CompletionItemResolutionInfo',
    ),
  ];
  return customTypes;
}

Future<List<AstNode>> getSpecClasses(ArgResults args) async {
  if (args[argDownload]) {
    await downloadSpec();
  }
  final spec = await readSpec();

  final types = extractTypeScriptBlocks(spec)
      .where(shouldIncludeScriptBlock)
      .map(parseString)
      .expand((f) => f)
      .where(includeTypeDefinitionInOutput)
      .toList();

  // Generate an enum for all of the request methods to avoid strings.
  types.add(extractMethodsEnum(spec));

  // Extract additional inline types that are specificed online in the `results`
  // section of the doc.
  types.addAll(extractResultsInlineTypes(spec));
  return types;
}

Future<String> readSpec() => File(localSpecPath).readAsString();

/// Returns whether a script block should be parsed or not.
bool shouldIncludeScriptBlock(String input) {
  // Skip over some typescript blocks that are known sample code and not part
  // of the LSP spec.
  if (input.trim() == r"export const EOL: string[] = ['\n', '\r\n', '\r'];" ||
      input.startsWith('textDocument.codeAction.resolveSupport =')) {
    return false;
  }

  // There are some code blocks that just have example JSON in them.
  if (input.startsWith('{') && input.endsWith('}')) {
    return false;
  }

  // There are some example blocks that just contain arrays with no definitions.
  // They're most easily noted by ending with `]` which no valid TypeScript blocks
  // do.
  if (input.trim().endsWith(']')) {
    return false;
  }

  // There's a chunk of typescript that is just a partial snippet from a real
  // interface declared elsewhere that we can only detect by the leading comment.
  if (input
      .replaceAll('\r', '')
      .startsWith('/**\n\t * Window specific client capabilities.')) {
    return false;
  }

  return true;
}
