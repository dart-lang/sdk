// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
library;

import '../../integration_harness.dart';

void main() => testDartIntegration('dartpad', (ctx) async {
  await ctx.ws.writeFileFromText('pubspec.yaml', '''
    name: myapp
    dependencies:
      foo: ^1.0.0
    environment:
      sdk: ^3.11.0
  ''');

  printOnFailure('# Running pub get');
  await ctx.ws.pub(command: 'get');

  await ctx.ws.writeFileFromText('main.dart', r'''
    void main() {
      print('Hello from DartPad!');
    }
  ''');

  printOnFailure('# Compiling main.dart');
  final result = await ctx.ws.compile(Uri.parse('main.dart'));
  check(result).successEmptyLog();

  printOnFailure('# Running code in sandbox');
  await ctx.sandbox.loadModule(code: result.code!);
  await ctx.sandbox.runMain(ctx.ws.workspaceFolder.resolve('main.dart'));

  await ctx.checkConsole((m) => m.contains('Hello from DartPad!'));
});
