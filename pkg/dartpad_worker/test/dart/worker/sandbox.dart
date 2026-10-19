// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:vm_service/vm_service.dart';

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

    // Test extensionEvent and callServiceExtension via startServiceProtocol()
    final service = await sandbox.startServiceProtocol();
    await service.streamListen(EventStreams.kIsolate);
    await service.streamListen(EventStreams.kExtension);

    final extAdded = check(service.onIsolateEvent).withQueue.emitsThrough(
      .it()
        ..kind.equals(EventKind.kServiceExtensionAdded)
        ..extensionRPC.equals('ext.myMethod'),
    );
    iframe.emitIsolateStart('workspace:///main.dart', 'console');
    iframe.emitRegisterExtension('ext.myMethod');
    await extAdded;

    check(service.onExtensionEvent).withQueue.emitsThrough(
      .it()
        ..extensionKind.equals('ext.testEvent')
        ..extensionData.isNotNull().data.isNotNull().deepEquals({
          'key': 'value',
        }),
    );
    iframe.emitExtensionEvent('ext.testEvent', {'key': 'value'});

    // Test callServiceExtension
    final result = await service.callServiceExtension(
      'ext.myMethod',
      isolateId: 'isolates/1',
      args: {'arg': 'val'},
    );
    check(result.json?['result']).equals('success');
    await iframe.checkEvent(
      .it()..isA<InvokeExtensionEvent>(
        .it()
          ..method.equals('ext.myMethod')
          ..parameters.deepEquals({'arg': 'val'}),
      ),
    );

    await service.dispose();

    // Test close
    await sandbox.close();

    await iframe.close();
  });

  testDartWorkspace('sandbox read-only filesystem', (ws) async {
    final iframe = FakeSandboxedIframe();
    final sandbox = await ws.connectSandboxedIframe(iframe.port);

    await ws.writeFileFromText('bin/main.dart', 'void main() {}');
    await ws.writeFileFromBytes(
      'assets/data.bin',
      Uint8List.fromList([1, 2, 3]),
    );

    // Read-only filesystem operations work with relative and absolute paths
    await check(
      iframe.readFileAsText('bin/main.dart'),
    ).completes(.it()..equals('void main() {}'));
    await check(
      iframe.readFileAsBytes('${ws.workspaceFolder}/assets/data.bin'),
    ).completes(.it()..deepEquals([1, 2, 3]));
    await check(
      iframe.stat('assets/data.bin'),
    ).completes(.it()..deepEquals({'type': 'file', 'size': 3}));
    await check(
      iframe.stat('assets'),
    ).completes(.it()..deepEquals({'type': 'folder'}));
    await check(iframe.listDirectory('assets')).completes(
      .it()..deepEquals([
        {'path': 'data.bin', 'type': 'file'},
      ]),
    );
    await check(
      iframe.readFileAsText('missing.txt'),
    ).throws<FileNotFoundException>();

    await sandbox.close();
    await iframe.close();
  });

  testDartWorkspace('sandbox packageRoot', (ws) async {
    final iframe = FakeSandboxedIframe();
    final sandbox = await ws.connectSandboxedIframe(iframe.port);

    await ws.writeFileFromText('bin/main.dart', 'void main() {}');

    await sandbox.run('bin/main.dart', mode: 'console');
    await iframe.checkEvent(
      .it()..isA<RunEvent>(.it()..packageRoot.equals(ws.workspaceFolder)),
    );

    await sandbox.close();
    await iframe.close();
  });
}
