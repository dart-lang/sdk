#library('WebSocketTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/html_config.dart');
#import('dart:html');

main() {

  useHtmlConfiguration();

  test('constructorTest', () {
      var socket = new WebSocket('ws://localhost');
      Expect.isTrue(socket != null);
      Expect.isTrue(socket is WebSocket);
  });
}
