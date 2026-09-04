// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../worker_harness.dart';

void main() {
  testFlutterWorkspace('recompile hello world', (ws) async {
    await ws.writeFileFromText('bin/main.dart', '''
      import 'package:flutter/material.dart';

      void main() => runApp(
        const MaterialApp(home: Center(child: Text('Hello Flutter 1!'))),
      );
    ''');

    final iframe = FakeSandboxedIframe();
    final sandbox = await ws.connectSandboxedIframe(iframe.port);

    var result = await sandbox.runMain('bin/main.dart');
    check(result.log).isEmpty();
    await iframe.checkEvent(
      (it) => it.isA<LoadModuleEvent>().code
        ..contains('Hello Flutter 1!')
        ..contains('MaterialApp'),
    );
    await iframe.checkEvent((it) => it.isA<RunMainEvent>());

    // Update the main file and recompile!
    await ws.writeFileFromText('bin/main.dart', '''
      import 'package:flutter/material.dart';

      void main() => runApp(
        const MaterialApp(home: Center(child: Text('Hello Flutter 2!'))),
      );
    ''');

    result = await sandbox.hotReload();
    check(result.log).isEmpty();
    await iframe.checkEvent(
      (it) => it.isA<HotReloadEvent>().code.isNotNull()
        ..contains('Hello Flutter 2!')
        ..contains('MaterialApp'),
    );

    await iframe.close();
  });

  testFlutterWorkspace('recompile lib/main.dart entrypoint', (ws) async {
    await ws.writeFileFromText('lib/main.dart', '''
      import 'package:flutter/material.dart';

      void main() => runApp(
        const MaterialApp(home: Center(child: Text('Hello Lib Main!'))),
      );
    ''');

    final iframe = FakeSandboxedIframe();
    final sandbox = await ws.connectSandboxedIframe(iframe.port);

    final result = await sandbox.runMain('lib/main.dart');
    check(result.log).isEmpty();
    await iframe.checkEvent(
      (it) => it.isA<LoadModuleEvent>().code
        ..contains('Hello Lib Main!')
        ..contains('MaterialApp'),
    );
    await iframe.checkEvent((it) => it.isA<RunMainEvent>());

    await iframe.close();
  });

  testFlutterWorkspace('recompile with imports', (ws) async {
    await ws.writeFileFromText('lib/sayhello.dart', '''
      void sayHello() => print('Hello 1!');
    ''');

    await ws.writeFileFromText('bin/main.dart', '''
      import 'dart:async';
      import 'package:myapp/sayhello.dart';
      import 'package:flutter/material.dart';

      void main() {
        Timer.periodic(Duration(milliseconds: 100), (_) {
          sayHello();
        });
        runApp(
          const MaterialApp(home: Center(child: Text('Hello Flutter 1!'))),
        );
      }
    ''');

    final iframe = FakeSandboxedIframe();
    final sandbox = await ws.connectSandboxedIframe(iframe.port);

    var result = await sandbox.runMain('bin/main.dart');
    check(result.log).isEmpty();
    await iframe.checkEvent(
      (it) => it.isA<LoadModuleEvent>().code.contains('Hello 1!'),
    );
    await iframe.checkEvent((it) => it.isA<RunMainEvent>());

    await ws.writeFileFromText('lib/sayhello.dart', '''
      void sayHello() => print('Hello 2!');
    ''');

    result = await sandbox.hotReload();
    check(result.log).isEmpty();
    await iframe.checkEvent(
      (it) => it.isA<HotReloadEvent>().code.isNotNull().contains('Hello 2!'),
    );

    await iframe.close();
  });

  testFlutterWorkspace('rejects enum -> class change', (ws) async {
    await ws.writeFileFromText('bin/main.dart', '''
      import 'package:flutter/material.dart';

      enum Foo { bar }
      void main() => runApp(
        const MaterialApp(home: Center(child: Text('Hello Flutter 1!'))),
      );
    ''');

    final iframe = FakeSandboxedIframe();
    final sandbox = await ws.connectSandboxedIframe(iframe.port);

    var result = await sandbox.runMain('bin/main.dart');
    check(result.log).isEmpty();
    await iframe.checkEvent(
      (it) => it.isA<LoadModuleEvent>().code.contains('Hello Flutter 1!'),
    );
    await iframe.checkEvent((it) => it.isA<RunMainEvent>());

    // Recompilation is rejected, because this cannot be hot-reloaded
    await ws.writeFileFromText('bin/main.dart', '''
      import 'package:flutter/material.dart';

      class Foo {}
      void main() => runApp(
        const MaterialApp(home: Center(child: Text('Hello Flutter!'))),
      );
    ''');

    await check(sandbox.hotReload()).throws<HotReloadRejectedException>(
      (e) => e
          .has((it) => it.message, 'message')
          .contains('Enum class cannot be redefined'),
    );

    // Recompilation is successful
    await ws.writeFileFromText('bin/main.dart', '''
      import 'package:flutter/material.dart';

      enum Foo { bar }
      void main() => runApp(
        const MaterialApp(home: Center(child: Text('Hello Flutter 2!'))),
      );
    ''');

    result = await sandbox.hotReload();
    check(result.log).isEmpty();
    await iframe.checkEvent(
      (it) => it.isA<HotReloadEvent>().code.isNotNull().contains(
        'Hello Flutter 2!',
      ),
    );

    await iframe.close();
  });
}
