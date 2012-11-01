library IsolatesTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';
import 'dart:json';
import 'dart:isolate' as isolate;

String responseFor(message) => 'response for $message';

void isolateEntry() {
  bool wasThrown = false;
  try {
    window.alert('Test');
  } catch (e) {
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
        expect(response, equals(responseFor(msg1)));
        port.call(msg2).then((response) {
          guardAsync(() {
            expect(response, equals(responseFor(msg2)));
            callback();
          });
        });
      });
    });
  });
}
