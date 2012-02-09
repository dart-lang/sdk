#library('DOMParserTest');
#import('../../../testing/unittest/unittest.dart');
#import('dart:dom');

main() {

  forLayoutTests();

  test('constructorTest', () {
      var ctx = new DOMParser();
      Expect.isTrue(ctx != null);
      Expect.isTrue(ctx is DOMParser);
  });
}
