// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../worker_harness.dart';

void main() {
  testFlutterWorkspace('ws.compile() flutter hello world', (ws) async {
    await ws.writeFileFromText('bin/main.dart', '''
      import 'package:flutter/material.dart';

      void main() => runApp(
        const MaterialApp(home: Center(child: Text('Hello Flutter'))),
      );
    ''');

    check(await ws.compile(Uri.parse('bin/main.dart')))
      ..log.isEmpty()
      ..codeContains('Hello Flutter')
      ..codeContains('MaterialApp');
  });

  testFlutterWorkspace('ws.compile() missing semicolon', (ws) async {
    await ws.writeFileFromText('bin/main.dart', '''
      import 'package:flutter/material.dart';

      void main() => runApp(
        const MaterialApp(home: Center(child: Text('Hello Flutter'))),
      )
    ''');

    await check(
      ws.compile(Uri.parse('bin/main.dart')),
    ).throws<CompilationFailedException>(
      (e) => e.message.contains("Expected ';'"),
    );
  });

  testFlutterWorkspace('ws.compile() with imports', (ws) async {
    await ws.writeFileFromText('lib/sayhello.dart', '''
      void sayHello() => print('Hello World');
    ''');

    await ws.writeFileFromText('bin/main.dart', '''
      import 'package:flutter/material.dart';
      import 'package:myapp/sayhello.dart';

      void main() {
        sayHello();
        runApp(const MaterialApp(home: Center(child: Text('Hello Flutter'))));
      }
    ''');

    check(await ws.compile(Uri.parse('bin/main.dart')))
      ..log.isEmpty()
      ..codeContains('Hello Flutter')
      ..codeContains('Hello World')
      ..codeContains('MaterialApp');
  });
}
