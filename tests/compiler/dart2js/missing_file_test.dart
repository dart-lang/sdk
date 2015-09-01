// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the compiler can handle imports when package root has not been set.

library dart2js.test.missing_file;

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import "package:compiler/src/diagnostics/messages.dart";
import 'package:expect/expect.dart';
import 'memory_compiler.dart';

const MEMORY_SOURCE_FILES = const {
  'main.dart': '''

import 'foo.dart';

main() {}
''',
};

Future runTest(Uri main, MessageKind expectedMessageKind) async {
  print("\n\n\n");

  DiagnosticCollector diagnostics = new DiagnosticCollector();
  OutputCollector output = new OutputCollector();
  await runCompiler(
      memorySourceFiles: MEMORY_SOURCE_FILES,
      diagnosticHandler: diagnostics,
      outputProvider: output);

  Expect.isFalse(output.hasExtraOutput);
  Expect.equals(1, diagnostics.errors.length);
  Expect.equals(expectedMessageKind, diagnostics.errors.first.message.kind);
}

void main() {
  asyncTest(() async {
    await runTest(
        Uri.parse('memory:main.dart'), MessageKind.READ_SCRIPT_ERROR);
    await runTest(
        Uri.parse('memory:foo.dart'), MessageKind.READ_SCRIPT_ERROR);
    await runTest(
        Uri.parse('dart:foo'), MessageKind.READ_SCRIPT_ERROR);
  });
}
