#library('DOMParserTest');
#import('../../../../lib/unittest/unittest_dom.dart');
#import('dart:dom');

main() {

  forLayoutTests();

  test('constructorTest', () {
      var ctx = new DOMParser();
      Expect.isTrue(ctx != null);
      Expect.isTrue(ctx is DOMParser);
  });
}
