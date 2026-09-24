// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../worker_harness.dart';

void main() {
  testDartWorkspace('sandbox handles events and extensions', (ws) async {
    final iframe = FakeSandboxedIframe();
    final sandbox = await ws.connectSandboxedIframe(iframe.port);

    // Both APIs receive the same messages, including multiline error reports.
    for (final level in ConsoleLevel.values) {
      final consoleFuture = sandbox.console.first;
      final eventFuture = sandbox.consoleEvents.first;
      final message = '${level.name} message\nsecond line';
      iframe.emitConsole(level.name, message);
      check(await consoleFuture).equals(message);
      check(
        await eventFuture,
      ).equals((level: level, source: ConsoleSource.console, message: message));
    }

    final printFuture = sandbox.consoleEvents.first;
    iframe.emitConsole('log', 'Dart print', source: 'dartPrint');
    check(await printFuture).equals((
      level: ConsoleLevel.log,
      source: ConsoleSource.dartPrint,
      message: 'Dart print',
    ));

    // Test error event
    final errorFuture = sandbox.errors.first;
    iframe.emitError('hello error', 'stack trace details');
    check(await errorFuture).equals('hello error');

    // Test unhandledRejection
    final unhandledRejectionFuture = sandbox.unhandledRejections.first;
    iframe.emitUnhandledRejection('hello unhandledRejection');
    check(await unhandledRejectionFuture).equals('hello unhandledRejection');

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
