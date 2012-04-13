#library('DocumentTest');
#import('../../../../lib/unittest/unittest.dart');
#import('../../../../lib/unittest/dom_config.dart');
#import('dart:dom');

main() {
  useDomConfiguration();

  test('CreateElement', () {
    // FIXME: nifty way crashes, do it boring way.
    Expect.isTrue(document.createElement('span') is HTMLElement);
    Expect.isTrue(document.createElement('div') is HTMLDivElement);
    Expect.isTrue(document.createElement('a') is HTMLAnchorElement);
    Expect.isTrue(document.createElement('bad_name') is HTMLUnknownElement);
  });

  test('DocumentURL', () {
    // URL is something like ..._client_dom_DocumentTest.dartfrogium.html
    Expect.isTrue(document.URL.endsWith('.html'));
    Expect.isTrue(document.URL.indexOf('DocumentTest') > 0);
  });
}
