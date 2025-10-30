// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:analyzer/src/fasta/error_converter.dart';
library;

import 'dart:convert';
import 'dart:io';

import 'package:analyzer_testing/package_root.dart' as pkg_root;
import 'package:analyzer_utilities/analyzer_messages.dart';
import 'package:analyzer_utilities/extensions/string.dart';
import 'package:analyzer_utilities/tools.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart';
import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart'
    show YamlMap, YamlScalar, YamlNode, loadYamlNode;

const Map<String, String> severityEnumNames = <String, String>{
  'CONTEXT': 'context',
  'IGNORED': 'ignored',
  'INTERNAL_PROBLEM': 'internalProblem',
  'WARNING': 'warning',
  'INFO': 'info',
};

/// A set of tables derived from shared, CFE, analyzer, and linter diagnostics.
///
/// For details see the documentation for fields in the [DiagnosticTables]
/// class.
final DiagnosticTables diagnosticTables = DiagnosticTables._([
  ...frontEndMessages,
  ...feAnalyzerSharedMessages,
  ...analyzerMessages,
  ...lintMessages,
]);

/// Decoded messages from the `_fe_analyzer_shared` package's `messages.yaml`
/// file.
final List<SharedMessage> feAnalyzerSharedMessages = _loadCfeStyleMessages(
  feAnalyzerSharedPkgPath,
  decodeMessage: SharedMessage.new,
);

/// The path to the `fe_analyzer_shared` package.
final String feAnalyzerSharedPkgPath = normalize(
  join(pkg_root.packageRoot, '_fe_analyzer_shared'),
);

/// Decoded messages from the front end's `messages.yaml` file.
final List<FrontEndMessage> frontEndMessages = _loadCfeStyleMessages(
  frontEndPkgPath,
  decodeMessage: FrontEndMessage.new,
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

/// Converts a template to an analyzer internal template string (which uses
/// placeholders like `{0}`).
String convertTemplate(List<TemplatePart> template) {
  return template
      .map(
        (part) => switch (part) {
          TemplateLiteralPart(:var text) => text,
          TemplateParameterPart(:var parameter) => '{${parameter.index}}',
        },
      )
      .join();
}

/// Decodes a YAML object (in CFE style `messages.yaml` format) into a list of
/// [CfeStyleMessage]s.
List<T> decodeCfeStyleMessagesYaml<T extends CfeStyleMessage>(
  YamlNode yaml, {
  required T Function(MessageYaml) decodeMessage,
  required String path,
}) {
  var result = <T>[];
  if (yaml is! YamlMap) {
    throw LocatedError('root node is not a map', span: yaml.span);
  }
  for (var entry in yaml.nodes.entries) {
    var keyNode = entry.key as YamlScalar;
    var diagnosticName = keyNode.value;
    if (diagnosticName is! String) {
      throw LocatedError(
        'non-string diagnostic key ${json.encode(diagnosticName)}',
        span: keyNode.span,
      );
    }
    var diagnosticValue = entry.value;
    if (diagnosticValue is! YamlMap) {
      throw LocatedError(
        'value associated with diagnostic $diagnosticName is not a map',
        span: diagnosticValue.span,
      );
    }
    result.add(
      MessageYaml.decode(
        key: keyNode,
        value: diagnosticValue,
        decoder: decodeMessage,
      ),
    );
  }
  return result;
}

/// Loads messages in CFE style `messages.yaml` format.
List<T> _loadCfeStyleMessages<T extends CfeStyleMessage>(
  String packagePath, {
  required T Function(MessageYaml) decodeMessage,
}) {
  var path = join(packagePath, 'messages.yaml');
  var messagesYaml = loadYamlNode(
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
  /// The class containing the constant for this diagnostic.
  final DiagnosticClassInfo diagnosticClass;

  /// The diagnostic name.
  ///
  /// The diagnostic name is in "snake case", meaning it consists of words
  /// separated by underscores. Those words might be lower case or upper case.
  ///
  // TODO(paulberry): change `messages.yaml` to consistently use lower snake
  // case.
  final String snakeCaseName;

  AnalyzerCode({required this.diagnosticClass, required this.snakeCaseName});

  /// The string that should be generated into analyzer source code to refer to
  /// this diagnostic code.
  String get analyzerCodeReference =>
      [diagnosticClass.name, camelCaseName].join('.');

  /// The diagnostic name, converted to camel case.
  String get camelCaseName => snakeCaseName.toCamelCase();

  @override
  int get hashCode => Object.hash(diagnosticClass, snakeCaseName);

  /// The diagnostic name, converted to PascalCase.
  String get pascalCaseName => snakeCaseName.toPascalCase();

  @override
  bool operator ==(Object other) =>
      other is AnalyzerCode &&
      diagnosticClass == other.diagnosticClass &&
      snakeCaseName == other.snakeCaseName;

  @override
  int compareTo(AnalyzerCode other) {
    // Compare the diagnostic classes by name. This works because we know that
    // the diagnostic classes are unique (this is verified by the
    // `DiagnosticClassInfo.byName` method).
    var className = diagnosticClass.name;
    var otherClassName = other.diagnosticClass.name;
    if (className.compareTo(otherClassName) case var result when result != 0) {
      return result;
    }
    return snakeCaseName.compareTo(other.snakeCaseName);
  }

  @override
  String toString() => [diagnosticClass.name, snakeCaseName].join('.');
}

/// In-memory representation of diagnostic information obtained from a
/// `messages.yaml` file in `pkg/front_end` or `pkg/_fe_analyzer_shared`.
abstract class CfeStyleMessage extends Message {
  /// The name of the [CfeSeverity] constant describing this diagnostic's CFE
  /// severity.
  final String? cfeSeverity;

  /// The name used by the front end to refer to this diagnostic.
  ///
  /// This is the key corresponding to the diagnostic's entry in
  /// `messages.yaml`.
  final String frontEndCode;

  CfeStyleMessage(MessageYaml messageYaml)
    : cfeSeverity = messageYaml.get(
        'severity',
        decode: (node) {
          switch (node) {
            case YamlScalar(:var value):
              if (value == 'ERROR') {
                throw 'The "ERROR" severity is the default and not necessary.';
              }
              return severityEnumNames[value] ??
                  (throw "Unknown severity '$value'");
            default:
              return throw 'Bad severity type: ${node.runtimeType}';
          }
        },
        ifAbsent: () => null,
      ),
      frontEndCode = messageYaml.keyString,
      super(messageYaml, requireProblemMessage: true) {
    // Ignore extra keys related to front end example-based tests.
    messageYaml.allowExtraKeys({
      'bytes',
      'declaration',
      'exampleAllowMultipleReports',
      'exampleAllowOtherCodes',
      'experiments',
      'expression',
      'external',
      'includeErrorContext',
      'script',
      'statement',
    });
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
  String? toCode({required String name, required DiagnosticParameterType type});
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

  const DiagnosticClassInfo({required this.name});

  static DiagnosticClassInfo byName(String name) =>
      _diagnosticClassesByName[name] ??
      (throw 'No diagnostic class named ${json.encode(name)}. Possible names: '
          '$_allDiagnosticClassNames');
}

/// In-memory representation of a single key/value pair from the `parameters`
/// map for a diagnostic.
class DiagnosticParameter {
  final String name;
  final DiagnosticParameterType type;
  final String comment;
  final int index;

  DiagnosticParameter({
    required this.name,
    required this.type,
    required this.comment,
    required this.index,
  });
}

/// In-memory representation of the type of a single diagnostic code's
/// parameter.
enum DiagnosticParameterType {
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

  const DiagnosticParameterType({
    required this.messagesYamlName,
    String? analyzerName,
    this.cfeName,
    this.cfeConversion,
  }) : _analyzerName = analyzerName;

  /// Decodes a type name from `messages.yaml` into a [DiagnosticParameterType].
  factory DiagnosticParameterType.fromMessagesYamlName(String name) =>
      _messagesYamlNameToValue[name] ?? (throw 'Unknown type name: $name');

  String get analyzerName =>
      _analyzerName ??
      (throw 'No analyzer support for type ${json.encode(messagesYamlName)}');

  /// Whether giatnostic messages using parameters of this type are supported by
  /// the analyzer.
  bool get isSupportedByAnalyzer => _analyzerName != null;
}

/// A set of tables derived from shared, CFE, analyzer, and linter diagnostics.
class DiagnosticTables {
  /// List of shared diagnostics for which analyzer diagnostics should be
  /// automatically generated, sorted by analyzer code.
  final List<SharedMessage> sortedSharedDiagnostics = [];

  /// List of front end diagnostics, sorted by front end code.
  final List<CfeStyleMessage> sortedFrontEndDiagnostics = [];

  /// Map from [AnalyzerDiagnosticPackage] to the list of active diagnostic
  /// messages for that package.
  ///
  /// A message is considered active is [MessageWithAnalyzerCode.isRemoved] is
  /// `false` and the message is not an [AliasMessage].
  ///
  /// Each list is sorted by analyzer code.
  final Map<AnalyzerDiagnosticPackage, List<MessageWithAnalyzerCode>>
  activeMessagesByPackage = {};

  DiagnosticTables._(List<Message> messages) {
    var frontEndCodeDuplicateChecker = _DuplicateChecker<String>(
      kind: 'Front end code',
    );
    var analyzerCodeDuplicateChecker = _DuplicateChecker<AnalyzerCode>(
      kind: 'Analyzer code',
    );
    var analyzerCodeCamelCaseNameDuplicateChecker = _DuplicateChecker<String>(
      kind: 'Analyzer code camelCase name',
    );
    var analyzerSharedNameToMessages =
        <String, List<MessageWithAnalyzerCode>>{};
    for (var message in messages) {
      if (message is CfeStyleMessage) {
        var frontEndCode = message.frontEndCode;
        frontEndCodeDuplicateChecker[frontEndCode] = message;
        sortedFrontEndDiagnostics.add(message);
      }
      if (message is SharedMessage) {
        sortedSharedDiagnostics.add(message);
      }
      if (message is MessageWithAnalyzerCode) {
        var analyzerCode = message.analyzerCode;
        analyzerCodeDuplicateChecker[analyzerCode] = message;
        analyzerCodeCamelCaseNameDuplicateChecker[analyzerCode.camelCaseName] =
            message;
        (analyzerSharedNameToMessages[message.sharedName ??
                    analyzerCode.snakeCaseName] ??=
                [])
            .add(message);
        var diagnosticClass = analyzerCode.diagnosticClass;
        if (diagnosticClass is GeneratedDiagnosticClassInfo &&
            !message.isRemoved &&
            message is! AliasMessage) {
          (activeMessagesByPackage[diagnosticClass.package] ??= []).add(
            message,
          );
        }
      }
    }

    analyzerCodeDuplicateChecker.check();
    analyzerCodeCamelCaseNameDuplicateChecker.check();
    frontEndCodeDuplicateChecker.check();
    _checkSharedNames(analyzerSharedNameToMessages);

    sortedSharedDiagnostics.sortBy((e) => e.analyzerCode.camelCaseName);
    sortedFrontEndDiagnostics.sortBy((e) => e.frontEndCode);
    for (var value in activeMessagesByPackage.values) {
      value.sortBy((e) => e.analyzerCode);
    }
  }

  static void _checkSharedNames(
    Map<String, List<MessageWithAnalyzerCode>> analyzerSharedNameToMessages,
  ) {
    for (var MapEntry(key: sharedName, value: messages)
        in analyzerSharedNameToMessages.entries) {
      if (messages case [
        var message,
      ] when sharedName != message.analyzerCode.snakeCaseName) {
        var sharedNameJson = json.encode(sharedName);
        throw LocatedError(
          'This is the only message that uses shared name '
          '$sharedNameJson. The message should be renamed to $sharedNameJson.',
          span: message.keySpan,
        );
      }
    }
  }
}

/// In-memory representation of diagnostic information obtained from the file
/// `pkg/front_end/messages.yaml`.
class FrontEndMessage extends CfeStyleMessage {
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

  FrontEndMessage(super.messageYaml)
    : pseudoSharedCode = messageYaml.getOptionalString('pseudoSharedCode');
}

/// Information about a code generated class derived from `DiagnosticCode`.
class GeneratedDiagnosticClassInfo extends DiagnosticClassInfo {
  /// The generated file containing this class.
  final GeneratedDiagnosticFile file;

  /// The severity of diagnostics in this class, or `null` if the severity
  /// should be based on the [type] of the diagnostic.
  final String? severity;

  /// The type of diagnostics in this class.
  final String type;

  /// The names of any diagnostics which are relied upon by analyzer clients,
  /// and therefore will need their "snake case" form preserved (with a
  /// deprecation notice) after migration to camel case diagnostic codes.
  final Set<String> deprecatedSnakeCaseNames;

  /// The package into which the diagnostic codes will be generated.
  final AnalyzerDiagnosticPackage package;

  /// Documentation comment to generate for the diagnostic class.
  ///
  /// If no documentation comment is needed, this should be the empty string.
  final String comment;

  const GeneratedDiagnosticClassInfo({
    required this.file,
    required super.name,
    this.severity,
    required this.type,
    this.deprecatedSnakeCaseNames = const {},
    this.package = AnalyzerDiagnosticPackage.analyzer,
    this.comment = '',
  });

  /// Generates the code to compute the severity of diagnostics of this class.
  String get severityCode {
    var severity = this.severity;
    if (severity == null) {
      return '$typeCode.severity';
    } else {
      return 'DiagnosticSeverity.$severity';
    }
  }

  String get templateName => '${_baseName}Template';

  /// Generates the code to compute the type of diagnostics of this class.
  String get typeCode => 'DiagnosticType.$type';

  String get withoutArgumentsName => '${_baseName}WithoutArguments';

  String get _baseName {
    const suffix = 'Code';
    if (name.endsWith(suffix)) {
      return name.substring(0, name.length - suffix.length);
    } else {
      throw "Can't infer base name for class $name";
    }
  }
}

/// Representation of a single file containing generated diagnostics.
class GeneratedDiagnosticFile {
  /// The file path (relative to the SDK's `pkg` directory) of the generated
  /// file.
  final String path;

  /// The URI of the library that the generated file will be a part of.
  final String parentLibrary;

  /// Whether the generated file should use the `new` and `const` keywords when
  /// generating constructor invocations.
  final bool shouldUseExplicitNewOrConst;

  final bool shouldIgnorePreferSingleQuotes;

  const GeneratedDiagnosticFile({
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
  String toCode({
    required String name,
    required DiagnosticParameterType type,
  }) => 'labeler.$methodName($name)';
}

/// An error with an associated source span.
class LocatedError {
  final SourceSpan span;
  final String message;

  LocatedError(this.message, {required this.span});

  @override
  String toString() => '${span.location}: $message';

  /// Executes [callback], converting any exceptions it generates to a
  /// [LocatedError] that points to [node].
  static T wrap<T>(T Function() callback, {required SourceSpan span}) {
    try {
      return callback();
    } catch (error, stackTrace) {
      if (error is! LocatedError) {
        Error.throwWithStackTrace(
          LocatedError(error.toString(), span: span),
          stackTrace,
        );
      } else {
        rethrow;
      }
    }
  }
}

/// In-memory representation of diagnostic information obtained from either the
/// analyzer or the front end's `messages.yaml` file.  This class contains the
/// common functionality supported by both formats.
abstract class Message {
  /// If present, a documentation comment that should be associated with the
  /// diagnostic in code generated output.
  final String? comment;

  /// If the diagnostic has an associated correctionMessage, the template for
  /// it.
  final List<TemplatePart>? correctionMessage;

  /// If non-null, the deprecation message for this error code.
  final String? deprecatedMessage;

  /// If present, user-facing documentation for the error.
  final String? documentation;

  /// Indicates whether this error is caused by an unresolved identifier.
  final bool isUnresolvedIdentifier;

  /// The problemMessage for the error code.
  final List<TemplatePart> problemMessage;

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

  /// Map describing the parameters for this diagnostic, obtained from the
  /// `parameters` entry in the yaml file.
  ///
  /// Map keys are parameter names. Map values are [DiagnosticParameter] objects.
  final Map<String, DiagnosticParameter> parameters;

  /// SourceSpan for the YAML value that this [Message] was parsed from.
  ///
  /// This exists to make it easier for automated scripts to edit the YAML
  /// source.
  final SourceSpan valueSpan;

  /// SourceSpan for the YAML key that this [Message] was parsed from.
  ///
  /// This exists to make it easier for automated scripts to edit the YAML
  /// source.
  final SourceSpan keySpan;

  /// The key from the key/value pair that defines the message, expressed as a
  /// [String].
  final String keyString;

  /// Decodes a [Message] object from its YAML representation.
  Message(MessageYaml messageYaml, {bool requireProblemMessage = false})
    : comment = messageYaml.getOptionalString('comment'),
      correctionMessage = messageYaml.getMessageTemplate(
        'correctionMessage',
        isRequired: false,
      ),
      deprecatedMessage = messageYaml.getOptionalString('deprecatedMessage'),
      documentation = messageYaml.getOptionalString('documentation'),
      isUnresolvedIdentifier =
          messageYaml.getOptionalBool('isUnresolvedIdentifier') ?? false,
      problemMessage =
          messageYaml.getMessageTemplate(
            'problemMessage',
            isRequired: requireProblemMessage,
          ) ??
          [],
      sharedName = messageYaml.getOptionalString('sharedName'),
      removedIn = messageYaml.getOptionalString('removedIn'),
      previousName = messageYaml.getOptionalString('previousName'),
      parameters = messageYaml.parameters,
      valueSpan = messageYaml.valueSpan,
      keySpan = messageYaml.keySpan,
      keyString = messageYaml.keyString;

  /// If this diagnostic is no longer reported and
  /// its diagnostic codes should no longer be generated.
  bool get isRemoved => removedIn != null;

  /// A string suitable for identifying the location of this message's key node
  /// in the source YAML file.
  String get location => keySpan.location;

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
      '${sharedNameReference ?? "'${sharedName ?? diagnosticCode}'"},',
    );
    var maxWidth = 80 - 8 /* indentation */ - 2 /* quotes */ - 1 /* comma */;
    var messageAsCode = convertTemplate(problemMessage);
    var messageLines = _splitText(
      messageAsCode,
      maxWidth: maxWidth,
      firstLineWidth: maxWidth + 4,
    );
    constant.writeln('${messageLines.map(_encodeString).join('\n')},');
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
}

/// The raw YAML key/value pair representing a single diagnostic message.
///
/// This class provides methods and getters for validating that the message is
/// well-formed and decoding it.
class MessageYaml {
  /// The YAML key node from the key/value pair that defines the message.
  final YamlScalar _key;

  /// The YAML value node from key/value pair that defines the message. This is
  /// always a [YamlMap].
  final YamlMap _map;

  /// The parameters listed under the `parameters` key, decoded into a map.
  late final Map<String, DiagnosticParameter> parameters = get(
    'parameters',
    decode: _decodeParameters,
  );

  /// The set of keys that the message is permitted to contain.
  ///
  /// Keys are added to this set while the message is being decoded. At the end
  /// of the [decode] method, if there are any keys in [_map] that aren't in
  /// this set, an exception will be thrown to report them as unexpected keys.
  final Set<String> _permittedKeys = {};

  MessageYaml._(this._key, this._map);

  /// The span of the YAML key node from the key/value pair that defines the
  /// message.
  SourceSpan get keySpan => _key.span;

  /// The key from the key/value pair that defines the message, expressed as a
  /// [String].
  String get keyString => _key.value.toString();

  /// The span of the YAML value node from the key/value pair that defines the
  /// message.
  SourceSpan get valueSpan => _map.span;

  /// Adds [extraKeys] to the set of keys that the message is allowed to
  /// contain.
  ///
  /// At the end of the [decode] method, if there are any keys that haven't been
  /// passed to either this method or one of the `get` methods, an exception
  /// will be thrown to report them as unexpected keys.
  void allowExtraKeys(Iterable<String> extraKeys) {
    _permittedKeys.addAll(extraKeys);
  }

  /// Attempts to decode the YAML value associated with [key].
  ///
  /// If an entry is present with the given [key], the corresponding value
  /// [YamlNode] is passed to the [decode] callback for decoding.
  ///
  /// If no entry is present and a non-null value was supplied for the
  /// [ifAbsent] callback, it is invoked to obtain the default value.
  ///
  /// If no entry is present and [ifAbsent] is `null` (the default), an
  /// exception is thrown.
  ///
  /// Any exceptions that occur during execution of the [decode] or [ifAbsent]
  /// callback are converted to [LocatedError] (if necessary), and tagged with
  /// an appropriate location in the source YAML file.
  T get<T>(
    String key, {
    required T Function(YamlNode) decode,
    T Function()? ifAbsent,
  }) {
    _permittedKeys.add(key);
    if (_map.nodes[key] case var node?) {
      return LocatedError.wrap(() => decode(node), span: node.span);
    } else {
      return LocatedError.wrap(
        ifAbsent ?? (() => throw 'Missing key ${json.encode(key)}'),
        span: keySpan,
      );
    }
  }

  /// Attempts to decode the YAML value associated with [key] as a boolean.
  ///
  /// If there is no entry present with the given [key], an exception is thrown.
  bool getBool(String key) => get(key, decode: _decodeBool);

  /// Attempts to decode the YAML value associated with [key] as a message
  /// template.
  ///
  /// If [isRequired] is `true` and there is no entry present with the given
  /// [key], an exception is thrown.
  List<TemplatePart>? getMessageTemplate(
    String key, {
    required bool isRequired,
  }) => get(
    key,
    decode: (node) {
      switch (node) {
        case YamlScalar(:String value):
          // Remove trailing whitespace. This is necessary for templates defined
          // with `|` (verbatim) as they always contain a trailing newline that we
          // don't want.
          var text = value.trimRight();
          if (text.contains(oldPlaceholderPattern)) {
            throw '$key contains an old-style analyzer placeholder pattern. '
                'Please convert to #NAME format.';
          }

          var template = <TemplatePart>[];
          var i = 0;
          for (var match in placeholderPattern.allMatches(text)) {
            var matchStart = match.start;
            if (matchStart > i) {
              template.add(TemplateLiteralPart(text.substring(i, matchStart)));
            }
            template.add(
              TemplateParameterPart.fromMatch(match, parameters: parameters),
            );
            i = match.end;
          }
          if (text.length > i) {
            template.add(TemplateLiteralPart(text.substring(i)));
          }
          return template;
        default:
          throw 'Bad message type: ${node.runtimeType}';
      }
    },
    ifAbsent: isRequired ? null : () => null,
  );

  /// Attempts to decode the YAML value associated with [key] as a boolean.
  ///
  /// If there is no entry present with the given [key], `null` is returned.
  bool? getOptionalBool(String key) =>
      get(key, decode: _decodeBool, ifAbsent: () => null);

  /// Attempts to decode the YAML value associated with [key] as a string.
  ///
  /// If there is no entry present with the given [key], `null` is returned.
  String? getOptionalString(String key) => get(
    key,
    decode: (node) => switch (node) {
      YamlScalar(:String value) => value,
      _ => throw 'Must be a string',
    },
    ifAbsent: () => null,
  );

  /// Decodes a YAML [key]/[value] pair into a diagnostic message by invoking
  /// the given [decoder].
  ///
  /// Any exceptions that occur during execution of the [decoder] are converted
  /// to [LocatedError] (if necessary), and tagged with an appropriate location
  /// in the source YAML file.
  static T decode<T extends Message>({
    required YamlScalar key,
    required YamlMap value,
    required T Function(MessageYaml) decoder,
  }) {
    return LocatedError.wrap(() {
      var messageYaml = MessageYaml._(key, value);
      var result = decoder(messageYaml);
      for (var key in value.nodes.keys) {
        key as YamlScalar;
        if (!messageYaml._permittedKeys.contains(key.value)) {
          throw LocatedError(
            'Unexpected key ${json.encode(key.value)}',
            span: key.span,
          );
        }
      }
      return result;
    }, span: key.span);
  }

  static bool _decodeBool(YamlNode node) => switch (node) {
    YamlScalar(:bool value) => value,
    _ => throw 'Must be a bool',
  };

  static Map<String, DiagnosticParameter> _decodeParameters(YamlNode yaml) {
    switch (yaml) {
      case YamlScalar(value: 'none'):
        return const {};
      case YamlMap(:var nodes):
        var result = <String, DiagnosticParameter>{};
        var index = 0;
        for (var MapEntry(:key, :value) in nodes.entries) {
          var keyNode = key as YamlScalar;
          LocatedError.wrap(span: keyNode.span, () {
            switch ((keyNode.value as String).split(' ')) {
              case [var type, var name]:
                if (result.containsKey(name)) {
                  throw 'Duplicate parameter name: $name';
                }
                result[name] = DiagnosticParameter(
                  name: name,
                  type: DiagnosticParameterType.fromMessagesYamlName(type),
                  comment: value.value as String,
                  index: index++,
                );
              default:
                throw 'Malformed parameter key (should be `TYPE NAME`): '
                    '${json.encode(key.value)}';
            }
          });
        }
        return result;
    }
    throw 'Must be a map or "none".';
  }
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
  String? toCode({
    required String name,
    required DiagnosticParameterType type,
  }) {
    if (type != DiagnosticParameterType.num) {
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

/// In-memory representation of diagnostic information obtained from the file
/// `pkg/_fe_analyzer_shared/messages.yaml`.
class SharedMessage extends CfeStyleMessage with MessageWithAnalyzerCode {
  /// The analyzer diagnostic code that corresponds to this shared diagnostic.
  ///
  /// Shared diagnostics are required to have exactly one analyzer code
  /// associated with them.
  @override
  final AnalyzerCode analyzerCode;

  @override
  final bool hasPublishedDocs;

  SharedMessage(super.messageYaml)
    : analyzerCode = messageYaml.get(
        'analyzerCode',
        decode: _decodeAnalyzerCode,
      ),
      hasPublishedDocs = messageYaml.getBool('hasPublishedDocs');

  static AnalyzerCode _decodeAnalyzerCode(YamlNode node) {
    switch (node) {
      case YamlScalar(value: String s):
        switch (s.split('.')) {
          case [var className, var snakeCaseName]
              when snakeCaseName == snakeCaseName.toUpperCase():
            return AnalyzerCode(
              diagnosticClass: DiagnosticClassInfo.byName(className),
              snakeCaseName: snakeCaseName,
            );
        }
    }
    throw 'Analyzer codes must take the form ClassName.DIAGNOSTIC_NAME.';
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
  String toCode({
    required String name,
    required DiagnosticParameterType type,
  }) => 'conversions.$functionName($name)';
}

/// [TemplatePart] representing a literal string of characters, with no
/// parameter substitutions.
class TemplateLiteralPart implements TemplatePart {
  /// The literal text.
  final String text;

  TemplateLiteralPart(this.text);
}

/// [TemplatePart] representing a parameter to be substituted into the
/// diagnostic message.
class TemplateParameterPart implements TemplatePart {
  /// The parameter to be substituted.
  final DiagnosticParameter parameter;

  /// The conversion to apply to the parameter.
  ///
  /// If `null`, the default conversion for the parameter's type will be used.
  final Conversion? conversionOverride;

  /// Builds a [TemplateParameterPart] from the given [match] of
  /// [placeholderPattern].
  factory TemplateParameterPart.fromMatch(
    Match match, {
    required Map<String, DiagnosticParameter> parameters,
  }) {
    String name = match[1]!;
    var parameter = parameters[name];
    if (parameter == null) {
      throw 'Placeholder ${json.encode(name)} not declared as a parameter';
    }

    return TemplateParameterPart._(
      parameter: parameter,
      conversionOverride: NumericConversion.from(match),
    );
  }

  TemplateParameterPart._({
    required this.parameter,
    required this.conversionOverride,
  });

  @override
  int get hashCode => Object.hash(parameter, conversionOverride);

  @override
  bool operator ==(Object other) =>
      other is TemplateParameterPart &&
      other.parameter == parameter &&
      other.conversionOverride == conversionOverride;
}

/// A part of a parsed template string.
///
/// Each `problemMessage` and `correctionMessage` template string in a
/// `messages.yaml` file is decoded into a list of [TemplatePart].
sealed class TemplatePart {}

class _DuplicateChecker<Code> {
  final Map<Code, List<Message>> _codeToMessages = {};
  final String kind;

  _DuplicateChecker({required this.kind});

  void operator []=(Code code, Message message) {
    (_codeToMessages[code] ??= []).add(message);
  }

  void check() {
    for (var MapEntry(key: code, value: messages) in _codeToMessages.entries) {
      if (messages.length != 1) {
        throw [
          '$kind $code used for multiple diagnostics:',
          for (var message in messages)
            '${message.location}: ${message.keyString}',
        ].join('\n');
      }
    }
  }
}

extension SourceSpanLocation on SourceSpan {
  /// A string suitable for identifying this span in the source YAML file.
  String get location {
    var path = start.sourceUrl?.toFilePath() ?? '<unknown>';
    // Convert line/column to 1-based because that's what most editors expect
    var line = start.line + 1;
    var column = start.column + 1;
    return '$path:$line:$column';
  }
}
