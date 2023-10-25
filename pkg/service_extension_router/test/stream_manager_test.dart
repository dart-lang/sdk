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

void main() {
  late TestStreamClient client;
  late StreamManager manager;
  group('Stream Manager', () {
    setUp(() {
      client = TestStreamClient();
      manager = StreamManager();
    });

    test('streamListen lets a client recieve messages for post', () {
      final message = {'message': 'A message'};
      manager.streamListen(client, 'A');

      manager.postEvent('B', {'message': 'B message'});
      expect(client.streamNotifyCount, equals(0));
      expect(client.notification, isNull);

      manager.postEvent('A', message);
      expect(client.streamNotifyCount, equals(1));
      expect(client.notification, equals(message));
    });

    test('streamCancel removes the client from the stream', () {
      final messageA = {'message': 'Message A'};
      final messageA2 = {'message': 'Message A2'};

      final clientA2 = TestStreamClient();
      manager.streamListen(client, 'A');
      manager.streamListen(clientA2, 'A');

      manager.postEvent('A', messageA);

      expect(client.notification, equals(messageA));
      expect(client.streamNotifyCount, equals(1));
      expect(clientA2.notification, equals(messageA));
      expect(clientA2.streamNotifyCount, equals(1));

      manager.streamCancel(client, 'A');

      manager.postEvent('A', messageA2);

      expect(client.notification, equals(messageA));
      expect(client.streamNotifyCount, equals(1));
      expect(clientA2.notification, equals(messageA2));
      expect(clientA2.streamNotifyCount, equals(2));
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

      expect(client.streamNotifyCount, equals(1));
      expect(client.notification, equals(messageA));
      expect(clientA2.streamNotifyCount, equals(1));
      expect(clientA2.notification, equals(messageA));
      expect(clientB.streamNotifyCount, equals(0));
      expect(clientB.notification, isNull);

      manager.postEvent(
        'B',
        messageB,
      );
      expect(client.streamNotifyCount, equals(1));
      expect(client.notification, equals(messageA));
      expect(clientA2.streamNotifyCount, equals(1));
      expect(clientA2.notification, equals(messageA));
      expect(clientB.streamNotifyCount, equals(1));
      expect(clientB.notification, messageB);
    });
  });
}
