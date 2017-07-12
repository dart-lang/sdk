// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'dart:isolate';

import 'package:yaml/yaml.dart' show loadYaml;

import 'package:dart_style/dart_style.dart' show DartFormatter;

main(List<String> arguments) async {
  var port = new ReceivePort();
  Uri messagesFile = Platform.script.resolve("../../messages.yaml");
  Map yaml = loadYaml(await new File.fromUri(messagesFile).readAsStringSync());
  StringBuffer sb = new StringBuffer();

  sb.writeln("""
// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// NOTE: THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/front_end/messages.yaml' and run
// 'pkg/front_end/tool/_fasta/generate_messages.dart' to update.

part of fasta.codes;
""");

  yaml.forEach((String name, description) {
    while (description is String) {
      description = yaml[description];
    }
    Map map = description;
    sb.writeln(compileTemplate(name, map['template'], map['tip'],
        map['analyzerCode'], map['dart2jsCode']));
  });

  String dartfmtedText = new DartFormatter().format("$sb");

  Uri problemsFile = await Isolate.resolvePackageUri(
      Uri.parse('package:front_end/src/fasta/fasta_codes_generated.dart'));
  await new File.fromUri(problemsFile)
      .writeAsString(dartfmtedText, flush: true);
  port.close();
}

final RegExp placeholderPattern = new RegExp("#[a-zA-Z0-9_]+");

String compileTemplate(String name, String template, String tip,
    String analyzerCode, String dart2jsCode) {
  var parameters = new Set<String>();
  var conversions = new Set<String>();
  var arguments = new Set<String>();
  for (Match match in placeholderPattern.allMatches("$template${tip ?? ''}")) {
    switch (match[0]) {
      case "#character":
        parameters.add("String character");
        arguments.add("'character': character");
        break;

      case "#unicode":
        parameters.add("int codePoint");
        conversions.add("String unicode = "
            "\"(U+\${codePoint.toRadixString(16).padLeft(4, '0')})\";");
        arguments.add("'codePoint': codePoint");
        break;

      case "#name":
        parameters.add("String name");
        arguments.add("'name': name");
        break;

      case "#name2":
        parameters.add("String name2");
        arguments.add("'name2': name2");
        break;

      case "#lexeme":
        parameters.add("Token token");
        conversions.add("String lexeme = token.lexeme;");
        arguments.add("'token': token");
        break;

      case "#string":
        parameters.add("String string");
        arguments.add("'string': string");
        break;

      case "#string2":
        parameters.add("String string2");
        arguments.add("'string2': string2");
        break;

      case "#uri":
        parameters.add("Uri uri_");
        conversions.add("String uri = relativizeUri(uri_);");
        arguments.add("'uri': uri_");
        break;

      case "#uri2":
        parameters.add("Uri uri2_");
        conversions.add("String uri2 = relativizeUri(uri2_);");
        arguments.add("'uri': uri2_");
        break;

      default:
        throw "Unhandled placeholder in template: ${match[0]}";
    }
  }

  String interpolate(String name, String text) {
    return "$name: "
        "\"\"\"${text.replaceAll(r'$', r'\$').replaceAll('#', '\$')}\"\"\"";
  }

  List<String> codeArguments = <String>[];
  if (analyzerCode != null) {
    codeArguments.add('analyzerCode: "$analyzerCode"');
  }
  if (dart2jsCode != null) {
    codeArguments.add('dart2jsCode: "$dart2jsCode"');
  }

  if (parameters.isEmpty && conversions.isEmpty && arguments.isEmpty) {
    if (template != null) {
      codeArguments.add('message: r"""$template"""');
    }
    if (tip != null) {
      codeArguments.add('tip: r"""$tip"""');
    }

    return """
// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> code$name = message$name;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode message$name =
    const MessageCode(\"$name\", ${codeArguments.join(', ')});
""";
  }

  List<String> templateArguments = <String>[];
  if (template != null) {
    templateArguments.add('messageTemplate: r"""$template"""');
  }
  if (tip != null) {
    templateArguments.add('tipTemplate: r"""$tip"""');
  }

  templateArguments.add("withArguments: _withArguments$name");

  List<String> messageArguments = <String>[];
  messageArguments.add(interpolate("message", template));
  if (tip != null) {
    messageArguments.add(interpolate("tip", tip));
  }
  messageArguments.add("arguments: { ${arguments.join(', ')} }");

  return """
// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(${parameters.join(', ')})> template$name =
    const Template<Message Function(${parameters.join(', ')})>(
        ${templateArguments.join(', ')});

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(${parameters.join(', ')})> code$name =
    const Code<Message Function(${parameters.join(', ')})>(
        \"$name\", template$name, ${codeArguments.join(', ')});

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArguments$name(${parameters.join(', ')}) {
  ${conversions.join('\n  ')}
  return new Message(
     code$name,
     ${messageArguments.join(', ')});
}
""";
}
