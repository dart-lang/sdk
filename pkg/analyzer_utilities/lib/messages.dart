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
import 'package:yaml/yaml.dart'
    show YamlMap, YamlScalar, YamlNode, loadYamlNode;

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
final Map<String, SharedMessage> feAnalyzerSharedMessages =
    _loadCfeStyleMessages(
      feAnalyzerSharedPkgPath,
      decodeMessage: SharedMessage.fromYaml,
    );

/// The path to the `fe_analyzer_shared` package.
final String feAnalyzerSharedPkgPath = normalize(
  join(pkg_root.packageRoot, '_fe_analyzer_shared'),
);

/// Decoded messages from the `messages.yaml` files in the front end and
/// `_fe_analyzer_shared`.
final Map<String, CfeStyleMessage> frontEndAndSharedMessages = Map.from(
  frontEndMessages,
)..addAll(feAnalyzerSharedMessages);

/// Decoded messages from the front end's `messages.yaml` file.
final Map<String, FrontEndMessage> frontEndMessages = _loadCfeStyleMessages(
  frontEndPkgPath,
  decodeMessage: FrontEndMessage.fromYaml,
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

/// A set of tables mapping between shared and analyzer diagnostics.
final SharedToAnalyzerDiagnosticTables sharedToAnalyzerDiagnosticTables =
    SharedToAnalyzerDiagnosticTables._(feAnalyzerSharedMessages);

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

/// Decodes a YAML object (in CFE style `messages.yaml` format) into a map from
/// diagnostic name to [Message].
Map<String, T> decodeCfeStyleMessagesYaml<T extends CfeStyleMessage>(
  YamlNode yaml, {
  required T Function(YamlMap, {required YamlScalar keyNode}) decodeMessage,
  required String path,
}) {
  var result = <String, T>{};
  if (yaml is! YamlMap) {
    throw LocatedError('root node is not a map', node: yaml);
  }
  for (var entry in yaml.nodes.entries) {
    var keyNode = entry.key as YamlScalar;
    var diagnosticName = keyNode.value;
    if (diagnosticName is! String) {
      throw LocatedError(
        'non-string diagnostic key ${json.encode(diagnosticName)}',
        node: keyNode,
      );
    }
    var diagnosticValue = entry.value;
    if (diagnosticValue is! YamlMap) {
      throw LocatedError(
        'value associated with diagnostic $diagnosticName is not a map',
        node: diagnosticValue,
      );
    }
    result[diagnosticName] = LocatedError.wrap(
      node: diagnosticValue,
      () => decodeMessage(diagnosticValue, keyNode: keyNode),
    );
  }
  return result;
}

/// Loads messages in CFE style `messages.yaml` format.
Map<String, T> _loadCfeStyleMessages<T extends CfeStyleMessage>(
  String packagePath, {
  required T Function(YamlMap, {required YamlScalar keyNode}) decodeMessage,
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

  CfeStyleMessage.fromYaml(YamlMap yaml, {required super.keyNode})
    : cfeSeverity = _decodeSeverity(yaml.nodes['severity']),
      super.fromYaml(yaml) {
    if (yaml['problemMessage'] == null) {
      throw LocatedError('Missing problemMessage', node: yaml);
    }
  }

  static String? _decodeSeverity(YamlNode? node) {
    switch (node) {
      case null:
        return null;
      case YamlScalar(:var value):
        return severityEnumNames[value] ??
            (throw LocatedError("Unknown severity '$value'", node: node));
      default:
        throw LocatedError(
          'Bad severity type: ${node.runtimeType}',
          node: node,
        );
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

  FrontEndMessage.fromYaml(YamlMap yaml, {required super.keyNode})
    : pseudoSharedCode = yaml['pseudoSharedCode'] as String?,
      super.fromYaml(yaml) {
    if (yaml.nodes['analyzerCode'] case var node?) {
      throw LocatedError(
        'Only shared messages can have an analyzer code',
        node: node,
      );
    }
  }
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

  /// If `true` (the default), diagnostic codes of this class will be included
  /// in the automatically-generated `diagnosticCodeValues` list.
  final bool includeInDiagnosticCodeValues;

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
    this.includeInDiagnosticCodeValues = true,
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

/// An error with an associated YAML source location.
class LocatedError {
  final YamlNode node;
  final String message;

  LocatedError(this.message, {required this.node});

  @override
  String toString() => '${node.location}: $message';

  /// Executes [callback], converting any exceptions it generates to a
  /// [LocatedError] that points to [node].
  static T wrap<T>(T Function() callback, {required YamlNode node}) {
    try {
      return callback();
    } catch (error, stackTrace) {
      if (error is! LocatedError) {
        Error.throwWithStackTrace(
          LocatedError(error.toString(), node: node),
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

  /// Whether diagnostics with this code have documentation for them that has
  /// been published.
  ///
  /// `null` if the YAML doesn't contain this information.
  final bool? hasPublishedDocs;

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

  /// The raw YAML node that this [Message] was parsed from.
  ///
  /// This exists to make it easier for automated scripts to edit the YAML
  /// source.
  final YamlMap yamlNode;

  /// The raw YAML key for the key/value pair that this `ErrorCodeInfo` was
  /// parsed from.
  ///
  /// This exists to make it easier for automated scripts to edit the YAML
  /// source.
  final YamlScalar keyNode;

  Message({
    this.comment,
    this.documentation,
    this.hasPublishedDocs,
    this.isUnresolvedIdentifier = false,
    this.sharedName,
    required YamlNode? problemMessageYaml,
    required YamlNode? correctionMessageYaml,
    this.deprecatedMessage,
    this.previousName,
    this.removedIn,
    required this.parameters,
    required this.yamlNode,
    required this.keyNode,
  }) : problemMessage =
           _decodeMessage(
             problemMessageYaml,
             parameters: parameters,
             kind: 'problemMessage',
           ) ??
           [],
       correctionMessage = _decodeMessage(
         correctionMessageYaml,
         parameters: parameters,
         kind: 'correctionMessage',
       );

  /// Decodes an [Message] object from its YAML representation.
  Message.fromYaml(YamlMap yaml, {required YamlScalar keyNode})
    : this(
        comment: yaml['comment'] as String?,
        correctionMessageYaml: yaml.nodes['correctionMessage'],
        deprecatedMessage: yaml['deprecatedMessage'] as String?,
        documentation: yaml['documentation'] as String?,
        hasPublishedDocs: yaml['hasPublishedDocs'] as bool?,
        isUnresolvedIdentifier:
            yaml['isUnresolvedIdentifier'] as bool? ?? false,
        problemMessageYaml: yaml.nodes['problemMessage'],
        sharedName: yaml['sharedName'] as String?,
        removedIn: yaml['removedIn'] as String?,
        previousName: yaml['previousName'] as String?,
        parameters: _decodeParameters(yaml.nodes['parameters']),
        yamlNode: yaml,
        keyNode: keyNode,
      );

  /// If this diagnostic is no longer reported and
  /// its diagnostic codes should no longer be generated.
  bool get isRemoved => removedIn != null;

  /// A string suitable for identifying the location of this message's key node
  /// in the source YAML file.
  String get location => keyNode.location;

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
    GeneratedDiagnosticClassInfo diagnosticClassInfo,
    String diagnosticCode, {
    String? sharedNameReference,
    required MemberAccumulator memberAccumulator,
  }) {
    var correctionMessage = this.correctionMessage;
    var parameters = this.parameters;
    var usesParameters = [problemMessage, correctionMessage].any(
      (value) =>
          value != null && value.any((part) => part is TemplateParameterPart),
    );
    var constantName = diagnosticCode.toCamelCase();
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
      var pascalCaseName = diagnosticCode.toPascalCase();
      withArgumentsName = '_withArguments$pascalCaseName';
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

  static List<TemplatePart>? _decodeMessage(
    YamlNode? node, {
    required Map<String, DiagnosticParameter> parameters,
    required String kind,
  }) {
    switch (node) {
      case null:
        return null;
      case YamlScalar(:String value):
        // Remove trailing whitespace. This is necessary for templates defined
        // with `|` (verbatim) as they always contain a trailing newline that we
        // don't want.
        var text = value.trimRight();
        if (text.contains(oldPlaceholderPattern)) {
          throw LocatedError(
            '$kind is ${json.encode(text)}, which contains an old-style '
            'analyzer placeholder pattern. Please convert to #NAME format.',
            node: node,
          );
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
        throw LocatedError('Bad message type: ${node.runtimeType}', node: node);
    }
  }

  static Map<String, DiagnosticParameter> _decodeParameters(YamlNode? yaml) {
    if (yaml == null) {
      throw 'Missing parameters section';
    }
    if (yaml case YamlScalar(value: 'none')) return const {};
    yaml as YamlMap;
    var result = <String, DiagnosticParameter>{};
    var index = 0;
    for (var MapEntry(:key, :value) in yaml.nodes.entries) {
      var keyNode = key as YamlScalar;
      LocatedError.wrap(node: keyNode, () {
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
                '${json.encode(key)}';
        }
      });
    }
    return result;
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
class SharedMessage extends CfeStyleMessage {
  /// The analyzer diagnostic code that corresponds to this shared diagnostic.
  ///
  /// Shared diagnostics are required to have exactly one analyzer code
  /// associated with them.
  final AnalyzerCode analyzerCode;

  SharedMessage.fromYaml(super.yaml, {required super.keyNode})
    : analyzerCode = _decodeAnalyzerCode(
        (yaml['analyzerCode'] ??
                (throw LocatedError(
                  'Shared diagnostics must specify an analyzerCode.',
                  node: yaml,
                )))
            as String,
      ),
      super.fromYaml();

  static AnalyzerCode _decodeAnalyzerCode(String s) {
    switch (s.split('.')) {
      case [var className, var snakeCaseName]
          when snakeCaseName == snakeCaseName.toUpperCase():
        return AnalyzerCode(
          diagnosticClass: DiagnosticClassInfo.byName(className),
          snakeCaseName: snakeCaseName,
        );
      default:
        throw 'Analyzer codes must take the form ClassName.DIAGNOSTIC_NAME. '
            'Found ${json.encode(s)} instead.';
    }
  }
}

/// Data tables mapping between shared diagnostics and their corresponding
/// automatically generated analyzer diagnostics.
class SharedToAnalyzerDiagnosticTables {
  /// Map whose values are the shared diagnostics for which analyzer diagnostics
  /// should be automatically generated, and whose keys are the corresponding
  /// analyzer code.
  final Map<AnalyzerCode, SharedMessage> analyzerCodeToMessage = {};

  /// List of shared diagnostics for which analyzer diagnostics should be
  /// automatically generated, sorted by analyzer code.
  final List<SharedMessage> sortedSharedDiagnostics = [];

  SharedToAnalyzerDiagnosticTables._(Map<String, SharedMessage> messages) {
    var infoToFrontEndCode = <SharedMessage, String>{};
    var analyzerCodeToMessages = <AnalyzerCode, List<SharedMessage>>{};
    for (var entry in messages.entries) {
      var message = entry.value;
      var frontEndCode = entry.key;
      sortedSharedDiagnostics.add(message);
      infoToFrontEndCode[message] = frontEndCode;
      var analyzerCode = message.analyzerCode;
      (analyzerCodeToMessages[analyzerCode] ??= []).add(message);
    }

    for (var MapEntry(key: analyzerCode, value: messages)
        in analyzerCodeToMessages.entries) {
      switch (messages) {
        case [var message]:
          analyzerCodeToMessage[analyzerCode] = message;
        default:
          throw [
            'Analyzer code $analyzerCode used for multiple diagnostics:',
            for (var message in messages)
              '${message.location}: ${message.keyNode}',
          ].join('\n');
      }
    }

    sortedSharedDiagnostics.sortBy((e) => e.analyzerCode.camelCaseName);
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

extension YamlNodeLocation on YamlNode {
  /// A string suitable for identifying the location of this node in the source
  /// YAML file.
  String get location {
    var start = span.start;
    var path = start.sourceUrl?.toFilePath() ?? '<unknown>';
    // Convert line/column to 1-based because that's what most editors expect
    var line = start.line + 1;
    var column = start.column + 1;
    return '$path:$line:$column';
  }
}
