#library('DocumentTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();

  test('CreateElement', () {
    // FIXME: nifty way crashes, do it boring way.
    Expect.isTrue(new Element.tag('span') is Element);
    Expect.isTrue(new Element.tag('div') is DivElement);
    Expect.isTrue(new Element.tag('a') is AnchorElement);
    Expect.isTrue(new Element.tag('bad_name') is UnknownElement);
  });
}
