#library('WebSocketTest');
#import('../../../../lib/unittest/unittest_dom.dart');
#import('dart:dom');

main() {

  forLayoutTests();

  test('constructorTest', () {
      var socket = new WebSocket('ws://localhost');
      Expect.isTrue(socket != null);
      Expect.isTrue(socket is WebSocket);
  });
}
