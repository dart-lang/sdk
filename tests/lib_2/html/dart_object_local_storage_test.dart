import 'dart:html';

import 'package:expect/minitest.dart';

// TODO(vsm): Rename this to wrapper_caching_test or similar.  It's
// basically a port of dom/dart_object_local_storage_test.dart.  For
// wrapping implementation of dart:html (i.e., the dartium one), it is
// effectively testing dart_object_local_storage in the underlying dom
// object.
main() {
  BodyElement body = document.body;
  Storage localStorage = window.localStorage;
  Storage sessionStorage = window.sessionStorage;
  var element = new Element.tag('canvas');
  element.id = 'test';
  body.append(element);

  test('body', () {
    expect(body, equals(document.body));
  });
  test('localStorage', () {
    expect(localStorage, equals(window.localStorage));
  });
  test('sessionStorage', () {
    expect(sessionStorage, equals(window.sessionStorage));
  });
  test('unknown', () {
    var test = document.query('#test');
    expect(element, equals(test));
  });
}
