// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// All three libraries have an HttpRequest class.
import "conditional_import.dart"
    if (dart.library.io) "dart:io"
    if (dart.library.html) "dart:html" as a;

// All three libraries have an HttpRequest class.
import "conditional_import.dart"
    if (dart.library.html) "dart:html"
    if (dart.library.io) "dart:io" as b;

import "conditional_import.dart" if (dart.library.foo) "dart:foo" as c;

class HttpRequest {}

testA(a.HttpRequest request) {
  request.certificate; // ok (from dart:io)
  request.response; // ok (from dart:io and dart:html)
  request.readyState; // error (from dart:html)
  request.hashCode; // ok
}

testB(b.HttpRequest request) {
  request.certificate; // ok (from dart:io)
  request.response; // ok (from dart:io and dart:html)
  request.readyState; // error (from dart:html)
  request.hashCode; // ok
}

testC(c.HttpRequest request) {
  request.certificate; // error
  request.response; // error
  request.readyState; // error
  request.hashCode; // ok
}

void main() {
  expect(true, const bool.fromEnvironment("dart.library.io"));
  expect(false, const bool.fromEnvironment("dart.library.html"));
  expect(false, const bool.fromEnvironment("dart.library.foo"));
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
