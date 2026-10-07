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
    import 'package:flutter/material.dart';

    void main() {
      print('Hello from Flutter!');
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

  printOnFailure('# Running code in sandbox');
  await ctx.sandbox.run('main.dart', mode: 'flutter');

  await ctx.checkConsole(.it()..contains('Hello from Flutter!'));

  final service = await ctx.sandbox.startServiceProtocol();
  try {
    final vm = await service.getVM();
    final isolateId = vm.isolates!.first.id!;
    final isolate = await service.getIsolate(isolateId);
    check(
      isolate.extensionRPCs,
    ).isNotNull().contains('ext.flutter.inspector.getRootWidgetTree');
    check(
      isolate.extensionRPCs,
    ).isNotNull().contains('ext.flutter.inspector.structuredErrors');

    final tree = await service.callServiceExtension(
      'ext.flutter.inspector.getRootWidgetTree',
      isolateId: isolateId,
      args: {
        'groupName': 'test-group',
        'isSummaryTree': 'true',
        'withPreviews': 'false',
        'fullDetails': 'false',
      },
    );
    check(tree.json?['result']).isNotNull();
  } finally {
    await service.dispose();
  }
});
