// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../worker_harness.dart';

void main() {
  testDartWorkspace('recompile hello world (twice)', (ws) async {
    await ws.writeFileFromText(
      'main.dart',
      "void main() => print('Hello World 1!');",
    );

    final iframe = FakeSandboxedIframe();
    final sandbox = await ws.connectSandboxedIframe(iframe.port);

    var result = await sandbox.run('main.dart', mode: 'console');
    check(result.log).isEmpty;
    await iframe.checkEvent(
      .it()..isA<LoadModulesEvent>(.it()..anyModuleContains('Hello World 1!')),
    );
    await iframe.checkEvent(.it()..isA<RunEvent>());

    // Update the main file and recompile!
    await ws.writeFileFromText(
      'main.dart',
      "void main() => print('Hello World 2!');",
    );

    result = await sandbox.hotReload();
    check(result.log).isEmpty;
    await iframe.checkEvent(
      .it()..isA<HotReloadEvent>(.it()..anyModuleContains('Hello World 2!')),
    );

    await iframe.close();
  });

  testDartWorkspace('recompile with imports', (ws) async {
    await ws.writeFileFromText('lib/sayhello.dart', '''
      void sayHello() => print('Hello 1!');
    ''');

    await ws.writeFileFromText('bin/main.dart', '''
      import 'dart:async';
      import 'package:myapp/sayhello.dart';

      void main() {
        Timer.periodic(Duration(milliseconds: 100), (_) {
          sayHello();
        });
      }
    ''');

    final iframe = FakeSandboxedIframe();
    final sandbox = await ws.connectSandboxedIframe(iframe.port);

    var result = await sandbox.run('bin/main.dart', mode: 'console');
    check(result.log).isEmpty;
    await iframe.checkEvent(
      .it()..isA<LoadModulesEvent>(.it()..anyModuleContains('Hello 1!')),
    );
    await iframe.checkEvent(.it()..isA<RunEvent>());

    await ws.writeFileFromText('lib/sayhello.dart', '''
      void sayHello() => print('Hello 2!');
    ''');

    result = await sandbox.hotReload();
    check(result.log).isEmpty;
    await iframe.checkEvent(
      .it()..isA<HotReloadEvent>(.it()..anyModuleContains('Hello 2!')),
    );

    await iframe.close();
  });

  testDartWorkspace('rejects enum -> class change', (ws) async {
    await ws.writeFileFromText(
      'main.dart',
      'enum Foo {bar}\nvoid main() => print(Foo);',
    );

    final iframe = FakeSandboxedIframe();
    final sandbox = await ws.connectSandboxedIframe(iframe.port);

    var result = await sandbox.run('main.dart', mode: 'console');
    check(result.log).isEmpty;
    await iframe.checkEvent(.it()..isA<LoadModulesEvent>());
    await iframe.checkEvent(.it()..isA<RunEvent>());

    // Recompilation is rejected, because this cannot be hot-reloaded
    await ws.writeFileFromText(
      'main.dart',
      'class Foo{}\nvoid main() => print(Foo);',
    );

    await check(sandbox.hotReload()).throws<HotReloadRejectedException>(
      .it()
        ..has(
          (it) => it.message,
          'message',
        ).contains('Enum class cannot be redefined'),
    );

    // Recompilation is successful
    await ws.writeFileFromText(
      'main.dart',
      'enum Foo {bar}\nvoid main() => print(Foo.bar);',
    );

    result = await sandbox.hotReload();
    check(result.log).isEmpty;
    await iframe.checkEvent(.it()..isA<HotReloadEvent>());

    await iframe.close();
  });

  testDartWorkspace('recompile after importing a missing file', (ws) async {
    await ws.writeFileFromText(
      'main.dart',
      "void main() => print('Hello 1!');",
    );

    final iframe = FakeSandboxedIframe();
    final sandbox = await ws.connectSandboxedIframe(iframe.port);

    var result = await sandbox.run('main.dart', mode: 'console');
    check(result.log).isEmpty;
    await iframe.checkEvent(
      .it()..isA<LoadModulesEvent>(.it()..anyModuleContains('Hello 1!')),
    );
    await iframe.checkEvent(.it()..isA<RunEvent>());

    // Import a file that hasn't been created yet. `frontend_server` reports it
    // as a dependency of this failed compilation, and only reports it once.
    await ws.writeFileFromText('main.dart', '''
      import 'sayhello.dart';

      void main() => sayHello();
    ''');

    await check(sandbox.hotReload()).throws<CompilationFailedException>();

    // Creating it recovers, ...
    await ws.writeFileFromText(
      'sayhello.dart',
      "void sayHello() => print('Hello 2!');",
    );

    result = await sandbox.hotReload();
    check(result.log).isEmpty;
    await iframe.checkEvent(
      .it()..isA<HotReloadEvent>(.it()..anyModuleContains('Hello 2!')),
    );

    // ... and it must be tracked, so that editing it is picked up.
    await ws.writeFileFromText(
      'sayhello.dart',
      "void sayHello() => print('Hello 3!');",
    );

    result = await sandbox.hotReload();
    check(result.log).isEmpty;
    await iframe.checkEvent(
      .it()..isA<HotReloadEvent>(.it()..anyModuleContains('Hello 3!')),
    );

    await iframe.close();
  });
}
