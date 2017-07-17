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

    expect(vm.services, isEmpty,
        reason: 'No service should be registered at startup');

    WebSocket _socket =
        await WebSocket.connect((vm as WebSocketVM).target.networkAddress);

    final socket = new StreamController();

    // Avoid to manually encode and decode messages from the stream
    socket.stream.map(JSON.encode).pipe(_socket);
    final client = _socket.map(JSON.decode).asBroadcastStream();

    // Note: keep this in sync with sdk/lib/vmservice.dart
    const kServiceAlreadyRegistered = 110;
    const kServiceAlreadyRegistered_Msg = 'Service already registered';

    const serviceName = 'serviceName';
    const serviceAlias = 'serviceAlias';

    {
      // Registering first service
      socket.add({
        'jsonrpc': '2.0',
        'method': '_registerService',
        'params': {'service': serviceName, 'alias': serviceAlias}
      });

      await serviceEvents.first;

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
        'method': '_registerService',
        'params': {'service': serviceName + '2', 'alias': serviceAlias + '2'}
      });

      await serviceEvents.first;

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
        'method': '_registerService',
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

main(args) => runIsolateTests(args, tests);
