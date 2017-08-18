// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';
import 'dart:io' show WebSocket;
import 'dart:convert' show JSON;
import 'dart:async' show Future, StreamController;

var tests = [
  (Isolate isolate) async {
    VM vm = isolate.owner;

    final serviceEvents =
        (await vm.getEventStream('_Service')).asBroadcastStream();

    WebSocket _socket =
        await WebSocket.connect((vm as WebSocketVM).target.networkAddress);
    WebSocket _socket_invoker =
        await WebSocket.connect((vm as WebSocketVM).target.networkAddress);

    final socket = new StreamController();
    final socket_invoker = new StreamController();

    // Avoid to manually encode and decode messages from the stream
    socket.stream.map(JSON.encode).pipe(_socket);
    socket_invoker.stream.map(JSON.encode).pipe(_socket_invoker);
    final client = _socket.map(JSON.decode).asBroadcastStream();
    final client_invoker = _socket_invoker.map(JSON.decode).asBroadcastStream();

    const serviceName = 'successService';
    const serviceAlias = 'serviceAlias';
    const paramKey = 'pkey';
    const paramValue = 'pvalue';
    const repetition = 5;

    socket.add({
      'jsonrpc': '2.0',
      'id': 1,
      'method': '_registerService',
      'params': {'service': serviceName, 'alias': serviceAlias}
    });

    // Avoid flaky test.
    // We cannot assume the order in which two messages will arrive
    // from two different sockets
    await Future.wait([client.first, serviceEvents.first]);

    client_invoker.first.then((_) {
      expect(false, isTrue, reason: 'shouldn\'t get here');
    }).catchError((e) => e);

    // Testing serial invocation of service which succedes
    for (var iteration = 0; iteration < repetition; iteration++) {
      final end = iteration.toString();
      socket_invoker.add({
        'jsonrpc': '2.0',
        'method': vm.services.first.method,
        'params': {paramKey + end: paramValue + end}
      });
      final request = await client.first;

      expect(request, contains('id'));
      expect(request['id'], isNotNull);
      expect(request['method'], equals(serviceName));
      expect(request['params'], isNotNull);
      expect(request['params'][paramKey + end], equals(paramValue + end));

      socket.add({'jsonrpc': '2.0', 'id': request['id'], 'result': {}});
    }

    await socket.close();
    await socket_invoker.close();
  },
];

main(args) => runIsolateTests(args, tests);
