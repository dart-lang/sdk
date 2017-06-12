library WebSocketTest;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';
import 'dart:html';

main() {
  useHtmlIndividualConfiguration();

  group('supported', () {
    test('supported', () {
      expect(WebSocket.supported, true);
    });
  });

  group('websocket', () {
    var isWebSocket = predicate((x) => x is WebSocket, 'is a WebSocket');
    var expectation = WebSocket.supported ? returnsNormally : throws;

    test('constructorTest', () {
      expect(() {
        var socket = new WebSocket('ws://localhost/ws', 'chat');
        expect(socket, isNotNull);
        expect(socket, isWebSocket);
      }, expectation);
    });

    if (WebSocket.supported) {
      test('echo', () {
        var socket = new WebSocket('ws://${window.location.host}/ws');

        socket.onOpen.first.then((_) {
          socket.send('hello!');
        });

        return socket.onMessage.first.then((MessageEvent e) {
          expect(e.data, 'hello!');
          socket.close();
        });
      });

      test('error handling', () {
        var socket = new WebSocket('ws://${window.location.host}/ws');
        socket.onOpen.first.then((_) => socket.send('close-with-error'));
        return socket.onError.first.then((e) {
          print('$e was caught, yay!');
          socket.close();
        });
      });
    }
  });
}
