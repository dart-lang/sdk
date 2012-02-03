#library('IsolatesTest');
#import('../../../testing/unittest/unittest.dart');
#import('dart:dom');
#import('dart:json');

class PingPongIsolate extends Isolate {
  PingPongIsolate() : super.heavy();

  void main() {
    bool wasThrown = false;
    try {
      window.alert('Test');
    } catch(final e) {
      wasThrown = true;
    }
    // If wasn't thrown, do not listen to messages to make test fail.
    if (!wasThrown) {
      return;
    }

    // Check that JSON library was loaded to isolate.
    JSON.stringify([1, 2, 3]);

    port.receive((message, replyTo) {
      replyTo.send(responseFor(message), null);
    });
  }

  static String responseFor(message) => 'response for $message';
}

main() {
  forLayoutTests();
  asyncTest('IsolateSpawn', 1, () {
    new PingPongIsolate().spawn().then((SendPort port) {
      callbackDone();
    });
  });
  asyncTest('NonDOMIsolates', 1, () {
    new PingPongIsolate().spawn().then((SendPort port) {
      final msg1 = 'foo';
      final msg2 = 'bar';
      port.call(msg1).receive((response, _) {
        Expect.equals(PingPongIsolate.responseFor(msg1), response);
        port.call(msg2).receive((response, _) {
          Expect.equals(PingPongIsolate.responseFor(msg2), response);
          callbackDone();
        });
      });
    });
  });
}
