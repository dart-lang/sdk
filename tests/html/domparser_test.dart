#library('DOMParserTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

main() {

  useHtmlConfiguration();

  test('constructorTest', () {
      var ctx = new DOMParser();
      Expect.isTrue(ctx != null);
      Expect.isTrue(ctx is DOMParser);
  });
}
