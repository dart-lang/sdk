library WebSocketTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_individual_config.dart';
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
        var socket = new WebSocket('ws://localhost');
        expect(socket, isNotNull);
        expect(socket, isWebSocket);
        }, expectation);
    });
  });
}
