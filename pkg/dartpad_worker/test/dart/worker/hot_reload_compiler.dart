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

    final c = await ws.startHotReloadCompiler(Uri.parse('main.dart'));
    check(await c.compile())
      ..codeContains('Hello World 1!')
      ..log.isEmpty();

    // Update the main file and recompile!
    await ws.writeFileFromText(
      'main.dart',
      "void main() => print('Hello World 2!');",
    );
    check(await c.compile())
      ..codeContains('Hello World 2!')
      ..log.isEmpty();
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

    final c = await ws.startHotReloadCompiler(Uri.parse('bin/main.dart'));

    check(await c.compile())
      ..codeContains('Hello 1!')
      ..log.isEmpty();

    await ws.writeFileFromText('lib/sayhello.dart', '''
      void sayHello() => print('Hello 2!');
    ''');

    check(await c.compile())
      ..codeContains('Hello 2!')
      ..log.isEmpty();
  });

  testDartWorkspace('rejects enum -> class change', (ws) async {
    await ws.writeFileFromText(
      'main.dart',
      'enum Foo {bar}\nvoid main() => print(Foo);',
    );

    final c = await ws.startHotReloadCompiler(Uri.parse('main.dart'));
    check(await c.compile())
      ..code.isNotNull()
      ..log.isEmpty();

    // Recompilation is rejected, because this cannot be hot-reloaded
    await ws.writeFileFromText(
      'main.dart',
      'class Foo{}\nvoid main() => print(Foo);',
    );

    await check(c.compile()).throws<HotReloadRejectedException>(
      (e) => e.message.contains('Enum class cannot be redefined'),
    );

    // Recompilation is successful
    await ws.writeFileFromText(
      'main.dart',
      'enum Foo {bar}\nvoid main() => print(Foo.bar);',
    );
    check(await c.compile())
      ..code.isNotNull()
      ..log.isEmpty();
  });
}
