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
      'method': 'registerService',
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
      'method': 'registerService',
      'params': {'service': errorServiceName, 'alias': serviceAlias}
    });

    // Avoid flaky test.
    // We cannot assume the order in which two messages will arrive
    // from two different sockets
    await Future.wait([client.first, serviceEvents.first]);

    // Testing parallel invocation of service which succeeds
    {
      final results = new List<Future<Map>>.generate(repetition, (iteration) {
        final end = iteration.toString();
        return vm.invokeRpcRaw(
            vm.services.first.method, {paramKey + end: paramValue + end});
      });
      final requests = await (client.take(repetition).toList());

      final completions = requests.map((final request) {
        final iteration = requests.indexOf(request);
        final end = iteration.toString();

        // check requests while they arrive
        expect(request, contains('id'));
        expect(request['id'], isNotNull);
        expect(request['method'], equals(successServiceName));
        expect(request['params'], isNotNull);
        expect(request['params'][paramKey + end], equals(paramValue + end));

        // answer later
        return () => socket.add({
              'jsonrpc': '2.0',
              'id': request['id'],
              'result': {resultKey + end: resultValue + end}
            });
      }).toList();
      // random order
      completions.shuffle();
      // answer out of order
      completions.forEach((complete) => complete());

      final responses = await Future.wait(results);
      responses.forEach((final response) {
        final iteration = responses.indexOf(response);
        final end = iteration.toString();

        expect(response, isNotNull);
        expect(response[resultKey + end], equals(resultValue + end));
      });
    }

    // Testing parallel invocation of service which fails
    {
      final results = new List<Future<Map>>.generate(repetition, (iteration) {
        final end = iteration.toString();
        return vm.invokeRpcRaw(
            vm.services[1].method, {paramKey + end: paramValue + end});
      });
      final requests = await (client.take(repetition).toList());

      final completions = requests.map((final request) {
        final iteration = requests.indexOf(request);
        final end = iteration.toString();

        // check requests while they arrive
        expect(request, contains('id'));
        expect(request['id'], isNotNull);
        expect(request['method'], equals(errorServiceName));
        expect(request['params'], isNotNull);
        expect(request['params'][paramKey + end], equals(paramValue + end));

        // answer later
        return () => socket.add({
              'jsonrpc': '2.0',
              'id': request['id'],
              'error': {
                'code': errorCode + iteration,
                'data': {errorKey + end: errorValue + end},
                'message': 'error message',
              }
            });
      }).toList();
      // random order
      completions.shuffle();
      // answer out of order
      completions.forEach((complete) => complete());

      final errors = await Future.wait(results.map((future) {
        return future.then<dynamic>((_) {
          expect(false, isTrue, reason: 'shouldn\'t get here');
        }).catchError((e) => e);
      }));
      errors.forEach((dynamic error) {
        final iteration = errors.indexOf(error);
        final end = iteration.toString();

        expect(error, isNotNull);
        expect(error.code, equals(errorCode + iteration));
        expect(error.data, isNotNull);
        expect(error.data[errorKey + end], equals(errorValue + end));
      });
    }

    await socket.close();
  },
];

main(args) => runIsolateTests(
      args,
      tests,
    );
