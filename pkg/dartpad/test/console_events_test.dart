// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:checks/checks.dart';
import 'package:dartpad/src/message_port/message_port.dart';
import 'package:dartpad/src/worker_client.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

void main() {
  late Peer worker;
  late Sandbox sandbox;

  setUp(() async {
    final channel = StreamChannelController<Object?>();
    worker = Peer.withoutJson(channel.foreign);
    worker.registerMethod(
      'createWorkspace',
      (Parameters _) => {
        'workspaceId': 1,
        'workspaceFolder': '/workspace/pad_1/',
      },
    );
    worker.registerMethod(
      'workspace/connectSandbox',
      (Parameters _) => {
        'sandboxId': 1,
        'modes': ['console'],
      },
    );
    worker.registerMethod(
      'workspace/sandbox/close',
      (Parameters _) => <String, Object?>{},
    );
    unawaited(worker.listen());
    final client = WorkerClient(channel.local);
    addTearDown(client.dispose);
    addTearDown(worker.close);
    final workspace = await client.createWorkspace();
    final portChannel = StreamChannelController<Uint8List>();
    sandbox = await workspace.connectSandboxedIframe(
      MessagePort.fromBinaryChannel(portChannel.local),
    );
    addTearDown(sandbox.close);
  });

  void emitConsole(String? level, String message, {String? source}) {
    worker.sendNotification('workspace/sandbox/console', {
      'workspaceId': 1,
      'sandboxId': 1,
      'level': ?level,
      'source': ?source,
      'message': message,
    });
  }

  test(
    'consoleEvents preserves levels alongside legacy text listeners',
    () async {
      final events = sandbox.consoleEvents.take(4).toList();
      final messages = sandbox.console.take(4).toList();
      final secondListener = sandbox.consoleEvents.take(4).toList();
      for (final level in ConsoleLevel.values) {
        emitConsole(
          level.name,
          '${level.name} message\nsecond line',
          source: 'console',
        );
      }

      final expected = [
        for (final level in ConsoleLevel.values)
          (
            level: level,
            source: ConsoleSource.console,
            message: '${level.name} message\nsecond line',
          ),
      ];
      check(await events).deepEquals(expected);
      check(await secondListener).deepEquals(expected);
      check(await messages).deepEquals(expected.map((e) => e.message));
    },
  );

  test('missing and unknown metadata defaults to console log', () async {
    final events = sandbox.consoleEvents.take(2).toList();
    emitConsole(null, 'older worker');
    emitConsole('future-level', 'newer worker', source: 'future-source');

    check(await events).deepEquals([
      (
        level: ConsoleLevel.log,
        source: ConsoleSource.console,
        message: 'older worker',
      ),
      (
        level: ConsoleLevel.log,
        source: ConsoleSource.console,
        message: 'newer worker',
      ),
    ]);
  });

  test('Dart prints are distinct from identical console messages', () async {
    final events = sandbox.consoleEvents.take(2).toList();
    final messages = sandbox.console.take(2).toList();
    emitConsole('log', 'same text', source: 'dartPrint');
    emitConsole('log', 'same text', source: 'console');

    check(await events).deepEquals([
      (
        level: ConsoleLevel.log,
        source: ConsoleSource.dartPrint,
        message: 'same text',
      ),
      (
        level: ConsoleLevel.log,
        source: ConsoleSource.console,
        message: 'same text',
      ),
    ]);
    check(await messages).deepEquals(['same text', 'same text']);
  });

  test('closing a sandbox closes both console streams', () async {
    final events = sandbox.consoleEvents.toList();
    final messages = sandbox.console.toList();
    final firstEvent = sandbox.consoleEvents.first;
    emitConsole('error', 'last message');
    await firstEvent;
    await sandbox.close();

    check(await events).deepEquals([
      (
        level: ConsoleLevel.error,
        source: ConsoleSource.console,
        message: 'last message',
      ),
    ]);
    check(await messages).deepEquals(['last message']);
  });
}
