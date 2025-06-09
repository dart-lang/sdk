// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart';
import 'package:analyzer/src/generated/java_core.dart';

/// A diagnostic, as defined by the [Diagnostic Design Guidelines][guidelines]:
///
/// > An indication of a specific problem at a specific location within the
/// > source code being processed by a development tool.
///
/// Clients may not extend, implement or mix-in this class.
///
/// [guidelines]: https://github.com/dart-lang/sdk/blob/main/pkg/analyzer/doc/implementation/diagnostics.md
class Diagnostic {
  /// The diagnostic code associated with the diagnostic.
  final DiagnosticCode diagnosticCode;

  /// A list of messages that provide context for understanding the problem
  /// being reported. The list will be empty if there are no such messages.
  final List<DiagnosticMessage> contextMessages;

  /// Data associated with this diagnostic, specific for [diagnosticCode].
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
    required DiagnosticCode errorCode,
    required String message,
    this.correctionMessage,
    this.contextMessages = const [],
    this.data,
  }) : diagnosticCode = errorCode,
       problemMessage = DiagnosticMessageImpl(
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
    // TODO(srawlins): Rename to `diagnosticCode`.
    required DiagnosticCode errorCode,
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

    return Diagnostic.forValues(
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
        throw StateError('Invalid severity: ${diagnosticCode.severity}');
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

/// A single message associated with a [Diagnostic], consisting of the text of
/// the message and the location associated with it.
///
/// Clients may not extend, implement or mix-in this class.
abstract class DiagnosticMessage {
  /// The absolute and normalized path of the file associated with this message.
  String get filePath;

  /// The length of the source range associated with this message.
  int get length;

  /// The zero-based offset from the start of the file to the beginning of the
  /// source range associated with this message.
  int get offset;

  /// The URL associated with this diagnostic message, if any.
  String? get url;

  /// Gets the text of the message.
  ///
  /// If [includeUrl] is `true`, and this diagnostic message has an associated
  /// URL, it is included in the returned value in a human-readable way.
  /// Clients that wish to present URLs as simple text can do this.  If
  /// [includeUrl] is `false`, no URL is included in the returned value.
  /// Clients that have a special mechanism for presenting URLs (e.g. as a
  /// clickable link) should do this and then consult the [url] getter to access
  /// the URL.
  String messageText({required bool includeUrl});
}

/// An indication of the severity of a [Diagnostic].
enum Severity { error, warning, info }
