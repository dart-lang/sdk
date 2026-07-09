// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Make sure `Object` methods work as expected with `dart:html` and interop
// types. The expectations here aren't guarantees that they should work a
// particular way, but rather a way to monitor regressions/changes.

@JS()
library object_members_test;

import 'package:js/js.dart';
import 'package:expect/legacy/minitest.dart'; // ignore: deprecated_member_use_from_same_package

import 'dart:html';
import 'dart:_interceptors' show JSObject, LegacyJavaScriptObject;

const isDart2JS = const bool.fromEnvironment('dart.library._dart2js_only');

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

  // `toString` for `dart:html` types depend on the implementation. dart2js
  // provides a more readable string, whereas DDC just uses the underlying
  // `toString`.
  final navigatorToString = window.navigator.toString();
  if (isDart2JS) {
    expect(navigatorToString, "Instance of 'Navigator'");
  } else {
    expect(navigatorToString, "[object Navigator]");
  }

  // Interop type.
  var js = JSClass();
  expect(js == js, true);
  expect(js == JSClass(), false);
  hashCode = js.hashCode;
  if (isDart2JS) {
    // DDC adds a random hash code to the object (should use a weak map), but
    // dart2js returns 0 for all `LegacyJavaScriptObject`s.
    // TODO(srujzs): Modify this once interop has random hash codes.
    expect(hashCode, 0);
  }
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
  final runtimeType = js.runtimeType;
  if (isDart2JS) {
    // dart2js explicitly returns `JSObject` as the `runtimeType` for all
    // `LegacyJavaScriptObject`s.
    expect(runtimeType, JSObject);
  } else {
    expect(runtimeType, LegacyJavaScriptObject);
  }
}
