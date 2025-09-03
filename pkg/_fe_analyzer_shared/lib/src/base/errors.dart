// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:analyzer/error/listener.dart';
library;

import 'dart:math';

import 'package:_fe_analyzer_shared/src/base/analyzer_public_api.dart';
import 'package:_fe_analyzer_shared/src/base/diagnostic_message.dart';
import 'package:_fe_analyzer_shared/src/base/source.dart';
import 'package:_fe_analyzer_shared/src/base/syntactic_entity.dart';

import 'customized_codes.dart';

/// Inserts the given [arguments] into [pattern].
///
///     format('Hello, {0}!', ['John']) = 'Hello, John!'
///     format('{0} are you {1}ing?', ['How', 'do']) = 'How are you doing?'
///     format('{0} are you {1}ing?', ['What', 'read']) =
///         'What are you reading?'
String formatList(String pattern, List<Object?>? arguments) {
  if (arguments == null || arguments.isEmpty) {
    assert(
      !pattern.contains(new RegExp(r'\{(\d+)\}')),
      'Message requires arguments, but none were provided.',
    );
    return pattern;
  }
  return pattern.replaceAllMapped(new RegExp(r'\{(\d+)\}'), (match) {
    String indexStr = match.group(1)!;
    int index = int.parse(indexStr);
    return arguments[index].toString();
  });
}

/// A diagnostic code associated with an `AnalysisError`.
///
/// Generally, messages should follow the [Guide for Writing
/// Diagnostics](https://github.com/dart-lang/sdk/blob/main/pkg/front_end/lib/src/base/diagnostics.md).
@AnalyzerPublicApi(message: 'exported by package:analyzer/error/error.dart')
@Deprecated("Use 'DiagnosticCode' instead.")
typedef ErrorCode = DiagnosticCode;

/// The severity of a [DiagnosticCode].
@AnalyzerPublicApi(message: 'exported by package:analyzer/error/error.dart')
@Deprecated("Use 'DiagnosticSeverity' instead.")
typedef ErrorSeverity = DiagnosticSeverity;

@AnalyzerPublicApi(message: 'exported by package:analyzer/error/error.dart')
@Deprecated("Use 'DiagnosticType' instead.")
typedef ErrorType = DiagnosticType;

/// A diagnostic, as defined by the [Diagnostic Design Guidelines][guidelines]:
///
/// > An indication of a specific problem at a specific location within the
/// > source code being processed by a development tool.
///
/// Clients may not extend, implement or mix-in this class.
///
/// [guidelines]: https://github.com/dart-lang/sdk/blob/main/pkg/analyzer/doc/implementation/diagnostics.md
@AnalyzerPublicApi(
  message: 'Exported by package:analyzer/diagnostic/diagnostic.dart',
)
class Diagnostic {
  /// The diagnostic code associated with the diagnostic.
  final DiagnosticCode diagnosticCode;

  /// A list of messages that provide context for understanding the problem
  /// being reported. The list will be empty if there are no such messages.
  final List<DiagnosticMessage> contextMessages;

  /// Data associated with this diagnostic, specific for [diagnosticCode].
  @Deprecated('Use an expando instead')
  final Object? data;

  /// A description of how to fix the problem, or `null` if there is no such
  /// description.
  final String? correctionMessage;

  /// A message describing what is wrong and why.
  final DiagnosticMessage problemMessage;

  /// The source in which the diagnostic occurred, or `null` if unknown.
  final Source source;

  Diagnostic.forValues({
    required this.source,
    required int offset,
    required int length,
    DiagnosticCode? diagnosticCode,
    @Deprecated("Pass a value for 'diagnosticCode' instead")
    DiagnosticCode? errorCode,
    required String message,
    this.correctionMessage,
    this.contextMessages = const [],
    @Deprecated('Use an expando instead') this.data,
  }) : diagnosticCode = _useNonNullCodeBetween(diagnosticCode, errorCode),
       problemMessage = new DiagnosticMessageImpl(
         filePath: source.fullName,
         length: length,
         message: message,
         offset: offset,
         url: null,
       );

  /// Initialize a newly created diagnostic.
  ///
  /// The diagnostic is associated with the given [source] and is located at the
  /// given [offset] with the given [length]. The diagnostic will have the given
  /// [errorCode] and the list of [arguments] will be used to complete the
  /// message and correction. If any [contextMessages] are provided, they will
  /// be recorded with the diagnostic.
  factory Diagnostic.tmp({
    required Source source,
    required int offset,
    required int length,
    DiagnosticCode? diagnosticCode,
    @Deprecated("Pass a value for 'diagnosticCode' instead")
    DiagnosticCode? errorCode,
    List<Object?> arguments = const [],
    List<DiagnosticMessage> contextMessages = const [],
    @Deprecated('Use an expando instead') Object? data,
  }) {
    DiagnosticCode code = _useNonNullCodeBetween(diagnosticCode, errorCode);
    assert(
      arguments.length == code.numParameters,
      'Message $code requires ${code.numParameters} '
      'argument${code.numParameters == 1 ? '' : 's'}, but '
      '${arguments.length} '
      'argument${arguments.length == 1 ? ' was' : 's were'} '
      'provided',
    );
    String message = formatList(code.problemMessage, arguments);
    String? correctionTemplate = code.correctionMessage;
    String? correctionMessage;
    if (correctionTemplate != null) {
      correctionMessage = formatList(correctionTemplate, arguments);
    }

    return new Diagnostic.forValues(
      source: source,
      offset: offset,
      length: length,
      diagnosticCode: code,
      message: message,
      correctionMessage: correctionMessage,
      contextMessages: contextMessages,
      // ignore: deprecated_member_use_from_same_package
      data: data,
    );
  }

  /// The template used to create the correction to be displayed for this
  /// diagnostic, or `null` if there is no correction information for this
  /// error. The correction should indicate how the user can fix the error.
  @Deprecated("Use 'correctionMessage' instead.")
  String? get correction => correctionMessage;

  @Deprecated("Use 'diagnosticCode' instead")
  DiagnosticCode get errorCode => diagnosticCode;

  @override
  int get hashCode {
    int hashCode = offset;
    hashCode ^= message.hashCode;
    hashCode ^= source.hashCode;
    return hashCode;
  }

  /// The number of characters from the offset to the end of the source which
  /// encompasses the compilation error.
  int get length => problemMessage.length;

  /// The message to be displayed for this diagnostic.
  ///
  /// The message indicates what is wrong and why it is wrong.
  String get message => problemMessage.messageText(includeUrl: true);

  /// The character offset from the beginning of the source (zero based) where
  /// the diagnostic occurred.
  int get offset => problemMessage.offset;

  Severity get severity {
    switch (diagnosticCode.severity) {
      case DiagnosticSeverity.ERROR:
        return Severity.error;
      case DiagnosticSeverity.WARNING:
        return Severity.warning;
      case DiagnosticSeverity.INFO:
        return Severity.info;
      default:
        throw new StateError('Invalid severity: ${diagnosticCode.severity}');
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    // prepare the other Diagnostic.
    if (other is Diagnostic) {
      // Quick checks.
      if (!identical(diagnosticCode, other.diagnosticCode)) {
        return false;
      }
      if (offset != other.offset || length != other.length) {
        return false;
      }
      // Deep checks.
      if (message != other.message) {
        return false;
      }
      if (source != other.source) {
        return false;
      }
      return true;
    }
    return false;
  }

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    buffer.write(source.fullName);
    buffer.write("(");
    buffer.write(offset);
    buffer.write("..");
    buffer.write(offset + length - 1);
    buffer.write("): ");
    buffer.write(message);
    return buffer.toString();
  }

  /// The non-`null` [DiagnosticCode] value between the two parameters.
  static DiagnosticCode _useNonNullCodeBetween(
    DiagnosticCode? diagnosticCode,
    DiagnosticCode? errorCode,
  ) {
    if ((diagnosticCode == null) == (errorCode == null)) {
      throw new ArgumentError(
        "Exactly one of 'diagnosticCode' and 'errorCode' may be passed",
      );
    }
    return diagnosticCode ?? errorCode!;
  }
}

/// Private subtype of [DiagnosticCode] that supports runtime checking of
/// parameter types.
abstract class DiagnosticCodeWithExpectedTypes extends DiagnosticCode {
  final List<ExpectedType>? expectedTypes;

  const DiagnosticCodeWithExpectedTypes({
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    required super.name,
    required super.problemMessage,
    required super.uniqueName,
    this.expectedTypes,
  });
}

/// An error code associated with an `AnalysisError`.
///
/// Generally, messages should follow the [Guide for Writing
/// Diagnostics](https://github.com/dart-lang/sdk/blob/main/pkg/front_end/lib/src/base/diagnostics.md).
@AnalyzerPublicApi(message: 'exported by package:analyzer/error/error.dart')
abstract class DiagnosticCode {
  /// Regular expression for identifying positional arguments in error messages.
  static final RegExp _positionalArgumentRegExp = new RegExp(r'\{(\d+)\}');

  /**
   * The name of the error code.
   */
  final String name;

  /**
   * The unique name of this error code.
   */
  final String uniqueName;

  final String _problemMessage;

  final String? _correctionMessage;

  /**
   * Return `true` if diagnostics with this code have documentation for them
   * that has been published.
   */
  final bool hasPublishedDocs;

  /**
   * Whether this error is caused by an unresolved identifier.
   */
  final bool isUnresolvedIdentifier;

  /**
   * Initialize a newly created error code to have the given [name]. The message
   * associated with the error will be created from the given [problemMessage]
   * template. The correction associated with the error will be created from the
   * given [correctionMessage] template.
   */
  const DiagnosticCode({
    String? correctionMessage,
    this.hasPublishedDocs = false,
    this.isUnresolvedIdentifier = false,
    required this.name,
    required String problemMessage,
    required this.uniqueName,
  }) : _correctionMessage = correctionMessage,
       _problemMessage = problemMessage;

  /**
   * The template used to create the correction to be displayed for this
   * diagnostic, or `null` if there is no correction information for this
   * diagnostic. The correction should indicate how the user can fix the
   * diagnostic.
   */
  String? get correctionMessage =>
      customizedCorrections[uniqueName] ?? _correctionMessage;

  @Deprecated("Use 'diagnosticSeverity' instead")
  DiagnosticSeverity get errorSeverity => severity;

  /// Whether a finding of this diagnostic is ignorable via comments such as
  /// `// ignore:` or `// ignore_for_file:`.
  bool get isIgnorable => severity != DiagnosticSeverity.ERROR;

  int get numParameters {
    int result = 0;
    String? correctionMessage = _correctionMessage;
    for (String s in [
      _problemMessage,
      if (correctionMessage != null) correctionMessage,
    ]) {
      for (RegExpMatch match in _positionalArgumentRegExp.allMatches(s)) {
        result = max(result, int.parse(match.group(1)!) + 1);
      }
    }
    return result;
  }

  /**
   * The template used to create the problem message to be displayed for this
   * diagnostic. The problem message should indicate what is wrong and why it is
   * wrong.
   */
  String get problemMessage =>
      customizedMessages[uniqueName] ?? _problemMessage;

  /**
   * The severity of the diagnostic.
   */
  DiagnosticSeverity get severity;

  /**
   * The type of the error.
   */
  DiagnosticType get type;

  /**
   * Return a URL that can be used to access documentation for diagnostics with
   * this code, or `null` if there is no published documentation.
   */
  String? get url {
    if (hasPublishedDocs) {
      return 'https://dart.dev/diagnostics/${name.toLowerCase()}';
    }
    return null;
  }

  @override
  String toString() => uniqueName;
}

/**
 * The severity of an [DiagnosticCode].
 */
@AnalyzerPublicApi(message: 'exported by package:analyzer/error/error.dart')
class DiagnosticSeverity implements Comparable<DiagnosticSeverity> {
  /**
   * The severity representing a non-error. This is never used for any error
   * code, but is useful for clients.
   */
  static const DiagnosticSeverity NONE = const DiagnosticSeverity(
    'NONE',
    0,
    " ",
    "none",
  );

  /**
   * The severity representing an informational level analysis issue.
   */
  static const DiagnosticSeverity INFO = const DiagnosticSeverity(
    'INFO',
    1,
    "I",
    "info",
  );

  /**
   * The severity representing a warning. Warnings can become errors if the
   * `-Werror` command line flag is specified.
   */
  static const DiagnosticSeverity WARNING = const DiagnosticSeverity(
    'WARNING',
    2,
    "W",
    "warning",
  );

  /**
   * The severity representing an error.
   */
  static const DiagnosticSeverity ERROR = const DiagnosticSeverity(
    'ERROR',
    3,
    "E",
    "error",
  );

  static const List<DiagnosticSeverity> values = const [
    NONE,
    INFO,
    WARNING,
    ERROR,
  ];

  final String name;

  final int ordinal;

  /**
   * The name of the severity used when producing machine output.
   */
  final String machineCode;

  /**
   * The name of the severity used when producing readable output.
   */
  final String displayName;

  const DiagnosticSeverity(
    this.name,
    this.ordinal,
    this.machineCode,
    this.displayName,
  );

  @override
  int get hashCode => ordinal;

  @override
  int compareTo(DiagnosticSeverity other) => ordinal - other.ordinal;

  /**
   * Return the severity constant that represents the greatest severity.
   */
  DiagnosticSeverity max(DiagnosticSeverity severity) =>
      this.ordinal >= severity.ordinal ? this : severity;

  @override
  String toString() => name;
}

/**
 * The type of a [DiagnosticCode].
 */
@AnalyzerPublicApi(message: 'exported by package:analyzer/error/error.dart')
class DiagnosticType implements Comparable<DiagnosticType> {
  /**
   * Task (todo) comments in user code.
   */
  static const DiagnosticType TODO = const DiagnosticType(
    'TODO',
    0,
    DiagnosticSeverity.INFO,
  );

  /**
   * Extra analysis run over the code to follow best practices, which are not in
   * the Dart Language Specification.
   */
  static const DiagnosticType HINT = const DiagnosticType(
    'HINT',
    1,
    DiagnosticSeverity.INFO,
  );

  /**
   * Compile-time errors are errors that preclude execution. A compile time
   * error must be reported by a Dart compiler before the erroneous code is
   * executed.
   */
  static const DiagnosticType COMPILE_TIME_ERROR = const DiagnosticType(
    'COMPILE_TIME_ERROR',
    2,
    DiagnosticSeverity.ERROR,
  );

  /**
   * Checked mode compile-time errors are errors that preclude execution in
   * checked mode.
   */
  static const DiagnosticType CHECKED_MODE_COMPILE_TIME_ERROR =
      const DiagnosticType(
        'CHECKED_MODE_COMPILE_TIME_ERROR',
        3,
        DiagnosticSeverity.ERROR,
      );

  /**
   * Static warnings are those warnings reported by the static checker. They
   * have no effect on execution. Static warnings must be provided by Dart
   * compilers used during development.
   */
  static const DiagnosticType STATIC_WARNING = const DiagnosticType(
    'STATIC_WARNING',
    4,
    DiagnosticSeverity.WARNING,
  );

  /**
   * Syntactic errors are errors produced as a result of input that does not
   * conform to the grammar.
   */
  static const DiagnosticType SYNTACTIC_ERROR = const DiagnosticType(
    'SYNTACTIC_ERROR',
    6,
    DiagnosticSeverity.ERROR,
  );

  /**
   * Lint warnings describe style and best practice recommendations that can be
   * used to formalize a project's style guidelines.
   */
  static const DiagnosticType LINT = const DiagnosticType(
    'LINT',
    7,
    DiagnosticSeverity.INFO,
  );

  static const List<DiagnosticType> values = const [
    TODO,
    HINT,
    COMPILE_TIME_ERROR,
    CHECKED_MODE_COMPILE_TIME_ERROR,
    STATIC_WARNING,
    SYNTACTIC_ERROR,
    LINT,
  ];

  /**
   * The name of this error type.
   */
  final String name;

  /**
   * The ordinal value of the error type.
   */
  final int ordinal;

  /**
   * The severity of this type of error.
   */
  final DiagnosticSeverity severity;

  /**
   * Initialize a newly created error type to have the given [name] and
   * [severity].
   */
  const DiagnosticType(this.name, this.ordinal, this.severity);

  String get displayName => name.toLowerCase().replaceAll('_', ' ');

  @override
  int get hashCode => ordinal;

  @override
  int compareTo(DiagnosticType other) => ordinal - other.ordinal;

  @override
  String toString() => name;
}

/// Common functionality for [DiagnosticCode]-derived classes that represent
/// errors that do not take arguments.
///
/// This class implements [LocatableDiagnostic], which means that instances can
/// be associated with a location in the source code using the [at] method, and
/// then the result can be passed to [DiagnosticReporter.reportError].
base mixin DiagnosticWithoutArguments on DiagnosticCode
    implements LocatableDiagnostic {
  @override
  List<Object> get arguments => const [];

  @override
  DiagnosticCode get code => this;

  @override
  Iterable<DiagnosticMessage> get contextMessages => const [];

  @override
  LocatedDiagnostic at(SyntacticEntity node) =>
      atOffset(offset: node.offset, length: node.length);

  @override
  LocatedDiagnostic atOffset({required int offset, required int length}) =>
      new LocatedDiagnostic(this, offset, length);

  @override
  LocatableDiagnostic withContextMessages(List<DiagnosticMessage> messages) =>
      new LocatableDiagnosticImpl(code, arguments, contextMessages: messages);
}

/// Expected type of a diagnostic code's parameter.
enum ExpectedType { element, int, name, object, string, token, type, uri }

/// Interface for a diagnostic that does not have any unfilled template
/// parameters, and hence is ready to be associated with a location in the
/// source code.
///
/// This could either be the result of calling `withArguments` on a diagnostic
/// code that requires arguments, or it could be a diagnostic code that doesn't
/// require arguments.
abstract final class LocatableDiagnostic {
  /// The arguments that were applied to the diagnostic, or the empty list if
  /// [code] doesn't accept any arguments.
  List<Object> get arguments;

  /// The [DiagnosticCode] associated with the diagnostic.
  DiagnosticCode get code;

  /// The context messages that were applied to the diagnostic.
  Iterable<DiagnosticMessage> get contextMessages;

  /// Converts this diagnostic to a [LocatedDiagnostic] by applying it to a
  /// syntactic entity in the source code.
  ///
  /// The result may be passed to [DiagnosticReporter.reportError].
  LocatedDiagnostic at(SyntacticEntity node);

  /// Converts this diagnostic to a [LocatedDiagnostic] by applying it to a
  /// location in the source code.
  ///
  /// The result may be passed to [DiagnosticReporter.reportError].
  LocatedDiagnostic atOffset({required int offset, required int length});

  /// Attaches context messages to this diagnostic.
  ///
  /// The return value is a fresh instance of [LocatableDiagnostic]. This allows
  /// for a literate style of error reporting, e.g.:
  /// ```dart
  /// // For an diagnostic code that doesn't take arguments:
  /// diagnosticReporter.reportError(
  ///   diagnosticCode.withContextMessages(messages).at(astNode));
  ///
  /// // For a diagnostic code that does take arguments:
  /// diagnosticReporter.reportError(
  ///   diagnosticCode
  ///     .withArguments(...)
  ///     .withContextMessages(messages)
  ///     .at(astNode));
  /// ```
  LocatableDiagnostic withContextMessages(List<DiagnosticMessage> messages);
}

/// Concrete implementation of [LocatableDiagnostic].
final class LocatableDiagnosticImpl implements LocatableDiagnostic {
  @override
  final DiagnosticCode code;

  @override
  final List<Object> arguments;

  @override
  final Iterable<DiagnosticMessage> contextMessages;

  LocatableDiagnosticImpl(
    this.code,
    this.arguments, {
    this.contextMessages = const [],
  });

  @override
  LocatedDiagnostic at(SyntacticEntity node) =>
      atOffset(offset: node.offset, length: node.length);

  @override
  LocatedDiagnostic atOffset({required int offset, required int length}) =>
      new LocatedDiagnostic(this, offset, length);

  @override
  LocatableDiagnostic withContextMessages(List<DiagnosticMessage> messages) =>
      new LocatableDiagnosticImpl(
        code,
        arguments,
        contextMessages: [...contextMessages, ...messages],
      );
}

/// A diagnostic that does not have any unfilled template parameters, and has
/// been associated with a location in the source code.
final class LocatedDiagnostic {
  final LocatableDiagnostic locatableDiagnostic;
  final int offset;
  final int length;

  LocatedDiagnostic(this.locatableDiagnostic, this.offset, this.length);
}
