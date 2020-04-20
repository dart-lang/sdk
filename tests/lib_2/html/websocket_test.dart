library WebSocketTest;

import 'dart:html';

import 'package:async_helper/async_minitest.dart';

main() {
  group('supported', () {
    test('supported', () {
      expect(WebSocket.supported, true);
    });
  });

  group('websocket', () {
    var expectation = WebSocket.supported ? returnsNormally : throws;

    test('constructorTest', () {
      expect(() {
        var socket = new WebSocket('ws://localhost/ws', 'chat');
        expect(socket, isNotNull);
        expect(socket, isInstanceOf<WebSocket>());
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
