// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class DiagnosticListener {
  // TODO(karlklose): replace cancel with better error reporting mechanism.
  void cancel([String reason, node, token, instruction, element]);
  // TODO(karlklose): rename log to something like reportInfo.
  void log(message);
  // TODO(karlklose): add reportWarning and reportError to this interface.

  void internalErrorOnElement(Element element, String message);
  void internalError(String message,
                     [Node node, Token token, HInstruction instruction,
                      Element element]);
}
