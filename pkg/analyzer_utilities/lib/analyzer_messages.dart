// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:_fe_analyzer_shared/src/base/errors.dart';
library;

import 'dart:convert';
import 'dart:io';

import 'package:analyzer_testing/package_root.dart' as pkg_root;
import 'package:analyzer_utilities/analyzer_message_constant_style.dart';
import 'package:analyzer_utilities/extensions/string.dart';
import 'package:analyzer_utilities/messages.dart';
import 'package:analyzer_utilities/tools.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart' show YamlMap, YamlScalar, loadYamlNode;

/// Base diagnostic classes used for analyzer messages.
const analyzerBaseClasses = DiagnosticBaseClasses(
  requiresTypeArgument: true,
  withArgumentsClass: 'DiagnosticWithArguments',
  withExpectedTypesClass: 'DiagnosticCodeWithExpectedTypes',
  withoutArgumentsClass: 'DiagnosticWithoutArguments',
  withoutArgumentsImplClass: 'DiagnosticWithoutArgumentsImpl',
);

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
  linterLintCodeInfo,
  DiagnosticClassInfo(
    file: optionCodesFile,
    name: 'AnalysisOptionsErrorCode',
    type: AnalyzerDiagnosticType.compileTimeError,
  ),
  DiagnosticClassInfo(
    file: optionCodesFile,
    name: 'AnalysisOptionsWarningCode',
    type: AnalyzerDiagnosticType.staticWarning,
  ),
  DiagnosticClassInfo(
    file: codesFile,
    name: 'CompileTimeErrorCode',
    type: AnalyzerDiagnosticType.compileTimeError,
  ),
  DiagnosticClassInfo(
    file: syntacticErrorsFile,
    name: 'ScannerErrorCode',
    type: AnalyzerDiagnosticType.syntacticError,
  ),
  DiagnosticClassInfo(
    file: codesFile,
    name: 'StaticWarningCode',
    type: AnalyzerDiagnosticType.staticWarning,
  ),
  DiagnosticClassInfo(
    file: codesFile,
    name: 'WarningCode',
    type: AnalyzerDiagnosticType.staticWarning,
  ),
  DiagnosticClassInfo(
    file: ffiCodesFile,
    name: 'FfiCode',
    type: AnalyzerDiagnosticType.compileTimeError,
  ),
  DiagnosticClassInfo(
    file: hintCodesFile,
    name: 'HintCode',
    type: AnalyzerDiagnosticType.hint,
  ),
  DiagnosticClassInfo(
    file: syntacticErrorsFile,
    name: 'ParserErrorCode',
    type: AnalyzerDiagnosticType.syntacticError,
    deprecatedSnakeCaseNames: {
      'UNEXPECTED_TOKEN', // Referenced by `package:dart_style`.
    },
  ),
  DiagnosticClassInfo(
    file: manifestWarningCodeFile,
    name: 'ManifestWarningCode',
    type: AnalyzerDiagnosticType.staticWarning,
  ),
  DiagnosticClassInfo(
    file: pubspecWarningCodeFile,
    name: 'PubspecWarningCode',
    type: AnalyzerDiagnosticType.staticWarning,
  ),
  DiagnosticClassInfo(
    file: todoCodesFile,
    name: 'TodoCode',
    type: AnalyzerDiagnosticType.todo,
    comment: '''
The error code indicating a marker in code for work that needs to be finished
or revisited.
''',
  ),
  DiagnosticClassInfo(
    file: transformSetErrorCodeFile,
    name: 'TransformSetErrorCode',
    type: AnalyzerDiagnosticType.compileTimeError,
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

const lintCodesFile = GeneratedDiagnosticFile(
  path: generatedLintCodesPath,
  parentLibrary: 'package:linter/src/lint_codes.dart',
  package: AnalyzerDiagnosticPackage.linter,
);

/// Base diagnostic classes used for lint messages.
const linterBaseClasses = DiagnosticBaseClasses(
  requiresTypeArgument: false,
  withArgumentsClass: 'LinterLintTemplate',
  withExpectedTypesClass: 'LinterLintCode',
  withoutArgumentsClass: 'LinterLintWithoutArguments',
  withoutArgumentsImplClass: 'LinterLintWithoutArguments',
);

const linterLintCodeInfo = DiagnosticClassInfo(
  file: lintCodesFile,
  name: 'LinterLintCode',
  type: AnalyzerDiagnosticType.lint,
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
  package: AnalyzerDiagnosticPackage.analysisServer,
);

/// Decoded messages from the analysis server's `messages.yaml` file.
final List<AnalyzerMessage> analysisServerMessages = decodeAnalyzerMessagesYaml(
  analysisServerPkgPath,
);

/// The path to the `analysis_server` package.
final String analysisServerPkgPath = normalize(
  join(pkg_root.packageRoot, 'analysis_server'),
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
  void toAnalyzerCode({
    String? sharedNameReference,
    required MemberAccumulator memberAccumulator,
  }) {
    var constant = StringBuffer();
    outputConstantHeader(constant);
    constant.writeln('const $aliasForClass $constantName =');
    constant.writeln('$aliasFor;');
    memberAccumulator.constants[constantName] = constant.toString();
  }
}

/// Enum representing the packages into which analyzer diagnostics can be
/// generated.
enum AnalyzerDiagnosticPackage {
  analyzer(
    diagnosticPathPart: 'src/diagnostic/diagnostic',
    dirName: 'analyzer',
  ),
  analysisServer(
    diagnosticPathPart: 'src/diagnostic',
    dirName: 'analysis_server',
    shouldIgnorePreferSingleQuotes: true,
  ),
  linter(
    diagnosticPathPart: 'src/diagnostic',
    dirName: 'linter',
    shouldIgnorePreferExpressionFunctionBodies: true,
    shouldIgnorePreferSingleQuotes: true,
  );

  /// The name of the subdirectory of `pkg` containing this package.
  final String dirName;

  /// The part of the path to the generated `diagnostic.g.dart` file that
  /// follows the package's `lib` directory and precedes `diagnostic.g.dart`.
  ///
  /// For example, if [dirName] is `linter` and [diagnosticPathPart] is
  /// `src/diagnostic`, then the full path to the generated `diagnostic.g.dart`
  /// file will be `pkg/linter/lib/src/diagnostic/diagnostic.g.dart`.
  final String diagnosticPathPart;

  /// Whether code generated in this package needs an "ignore" comment to ignore
  /// the `prefer_expression_function_bodies` lint.
  final bool shouldIgnorePreferExpressionFunctionBodies;

  /// Whether code generated in this package needs an "ignore" comment to ignore
  /// the `prefer_single_quotes` lint.
  final bool shouldIgnorePreferSingleQuotes;

  const AnalyzerDiagnosticPackage({
    required this.diagnosticPathPart,
    required this.dirName,
    this.shouldIgnorePreferExpressionFunctionBodies = false,
    this.shouldIgnorePreferSingleQuotes = false,
  });

  void writeIgnoresTo(StringBuffer out) {
    if (shouldIgnorePreferExpressionFunctionBodies) {
      out.write('''

// Code generation is easier if we don't have to decide whether to generate an
// expression function body or a block function body.
// ignore_for_file: prefer_expression_function_bodies
''');
    }
    if (shouldIgnorePreferSingleQuotes) {
      out.write('''

// Code generation is easier using double quotes (since we can use json.convert
// to quote strings).
// ignore_for_file: prefer_single_quotes
''');
    }
    out.write('''

// Generated comments don't quite align with flutter style.
// ignore_for_file: flutter_style_todos
''');
  }
}

/// Enum representing the possible values for the [DiagnosticType] class.
///
/// Code generation logic uses this enum rather than [DiagnosticType] to avoid
/// introducing dependencies between the code generator and the generated code.
enum AnalyzerDiagnosticType {
  compileTimeError,
  hint,
  lint(baseClasses: linterBaseClasses),
  staticWarning,
  syntacticError,
  todo;

  /// Base classes used for messages of this type.
  final DiagnosticBaseClasses baseClasses;

  const AnalyzerDiagnosticType({this.baseClasses = analyzerBaseClasses});
}

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

/// Description of the set of base messages classes used for a certain message
/// type.
class DiagnosticBaseClasses {
  /// Whether the constructor argument `type` must be passed to constructors
  /// when constructing messages of this type.
  final bool requiresTypeArgument;

  /// The name of the concrete class used for messages of this type that require
  /// arguments.
  final String withArgumentsClass;

  /// The name of the concrete class used for messages of this type that require
  /// arguments but don't yet support the literate API.
  // TODO(paulberry): finish supporting the literate API in all analyzer
  // messages and eliminate this.
  final String withExpectedTypesClass;

  /// The name of the abstract class used for messages of this type that do not
  /// require arguments.
  final String withoutArgumentsClass;

  /// The name of the concrete class used for messages of this type that do not
  /// require arguments.
  final String withoutArgumentsImplClass;

  const DiagnosticBaseClasses({
    required this.requiresTypeArgument,
    required this.withArgumentsClass,
    required this.withExpectedTypesClass,
    required this.withoutArgumentsClass,
    required this.withoutArgumentsImplClass,
  });
}

/// Information about a class derived from `DiagnosticCode`.
class DiagnosticClassInfo {
  static final Map<String, DiagnosticClassInfo> _diagnosticClassesByName = () {
    var result = <String, DiagnosticClassInfo>{};
    for (var info in diagnosticClasses) {
      if (result.containsKey(info.name)) {
        throw 'Duplicate diagnostic class name: ${json.encode(info.name)}';
      }
      result[info.name] = info;
    }
    return result;
  }();

  static String get _allDiagnosticClassNames =>
      (_diagnosticClassesByName.keys.toList()..sort())
          .map(json.encode)
          .join(', ');

  /// The name of this class.
  final String name;

  /// The generated file containing this class.
  final GeneratedDiagnosticFile file;

  /// The type of diagnostics in this class.
  final AnalyzerDiagnosticType type;

  /// The names of any diagnostics which are relied upon by analyzer clients,
  /// and therefore will need their "snake case" form preserved (with a
  /// deprecation notice) after migration to camel case diagnostic codes.
  final Set<String> deprecatedSnakeCaseNames;

  /// Documentation comment to generate for the diagnostic class.
  ///
  /// If no documentation comment is needed, this should be the empty string.
  final String comment;

  const DiagnosticClassInfo({
    required this.file,
    required this.name,
    required this.type,
    this.deprecatedSnakeCaseNames = const {},
    this.comment = '',
  });

  /// Generates the code to compute the type of diagnostics of this class.
  String get typeCode =>
      'DiagnosticType.${type.name.toSnakeCase().toUpperCase()}';

  static DiagnosticClassInfo byName(String name) =>
      _diagnosticClassesByName[name] ??
      (throw 'No diagnostic class named ${json.encode(name)}. Possible names: '
          '$_allDiagnosticClassNames');
}

/// Interface class for diagnostic messages that have an analyzer code, and thus
/// can be reported by the analyzer.
mixin MessageWithAnalyzerCode on Message {
  late ConstantStyle constantStyle = () {
    var usesParameters = [problemMessage, correctionMessage].any(
      (value) =>
          value != null && value.any((part) => part is TemplateParameterPart),
    );
    var baseClasses = analyzerCode.diagnosticClass.type.baseClasses;
    if (parameters.isNotEmpty && !usesParameters) {
      throw 'Error code declares parameters using a `parameters` entry, but '
          "doesn't use them";
    } else if (parameters.values.any((p) => !p.type.isSupportedByAnalyzer)) {
      // Do not generate literate API yet.
      return OldConstantStyle(
        concreteClassName: baseClasses.withExpectedTypesClass,
        staticType: 'DiagnosticCode',
      );
    } else if (parameters.isNotEmpty) {
      // Parameters are present so generate a diagnostic template (with
      // `.withArguments` support).
      var withArgumentsParams = parameters.entries
          .map((p) => 'required ${p.value.type.analyzerName} ${p.key}')
          .join(', ');
      var templateParameters =
          '<LocatableDiagnostic Function({$withArgumentsParams})>';
      return WithArgumentsConstantStyle(
        concreteClassName: baseClasses.withArgumentsClass,
        staticType: 'DiagnosticWithArguments$templateParameters',
        withArgumentsParams: withArgumentsParams,
      );
    } else {
      return WithoutArgumentsConstantStyle(
        concreteClassName: baseClasses.withoutArgumentsImplClass,
        staticType: baseClasses.withoutArgumentsClass,
      );
    }
  }();

  late final DiagnosticClassInfo diagnosticClassInfo =
      analyzerCode.diagnosticClass;

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
  void toAnalyzerCode({
    String? sharedNameReference,
    required MemberAccumulator memberAccumulator,
  }) {
    var diagnosticCode = analyzerCode.snakeCaseName;
    var correctionMessage = this.correctionMessage;
    String? withArgumentsName;
    var baseClasses = analyzerCode.diagnosticClass.type.baseClasses;
    var ConstantStyle(:concreteClassName, :staticType) = constantStyle;
    if (constantStyle case WithArgumentsConstantStyle(
      :var withArgumentsParams,
    )) {
      var argumentNames = parameters.keys.join(', ');
      withArgumentsName = '_withArguments${analyzerCode.pascalCaseName}';
      memberAccumulator.staticMethods[withArgumentsName] =
          '''
LocatableDiagnostic $withArgumentsName({$withArgumentsParams}) {
  return LocatableDiagnosticImpl(
    ${analyzerCode.analyzerCodeReference}, [$argumentNames]);
}''';
    }

    var constant = StringBuffer();
    outputConstantHeader(constant);
    constant.writeln('const $staticType $constantName =');
    constant.writeln('$concreteClassName(');
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
    if (baseClasses.requiresTypeArgument) {
      constant.writeln('type: ${diagnosticClassInfo.typeCode},');
    }
    String uniqueName = analyzerCode.toString().replaceFirst(
      'LinterLintCode.',
      'LintCode.',
    );
    constant.writeln("uniqueName: '$uniqueName',");
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
const DiagnosticCode $diagnosticCode = $constantName;
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

  /// Generates a dart declaration for this diagnostic, suitable for inclusion
  /// in the diagnostic class [className].
  ///
  /// The generated code simply redirects to the primary definition of the
  /// diagnostic, imported from `diagnostic.g.dart` using the import prefix
  /// `diag`.
  void toAnalyzerRedirectCode({required MemberAccumulator memberAccumulator}) {
    var diagnosticCode = analyzerCode.snakeCaseName;
    var ConstantStyle(:staticType) = constantStyle;
    var constant = StringBuffer();
    outputConstantHeader(constant);
    constant.writeln('  static const $staticType $constantName =');
    constant.writeln('    diag.$constantName;');
    memberAccumulator.constants[constantName] = constant.toString();

    if (diagnosticClassInfo.deprecatedSnakeCaseNames.contains(diagnosticCode)) {
      memberAccumulator.constants[diagnosticCode] =
          '''
  @Deprecated("Please use $constantName")
  static const DiagnosticCode $diagnosticCode = $constantName;
''';
    }
  }

  /// Generates the appropriate declaration for this diagnostic to include in
  /// the diagnostic class.
  void toClassMember({
    String? sharedNameReference,
    required MemberAccumulator memberAccumulator,
  }) {
    toAnalyzerRedirectCode(memberAccumulator: memberAccumulator);
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
