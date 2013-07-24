library ExceptionsTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();

  test('EventException', () {
    final event = new Event('Event');
    // Intentionally do not initialize it!
    try {
      document.dispatchEvent(event);
    } on DomException catch (e) {
      expect(e.name, DomException.INVALID_STATE);
    }
  });
}
