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

    final iframe = FakeSandboxedIframe();
    final sandbox = await ws.connectSandboxedIframe(iframe.port);

    var result = await sandbox.runMain('bin/main.dart');
    check(result.log).isEmpty();
    await iframe.checkEvent(
      (it) => it.isA<LoadModuleEvent>().code
        ..contains('Hello Flutter')
        ..contains('MaterialApp'),
    );
    await iframe.checkEvent((it) => it.isA<RunMainEvent>());
    await iframe.close();
  });

  testFlutterWorkspace('ws.compile() missing semicolon', (ws) async {
    await ws.writeFileFromText('bin/main.dart', '''
      import 'package:flutter/material.dart';

      void main() => runApp(
        const MaterialApp(home: Center(child: Text('Hello Flutter'))),
      )
    ''');

    final iframe = FakeSandboxedIframe();
    final sandbox = await ws.connectSandboxedIframe(iframe.port);

    await check(
      sandbox.runMain('bin/main.dart'),
    ).throws<CompilationFailedException>(
      (e) => e.has((it) => it.message, 'message').contains("Expected ';'"),
    );
    await iframe.close();
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

    final iframe = FakeSandboxedIframe();
    final sandbox = await ws.connectSandboxedIframe(iframe.port);

    var result = await sandbox.runMain('bin/main.dart');
    check(result.log).isEmpty();
    await iframe.checkEvent(
      (it) => it.isA<LoadModuleEvent>().code
        ..contains('Hello Flutter')
        ..contains('Hello World')
        ..contains('MaterialApp'),
    );
    await iframe.checkEvent((it) => it.isA<RunMainEvent>());
    await iframe.close();
  });
}
