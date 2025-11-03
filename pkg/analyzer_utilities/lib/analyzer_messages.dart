// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:analyzer_testing/package_root.dart' as pkg_root;
import 'package:analyzer_utilities/messages.dart';
import 'package:analyzer_utilities/tools.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart' show YamlMap, YamlScalar, loadYamlNode;

const codesFile = GeneratedDiagnosticFile(
  path: 'analyzer/lib/src/error/codes.g.dart',
  parentLibrary: 'package:analyzer/src/error/codes.dart',
);

/// Information about all the classes derived from `DiagnosticCode` that are
/// code-generated based on the contents of the analyzer and front end
/// `messages.yaml` files.
///
/// Note: to look up an error class by name, use [DiagnosticClassInfo.byName].
const List<DiagnosticClassInfo> diagnosticClasses = [
  lintCodeInfo,
  linterLintCodeInfo,
  GeneratedDiagnosticClassInfo(
    file: optionCodesFile,
    name: 'AnalysisOptionsErrorCode',
    type: 'COMPILE_TIME_ERROR',
  ),
  GeneratedDiagnosticClassInfo(
    file: optionCodesFile,
    name: 'AnalysisOptionsWarningCode',
    type: 'STATIC_WARNING',
  ),
  GeneratedDiagnosticClassInfo(
    file: codesFile,
    name: 'CompileTimeErrorCode',
    type: 'COMPILE_TIME_ERROR',
  ),
  GeneratedDiagnosticClassInfo(
    file: syntacticErrorsFile,
    name: 'ScannerErrorCode',
    type: 'SYNTACTIC_ERROR',
  ),
  GeneratedDiagnosticClassInfo(
    file: codesFile,
    name: 'StaticWarningCode',
    type: 'STATIC_WARNING',
  ),
  GeneratedDiagnosticClassInfo(
    file: codesFile,
    name: 'WarningCode',
    type: 'STATIC_WARNING',
  ),
  GeneratedDiagnosticClassInfo(
    file: ffiCodesFile,
    name: 'FfiCode',
    type: 'COMPILE_TIME_ERROR',
  ),
  GeneratedDiagnosticClassInfo(
    file: hintCodesFile,
    name: 'HintCode',
    type: 'HINT',
  ),
  GeneratedDiagnosticClassInfo(
    file: syntacticErrorsFile,
    name: 'ParserErrorCode',
    type: 'SYNTACTIC_ERROR',
    deprecatedSnakeCaseNames: {
      'UNEXPECTED_TOKEN', // Referenced by `package:dart_style`.
    },
  ),
  GeneratedDiagnosticClassInfo(
    file: manifestWarningCodeFile,
    name: 'ManifestWarningCode',
    type: 'STATIC_WARNING',
  ),
  GeneratedDiagnosticClassInfo(
    file: pubspecWarningCodeFile,
    name: 'PubspecWarningCode',
    type: 'STATIC_WARNING',
  ),
  GeneratedDiagnosticClassInfo(
    file: todoCodesFile,
    name: 'TodoCode',
    type: 'TODO',
    comment: '''
The error code indicating a marker in code for work that needs to be finished
or revisited.
''',
  ),
  GeneratedDiagnosticClassInfo(
    file: transformSetErrorCodeFile,
    name: 'TransformSetErrorCode',
    type: 'COMPILE_TIME_ERROR',
    package: AnalyzerDiagnosticPackage.analysisServer,
    comment: '''
An error code representing a problem in a file containing an encoding of a
transform set.
''',
  ),
];

const ffiCodesFile = GeneratedDiagnosticFile(
  path: 'analyzer/lib/src/dart/error/ffi_code.g.dart',
  parentLibrary: 'package:analyzer/src/dart/error/ffi_code.dart',
);

const String generatedLintCodesPath = 'linter/lib/src/lint_codes.g.dart';

const hintCodesFile = GeneratedDiagnosticFile(
  path: 'analyzer/lib/src/dart/error/hint_codes.g.dart',
  parentLibrary: 'package:analyzer/src/dart/error/hint_codes.dart',
);

const lintCodeInfo = DiagnosticClassInfo(name: 'LintCode');

const lintCodesFile = GeneratedDiagnosticFile(
  path: generatedLintCodesPath,
  parentLibrary: 'package:linter/src/lint_codes.dart',
);

const linterLintCodeInfo = GeneratedDiagnosticClassInfo(
  file: lintCodesFile,
  name: 'LinterLintCode',
  type: 'LINT',
  package: AnalyzerDiagnosticPackage.linter,
);

const manifestWarningCodeFile = GeneratedDiagnosticFile(
  path: 'analyzer/lib/src/manifest/manifest_warning_code.g.dart',
  parentLibrary: 'package:analyzer/src/manifest/manifest_warning_code.dart',
);

const optionCodesFile = GeneratedDiagnosticFile(
  path: 'analyzer/lib/src/analysis_options/error/option_codes.g.dart',
  parentLibrary:
      'package:analyzer/src/analysis_options/error/option_codes.dart',
);

const pubspecWarningCodeFile = GeneratedDiagnosticFile(
  path: 'analyzer/lib/src/pubspec/pubspec_warning_code.g.dart',
  parentLibrary: 'package:analyzer/src/pubspec/pubspec_warning_code.dart',
);

const syntacticErrorsFile = GeneratedDiagnosticFile(
  path: 'analyzer/lib/src/dart/error/syntactic_errors.g.dart',
  parentLibrary: 'package:analyzer/src/dart/error/syntactic_errors.dart',
);

const todoCodesFile = GeneratedDiagnosticFile(
  path: 'analyzer/lib/src/dart/error/todo_codes.g.dart',
  parentLibrary: 'package:analyzer/src/dart/error/todo_codes.dart',
);

const transformSetErrorCodeFile = GeneratedDiagnosticFile(
  path:
      'analysis_server/lib/src/services/correction/fix/data_driven/'
      'transform_set_error_code.g.dart',
  parentLibrary:
      'package:analysis_server/src/services/correction/fix/data_driven/'
      'transform_set_error_code.dart',
  shouldIgnorePreferSingleQuotes: true,
);

/// Decoded messages from the analyzer's `messages.yaml` file.
final List<AnalyzerMessage> analyzerMessages = decodeAnalyzerMessagesYaml(
  analyzerPkgPath,
);

/// The path to the `analyzer` package.
final String analyzerPkgPath = normalize(
  join(pkg_root.packageRoot, 'analyzer'),
);

/// The path to the `linter` package.
final String linterPkgPath = normalize(join(pkg_root.packageRoot, 'linter'));

/// Decoded messages from the linter's `messages.yaml` file.
final List<AnalyzerMessage> lintMessages = decodeAnalyzerMessagesYaml(
  linterPkgPath,
  allowLinterKeys: true,
);

/// Decodes a YAML object (in analyzer style `messages.yaml` format) into a list
/// of [AnalyzerMessage]s.
///
/// If [allowLinterKeys], error checking logic will not reject key/value pairs
/// that are used by the linter.
List<AnalyzerMessage> decodeAnalyzerMessagesYaml(
  String packagePath, {
  bool allowLinterKeys = false,
}) {
  var path = join(packagePath, 'messages.yaml');
  var yaml = loadYamlNode(
    File(path).readAsStringSync(),
    sourceUrl: Uri.file(path),
  );

  var result = <AnalyzerMessage>[];
  if (yaml is! YamlMap) {
    throw LocatedError('root node is not a map', span: yaml.span);
  }
  for (var classEntry in yaml.nodes.entries) {
    var keyNode = classEntry.key as YamlScalar;
    var className = keyNode.value;
    if (className is! String) {
      throw LocatedError(
        'non-string class key ${json.encode(className)}',
        span: keyNode.span,
      );
    }
    var classValue = classEntry.value;
    if (classValue is! YamlMap) {
      throw LocatedError(
        'value associated with class key $className is not a map',
        span: classValue.span,
      );
    }
    for (var diagnosticEntry in classValue.nodes.entries) {
      var keyNode = diagnosticEntry.key as YamlScalar;
      var diagnosticName = keyNode.value;
      if (diagnosticName is! String) {
        throw LocatedError(
          'non-string diagnostic key ${json.encode(diagnosticName)}',
          span: keyNode.span,
        );
      }
      var diagnosticValue = diagnosticEntry.value;
      if (diagnosticValue is! YamlMap) {
        throw LocatedError(
          'value associated with diagnostic is not a map',
          span: diagnosticValue.span,
        );
      }

      AnalyzerMessage message = MessageYaml.decode(
        key: keyNode,
        value: diagnosticValue,
        decoder: (messageYaml) {
          var analyzerCode = AnalyzerCode(
            diagnosticClass: DiagnosticClassInfo.byName(className),
            snakeCaseName: diagnosticName,
          );
          return AnalyzerMessage(
            messageYaml,
            analyzerCode: analyzerCode,
            allowLinterKeys: allowLinterKeys,
          );
        },
      );
      result.add(message);

      if (message case AliasMessage(:var aliasFor)) {
        var aliasForPath = aliasFor.split('.');
        if (aliasForPath.isEmpty) {
          throw LocatedError(
            "The 'aliasFor' value is empty",
            span: diagnosticValue.span,
          );
        }
        var node = yaml;
        for (var key in aliasForPath) {
          var value = node[key];
          if (value is! YamlMap) {
            throw LocatedError(
              'No Map value at "$aliasFor"',
              span: diagnosticValue.span,
            );
          }
          node = value;
        }
      }
    }
  }
  return result;
}

/// Splits [text] on spaces using the given [maxWidth] (and [firstLineWidth] if
/// given).
List<String> _splitText(
  String text, {
  required int maxWidth,
  int? firstLineWidth,
}) {
  firstLineWidth ??= maxWidth;
  var lines = <String>[];
  // The character width to use as a maximum width. This starts as
  // [firstLineWidth] but becomes [maxWidth] on every iteration after the first.
  var width = firstLineWidth;
  var lineMaxEndIndex = width;
  var lineStartIndex = 0;

  while (true) {
    if (lineMaxEndIndex >= text.length) {
      lines.add(text.substring(lineStartIndex, text.length));
      break;
    } else {
      var lastSpaceIndex = text.lastIndexOf(' ', lineMaxEndIndex);
      if (lastSpaceIndex == -1 || lastSpaceIndex <= lineStartIndex) {
        // No space between [lineStartIndex] and [lineMaxEndIndex]. Get the
        // _next_ space.
        lastSpaceIndex = text.indexOf(' ', lineMaxEndIndex);
        if (lastSpaceIndex == -1) {
          // No space at all after [lineStartIndex].
          lines.add(text.substring(lineStartIndex));
          break;
        }
      }
      lines.add(text.substring(lineStartIndex, lastSpaceIndex + 1));
      lineStartIndex = lastSpaceIndex + 1;
      width = maxWidth;
    }
    lineMaxEndIndex = lineStartIndex + maxWidth;
  }
  return lines;
}

/// An [AnalyzerMessage] which is an alias for another, for incremental
/// deprecation purposes.
class AliasMessage extends AnalyzerMessage {
  String aliasFor;

  AliasMessage(
    super.messageYaml, {
    required this.aliasFor,
    required super.analyzerCode,
    required super.allowLinterKeys,
  }) : super._();

  String get aliasForClass => aliasFor.split('.').first;

  @override
  void toAnalyzerCode(
    DiagnosticClassInfo diagnosticClassInfo, {
    String? sharedNameReference,
    required MemberAccumulator memberAccumulator,
  }) {
    var constant = StringBuffer();
    outputConstantHeader(constant);
    constant.writeln('  static const $aliasForClass $constantName =');
    constant.writeln('$aliasFor;');
    memberAccumulator.constants[constantName] = constant.toString();
  }
}

/// Enum representing the packages into which analyzer diagnostics can be
/// generated.
enum AnalyzerDiagnosticPackage { analyzer, analysisServer, linter }

/// In-memory representation of diagnostic information obtained from the
/// analyzer's `messages.yaml` file.
class AnalyzerMessage extends Message with MessageWithAnalyzerCode {
  @override
  final AnalyzerCode analyzerCode;

  @override
  final bool hasPublishedDocs;

  factory AnalyzerMessage(
    MessageYaml messageYaml, {
    required AnalyzerCode analyzerCode,
    required bool allowLinterKeys,
  }) {
    if (messageYaml.getOptionalString('aliasFor') case var aliasFor?) {
      return AliasMessage(
        messageYaml,
        aliasFor: aliasFor,
        analyzerCode: analyzerCode,
        allowLinterKeys: allowLinterKeys,
      );
    } else {
      return AnalyzerMessage._(
        messageYaml,
        analyzerCode: analyzerCode,
        allowLinterKeys: allowLinterKeys,
      );
    }
  }

  AnalyzerMessage._(
    MessageYaml messageYaml, {
    required this.analyzerCode,
    required bool allowLinterKeys,
  }) : hasPublishedDocs = messageYaml.getBool('hasPublishedDocs'),
       super(messageYaml) {
    // Ignore extra keys related to analyzer example-based tests.
    messageYaml.allowExtraKeys({'experiment'});
    if (allowLinterKeys) {
      // Ignore extra keys understood by the linter.
      messageYaml.allowExtraKeys({'categories', 'deprecatedDetails', 'state'});
    }
  }
}

/// Interface class for diagnostic messages that have an analyzer code, and thus
/// can be reported by the analyzer.
mixin MessageWithAnalyzerCode on Message {
  /// The code used by the analyzer to refer to this diagnostic message.
  AnalyzerCode get analyzerCode;

  /// The name of the constant in analyzer code that should be used to refer to
  /// this message.
  String get constantName => analyzerCode.camelCaseName;

  /// Whether diagnostics with this code have documentation for them that has
  /// been published.
  ///
  /// `null` if the YAML doesn't contain this information.
  bool get hasPublishedDocs;

  void outputConstantHeader(StringSink out) {
    out.write(toAnalyzerComments(indent: '  '));
    if (deprecatedMessage != null) {
      out.writeln('  @Deprecated("$deprecatedMessage")');
    }
  }

  /// Generates a dart declaration for this diagnostic, suitable for inclusion
  /// in the diagnostic class [className].
  ///
  /// [diagnosticCode] is the name of the diagnostic to be generated.
  void toAnalyzerCode(
    GeneratedDiagnosticClassInfo diagnosticClassInfo, {
    String? sharedNameReference,
    required MemberAccumulator memberAccumulator,
  }) {
    var diagnosticCode = analyzerCode.snakeCaseName;
    var correctionMessage = this.correctionMessage;
    var parameters = this.parameters;
    var usesParameters = [problemMessage, correctionMessage].any(
      (value) =>
          value != null && value.any((part) => part is TemplateParameterPart),
    );
    String className;
    String templateParameters = '';
    String? withArgumentsName;
    if (parameters.isNotEmpty && !usesParameters) {
      throw 'Error code declares parameters using a `parameters` entry, but '
          "doesn't use them";
    } else if (parameters.values.any((p) => !p.type.isSupportedByAnalyzer)) {
      // Do not generate literate API yet.
      className = diagnosticClassInfo.name;
    } else if (parameters.isNotEmpty) {
      // Parameters are present so generate a diagnostic template (with
      // `.withArguments` support).
      className = diagnosticClassInfo.templateName;
      var withArgumentsParams = parameters.entries
          .map((p) => 'required ${p.value.type.analyzerName} ${p.key}')
          .join(', ');
      var argumentNames = parameters.keys.join(', ');
      withArgumentsName = '_withArguments${analyzerCode.pascalCaseName}';
      templateParameters =
          '<LocatableDiagnostic Function({$withArgumentsParams})>';
      var newIfNeeded = diagnosticClassInfo.file.shouldUseExplicitNewOrConst
          ? 'new '
          : '';
      memberAccumulator.staticMethods[withArgumentsName] =
          '''
static LocatableDiagnostic $withArgumentsName({$withArgumentsParams}) {
  return ${newIfNeeded}LocatableDiagnosticImpl(
    ${diagnosticClassInfo.name}.$constantName, [$argumentNames]);
}''';
    } else {
      // Parameters are not present so generate a "withoutArguments" constant.
      className = diagnosticClassInfo.withoutArgumentsName;
    }

    var constant = StringBuffer();
    outputConstantHeader(constant);
    constant.writeln(
      '  static const $className$templateParameters $constantName =',
    );
    if (diagnosticClassInfo.file.shouldUseExplicitNewOrConst) {
      constant.writeln('const ');
    }
    constant.writeln('$className(');
    constant.writeln(
      'name: ${sharedNameReference ?? "'${sharedName ?? diagnosticCode}'"},',
    );
    var maxWidth = 80 - 8 /* indentation */ - 2 /* quotes */ - 1 /* comma */;
    var messageAsCode = convertTemplate(problemMessage);
    var messageLines = _splitText(
      messageAsCode,
      maxWidth: maxWidth,
      firstLineWidth: maxWidth + 4,
    );
    constant.writeln(
      'problemMessage: ${messageLines.map(_encodeString).join('\n')},',
    );
    if (correctionMessage != null) {
      constant.write('correctionMessage: ');
      var code = convertTemplate(correctionMessage);
      var codeLines = _splitText(code, maxWidth: maxWidth);
      constant.writeln('${codeLines.map(_encodeString).join('\n')},');
    }
    if (hasPublishedDocs) {
      constant.writeln('hasPublishedDocs:true,');
    }
    if (isUnresolvedIdentifier) {
      constant.writeln('isUnresolvedIdentifier:true,');
    }
    if (sharedName != null) {
      constant.writeln("uniqueName: '$diagnosticCode',");
    }
    if (withArgumentsName != null) {
      constant.writeln('withArguments: $withArgumentsName,');
    }
    constant.writeln('expectedTypes: ${_computeExpectedTypes()},');
    constant.writeln(');');
    memberAccumulator.constants[constantName] = constant.toString();

    if (diagnosticClassInfo.deprecatedSnakeCaseNames.contains(diagnosticCode)) {
      memberAccumulator.constants[diagnosticCode] =
          '''
  @Deprecated("Please use $constantName")
  static const ${diagnosticClassInfo.name} $diagnosticCode = $constantName;
''';
    }
  }

  /// Generates doc comments for this error code.
  String toAnalyzerComments({String indent = ''}) {
    // Start with the comment specified in `messages.yaml`.
    var out = StringBuffer();
    List<String> commentLines = switch (comment) {
      null || '' => [],
      var c => c.split('\n'),
    };

    // Add a `Parameters:` section to the bottom of the comment if appropriate.
    switch (parameters) {
      case Map(isEmpty: true):
        if (commentLines.isNotEmpty) commentLines.add('');
        commentLines.add('No parameters.');
      default:
        if (commentLines.isNotEmpty) commentLines.add('');
        commentLines.add('Parameters:');
        for (var MapEntry(key: name, value: p) in parameters.entries) {
          var prefix = '${p.type.messagesYamlName} $name: ';
          var extraIndent = ' ' * prefix.length;
          var firstLineWidth = 80 - 4 - indent.length;
          var lines = _splitText(
            '$prefix${p.comment}',
            maxWidth: firstLineWidth - prefix.length,
            firstLineWidth: firstLineWidth,
          );
          commentLines.add(lines[0]);
          for (var line in lines.skip(1)) {
            commentLines.add('$extraIndent$line');
          }
        }
    }

    // Indent the result and prefix with `///`.
    for (var line in commentLines) {
      out.writeln('$indent///${line.isEmpty ? '' : ' '}$line');
    }
    return out.toString();
  }

  String _computeExpectedTypes() {
    var expectedTypes = [
      for (var parameter in parameters.values)
        'ExpectedType.${parameter.type.name}',
    ];
    return '[${expectedTypes.join(', ')}]';
  }

  String _encodeString(String s) {
    // JSON encoding gives us mostly what we need.
    var jsonEncoded = json.encode(s);
    // But we also need to escape `$`.
    return jsonEncoded.replaceAll(r'$', r'\$');
  }
}
