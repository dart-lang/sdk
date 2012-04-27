#library('AudioContextTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/html_config.dart');
#import('dart:html');

main() {

  useHtmlConfiguration();

  test('constructorTest', () {
      var ctx = new AudioContext();
      Expect.isTrue(ctx != null);
      Expect.isTrue(ctx is AudioContext);
  });
}
