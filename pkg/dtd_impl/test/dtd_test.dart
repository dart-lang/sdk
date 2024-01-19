// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dtd_impl/src/rpc_error_codes.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:test/test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:dtd_impl/dart_tooling_daemon.dart';

void main() {
  late Peer client1;
  late Peer client2;
  late DartToolingDaemon? dtd;
  setUp(() async {
    dtd = await DartToolingDaemon.startService([]);

    // Wait for server to start and print to the port to stdout.
    final uri = dtd!.uri!.toString();

    client1 = _createClient(uri);
    client2 = _createClient(uri);
  });

  tearDown(() async {
    await client2.close();
    await client1.close();
    await dtd?.close();
  });

  group('streams', () {
    final streamId = 'testStream';
    final eventKind = 'test';
    final eventData = {'the': 'data'};

    test('basics', () async {
      final completer = Completer();
      client1.registerMethod('streamNotify', (Parameters parameters) {
        completer.complete(parameters.asMap);
      });
      final listenResult = await client1.sendRequest('streamListen', {
        "streamId": streamId,
      });

      expect(listenResult, {"type": "Success"});

      final postResult = await client2.sendRequest(
        'postEvent',
        {
          'streamId': streamId,
          'eventKind': eventKind,
          'eventData': eventData,
        },
      );
      expect(postResult, {"type": "Success"});

      final dataFromTheStream = await completer.future;
      expect(dataFromTheStream, {
        "streamId": streamId,
        "eventKind": eventKind,
        "eventData": eventData,
      });
    });

    test('streamListen the same stream', () async {
      final listenResult = await client1.sendRequest('streamListen', {
        "streamId": streamId,
      });

      expect(listenResult, {"type": "Success"});

      expect(
        () => client1.sendRequest('streamListen', {
          "streamId": streamId,
        }),
        throwsA(
          predicate(
            (e) =>
                e is RpcException &&
                e.code == RpcErrorCodes.kStreamAlreadySubscribed,
          ),
        ),
      );
    });

    test('stop listening to a stream that is not being listened to', () {
      expect(
        () => client1.sendRequest('streamCancel', {
          "streamId": streamId,
        }),
        throwsA(
          predicate(
            (e) =>
                e is RpcException &&
                e.code == RpcErrorCodes.kStreamNotSubscribed,
          ),
        ),
      );
    });

    test('postEvent when there are no listeners', () async {
      final postResult = await client2.sendRequest(
        'postEvent',
        {
          'streamId': streamId,
          'eventKind': eventKind,
          'eventData': eventData,
        },
      );
      expect(postResult, {"type": "Success"});
    });
  });

  group('service methods', () {
    final service1 = 'foo1';
    final method1 = 'bar1';
    final method2 = 'bar2';
    final data1 = {"data": 1};
    final response1 = {"response": 1};

    test('basics', () async {
      client1.registerMethod('$service1.$method1', (Parameters parameters) {
        return response1;
      });
      final registerResult = await client1.sendRequest('registerService', {
        "service": service1,
        "method": method1,
      });

      expect(registerResult, {"type": "Success"});

      final register2Result = await client1.sendRequest('registerService', {
        "service": service1,
        "method": method2,
      });
      expect(register2Result, {"type": "Success"});

      final methodResponse = await client2.sendRequest(
        '$service1.$method1',
        data1,
      );
      expect(methodResponse, response1);
    });

    test('registering a service method that already exists', () async {
      final registerResult = await client1.sendRequest('registerService', {
        "service": service1,
        "method": method1,
      });

      expect(registerResult, {"type": "Success"});
      expect(
        () => client1.sendRequest('registerService', {
          "service": service1,
          "method": method1,
        }),
        throwsA(
          predicate(
            (p0) =>
                p0 is RpcException &&
                p0.code == RpcErrorCodes.kServiceMethodAlreadyRegistered,
          ),
        ),
      );
    });

    test('calling a method that does not exist', () {
      expect(
        () => client1.sendRequest('zoo.abc', {}),
        throwsA(
          predicate(
            (p0) =>
                p0 is RpcException &&
                p0.code == RpcException.methodNotFound('zoo.abc').code,
          ),
        ),
      );
    });

    test('different clients cannot register the same service', () async {
      final registerResult = await client1.sendRequest('registerService', {
        "service": service1,
        "method": method1,
      });
      expect(registerResult, {"type": "Success"});

      expect(
        () => client2.sendRequest('registerService', {
          "service": service1,
          "method": method2,
        }),
        throwsA(
          predicate(
            (p0) =>
                p0 is RpcException &&
                p0.code == RpcErrorCodes.kServiceAlreadyRegistered,
          ),
        ),
      );
    });

    test('releases service methods on disconnect', () async {
      final registerResult = await client1.sendRequest('registerService', {
        "service": service1,
        "method": method1,
      });
      expect(registerResult, {"type": "Success"});

      await client1.close();

      // TODO: replace this polling when notification streams are implemented.

      dynamic client2RegisterResult;
      for (var i = 0; i < 10; i++) {
        try {
          // The service method registration should succeed once client1
          // finishes closing.
          client2RegisterResult = await client2.sendRequest('registerService', {
            "service": service1,
            "method": method1,
          });
          break;
        } catch (_) {}
        await Future.delayed(Duration(seconds: 1));
      }
      expect(client2RegisterResult, {"type": "Success"});
    });
  });
}

Peer _createClient(String uri) {
  final channel = WebSocketChannel.connect(
    Uri.parse(uri),
  );

  final client = Peer(channel.cast());
  unawaited(client.listen());
  return client;
}
