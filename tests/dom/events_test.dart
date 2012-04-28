#library('EventsTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/dom_config.dart');
#import('dart:dom');

main() {
  useDomConfiguration();
  test('TimeStamp', () {
    Event event = document.createEvent('Event');

    int timeStamp = event.timeStamp;
    Expect.isTrue(timeStamp > 0);
  });
  // The next test is not asynchronous because [dispatchEvent] fires the event
  // and event listener synchronously.
  test('EventTarget', () {
    HTMLElement element = window.document.createElement('test');
    element.id = 'eventtarget';
    window.document.body.appendChild(element);

    int invocationCounter = 0;
    void handler(Event e) {
      Expect.equals('test', e.type);
      HTMLElement target = e.target;
      Expect.identical(element, target);
      invocationCounter++;
    }

    Event event = window.document.createEvent('Event');
    event.initEvent('test', true, false);

    invocationCounter = 0;
    element.dispatchEvent(event);
    Expect.equals(0, invocationCounter);

    element.addEventListener('test', handler, false);
    invocationCounter = 0;
    element.dispatchEvent(event);
    Expect.equals(1, invocationCounter);

    element.removeEventListener('test', handler, false);
    invocationCounter = 0;
    element.dispatchEvent(event);
    Expect.equals(0, invocationCounter);

    element.addEventListener('test', handler, false);
    invocationCounter = 0;
    element.dispatchEvent(event);
    Expect.equals(1, invocationCounter);

    element.addEventListener('test', handler, false);
    invocationCounter = 0;
    element.dispatchEvent(event);
    Expect.equals(1, invocationCounter);
  });
  test('InitMouseEvent', () {
    HTMLDivElement div = window.document.createElement('div');
    MouseEvent event = window.document.createEvent('MouseEvent');
    event.initMouseEvent('zebra', true, true, window, 0, 1, 2, 3, 4, false, false, false, false, 0, div);
  });
}
