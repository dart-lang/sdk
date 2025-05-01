// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:_fe_analyzer_shared/src/base/errors.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart';
import 'package:analyzer/src/error/error_code_values.g.dart';
import 'package:analyzer/src/generated/java_core.dart';

export 'package:_fe_analyzer_shared/src/base/errors.dart'
    show
        DiagnosticCode,
        DiagnosticSeverity,
        DiagnosticType,
        ErrorCode,
        ErrorSeverity,
        // Continue exporting the deleted element until it is removed.
        // ignore: deprecated_member_use
        ErrorType;
export 'package:analyzer/src/dart/error/lint_codes.dart' show LintCode;
export 'package:analyzer/src/error/error_code_values.g.dart';

/// The lazy initialized map from [ErrorCode.uniqueName] to the [ErrorCode]
/// instance.
final HashMap<String, ErrorCode> _uniqueNameToCodeMap =
    _computeUniqueNameToCodeMap();

/// Return the [ErrorCode] with the given [uniqueName], or `null` if not
/// found.
ErrorCode? errorCodeByUniqueName(String uniqueName) {
  return _uniqueNameToCodeMap[uniqueName];
}

/// Return the map from [ErrorCode.uniqueName] to the [ErrorCode] instance
/// for all [errorCodeValues].
HashMap<String, ErrorCode> _computeUniqueNameToCodeMap() {
  var result = HashMap<String, ErrorCode>();
  for (ErrorCode errorCode in errorCodeValues) {
    var uniqueName = errorCode.uniqueName;
    assert(() {
      if (result.containsKey(uniqueName)) {
        throw StateError('Not unique: $uniqueName');
      }
      return true;
    }());
    result[uniqueName] = errorCode;
  }
  return result;
}

/// An error discovered during the analysis of some Dart code.
///
/// See `AnalysisErrorListener`.
class AnalysisError implements Diagnostic {
  /// The error code associated with the error.
  final ErrorCode errorCode;

  @override
  final DiagnosticMessage problemMessage;

  @override
  final List<DiagnosticMessage> contextMessages;

  /// Data associated with this error, specific for [errorCode].
  final Object? data;

  @override
  final String? correctionMessage;

  /// The source in which the error occurred, or `null` if unknown.
  final Source source;

  /// Initialize a newly created analysis error with given values.
  AnalysisError.forValues({
    required this.source,
    required int offset,
    required int length,
    required this.errorCode,
    required String message,
    this.correctionMessage,
    this.contextMessages = const [],
    this.data,
  }) : problemMessage = DiagnosticMessageImpl(
         filePath: source.fullName,
         length: length,
         message: message,
         offset: offset,
         url: null,
       );

  /// Initialize a newly created analysis error. The error is associated with
  /// the given [source] and is located at the given [offset] with the given
  /// [length]. The error will have the given [errorCode] and the list of
  /// [arguments] will be used to complete the message and correction. If any
  /// [contextMessages] are provided, they will be recorded with the error.
  factory AnalysisError.tmp({
    required Source source,
    required int offset,
    required int length,
    required ErrorCode errorCode,
    List<Object?> arguments = const [],
    List<DiagnosticMessage> contextMessages = const [],
    Object? data,
  }) {
    assert(
      arguments.length == errorCode.numParameters,
      'Message $errorCode requires ${errorCode.numParameters} '
      'argument${errorCode.numParameters == 1 ? '' : 's'}, but '
      '${arguments.length} '
      'argument${arguments.length == 1 ? ' was' : 's were'} '
      'provided',
    );
    String message = formatList(errorCode.problemMessage, arguments);
    String? correctionTemplate = errorCode.correctionMessage;
    String? correctionMessage;
    if (correctionTemplate != null) {
      correctionMessage = formatList(correctionTemplate, arguments);
    }

    return AnalysisError.forValues(
      source: source,
      offset: offset,
      length: length,
      errorCode: errorCode,
      message: message,
      correctionMessage: correctionMessage,
      contextMessages: contextMessages,
      data: data,
    );
  }

  /// The template used to create the correction to be displayed for this error,
  /// or `null` if there is no correction information for this error. The
  /// correction should indicate how the user can fix the error.
  @Deprecated("Use 'correctionMessage' instead.")
  String? get correction => correctionMessage;

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

  /// Return the message to be displayed for this error. The message should
  /// indicate what is wrong and why it is wrong.
  String get message => problemMessage.messageText(includeUrl: true);

  /// The character offset from the beginning of the source (zero based) where
  /// the error occurred.
  int get offset => problemMessage.offset;

  @override
  Severity get severity {
    switch (errorCode.errorSeverity) {
      case ErrorSeverity.ERROR:
        return Severity.error;
      case ErrorSeverity.WARNING:
        return Severity.warning;
      case ErrorSeverity.INFO:
        return Severity.info;
      default:
        throw StateError('Invalid error severity: ${errorCode.errorSeverity}');
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    // prepare other AnalysisError
    if (other is AnalysisError) {
      // Quick checks.
      if (!identical(errorCode, other.errorCode)) {
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
      // OK
      return true;
    }
    return false;
  }

  @override
  String toString() {
    StringBuffer buffer = StringBuffer();
    buffer.write(source.fullName);
    buffer.write("(");
    buffer.write(offset);
    buffer.write("..");
    buffer.write(offset + length - 1);
    buffer.write("): ");
    //buffer.write("(" + lineNumber + ":" + columnNumber + "): ");
    buffer.write(message);
    return buffer.toString();
  }
}
