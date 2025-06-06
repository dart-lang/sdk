// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:expect/legacy/minitest.dart'; // ignore: deprecated_member_use_from_same_package

// TODO(vsm): Rename this to wrapper_caching_test or similar.  It's
// basically a port of dom/dart_object_local_storage_test.dart.  For
// wrapping implementation of dart:html (i.e., the dartium one), it is
// effectively testing dart_object_local_storage in the underlying dom
// object.
main() {
  BodyElement body = document.body!;
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
    var test = document.querySelector('#test');
    expect(element, equals(test));
  });
}
