// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:analyzer/src/fasta/error_converter.dart';
library;

import 'dart:convert';
import 'dart:io';

import 'package:analyzer_testing/package_root.dart' as pkg_root;
import 'package:analyzer_testing/utilities/extensions/string.dart';
import 'package:analyzer_utilities/analyzer_messages.dart';
import 'package:analyzer_utilities/lint_messages.dart';
import 'package:analyzer_utilities/located_error.dart';
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
  ...analysisServerMessages,
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
  final DiagnosticCodeName frontEndCode;

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
      frontEndCode = switch (messageYaml.keyString) {
        var s when s.isCamelCase => DiagnosticCodeName.fromCamelCase(
          messageYaml.keyString,
        ),
        _ => throw LocatedError(
          'Front end codes must be camelCase',
          span: messageYaml.keySpan,
        ),
      },
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

/// A diagnostic code name used by either the analyzer or the front end.
///
/// This class implements [operator==] and [hashCode] so it can be used as a map
/// key or in a set.
///
/// This class implements [Comparable], so lists of it can be safely
/// [List.sort]ed.
class DiagnosticCodeName implements Comparable<DiagnosticCodeName> {
  /// Exceptions to the usual rules for converting diagnostic code names from
  /// camel case to snake case.
  ///
  /// Normally, diagnostic code names are converted from camel case to snake
  /// case using [StringExtension.toSnakeCase]. But in rare situations when the
  /// name contains numbers, this can produce results that aren't ideal. Rather
  /// than try to fix these rare situations in a general fashion, it's easier to
  /// just have an explicit map of the problematic names, with their preferred
  /// snake case forms.
  static const Map<String, String> _snakeCaseExceptions = {
    'finalNotInitializedConstructor1': 'final_not_initialized_constructor_1',
    'finalNotInitializedConstructor2': 'final_not_initialized_constructor_2',
    'finalNotInitializedConstructor3Plus':
        'final_not_initialized_constructor_3_plus',
    'linesLongerThan80Chars': 'lines_longer_than_80_chars',
  };

  /// The diagnostic name, as a "lower snake case" name (lower case words
  /// separated by underscores).
  final String snakeCaseName;

  /// The diagnostic name, as a "camel case" name (lower case word followed by
  /// capitalized words, with no separation between words).
  final String camelCaseName;

  DiagnosticCodeName.fromCamelCase(this.camelCaseName)
    : snakeCaseName =
          _snakeCaseExceptions[camelCaseName] ?? camelCaseName.toSnakeCase() {
    if (snakeCaseName.toLowerCase() != snakeCaseName) {
      throw 'Snake case name ${json.encode(snakeCaseName)} is not all lower '
          'case';
    }
    if (snakeCaseName.toCamelCase() != camelCaseName) {
      throw 'Round-trip conversion from ${json.encode(camelCaseName)} to snake '
          'case and back produces ${json.encode(snakeCaseName.toCamelCase())}';
    }
  }

  /// The string that should be generated into analyzer source code to refer to
  /// this diagnostic code.
  String get analyzerCodeReference => ['diag', camelCaseName].join('.');

  @override
  int get hashCode => snakeCaseName.hashCode;

  /// The diagnostic name, converted to PascalCase.
  String get pascalCaseName => snakeCaseName.toPascalCase();

  @override
  bool operator ==(Object other) =>
      other is DiagnosticCodeName && snakeCaseName == other.snakeCaseName;

  @override
  int compareTo(DiagnosticCodeName other) {
    return snakeCaseName.compareTo(other.snakeCaseName);
  }

  @override
  String toString() => snakeCaseName;
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
  /// automatically generated, sorted by [DiagnosticCodeName.camelCaseName].
  final List<SharedMessage> sortedSharedDiagnostics = [];

  /// List of front end diagnostics, sorted by front end code.
  final List<CfeStyleMessage> sortedFrontEndDiagnostics = [];

  /// Map from [AnalyzerDiagnosticPackage] to the list of active diagnostic
  /// messages for that package.
  ///
  /// A message is considered active is [MessageWithAnalyzerCode.isRemoved] is
  /// `false` and the message is not an [AliasMessage].
  ///
  /// Each list is sorted by [DiagnosticCodeName.camelCaseName].
  final Map<AnalyzerDiagnosticPackage, List<MessageWithAnalyzerCode>>
  activeMessagesByPackage = {};

  final Map<String, MessageWithAnalyzerCode> diagnosticsByAnalyzerUniqueName =
      {};

  /// Map from [DiagnosticCodeName.pascalCaseName] to front end diagnostic.
  final Map<String, CfeStyleMessage> frontEndDiagnosticsByPascalCaseName = {};

  DiagnosticTables._(List<Message> messages) {
    var frontEndCodeDuplicateChecker = _DuplicateChecker<DiagnosticCodeName>(
      kind: 'Front end code',
    );
    var analyzerCodeDuplicateChecker = _DuplicateChecker<DiagnosticCodeName>(
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
        frontEndDiagnosticsByPascalCaseName[frontEndCode.pascalCaseName] =
            message;
      }
      if (message is SharedMessage) {
        sortedSharedDiagnostics.add(message);
      }
      if (message is MessageWithAnalyzerCode) {
        var analyzerCode = message.analyzerCode;
        analyzerCodeDuplicateChecker[analyzerCode] = message;
        analyzerCodeCamelCaseNameDuplicateChecker[analyzerCode.camelCaseName] =
            message;
        (analyzerSharedNameToMessages[(message.sharedName ?? analyzerCode)
                    .snakeCaseName] ??=
                [])
            .add(message);
        diagnosticsByAnalyzerUniqueName[analyzerCode.snakeCaseName] = message;
        var package = message.package;
        var type = message.type;
        if (!package.permittedTypes.contains(type)) {
          throw LocatedError(
            'Diagnostic type is ${type.name}, which may not be used in '
            'package:${package.dirName}',
            span: message.keySpan,
          );
        }
        if (!message.isRemoved && message is! AliasMessage) {
          (activeMessagesByPackage[package] ??= []).add(message);
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
      value.sortBy((e) => e.analyzerCode.camelCaseName);
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
  final DiagnosticCodeName? sharedName;

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
      sharedName = messageYaml.get(
        'sharedName',
        decode: (s) => switch (s) {
          YamlScalar(:String value) =>
            value.isCamelCase
                ? DiagnosticCodeName.fromCamelCase(value)
                : throw 'Shared names should be camelCase',
          _ => throw 'Must be a string',
        },
        ifAbsent: () => null,
      ),
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
  final DiagnosticCodeName analyzerCode;

  @override
  final bool hasPublishedDocs;

  @override
  final AnalyzerDiagnosticType type;

  SharedMessage(super.messageYaml)
    : analyzerCode = messageYaml.get(
        'analyzerCode',
        decode: _decodeAnalyzerCode,
      ),
      hasPublishedDocs = messageYaml.getBool('hasPublishedDocs'),
      type = messageYaml.get(
        'type',
        decode: MessageWithAnalyzerCode.decodeType,
      );

  @override
  AnalyzerDiagnosticPackage get package => AnalyzerDiagnosticPackage.analyzer;

  static DiagnosticCodeName _decodeAnalyzerCode(YamlNode node) {
    switch (node) {
      case YamlScalar(value: String s):
        switch (s.split('.')) {
          case [var camelCaseName] when camelCaseName.isCamelCase:
            return DiagnosticCodeName.fromCamelCase(camelCaseName);
        }
    }
    throw 'Analyzer codes must be camelCase names.';
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
