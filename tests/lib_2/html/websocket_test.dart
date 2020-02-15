library WebSocketTest;

import 'dart:html';

import 'package:async_helper/async_minitest.dart';
import 'package:expect/minitest.dart' as minitest;

main() {
  group('supported', () {
    test('supported', () {
      expect(WebSocket.supported, true);
    });
  });

  group('websocket', () {
    var isWebSocket =
        minitest.predicate((x) => x is WebSocket, 'is a WebSocket');
    var expectation = WebSocket.supported ? minitest.returnsNormally : throws;

    test('constructorTest', () {
      minitest.expect(() {
        var socket = new WebSocket('ws://localhost/ws', 'chat');
        expect(socket, isNotNull);
        minitest.expect(socket, isWebSocket);
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
