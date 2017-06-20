// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.diagnostic_reporter.helper;

import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/diagnostics/messages.dart';
import 'package:compiler/src/diagnostics/source_span.dart';
import 'package:compiler/src/diagnostics/spannable.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:front_end/src/fasta/scanner.dart';
import 'options_helper.dart';

abstract class DiagnosticReporterWrapper extends DiagnosticReporter {
  DiagnosticReporter get reporter;

  @override
  DiagnosticMessage createMessage(Spannable spannable, MessageKind messageKind,
      [Map arguments = const {}]) {
    return reporter.createMessage(spannable, messageKind, arguments);
  }

  @override
  internalError(Spannable spannable, message) {
    return reporter.internalError(spannable, message);
  }

  @override
  void log(message) {
    return reporter.log(message);
  }

  @override
  DiagnosticOptions get options => reporter.options;

  @override
  void reportError(DiagnosticMessage message,
      [List<DiagnosticMessage> infos = const <DiagnosticMessage>[]]) {
    reporter.reportError(message, infos);
  }

  @override
  void reportHint(DiagnosticMessage message,
      [List<DiagnosticMessage> infos = const <DiagnosticMessage>[]]) {
    reporter.reportHint(message, infos);
  }

  @override
  void reportInfo(Spannable node, MessageKind errorCode,
      [Map arguments = const {}]) {
    reporter.reportInfo(node, errorCode, arguments);
  }

  @override
  void reportWarning(DiagnosticMessage message,
      [List<DiagnosticMessage> infos = const <DiagnosticMessage>[]]) {
    reporter.reportWarning(message, infos);
  }

  @override
  SourceSpan spanFromSpannable(Spannable node) {
    return reporter.spanFromSpannable(node);
  }

  @override
  SourceSpan spanFromToken(Token token) => reporter.spanFromToken(token);

  @override
  withCurrentElement(Entity element, f()) {
    return reporter.withCurrentElement(element, f);
  }

  @override
  bool get hasReportedError => reporter.hasReportedError;
}
