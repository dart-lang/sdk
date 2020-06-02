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

    expect(vm.services, isEmpty,
        reason: 'No service should be registered at startup');

    WebSocket _socket =
        await WebSocket.connect((vm as WebSocketVM).target.networkAddress);

    final socket = new StreamController();

    // Avoid to manually encode and decode messages from the stream
    Stream<String> socket_stream = socket.stream.map(jsonEncode);
    socket_stream.cast<dynamic>().pipe(_socket);
    dynamic _decoder(dynamic obj) {
      return jsonDecode(obj);
    }

    final client = _socket.map(_decoder).asBroadcastStream();

    // Note: keep this in sync with sdk/lib/vmservice.dart
    const kServiceAlreadyRegistered = 111;
    const kServiceAlreadyRegistered_Msg = 'Service already registered';

    const serviceName = 'serviceName';
    const serviceAlias = 'serviceAlias';

    {
      // Registering first service
      socket.add({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'registerService',
        'params': {'service': serviceName, 'alias': serviceAlias}
      });

      // Avoid flaky test.
      // We cannot assume the order in which two messages will arrive
      // from two different sockets
      final message =
          (await Future.wait([client.first, serviceEvents.first])).first;

      expect(message['id'], equals(1),
          reason: 'Should answer with the same id');
      expect(message['result'], isNotEmpty);
      expect(message['result']['type'], equals('Success'));

      expect(vm.services, isNotEmpty);
      expect(vm.services.length, equals(1));
      expect(vm.services.first.service, equals(serviceName));
      expect(vm.services.first.method, isNotEmpty);
      expect(vm.services.first.alias, equals(serviceAlias));
    }

    {
      // Registering second service
      socket.add({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'registerService',
        'params': {'service': serviceName + '2', 'alias': serviceAlias + '2'}
      });

      // Avoid flaky test.
      // We cannot assume the order in which two messages will arrive
      // from two different sockets
      final message =
          (await Future.wait([client.first, serviceEvents.first])).first;

      expect(message['id'], equals(1),
          reason: 'Should answer with the same id');
      expect(message['result'], isNotEmpty);
      expect(message['result']['type'], equals('Success'));

      expect(vm.services, isNotEmpty);
      expect(vm.services.length, equals(2));
      expect(vm.services[1].service, equals(serviceName + '2'));
      expect(vm.services[1].method, isNotEmpty);
      expect(vm.services[1].alias, equals(serviceAlias + '2'));
    }

    {
      // Double registering first service
      socket.add({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'registerService',
        'params': {'service': serviceName, 'alias': serviceAlias}
      });

      final message = await client.first;

      expect(message['id'], equals(1),
          reason: 'Should answer with the same id');
      expect(message['error'], isNotEmpty);
      expect(message['error']['code'], equals(kServiceAlreadyRegistered));
      expect(
          message['error']['message'], equals(kServiceAlreadyRegistered_Msg));
    }

    // Avoid flaky test.
    // We cannot assume the order in which two messages will arrive
    // from two different sockets
    await Future.wait([socket.close(), serviceEvents.take(2).last]);

    expect(vm.services, isEmpty,
        reason: 'Should unregister services when client disconnects');
  },
];

main(args) => runIsolateTests(
      args,
      tests,
    );
