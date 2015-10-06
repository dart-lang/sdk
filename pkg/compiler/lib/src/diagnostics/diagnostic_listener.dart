// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.diagnostic_listener;

import 'source_span.dart' show
    SourceSpan;
import 'spannable.dart' show
    Spannable;
import '../elements/elements.dart' show
    Element;
import 'messages.dart';

class DiagnosticOptions {

  /// Emit terse diagnostics without howToFix.
  final bool terseDiagnostics;

  /// If `true`, warnings and hints not from user code are reported.
  final bool showPackageWarnings;

  /// If `true`, warnings are not reported.
  final bool suppressWarnings;

  /// If `true`, warnings cause the compilation to fail.
  final bool fatalWarnings;

  /// If `true`, hints are not reported.
  final bool suppressHints;

  const DiagnosticOptions({
    this.suppressWarnings: false,
    this.fatalWarnings: false,
    this.suppressHints: false,
    this.terseDiagnostics: false,
    this.showPackageWarnings: false});
}

// TODO(johnniwinther): Rename and cleanup this interface. Add severity enum.
abstract class DiagnosticReporter {
  DiagnosticOptions get options => const DiagnosticOptions();

  // TODO(karlklose): rename log to something like reportInfo.
  void log(message);

  internalError(Spannable spannable, message);

  SourceSpan spanFromSpannable(Spannable node);

  void reportErrorMessage(
      Spannable spannable,
      MessageKind messageKind,
      [Map arguments = const {}]) {
    reportError(createMessage(spannable, messageKind, arguments));
  }

  void reportError(
      DiagnosticMessage message,
      [List<DiagnosticMessage> infos = const <DiagnosticMessage>[]]);

  void reportWarningMessage(
      Spannable spannable,
      MessageKind messageKind,
      [Map arguments = const {}]) {
    reportWarning(createMessage(spannable, messageKind, arguments));
  }

  void reportWarning(
      DiagnosticMessage message,
      [List<DiagnosticMessage> infos = const <DiagnosticMessage>[]]);

  void reportHintMessage(
      Spannable spannable,
      MessageKind messageKind,
      [Map arguments = const {}]) {
    reportHint(createMessage(spannable, messageKind, arguments));
  }

  void reportHint(
      DiagnosticMessage message,
      [List<DiagnosticMessage> infos = const <DiagnosticMessage>[]]);


  @deprecated
  void reportInfo(Spannable node, MessageKind errorCode,
                  [Map arguments = const {}]);

  // TODO(ahe): We should not expose this here.  Perhaps a
  // [SourceSpan] should implement [Spannable], and we should have a
  // way to construct a [SourceSpan] from a [Spannable] and an
  // [Element].
  withCurrentElement(Element element, f());

  DiagnosticMessage createMessage(
      Spannable spannable,
      MessageKind messageKind,
      [Map arguments = const {}]);
}

class DiagnosticMessage {
  final SourceSpan sourceSpan;
  final Spannable spannable;
  final Message message;

  DiagnosticMessage(this.sourceSpan, this.spannable, this.message);
}