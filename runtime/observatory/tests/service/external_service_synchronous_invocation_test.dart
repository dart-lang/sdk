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

    final socket = new StreamController();

    // Avoid to manually encode and decode messages from the stream
    socket.stream.map(JSON.encode).pipe(_socket);
    final client = _socket.map(JSON.decode).asBroadcastStream();

    const successServiceName = 'successService';
    const errorServiceName = 'errorService';
    const serviceAlias = 'serviceAlias';
    const paramKey = 'pkey';
    const paramValue = 'pvalue';
    const resultKey = 'rkey';
    const resultValue = 'rvalue';
    const errorCode = 5000;
    const errorKey = 'ekey';
    const errorValue = 'evalue';
    const repetition = 5;

    socket.add({
      'jsonrpc': '2.0',
      'id': 1,
      'method': '_registerService',
      'params': {'service': successServiceName, 'alias': serviceAlias}
    });

    // Avoid flaky test.
    // We cannot assume the order in which two messages will arrive
    // from two different sockets
    await Future.wait([client.first, serviceEvents.first]);

    // Registering second service
    socket.add({
      'jsonrpc': '2.0',
      'id': 1,
      'method': '_registerService',
      'params': {'service': errorServiceName, 'alias': serviceAlias}
    });

    // Avoid flaky test.
    // We cannot assume the order in which two messages will arrive
    // from two different sockets
    await Future.wait([client.first, serviceEvents.first]);

    // Testing serial invocation of service which succeeds
    for (var iteration = 0; iteration < repetition; iteration++) {
      final end = iteration.toString();
      final result = vm.invokeRpcRaw(
          vm.services.first.method, {paramKey + end: paramValue + end});
      final request = await client.first;

      expect(request, contains('id'));
      expect(request['id'], isNotNull);
      expect(request['method'], equals(successServiceName));
      expect(request['params'], isNotNull);
      expect(request['params'][paramKey + end], equals(paramValue + end));

      socket.add({
        'jsonrpc': '2.0',
        'id': request['id'],
        'result': {resultKey + end: resultValue + end}
      });

      final response = await result;

      expect(response, isNotNull);
      expect(response[resultKey + end], equals(resultValue + end));
    }

    // Testing serial invocation of service which fails
    for (var iteration = 0; iteration < repetition; iteration++) {
      final end = iteration.toString();
      final result = vm.invokeRpcRaw(
          vm.services[1].method, {paramKey + end: paramValue + end});
      final request = await client.first;

      expect(request, contains('id'));
      expect(request['id'], isNotNull);
      expect(request['method'], equals(errorServiceName));
      expect(request['params'], isNotNull);
      expect(request['params'][paramKey + end], equals(paramValue + end));

      socket.add({
        'jsonrpc': '2.0',
        'id': request['id'],
        'error': {
          'code': errorCode + iteration,
          'data': {errorKey + end: errorValue + end}
        }
      });

      try {
        final response = await result;
        expect(false, isTrue, reason: 'shouldn\'t get here');
      } on ServerRpcException catch (e) {
        expect(e.code, equals(errorCode + iteration));
        expect(e.data, isNotNull);
        expect(e.data[errorKey + end], equals(errorValue + end));
      }
    }
  },
];

main(args) => runIsolateTests(args, tests);
