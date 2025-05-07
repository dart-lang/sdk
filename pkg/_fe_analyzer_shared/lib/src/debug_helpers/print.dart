// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Whether [_debugPrint] is printing to stdout.UnsupportedError
///
/// Change this to `false` during development/debugging to temporarily disable
/// the debug printing without having to remove calls to [debugPrint],
/// [debugPrintStart], [debugPrintEnd] and [inDebugPrint].
const bool _debugPrintEnabled = true;

/// The current indentation level used in [_debugPrint].
int _indentLevel = 0;

/// Prints the `toString()` of [value] to stdout.
///
/// This supports automatic indentation when used with [debugPrintEnd],
/// [debugPrintStart] and [inDebugPrint].
void debugPrint(Object value) {
  _debugPrint(value);
}

/// Decreases the indentation level used by [debugPrint] and prints the
/// `toString()` of [value] using [debugPrint].
void debugPrintEnd(Object value) {
  _indentLevel--;
  _debugPrint(value);
}

/// Prints the `toString()` of [value] using [debugPrint] and increases the
/// indentation level used by [debugPrint].
void debugPrintStart(Object value) {
  _debugPrint(value);
  _indentLevel++;
}

/// Wraps the call to [f] with a start and end message containing the
/// `toString()` of [value], increasing the indentation level during the call
/// to [f].
///
/// This can be used for easily printing call stacks for debugging.
void inDebugPrint(Object value, void Function() f) {
  debugPrintStart('start:$value');
  try {
    f();
  } finally {
    debugPrintEnd('end  :$value');
  }
}

/// Prints the `toString()` of [value] at the current [_indentLevel] if
/// [_debugPrintEnabled] is `true`.
void _debugPrint(Object value) {
  if (_debugPrintEnabled) {
    print('${'  ' * _indentLevel}${value}');
  }
}
