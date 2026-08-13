// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:path/path.dart' as p;
import 'package:perf_witness/src/common.dart';
import 'package:perf_witness/src/json_rpc.dart';
import 'package:test/test.dart';

void main() {
  group('JsonRpc', () {
    late JsonRpcServer server;
    late JsonRpcPeer client;
    late String socketPath;

    setUp(() async {
      socketPath = p.join(
        io.Directory.systemTemp.createTempSync().path,
        'test.sock',
      );
      server = JsonRpcServer(await UnixDomainSocket.bind(socketPath), {
        'testMethod': (requestor, params) => 'Hello, ${params!['name']}',
        'errorMethod': (requestor, params) => throw 'Something went wrong',
        'ping': (requestor, params) => 'pong',
        'checkEndpoint': (requestor, params) {
          expect(server.endpoints, contains(requestor));
          return 'ok';
        },
      });
      client =
          jsonRpcPeerFromSocket(await UnixDomainSocket.connect(socketPath), {
            'reverse': (requestor, params) =>
                (params!['text'] as String).split('').reversed.join(),
          });
    });

    tearDown(() async {
      await client.close();
      await server.close();
      final file = io.File(socketPath);
      if (file.existsSync()) {
        file.deleteSync();
      }
    });

    test('can make a successful request', () async {
      final result = await client.sendRequest('testMethod', {'name': 'World'});
      expect(result, 'Hello, World');
    });

    test('handles method not found', () async {
      try {
        await client.sendRequest('nonExistentMethod');
        fail('Expected an error');
      } catch (e) {
        expect(e, isA<JsonRpcException>());
        expect(
          (e as JsonRpcException).message,
          'Unknown method "nonExistentMethod".',
        );
      }
    });

    test('handles internal server error', () async {
      try {
        await client.sendRequest('errorMethod');
        fail('Expected an error');
      } catch (e) {
        expect(e, isA<JsonRpcException>());
        expect((e as JsonRpcException).message, 'Something went wrong');
      }
    });

    test('can make bidirectional requests', () async {
      // Client calls server
      expect(await client.sendRequest('ping'), 'pong');

      // Server calls client
      // Wait for the server to accept the connection.
      while (server.endpoints.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
      final endpoint = server.endpoints.first;
      expect(await endpoint.sendRequest('reverse', {'text': 'hello'}), 'olleh');
    });

    test('method receives correct endpoint', () async {
      expect(await client.sendRequest('checkEndpoint'), equals('ok'));
    });
  });
}
