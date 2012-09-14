#library('EventsTest');
#import('../../pkg/unittest/lib/unittest.dart');
#import('../../pkg/unittest/lib/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();
  test('TimeStamp', () {
    Event event = new Event('test');

    int timeStamp = event.timeStamp;
    Expect.isTrue(timeStamp > 0);
  });
  // The next test is not asynchronous because [on['test'].dispatch(event)] fires the event
  // and event listener synchronously.
  test('EventTarget', () {
    Element element = new Element.tag('test');
    element.id = 'eventtarget';
    window.document.body.nodes.add(element);

    int invocationCounter = 0;
    void handler(Event e) {
      Expect.equals('test', e.type);
      Element target = e.target;
      Expect.identical(element, target);
      invocationCounter++;
    }

    Event event = new Event('test');

    invocationCounter = 0;
    element.on['test'].dispatch(event);
    Expect.equals(0, invocationCounter);

    element.on['test'].add(handler, false);
    invocationCounter = 0;
    element.on['test'].dispatch(event);
    Expect.equals(1, invocationCounter);

    element.on['test'].remove(handler, false);
    invocationCounter = 0;
    element.on['test'].dispatch(event);
    Expect.equals(0, invocationCounter);

    element.on['test'].add(handler, false);
    invocationCounter = 0;
    element.on['test'].dispatch(event);
    Expect.equals(1, invocationCounter);

    element.on['test'].add(handler, false);
    invocationCounter = 0;
    element.on['test'].dispatch(event);
    Expect.equals(1, invocationCounter);
  });
  test('InitMouseEvent', () {
    DivElement div = new Element.tag('div');
    MouseEvent event = document.$dom_createEvent('MouseEvent');
    event.$dom_initMouseEvent('zebra', true, true, window, 0, 1, 2, 3, 4, false, false, false, false, 0, div);
  });
}
