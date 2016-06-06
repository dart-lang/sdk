// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that we don't report invalid modifier on error tokens.

library dart2js.test.error_token;

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import "package:compiler/src/diagnostics/messages.dart";
import 'package:expect/expect.dart';
import 'memory_compiler.dart';

Future runTest(String code, {MessageKind error}) async {
  DiagnosticCollector diagnostics = new DiagnosticCollector();
  OutputCollector output = new OutputCollector();
  await runCompiler(
      entryPoint: Uri.parse('memory:main.dart'),
      memorySourceFiles: {'main.dart': code},
      diagnosticHandler: diagnostics,
      outputProvider: output);

  Expect.equals(error != null ? 1 : 0, diagnostics.errors.length);
  if (error != null) {
    Expect.equals(error, diagnostics.errors.first.message.kind);
  }
  Expect.equals(0, diagnostics.warnings.length);
  Expect.equals(0, diagnostics.hints.length);
  Expect.equals(0, diagnostics.infos.length);
}

void main() {
  asyncTest(() async {
    await runTest('''
main() {}
class Foo {
	static void bar() {
		baz());
	}
}
''', error: MessageKind.UNMATCHED_TOKEN);

    await runTest('''
main() {}
class C {
  C(v) {
    throw '');
  }
}''', error: MessageKind.UNMATCHED_TOKEN);
  });
}
