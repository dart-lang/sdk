// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:front_end/src/codes/type_labeler.dart';
library;

import 'package:analyzer_utilities/extensions/string.dart';
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

  List<String> keys = frontEndAndSharedMessages.keys.toList()..sort();
  var pseudoSharedCodeValues = <String>{};
  for (String name in keys) {
    var errorCodeInfo = frontEndAndSharedMessages[name]!;
    var forFeAnalyzerShared =
        errorCodeInfo is SharedErrorCodeInfo ||
        errorCodeInfo is FrontEndErrorCodeInfo &&
            errorCodeInfo.pseudoSharedCode != null;
    String template;
    try {
      template = _TemplateCompiler(
        name: name,
        isShared: errorCodeInfo is SharedErrorCodeInfo,
        errorCodeInfo: errorCodeInfo,
        pseudoSharedCodeValues: forFeAnalyzerShared
            ? pseudoSharedCodeValues
            : null,
      ).compile();
    } catch (e, st) {
      Error.throwWithStackTrace('Error while compiling $name: $e', st);
    }
    if (forFeAnalyzerShared) {
      sharedMessages.writeln(template);
    } else {
      cfeMessages.writeln(template);
    }
  }
  sharedMessages.writeln();
  sharedMessages.writeln(
    '/// Enum containing analyzer error codes referenced by '
    '[Code.pseudoSharedCode].',
  );
  sharedMessages.writeln('enum PseudoSharedCode {');
  for (var code in pseudoSharedCodeValues.toList()..sort()) {
    sharedMessages.writeln('  $code,');
  }
  sharedMessages.writeln('}');
  sharedMessages.writeln();
  sharedMessages.writeln(
    '/// Enum containing analyzer error codes referenced by '
    '[Code.sharedCode].',
  );
  sharedMessages.writeln('enum SharedCode {');
  for (var code in sharedToAnalyzerErrorCodeTables.sortedSharedErrors) {
    sharedMessages.writeln(
      '  ${sharedToAnalyzerErrorCodeTables.infoToFrontEndCode[code]},',
    );
  }
  sharedMessages.writeln('}');

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

class _TemplateCompiler {
  final String name;
  final bool isShared;
  final List<TemplatePart> problemMessage;
  final List<TemplatePart>? correctionMessage;
  final String? severity;
  final Map<String, ErrorCodeParameter> parameters;
  final String? pseudoSharedCode;

  /// If the template will be generated into `pkg/_fe_analyzer_shared`, a set of
  /// strings representing the values that will be generated for the
  /// `PseudoSharedCode` enum; otherwise `null`.
  ///
  /// The template compiler will add to this set as needed.
  final Set<String>? pseudoSharedCodeValues;

  late final Set<String> usedNames = {
    'conversions',
    'labeler',
    ...parameters.keys,
  };
  late final List<String> arguments = parameters.keys
      .map((name) => "'$name': $name")
      .toList();
  final Map<TemplateParameterPart, String> interpolators = {};
  final List<String> withArgumentsStatements = [];
  bool hasLabeler = false;

  _TemplateCompiler({
    required this.name,
    required this.isShared,
    required CfeStyleErrorCodeInfo errorCodeInfo,
    required this.pseudoSharedCodeValues,
  }) : problemMessage = errorCodeInfo.problemMessage,
       correctionMessage = errorCodeInfo.correctionMessage,
       severity = errorCodeInfo.cfeSeverity,
       parameters = errorCodeInfo.parameters,
       pseudoSharedCode = errorCodeInfo is FrontEndErrorCodeInfo
           ? errorCodeInfo.pseudoSharedCode
           : null;

  String compile() {
    var codeArguments = <String>[
      if (pseudoSharedCodeValues != null && pseudoSharedCode != null)
        'pseudoSharedCode: ${_encodePseudoSharedCode(pseudoSharedCode!)}',
      if (severity != null) 'severity: CfeSeverity.$severity',
      if (isShared) 'sharedCode: SharedCode.$name',
    ];

    String interpolatedProblemMessage = interpolate(problemMessage)!;
    String? interpolatedCorrectionMessage = interpolate(correctionMessage);
    if (hasLabeler) {
      interpolatedProblemMessage += " + labeler.originMessages";
    }

    if (parameters.isEmpty) {
      codeArguments.add('problemMessage: $interpolatedProblemMessage');
      if (correctionMessage != null) {
        codeArguments.add('correctionMessage: $interpolatedCorrectionMessage');
      }

      return """
// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode code$name =
    const MessageCode(\"$name\", ${codeArguments.join(', ')},);
""";
    }

    List<String> templateArguments = <String>[];
    templateArguments.add('\"$name\"');
    templateArguments.add("withArgumentsOld: _withArgumentsOld$name");
    templateArguments.add("withArguments: _withArguments$name");
    templateArguments.addAll(codeArguments);

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

    return """
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
""";
  }

  String computeInterpolator(TemplateParameterPart placeholder) {
    var parameter = placeholder.parameter;
    var name = parameter.name;
    var type = parameter.type;
    var conversion = placeholder.conversionOverride ?? type.cfeConversion;
    if (conversion is LabelerConversion && !hasLabeler) {
      withArgumentsStatements.add("TypeLabeler labeler = new TypeLabeler();");
      hasLabeler = true;
    }

    if (conversion?.toCode(name: name, type: type) case var conversion?) {
      var interpolator = _newName(usedNames: usedNames, nameHint: name);
      withArgumentsStatements.add("var $interpolator = $conversion;");
      return interpolator;
    } else {
      return name;
    }
  }

  String? interpolate(List<TemplatePart>? template) {
    if (template == null) return null;
    var text = template
        .map(
          (part) => switch (part) {
            TemplateLiteralPart(:var text) =>
              text.replaceAll(r'\', r'\\').replaceAll(r"$", r"\$"),
            TemplateParameterPart() =>
              "\${${interpolators[part] ??= computeInterpolator(part)}}",
          },
        )
        .join();
    return "\"\"\"$text\"\"\"";
  }

  /// Creates the list literal that should populate the error code's
  /// `pseudoSharedCode` value.
  String _encodePseudoSharedCode(String code) {
    var camelCaseCode = code.toCamelCase();
    pseudoSharedCodeValues!.add(camelCaseCode);
    return 'PseudoSharedCode.$camelCaseCode';
  }
}
