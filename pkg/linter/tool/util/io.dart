// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

/// A shared sink for standard error reporting.
StringSink errorSink = stderr;

/// A shared sink for standard out reporting.
StringSink outSink = stdout;

/// Write the given [object] to the console.
/// Uses the shared [outSink] for redirecting in tests.
void printToConsole(Object? object) {
  outSink.writeln(object);
}
