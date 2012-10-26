#library('DocumentTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();

  var isElement = predicate((x) => x is Element, 'is an Element');
  var isDivElement = predicate((x) => x is DivElement, 'is a DivElement');
  var isAnchorElement =
      predicate((x) => x is AnchorElement, 'is an AnchorElement');
  var isUnknownElement = predicate((x) => x is Element, 'is UnknownElement');

  test('CreateElement', () {
    // FIXME: nifty way crashes, do it boring way.
    expect(new Element.tag('span'), isElement);
    expect(new Element.tag('div'), isDivElement);
    expect(new Element.tag('a'), isAnchorElement);
    expect(new Element.tag('bad_name'), isUnknownElement);
  });
}
