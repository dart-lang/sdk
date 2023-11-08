// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:service_extension_router/src/client.dart';
import 'package:service_extension_router/src/stream_manager.dart';

import 'package:test/test.dart';

class TestStreamClient extends Client {
  int closeCount = 0;
  int sendRequestCount = 0;
  int streamNotifyCount = 0;
  Map<String, dynamic>? notification;

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
  void streamNotify(String stream, Map<String, Object?> data) {
    streamNotifyCount++;
    notification = data;
  }
}

class StreamManagerWithFailingStreamCancel extends StreamManager {
  final testException = FormatException('This is a test exception');
  @override
  // ignore: must_call_super
  Future<void> streamCancel(Client client, String stream) {
    return Future.error(testException);
  }
}

class TestStreamManager extends StreamManager {}

void main() {
  late TestStreamClient client;
  late StreamManager manager;

  group('Stream Manager', () {
    setUp(() {
      client = TestStreamClient();
      manager = TestStreamManager();
    });

    test('streamListen lets a client recieve messages for post', () {
      final message = {'message': 'A message'};
      manager.streamListen(client, 'A');

      manager.postEvent('B', {'message': 'B message'});
      expect(client.streamNotifyCount, 0);
      expect(client.notification, isNull);

      manager.postEvent('A', message);
      expect(client.streamNotifyCount, 1);
      expect(client.notification, message);
    });

    test('streamCancel removes the client from the stream', () {
      final messageA = {'message': 'Message A'};
      final messageA2 = {'message': 'Message A2'};

      final clientA2 = TestStreamClient();
      manager.streamListen(client, 'A');
      manager.streamListen(clientA2, 'A');

      manager.postEvent('A', messageA);

      expect(client.notification, messageA);
      expect(client.streamNotifyCount, 1);
      expect(clientA2.notification, messageA);
      expect(clientA2.streamNotifyCount, 1);
      expect(manager.isSubscribed(client, 'A'), isTrue);

      manager.streamCancel(client, 'A');

      manager.postEvent('A', messageA2);

      expect(client.notification, messageA);
      expect(client.streamNotifyCount, 1);
      expect(clientA2.notification, messageA2);
      expect(clientA2.streamNotifyCount, 2);
      expect(manager.isSubscribed(client, 'A'), isFalse);
    });

    test('postEvent notifies clients', () {
      final messageA = {'message': 'Message A'};
      final messageB = {'message': 'Message B'};
      final clientA2 = TestStreamClient();
      final clientB = TestStreamClient();
      manager.streamListen(client, 'A');
      manager.streamListen(clientA2, 'A');
      manager.streamListen(clientB, 'B');

      manager.postEvent(
        'A',
        messageA,
      );

      expect(client.streamNotifyCount, 1);
      expect(client.notification, messageA);
      expect(clientA2.streamNotifyCount, 1);
      expect(clientA2.notification, messageA);
      expect(clientB.streamNotifyCount, 0);
      expect(clientB.notification, isNull);

      manager.postEvent(
        'B',
        messageB,
      );
      expect(client.streamNotifyCount, 1);
      expect(client.notification, messageA);
      expect(clientA2.streamNotifyCount, 1);
      expect(clientA2.notification, messageA);
      expect(clientB.streamNotifyCount, 1);
      expect(clientB.notification, messageB);
    });

    test('onClientDisconnect cancels a client from all streams', () async {
      final testClient = TestStreamClient();
      final aClients = [
        TestStreamClient(),
        TestStreamClient(),
        TestStreamClient()
      ];
      final bClients = [
        TestStreamClient(),
        TestStreamClient(),
      ];

      for (final client in aClients) {
        manager.streamListen(client, 'A');
      }
      for (final client in bClients) {
        manager.streamListen(client, 'B');
      }
      manager.streamListen(testClient, 'A');
      manager.streamListen(testClient, 'B');
      manager.streamListen(testClient, 'C');

      expect(manager.getListenersFor(stream: 'A'), [...aClients, testClient]);
      expect(manager.getListenersFor(stream: 'B'), [...bClients, testClient]);
      expect(manager.getListenersFor(stream: 'C'), [testClient]);

      await manager.onClientDisconnect(testClient);

      expect(manager.getListenersFor(stream: 'A'), aClients);
      expect(manager.getListenersFor(stream: 'B'), bClients);
      expect(manager.getListenersFor(stream: 'C'), []);
    });

    test('onClientDisconnect can ignore certain errors.', () async {
      manager = StreamManagerWithFailingStreamCancel();
      manager.streamListen(client, 'A');
      int caughtCount = 0;
      try {
        await manager.onClientDisconnect(client);
      } catch (e) {
        caughtCount++;
        expect(
            e, (manager as StreamManagerWithFailingStreamCancel).testException);
      }

      expect(caughtCount, 1);

      // We can ignore certain types of exceptions with onCatchErrorTest
      await manager.onClientDisconnect(client,
          onCatchErrorTest: (e) => e is FormatException);
    });
  });
}
