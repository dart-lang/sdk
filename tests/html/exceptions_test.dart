#library('ExceptionsTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();
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
    final event = new Event('Event');
    // Intentionally do not initialize it!
    try {
      document.$dom_dispatchEvent(event);
    } catch (EventException e) {
      Expect.equals(EventException.UNSPECIFIED_EVENT_TYPE_ERR, e.code);
      Expect.equals('UNSPECIFIED_EVENT_TYPE_ERR', e.name);
      Expect.equals('UNSPECIFIED_EVENT_TYPE_ERR: DOM Events Exception 0', e.message);
    }
  });
}
