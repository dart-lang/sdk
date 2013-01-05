library ExceptionsTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();
  test('DomException', () {
    try {
      window.webkitNotifications.createNotification('', '', '');
    } on DomException catch (e) {
      expect(e.code, DomException.SECURITY_ERR);
      expect(e.name, 'SecurityError');
      expect(e.message, 'SecurityError: DOM Exception 18');
    }
  });
  test('EventException', () {
    final event = new Event('Event');
    // Intentionally do not initialize it!
    try {
      document.$dom_dispatchEvent(event);
    } on EventException catch (e) {
      expect(e.code, EventException.UNSPECIFIED_EVENT_TYPE_ERR);
      expect(e.name, 'UNSPECIFIED_EVENT_TYPE_ERR');
      expect(e.message, 'UNSPECIFIED_EVENT_TYPE_ERR: DOM Events Exception 0');
    }
  });
}
