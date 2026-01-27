// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:front_end/src/codes/type_labeler.dart';
library;

import 'package:analyzer_utilities/extensions/string.dart';
import 'package:analyzer_utilities/located_error.dart';
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

class MessageAccumulator {
  static const doNotEditComment =
      '// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.';

  /// The buffer in which generated code will be accumulated.
  final StringBuffer _buffer = new StringBuffer();

  /// The URI which the generated file which will be part of.
  final String partOf;

  MessageAccumulator({required this.partOf}) {
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

    _buffer.writeln(preamble1);
    _buffer.writeln(preamble2);
    _buffer.writeln("""
part of '$partOf';
""");
  }

  String finish() {
    return _buffer.toString();
  }

  void writeConstant({
    required String type,
    required String name,
    required String initializer,
  }) {
    _buffer.writeln(doNotEditComment);
    _buffer.writeln('const $type $name = $initializer;');
    _buffer.writeln();
  }

  void writeEnum({
    required String documentation,
    required String name,
    required List<String> values,
  }) {
    _buffer.writeln();
    _buffer.writeln('/// $documentation');
    _buffer.writeln('enum $name {');
    for (var value in values) {
      _buffer.writeln('  $value,');
    }
    _buffer.writeln('}');
  }

  void writeWithArgumentsFunction(String function) {
    _buffer.writeln(doNotEditComment);
    _buffer.writeln(function);
  }
}

class Messages {
  final String sharedMessages;
  final String cfeMessages;

  Messages(this.sharedMessages, this.cfeMessages);
}

Messages generateMessagesFilesRaw(Uri repoDir) {
  MessageAccumulator sharedMessages = new MessageAccumulator(
    partOf: 'codes.dart',
  );
  MessageAccumulator cfeMessages = new MessageAccumulator(
    partOf: 'cfe_codes.dart',
  );

  var pseudoSharedCodeValues = <String>{};
  for (var message in diagnosticTables.sortedFrontEndDiagnostics) {
    var forFeAnalyzerShared =
        message is SharedMessage ||
        message is FrontEndMessage && message.pseudoSharedCode != null;
    LocatedError.wrap(
      span: message.keySpan,
      () => _TemplateCompiler(
        message: message,
        pseudoSharedCodeValues: forFeAnalyzerShared
            ? pseudoSharedCodeValues
            : null,
      ).compile(forFeAnalyzerShared ? sharedMessages : cfeMessages),
    );
  }
  sharedMessages.writeEnum(
    documentation:
        'Enum containing analyzer error codes referenced by '
        '[Code.pseudoSharedCode].',
    name: 'PseudoSharedCode',
    values: pseudoSharedCodeValues.toList()..sort(),
  );
  sharedMessages.writeEnum(
    documentation:
        'Enum containing analyzer error codes referenced by '
        '[Code.sharedCode].',
    name: 'SharedCode',
    values: [
      for (var code in diagnosticTables.sortedSharedDiagnostics)
        code.analyzerCode.camelCaseName,
    ],
  );

  return new Messages(sharedMessages.finish(), cfeMessages.finish());
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
  final CfeStyleMessage message;
  final List<TemplatePart> problemMessage;
  final List<TemplatePart>? correctionMessage;
  final String? severity;
  final Map<String, DiagnosticParameter> parameters;
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
    required this.message,
    required this.pseudoSharedCodeValues,
  }) : name = message.frontEndCode.pascalCaseName,
       problemMessage = message.problemMessage,
       correctionMessage = message.correctionMessage,
       severity = message.cfeSeverity,
       parameters = message.parameters,
       pseudoSharedCode = message is FrontEndMessage
           ? message.pseudoSharedCode
           : null;

  void compile(MessageAccumulator messageAccumulator) {
    var constantName = 'code$name';
    var codeArguments = <String>[
      if (pseudoSharedCodeValues != null && pseudoSharedCode != null)
        'pseudoSharedCode: ${_encodePseudoSharedCode(pseudoSharedCode!)}',
      if (severity != null) 'severity: CfeSeverity.$severity',
      if (message case SharedMessage(:var analyzerCode))
        'sharedCode: SharedCode.${analyzerCode.camelCaseName}',
    ];

    String interpolatedProblemMessage = interpolate(problemMessage)!;
    String? interpolatedCorrectionMessage = interpolate(correctionMessage);
    if (hasLabeler) {
      interpolatedProblemMessage += " + labeler.originMessages";
    }

    String constantType;
    String constantInitializer;
    List<String> withArgumentsFunctions = [];
    if (parameters.isEmpty) {
      codeArguments.add('problemMessage: $interpolatedProblemMessage');
      if (correctionMessage != null) {
        codeArguments.add('correctionMessage: $interpolatedCorrectionMessage');
      }

      constantType = 'MessageCode';
      constantInitializer =
          'const MessageCode("$name", ${codeArguments.join(', ')},)';
    } else {
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

      constantType =
          """
Template<
  Message Function(${positionalParameters.join(', ')}),
  Message Function({${namedParameters.join(', ')}})
>""";
      constantInitializer = 'const Template(${templateArguments.join(', ')},)';
      withArgumentsFunctions.add("""
Message _withArguments$name({${namedParameters.join(', ')}}) {
  ${withArgumentsStatements.join('\n  ')}
  return new Message(
     $constantName,
     ${messageArguments.join(', ')},);
}
""");
      withArgumentsFunctions.add("""
Message _withArgumentsOld$name(${positionalParameters.join(', ')}) =>
    _withArguments$name(${oldToNewArguments.join(', ')});
""");
    }
    messageAccumulator.writeConstant(
      type: constantType,
      name: constantName,
      initializer: constantInitializer,
    );
    for (var withArgumentsFunction in withArgumentsFunctions) {
      messageAccumulator.writeWithArgumentsFunction(withArgumentsFunction);
    }
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
