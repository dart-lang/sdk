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

    var result = await sandbox.run('bin/main.dart', mode: 'flutter');
    check(result.log).isEmpty;
    await iframe.checkEvent(
      .it()..isA<LoadModuleEvent>(
        .it()
          ..code.contains('Hello Flutter')
          ..code.contains('MaterialApp'),
      ),
    );
    await iframe.checkEvent(
      .it()..isA<RunEvent>(.it()..mode.equals('flutter')),
    );
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
      sandbox.run('bin/main.dart', mode: 'flutter'),
    ).throws<CompilationFailedException>(
      .it()..has((it) => it.message, 'message').contains("Expected ';'"),
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

    var result = await sandbox.run('bin/main.dart', mode: 'flutter');
    check(result.log).isEmpty;
    await iframe.checkEvent(
      .it()..isA<LoadModuleEvent>(
        .it()
          ..code.contains('Hello Flutter')
          ..code.contains('Hello World')
          ..code.contains('MaterialApp'),
      ),
    );
    await iframe.checkEvent(.it()..isA<RunEvent>());
    await iframe.close();
  });
}
