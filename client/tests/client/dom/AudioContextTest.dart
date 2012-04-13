#library('AudioContextTest');
#import('../../../../lib/unittest/unittest.dart');
#import('../../../../lib/unittest/dom_config.dart');
#import('dart:dom');

main() {

  useDomConfiguration();

  test('constructorTest', () {
      var ctx = new AudioContext();
      Expect.isTrue(ctx != null);
      Expect.isTrue(ctx is AudioContext);
  });
}
