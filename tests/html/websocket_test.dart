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

      test('regression for 19137', () {
        // The server supports ws, but not wss, this will yield an error that we
        // expect to catch below.
        var socket = new WebSocket('wss://${window.location.host}/ws');
        socket.onOpen.first.then((_) => socket.send('hello!'));
        return socket.onError.first.then((e) {
          // This test is modeled after a comment in issue #19137. We haven't
          // verified that this is the casue, but the theory is that on Safari
          // we will reach this point correctly, we then try to get an
          // interceptor for `e` to call `.toString` on it, but our
          // get-interceptor logic crashes.  This is because the process of
          // finding the interceptor may ask to extract the constructor name,
          // and that code assumes that the name matches a specific regular
          // expression.  Apparently that regular expression doesn't match on
          // Safari 7 and the line below would ends up throwing and error of the
          // form:
          //
          //   TypeError: null is not an object (evaluating
          //     'String(a.constructor).match(/^\s*function\s*([\w$]*)\s*\(/)')
          //     at ...
          //
          print('$e was caught');
          socket.close();
        });
      });
    }
  });
}
