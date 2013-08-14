part of dom_compat_test;

void registerDomCompatTests() {
  group('Element', () {
    test('outerHtml', () {
      final element = new Element.tag('div');
      expect(element.outerHtml, '<div></div>');
    });
  });
}
