#library('AudioContextTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

main() {

  useHtmlConfiguration();

  var isAudioContext =
      predicate((x) => x is AudioContext, 'is an AudioContext');

  test('constructorTest', () {
      var ctx = new AudioContext();
      expect(ctx, isNotNull);
      expect(ctx, isAudioContext);
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
