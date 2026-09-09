// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../worker_harness.dart';

void main() {
  testDartWorkspace('sandbox handles events and extensions', (ws) async {
    final iframe = FakeSandboxedIframe();
    final sandbox = await ws.connectSandboxedIframe(iframe.port);

    // Test console event
    final consoleFuture = sandbox.console.first;
    iframe.emitConsole('info', 'hello console');
    check(await consoleFuture).equals('hello console');

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
      (it) => it
        ..kind.equals('ext.testEvent')
        ..data.deepEquals({'key': 'value'}),
    );

    // Test invokeExtension
    final result = await sandbox.invokeExtension('ext.myMethod', {
      'arg': 'val',
    });
    check(result).equals('success');
    await iframe.checkEvent(
      (it) => it.isA<InvokeExtensionEvent>()
        ..method.equals('ext.myMethod')
        ..parameters.deepEquals({'arg': 'val'}),
    );

    // Test close
    await sandbox.close();

    await iframe.close();
  });
}
