#library('DOMParserTest');
#import('../../../../lib/unittest/unittest.dart');
#import('../../../../lib/unittest/dom_config.dart');
#import('dart:dom');

main() {

  useDomConfiguration();

  test('constructorTest', () {
      var ctx = new DOMParser();
      Expect.isTrue(ctx != null);
      Expect.isTrue(ctx is DOMParser);
  });
}
