// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:checks/checks.dart';
import 'package:dartpad_worker/src/tools/sandbox_client.dart';
import 'package:dartpad_worker/src/util/message_port.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

void main() {
  test('console notifications retain level, source and message', () async {
    final channel = StreamChannelController<Uint8List>();
    final iframe = Peer.withoutJson(
      MessagePort.fromBinaryChannel(channel.foreign).jsonRpcChannel(),
    );
    unawaited(iframe.listen());
    final client = SandboxClient(
      MessagePort.fromBinaryChannel(channel.local),
      () {},
    );
    addTearDown(iframe.close);
    addTearDown(client.close);

    final events = client.onConsole.take(6).toList();
    for (final level in ['log', 'info', 'warn', 'error']) {
      iframe.sendNotification('console', {
        'level': level,
        'source': 'console',
        'message': '$level message\nsecond line',
      });
    }
    iframe.sendNotification('console', {
      'level': 'log',
      'source': 'dartPrint',
      'message': 'Dart print',
    });
    iframe.sendNotification('console', {'message': 'without metadata'});

    check(await events).deepEquals([
      for (final level in ['log', 'info', 'warn', 'error'])
        (
          level: level,
          source: 'console',
          message: '$level message\nsecond line',
        ),
      (level: 'log', source: 'dartPrint', message: 'Dart print'),
      (level: 'log', source: 'console', message: 'without metadata'),
    ]);
  });
}
