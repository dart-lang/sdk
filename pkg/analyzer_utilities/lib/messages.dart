// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:analyzer/src/fasta/error_converter.dart';
library;

import 'dart:convert';
import 'dart:io';

import 'package:analyzer_testing/package_root.dart' as pkg_root;
import 'package:analyzer_utilities/extensions/string.dart';
import 'package:analyzer_utilities/tools.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart' show loadYaml, YamlMap;

const Map<String, String> severityEnumNames = <String, String>{
  'CONTEXT': 'context',
  'ERROR': 'error',
  'IGNORED': 'ignored',
  'INTERNAL_PROBLEM': 'internalProblem',
  'WARNING': 'warning',
  'INFO': 'info',
};

/// Decoded messages from the `_fe_analyzer_shared` package's `messages.yaml`
/// file.
final Map<String, SharedErrorCodeInfo> feAnalyzerSharedMessages =
    _loadCfeStyleMessages(
      feAnalyzerSharedPkgPath,
      decodeMessage: SharedErrorCodeInfo.fromYaml,
    );

/// The path to the `fe_analyzer_shared` package.
final String feAnalyzerSharedPkgPath = normalize(
  join(pkg_root.packageRoot, '_fe_analyzer_shared'),
);

/// Decoded messages from the `messages.yaml` files in the front end and
/// `_fe_analyzer_shared`.
final Map<String, CfeStyleErrorCodeInfo> frontEndAndSharedMessages = Map.from(
  frontEndMessages,
)..addAll(feAnalyzerSharedMessages);

/// Decoded messages from the front end's `messages.yaml` file.
final Map<String, FrontEndErrorCodeInfo> frontEndMessages =
    _loadCfeStyleMessages(
      frontEndPkgPath,
      decodeMessage: FrontEndErrorCodeInfo.fromYaml,
    );

/// The path to the `front_end` package.
final String frontEndPkgPath = normalize(
  join(pkg_root.packageRoot, 'front_end'),
);

/// Pattern formerly used by the analyzer to identify placeholders in error
/// message strings.
///
/// (This pattern is still used internally by the analyzer implementation, but
/// it is no longer supported in `messages.yaml`.)
final RegExp oldPlaceholderPattern = RegExp(r'\{\d+\}');

/// Pattern for placeholders in error message strings.
final RegExp placeholderPattern = RegExp(
  '#([-a-zA-Z0-9_]+)(?:%([0-9]*).([0-9]+))?',
);

/// A set of tables mapping between shared and analyzer error codes.
final SharedToAnalyzerErrorCodeTables sharedToAnalyzerErrorCodeTables =
    SharedToAnalyzerErrorCodeTables._(feAnalyzerSharedMessages);

/// Convert a template string (which uses placeholders matching
/// [placeholderPattern]) to an analyzer internal template string (which uses
/// placeholders like `{0}`).
String convertTemplate(Map<String, int> placeholderToIndexMap, String entry) {
  return entry.replaceAllMapped(
    placeholderPattern,
    (match) => '{${placeholderToIndexMap[match.group(0)!]}}',
  );
}

/// Decodes a YAML object (in CFE style `messages.yaml` format) into a map from
/// error name to [ErrorCodeInfo].
Map<String, T> decodeCfeStyleMessagesYaml<T extends CfeStyleErrorCodeInfo>(
  Object? yaml, {
  required T Function(YamlMap) decodeMessage,
  required String path,
}) {
  Never problem(String message) {
    throw 'Problem in $path: $message';
  }

  var result = <String, T>{};
  if (yaml is! Map<Object?, Object?>) {
    problem('root node is not a map');
  }
  for (var entry in yaml.entries) {
    var errorName = entry.key;
    if (errorName is! String) {
      problem('non-string error key ${json.encode(errorName)}');
    }
    var errorValue = entry.value;
    if (errorValue is! YamlMap) {
      problem('value associated with error $errorName is not a map');
    }
    try {
      result[errorName] = decodeMessage(errorValue);
    } catch (e, st) {
      Error.throwWithStackTrace(
        'while processing $errorName from $path, $e',
        st,
      );
    }
  }
  return result;
}

/// Loads messages in CFE style `messages.yaml` format.
Map<String, T> _loadCfeStyleMessages<T extends CfeStyleErrorCodeInfo>(
  String packagePath, {
  required T Function(YamlMap) decodeMessage,
}) {
  var path = join(packagePath, 'messages.yaml');
  Object? messagesYaml = loadYaml(
    File(path).readAsStringSync(),
    sourceUrl: Uri.file(path),
  );
  return decodeCfeStyleMessagesYaml(
    messagesYaml,
    decodeMessage: decodeMessage,
    path: path,
  );
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

/// An analyzer error code, consisting of an optional class name and an error
/// name.
///
/// This class implements [operator==] and [hashCode] so it can be used as a map
/// key or in a set.
///
/// This class implements [Comparable], so lists of it can be safely
/// [List.sort]ed.
class AnalyzerCode implements Comparable<AnalyzerCode> {
  /// The class name.
  final String className;

  /// The error name.
  ///
  /// The error name is in "snake case", meaning it consists of words separated
  /// by underscores. Those words might be lower case or upper case.
  ///
  // TODO(paulberry): change `messages.yaml` to consistently use lower snake
  // case.
  final String snakeCaseErrorName;

  AnalyzerCode({required this.className, required this.snakeCaseErrorName});

  /// The error name, converted to camel case.
  String get camelCaseErrorName => snakeCaseErrorName.toCamelCase();

  @override
  int get hashCode => Object.hash(className, snakeCaseErrorName);

  @override
  bool operator ==(Object other) =>
      other is AnalyzerCode &&
      className == other.className &&
      snakeCaseErrorName == other.snakeCaseErrorName;

  @override
  int compareTo(AnalyzerCode other) {
    var className = this.className;
    var otherClassName = other.className;
    if (className.compareTo(otherClassName) case var result when result != 0) {
      return result;
    }
    return snakeCaseErrorName.compareTo(other.snakeCaseErrorName);
  }

  @override
  String toString() => [className, snakeCaseErrorName].join('.');
}

/// In-memory representation of error code information obtained from a
/// `messages.yaml` file in `pkg/front_end` or `pkg/_fe_analyzer_shared`.
abstract class CfeStyleErrorCodeInfo extends ErrorCodeInfo {
  /// The index of the error in the analyzer's `fastaAnalyzerErrorCodes` table.
  final int? index;

  /// The name of the [CfeSeverity] constant describing this error code's CFE
  /// severity.
  final String? cfeSeverity;

  CfeStyleErrorCodeInfo.fromYaml(YamlMap yaml)
    : index = _decodeIndex(yaml['index']),
      cfeSeverity = _decodeSeverity(yaml['severity']),
      super.fromYaml(yaml) {
    if (yaml['problemMessage'] == null) {
      throw 'Missing problemMessage';
    }
  }

  static int? _decodeIndex(Object? value) {
    switch (value) {
      case null:
        return null;
      case int():
        if (value >= 1) {
          return value;
        }
    }
    throw 'Expected positive int for "index:", but found $value';
  }

  static String? _decodeSeverity(Object? yamlEntry) {
    switch (yamlEntry) {
      case null:
        return null;
      case String():
        return severityEnumNames[yamlEntry] ??
            (throw "Unknown severity '$yamlEntry'");
      default:
        throw 'Bad severity type: ${yamlEntry.runtimeType}';
    }
  }
}

/// Information about how to convert the CFE's internal representation of a
/// template parameter to a string.
///
/// Instances of this class should implement [==] and [hashCode] so that they
/// can be used as keys in a [Map].
sealed class Conversion {
  /// Returns Dart code that applies the conversion to a template parameter
  /// having the given [name] and [type].
  ///
  /// If no conversion is needed, returns `null`.
  String? toCode({required String name, required ErrorCodeParameterType type});
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

  /// Map describing the parameters for this error code, obtained from the
  /// `parameters` entry in the yaml file.
  ///
  /// Map keys are parameter names. Map values are [ErrorCodeParameter] objects.
  final Map<String, ErrorCodeParameter> parameters;

  /// The raw YAML node that this `ErrorCodeInfo` was parsed from, or `null` if
  /// this `ErrorCodeInfo` was created without reference to a raw YAML node.
  ///
  /// This exists to make it easier for automated scripts to edit the YAML
  /// source.
  final YamlMap? yamlNode;

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
    required this.parameters,
    this.yamlNode,
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
  ErrorCodeInfo.fromYaml(YamlMap yaml)
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
        yamlNode: yaml,
      );

  /// If this error is no longer reported and
  /// its error codes should no longer be generated.
  bool get isRemoved => removedIn != null;

  /// Given a messages.yaml entry, come up with a mapping from placeholder
  /// patterns in its message strings to their corresponding indices.
  Map<String, int> computePlaceholderToIndexMap() {
    // Parameters are always explicitly specified, so the mapping is determined
    // by the order in which they were specified.
    return {for (var (index, name) in parameters.keys.indexed) '#$name': index};
  }

  void outputConstantHeader(StringSink out) {
    out.write(toAnalyzerComments(indent: '  '));
    if (deprecatedMessage != null) {
      out.writeln('  @Deprecated("$deprecatedMessage")');
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
    if (parameters.isNotEmpty && !usesParameters) {
      throw StateError(
        'Error code declares parameters using a `parameters` entry, but '
        "doesn't use them",
      );
    } else if (parameters.values.any((p) => !p.type.isSupportedByAnalyzer)) {
      // Do not generate literate API yet.
      className = errorClassInfo.name;
    } else if (parameters.isNotEmpty) {
      // Parameters are present so generate a diagnostic template (with
      // `.withArguments` support).
      className = errorClassInfo.templateName;
      var withArgumentsParams = parameters.entries
          .map((p) => 'required ${p.value.type.analyzerName} ${p.key}')
          .join(', ');
      var argumentNames = parameters.keys.join(', ');
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
    outputConstantHeader(constant);
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

  static Map<String, ErrorCodeParameter> _decodeParameters(Object? yaml) {
    if (yaml == null) {
      throw StateError('Missing parameters section');
    }
    if (yaml == 'none') return const {};
    yaml as Map<Object?, Object?>;
    var result = <String, ErrorCodeParameter>{};
    for (var MapEntry(:key, :value) in yaml.entries) {
      switch ((key as String).split(' ')) {
        case [var type, var name]:
          if (result.containsKey(name)) {
            throw StateError('Duplicate parameter name: $name');
          }
          result[name] = ErrorCodeParameter(
            type: ErrorCodeParameterType.fromMessagesYamlName(type),
            comment: value as String,
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
///
/// The name of the parameter is not included, since parameters are stored in a
/// map from name to [ErrorCodeParameter].
class ErrorCodeParameter {
  final ErrorCodeParameterType type;
  final String comment;

  ErrorCodeParameter({required this.type, required this.comment});
}

/// In-memory representation of the type of a single diagnostic code's
/// parameter.
enum ErrorCodeParameterType {
  character(
    messagesYamlName: 'Character',
    cfeName: 'String',
    cfeConversion: SimpleConversion('validateCharacter'),
  ),
  constant(
    messagesYamlName: 'Constant',
    cfeName: 'Constant',
    cfeConversion: LabelerConversion('labelConstant'),
  ),
  element(messagesYamlName: 'Element', analyzerName: 'Element'),
  int(messagesYamlName: 'int', analyzerName: 'int', cfeName: 'int'),
  name(
    messagesYamlName: 'Name',
    cfeName: 'String',
    cfeConversion: SimpleConversion('validateAndDemangleName'),
  ),
  nameOKEmpty(
    messagesYamlName: 'NameOKEmpty',
    cfeName: 'String',
    cfeConversion: SimpleConversion('nameOrUnnamed'),
  ),
  names(
    messagesYamlName: 'Names',
    cfeName: 'List<String>',
    cfeConversion: SimpleConversion('validateAndItemizeNames'),
  ),
  num(
    messagesYamlName: 'num',
    cfeName: 'num',
    cfeConversion: SimpleConversion('formatNumber'),
  ),
  object(messagesYamlName: 'Object', analyzerName: 'Object'),
  string(
    messagesYamlName: 'String',
    analyzerName: 'String',
    cfeName: 'String',
    cfeConversion: SimpleConversion('validateString'),
  ),
  stringOKEmpty(
    messagesYamlName: 'StringOKEmpty',
    analyzerName: 'String',
    cfeName: 'String',
    cfeConversion: SimpleConversion('stringOrEmpty'),
  ),
  token(
    messagesYamlName: 'Token',
    cfeName: 'Token',
    cfeConversion: SimpleConversion('tokenToLexeme'),
  ),
  type(
    messagesYamlName: 'Type',
    analyzerName: 'DartType',
    cfeName: 'DartType',
    cfeConversion: LabelerConversion('labelType'),
  ),
  unicode(
    messagesYamlName: 'Unicode',
    cfeName: 'int',
    cfeConversion: SimpleConversion('codePointToUnicode'),
  ),
  uri(
    messagesYamlName: 'Uri',
    analyzerName: 'Uri',
    cfeName: 'Uri',
    cfeConversion: SimpleConversion('relativizeUri'),
  );

  /// Map from [messagesYamlName] to the enum constant.
  ///
  /// Used for decoding parameter types from `messages.yaml`.
  static final _messagesYamlNameToValue = {
    for (var value in values) value.messagesYamlName: value,
  };

  /// Name of this type as it appears in `messages.yaml`.
  final String messagesYamlName;

  /// Name of this type as it appears in analyzer source code.
  ///
  /// If `null`, diagnostic messages using parameters of this type are not yet
  /// supported by the analyzer (see [isSupportedByAnalyzer])
  final String? _analyzerName;

  /// Name of this type as it appears in CFE source code.
  ///
  /// If `null`, diagnostic messages using parameters of this type are not
  /// supported by the CFE.
  final String? cfeName;

  /// How to convert the CFE's internal representation of a template parameter
  /// to a string.
  ///
  /// This field will be `null` if either:
  /// - Diagnostic messages using parameters of this type are not supported by
  ///   the CFE (and hence no CFE conversion is needed), or
  /// - No CFE conversion is needed because the type's `toString` method is
  ///   sufficient.
  final Conversion? cfeConversion;

  const ErrorCodeParameterType({
    required this.messagesYamlName,
    String? analyzerName,
    this.cfeName,
    this.cfeConversion,
  }) : _analyzerName = analyzerName;

  /// Decodes a type name from `messages.yaml` into an [ErrorCodeParameterName].
  factory ErrorCodeParameterType.fromMessagesYamlName(String name) =>
      _messagesYamlNameToValue[name] ??
      (throw StateError('Unknown type name: $name'));

  String get analyzerName =>
      _analyzerName ??
      (throw 'No analyzer support for type ${json.encode(messagesYamlName)}');

  /// Whether giatnostic messages using parameters of this type are supported by
  /// the analyzer.
  bool get isSupportedByAnalyzer => _analyzerName != null;
}

/// In-memory representation of error code information obtained from the file
/// `pkg/front_end/messages.yaml`.
class FrontEndErrorCodeInfo extends CfeStyleErrorCodeInfo {
  /// The value of the `pseudoSharedCode` property in
  /// `pkg/front_end/messages.yaml`.
  ///
  /// Messages with this property set are not shared; they have separately
  /// declared analyzer and CFE codes. However, they are reported by code
  /// defined in `pkg/_fe_analyzer_shared` using the CFE error reporting
  /// mechanism. When running under the analyzer, they are then translated
  /// into the associated analyzer error using [FastaErrorReporter].
  // TODO(paulberry): migrate all pseudo-shared error codes to shared error
  // codes.
  final String? pseudoSharedCode;

  FrontEndErrorCodeInfo.fromYaml(YamlMap yaml)
    : pseudoSharedCode = yaml['pseudoSharedCode'] as String?,
      super.fromYaml(yaml) {
    if (yaml['analyzerCode'] != null) {
      throw StateError('Only shared messages can have an analyzer code');
    }
    if (index != null) {
      throw StateError('Non-shared messages must not have an index');
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

/// A [Conversion] that makes use of the [TypeLabeler] class.
class LabelerConversion implements Conversion {
  /// The name of the [TypeLabeler] method to call.
  final String methodName;

  const LabelerConversion(this.methodName);

  @override
  int get hashCode => Object.hash(runtimeType, methodName.hashCode);

  @override
  bool operator ==(Object other) =>
      other is LabelerConversion && other.methodName == methodName;

  @override
  String toCode({required String name, required ErrorCodeParameterType type}) =>
      'labeler.$methodName($name)';
}

/// A [Conversion] that acts on [num], applying formatting parameters specified
/// in the template.
class NumericConversion implements Conversion {
  /// If non-null, the number of digits to show after the decimal point.
  final int? fractionDigits;

  /// The minimum number of characters of output to be generated.
  ///
  /// If the number does not require this many characters to display, extra
  /// padding characters are inserted to the left.
  final int padWidth;

  /// If `true`, '0' is used for padding (see [padWidth]); otherwise ' ' is
  /// used.
  final bool padWithZeros;

  NumericConversion({
    required this.fractionDigits,
    required this.padWidth,
    required this.padWithZeros,
  });

  @override
  int get hashCode => Object.hash(
    runtimeType,
    fractionDigits.hashCode,
    padWidth.hashCode,
    padWithZeros.hashCode,
  );

  @override
  bool operator ==(Object other) =>
      other is NumericConversion &&
      other.fractionDigits == fractionDigits &&
      other.padWidth == padWidth &&
      other.padWithZeros == padWithZeros;

  @override
  String? toCode({required String name, required ErrorCodeParameterType type}) {
    if (type != ErrorCodeParameterType.num) {
      throw 'format suffix may only be applied to parameters of type num';
    }
    return 'conversions.formatNumber($name, fractionDigits: $fractionDigits, '
        'padWidth: $padWidth, padWithZeros: $padWithZeros)';
  }

  /// Creates a [NumericConversion] from the given regular expression [match].
  ///
  /// [match] should be the result of matching [placeholderPattern] to the
  /// template string.
  ///
  /// Returns `null` if no special numeric conversion is needed.
  static NumericConversion? from(Match match) {
    String? padding = match[2];
    String? fractionDigitsStr = match[3];

    int? fractionDigits = fractionDigitsStr == null
        ? null
        : int.parse(fractionDigitsStr);
    if (padding != null && padding.isNotEmpty) {
      return NumericConversion(
        fractionDigits: fractionDigits,
        padWidth: int.parse(padding),
        padWithZeros: padding.startsWith('0'),
      );
    } else if (fractionDigits != null) {
      return NumericConversion(
        fractionDigits: fractionDigits,
        padWidth: 0,
        padWithZeros: false,
      );
    } else {
      return null;
    }
  }
}

/// The result of parsing a [placeholderPattern] match in a template string.
class ParsedPlaceholder {
  /// The name of the template parameter.
  ///
  /// This is the identifier that immediately follows the `#`.
  final String name;

  /// The conversion specified in the placeholder, if any.
  ///
  /// If `null`, the default conversion for the parameter's type will be used.
  final Conversion? conversionOverride;

  /// Builds a [ParsedPlaceholder] from the given [match] of
  /// [placeholderPattern].
  factory ParsedPlaceholder.fromMatch(Match match) {
    String name = match[1]!;

    return ParsedPlaceholder._(
      name: name,
      conversionOverride: NumericConversion.from(match),
    );
  }

  ParsedPlaceholder._({required this.name, required this.conversionOverride});

  @override
  int get hashCode => Object.hash(name, conversionOverride);

  @override
  bool operator ==(Object other) =>
      other is ParsedPlaceholder &&
      other.name == name &&
      other.conversionOverride == conversionOverride;
}

/// In-memory representation of error code information obtained from the file
/// `pkg/_fe_analyzer_shared/messages.yaml`.
class SharedErrorCodeInfo extends CfeStyleErrorCodeInfo {
  /// The analyzer error code that corresponds to this shared error code.
  ///
  /// Shared error codes are required to have exactly one analyzer error code
  /// associated with them.
  final AnalyzerCode analyzerCode;

  SharedErrorCodeInfo.fromYaml(super.yaml)
    : analyzerCode = _decodeAnalyzerCode(
        (yaml['analyzerCode'] ??
                (throw StateError(
                  'Shared error codes must specify an analyzerCode.',
                )))
            as String,
      ),
      super.fromYaml() {
    if (super.index == null) {
      throw StateError('Shared messages must have an index');
    }
  }

  /// The index of the error in the analyzer's `fastaAnalyzerErrorCodes` table.
  ///
  /// Shared error codes are required to have a non-null index.
  @override
  int get index => super.index!;

  static AnalyzerCode _decodeAnalyzerCode(String s) {
    switch (s.split('.')) {
      case [var className, var errorName]
          when errorName == errorName.toUpperCase():
        return AnalyzerCode(
          className: className,
          snakeCaseErrorName: errorName,
        );
      default:
        throw StateError(
          'Analyzer codes must take the form ClassName.DIAGNOSTIC_NAME. Found '
          '${json.encode(s)} instead.',
        );
    }
  }
}

/// Data tables mapping between shared errors and their corresponding
/// automatically generated analyzer errors.
class SharedToAnalyzerErrorCodeTables {
  /// List of shared errors for which analyzer errors should be automatically
  /// generated, organized by their `index` property.
  final List<SharedErrorCodeInfo?> indexToInfo = [];

  /// Map whose values are the shared errors for which analyzer errors should be
  /// automatically generated, and whose keys are the corresponding analyzer
  /// error code.
  final Map<AnalyzerCode, SharedErrorCodeInfo> analyzerCodeToInfo = {};

  /// Map whose values are the shared errors for which analyzer errors should be
  /// automatically generated, and whose keys are the front end error name.
  final Map<String, SharedErrorCodeInfo> frontEndCodeToInfo = {};

  /// Map whose keys are the shared errors for which analyzer errors should be
  /// automatically generated, and whose values are the corresponding analyzer
  /// error name.
  final Map<SharedErrorCodeInfo, AnalyzerCode> infoToAnalyzerCode = {};

  /// Map whose keys are the shared errors for which analyzer errors should be
  /// automatically generated, and whose values are the front end error name.
  final Map<SharedErrorCodeInfo, String> infoToFrontEndCode = {};

  SharedToAnalyzerErrorCodeTables._(Map<String, SharedErrorCodeInfo> messages) {
    for (var entry in messages.entries) {
      var errorCodeInfo = entry.value;
      var index = errorCodeInfo.index;
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
      var analyzerCode = errorCodeInfo.analyzerCode;
      // TODO(paulberry): allow shared errors to be things other than parser
      // errors. See `ErrorClassInfo.includeCfeMessages`.
      var expectedClassName = 'ParserErrorCode';
      if (analyzerCode.className != expectedClassName) {
        throw 'Expected all analyzer error codes to be prefixed with '
            '${json.encode('$expectedClassName.')}.  Found '
            '${json.encode(analyzerCode.toString())}.';
      }
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

/// A [Conversion] that invokes a top level function via the `conversions`
/// import prefix.
class SimpleConversion implements Conversion {
  /// The name of the function to be invoked.
  final String functionName;

  const SimpleConversion(this.functionName);

  @override
  int get hashCode => Object.hash(runtimeType, functionName.hashCode);

  @override
  bool operator ==(Object other) =>
      other is SimpleConversion && other.functionName == functionName;

  @override
  String toCode({required String name, required ErrorCodeParameterType type}) =>
      'conversions.$functionName($name)';
}
