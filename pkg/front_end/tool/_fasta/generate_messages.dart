// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'dart:isolate';

import 'package:yaml/yaml.dart' show loadYaml;

import 'package:front_end/src/fasta/parser/error_kind.dart' show ErrorKind;

main(List<String> arguments) async {
  var port = new ReceivePort();
  Uri messagesFile = Platform.script.resolve("../../messages.yaml");
  Map yaml = loadYaml(await new File.fromUri(messagesFile).readAsStringSync());
  Set<String> names =
      new Set<String>.from(yaml.keys.map((String s) => "ErrorKind.$s"));
  Set<String> kinds =
      new Set<String>.from(ErrorKind.values.map((kind) => "$kind"));
  Set<String> difference = kinds.difference(names);
  if (difference.isNotEmpty) {
    Uri errorKindFile = await Isolate.resolvePackageUri(
        Uri.parse('package:front_end/src/fasta/parser/error_kind.dart'));
    throw "Mismatch between '${errorKindFile.toFilePath()}' and"
        " '${messagesFile.toFilePath()}': ${difference.join(' ')}.";
  }
  StringBuffer sb = new StringBuffer();

  sb.writeln("""
// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// NOTE: THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/front_end/messages.yaml' and run
// 'pkg/front_end/tool/_fasta/generate_messages.dart' to update.

library fasta.problems;

import 'package:front_end/src/fasta/scanner/token.dart' show Token;

import 'package:front_end/src/fasta/parser/error_kind.dart' show ErrorKind;
""");

  yaml.forEach((String name, description) {
    while (description is String) {
      description = yaml[description];
    }
    Map map = description;
    sb.writeln(compileTemplate(name, map['template'], map['tip']));
  });

  Uri problemsFile = await Isolate.resolvePackageUri(
      Uri.parse('package:front_end/src/fasta/problems.dart'));
  await new File.fromUri(problemsFile).writeAsString("$sb", flush: true);
  port.close();
}

final RegExp placeholderPattern = new RegExp("#[a-zA-Z0-9_]+");

String compileTemplate(String name, String template, String tip) {
  var parameters = new Set<String>();
  var conversions = new Set<String>();
  var arguments = new Set<String>();
  for (Match match in placeholderPattern.allMatches("$template$tip")) {
    switch (match[0]) {
      case "#character":
        parameters.add("String character");
        arguments.add("'character': character,");
        break;

      case "#unicode":
        parameters.add("int codePoint");
        conversions.add("String unicode = "
            "\"(U+\${codePoint.toRadixString(16).padLeft(4, '0')})\";");
        arguments.add("'codePoint': codePoint,");
        break;

      case "#name":
        parameters.add("String name");
        arguments.add("'name': name,");
        break;

      case "#lexeme":
        parameters.add("Token token");
        conversions.add("String lexeme = token.lexeme;");
        arguments.add("'token': token,");
        break;

      case "#string":
        parameters.add("String string");
        arguments.add("'string': string,");
        break;
    }
  }

  String interpolate(String name, String text) {
    if (text == null) return "";
    return "  '$name': "
        "\"${text.replaceAll(r'$', r'\$').replaceAll('#', '\$')}\",";
  }

  return """
problem$name(${parameters.join(', ')}) {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  ${conversions.join('\n  ')}
  return {
  ${interpolate('message', template)}
  ${interpolate('tip', tip)}
    'code': ErrorKind.$name,
    'arguments': {
      ${arguments.join('\n      ')}
    },
  };
}
""";
}
