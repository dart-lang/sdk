import 'dart:html';

import 'package:expect/minitest.dart';

main() {
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
