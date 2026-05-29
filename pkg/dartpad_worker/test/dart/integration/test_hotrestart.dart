// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
library;

import '../../integration_harness.dart';

void main() => testDartIntegration('hotRestart', (ctx) async {
  await ctx.ws.writeFileFromText('pubspec.yaml', '''
    name: myapp
    environment:
      sdk: ^3.11.0
  ''');
  printOnFailure('# Running pub get');
  await ctx.ws.pub(command: 'get', args: ['--offline']);

  await ctx.ws.writeFileFromText('bin/main.dart', '''
      void main() {
        print('Hello 1!');
      }
    ''');

  printOnFailure('# c = startHotReloadCompiler()');
  final c = await ctx.ws.startHotReloadCompiler(Uri.parse('bin/main.dart'));

  printOnFailure('# c.compile()');
  final r1 = await c.compile();
  check(r1).successEmptyLog();

  printOnFailure('# Running code in sandbox');
  await ctx.sandbox.loadModule(code: r1.code!);
  await ctx.sandbox.runMain(ctx.ws.workspaceFolder.resolve('bin/main.dart'));

  await ctx.checkConsole((m) => m.contains('Hello 1!'));

  await ctx.ws.writeFileFromText('bin/main.dart', '''
      void main() {
        print('Hello 2!');
      }
    ''');

  printOnFailure('# c.compile(), again!');
  final r2 = await c.compile();
  check(r2).successEmptyLog();

  printOnFailure('# hotReload in sandbox');
  await ctx.sandbox.hotRestart(code: r2.code);

  await ctx.checkConsole((m) => m.contains('Hello 2!'));
});
