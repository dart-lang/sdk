#library('StorageTest');
#import('../../../../lib/unittest/unittest_dom.dart');
#import('dart:dom');

main() {
  forLayoutTests();
  test('GetItem', () {
    final value = window.localStorage.getItem('does not exist');
    Expect.isNull(value);
  });
  test('SetItem', () {
    final key = 'foo';
    final value = 'bar';
    window.localStorage.setItem(key, value);
    final stored = window.localStorage.getItem(key);
    Expect.equals(value, stored);
  });
}
