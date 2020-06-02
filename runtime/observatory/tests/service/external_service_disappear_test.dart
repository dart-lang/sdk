// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';
import 'dart:io' show WebSocket;
import 'dart:convert' show jsonDecode, jsonEncode;
import 'dart:async' show Future, Stream, StreamController;

var tests = <IsolateTest>[
  (Isolate isolate) async {
    VM vm = isolate.owner as VM;

    final serviceEvents =
        (await vm.getEventStream('Service')).asBroadcastStream();

    WebSocket _socket =
        await WebSocket.connect((vm as WebSocketVM).target.networkAddress);

    final socket = new StreamController();

    // Avoid to manually encode and decode messages from the stream
    Stream<String> stream = socket.stream.map(jsonEncode);
    stream.cast<dynamic>().pipe(_socket);
    dynamic _decoder(dynamic obj) {
      return jsonDecode(obj);
    }

    final client = _socket.map(_decoder).asBroadcastStream();

    // Note: keep this in sync with sdk/lib/vmservice.dart
    const kServiceDisappeared = 112;
    const kServiceDisappeared_Msg = 'Service has disappeared';

    const serviceName = 'disapearService';
    const serviceAlias = 'serviceAlias';
    const paramKey = 'pkey';
    const paramValue = 'pvalue';
    const repetition = 5;

    socket.add({
      'jsonrpc': '2.0',
      'id': 1,
      'method': 'registerService',
      'params': {'service': serviceName, 'alias': serviceAlias}
    });

    // Avoid flaky test.
    // We cannot assume the order in which two messages will arrive
    // from two different sockets
    await Future.wait([client.first, serviceEvents.first]);

    // Testing invocation of service which disappear
    {
      final results = new List<Future<Map>>.generate(repetition, (iteration) {
        final end = iteration.toString();
        return vm.invokeRpcRaw(
            vm.services.first.method, {paramKey + end: paramValue + end});
      });
      final requests = await (client.take(repetition).toList());

      requests.forEach((final request) {
        final iteration = requests.indexOf(request);
        final end = iteration.toString();

        // check requests while they arrive
        expect(request, contains('id'));
        expect(request['id'], isNotNull);
        expect(request['method'], equals(serviceName));
        expect(request['params'], isNotNull);
        expect(request['params'][paramKey + end], equals(paramValue + end));
      });

      await socket.close();

      await Future.wait(results.map((future) {
        return future.then((_) {
          expect(false, isTrue, reason: 'shouldn\'t get here');
        }).catchError((Object error_object) {
          ServerRpcException error = error_object as ServerRpcException;
          expect(error, isNotNull);
          expect(error.code, equals(kServiceDisappeared));
          expect(error.message, equals(kServiceDisappeared_Msg));
        });
      }));
    }
  },
];

main(args) => runIsolateTests(
      args,
      tests,
    );
