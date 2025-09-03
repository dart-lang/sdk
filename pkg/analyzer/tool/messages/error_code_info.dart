// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:analyzer_testing/package_root.dart' as pkg_root;
import 'package:analyzer_utilities/extensions/string.dart';
import 'package:analyzer_utilities/tools.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart' show loadYaml;

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

/// A set of tables mapping between front end and analyzer error codes.
final CfeToAnalyzerErrorCodeTables cfeToAnalyzerErrorCodeTables =
    CfeToAnalyzerErrorCodeTables._(frontEndMessages);

/// Decoded messages from the front end's `messages.yaml` file.
final Map<String, FrontEndErrorCodeInfo> frontEndMessages =
    _loadFrontEndMessages();

/// The path to the `front_end` package.
final String frontEndPkgPath = normalize(
  join(pkg_root.packageRoot, 'front_end'),
);

/// The path to the `linter` package.
final String linterPkgPath = normalize(join(pkg_root.packageRoot, 'linter'));

/// Decoded messages from the linter's `messages.yaml` file.
final Map<String, Map<String, AnalyzerErrorCodeInfo>> lintMessages =
    _loadLintMessages();

/// Pattern formerly used by the analyzer to identify placeholders in error
/// message strings.
///
/// (This pattern is still used internally by the analyzer implementation, but
/// it is no longer supported in `messages.yaml`.)
final RegExp oldPlaceholderPattern = RegExp(r'\{\d+\}');

/// Pattern for placeholders in error message strings.
// TODO(paulberry): share this regexp (and the code for interpreting
// it) between the CFE and analyzer.
final RegExp placeholderPattern = RegExp(
  '#([-a-zA-Z0-9_]+)(?:%([0-9]*).([0-9]+))?',
);

/// Convert a template string (which uses placeholders matching
/// [placeholderPattern]) to an analyzer internal template string (which uses
/// placeholders like `{0}`).
String convertTemplate(Map<String, int> placeholderToIndexMap, String entry) {
  return entry.replaceAllMapped(
    placeholderPattern,
    (match) => '{${placeholderToIndexMap[match.group(0)!]}}',
  );
}

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
      if (errorValue is! Map<Object?, Object?>) {
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

/// Decodes a YAML object (obtained from `pkg/front_end/messages.yaml`) into a
/// map from error name to [ErrorCodeInfo].
Map<String, FrontEndErrorCodeInfo> decodeCfeMessagesYaml(Object? yaml) {
  Never problem(String message) {
    throw 'Problem in pkg/front_end/messages.yaml: $message';
  }

  var result = <String, FrontEndErrorCodeInfo>{};
  if (yaml is! Map<Object?, Object?>) {
    problem('root node is not a map');
  }
  for (var entry in yaml.entries) {
    var errorName = entry.key;
    if (errorName is! String) {
      problem('non-string error key ${json.encode(errorName)}');
    }
    var errorValue = entry.value;
    if (errorValue is! Map<Object?, Object?>) {
      problem('value associated with error $errorName is not a map');
    }
    try {
      result[errorName] = FrontEndErrorCodeInfo.fromYaml(errorValue);
    } catch (e, st) {
      Error.throwWithStackTrace('while processing $errorName, $e', st);
    }
  }
  return result;
}

/// Loads analyzer messages from the analyzer's `messages.yaml` file.
Map<String, Map<String, AnalyzerErrorCodeInfo>> _loadAnalyzerMessages() =>
    decodeAnalyzerMessagesYaml(analyzerPkgPath);

/// Loads front end messages from the front end's `messages.yaml` file.
Map<String, FrontEndErrorCodeInfo> _loadFrontEndMessages() {
  Object? messagesYaml = loadYaml(
    File(join(frontEndPkgPath, 'messages.yaml')).readAsStringSync(),
  );
  return decodeCfeMessagesYaml(messagesYaml);
}

/// Loads linter messages from the linter's `messages.yaml` file.
Map<String, Map<String, AnalyzerErrorCodeInfo>> _loadLintMessages() =>
    decodeAnalyzerMessagesYaml(linterPkgPath);

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
    _outputConstantHeader(constant);
    constant.writeln('  static const $aliasForClass $diagnosticCode =');
    constant.writeln('$aliasFor;');
    memberAccumulator.constants[diagnosticCode] = constant.toString();
  }
}

/// In-memory representation of error code information obtained from the
/// analyzer's `messages.yaml` file.
class AnalyzerErrorCodeInfo extends ErrorCodeInfo {
  factory AnalyzerErrorCodeInfo.fromYaml(Map<Object?, Object?> yaml) {
    if (yaml['aliasFor'] case var aliasFor?) {
      return AliasErrorCodeInfo._fromYaml(yaml, aliasFor: aliasFor as String);
    } else {
      return AnalyzerErrorCodeInfo._fromYaml(yaml);
    }
  }

  AnalyzerErrorCodeInfo._fromYaml(super.yaml) : super.fromYaml() {
    _check();
  }

  void _check() {
    if (parameters == null) throw StateError('Missing `parameters` entry.');
  }
}

/// Data tables mapping between CFE errors and their corresponding automatically
/// generated analyzer errors.
class CfeToAnalyzerErrorCodeTables {
  /// List of CFE errors for which analyzer errors should be automatically
  /// generated, organized by their `index` property.
  final List<ErrorCodeInfo?> indexToInfo = [];

  /// Map whose values are the CFE errors for which analyzer errors should be
  /// automatically generated, and whose keys are the corresponding analyzer
  /// error name.  (Names are simple identifiers; they are not prefixed by the
  /// class name `ParserErrorCode`)
  final Map<String, ErrorCodeInfo> analyzerCodeToInfo = {};

  /// Map whose values are the CFE errors for which analyzer errors should be
  /// automatically generated, and whose keys are the front end error name.
  final Map<String, ErrorCodeInfo> frontEndCodeToInfo = {};

  /// Map whose keys are the CFE errors for which analyzer errors should be
  /// automatically generated, and whose values are the corresponding analyzer
  /// error name.  (Names are simple identifiers; they are not prefixed by the
  /// class name `ParserErrorCode`)
  final Map<ErrorCodeInfo, String> infoToAnalyzerCode = {};

  /// Map whose keys are the CFE errors for which analyzer errors should be
  /// automatically generated, and whose values are the front end error name.
  final Map<ErrorCodeInfo, String> infoToFrontEndCode = {};

  CfeToAnalyzerErrorCodeTables._(Map<String, FrontEndErrorCodeInfo> messages) {
    for (var entry in messages.entries) {
      var errorCodeInfo = entry.value;
      var index = errorCodeInfo.index;
      if (index == null || errorCodeInfo.analyzerCode.length != 1) {
        continue;
      }
      var frontEndCode = entry.key;
      if (index < 1) {
        throw '''
$frontEndCode specifies index $index but indices must be 1 or greater.
For more information run:
dart pkg/front_end/tool/generate_messages.dart
''';
      }
      if (indexToInfo.length <= index) {
        indexToInfo.length = index + 1;
      }
      var previousEntryForIndex = indexToInfo[index];
      if (previousEntryForIndex != null) {
        throw 'Index $index used by both '
            '${infoToFrontEndCode[previousEntryForIndex]} and $frontEndCode';
      }
      indexToInfo[index] = errorCodeInfo;
      frontEndCodeToInfo[frontEndCode] = errorCodeInfo;
      infoToFrontEndCode[errorCodeInfo] = frontEndCode;
      var analyzerCodeLong = errorCodeInfo.analyzerCode.single;
      var expectedPrefix = 'ParserErrorCode.';
      if (!analyzerCodeLong.startsWith(expectedPrefix)) {
        throw 'Expected all analyzer error codes to be prefixed with '
            '${json.encode(expectedPrefix)}.  Found '
            '${json.encode(analyzerCodeLong)}.';
      }
      var analyzerCode = analyzerCodeLong.substring(expectedPrefix.length);
      infoToAnalyzerCode[errorCodeInfo] = analyzerCode;
      var previousEntryForAnalyzerCode = analyzerCodeToInfo[analyzerCode];
      if (previousEntryForAnalyzerCode != null) {
        throw 'Analyzer code $analyzerCode used by both '
            '${infoToFrontEndCode[previousEntryForAnalyzerCode]} and '
            '$frontEndCode';
      }
      analyzerCodeToInfo[analyzerCode] = errorCodeInfo;
    }
    for (int i = 1; i < indexToInfo.length; i++) {
      if (indexToInfo[i] == null) {
        throw 'Indices are not consecutive; no error code has index $i.';
      }
    }
  }
}

/// Information about a code generated class derived from `ErrorCode`.
class ErrorClassInfo {
  /// The generated file containing this class.
  final GeneratedErrorCodeFile file;

  /// True if this class should contain error messages extracted from the front
  /// end's `messages.yaml` file.
  ///
  /// Note: at the moment we only support extracting front end error messages to
  /// a single error class.
  final bool includeCfeMessages;

  /// The name of this class.
  final String name;

  /// The severity of errors in this class, or `null` if the severity should be
  /// based on the [type] of the error.
  final String? severity;

  /// The type of errors in this class.
  final String type;

  /// The names of any errors which are relied upon by analyzer clients, and
  /// therefore will need their "snake case" form preserved (with a deprecation
  /// notice) after migration to camel case error codes.
  final Set<String> deprecatedSnakeCaseNames;

  /// If `true` (the default), error codes of this class will be included in the
  /// automatically-generated `diagnosticCodeValues` list.
  final bool includeInDiagnosticCodeValues;

  /// Documentation comment to generate for the error class.
  ///
  /// If no documentation comment is needed, this should be the empty string.
  final String comment;

  const ErrorClassInfo({
    required this.file,
    this.includeCfeMessages = false,
    required this.name,
    this.severity,
    required this.type,
    this.deprecatedSnakeCaseNames = const {},
    this.includeInDiagnosticCodeValues = true,
    this.comment = '',
  });

  /// Generates the code to compute the severity of errors of this class.
  String get severityCode {
    var severity = this.severity;
    if (severity == null) {
      return '$typeCode.severity';
    } else {
      return 'DiagnosticSeverity.$severity';
    }
  }

  String get templateName => '${_baseName}Template';

  /// Generates the code to compute the type of errors of this class.
  String get typeCode => 'DiagnosticType.$type';

  String get withoutArgumentsName => '${_baseName}WithoutArguments';

  String get _baseName {
    const suffix = 'Code';
    if (name.endsWith(suffix)) {
      return name.substring(0, name.length - suffix.length);
    } else {
      throw StateError("Can't infer base name for class $name");
    }
  }
}

/// In-memory representation of error code information obtained from either the
/// analyzer or the front end's `messages.yaml` file.  This class contains the
/// common functionality supported by both formats.
abstract class ErrorCodeInfo {
  /// If present, a documentation comment that should be associated with the
  /// error in code generated output.
  final String? comment;

  /// If the error code has an associated correctionMessage, the template for
  /// it.
  final String? correctionMessage;

  /// If non-null, the deprecation message for this error code.
  final String? deprecatedMessage;

  /// If present, user-facing documentation for the error.
  final String? documentation;

  /// Whether diagnostics with this code have documentation for them that has
  /// been published.
  ///
  /// `null` if the YAML doesn't contain this information.
  final bool? hasPublishedDocs;

  /// Indicates whether this error is caused by an unresolved identifier.
  final bool isUnresolvedIdentifier;

  /// The problemMessage for the error code.
  final String problemMessage;

  /// If present, the SDK version this error code stopped being reported in.
  /// If not null, error codes will not be generated for this error.
  final String? removedIn;

  /// If present, indicates that this error code has a special name for
  /// presentation to the user, that is potentially shared with other error
  /// codes.
  final String? sharedName;

  /// If present, indicates that this error code has been renamed from
  /// [previousName] to its current name (or [sharedName]).
  final String? previousName;

  /// A list of [ErrorCodeParameter] objects describing the parameters for this
  /// error code, obtained from the `parameters` entry in the yaml file.
  ///
  /// If `null`, then there is no `parameters` entry, meaning the error code
  /// hasn't been translated from the old placeholder format yet.
  final List<ErrorCodeParameter>? parameters;

  ErrorCodeInfo({
    this.comment,
    this.documentation,
    this.hasPublishedDocs,
    this.isUnresolvedIdentifier = false,
    this.sharedName,
    required this.problemMessage,
    this.correctionMessage,
    this.deprecatedMessage,
    this.previousName,
    this.removedIn,
    this.parameters,
  }) {
    for (var MapEntry(:key, :value) in {
      'problemMessage': problemMessage,
      'correctionMessage': correctionMessage,
    }.entries) {
      if (value == null) continue;
      if (value.contains(oldPlaceholderPattern)) {
        throw StateError(
          '$key is ${json.encode(value)}, which contains an old-style analyzer '
          'placeholder pattern. Please convert to #NAME format.',
        );
      }
    }
  }

  /// Decodes an [ErrorCodeInfo] object from its YAML representation.
  ErrorCodeInfo.fromYaml(Map<Object?, Object?> yaml)
    : this(
        comment: yaml['comment'] as String?,
        correctionMessage: _decodeMessage(yaml['correctionMessage']),
        deprecatedMessage: yaml['deprecatedMessage'] as String?,
        documentation: yaml['documentation'] as String?,
        hasPublishedDocs: yaml['hasPublishedDocs'] as bool?,
        isUnresolvedIdentifier:
            yaml['isUnresolvedIdentifier'] as bool? ?? false,
        problemMessage: _decodeMessage(yaml['problemMessage']) ?? '',
        sharedName: yaml['sharedName'] as String?,
        removedIn: yaml['removedIn'] as String?,
        previousName: yaml['previousName'] as String?,
        parameters: _decodeParameters(yaml['parameters']),
      );

  /// If this error is no longer reported and
  /// its error codes should no longer be generated.
  bool get isRemoved => removedIn != null;

  /// Given a messages.yaml entry, come up with a mapping from placeholder
  /// patterns in its message strings to their corresponding indices.
  Map<String, int> computePlaceholderToIndexMap() {
    if (parameters case var parameters?) {
      // Parameters were explicitly specified, so the mapping is determined by
      // the order in which they were specified.
      return {
        for (var (index, parameter) in parameters.indexed)
          '#${parameter.name}': index,
      };
    } else {
      // Parameters are not explicitly specified, so it's necessary to invent a
      // mapping by searching the problemMessage and correctionMessage for
      // placeholders.
      var mapping = <String, int>{};
      for (var value in [problemMessage, correctionMessage]) {
        if (value is! String) continue;
        for (Match match in placeholderPattern.allMatches(value)) {
          // CFE supports a bunch of formatting options that analyzer doesn't;
          // make sure none of those are used.
          if (match.group(0) != '#${match.group(1)}') {
            throw 'Template string ${json.encode(value)} contains unsupported '
                'placeholder pattern ${json.encode(match.group(0))}';
          }

          mapping[match.group(0)!] ??= mapping.length;
        }
      }
      return mapping;
    }
  }

  /// Generates a dart declaration for this error code, suitable for inclusion
  /// in the error class [className].
  ///
  /// [diagnosticCode] is the name of the error code to be generated.
  void toAnalyzerCode(
    ErrorClassInfo errorClassInfo,
    String diagnosticCode, {
    String? sharedNameReference,
    required MemberAccumulator memberAccumulator,
  }) {
    var correctionMessage = this.correctionMessage;
    var parameters = this.parameters;
    var usesParameters = [
      problemMessage,
      correctionMessage,
    ].any((value) => value != null && value.contains(placeholderPattern));
    var constantName = diagnosticCode.toCamelCase();
    String className;
    String templateParameters = '';
    String? withArgumentsName;
    if (parameters != null && parameters.isNotEmpty && !usesParameters) {
      throw StateError(
        "Error code declares parameters using a `parameters` entry, but "
        "doesn't use them",
      );
    } else if (parameters == null) {
      // Do not generate literate API yet.
      className = errorClassInfo.name;
    } else if (parameters.isNotEmpty) {
      // Parameters are present so generate a diagnostic template (with
      // `.withArguments` support).
      className = errorClassInfo.templateName;
      var withArgumentsParams = parameters
          .map((p) => 'required ${p.type.analyzerName} ${p.name}')
          .join(', ');
      var argumentNames = parameters.map((p) => p.name).join(', ');
      var pascalCaseName = diagnosticCode.toPascalCase();
      withArgumentsName = '_withArguments$pascalCaseName';
      templateParameters =
          '<LocatableDiagnostic Function({$withArgumentsParams})>';
      var newIfNeeded = errorClassInfo.file.shouldUseExplicitNewOrConst
          ? 'new '
          : '';
      memberAccumulator.staticMethods[withArgumentsName] =
          '''
static LocatableDiagnostic $withArgumentsName({$withArgumentsParams}) {
  return ${newIfNeeded}LocatableDiagnosticImpl($constantName, [$argumentNames]);
}''';
    } else {
      // Parameters are not present so generate a "withoutArguments" constant.
      className = errorClassInfo.withoutArgumentsName;
    }

    var constant = StringBuffer();
    _outputConstantHeader(constant);
    constant.writeln(
      '  static const $className$templateParameters $constantName =',
    );
    if (errorClassInfo.file.shouldUseExplicitNewOrConst) {
      constant.writeln('const ');
    }
    constant.writeln('$className(');
    constant.writeln(
      '${sharedNameReference ?? "'${sharedName ?? diagnosticCode}'"},',
    );
    var maxWidth = 80 - 8 /* indentation */ - 2 /* quotes */ - 1 /* comma */;
    var placeholderToIndexMap = computePlaceholderToIndexMap();
    var messageAsCode = convertTemplate(placeholderToIndexMap, problemMessage);
    var messageLines = _splitText(
      messageAsCode,
      maxWidth: maxWidth,
      firstLineWidth: maxWidth + 4,
    );
    constant.writeln('${messageLines.map(_encodeString).join('\n')},');
    if (correctionMessage is String) {
      constant.write('correctionMessage: ');
      var code = convertTemplate(placeholderToIndexMap, correctionMessage);
      var codeLines = _splitText(code, maxWidth: maxWidth);
      constant.writeln('${codeLines.map(_encodeString).join('\n')},');
    }
    if (hasPublishedDocs ?? false) {
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

    if (errorClassInfo.deprecatedSnakeCaseNames.contains(diagnosticCode)) {
      memberAccumulator.constants[diagnosticCode] =
          '''
  @Deprecated("Please use $constantName")
  static const ${errorClassInfo.name} $diagnosticCode = $constantName;
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
      case []:
        if (commentLines.isNotEmpty) commentLines.add('');
        commentLines.add('No parameters.');
      case var parameters?:
        if (commentLines.isNotEmpty) commentLines.add('');
        commentLines.add('Parameters:');
        for (var p in parameters) {
          var prefix = '${p.type.messagesYamlName} ${p.name}: ';
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

  /// Encodes this object into a YAML representation.
  Map<Object?, Object?> toYaml() => {
    if (removedIn != null) 'removedIn': removedIn,
    if (sharedName != null) 'sharedName': sharedName,
    'problemMessage': problemMessage,
    if (correctionMessage != null) 'correctionMessage': correctionMessage,
    if (isUnresolvedIdentifier) 'isUnresolvedIdentifier': true,
    if (hasPublishedDocs ?? false) 'hasPublishedDocs': true,
    if (comment != null) 'comment': comment,
    if (documentation != null) 'documentation': documentation,
  };

  String _computeExpectedTypes() {
    if (parameters case var parameters?) {
      var expectedTypes = [
        for (var parameter in parameters) 'ExpectedType.${parameter.type.name}',
      ];
      return '[${expectedTypes.join(', ')}]';
    } else {
      return 'null';
    }
  }

  String _encodeString(String s) {
    // JSON encoding gives us mostly what we need.
    var jsonEncoded = json.encode(s);
    // But we also need to escape `$`.
    return jsonEncoded.replaceAll(r'$', r'\$');
  }

  void _outputConstantHeader(StringSink out) {
    out.write(toAnalyzerComments(indent: '  '));
    if (deprecatedMessage != null) {
      out.writeln('  @Deprecated("$deprecatedMessage")');
    }
  }

  static String? _decodeMessage(Object? rawMessage) {
    switch (rawMessage) {
      case null:
        return null;
      case String():
        // Remove trailing whitespace. This is necessary for templates defined
        // with `|` (verbatim) as they always contain a trailing newline that we
        // don't want.
        return rawMessage.trimRight();
      default:
        throw 'Bad message type: ${rawMessage.runtimeType}';
    }
  }

  static List<ErrorCodeParameter>? _decodeParameters(Object? yaml) {
    if (yaml == null) return null;
    if (yaml == 'none') return const [];
    yaml as Map<Object?, Object?>;
    var result = <ErrorCodeParameter>[];
    for (var MapEntry(:key, :value) in yaml.entries) {
      switch ((key as String).split(' ')) {
        case [var type, var name]:
          result.add(
            ErrorCodeParameter(
              type: ErrorCodeParameterType.fromMessagesYamlName(type),
              name: name,
              comment: value as String,
            ),
          );
        default:
          throw StateError(
            'Malformed parameter key (should be `TYPE NAME`): '
            '${json.encode(key)}',
          );
      }
    }
    return result;
  }
}

/// In-memory representation of a single key/value pair from the `parameters`
/// map for an error code.
class ErrorCodeParameter {
  final ErrorCodeParameterType type;
  final String name;
  final String comment;

  ErrorCodeParameter({
    required this.type,
    required this.name,
    required this.comment,
  });
}

/// In-memory representation of the type of a single diagnostic code's
/// parameter.
enum ErrorCodeParameterType {
  element(messagesYamlName: 'Element', analyzerName: 'Element'),
  int(messagesYamlName: 'int', analyzerName: 'int'),
  object(messagesYamlName: 'Object', analyzerName: 'Object'),
  string(messagesYamlName: 'String', analyzerName: 'String'),
  type(messagesYamlName: 'Type', analyzerName: 'DartType'),
  uri(messagesYamlName: 'Uri', analyzerName: 'Uri');

  /// Map from [messagesYamlName] to the enum constant.
  ///
  /// Used for decoding parameter types from `messages.yaml`.
  static final _messagesYamlNameToValue = {
    for (var value in values) value.messagesYamlName: value,
  };

  /// Name of this type as it appears in `messages.yaml`.
  final String messagesYamlName;

  /// Name of this type as it appears in Dart source code.
  final String analyzerName;

  const ErrorCodeParameterType({
    required this.messagesYamlName,
    required this.analyzerName,
  });

  /// Decodes a type name from `messages.yaml` into an [ErrorCodeParameterName].
  factory ErrorCodeParameterType.fromMessagesYamlName(String name) =>
      _messagesYamlNameToValue[name] ??
      (throw StateError('Unknown type name: $name'));
}

/// In-memory representation of error code information obtained from the front
/// end's `messages.yaml` file.
class FrontEndErrorCodeInfo extends ErrorCodeInfo {
  /// The set of analyzer error codes that corresponds to this error code, if
  /// any.
  final List<String> analyzerCode;

  /// The index of the error in the analyzer's `fastaAnalyzerErrorCodes` table.
  final int? index;

  FrontEndErrorCodeInfo.fromYaml(super.yaml)
    : analyzerCode = _decodeAnalyzerCode(yaml['analyzerCode']),
      index = yaml['index'] as int?,
      super.fromYaml();

  @override
  Map<Object?, Object?> toYaml() => {
    if (analyzerCode.isNotEmpty)
      'analyzerCode': _encodeAnalyzerCode(analyzerCode),
    if (index != null) 'index': index,
    ...super.toYaml(),
  };

  static List<String> _decodeAnalyzerCode(Object? value) {
    if (value == null) {
      return const [];
    } else if (value is String) {
      return [value];
    } else if (value is List) {
      return [for (var s in value) s as String];
    } else {
      throw 'Unrecognized analyzer code: $value';
    }
  }

  static Object _encodeAnalyzerCode(List<String> analyzerCode) {
    if (analyzerCode.length == 1) {
      return analyzerCode.single;
    } else {
      return analyzerCode;
    }
  }
}

/// Representation of a single file containing generated error codes.
class GeneratedErrorCodeFile {
  /// The file path (relative to the SDK's `pkg` directory) of the generated
  /// file.
  final String path;

  /// The URI of the library that the generated file will be a part of.
  final String parentLibrary;

  /// Whether the generated file should use the `new` and `const` keywords when
  /// generating constructor invocations.
  final bool shouldUseExplicitNewOrConst;

  final bool shouldIgnorePreferSingleQuotes;

  const GeneratedErrorCodeFile({
    required this.path,
    required this.parentLibrary,
    this.shouldUseExplicitNewOrConst = false,
    this.shouldIgnorePreferSingleQuotes = false,
  });
}
