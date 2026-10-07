// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
library;

import '../../integration_harness.dart';

String _appSource(String label) =>
    '''
  import 'package:flutter/material.dart';

  void main() {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) {
                print('build: $label');
                return const Text('$label');
              },
            ),
          ),
        ),
      ),
    );
  }
''';

void main() =>
    testFlutterIntegration('sandbox.hotRestart (flutter)', (ctx) async {
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

      await ctx.ws.writeFileFromText('main.dart', _appSource('v1'));

      printOnFailure('# Running code in sandbox');
      await ctx.sandbox.run('main.dart', mode: 'flutter');
      await ctx.checkConsole(.it()..contains('build: v1'));

      await ctx.ws.writeFileFromText('main.dart', _appSource('v2'));
      printOnFailure('# First hotRestart in sandbox');
      await ctx.sandbox.hotRestart();
      await ctx.checkConsole(.it()..contains('build: v2'));

      await ctx.ws.writeFileFromText('main.dart', _appSource('v3'));
      printOnFailure('# Second hotRestart in sandbox');
      await ctx.sandbox.hotRestart();
      await ctx.checkConsole(.it()..contains('build: v3'));

      check(ctx.consoleLog.where((e) => e.level == ConsoleLevel.error)).isEmpty;
    });
