#library('AudioContextTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/html_config.dart');
#import('dart:html');

main() {

  useHtmlConfiguration();

  test('constructorTest', () {
      var ctx = new AudioContext();
      Expect.isNotNull(ctx);
      Expect.isTrue(ctx is AudioContext);
  });
  test('createBuffer', () {
      var ctx = new AudioContext();
      ArrayBufferView arrayBufferView = new Float32Array.fromList([]);
      try {
        // Test that native overload is chosen correctly. Native implementation
        // should throw 'SYNTAX_ERR' DOMException because the buffer is empty.
        AudioBuffer buffer = ctx.createBuffer(arrayBufferView.buffer, false);
      } catch(var e) {
        Expect.equals(DOMException.SYNTAX_ERR, e.code);
      }
  });
}
