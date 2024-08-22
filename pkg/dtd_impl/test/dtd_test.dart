// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dtd/dtd.dart' show RpcErrorCodes, kFileSystemServiceName;
import 'package:dtd_impl/dtd.dart';
import 'package:dtd_impl/src/dtd_stream_manager.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:test/test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  late Peer client;
  late DartToolingDaemon? dtd;
  late String uri;

  tearDown(() async {
    await dtd?.close();
  });

  group('auth tokens', () {
    test('forbids connections where the URI auth code is invalid', () async {
      dtd = await DartToolingDaemon.startService([]);
      expect(dtd!.uri!.path, isNotEmpty); // Has code.

      expect(
        () async => await WebSocket.connect(
          dtd!.uri!.replace(path: 'someInvalidCode').toString(),
        ),
        throwsA(
          isA<WebSocketException>().having(
            (e) => e.message,
            'message',
            matches(
              RegExp("^Connection to '.*' was not upgraded to websocket\$"),
            ),
          ),
        ),
      );
    });

    test('forbids connections where the URI auth code is missing', () async {
      dtd = await DartToolingDaemon.startService([]);

      expect(
        () async => await WebSocket.connect(
          dtd!.uri!.replace(path: '').toString(),
        ),
        throwsA(
          isA<WebSocketException>().having(
            (e) => e.message,
            'message',
            matches(
              RegExp("^Connection to '.*' was not upgraded to websocket\$"),
            ),
          ),
        ),
      );
    });

    test(
        'allows connections with no URI auth code if started with --disable-service-auth-codes',
        () async {
      dtd = await DartToolingDaemon.startService([
        '--disable-service-auth-codes',
      ]);

      expect(dtd!.uri!.path, isEmpty); // No code.

      // Expect no exception.
      final ws = await WebSocket.connect(dtd!.uri!.toString());
      await ws.close();
    });
  });

  group('dtd', () {
    setUp(() async {
      dtd = await DartToolingDaemon.startService([]);

      // Wait for server to start and print to the port to stdout.
      uri = dtd!.uri!.toString();

      client = _createClient(uri);
    });

    tearDown(() async {
      await client.close();
    });

    group('streams', () {
      final streamId = 'testStream';
      final eventKind = 'test';
      final eventData = {'the': 'data'};

      test('basics', () async {
        var completer = Completer<Map<Object?, Object?>>();
        client.registerMethod('streamNotify', (Parameters parameters) {
          completer.complete(parameters.asMap);
        });
        final listenResult = await client.sendRequest('streamListen', {
          "streamId": streamId,
        });

        expect(listenResult, {"type": "Success"});

        final postResult = await client.sendRequest(
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
          "timestamp": anything,
        });

        // Now cancel the stream
        completer = Completer<Map<Object?, Object?>>(); // Reset the completer
        final cancelResult = await client.sendRequest(
          'streamCancel',
          {
            'streamId': streamId,
          },
        );
        expect(cancelResult, {"type": "Success"});
        final postResult2 = await client.sendRequest(
          'postEvent',
          {
            'streamId': streamId,
            'eventKind': eventKind,
            'eventData': eventData,
          },
        );
        expect(postResult2, {"type": "Success"});
        expect(
          completer.future.timeout(
            const Duration(seconds: 1),
            onTimeout: () => throw TimeoutException('Timed out'),
          ),
          throwsA(isA<TimeoutException>()),
        );
      });

      test('streamListen the same stream', () async {
        final listenResult = await client.sendRequest('streamListen', {
          "streamId": streamId,
        });

        expect(listenResult, {"type": "Success"});

        expect(
          () => client.sendRequest('streamListen', {
            "streamId": streamId,
          }),
          throwsA(
            isA<RpcException>().having(
              (e) => e.code,
              'code',
              RpcErrorCodes.kStreamAlreadySubscribed,
            ),
          ),
        );
      });

      test('stop listening to a stream that is not being listened to', () {
        expect(
          () => client.sendRequest('streamCancel', {
            "streamId": streamId,
          }),
          throwsA(
            isA<RpcException>().having(
              (e) => e.code,
              'code',
              RpcErrorCodes.kStreamNotSubscribed,
            ),
          ),
        );
      });

      test('postEvent when there are no listeners', () async {
        final postResult = await client.sendRequest(
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
        client.registerMethod('$service1.$method1', (Parameters parameters) {
          return response1;
        });
        final registerResult = await client.sendRequest('registerService', {
          "service": service1,
          "method": method1,
        });

        expect(registerResult, {"type": "Success"});

        final register2Result = await client.sendRequest('registerService', {
          "service": service1,
          "method": method2,
        });
        expect(register2Result, {"type": "Success"});

        final methodResponse = await client.sendRequest(
          '$service1.$method1',
          data1,
        );
        expect(methodResponse, response1);
      });

      test('disallows dots in service name', () async {
        expect(
          () => client.sendRequest('registerService', {
            "service": "a.b",
            "method": method1,
          }),
          throwsA(
            isA<RpcException>().having(
              (e) => e.code,
              'code',
              RpcErrorCodes.kServiceNameInvalid,
            ),
          ),
        );
      });

      test('allows dots in service method name', () async {
        final registerResult = await client.sendRequest('registerService', {
          "service": service1,
          "method": "a.b",
        });

        expect(registerResult, {"type": "Success"});
      });

      test(
          'disconnecting while handling a service request returns an error to the caller',
          () async {
        // Register a never-completing request that client2 can call.
        final requestStartedCompleter = Completer<void>();
        client.registerMethod('$service1.$method1', (Parameters parameters) {
          requestStartedCompleter.complete(); // Signal the request has started.
          return Completer<void>().future; // Never complete.
        });
        final registerResult = await client.sendRequest('registerService', {
          "service": service1,
          "method": method1,
        });
        expect(registerResult, {"type": "Success"});

        // Begin a call to that method.
        final client2 = _createClient(uri);
        final responseFuture = client2.sendRequest('$service1.$method1', {});
        await requestStartedCompleter.future;

        // Disconnect client1 so it never responses.
        await client.close();

        // Expect that we complete with the expected RPC error.
        expect(
          responseFuture,
          throwsA(
            isA<RpcException>().having((e) => e.code, 'code', -32000).having(
                  (e) => e.data,
                  'data',
                  containsPair(
                    'full',
                    'Bad state: The client closed with pending request "$service1.$method1".',
                  ),
                ),
          ),
        );
      });

      test('registering a service method that already exists', () async {
        final registerResult = await client.sendRequest('registerService', {
          "service": service1,
          "method": method1,
        });

        expect(registerResult, {"type": "Success"});
        expect(
          () => client.sendRequest('registerService', {
            "service": service1,
            "method": method1,
          }),
          throwsA(
            isA<RpcException>().having(
              (e) => e.code,
              'code',
              RpcErrorCodes.kServiceMethodAlreadyRegistered,
            ),
          ),
        );
      });

      test('calling a method that does not exist', () {
        expect(
          () => client.sendRequest('zoo.abc', {}),
          throwsA(
            isA<RpcException>().having(
              (e) => e.code,
              'code',
              RpcException.methodNotFound('zoo.abc').code,
            ),
          ),
        );
      });

      test('calling a method without a dot', () {
        expect(
          () => client.sendRequest('abc', {}),
          throwsA(
            isA<RpcException>()
                .having(
                  (e) => e.code,
                  'code',
                  RpcException.methodNotFound('abc').code,
                )
                .having((e) => e.message, 'message', 'Unknown method "abc".'),
          ),
        );
      });

      test('different clients cannot register the same service', () async {
        final client2 = _createClient(uri);
        final registerResult = await client.sendRequest('registerService', {
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
            isA<RpcException>().having(
              (e) => e.code,
              'code',
              RpcErrorCodes.kServiceAlreadyRegistered,
            ),
          ),
        );
      });

      test('clients cannot register an internal service', () async {
        expect(
          () => client.sendRequest('registerService', {
            "service": kFileSystemServiceName,
            "method": method2,
          }),
          throwsA(
            isA<RpcException>()
                .having(
                  (e) => e.code,
                  'code',
                  RpcErrorCodes.kServiceAlreadyRegistered,
                )
                .having(
                  (e) => e.data,
                  'data',
                  containsPair(
                    'details',
                    'Service \'FileSystem\' is already registered as a DTD internal service.',
                  ),
                ),
          ),
        );
      });

      test('releases service methods on disconnect', () async {
        final client2 = _createClient(uri);
        final registerResult = await client.sendRequest('registerService', {
          "service": service1,
          "method": method1,
        });
        expect(registerResult, {"type": "Success"});

        await client.close();

        // TODO: replace this polling when notification streams are implemented.

        dynamic client2RegisterResult;
        for (var i = 0; i < 10; i++) {
          try {
            // The service method registration should succeed once the other
            // finishes closing.
            client2RegisterResult =
                await client2.sendRequest('registerService', {
              "service": service1,
              "method": method1,
            });
            break;
          } catch (_) {}
          await Future<void>.delayed(Duration(seconds: 1));
        }
        expect(client2RegisterResult, {"type": "Success"});
      });

      group('sends notifications', () {
        late Peer client2;

        setUp(() {
          client2 = _createClient(uri);
        });

        tearDown(() async {
          await client2.close();
        });

        test('when a service method is registered', () async {
          // Subscribe to the services stream.
          final serviceStream = StreamController<Map<Object?, Object?>>();
          client.registerMethod('streamNotify', (Parameters parameters) {
            if (parameters['streamId'].asString ==
                DTDStreamManager.servicesStreamId) {
              serviceStream.add(parameters.asMap);
            }
          });
          await client.sendRequest('streamListen', {
            'streamId': DTDStreamManager.servicesStreamId,
          });

          // Register a method on a second client.
          await client2.sendRequest(
            'registerService',
            {
              'service': service1,
              'method': method1,
              'capabilities': {'supportsFoo': true},
            },
          );

          // Expect we had a service registered event.
          final event = await serviceStream.stream.first;
          expect(event['streamId'], DTDStreamManager.servicesStreamId);
          expect(event['eventKind'], DTDStreamManager.serviceRegisteredId);
          expect(
            event['eventData'],
            {
              'service': 'foo1',
              'method': 'bar1',
              'capabilities': {'supportsFoo': true},
            },
          );
        });

        test('when a service method is registered before subscribing',
            () async {
          // Register a method on a second client _first_.
          await client2.sendRequest(
            'registerService',
            {
              'service': service1,
              'method': method1,
              'capabilities': {'supportsFoo': true},
            },
          );

          // Subscribe to the services stream.
          var serviceStream = StreamController<Map<Object?, Object?>>();
          client.registerMethod('streamNotify', (Parameters parameters) {
            if (parameters['streamId'].asString ==
                DTDStreamManager.servicesStreamId) {
              serviceStream.add(parameters.asMap);
            }
          });
          await client.sendRequest('streamListen', {
            'streamId': DTDStreamManager.servicesStreamId,
          });

          // Expect we had a service registered event.
          final event = await serviceStream.stream.first;
          expect(event['streamId'], DTDStreamManager.servicesStreamId);
          expect(event['eventKind'], DTDStreamManager.serviceRegisteredId);
          expect(
            event['eventData'],
            {
              'service': 'foo1',
              'method': 'bar1',
              'capabilities': {'supportsFoo': true},
            },
          );
        });

        test('when a service method is unregistered', () async {
          // Subscribe to the services stream.
          var serviceStream = StreamController<Map<Object?, Object?>>();
          client.registerMethod('streamNotify', (Parameters parameters) {
            if (parameters['streamId'].asString ==
                DTDStreamManager.servicesStreamId) {
              serviceStream.add(parameters.asMap);
            }
          });
          await client.sendRequest('streamListen', {
            'streamId': DTDStreamManager.servicesStreamId,
          });

          // Register a method on a second client and then close it so the
          // service is removed.
          await client2.sendRequest(
            'registerService',
            {
              'service': service1,
              'method': method1,
              'capabilities': {'supportsFoo': true},
            },
          );
          await client2.close();

          // Expect we had a service unregistered event (after the registered
          // event).
          final event = await serviceStream.stream.skip(1).first;
          expect(event['streamId'], DTDStreamManager.servicesStreamId);
          expect(event['eventKind'], DTDStreamManager.serviceUnregisteredId);
          expect(
            event['eventData'],
            {
              'service': 'foo1',
              'method': 'bar1',
              // No capabilities on unregister.
            },
          );
        });
      });
    });
  });

  group('dtd arguments', () {
    test('allow explicit port', () async {
      const testPort = 8123;
      dtd = await DartToolingDaemon.startService(['--port=$testPort']);
      uri = dtd!.uri!.toString();
      expect(Uri.parse(uri).port, testPort);
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
