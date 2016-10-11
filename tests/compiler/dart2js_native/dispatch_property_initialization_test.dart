// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for initialization of dispatchPropertyName.

import "package:expect/expect.dart";
import 'dart:_foreign_helper' show JS;
import 'dart:_js_helper' show Native;

@Native("Foo")
class Foo {
  String method(String x) native;
}

makeFoo() native;

void setup() native r"""
function Foo() {}
Foo.prototype.method = function(x) { return 'Foo ' + x; }

self.makeFoo = function() { return new Foo(); }
""";


main() {
  setup();

  // If the dispatchPropertyName is uninitialized, it will be `undefined` or
  // `null` instead of the secret string or Symbol. These properties on
  // `Object.prototype` will be retrieved by the lookup instead of `undefined`
  // for the dispatch record.
  JS('', r'self.Object.prototype["undefined"] = {}');
  JS('', r'self.Object.prototype["null"] = {}');
  Expect.equals('Foo A', makeFoo().method('A'));

  // Slightly different version that has malformed dispatch records.
  JS('', r'self.Object.prototype["undefined"] = {p: false}');
  JS('', r'self.Object.prototype["null"] = {p: false}');
  Expect.equals('Foo B', makeFoo().method('B'));
}
