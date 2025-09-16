// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:analyzer_testing/package_root.dart' as pkg_root;
import 'package:analyzer_utilities/messages.dart';
import 'package:analyzer_utilities/tools.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart' show loadYaml, YamlMap;

const codesFile = GeneratedErrorCodeFile(
  path: 'analyzer/lib/src/error/codes.g.dart',
  parentLibrary: 'package:analyzer/src/error/codes.dart',
);

/// Information about all the classes derived from `DiagnosticCode` that are
/// code-generated based on the contents of the analyzer and front end
/// `messages.yaml` files.
const List<ErrorClassInfo> errorClasses = [
  ErrorClassInfo(
    file: optionCodesFile,
    name: 'AnalysisOptionsErrorCode',
    type: 'COMPILE_TIME_ERROR',
    severity: 'ERROR',
  ),
  ErrorClassInfo(
    file: optionCodesFile,
    name: 'AnalysisOptionsWarningCode',
    type: 'STATIC_WARNING',
    severity: 'WARNING',
  ),
  ErrorClassInfo(
    file: codesFile,
    name: 'CompileTimeErrorCode',
    type: 'COMPILE_TIME_ERROR',
  ),
  ErrorClassInfo(
    file: scannerErrorFile,
    name: 'ScannerErrorCode',
    type: 'SYNTACTIC_ERROR',
  ),
  ErrorClassInfo(
    file: codesFile,
    name: 'StaticWarningCode',
    type: 'STATIC_WARNING',
    severity: 'WARNING',
  ),
  ErrorClassInfo(
    file: codesFile,
    name: 'WarningCode',
    type: 'STATIC_WARNING',
    severity: 'WARNING',
  ),
  ErrorClassInfo(
    file: ffiCodesFile,
    name: 'FfiCode',
    type: 'COMPILE_TIME_ERROR',
  ),
  ErrorClassInfo(file: hintCodesFile, name: 'HintCode', type: 'HINT'),
  ErrorClassInfo(
    file: syntacticErrorsFile,
    name: 'ParserErrorCode',
    type: 'SYNTACTIC_ERROR',
    severity: 'ERROR',
    includeCfeMessages: true,
    deprecatedSnakeCaseNames: {
      'UNEXPECTED_TOKEN', // Referenced by `package:dart_style`.
    },
  ),
  ErrorClassInfo(
    file: manifestWarningCodeFile,
    name: 'ManifestWarningCode',
    type: 'STATIC_WARNING',
    severity: 'WARNING',
  ),
  ErrorClassInfo(
    file: pubspecWarningCodeFile,
    name: 'PubspecWarningCode',
    type: 'STATIC_WARNING',
    severity: 'WARNING',
  ),
  ErrorClassInfo(
    file: todoCodesFile,
    name: 'TodoCode',
    type: 'TODO',
    severity: 'INFO',
    comment: '''
The error code indicating a marker in code for work that needs to be finished
or revisited.
''',
  ),
  ErrorClassInfo(
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

const ffiCodesFile = GeneratedErrorCodeFile(
  path: 'analyzer/lib/src/dart/error/ffi_code.g.dart',
  parentLibrary: 'package:analyzer/src/dart/error/ffi_code.dart',
);

const hintCodesFile = GeneratedErrorCodeFile(
  path: 'analyzer/lib/src/dart/error/hint_codes.g.dart',
  parentLibrary: 'package:analyzer/src/dart/error/hint_codes.dart',
);

const manifestWarningCodeFile = GeneratedErrorCodeFile(
  path: 'analyzer/lib/src/manifest/manifest_warning_code.g.dart',
  parentLibrary: 'package:analyzer/src/manifest/manifest_warning_code.dart',
);

const optionCodesFile = GeneratedErrorCodeFile(
  path: 'analyzer/lib/src/analysis_options/error/option_codes.g.dart',
  parentLibrary:
      'package:analyzer/src/analysis_options/error/option_codes.dart',
);

const pubspecWarningCodeFile = GeneratedErrorCodeFile(
  path: 'analyzer/lib/src/pubspec/pubspec_warning_code.g.dart',
  parentLibrary: 'package:analyzer/src/pubspec/pubspec_warning_code.dart',
);

const scannerErrorFile = GeneratedErrorCodeFile(
  path: '_fe_analyzer_shared/lib/src/scanner/errors.g.dart',
  parentLibrary: 'package:_fe_analyzer_shared/src/scanner/errors.dart',
  shouldUseExplicitNewOrConst: true,
);

const syntacticErrorsFile = GeneratedErrorCodeFile(
  path: 'analyzer/lib/src/dart/error/syntactic_errors.g.dart',
  parentLibrary: 'package:analyzer/src/dart/error/syntactic_errors.dart',
);

const todoCodesFile = GeneratedErrorCodeFile(
  path: 'analyzer/lib/src/dart/error/todo_codes.g.dart',
  parentLibrary: 'package:analyzer/src/dart/error/todo_codes.dart',
);

const transformSetErrorCodeFile = GeneratedErrorCodeFile(
  path:
      'analysis_server/lib/src/services/correction/fix/data_driven/'
      'transform_set_error_code.g.dart',
  parentLibrary:
      'package:analysis_server/src/services/correction/fix/data_driven/'
      'transform_set_error_code.dart',
  shouldIgnorePreferSingleQuotes: true,
);

/// Decoded messages from the analyzer's `messages.yaml` file.
final Map<String, Map<String, AnalyzerErrorCodeInfo>> analyzerMessages =
    _loadAnalyzerMessages();

/// The path to the `analyzer` package.
final String analyzerPkgPath = normalize(
  join(pkg_root.packageRoot, 'analyzer'),
);

/// The path to the `linter` package.
final String linterPkgPath = normalize(join(pkg_root.packageRoot, 'linter'));

/// Decoded messages from the linter's `messages.yaml` file.
final Map<String, Map<String, AnalyzerErrorCodeInfo>> lintMessages =
    _loadLintMessages();

/// Decodes a YAML object (obtained from a `messages.yaml` file) into a
/// two-level map of [ErrorCodeInfo], indexed first by class name and then by
/// error name.
Map<String, Map<String, AnalyzerErrorCodeInfo>> decodeAnalyzerMessagesYaml(
  String packagePath,
) {
  var yaml =
      loadYaml(File(join(packagePath, 'messages.yaml')).readAsStringSync())
          as Object?;
  Never problem(String message) {
    throw 'Problem in $packagePath/messages.yaml: $message';
  }

  var result = <String, Map<String, AnalyzerErrorCodeInfo>>{};
  if (yaml is! Map<Object?, Object?>) {
    problem('root node is not a map');
  }
  for (var classEntry in yaml.entries) {
    var className = classEntry.key;
    if (className is! String) {
      problem('non-string class key ${json.encode(className)}');
    }
    var classValue = classEntry.value;
    if (classValue is! Map<Object?, Object?>) {
      problem('value associated with class key $className is not a map');
    }
    for (var errorEntry in classValue.entries) {
      var errorName = errorEntry.key;
      if (errorName is! String) {
        problem(
          'in class $className, non-string error key '
          '${json.encode(errorName)}',
        );
      }
      var errorValue = errorEntry.value;
      if (errorValue is! YamlMap) {
        problem(
          'value associated with error $className.$errorName is not a '
          'map',
        );
      }

      AnalyzerErrorCodeInfo errorCodeInfo;
      try {
        errorCodeInfo = (result[className] ??= {})[errorName] =
            AnalyzerErrorCodeInfo.fromYaml(errorValue);
      } catch (e, st) {
        Error.throwWithStackTrace(
          'while processing $className.$errorName, $e',
          st,
        );
      }
      if (errorCodeInfo.hasPublishedDocs == null) {
        problem('Missing hasPublishedDocs for $className.$errorName');
      }

      if (errorCodeInfo case AliasErrorCodeInfo(:var aliasFor)) {
        var aliasForPath = aliasFor.split('.');
        if (aliasForPath.isEmpty) {
          problem("The 'aliasFor' value at '$className.$errorName is empty");
        }
        var node = yaml;
        for (var key in aliasForPath) {
          var value = node[key];
          if (value is! Map<Object?, Object?>) {
            problem(
              'No Map value at "$aliasFor", aliased from '
              '$className.$errorName',
            );
          }
          node = value;
        }
      }
    }
  }
  return result;
}

/// Loads analyzer messages from the analyzer's `messages.yaml` file.
Map<String, Map<String, AnalyzerErrorCodeInfo>> _loadAnalyzerMessages() =>
    decodeAnalyzerMessagesYaml(analyzerPkgPath);

/// Loads linter messages from the linter's `messages.yaml` file.
Map<String, Map<String, AnalyzerErrorCodeInfo>> _loadLintMessages() =>
    decodeAnalyzerMessagesYaml(linterPkgPath);

/// An [AnalyzerErrorCodeInfo] which is an alias for another, for incremental
/// deprecation purposes.
class AliasErrorCodeInfo extends AnalyzerErrorCodeInfo {
  String aliasFor;

  AliasErrorCodeInfo._fromYaml(super.yaml, {required this.aliasFor})
    : super._fromYaml();

  String get aliasForClass => aliasFor.split('.').first;

  String get aliasForFilePath => errorClasses
      .firstWhere((element) => element.name == aliasForClass)
      .file
      .path;

  @override
  void toAnalyzerCode(
    ErrorClassInfo errorClassInfo,
    String diagnosticCode, {
    String? sharedNameReference,
    required MemberAccumulator memberAccumulator,
  }) {
    var constant = StringBuffer();
    outputConstantHeader(constant);
    constant.writeln('  static const $aliasForClass $diagnosticCode =');
    constant.writeln('$aliasFor;');
    memberAccumulator.constants[diagnosticCode] = constant.toString();
  }
}

/// In-memory representation of error code information obtained from the
/// analyzer's `messages.yaml` file.
class AnalyzerErrorCodeInfo extends ErrorCodeInfo {
  factory AnalyzerErrorCodeInfo.fromYaml(YamlMap yaml) {
    if (yaml['aliasFor'] case var aliasFor?) {
      return AliasErrorCodeInfo._fromYaml(yaml, aliasFor: aliasFor as String);
    } else {
      return AnalyzerErrorCodeInfo._fromYaml(yaml);
    }
  }

  AnalyzerErrorCodeInfo._fromYaml(super.yaml) : super.fromYaml();
}
