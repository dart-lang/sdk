// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analysis_server/src/services/correction/strings.dart';
import 'package:http/http.dart' as http;

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import 'codegen_dart.dart';
import 'markdown.dart';
import 'typescript.dart';
import 'typescript_parser.dart';

const argHelp = 'help';
const argDownload = 'download';

final argParser = new ArgParser()
  ..addFlag(argHelp, hide: true)
  ..addFlag(argDownload,
      negatable: false,
      abbr: 'd',
      help:
          'Download the latest version of the LSP spec before generating types');

main(List<String> arguments) async {
  final args = argParser.parse(arguments);
  if (args[argHelp]) {
    print(argParser.usage);
    return;
  }

  final String script = Platform.script.toFilePath();
  // 3x parent = file -> lsp_spec -> tool -> analysis_server.
  final String packageFolder = new File(script).parent.parent.parent.path;
  final String outFolder = path.join(packageFolder, 'lib', 'lsp_protocol');
  new Directory(outFolder).createSync();

  await writeSpecClasses(args, outFolder);
  await writeCustomClasses(args, outFolder);
}

Future writeSpecClasses(ArgResults args, String outFolder) async {
  if (args[argDownload]) {
    await downloadSpec();
  }
  final String spec = await readSpec();

  final List<AstNode> types = extractTypeScriptBlocks(spec)
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

  final String output = generateDartForTypes(types);

  new File(path.join(outFolder, 'protocol_generated.dart'))
      .writeAsStringSync(generatedFileHeader(2018) + output);
}

/// Writes classes used by Dart's custom LSP methods.
Future writeCustomClasses(ArgResults args, String outFolder) async {
  interface(String name, List<Member> fields) {
    return new Interface(null, Token.identifier(name), [], [], fields);
  }

  field(String name, {String type, canBeNull: false, canBeUndefined: false}) {
    return new Field(null, Token.identifier(name), Type.identifier(type),
        canBeNull, canBeUndefined);
  }

  final List<AstNode> customTypes = [
    interface('DartDiagnosticServer', [field('port', type: 'number')]),
  ];

  final String output = generateDartForTypes(customTypes);

  new File(path.join(outFolder, 'protocol_custom_generated.dart'))
      .writeAsStringSync(generatedFileHeader(2019) + output);
}

Namespace extractMethodsEnum(String spec) {
  Const toConstant(String value) {
    final comment = new Comment(
        new Token(TokenType.COMMENT, '''Constant for the '$value' method.'''));

    // Generate a safe name for the member from the string. Those that start with
    // $/ will have the prefix removed and all slashes should be replaced with
    // underscores.
    final safeMemberName = value.replaceAll(r'$/', '').replaceAll('/', '_');

    return new Const(
      comment,
      new Token.identifier(safeMemberName),
      new Type.identifier('string'),
      new Token(TokenType.STRING, "'$value'"),
    );
  }

  final comment = new Comment(new Token(TokenType.COMMENT,
      'Valid LSP methods known at the time of code generation from the spec.'));
  final methodConstants = extractMethodNames(spec).map(toConstant).toList();

  return new Namespace(
      comment, new Token.identifier('Method'), methodConstants);
}

String generatedFileHeader(int year) => '''
// Copyright (c) $year, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/tool/lsp_spec/generate_all.dart".

// ignore_for_file: deprecated_member_use
// ignore_for_file: unnecessary_brace_in_string_interps
// ignore_for_file: unused_import

import 'dart:core' hide deprecated;
import 'dart:core' as core show deprecated;
import 'dart:convert' show JsonEncoder;
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart'
    show listEqual, mapEqual;
import 'package:analyzer/src/generated/utilities_general.dart';

const jsonEncoder = const JsonEncoder.withIndent('    ');

''';

final Uri specUri = Uri.parse(
    'https://raw.githubusercontent.com/Microsoft/language-server-protocol/gh-pages/specification.md');
final Uri specLicenseUri = Uri.parse(
    'https://raw.githubusercontent.com/Microsoft/language-server-protocol/gh-pages/License.txt');
final String localSpecPath = path.join(
    path.dirname(Platform.script.toFilePath()), 'lsp_specification.md');

/// Pattern to extract inline types from the `result: {xx, yy }` notes in the spec.
/// Doesn't parse past full stops as some of these have english sentences tagged on
/// the end that we don't want to parse.
final _resultsInlineTypesPattern = new RegExp(r'''\* result:[^\.]*({.*})''');

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

    return new InlineInterface(newName, interface.members);
  }

  return _resultsInlineTypesPattern
      .allMatches(spec)
      .map((m) => m.group(1).trim())
      .toList()
      .map(toInterface)
      .toList();
}

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
  return new File(localSpecPath).writeAsString(text.join('\n\n---\n\n'));
}

Future<String> readSpec() => new File(localSpecPath).readAsString();

/// Returns whether a script block should be parsed or not.
bool shouldIncludeScriptBlock(String input) {
  // We can't parse literal arrays, but this script block is just an example
  // and not actually referenced anywhere.
  if (input.trim() == r"export const EOL: string[] = ['\n', '\r\n', '\r'];") {
    return false;
  }

  // There are some code blocks that just have example JSON in them.
  if (input.startsWith('{') && input.endsWith('}')) {
    return false;
  }

  return true;
}
