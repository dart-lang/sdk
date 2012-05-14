#library('StorageTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/dom_config.dart');
#import('dart:dom_deprecated');

main() {
  useDomConfiguration();
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
