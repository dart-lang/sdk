// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
library;

import '../../integration_harness.dart';

void main() => testDartIntegration('hotReload', (ctx) async {
  await ctx.ws.writeFileFromText('pubspec.yaml', '''
    name: myapp
    environment:
      sdk: ^3.11.0
  ''');
  printOnFailure('# Running pub get');
  await ctx.ws.pub(command: 'get', args: ['--offline']);

  await ctx.ws.writeFileFromText('bin/main.dart', '''
    import 'dart:async';

    void sayHello() => print('Hello 1!');

    void main() {
      Timer.periodic(Duration(milliseconds: 100), (_) {
        sayHello();
      });
    }
  ''');

  printOnFailure('# Running code in sandbox');
  final r1 = await ctx.sandbox.runMain('bin/main.dart');
  check(r1.log).isNotNull();

  await ctx.checkConsole((m) => m.contains('Hello 1!'));

  await ctx.ws.writeFileFromText('bin/main.dart', '''
    import 'dart:async';

    void sayHello() => print('Hello 2!');

    void main() {
      Timer.periodic(Duration(milliseconds: 100), (_) {
        sayHello();
      });
    }
  ''');

  printOnFailure('# hotReload in sandbox');
  final r2 = await ctx.sandbox.hotReload();
  check(r2.log).isNotNull();

  await ctx.checkConsole((m) => m.contains('Hello 2!'));
});
