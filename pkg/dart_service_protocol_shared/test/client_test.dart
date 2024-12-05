// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_service_protocol_shared/src/client.dart';
import 'package:test/test.dart';

class TestClientManager extends ClientManager {}

class TestClient extends Client {
  int closeCount = 0;
  int sendRequestCount = 0;
  int streamNotifyCount = 0;

  @override
  Future<void> close() {
    closeCount++;
    return Future.value();
  }

  @override
  Future sendRequest({required String method, parameters}) {
    sendRequestCount++;
    return Future.value();
  }

  @override
  void streamNotify(String stream, Object data) {
    streamNotifyCount++;
  }
}

void main() {
  group('ClientManager', () {
    late ClientManager clientManager;
    setUp(() {
      clientManager = TestClientManager();
    });
    test('add and remove client', () {
      final client = TestClient();

      expect(clientManager.clients.length, 0);

      clientManager.addClient(client);

      expect(clientManager.clients.length, 1);
      expect(clientManager.clients.first, client);

      clientManager.removeClient(client);

      expect(clientManager.clients.length, 0);
    });

    test('client name', () {
      final client = TestClient();

      // Name unset until client is added to a manager
      expect(client.name, isNull);

      // Sets the client name to a default
      clientManager.addClient(client);
      final defaultClientName = client.name;
      expect(client.name?.startsWith('client'), isTrue);

      clientManager.setClientName(client, 'test');
      expect(client.name, 'test');

      clientManager.clearClientName(client);
      expect(client.name, defaultClientName);
    });

    test('findClientThatHandlesServiceMethod', () {
      final client1 = TestClient();
      final client2 = TestClient();
      client1.services['service1'] = ClientServiceInfo(
          'service1', {'method': ClientServiceMethodInfo('method')});
      client2.services['service2'] = ClientServiceInfo(
          'service2', {'method': ClientServiceMethodInfo('method')});
      clientManager.addClient(client1);
      clientManager.addClient(client2);

      expect(
        clientManager.findClientThatHandlesServiceMethod('service1', 'method'),
        client1,
      );
      expect(
        clientManager.findClientThatHandlesServiceMethod('service1', 'xxxxx'),
        isNull,
      );
      expect(
        clientManager.findClientThatHandlesServiceMethod('service2', 'method'),
        client2,
      );
      expect(
        clientManager.findClientThatHandlesServiceMethod('xxxxx', 'method'),
        isNull,
      );
    });

    test('shutdown', () async {
      final client1 = TestClient();
      final client2 = TestClient();
      final client3 = TestClient();
      clientManager.addClient(client1);
      clientManager.addClient(client2);
      clientManager.addClient(client3);

      expect(client1.closeCount, 0);
      expect(client2.closeCount, 0);
      expect(client3.closeCount, 0);
      expect(
        clientManager.clients,
        unorderedEquals([
          client1,
          client2,
          client3,
        ]),
      );

      await clientManager.shutdown();

      expect(client1.closeCount, 1);
      expect(client2.closeCount, 1);
      expect(client3.closeCount, 1);
      expect(
        clientManager.clients,
        [],
      );
    });
  });
}
