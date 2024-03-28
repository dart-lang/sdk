// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dtd/dtd.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
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
    toolingDaemonProcess.kill();
    await clientA.close();
    await clientB.close();
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
      final response = await clientB.call('TestService', 'foo', params: params);
      expect(response.result, {'type': 'test', 'data': data, 'params': params});
    });
  });
}
