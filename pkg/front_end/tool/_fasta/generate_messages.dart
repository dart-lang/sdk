// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show File, exitCode;

import "package:_fe_analyzer_shared/src/messages/severity.dart"
    show severityEnumNames;

import 'package:dart_style/dart_style.dart' show DartFormatter;

import 'package:yaml/yaml.dart' show loadYaml;

import '../../test/utils/io_utils.dart' show computeRepoDirUri;

void main(List<String> arguments) {
  final Uri repoDir = computeRepoDirUri();
  Messages message = generateMessagesFiles(repoDir);
  if (message.sharedMessages.trim().isEmpty ||
      message.cfeMessages.trim().isEmpty) {
    print("Bailing because of errors: "
        "Refusing to overwrite with empty file!");
  } else {
    new File.fromUri(computeSharedGeneratedFile(repoDir))
        .writeAsStringSync(message.sharedMessages, flush: true);
    new File.fromUri(computeCfeGeneratedFile(repoDir))
        .writeAsStringSync(message.cfeMessages, flush: true);
  }
}

Uri computeSharedGeneratedFile(Uri repoDir) {
  return repoDir
      .resolve("pkg/_fe_analyzer_shared/lib/src/messages/codes_generated.dart");
}

Uri computeCfeGeneratedFile(Uri repoDir) {
  return repoDir
      .resolve("pkg/front_end/lib/src/fasta/fasta_codes_cfe_generated.dart");
}

class Messages {
  final String sharedMessages;
  final String cfeMessages;

  Messages(this.sharedMessages, this.cfeMessages);
}

Messages generateMessagesFiles(Uri repoDir) {
  Uri messagesFile = repoDir.resolve("pkg/front_end/messages.yaml");
  Map<dynamic, dynamic> yaml =
      loadYaml(new File.fromUri(messagesFile).readAsStringSync());
  StringBuffer sharedMessages = new StringBuffer();
  StringBuffer cfeMessages = new StringBuffer();

  const String preamble1 = """
// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

""";

  const String preamble2 = """

// NOTE: THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/front_end/messages.yaml' and run
// 'pkg/front_end/tool/fasta generate-messages' to update.

// ignore_for_file: lines_longer_than_80_chars
""";

  sharedMessages.writeln(preamble1);
  sharedMessages.writeln(preamble2);
  sharedMessages.writeln("""
part of _fe_analyzer_shared.messages.codes;
""");

  cfeMessages.writeln(preamble1);
  cfeMessages.writeln("""

""");
  cfeMessages.writeln(preamble2);
  cfeMessages.writeln("""
part of fasta.codes;
""");

  bool hasError = false;
  int largestIndex = 0;
  final indexNameMap = new Map<int, String>();

  List<String> keys = yaml.keys.cast<String>().toList()..sort();
  for (String name in keys) {
    var description = yaml[name];
    while (description is String) {
      description = yaml[description];
    }
    Map<dynamic, dynamic>? map = description;
    if (map == null) {
      throw "No 'problemMessage:' in key $name.";
    }
    var index = map['index'];
    if (index != null) {
      if (index is! int || index < 1) {
        print('Error: Expected positive int for "index:" field in $name,'
            ' but found $index');
        hasError = true;
        index = -1;
        // Continue looking for other problems.
      } else {
        String? otherName = indexNameMap[index];
        if (otherName != null) {
          print('Error: The "index:" field must be unique, '
              'but is the same for $otherName and $name');
          hasError = true;
          // Continue looking for other problems.
        } else {
          indexNameMap[index] = name;
          if (largestIndex < index) {
            largestIndex = index;
          }
        }
      }
    }
    Template template = compileTemplate(name, index, map['problemMessage'],
        map['correctionMessage'], map['analyzerCode'], map['severity']);
    if (template.isShared) {
      sharedMessages.writeln(template.text);
    } else {
      cfeMessages.writeln(template.text);
    }
  }
  if (largestIndex > indexNameMap.length) {
    print('Error: The "index:" field values should be unique, consecutive'
        ' whole numbers starting with 1.');
    hasError = true;
    // Fall through to print more information.
  }
  if (hasError) {
    exitCode = 1;
    print('The largest index is $largestIndex');
    final sortedIndices = indexNameMap.keys.toList()..sort();
    int nextAvailableIndex = largestIndex + 1;
    for (int index = 1; index <= sortedIndices.length; ++index) {
      if (sortedIndices[index - 1] != index) {
        nextAvailableIndex = index;
        break;
      }
    }
    print('The next available index is ${nextAvailableIndex}');
    return new Messages('', '');
  }

  return new Messages(new DartFormatter().format("$sharedMessages"),
      new DartFormatter().format("$cfeMessages"));
}

final RegExp placeholderPattern =
    new RegExp("#\([-a-zA-Z0-9_]+\)(?:%\([0-9]*\)\.\([0-9]+\))?");

class Template {
  final String text;
  final isShared;

  Template(this.text, {this.isShared}) : assert(isShared != null);
}

Template compileTemplate(String name, int? index, String? problemMessage,
    String? correctionMessage, Object? analyzerCode, String? severity) {
  if (problemMessage == null) {
    print('Error: missing problemMessage for message: $name');
    exitCode = 1;
    return new Template('', isShared: true);
  }
  // Remove trailing whitespace. This is necessary for templates defined with
  // `|` (verbatim) as they always contain a trailing newline that we don't
  // want.
  problemMessage = problemMessage.trimRight();
  var parameters = new Set<String>();
  var conversions = new Set<String>();
  var conversions2 = new Set<String>();
  var arguments = new Set<String>();
  bool hasLabeler = false;
  bool canBeShared = true;
  void ensureLabeler() {
    if (hasLabeler) return;
    conversions
        .add("TypeLabeler labeler = new TypeLabeler(isNonNullableByDefault);");
    hasLabeler = true;
    canBeShared = false;
  }

  for (Match match in placeholderPattern
      .allMatches("$problemMessage\n${correctionMessage ?? ''}")) {
    String name = match[1]!;
    String? padding = match[2];
    String? fractionDigits = match[3];

    String format(String name) {
      String conversion;
      if (fractionDigits == null) {
        conversion = "'\$$name'";
      } else {
        conversion = "$name.toStringAsFixed($fractionDigits)";
      }
      if (padding!.isNotEmpty) {
        if (padding.startsWith("0")) {
          conversion += ".padLeft(${int.parse(padding)}, '0')";
        } else {
          conversion += ".padLeft(${int.parse(padding)})";
        }
      }
      return conversion;
    }

    switch (name) {
      case "character":
        parameters.add("String character");
        conversions.add("if (character.runes.length != 1)"
            "throw \"Not a character '\${character}'\";");
        arguments.add("'$name': character");
        break;

      case "unicode":
        // Write unicode value using at least four (but otherwise no more than
        // necessary) hex digits, using uppercase letters.
        // http://www.unicode.org/versions/Unicode10.0.0/appA.pdf
        parameters.add("int codePoint");
        conversions.add("String unicode = \"U+\${codePoint.toRadixString(16)"
            ".toUpperCase().padLeft(4, '0')}\";");
        arguments.add("'$name': codePoint");
        break;

      case "name":
        parameters.add("String name");
        conversions.add("if (name.isEmpty) throw 'No name provided';");
        arguments.add("'$name': name");
        conversions.add("name = demangleMixinApplicationName(name);");
        break;

      case "name2":
        parameters.add("String name2");
        conversions.add("if (name2.isEmpty) throw 'No name provided';");
        arguments.add("'$name': name2");
        conversions.add("name2 = demangleMixinApplicationName(name2);");
        break;

      case "name3":
        parameters.add("String name3");
        conversions.add("if (name3.isEmpty) throw 'No name provided';");
        arguments.add("'$name': name3");
        conversions.add("name3 = demangleMixinApplicationName(name3);");
        break;

      case "name4":
        parameters.add("String name4");
        conversions.add("if (name4.isEmpty) throw 'No name provided';");
        arguments.add("'$name': name4");
        conversions.add("name4 = demangleMixinApplicationName(name4);");
        break;

      case "nameOKEmpty":
        parameters.add("String nameOKEmpty");
        conversions.add("if (nameOKEmpty.isEmpty) "
            "nameOKEmpty = '(unnamed)';");
        arguments.add("'nameOKEmpty': nameOKEmpty");
        break;

      case "names":
        parameters.add("List<String> _names");
        conversions.add("if (_names.isEmpty) throw 'No names provided';");
        arguments.add("'$name': _names");
        conversions.add("String names = itemizeNames(_names);");
        break;

      case "lexeme":
        parameters.add("Token token");
        conversions.add("String lexeme = token.lexeme;");
        arguments.add("'$name': token");
        break;

      case "lexeme2":
        parameters.add("Token token2");
        conversions.add("String lexeme2 = token2.lexeme;");
        arguments.add("'$name': token2");
        break;

      case "string":
        parameters.add("String string");
        conversions.add("if (string.isEmpty) throw 'No string provided';");
        arguments.add("'$name': string");
        break;

      case "string2":
        parameters.add("String string2");
        conversions.add("if (string2.isEmpty) throw 'No string provided';");
        arguments.add("'$name': string2");
        break;

      case "string3":
        parameters.add("String string3");
        conversions.add("if (string3.isEmpty) throw 'No string provided';");
        arguments.add("'$name': string3");
        break;

      case "stringOKEmpty":
        parameters.add("String stringOKEmpty");
        conversions.add("if (stringOKEmpty.isEmpty) "
            "stringOKEmpty = '(empty)';");
        arguments.add("'$name': stringOKEmpty");
        break;

      case "type":
      case "type2":
      case "type3":
      case "type4":
        parameters.add("DartType _${name}");
        ensureLabeler();
        conversions
            .add("List<Object> ${name}Parts = labeler.labelType(_${name});");
        conversions2.add("String ${name} = ${name}Parts.join();");
        arguments.add("'${name}': _${name}");
        break;

      case "uri":
        parameters.add("Uri uri_");
        conversions.add("String? uri = relativizeUri(uri_);");
        arguments.add("'$name': uri_");
        break;

      case "uri2":
        parameters.add("Uri uri2_");
        conversions.add("String? uri2 = relativizeUri(uri2_);");
        arguments.add("'$name': uri2_");
        break;

      case "uri3":
        parameters.add("Uri uri3_");
        conversions.add("String? uri3 = relativizeUri(uri3_);");
        arguments.add("'$name': uri3_");
        break;

      case "count":
        parameters.add("int count");
        arguments.add("'$name': count");
        break;

      case "count2":
        parameters.add("int count2");
        arguments.add("'$name': count2");
        break;

      case "constant":
        parameters.add("Constant _constant");
        ensureLabeler();
        conversions.add(
            "List<Object> ${name}Parts = labeler.labelConstant(_${name});");
        conversions2.add("String ${name} = ${name}Parts.join();");
        arguments.add("'$name': _constant");
        break;

      case "num1":
        parameters.add("num _num1");
        conversions.add("String num1 = ${format('_num1')};");
        arguments.add("'$name': _num1");
        break;

      case "num2":
        parameters.add("num _num2");
        conversions.add("String num2 = ${format('_num2')};");
        arguments.add("'$name': _num2");
        break;

      case "num3":
        parameters.add("num _num3");
        conversions.add("String num3 = ${format('_num3')};");
        arguments.add("'$name': _num3");
        break;

      default:
        throw "Unhandled placeholder in template: '$name'";
    }
  }

  if (hasLabeler) {
    parameters.add("bool isNonNullableByDefault");
  }

  conversions.addAll(conversions2);

  String interpolate(String text) {
    text = text
        .replaceAll(r"$", r"\$")
        .replaceAllMapped(placeholderPattern, (Match m) => "\${${m[1]}}");
    return "\"\"\"$text\"\"\"";
  }

  List<String> codeArguments = <String>[];
  if (index != null) {
    codeArguments.add('index: $index');
  } else if (analyzerCode != null) {
    if (analyzerCode is String) {
      analyzerCode = <String>[analyzerCode];
    }
    List<Object?> codes = analyzerCode as List<Object?>;
    // If "index:" is defined, then "analyzerCode:" should not be generated
    // in the front end. See comment in messages.yaml
    codeArguments.add('analyzerCodes: <String>["${codes.join('", "')}"]');
  }
  if (severity != null) {
    String? severityEnumName = severityEnumNames[severity];
    if (severityEnumName == null) {
      throw "Unknown severity '$severity'";
    }
    codeArguments.add('severity: Severity.$severityEnumName');
  }

  if (parameters.isEmpty && conversions.isEmpty && arguments.isEmpty) {
    codeArguments.add('problemMessage: r"""$problemMessage"""');
    if (correctionMessage != null) {
      codeArguments.add('correctionMessage: r"""$correctionMessage"""');
    }

    return new Template("""
// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> code$name = message$name;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode message$name =
    const MessageCode(\"$name\", ${codeArguments.join(', ')});
""", isShared: canBeShared);
  }

  List<String> templateArguments = <String>[];
  templateArguments.add('problemMessageTemplate: r"""$problemMessage"""');
  if (correctionMessage != null) {
    templateArguments
        .add('correctionMessageTemplate: r"""$correctionMessage"""');
  }

  templateArguments.add("withArguments: _withArguments$name");

  List<String> messageArguments = <String>[];
  String message = interpolate(problemMessage);
  if (hasLabeler) {
    message += " + labeler.originMessages";
  }
  messageArguments.add("problemMessage: ${message}");
  if (correctionMessage != null) {
    messageArguments
        .add("correctionMessage: ${interpolate(correctionMessage)}");
  }
  messageArguments.add("arguments: { ${arguments.join(', ')} }");

  return new Template("""
// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(${parameters.join(', ')})> template$name =
    const Template<Message Function(${parameters.join(', ')})>(
        ${templateArguments.join(', ')});

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(${parameters.join(', ')})> code$name =
    const Code<Message Function(${parameters.join(', ')})>(
        \"$name\", ${codeArguments.join(', ')});

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArguments$name(${parameters.join(', ')}) {
  ${conversions.join('\n  ')}
  return new Message(
     code$name,
     ${messageArguments.join(', ')});
}
""", isShared: canBeShared);
}
