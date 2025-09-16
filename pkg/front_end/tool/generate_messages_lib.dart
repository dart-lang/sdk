// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:front_end/src/codes/type_labeler.dart';
library;

import 'dart:convert';
import 'dart:io' show exitCode;

import 'package:analyzer_utilities/messages.dart';

Uri computeSharedGeneratedFile(Uri repoDir) {
  return repoDir.resolve(
    "pkg/_fe_analyzer_shared/lib/src/messages/codes_generated.dart",
  );
}

Uri computeCfeGeneratedFile(Uri repoDir) {
  return repoDir.resolve(
    "pkg/front_end/lib/src/codes/cfe_codes_generated.dart",
  );
}

class Messages {
  final String sharedMessages;
  final String cfeMessages;

  Messages(this.sharedMessages, this.cfeMessages);
}

Messages generateMessagesFilesRaw(Uri repoDir) {
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
// Instead modify 'pkg/front_end/messages.yaml' and defer to it for the
// commands to update this file.

// ignore_for_file: lines_longer_than_80_chars
""";

  sharedMessages.writeln(preamble1);
  sharedMessages.writeln(preamble2);
  sharedMessages.writeln("""
part of 'codes.dart';
""");

  cfeMessages.writeln(preamble1);
  cfeMessages.writeln("""

""");
  cfeMessages.writeln(preamble2);
  cfeMessages.writeln("""
part of 'cfe_codes.dart';
""");

  bool hasError = false;
  int largestIndex = 0;
  final indexNameMap = new Map<int, String>();

  List<String> keys = frontEndAndSharedMessages.keys.toList()..sort();
  for (String name in keys) {
    var errorCodeInfo = frontEndAndSharedMessages[name]!;
    var index = errorCodeInfo.index;
    if (index != null) {
      String? otherName = indexNameMap[index];
      if (otherName != null) {
        print(
          'Error: The "index:" field must be unique, '
          'but is the same for $otherName and $name',
        );
        hasError = true;
        // Continue looking for other problems.
      } else {
        indexNameMap[index] = name;
        if (largestIndex < index) {
          largestIndex = index;
        }
      }
    }
    Template template;
    try {
      template = _TemplateCompiler(
        name: name,
        index: index,
        errorCodeInfo: errorCodeInfo,
      ).compile();
    } catch (e, st) {
      Error.throwWithStackTrace('Error while compiling $name: $e', st);
    }
    if (template.isShared) {
      sharedMessages.writeln(template.text);
    } else {
      cfeMessages.writeln(template.text);
    }
  }
  if (largestIndex > indexNameMap.length) {
    print(
      'Error: The "index:" field values should be unique, consecutive'
      ' whole numbers starting with 1.',
    );
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

  return new Messages("$sharedMessages", "$cfeMessages");
}

/// Returns a fresh identifier that is not yet present in [usedNames], and adds
/// it to [usedNames].
///
/// The name [nameHint] is used if it is available. Otherwise a new name is
/// chosen by appending characters to it.
String _newName({required Set<String> usedNames, required String nameHint}) {
  if (usedNames.add(nameHint)) return nameHint;
  for (var i = 0; ; i++) {
    var name = "${nameHint}_$i";
    if (usedNames.add(name)) return name;
  }
}

class Template {
  final String text;
  final isShared;

  Template(this.text, {this.isShared}) : assert(isShared != null);
}

class _TemplateCompiler {
  final String name;
  final int? index;
  final String problemMessage;
  final String? correctionMessage;
  final List<String> analyzerCodes;
  final String? severity;
  final Map<String, ErrorCodeParameter> parameters;

  late final Set<String> usedNames = {
    'conversions',
    'labeler',
    ...parameters.keys,
  };
  late final List<String> arguments = parameters.keys
      .map((name) => "'$name': $name")
      .toList();
  final Map<ParsedPlaceholder, String> interpolators = {};
  final List<String> withArgumentsStatements = [];
  bool hasLabeler = false;

  _TemplateCompiler({
    required this.name,
    required this.index,
    required CfeStyleErrorCodeInfo errorCodeInfo,
  }) : problemMessage = errorCodeInfo.problemMessage,
       correctionMessage = errorCodeInfo.correctionMessage,
       analyzerCodes = errorCodeInfo.analyzerCodes,
       severity = errorCodeInfo.cfeSeverity,
       parameters = errorCodeInfo.parameters;

  Template compile() {
    var codeArguments = <String>[
      if (index != null)
        'index: $index'
      else if (analyzerCodes.isNotEmpty)
        // If "index:" is defined, then "analyzerCode:" should not be generated
        // in the front end. See comment in messages.yaml
        'analyzerCodes: <String>["${analyzerCodes.join('", "')}"]',
      if (severity != null) 'severity: CfeSeverity.$severity',
    ];

    if (parameters.isEmpty) {
      codeArguments.add('problemMessage: r"""$problemMessage"""');
      if (correctionMessage != null) {
        codeArguments.add('correctionMessage: r"""$correctionMessage"""');
      }

      return new Template("""
// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode code$name =
    const MessageCode(\"$name\", ${codeArguments.join(', ')},);
""", isShared: true);
    }

    List<String> templateArguments = <String>[];
    templateArguments.add('\"$name\"');
    templateArguments.add('problemMessageTemplate: r"""$problemMessage"""');
    if (correctionMessage != null) {
      templateArguments.add(
        'correctionMessageTemplate: r"""$correctionMessage"""',
      );
    }

    templateArguments.add("withArgumentsOld: _withArgumentsOld$name");
    templateArguments.add("withArguments: _withArguments$name");
    templateArguments.addAll(codeArguments);

    String interpolatedProblemMessage = interpolate(problemMessage)!;
    String? interpolatedCorrectionMessage = interpolate(correctionMessage);
    if (hasLabeler) {
      interpolatedProblemMessage += " + labeler.originMessages";
    }

    List<String> messageArguments = <String>[
      "problemMessage: $interpolatedProblemMessage",
      if (interpolatedCorrectionMessage case var m?) "correctionMessage: $m",
      "arguments: { ${arguments.join(', ')}, }",
    ];
    List<String> positionalParameters = parameters.entries
        .map((entry) => '${entry.value.type.cfeName!} ${entry.key}')
        .toList();
    List<String> namedParameters = parameters.entries
        .map((entry) => 'required ${entry.value.type.cfeName!} ${entry.key}')
        .toList();
    List<String> oldToNewArguments = parameters.keys
        .map((name) => '$name: $name')
        .toList();

    return new Template("""
// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(${positionalParameters.join(', ')}),
  Message Function({${namedParameters.join(', ')}})
> code$name = const Template(${templateArguments.join(', ')},);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArguments$name({${namedParameters.join(', ')}}) {
  ${withArgumentsStatements.join('\n  ')}
  return new Message(
     code$name,
     ${messageArguments.join(', ')},);
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOld$name(${positionalParameters.join(', ')}) =>
    _withArguments$name(${oldToNewArguments.join(', ')});
""", isShared: !hasLabeler);
  }

  String computeInterpolator(ParsedPlaceholder placeholder) {
    var name = placeholder.name;
    var parameter = parameters[name];
    if (parameter == null) {
      throw StateError(
        'Placeholder ${json.encode(name)} not declared as a parameter',
      );
    }
    var conversion =
        placeholder.conversionOverride ?? parameter.type.cfeConversion;
    if (conversion is LabelerConversion && !hasLabeler) {
      withArgumentsStatements.add("TypeLabeler labeler = new TypeLabeler();");
      hasLabeler = true;
    }

    if (conversion?.toCode(
          name: placeholder.name,
          type: parameters[placeholder.name]!.type,
        )
        case var conversion?) {
      var interpolator = _newName(
        usedNames: usedNames,
        nameHint: placeholder.name,
      );
      withArgumentsStatements.add("var $interpolator = $conversion;");
      return interpolator;
    } else {
      return placeholder.name;
    }
  }

  String? interpolate(String? text) {
    if (text == null) return null;
    text = text.replaceAll(r"$", r"\$").replaceAllMapped(placeholderPattern, (
      Match m,
    ) {
      var placeholder = ParsedPlaceholder.fromMatch(m);
      var interpolator = interpolators[placeholder] ??= computeInterpolator(
        placeholder,
      );
      return "\${$interpolator}";
    });
    return "\"\"\"$text\"\"\"";
  }
}
