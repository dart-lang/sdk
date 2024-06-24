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
      const message2 = {'message': 'greetings'};

      test('listen and cancel', () async {
        var clientBCompleter = Completer<DTDEvent>();

        await clientB.streamListen(notificationStream);

        clientB.onEvent(notificationStream).listen(clientBCompleter.complete);

        await clientA.postEvent(notificationStream, messageEvent, message1);
        final event = await clientBCompleter.future;
        expect(event.data, message1);

        clientBCompleter = Completer<DTDEvent>();

        // Now test stream Cancel
        await clientB.streamCancel(notificationStream);
        await clientA.postEvent(notificationStream, messageEvent, message2);

        expect(
          clientBCompleter.future.timeout(
            const Duration(seconds: 1),
            onTimeout: () {
              throw TimeoutException('Timed out');
            },
          ),
          throwsA(predicate((p0) => p0 is TimeoutException)),
        );
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
    });
  });

  test('dtd can use streams directly', () async {
    const exampleEventToSend = {
      'jsonrpc': '2.0',
      'method': 'streamNotify',
      'params': {
        'streamId': 'testStream',
        'eventKind': 'x',
        'eventData': <String, Object?>{'foo': 'bar'},
        'timestamp': 1,
      },
    };
    const exampleCallToReceive = {
      'jsonrpc': '2.0',
      'method': 'foo.bar',
      'id': 0,
      'params': <String, Object?>{},
    };

    final clientToServer = StreamController<String>();
    final serverToClient = StreamController<String>();
    final channel = StreamChannel(serverToClient.stream, clientToServer.sink);
    final client = DartToolingDaemon.fromStreamChannel(channel);

    // Send a notification over the stream to the client and ensure it gets it.
    serverToClient.add(jsonEncode(exampleEventToSend));
    final clientReceivedEvent = await client.onEvent('testStream').first;
    expect(clientReceivedEvent.data['foo'], 'bar');

    // Send a request and ensure it comes on the stream.
    // Discard "Connection closed with pending 'foo.bar'"" error because the
    // test doesn't respond to it.
    unawaited(
      client.call('foo', 'bar').onError((_, __) => DTDResponse('', '', {})),
    );
    expect(jsonDecode(await clientToServer.stream.first), exampleCallToReceive);
  });
}
