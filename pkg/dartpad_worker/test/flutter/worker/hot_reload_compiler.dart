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

    final c = await ws.startHotReloadCompiler(Uri.parse('bin/main.dart'));
    check(await c.compile())
      ..log.isEmpty()
      ..codeContains('Hello Flutter 1!')
      ..codeContains('MaterialApp');

    // Update the main file and recompile!
    await ws.writeFileFromText('bin/main.dart', '''
      import 'package:flutter/material.dart';

      void main() => runApp(
        const MaterialApp(home: Center(child: Text('Hello Flutter 2!'))),
      );
    ''');

    check(await c.compile())
      ..log.isEmpty()
      ..codeContains('Hello Flutter 2!')
      ..codeContains('MaterialApp');
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

  testFlutterWorkspace('rejects enum -> class change', (ws) async {
    await ws.writeFileFromText('bin/main.dart', '''
      import 'package:flutter/material.dart';

      enum Foo { bar }
      void main() => runApp(
        const MaterialApp(home: Center(child: Text('Hello Flutter 1!'))),
      );
    ''');

    final c = await ws.startHotReloadCompiler(Uri.parse('bin/main.dart'));
    check(await c.compile())
      ..codeContains('Hello Flutter 1!')
      ..log.isEmpty();

    // Recompilation is rejected, because this cannot be hot-reloaded
    await ws.writeFileFromText('bin/main.dart', '''
      import 'package:flutter/material.dart';

      class Foo {}
      void main() => runApp(
        const MaterialApp(home: Center(child: Text('Hello Flutter!'))),
      );
    ''');

    await check(c.compile()).throws<HotReloadRejectedException>(
      (e) => e.message.contains('Enum class cannot be redefined'),
    );

    // Recompilation is successful
    await ws.writeFileFromText('bin/main.dart', '''
      import 'package:flutter/material.dart';

      enum Foo { bar }
      void main() => runApp(
        const MaterialApp(home: Center(child: Text('Hello Flutter 2!'))),
      );
    ''');
    check(await c.compile())
      ..codeContains('Hello Flutter 2!')
      ..log.isEmpty();
  });
}
