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
    severity: 'ERROR',
  ),
  GeneratedDiagnosticClassInfo(
    file: optionCodesFile,
    name: 'AnalysisOptionsWarningCode',
    type: 'STATIC_WARNING',
    severity: 'WARNING',
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
    severity: 'WARNING',
  ),
  GeneratedDiagnosticClassInfo(
    file: codesFile,
    name: 'WarningCode',
    type: 'STATIC_WARNING',
    severity: 'WARNING',
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
    severity: 'ERROR',
    deprecatedSnakeCaseNames: {
      'UNEXPECTED_TOKEN', // Referenced by `package:dart_style`.
    },
  ),
  GeneratedDiagnosticClassInfo(
    file: manifestWarningCodeFile,
    name: 'ManifestWarningCode',
    type: 'STATIC_WARNING',
    severity: 'WARNING',
  ),
  GeneratedDiagnosticClassInfo(
    file: pubspecWarningCodeFile,
    name: 'PubspecWarningCode',
    type: 'STATIC_WARNING',
    severity: 'WARNING',
  ),
  GeneratedDiagnosticClassInfo(
    file: todoCodesFile,
    name: 'TodoCode',
    type: 'TODO',
    severity: 'INFO',
    comment: '''
The error code indicating a marker in code for work that needs to be finished
or revisited.
''',
  ),
  GeneratedDiagnosticClassInfo(
    file: transformSetErrorCodeFile,
    name: 'TransformSetErrorCode',
    type: 'COMPILE_TIME_ERROR',
    severity: 'ERROR',
    includeInDiagnosticCodeValues: false,
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
final Map<AnalyzerCode, AnalyzerMessage> analyzerMessages =
    _analyzerAndLintMessages.analyzerMessages;

/// The path to the `analyzer` package.
final String analyzerPkgPath = normalize(
  join(pkg_root.packageRoot, 'analyzer'),
);

/// The path to the `linter` package.
final String linterPkgPath = normalize(join(pkg_root.packageRoot, 'linter'));

/// Decoded messages from the linter's `messages.yaml` file.
final Map<AnalyzerCode, AnalyzerMessage> lintMessages =
    _analyzerAndLintMessages.lintMessages;

final ({
  Map<AnalyzerCode, AnalyzerMessage> analyzerMessages,
  Map<AnalyzerCode, AnalyzerMessage> lintMessages,
})
_analyzerAndLintMessages = _loadAnalyzerAndLintMessages();

/// Decodes a YAML object (obtained from a `messages.yaml` file) into a map.
Map<AnalyzerCode, AnalyzerMessage> decodeAnalyzerMessagesYaml(
  String packagePath,
) {
  var path = join(packagePath, 'messages.yaml');
  var yaml = loadYamlNode(
    File(path).readAsStringSync(),
    sourceUrl: Uri.file(path),
  );

  var result = <AnalyzerCode, AnalyzerMessage>{};
  if (yaml is! YamlMap) {
    throw LocatedError('root node is not a map', node: yaml);
  }
  for (var classEntry in yaml.nodes.entries) {
    var keyNode = classEntry.key as YamlScalar;
    var className = keyNode.value;
    if (className is! String) {
      throw LocatedError(
        'non-string class key ${json.encode(className)}',
        node: keyNode,
      );
    }
    var classValue = classEntry.value;
    if (classValue is! YamlMap) {
      throw LocatedError(
        'value associated with class key $className is not a map',
        node: classValue,
      );
    }
    for (var diagnosticEntry in classValue.nodes.entries) {
      var keyNode = diagnosticEntry.key as YamlScalar;
      var diagnosticName = keyNode.value;
      if (diagnosticName is! String) {
        throw LocatedError(
          'non-string diagnostic key ${json.encode(diagnosticName)}',
          node: keyNode,
        );
      }
      var diagnosticValue = diagnosticEntry.value;
      if (diagnosticValue is! YamlMap) {
        throw LocatedError(
          'value associated with diagnostic is not a map',
          node: diagnosticValue,
        );
      }

      AnalyzerMessage message = LocatedError.wrap(node: diagnosticValue, () {
        var analyzerCode = AnalyzerCode(
          diagnosticClass: DiagnosticClassInfo.byName(className),
          snakeCaseName: diagnosticName,
        );
        return result[analyzerCode] = AnalyzerMessage.fromYaml(
          diagnosticValue,
          keyNode: keyNode,
          analyzerCode: analyzerCode,
        );
      });
      if (message.hasPublishedDocs == null) {
        throw LocatedError('Missing hasPublishedDocs', node: diagnosticValue);
      }

      if (message case AliasMessage(:var aliasFor)) {
        var aliasForPath = aliasFor.split('.');
        if (aliasForPath.isEmpty) {
          throw LocatedError(
            "The 'aliasFor' value is empty",
            node: diagnosticValue,
          );
        }
        var node = yaml;
        for (var key in aliasForPath) {
          var value = node[key];
          if (value is! YamlMap) {
            throw LocatedError(
              'No Map value at "$aliasFor"',
              node: diagnosticValue,
            );
          }
          node = value;
        }
      }
    }
  }
  return result;
}

/// Loads analyzer and lint messages from their respective `messages.yaml`
/// files, and performs consistency checks on them.
({
  Map<AnalyzerCode, AnalyzerMessage> analyzerMessages,
  Map<AnalyzerCode, AnalyzerMessage> lintMessages,
})
_loadAnalyzerAndLintMessages() {
  var analyzerMessages = decodeAnalyzerMessagesYaml(analyzerPkgPath);
  var lintMessages = decodeAnalyzerMessagesYaml(linterPkgPath);

  // Check for duplicate codes.
  var camelCaseNameToMessages = <String, List<Message>>{};
  var allAnalyzerAndLintMessages = [
    for (var codeMap in [analyzerMessages, lintMessages]) ...codeMap.values,
  ];
  for (var message in <MessageWithAnalyzerCode>[
    ...allAnalyzerAndLintMessages,
    ...feAnalyzerSharedMessages.values,
  ]) {
    (camelCaseNameToMessages[message.analyzerCode.camelCaseName] ??= []).add(
      message,
    );
  }
  for (var MapEntry(:key, :value) in camelCaseNameToMessages.entries) {
    if (value.length > 1) {
      throw [
        'Analyzer diagnostic name $key used for multiple diagnostics:',
        for (var message in value) '${message.location}: ${message.keyNode}',
      ].join('\n');
    }
  }

  return (analyzerMessages: analyzerMessages, lintMessages: lintMessages);
}

/// An [AnalyzerMessage] which is an alias for another, for incremental
/// deprecation purposes.
class AliasMessage extends AnalyzerMessage {
  String aliasFor;

  AliasMessage._fromYaml(
    super.yaml, {
    required this.aliasFor,
    required super.keyNode,
    required super.analyzerCode,
  }) : super._fromYaml();

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

/// In-memory representation of diagnostic information obtained from the
/// analyzer's `messages.yaml` file.
class AnalyzerMessage extends Message with MessageWithAnalyzerCode {
  @override
  final AnalyzerCode analyzerCode;

  factory AnalyzerMessage.fromYaml(
    YamlMap yaml, {
    required YamlScalar keyNode,
    required AnalyzerCode analyzerCode,
  }) {
    if (yaml['aliasFor'] case var aliasFor?) {
      return AliasMessage._fromYaml(
        yaml,
        aliasFor: aliasFor as String,
        keyNode: keyNode,
        analyzerCode: analyzerCode,
      );
    } else {
      return AnalyzerMessage._fromYaml(
        yaml,
        keyNode: keyNode,
        analyzerCode: analyzerCode,
      );
    }
  }

  AnalyzerMessage._fromYaml(
    super.yaml, {
    required super.keyNode,
    required this.analyzerCode,
  }) : super.fromYaml();
}
