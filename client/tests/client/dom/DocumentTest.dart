#library('DocumentTest');
#import('../../../testing/unittest/unittest.dart');
#import('dart:dom');

main() {
  forLayoutTests();
  test('CreateElement', () {
    // FIXME: nifty way crashes, do it boring way.
    Expect.isTrue(document.createElement('span') is HTMLElement);
    Expect.isTrue(document.createElement('div') is HTMLDivElement);
    Expect.isTrue(document.createElement('a') is HTMLAnchorElement);
    Expect.isTrue(document.createElement('bad_name') is HTMLUnknownElement);
  });
  test('DocumentURL', () {
    Expect.isTrue(document.URL.endsWith('DocumentTest.html'));
  });
}
