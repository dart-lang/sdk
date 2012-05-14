#library('DartObjectLocalStorageTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/dom_config.dart');
#import('dart:dom_deprecated');

verify(var object) {
  final value = window.document;
  object.dartObjectLocalStorage = value;
  final stored = object.dartObjectLocalStorage;
  Expect.equals(value, stored);
}

main() {
  useDomConfiguration();
  test('body', () {
      HTMLBodyElement body = document.body;
      verify(body);
  });
  test('localStorage', () {
      Storage storage = window.localStorage;
      verify(storage);
  });
  test('sessionStorage', () {
      Storage storage = window.sessionStorage;
      verify(storage);
  });
  test('unknown', () {
      var element = document.createElement('canvas');
      element.id = 'test';
      document.body.appendChild(element);
      element = document.getElementById('test');
      verify(element);
  });
}
