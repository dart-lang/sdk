library EventsTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();
  test('TimeStamp', () {
    Event event = new Event('test');

    int timeStamp = event.timeStamp;
    expect(timeStamp, greaterThan(0));
  });
  // The next test is not asynchronous because [on['test'].dispatch(event)] fires the event
  // and event listener synchronously.
  test('EventTarget', () {
    Element element = new Element.tag('test');
    element.id = 'eventtarget';
    window.document.body.nodes.add(element);

    int invocationCounter = 0;
    void handler(Event e) {
      expect(e.type, equals('test'));
      Element target = e.target;
      expect(element, equals(target));
      invocationCounter++;
    }

    Event event = new Event('test');

    invocationCounter = 0;
    element.dispatchEvent(event);
    expect(invocationCounter, isZero);

    var provider = new EventStreamProvider<CustomEvent>('test');

    var sub = provider.forTarget(element).listen(handler);
    invocationCounter = 0;
    element.dispatchEvent(event);
    expect(invocationCounter, 1);

    sub.cancel();
    invocationCounter = 0;
    element.dispatchEvent(event);
    expect(invocationCounter, isZero);

    provider.forTarget(element).listen(handler);
    invocationCounter = 0;
    element.dispatchEvent(event);
    expect(invocationCounter, 1);

    provider.forTarget(element).listen(handler);
    invocationCounter = 0;
    element.dispatchEvent(event);
    expect(invocationCounter, 1);
  });
  test('InitMouseEvent', () {
    DivElement div = new Element.tag('div');
    MouseEvent event = new MouseEvent('zebra', relatedTarget: div);
  });
}
