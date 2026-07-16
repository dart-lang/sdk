// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:checks/checks.dart';
import 'package:dartpad_worker/src/util/json_rpc_message_port_channel.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

void main() {
  // These tests lives in pkg/dartpad_worker/test/ because pkg/dartpad/test/
  // is not setup to run browser tests.

  group('JSON-RPC-2.0 over MessagePort', () {
    late StreamChannel<Object?> peer1;
    late StreamChannel<Object?> peer2;

    setUp(() {
      final channel = web.MessageChannel();
      peer1 = jsonRpcMessagePortChannel(channel.port1);
      peer2 = jsonRpcMessagePortChannel(channel.port2);
    });

    tearDown(() {
      peer1.sink.close();
      peer2.sink.close();
    });

    test('transmits standard JSON-RPC', () async {
      final request = {
        'jsonrpc': '2.0',
        'method': 'subtract',
        'params': {'minuend': 42, 'subtrahend': 23},
        'id': 1,
      };

      peer1.sink.add(request);

      final received = await peer2.stream.first;
      check(received).isA<Map>().deepEquals(request);
    });

    test('preserves Uint8List binary data', () async {
      peer1.sink.add({
        'jsonrpc': '2.0',
        'method': 'upload',
        'id': 2,
        'params': {
          // Uint8List is not JSON, but allowed by extension
          'bytes': Uint8List.fromList([1, 2, 3, 4, 5]),
        },
      });

      final received = await peer2.stream.first;
      check(received)
          .isA<Map>()['params']
          .isA<Map>()['bytes']
          .isA<Uint8List>()
          .deepEquals([1, 2, 3, 4, 5]);
    });

    test('transfers MessagePort in params.port', () async {
      // Create a secondary channel just to send one of its ports across
      final sideChannel = web.MessageChannel();
      final portToSend = sideChannel.port2;

      peer1.sink.add({
        'jsonrpc': '2.0',
        'method': 'connect',
        'params': {
          // We can only send ports in params.port and result.port
          'port': portToSend,
        },
        'id': 3,
      });
      final received = await peer2.stream.first as Map;

      // Verify the port arrived and is recognized as a MessagePort
      final receivedPort = (received['params'] as Map)['port'] as Object?;
      check(
        receivedPort.isA<web.MessagePort>(),
        because: 'params.port is a MessagePort',
      ).isTrue();

      // Verify that the port works
      final actualPort = receivedPort as web.MessagePort;
      actualPort.start();

      var pingReceived = Completer<void>();
      sideChannel.port1.onmessage = ((web.MessageEvent e) {
        if (e.data.dartify() == 'ping') {
          pingReceived.complete();
        }
      }).toJS;
      sideChannel.port1.start();

      actualPort.postMessage('ping'.toJS);

      await check(
        pingReceived.future.timeout(const Duration(milliseconds: 500)),
      ).completes();
    });

    test('transfers MessagePort in result.port', () async {
      final sideChannel = web.MessageChannel();
      final portToSend = sideChannel.port2;

      peer1.sink.add({
        'jsonrpc': '2.0',
        'id': 4,
        'result': {
          // We can only send ports in params.port and result.port
          'port': portToSend,
        },
      });
      final received = await peer2.stream.first as Map;

      // Verify the port arrived and is recognized as a MessagePort
      final receivedPort = (received['result'] as Map)['port'] as Object?;
      check(
        receivedPort.isA<web.MessagePort>(),
        because: 'result.port is a MessagePort',
      ).isTrue();
    });

    test('handles batched arrays of messages', () async {
      final batch = [
        {
          'jsonrpc': '2.0',
          'method': 'notify_hello',
          'params': [7],
        },
        {
          'jsonrpc': '2.0',
          'method': 'subtract',
          'params': [42, 23],
          'id': 2,
        },
      ];

      peer1.sink.add(batch);
      final received = await peer2.stream.first;

      check(received).isA<List>().deepEquals(batch);
    });

    test('json_rpc_2 Client/Server integration test', () async {
      // A simple integration test of using package:json_rpc_2 over a
      // MessagePort
      final server = Server.withoutJson(peer1);
      final client = Client.withoutJson(peer2);

      // Register methods on the server
      server.registerMethod('divide', (Parameters params) {
        final divisor = params['divisor'].asInt;
        if (divisor == 0) {
          throw RpcException(
            1234, // Custom error code
            'Cannot divide by zero',
          );
        }
        return params['dividend'].asInt ~/ divisor;
      });

      server.registerMethod('sendBytes', (Parameters params) {
        return params['bytes'].value is Uint8List;
      });

      server.registerMethod('receiveBytes', (Parameters params) {
        return {
          'bytes': Uint8List.fromList([1, 2, 3, 4, 5]),
        };
      });

      server.registerMethod('sendPort', (Parameters params) {
        return (params['port'].value as Object?).isA<web.MessagePort>();
      });

      server.registerMethod('receivePort', (Parameters params) {
        final sideChannel = web.MessageChannel();
        return {'port': sideChannel.port2};
      });

      // Start processing messages
      unawaited(server.listen());
      unawaited(client.listen());

      // Verify a successful request works perfectly
      final successResult = await client.sendRequest('divide', {
        'dividend': 10,
        'divisor': 2,
      });
      check(successResult).equals(5);

      // Verify an exception on the server surfaces as an RpcException
      await check(
        client.sendRequest('divide', {'dividend': 10, 'divisor': 0}),
      ).throws<RpcException>();

      // Verify that we can send bytes
      await check(
        client.sendRequest('sendBytes', {
          'bytes': Uint8List.fromList([42, 42, 42]),
        }),
      ).completes((v) => v.isA<bool>().isTrue());

      // Verify that we can receive bytes
      await check(client.sendRequest('receiveBytes')).completes(
        (v) =>
            v.isA<Map>()['bytes'].isA<Uint8List>().deepEquals([1, 2, 3, 4, 5]),
      );

      // Verify that we can send a port
      await check(
        client.sendRequest('sendPort', {'port': web.MessageChannel().port1}),
      ).completes((v) => v.isA<bool>().isTrue());

      // Verify that we can receive a port
      final r = await client.sendRequest('receivePort') as Map;
      check((r['port'] as Object?).isA<web.MessagePort>()).isTrue();

      // Closing the client/server closes the underlying streams automatically
      await client.close();
      await server.close();
    });

    test('json_rpc_2 exception with Port in request', () async {
      final server = Server.withoutJson(peer1);
      final client = Client.withoutJson(peer2);

      server.registerMethod('failWithPort', (Parameters params) {
        // We throw an exception. The server will echo the request back.
        // We test that error.data.request.params.port is scrubbed, otherwise,
        // the browser would throw a DataCloneError.
        throw RpcException(5678, 'Intentional failure');
      });

      unawaited(server.listen());
      unawaited(client.listen());

      await check(
        client.sendRequest('failWithPort', {
          'port': web.MessageChannel().port1,
        }),
      ).throws<RpcException>();

      await client.close();
      await server.close();
    });
  });
}
