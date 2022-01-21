// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Make sure `Object` methods work as expected with `dart:html` and interop
// types. The expectations here aren't guarantees that they should work a
// particular way, but rather a way to monitor regressions/changes.

@JS()
library object_members_test;

import 'package:js/js.dart';
import 'package:expect/minitest.dart';

import 'dart:html';
import 'dart:_interceptors' show JSObject;

@JS()
external void eval(String code);

@JS()
class JSClass {
  external JSClass();
}

void main() {
  eval(r'''
    function JSClass() {}
  ''');

  // `dart:html` type.
  var div = document.createElement('div');
  expect(div == div, true);
  expect(div == DomPointReadOnly(), false);
  // Ensure that we get a random hash for each new instance. It should be
  // improbable for this to fail across many runs if the hash is
  // non-deterministic.
  var hashCode = div.hashCode;
  var attempts = 0;
  var maxAttempts = 1000;
  while (div.hashCode == hashCode && attempts < maxAttempts) {
    div = document.createElement('div');
    attempts++;
  }
  expect(attempts > 0 && attempts != maxAttempts, isTrue);
  expect(div.toString, isNotNull);
  expect(div.toString(), 'div');
  expect(div.noSuchMethod, isNotNull);
  var noSuchMethodErrorThrown = true;
  try {
    (div as dynamic).triggerNoSuchMethod();
    noSuchMethodErrorThrown = false;
  } catch (_) {}
  expect(noSuchMethodErrorThrown, isTrue);
  expect(div.runtimeType, DivElement);

  // `toString` for `dart:html` types that do not have an overridden `toString`
  // should look up the type through the proto.
  expect(window.navigator.toString(), "Instance of 'Navigator'");

  // Interop type.
  var js = JSClass();
  expect(js == js, true);
  expect(js == JSClass(), false);
  // TODO(srujzs): Modify this once interop has random hash codes.
  hashCode = js.hashCode;
  expect(hashCode, 0);
  expect(hashCode, js.hashCode);
  expect(js.toString, isNotNull);
  // Should forward to underlying `toString` call.
  expect(js.toString(), '[object Object]');
  expect(js.noSuchMethod, isNotNull);
  noSuchMethodErrorThrown = true;
  try {
    (js as dynamic).triggerNoSuchMethod();
    noSuchMethodErrorThrown = false;
  } catch (_) {}
  expect(noSuchMethodErrorThrown, isTrue);
  expect(js.runtimeType, JSObject);
}
