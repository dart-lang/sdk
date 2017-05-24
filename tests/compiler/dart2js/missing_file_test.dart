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
  'bar.dart': '''
import 'dart:foo';
main() {}
''',
  'baz.dart': '''
import 'dart:io';
main() {}
''',
};

Future runTest(Uri main, {MessageKind error, MessageKind info}) async {
  print("----\nentry-point: $main\n");

  DiagnosticCollector diagnostics = new DiagnosticCollector();
  OutputCollector output = new OutputCollector();
  await runCompiler(
      entryPoint: main,
      memorySourceFiles: MEMORY_SOURCE_FILES,
      diagnosticHandler: diagnostics,
      outputProvider: output);

  Expect.isFalse(output.hasExtraOutput);
  Expect.equals(error != null ? 1 : 0, diagnostics.errors.length);
  if (error != null) {
    Expect.equals(error, diagnostics.errors.first.message.kind);
  }
  Expect.equals(info != null ? 1 : 0, diagnostics.infos.length);
  if (info != null) {
    Expect.equals(info, diagnostics.infos.first.message.kind);
  }
  Expect.equals(0, diagnostics.warnings.length);
  Expect.equals(0, diagnostics.hints.length);
}

void main() {
  asyncTest(() async {
    await runTest(Uri.parse('memory:main.dart'),
        error: MessageKind.READ_URI_ERROR);

    await runTest(Uri.parse('memory:foo.dart'),
        error: MessageKind.READ_SELF_ERROR);

    await runTest(Uri.parse('dart:foo'), error: MessageKind.LIBRARY_NOT_FOUND);

    await runTest(Uri.parse('dart:_mirror_helper'),
        error: MessageKind.INTERNAL_LIBRARY,
        info: MessageKind.DISALLOWED_LIBRARY_IMPORT);

    await runTest(Uri.parse('memory:bar.dart'),
        error: MessageKind.LIBRARY_NOT_FOUND);

    // Importing dart:io is temporarily allowed as a stopgap measure for the
    // lack of config specific imports. Once that is added, this will be
    // disallowed again.

    //await runTest(Uri.parse('dart:io'),
    //    error: MessageKind.LIBRARY_NOT_SUPPORTED,
    //    info: MessageKind.DISALLOWED_LIBRARY_IMPORT);

    //await runTest(Uri.parse('memory:baz.dart'),
    //    error: MessageKind.LIBRARY_NOT_SUPPORTED,
    //    info: MessageKind.DISALLOWED_LIBRARY_IMPORT);
  });
}
