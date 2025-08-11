// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:dtd/dtd.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('dtd', () {
    late DartToolingDaemon clientA;
    late DartToolingDaemon clientB;
    late Uri dtdUri;
    late ToolingDaemonTestProcess toolingDaemonProcess;

    setUp(() async {
      toolingDaemonProcess = ToolingDaemonTestProcess();
      await toolingDaemonProcess.start();
      dtdUri = toolingDaemonProcess.uri;

      clientA = await DartToolingDaemon.connect(dtdUri);
      clientB = await DartToolingDaemon.connect(dtdUri);
    });

    tearDown(() async {
      await clientA.close();
      await clientB.close();
      toolingDaemonProcess.kill();
    });

    group('streams', () {
      const notificationStream = 'notification_stream';
      const messageEvent = 'message';
      const message1 = {'message': 'hello'};

      test(CoreDtdServiceConstants.streamListen, () async {
        await clientB.streamListen(notificationStream);
        final eventFuture = clientB.onEvent(notificationStream).first;
        await clientA.postEvent(notificationStream, messageEvent, message1);
        final event = await eventFuture;
        expect(event.data, message1);
      });

      test(CoreDtdServiceConstants.streamCancel, () async {
        await clientB.streamListen(notificationStream);
        final eventFuture = clientB.onEvent(notificationStream).first;
        await clientB.streamCancel(notificationStream);
        await clientA.postEvent(notificationStream, messageEvent, message1);
        expect(
          eventFuture.timeout(
            const Duration(seconds: 1),
            onTimeout: () {
              throw TimeoutException('Timed out');
            },
          ),
          throwsA(predicate((p0) => p0 is TimeoutException)),
        );
      });

      test('can have multiple subscribers to a stream', () async {
        await clientB.streamListen(notificationStream);

        for (var i = 1; i <= 5; i++) {
          final event1Future = clientB.onEvent(notificationStream).first;
          final event2Future = clientB.onEvent(notificationStream).first;
          await clientA.postEvent(notificationStream, messageEvent, message1);
          expect((await event1Future).data, message1);
          expect((await event2Future).data, message1);
        }
      });
    });

    group('service methods', () {
      final data = {'some': 'data'};
      final params = {'a': 'param'};
      test('register and call', () async {
        await clientA.registerService(
          'TestService',
          'foo',
          (Parameters params) async {
            return {
              'type': 'test',
              'data': data,
              'params': params.asMap,
            };
          },
        );
        final response =
            await clientB.call('TestService', 'foo', params: params);
        expect(
          response.result,
          {'type': 'test', 'data': data, 'params': params},
        );
      });

      test(CoreDtdServiceConstants.getRegisteredServices, () async {
        await clientA.registerService(
          'TestService',
          'foo',
          (Parameters params) async {
            return {
              'type': 'test',
              'data': data,
              'params': params.asMap,
            };
          },
        );
        await clientA.registerService(
          'TestService',
          'bar',
          (Parameters params) async {
            return {
              'type': 'test',
              'data': data,
              'params': params.asMap,
            };
          },
          capabilities: {
            'language': 'french',
          },
        );
        await clientB.registerService(
          'OtherService',
          'foo',
          (Parameters params) async {
            return {
              'type': 'other',
              'data': data,
              'params': params.asMap,
            };
          },
          capabilities: {
            'skills': 'baking',
          },
        );

        final response = await clientA.getRegisteredServices();
        expect(
          response.toJson(),
          {
            'type': 'RegisteredServicesResponse',
            'dtdServices': [
              'streamListen',
              'streamCancel',
              'postEvent',
              'registerService',
              'getRegisteredServices',
              'ConnectedApp.registerVmService',
              'ConnectedApp.unregisterVmService',
              'ConnectedApp.getVmServices',
              'FileSystem.readFileAsString',
              'FileSystem.writeFileAsString',
              'FileSystem.listDirectoryContents',
              'FileSystem.setIDEWorkspaceRoots',
              'FileSystem.getIDEWorkspaceRoots',
              'FileSystem.getProjectRoots',
              'UnifiedAnalytics.getConsentMessage',
              'UnifiedAnalytics.shouldShowMessage',
              'UnifiedAnalytics.clientShowedMessage',
              'UnifiedAnalytics.telemetryEnabled',
              'UnifiedAnalytics.setTelemetry',
              'UnifiedAnalytics.send',
              'UnifiedAnalytics.listFakeAnalyticsSentEvents',
            ],
            'clientServices': [
              {
                'name': 'TestService',
                'methods': [
                  {
                    'name': 'foo',
                  },
                  {
                    'name': 'bar',
                    'capabilities': <String, Object?>{
                      'language': 'french',
                    },
                  }
                ],
              },
              {
                'name': 'OtherService',
                'methods': [
                  {
                    'name': 'foo',
                    'capabilities': <String, Object?>{
                      'skills': 'baking',
                    },
                  }
                ],
              },
            ],
          },
        );
      });
    });
  });

  test('dtd can use streams directly', () async {
    const exampleEventToSend = {
      'jsonrpc': '2.0',
      'method': CoreDtdServiceConstants.streamNotify,
      'params': {
        DtdParameters.streamId: 'testStream',
        DtdParameters.eventKind: 'x',
        DtdParameters.eventData: <String, Object?>{'foo': 'bar'},
        DtdParameters.timestamp: 1,
      },
    };

    final clientToServer = StreamController<String>();
    final serverToClient = StreamController<String>();
    final channel = StreamChannel(serverToClient.stream, clientToServer.sink);
    final client = DartToolingDaemon.fromStreamChannel(channel);

    // Send a notification over the stream to the client and ensure it gets it.
    serverToClient.add(jsonEncode(exampleEventToSend));
    final clientReceivedEvent = await client.onEvent('testStream').first;
    expect(clientReceivedEvent.data['foo'], 'bar');

    // Send requests and ensure they comes over the stream.
    // Discard "Connection closed with pending 'foo.bar'" errors because the
    // test doesn't respond to these.

    // Call service with no parameters.
    unawaited(
      client.call('foo', 'bar').onError((_, __) => DTDResponse('', '', {})),
    );
    // Call service with parameters.
    unawaited(
      client.call('foo', 'bar', params: {'test': 'test'}).onError(
        (_, __) => DTDResponse('', '', {}),
      ),
    );
    // Call method with null service.
    unawaited(
      client.call(null, 'bar').onError((_, __) => DTDResponse('', '', {})),
    );

    const expectedRequests = 3;
    final requestsReceived = <String>[];
    final allRequestsReceived = Completer<void>();

    StreamSubscription<String>? sub;
    sub = clientToServer.stream.asBroadcastStream().listen((request) {
      requestsReceived.add(request);
      if (requestsReceived.length == expectedRequests) {
        sub!.cancel();
        allRequestsReceived.complete();
      }
    });
    addTearDown(() => sub?.cancel());
    await allRequestsReceived.future;

    expect(
      jsonDecode(requestsReceived[0]),
      {'jsonrpc': '2.0', 'method': 'foo.bar', 'id': 0},
    );
    expect(
      jsonDecode(requestsReceived[1]),
      {
        'jsonrpc': '2.0',
        'method': 'foo.bar',
        'id': 1,
        'params': <String, Object?>{'test': 'test'},
      },
    );

    expect(
      jsonDecode(requestsReceived[2]),
      {'jsonrpc': '2.0', 'method': 'bar', 'id': 2},
    );
  });
}
