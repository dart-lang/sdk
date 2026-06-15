// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../worker_harness.dart';

void main() {
  testDartWorkspace('ws.compile() hello world', (ws) async {
    await ws.writeFileFromText(
      'bin/main.dart',
      "void main() => print('Hello World');",
    );

    check(await ws.compile(Uri.parse('bin/main.dart')))
      ..log.isEmpty()
      ..codeContains('Hello World')
      ..codeContains('main');
  });

  testDartWorkspace('ws.compile() missing semicolon', (ws) async {
    await ws.writeFileFromText(
      'bin/main.dart',
      "void main() => print('Hello World')",
    );

    await check(
      ws.compile(Uri.parse('bin/main.dart')),
    ).throws<CompilationFailedException>(
      (e) => e.message.contains("Expected ';'"),
    );
  });

  testDartWorkspace('ws.compile() with imports', (ws) async {
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

    check(await ws.compile(Uri.parse('bin/main.dart')))
      ..log.isEmpty()
      ..codeContains('Hello World')
      ..codeContains('main');
  });
}
