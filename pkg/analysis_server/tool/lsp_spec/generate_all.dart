// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analysis_server/src/services/correction/strings.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import 'codegen_dart.dart';
import 'markdown.dart';
import 'typescript.dart';
import 'typescript_parser.dart';

main() async {
  final String script = Platform.script.toFilePath();
  // 3x parent = file -> lsp_spec -> tool -> analysis_server.
  final String packageFolder = new File(script).parent.parent.parent.path;
  final String outFolder = path.join(packageFolder, 'lib', 'lsp_protocol');
  new Directory(outFolder).createSync();

  final String spec = await fetchSpec();
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
      .writeAsStringSync(_generatedFileHeader + output);
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

const _generatedFileHeader = '''
// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/tool/lsp_spec/generate_all.dart".

// ignore_for_file: deprecated_member_use
// ignore_for_file: unnecessary_brace_in_string_interps

import 'dart:core' hide deprecated;
import 'dart:core' as core show deprecated;
import 'dart:convert' show JsonEncoder;
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart' show listEqual, mapEqual;
import 'package:analyzer/src/generated/utilities_general.dart';

const jsonEncoder = const JsonEncoder.withIndent('    ');

''';

final Uri specUri = Uri.parse(
    'https://raw.githubusercontent.com/Microsoft/language-server-protocol/gh-pages/specification.md');

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

Future<String> fetchSpec() async {
  final resp = await http.get(specUri);
  return resp.body;
}

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
