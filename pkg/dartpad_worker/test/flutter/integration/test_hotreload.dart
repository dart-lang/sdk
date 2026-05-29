// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
library;

import '../../integration_harness.dart';

void main() => testFlutterIntegration('sandbox.runApp (flutter)', (ctx) async {
  await ctx.ws.writeFileFromText('pubspec.yaml', '''
    name: myapp
    environment:
      sdk: ^3.12.0
    dependencies:
      flutter:
        sdk: flutter
  ''');

  printOnFailure('# Running pub get');
  await ctx.ws.pub(command: 'get');

  await ctx.ws.writeFileFromText('main.dart', r'''
    import 'dart:async';
    import 'package:flutter/material.dart';

    void sayHello() => print('Hello 1!');

    void main() {
      Timer.periodic(Duration(milliseconds: 100), (_) {
        sayHello();
      });
      runApp(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Flutter Sandbox Test'),
            ),
          ),
        ),
      );
    }
  ''');

  printOnFailure('# c = startHotReloadCompiler()');
  final c = await ctx.ws.startHotReloadCompiler(Uri.parse('main.dart'));
  printOnFailure('# c.compile()');
  final r1 = await c.compile();
  check(r1).successEmptyLog();

  printOnFailure('# Running code in sandbox');
  await ctx.sandbox.loadModule(code: r1.code!);
  await ctx.sandbox.runApp(ctx.ws.workspaceFolder.resolve('main.dart'));

  await ctx.checkConsole((m) => m.contains('Hello 1!'));

  await ctx.ws.writeFileFromText('main.dart', r'''
    import 'dart:async';
    import 'package:flutter/material.dart';

    void sayHello() => print('Hello 2!');

    void main() {
      Timer.periodic(Duration(milliseconds: 100), (_) {
        sayHello();
      });
      runApp(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Flutter Sandbox Test'),
            ),
          ),
        ),
      );
    }
  ''');

  printOnFailure('# c.compile(), again!');
  final r2 = await c.compile();
  check(r2).successEmptyLog();

  printOnFailure('# hotReload in sandbox');
  await ctx.sandbox.hotReload(
    code: r2.code,
    librariesToReload: r2.compiledLibraryUris.map(Uri.parse).toList(),
  );

  await ctx.checkConsole((m) => m.contains('Hello 2!'));
});
