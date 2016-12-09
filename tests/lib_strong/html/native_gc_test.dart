library NativeGCTest;
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';

var testEvent = new EventStreamProvider<Event>('test');

main() {
  useHtmlConfiguration();

  test('EventListener', () {
      final int N = 1000000;
      final int M = 1000;

      var div;
      for (int i = 0; i < M; ++i) {
        // This memory should be freed when the listener below is
        // collected.
        List l = new List(N);

        // Record the iteration number.
        l[N - 1] = i;

        div = new Element.tag('div');
        testEvent.forTarget(div).listen((_) {
            // Only the final iteration's listener should be invoked.
            // Note: the reference to l keeps the entire list alive.
            expect(l[N - 1], M - 1);
          });
      }

      final event = new Event('test');
      div.dispatchEvent(event);
  });

  test('WindowEventListener', () {
    String message = 'WindowEventListenerTestPingMessage';

    Element testDiv = new DivElement();
    testDiv.id = '#TestDiv';
    document.body.append(testDiv);
    window.onMessage.listen((e) {
      if (e.data == message) testDiv.click();
    });

    for (int i = 0; i < 100; ++i) {
      triggerMajorGC();
    }

    testDiv.onClick.listen(expectAsync((e) {}));
    window.postMessage(message, '*');
  });
}

void triggerMajorGC() {
  List list = new List(1000000);
  Element div = new DivElement();
  div.onClick.listen((e) => print(list[0]));
}
