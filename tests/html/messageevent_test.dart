#library('SerializedScriptValueTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();

  test('MessageEvent.initMessageEvent', () {
      final event = document.$dom_createEvent('MessageEvent');
      event.initMessageEvent('type', false, true, 'data', 'origin', 'lastEventId', window, []);
      expect(event.type, equals('type'));
      expect(event.bubbles, isFalse);
      expect(event.cancelable, isTrue);
      expect(event.data, equals('data'));
      expect(event.origin, equals('origin'));
      expect(event.lastEventId, equals('lastEventId'));
      expect(event.source, same(window));
      // TODO(antonm): accessing ports is not supported yet.
  });
}
