#library('AudioContextTest');
#import('../../pkg/unittest/lib/unittest.dart');
#import('../../pkg/unittest/lib/html_config.dart');
#import('dart:html');

main() {

  useHtmlConfiguration();

  test('constructorTest', () {
      var ctx = new AudioContext();
      expect(ctx, isNotNull);
      expect(ctx is AudioContext);
  });
  test('createBuffer', () {
      var ctx = new AudioContext();
      ArrayBufferView arrayBufferView = new Float32Array.fromList([]);
      try {
        // Test that native overload is chosen correctly. Native implementation
        // should throw 'SYNTAX_ERR' DOMException because the buffer is empty.
        AudioBuffer buffer = ctx.createBuffer(arrayBufferView.buffer, false);
      } catch (e) {
        expect(e.code, equals(DOMException.SYNTAX_ERR));
      }
  });
}
