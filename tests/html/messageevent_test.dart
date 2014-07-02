library SerializedScriptValueTest;
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();

  test('new MessageEvent', () {
      final event = new MessageEvent('type', cancelable: true, data: 'data',
          origin: 'origin', lastEventId: 'lastEventId');

      expect(event.type, equals('type'));
      expect(event.bubbles, isFalse);
      expect(event.cancelable, isTrue);
      expect(event.data, equals('data'));
      expect(event.origin, equals('origin'));
      // IE allows setting this but just ignores it.
      // expect(event.lastEventId, equals('lastEventId'));
      expect(event.source, same(window));
      // TODO(antonm): accessing ports is not supported yet.
  });
}
