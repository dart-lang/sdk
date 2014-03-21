// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js;

abstract class DiagnosticListener {
  // TODO(karlklose): rename log to something like reportInfo.
  void log(message);

  void internalError(Spannable spannable, message);

  SourceSpan spanFromSpannable(Spannable node);

  /// Reports an error and terminates computation immediately.
  void reportFatalError(Spannable node, MessageKind errorCode,
                        [Map arguments = const {}]);

  void reportError(Spannable node, MessageKind errorCode,
                   [Map arguments = const {}]);

  void reportWarning(Spannable node, MessageKind errorCode,
                     [Map arguments = const {}]);

  void reportHint(Spannable node, MessageKind errorCode,
                  [Map arguments = const {}]);

  void reportInfo(Spannable node, MessageKind errorCode,
                  [Map arguments = const {}]);

  // TODO(ahe): We should not expose this here.  Perhaps a
  // [SourceSpan] should implement [Spannable], and we should have a
  // way to construct a [SourceSpan] from a [Spannable] and an
  // [Element].
  withCurrentElement(Element element, f());
}
