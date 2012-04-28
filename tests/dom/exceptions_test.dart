#library('ExceptionsTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/dom_config.dart');
#import('dart:dom');

main() {
  useDomConfiguration();
  test('DOMException', () {
    try {
      window.webkitNotifications.createNotification('', '', '');
    } catch (DOMException e) {
      Expect.equals(DOMException.SECURITY_ERR, e.code);
      Expect.equals('SECURITY_ERR', e.name);
      Expect.equals('SECURITY_ERR: DOM Exception 18', e.message);
    }
  });
  test('EventException', () {
    final event = window.document.createEvent('Event');
    // Intentionally do not initialize it!
    try {
      window.document.dispatchEvent(event);
    } catch (EventException e) {
      Expect.equals(EventException.UNSPECIFIED_EVENT_TYPE_ERR, e.code);
      Expect.equals('UNSPECIFIED_EVENT_TYPE_ERR', e.name);
      Expect.equals('UNSPECIFIED_EVENT_TYPE_ERR: DOM Events Exception 0', e.message);
    }
  });
}
