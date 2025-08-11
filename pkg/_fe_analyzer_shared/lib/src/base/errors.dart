// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:_fe_analyzer_shared/src/base/analyzer_public_api.dart';

import 'customized_codes.dart';

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
