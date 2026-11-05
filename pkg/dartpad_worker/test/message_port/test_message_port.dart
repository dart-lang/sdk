// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
library;

import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:checks/checks.dart';
import 'package:dartpad_worker/src/util/message_port.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

void main() {
  group('BrowserMessagePort', () {
    test('asTransferableMessagePort returns original port', () {
      final channel = web.MessageChannel();
      final port = MessagePortExt.fromMessagePort(channel.port1);
      check(port.asTransferableMessagePort()).equals(channel.port1);
    });

    test('jsonRpcChannel communicates properly', () async {
      final channel = web.MessageChannel();
      final port1 = MessagePortExt.fromMessagePort(channel.port1);
      final port2 = MessagePortExt.fromMessagePort(channel.port2);

      final rpc1 = port1.jsonRpcChannel();
      final rpc2 = port2.jsonRpcChannel();

      rpc1.sink.add({'ping': 'pong'});
      final received = await rpc2.stream.first;
      check(received).isA<Map>().deepEquals({'ping': 'pong'});

      await rpc1.sink.close();
      await rpc2.sink.close();
    });

    test('asBinaryChannel produces encoded messages', () async {
      final channel = web.MessageChannel();
      final port1 = MessagePortExt.fromMessagePort(channel.port1);
      final port2 = MessagePortExt.fromMessagePort(channel.port2);

      final rpc1 = port1.jsonRpcChannel();
      final rpc2 = MessagePort.fromBinaryChannel(
        port2.asBinaryChannel(),
      ).jsonRpcChannel();

      rpc1.sink.add({'ping': 'pong'});
      final received = await rpc2.stream.first;
      check(received).isA<Map>().deepEquals({'ping': 'pong'});

      await rpc1.sink.close();
      await rpc2.sink.close();
    });

    test('vmServiceChannel communicates strings, bytes, and close', () async {
      final channel = web.MessageChannel();
      final port1 = MessagePortExt.fromMessagePort(channel.port1);
      final port2 = MessagePortExt.fromMessagePort(channel.port2);

      final vm1 = port1.vmServiceChannel();
      final vm2 = MessagePort.fromBinaryChannel(
        port2.asBinaryChannel(),
      ).vmServiceChannel();

      vm1.sink.add('{"jsonrpc":"2.0","method":"getVersion","id":"1"}');
      vm1.sink.add(Uint8List.fromList([10, 20, 30]));
      await vm1.sink.close();

      final received = await vm2.stream.toList();
      check(received).length.equals(2);
      check(received[0]).isA<String>().equals(
        '{"jsonrpc":"2.0","method":"getVersion","id":"1"}',
      );
      check(received[1]).isA<Uint8List>().deepEquals([10, 20, 30]);
    });
  });

  group('StreamChannelMessagePort', () {
    test('asBinaryChannel returns original channel', () async {
      final ctrl = StreamChannelController<Uint8List>();

      final port = MessagePort.fromBinaryChannel(ctrl.local);
      final binChannel = port.asBinaryChannel();

      binChannel.sink.add(Uint8List.fromList([1, 2, 3]));
      final received = await ctrl.foreign.stream.first;
      check(received).deepEquals([1, 2, 3]);
    });

    test('jsonRpcChannel communicates properly', () async {
      final ctrl = StreamChannelController<Uint8List>();

      final port1 = MessagePort.fromBinaryChannel(ctrl.local);
      final port2 = MessagePort.fromBinaryChannel(ctrl.foreign);

      final rpc1 = port1.jsonRpcChannel();
      final rpc2 = port2.jsonRpcChannel();

      rpc1.sink.add({'ping': 'pong'});
      final received = await rpc2.stream.first;
      check(received).isA<Map>().deepEquals({'ping': 'pong'});
    });

    test('asTransferableMessagePort creates a web.MessagePort', () async {
      final ctrl = StreamChannelController<Uint8List>();

      final port1 = MessagePort.fromBinaryChannel(ctrl.local);
      final port2 = MessagePort.fromBinaryChannel(ctrl.foreign);

      final rpc2 = port2.jsonRpcChannel();

      final webPort = port1.asTransferableMessagePort();

      final wrappedWebPort = MessagePortExt.fromMessagePort(webPort);
      final rpc1 = wrappedWebPort.jsonRpcChannel();

      rpc1.sink.add({'remote': 'control'});
      final received = await rpc2.stream.first;
      check(received).isA<Map>().deepEquals({'remote': 'control'});
    });

    test('asTransferableMessagePort bridges vmServiceChannel', () async {
      final ctrl = StreamChannelController<Uint8List>();

      final port1 = MessagePort.fromBinaryChannel(ctrl.local);
      final port2 = MessagePort.fromBinaryChannel(ctrl.foreign);

      final vm2 = port2.vmServiceChannel();
      final webPort = port1.asTransferableMessagePort();
      final vm1 = MessagePortExt.fromMessagePort(webPort).vmServiceChannel();

      final receivedFuture = vm2.stream.toList();
      vm1.sink.add('{"jsonrpc":"2.0"}');
      vm1.sink.add(Uint8List.fromList([4, 5, 6]));
      await vm1.sink.close();

      final received = await receivedFuture;
      check(received).length.equals(2);
      check(received[0]).isA<String>().equals('{"jsonrpc":"2.0"}');
      check(received[1]).isA<Uint8List>().deepEquals([4, 5, 6]);
    });

    test('malformed frames emit FormatException', () async {
      final ctrl = StreamChannelController<Uint8List>();
      final rpc = MessagePort.fromBinaryChannel(ctrl.local).jsonRpcChannel();
      final queue = StreamQueue(rpc.stream);

      // Empty frame, truncated objectWithBytes (< 5 bytes and < 5 + jsonSize),
      // invalid UTF-8, and invalid JSON.
      for (final badFrame in [
        Uint8List(0),
        Uint8List.fromList([1, 0, 0]),
        Uint8List.fromList([1, 0, 0, 0, 10, 123, 125]),
        Uint8List.fromList([0, 0xff]),
        Uint8List.fromList([0, 123]),
      ]) {
        ctrl.foreign.sink.add(badFrame);
        await check(queue.next).throws<FormatException>();
      }
    });
  });
}
