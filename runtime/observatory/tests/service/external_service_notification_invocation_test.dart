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
    WebSocket _socket_invoker =
        await WebSocket.connect((vm as WebSocketVM).target.networkAddress);

    final socket = new StreamController<Map>();
    final socket_invoker = new StreamController<Map>();

    // Avoid to manually encode and decode messages from the stream
    Stream<String> socket_stream = socket.stream.map(jsonEncode);
    socket_stream.cast<dynamic>().pipe(_socket);
    Stream<String> socket_invoker_stream =
        socket_invoker.stream.map(jsonEncode);
    socket_invoker_stream.cast<dynamic>().pipe(_socket_invoker);
    dynamic _decoder(dynamic obj) {
      return jsonDecode(obj);
    }

    final client = _socket.map(_decoder).asBroadcastStream();
    final client_invoker = _socket_invoker.map(_decoder).asBroadcastStream();

    const serviceName = 'successService';
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

    client_invoker.first.then((_) {
      expect(false, isTrue, reason: 'shouldn\'t get here');
    }).catchError((_) => null);

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

main(args) => runIsolateTests(
      args,
      tests,
    );
