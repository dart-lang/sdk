#library('DOMIsolatesTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/html_config.dart');
#import('dart:html');
#import('dart:isolate');

isolateMain(port) {
  port.receive((msg, replyTo) {
    if (msg != 'check') {
      replyTo.send('wrong msg: $msg');
    }
    replyTo.send(window.location.toString());
    port.close();
  });
}

isolateMainTrampoline(port) {
  final childPortFuture = spawnDomIsolate(window, 'isolateMain');
  port.receive((msg, parentPort) {
    childPortFuture.then((childPort) {
      childPort.call(msg).then((response) {
        parentPort.send(response);
        port.close();
      });
    });
  });
}

main() {
  useHtmlConfiguration();

  final iframe = new Element.tag('iframe');
  document.body.nodes.add(iframe);

  asyncTest('Simple DOM isolate test', 1, () {
    spawnDomIsolate(iframe.contentWindow, 'isolateMain').then((sendPort) {
      sendPort.call('check').then((msg) {
        Expect.equals('about:blank', msg);
        callbackDone();
      });
    });
  });

  asyncTest('Nested DOM isolates test', 1, () {
    spawnDomIsolate(iframe.contentWindow, 'isolateMainTrampoline').then((sendPort) {
      sendPort.call('check').then((msg) {
        Expect.equals('about:blank', msg);
        callbackDone();
      });
    });
  });

  test('Null as target window', () {
    expectThrow(() => spawnDomIsolate(null, 'isolateMain'));
  });

  test('Not window as target window', () {
    expectThrow(() => spawnDomIsolate(document, 'isolateMain'));
  });
}
