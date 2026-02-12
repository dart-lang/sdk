// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:front_end/src/codes/type_labeler.dart';
library;

import 'package:analyzer_utilities/extensions/string.dart';
import 'package:analyzer_utilities/located_error.dart';
import 'package:analyzer_utilities/messages.dart';

class MessageAccumulator {
  static const doNotEditComment =
      '// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.';

  /// The buffer in which generated code will be accumulated.
  final StringBuffer _newBuffer = new StringBuffer();

  MessageAccumulator() {
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

    _newBuffer.writeln(preamble1);
    _newBuffer.writeln(preamble2);
    _newBuffer.writeln("""
part of 'diagnostic.dart';
""");
  }

  Messages finish({required String packageName, required String path}) {
    return Messages(
      packageName: packageName,
      path: path,
      contents: _newBuffer.toString(),
    );
  }

  void writeConstant({
    required String type,
    required String oldName,
    required String newName,
    required String initializer,
  }) {
    _newBuffer.writeln(doNotEditComment);
    _newBuffer.writeln('const $type $newName = $initializer;');
    _newBuffer.writeln();
  }

  void writeEnum({
    required String documentation,
    required String name,
    required List<String> values,
  }) {
    _newBuffer.writeln();
    _newBuffer.writeln('/// $documentation');
    _newBuffer.writeln('enum $name {');
    for (var value in values) {
      _newBuffer.writeln('  $value,');
    }
    _newBuffer.writeln('}');
  }

  void writeWithArgumentsFunction(String function) {
    _newBuffer.writeln(doNotEditComment);
    _newBuffer.writeln(function);
  }
}

/// Information about the message code to generate for a given package.
class Messages {
  /// The name of the package to which files are being generated.
  final String packageName;

  /// The path to the generated file, relative to the root of the package.
  final String path;

  /// The string to write to the generated file.
  final String contents;

  Messages({
    required this.packageName,
    required this.path,
    required this.contents,
  });

  /// Computes the absolute file URI to the generated file.
  ///
  /// [repoDir] is the absolute file URI of the SDK repo.
  Uri uri(Uri repoDir) => repoDir.resolve('pkg/$packageName/$path');
}

List<Messages> generateMessagesFilesRaw(Uri repoDir) {
  MessageAccumulator sharedMessages = new MessageAccumulator();
  MessageAccumulator cfeMessages = new MessageAccumulator();

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

  return [
    sharedMessages.finish(
      packageName: '_fe_analyzer_shared',
      path: "lib/src/messages/diagnostic.g.dart",
    ),
    cfeMessages.finish(
      packageName: 'front_end',
      path: "lib/src/codes/diagnostic.g.dart",
    ),
  ];
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
  final String pascalCaseName;
  final String camelCaseName;
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
  }) : pascalCaseName = message.frontEndCode.pascalCaseName,
       camelCaseName = message.frontEndCode.camelCaseName,
       problemMessage = message.problemMessage,
       correctionMessage = message.correctionMessage,
       severity = message.cfeSeverity,
       parameters = message.parameters,
       pseudoSharedCode = message is FrontEndMessage
           ? message.pseudoSharedCode
           : null;

  void compile(MessageAccumulator messageAccumulator) {
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
          'const MessageCode("$pascalCaseName", ${codeArguments.join(', ')},)';
    } else {
      List<String> templateArguments = <String>[];
      templateArguments.add('\"$pascalCaseName\"');
      templateArguments.add("withArguments: _withArguments$pascalCaseName");
      templateArguments.addAll(codeArguments);

      List<String> messageArguments = <String>[
        "problemMessage: $interpolatedProblemMessage",
        if (interpolatedCorrectionMessage case var m?) "correctionMessage: $m",
        "arguments: { ${arguments.join(', ')}, }",
      ];
      List<String> namedParameters = parameters.entries
          .map((entry) => 'required ${entry.value.type.cfeName!} ${entry.key}')
          .toList();

      constantType =
          """
Template<
  Message Function({${namedParameters.join(', ')}})
>""";
      constantInitializer = 'const Template(${templateArguments.join(', ')},)';
      withArgumentsFunctions.add("""
Message _withArguments$pascalCaseName({${namedParameters.join(', ')}}) {
  ${withArgumentsStatements.join('\n  ')}
  return new Message(
     $camelCaseName,
     ${messageArguments.join(', ')},);
}
""");
    }
    messageAccumulator.writeConstant(
      type: constantType,
      oldName: 'code$pascalCaseName',
      newName: camelCaseName,
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
