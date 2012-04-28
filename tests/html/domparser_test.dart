#library('DOMParserTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/html_config.dart');
#import('dart:html');

main() {

  useHtmlConfiguration();

  test('constructorTest', () {
      var ctx = new DOMParser();
      Expect.isTrue(ctx != null);
      Expect.isTrue(ctx is DOMParser);
  });
}
