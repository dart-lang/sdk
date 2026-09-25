// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../worker_harness.dart';

void main() {
  testDartWorkspace('sandbox handles events and extensions', (ws) async {
    final iframe = FakeSandboxedIframe();
    final sandbox = await ws.connectSandboxedIframe(iframe.port);

    // Test console events across levels
    for (final level in ConsoleLevel.values) {
      final consoleFuture = sandbox.console.first;
      iframe.emitConsole(level.protocolName, 'hello ${level.protocolName}');
      check(
        await consoleFuture,
      ).equals((level: level, message: 'hello ${level.protocolName}'));
    }

    // Test extensionEvent
    final extensionEventFuture = sandbox.extensionEvents.first;
    iframe.emitExtensionEvent('ext.testEvent', {'key': 'value'});
    await check(extensionEventFuture).completes(
      .it()
        ..kind.equals('ext.testEvent')
        ..data.deepEquals({'key': 'value'}),
    );

    // Test invokeExtension
    final result = await sandbox.invokeExtension('ext.myMethod', {
      'arg': 'val',
    });
    check(result).equals('success');
    await iframe.checkEvent(
      .it()..isA<InvokeExtensionEvent>(
        .it()
          ..method.equals('ext.myMethod')
          ..parameters.deepEquals({'arg': 'val'}),
      ),
    );

    // Test close
    await sandbox.close();

    await iframe.close();
  });
}
