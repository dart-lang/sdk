#library('IsolatesTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');
#import('dart:json');
#import('dart:isolate', prefix:'isolate');

String responseFor(message) => 'response for $message';

void isolateEntry() {
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

  isolate.port.receive((message, replyTo) {
    replyTo.send(responseFor(message), null);
  });
}

main() {
  useHtmlConfiguration();
  test('IsolateSpawn', () {
    isolate.spawnFunction(isolateEntry);
  });
  test('NonDOMIsolates', () {
    var callback = expectAsync0((){});
    var port = isolate.spawnFunction(isolateEntry);
    final msg1 = 'foo';
    final msg2 = 'bar';
    port.call(msg1).then((response) {
      guardAsync(() {
        Expect.equals(responseFor(msg1), response);
        port.call(msg2).then((response) {
          guardAsync(() {
            Expect.equals(responseFor(msg2), response);
            callback();
          });
        });
      });
    });
  });
}
