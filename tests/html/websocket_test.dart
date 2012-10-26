#library('WebSocketTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

main() {

  useHtmlConfiguration();

  var isWebSocket = predicate((x) => x is WebSocket, 'is a WebSocket');

  test('constructorTest', () {
      var socket = new WebSocket('ws://localhost');
      expect(socket, isNotNull);
      expect(socket, isWebSocket);
  });
}
