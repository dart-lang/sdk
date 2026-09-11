// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
library;

import 'dart:convert';
import 'dart:typed_data';

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
      final bin2 = port2.asBinaryChannel();

      rpc1.sink.add({'ping': 'pong'});

      final receivedBin = await bin2.stream.first;

      // Let's decode the binary manually to verify it produced the
      // valid encoding
      final v = ByteData.sublistView(receivedBin);
      final jsonSize = v.getUint32(0);
      final jsonBytes = Uint8List.sublistView(receivedBin, 4, jsonSize + 4);
      final decoded = json.fuse(utf8).decode(jsonBytes);
      check(decoded).isA<Map>().deepEquals({'ping': 'pong'});

      await rpc1.sink.close();
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
  });
}
