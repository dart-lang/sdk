#library('DartObjectLocalStorageTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/html_config.dart');
#import('dart:html');

verify(var object) {
  final value = window.document;
  object.dartObjectLocalStorage = value;
  final stored = object.dartObjectLocalStorage;
  Expect.equals(value, stored);
}

main() {
  useHtmlConfiguration();
  test('body', () {
      BodyElement body = document.body;
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
      var element = new Element.tag('canvas');
      element.id = 'test';
      document.body.nodes.add(element);
      element = document.query('#test');
      verify(element);
  });
}
