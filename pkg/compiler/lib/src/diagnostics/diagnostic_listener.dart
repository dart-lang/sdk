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

  /// List of packages for which warnings and hints are reported. If `null`,
  /// no package warnings or hints are reported. If empty, all warnings and
  /// hints are reported.
  final List<String> _shownPackageWarnings;

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
    List<String> shownPackageWarnings: null})
      : _shownPackageWarnings = shownPackageWarnings;


  /// Returns `true` if warnings and hints are shown for all packages.
  bool get showAllPackageWarnings {
    return _shownPackageWarnings != null && _shownPackageWarnings.isEmpty;
  }

  /// Returns `true` if warnings and hints are hidden for all packages.
  bool get hidePackageWarnings => _shownPackageWarnings == null;

  /// Returns `true` if warnings should be should for [uri].
  bool showPackageWarningsFor(Uri uri) {
    if (showAllPackageWarnings) {
      return true;
    }
    if (_shownPackageWarnings != null) {
      return uri.scheme == 'package' &&
          _shownPackageWarnings.contains(uri.pathSegments.first);
    }
    return false;
  }
}

// TODO(johnniwinther): Rename and cleanup this interface. Add severity enum.
abstract class DiagnosticReporter {
  DiagnosticOptions get options => const DiagnosticOptions();

  // TODO(karlklose): rename log to something like reportInfo.
  void log(message);

  internalError(Spannable spannable, message);

  /// Creates a [SourceSpan] for [node] in scope of the current element.
  ///
  /// If [node] is a [Node] or [Token] we assert in checked mode that the
  /// corresponding tokens can be found within the tokens of the current
  /// element.
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

  /// Set current element of this reporter to [element]. This is used for
  /// creating [SourceSpan] in [spanFromSpannable].
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