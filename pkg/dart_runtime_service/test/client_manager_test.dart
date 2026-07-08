// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

import 'utils/utilities.dart';

void main() {
  group('ClientManager:', () {
    late DartRuntimeService service;
    late ClientManager manager;

    setUp(() async {
      service = await createDartRuntimeServiceForTest(
        config: const DartRuntimeServiceOptions(enableLogging: true),
      );
      manager = service.clientManager;
    });

    test('findFirstClientThatHandlesService', () {
      const serviceName = 's1';

      expect(manager.findFirstClientThatHandlesService(serviceName), isNull);

      final controller1 = StreamChannelController<String>();
      final client1 = manager.addClient(connection: controller1.foreign);
      client1.registerService(service: serviceName, alias: 'Service 1');

      expect(
        manager.findFirstClientThatHandlesService(serviceName),
        equals(client1),
      );
    });

    test('Client send methods on closed channel throw '
        'RpcException.serviceDisappeared', () async {
      final controller = StreamChannelController<String>();
      final client = manager.addClient(connection: controller.foreign);

      // Close the channel to simulate disconnection.
      await controller.local.sink.close();

      expect(
        () async => await client.sendRequest(method: 'someMethod'),
        throwsA(
          isA<json_rpc.RpcException>().having(
            (e) => e.code,
            'code',
            equals(RpcException.serviceDisappeared.code),
          ),
        ),
      );
    });

    test('onClientNameChanged is called on client.setName', () {
      var callbackInvoked = false;
      String? oldNameParam;
      String? newNameParam;

      final testManager = TestClientManager(
        backend: manager.backend,
        eventStreamMethods: manager.eventStreamMethods,
        onNameChanged: (c, oldName, newName) {
          callbackInvoked = true;
          oldNameParam = oldName;
          newNameParam = newName;
        },
      );

      final controller2 = StreamChannelController<String>();
      final testClient = testManager.addClient(connection: controller2.foreign);
      final testClientInitialName = testClient.name;
      const newName = 'customName';
      testClient.setName(newName);

      expect(callbackInvoked, isTrue);
      expect(oldNameParam, equals(testClientInitialName));
      expect(newNameParam, equals(newName));
    });
  });
}

final class TestClientManager extends ClientManager {
  TestClientManager({
    required super.backend,
    required super.eventStreamMethods,
    required this.onNameChanged,
  });

  final void Function(Client client, String oldName, String newName)
  onNameChanged;

  @override
  void onClientNameChanged(
    Client client, {
    required String oldName,
    required String newName,
  }) {
    onNameChanged(client, oldName, newName);
  }
}
