// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Error that happened during executing a macro builder.
class MacroExecutionError {
  final int annotationIndex;
  final String macroName;
  final String message;

  MacroExecutionError({
    required this.annotationIndex,
    required this.macroName,
    required this.message,
  });
}
