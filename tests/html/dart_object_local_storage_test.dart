#library('DartObjectLocalStorageTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

// TODO(vsm): Rename this to wrapper_caching_test or similar.  It's
// basically a port of dom/dart_object_local_storage_test.dart.  For
// wrapping implementation of dart:html (i.e., the dartium one), it is
// effectively testing dart_object_local_storage in the underlying dom
// object.
main() {
  useHtmlConfiguration();

  BodyElement body = document.body;
  Storage localStorage = window.localStorage;
  Storage sessionStorage = window.sessionStorage;
  var element = new Element.tag('canvas');
  element.id = 'test';
  body.nodes.add(element);

  test('body', () {
      Expect.equals(body, document.body);
  });
  test('localStorage', () {
      Expect.equals(localStorage, window.localStorage);
  });
  test('sessionStorage', () {
      Expect.equals(sessionStorage, window.sessionStorage);
  });
  test('unknown', () {
      var test = document.query('#test');
      Expect.equals(element, test);
  });
}
