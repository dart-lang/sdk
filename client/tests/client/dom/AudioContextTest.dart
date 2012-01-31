#library('AudioContextTest');
#import('../../../testing/unittest/unittest.dart');
#import('dart:dom');

main() {

  forLayoutTests();

  test('constructorTest', () {
      var ctx = new AudioContext();
      Expect.isTrue(ctx != null);
      Expect.isTrue(ctx is AudioContext);
  });
}
