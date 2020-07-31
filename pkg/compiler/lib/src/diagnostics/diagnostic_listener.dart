// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.diagnostic_listener;

import '../elements/entities.dart';
import '../options.dart' show DiagnosticOptions;
import 'messages.dart';
import 'source_span.dart' show SourceSpan;
import 'spannable.dart' show Spannable;

// TODO(johnniwinther): Rename and cleanup this interface. Add severity enum.
abstract class DiagnosticReporter {
  DiagnosticOptions get options;

  // TODO(karlklose): rename log to something like reportInfo.
  void log(message);

  internalError(Spannable spannable, message);

  /// Creates a [SourceSpan] for [node] in scope of the current element.
  ///
  /// If [node] is a [Node] we assert in checked mode that the corresponding
  /// tokens can be found within the tokens of the current element.
  SourceSpan spanFromSpannable(Spannable node);

  void reportErrorMessage(Spannable spannable, MessageKind messageKind,
      [Map<String, String> arguments = const {}]) {
    reportError(createMessage(spannable, messageKind, arguments));
  }

  void reportError(DiagnosticMessage message,
      [List<DiagnosticMessage> infos = const <DiagnosticMessage>[]]);

  void reportWarningMessage(Spannable spannable, MessageKind messageKind,
      [Map<String, String> arguments = const {}]) {
    reportWarning(createMessage(spannable, messageKind, arguments));
  }

  void reportWarning(DiagnosticMessage message,
      [List<DiagnosticMessage> infos = const <DiagnosticMessage>[]]);

  void reportHintMessage(Spannable spannable, MessageKind messageKind,
      [Map<String, String> arguments = const {}]) {
    reportHint(createMessage(spannable, messageKind, arguments));
  }

  void reportHint(DiagnosticMessage message,
      [List<DiagnosticMessage> infos = const <DiagnosticMessage>[]]);

  @deprecated
  void reportInfo(Spannable node, MessageKind errorCode,
      [Map<String, String> arguments = const {}]);

  /// Set current element of this reporter to [element]. This is used for
  /// creating [SourceSpan] in [spanFromSpannable].
  withCurrentElement(Entity element, f());

  DiagnosticMessage createMessage(Spannable spannable, MessageKind messageKind,
      [Map<String, String> arguments = const {}]);

  /// Returns `true` if a crash, an error or a fatal warning has been reported.
  bool get hasReportedError;

  /// Called when an [exception] is thrown from user-provided code, like from
  /// the input provider or diagnostics handler.
  void onCrashInUserCode(String message, exception, stackTrace) {}
}

class DiagnosticMessage {
  final SourceSpan sourceSpan;
  final Spannable spannable;
  final Message message;

  DiagnosticMessage(this.sourceSpan, this.spannable, this.message);
}
