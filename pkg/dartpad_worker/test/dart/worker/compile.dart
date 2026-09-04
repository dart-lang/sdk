// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../worker_harness.dart';

void main() {
  testDartWorkspace('sandbox.runMain() hello world', (ws) async {
    await ws.writeFileFromText(
      'bin/main.dart',
      "void main() => print('Hello World');",
    );

    final iframe = FakeSandboxedIframe();
    final sandbox = await ws.connectSandboxedIframe(iframe.port);

    final result = await sandbox.runMain('bin/main.dart');
    check(result.log).isEmpty();

    await iframe.checkEvent(
      (it) => it.isA<LoadModuleEvent>().code
        ..contains('Hello World')
        ..contains('main'),
    );
    await iframe.checkEvent((it) => it.isA<RunMainEvent>());
    await iframe.close();
  });

  testDartWorkspace('sandbox.runMain() missing semicolon', (ws) async {
    await ws.writeFileFromText(
      'bin/main.dart',
      "void main() => print('Hello World')",
    );

    final iframe = FakeSandboxedIframe();
    final sandbox = await ws.connectSandboxedIframe(iframe.port);

    await check(
      sandbox.runMain('bin/main.dart'),
    ).throws<CompilationFailedException>(
      (it) => it.has((e) => e.message, 'message').contains("Expected ';'"),
    );

    await iframe.close();
  });

  testDartWorkspace('sandbox.runMain() with imports', (ws) async {
    await ws.writeFileFromText('lib/sayhello.dart', '''
      void sayHello() => print('Hello World');
    ''');

    await ws.writeFileFromText('bin/main.dart', '''
      import 'dart:async';
      import 'package:myapp/sayhello.dart';

      void main() {
        sayHello();
      }
    ''');

    final iframe = FakeSandboxedIframe();
    final sandbox = await ws.connectSandboxedIframe(iframe.port);

    final result = await sandbox.runMain('bin/main.dart');
    check(result.log).isEmpty();

    await iframe.checkEvent(
      (it) => it.isA<LoadModuleEvent>().code
        ..contains('Hello World')
        ..contains('main'),
    );
    await iframe.checkEvent((it) => it.isA<RunMainEvent>());
    await iframe.close();
  });
}
