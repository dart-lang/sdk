// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the compiler can handle imports when package root has not been set.

library dart2js.test.missing_file;

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/dart2jslib.dart';
import 'package:expect/expect.dart';
import 'memory_compiler.dart';

const MEMORY_SOURCE_FILES = const {
  'main.dart': '''

import 'foo.dart';

main() {}
''',
};

Future runCompiler(Uri main, String expectedMessage) {
  print("\n\n\n");

  DiagnosticCollector diagnostics = new DiagnosticCollector();
  OutputCollector output = new OutputCollector();
  Compiler compiler = compilerFor(
      MEMORY_SOURCE_FILES,
      diagnosticHandler: diagnostics,
      outputProvider: output);

  return compiler.run(main).then((_) {
    Expect.isFalse(output.hasExtraOutput);
    Expect.equals(1, diagnostics.errors.length);
    Expect.equals(expectedMessage, diagnostics.errors.first.message);
  });
}

void main() {
  asyncTest(() => Future.forEach([
  () => runCompiler(
      Uri.parse('memory:main.dart'),
      "Can't read 'memory:foo.dart' "
      "(Exception: No such file memory:foo.dart)."),
  () => runCompiler(
      Uri.parse('memory:foo.dart'),
      "Exception: No such file memory:foo.dart"),
  () => runCompiler(
      Uri.parse('dart:foo'),
      "Library not found 'dart:foo'."),
  ], (f) => f()));
}
