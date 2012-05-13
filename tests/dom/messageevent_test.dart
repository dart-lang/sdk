#library('SerializedScriptValueTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/dom_config.dart');
#import('dart:dom_deprecated');

main() {
  useDomConfiguration();

  test('MessageEvent.initMessageEvent', () {
      final event = document.createEvent('MessageEvent');
      event.initMessageEvent('type', false, true, 'data', 'origin', 'lastEventId', window, []);
      expect(event.type).equals('type');
      expect(event.bubbles).equals(false);
      expect(event.cancelable).equals(true);
      expect(event.data).equals('data');
      expect(event.origin).equals('origin');
      expect(event.lastEventId).equals('lastEventId');
      expect(event.source).same(window);
      // TODO(antonm): accessing ports is not supported yet.
  });
}
