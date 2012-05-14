#library('WebSocketTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/dom_config.dart');
#import('dart:dom_deprecated');

main() {

  useDomConfiguration();

  test('constructorTest', () {
      var socket = new WebSocket('ws://localhost');
      Expect.isTrue(socket != null);
      Expect.isTrue(socket is WebSocket);
  });
}
