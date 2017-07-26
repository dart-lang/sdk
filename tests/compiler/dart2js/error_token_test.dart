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

Future runTest(String code,
    {MessageKind error, int expectedWarningCount: 0}) async {
  DiagnosticCollector diagnostics = new DiagnosticCollector();
  OutputCollector output = new OutputCollector();
  await runCompiler(
      entryPoint: Uri.parse('memory:main.dart'),
      memorySourceFiles: {'main.dart': code},
      diagnosticHandler: diagnostics,
      outputProvider: output);

  Expect.equals(error != null ? 1 : 0, diagnostics.errors.length);
  if (error != null)
    Expect.equals(error, diagnostics.errors.first.message.kind);
  Expect.equals(expectedWarningCount, diagnostics.warnings.length);
  Expect.equals(0, diagnostics.hints.length);
  Expect.equals(0, diagnostics.infos.length);
}

void main() {
  asyncTest(() async {
    await runTest(
        '''
main() {Foo.bar();}
class Foo {
	static void bar() {
		baz());
	}
}
''',
        error: MessageKind.MISSING_TOKEN_AFTER_THIS,
        expectedWarningCount: 1);

    await runTest(
        '''
main() {new C(v);}
class C {
  C(v) {
    throw '');
  }
}''',
        error: MessageKind.MISSING_TOKEN_AFTER_THIS,
        expectedWarningCount: 1);
  });
}
