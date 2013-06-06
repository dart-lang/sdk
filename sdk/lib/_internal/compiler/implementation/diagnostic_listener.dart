// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js;

abstract class DiagnosticListener {
  // TODO(karlklose): replace cancel with better error reporting mechanism.
  void cancel(String reason, {node, token, instruction, element});
  // TODO(karlklose): rename log to something like reportInfo.
  void log(message);
  // TODO(karlklose): add reportWarning and reportError to this interface.

  void internalErrorOnElement(Element element, String message);
  void internalError(String message,
                     {Node node, Token token, HInstruction instruction,
                      Element element});

  SourceSpan spanFromSpannable(Spannable node, [Uri uri]);

  void reportMessage(SourceSpan span, Diagnostic message, api.Diagnostic kind);

  // TODO(ahe): Rename to reportError when that method has been removed.
  void reportErrorCode(Spannable node, MessageKind errorCode, [Map arguments]);

  void reportInfo(Spannable node, MessageKind errorCode, [Map arguments]);

  /// Returns true if a diagnostic was emitted.
  bool onDeprecatedFeature(Spannable span, String feature);

  // TODO(ahe): We should not expose this here.  Perhaps a
  // [SourceSpan] should implement [Spannable], and we should have a
  // way to construct a [SourceSpan] from a [Spannable] and an
  // [Element].
  withCurrentElement(Element element, f());
}
