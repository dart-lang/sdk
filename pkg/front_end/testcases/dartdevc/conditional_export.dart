// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'conditional_export_lib1.dart' as a;
import 'conditional_export_lib2.dart' as b;
import 'conditional_export_lib3.dart' as c;

testA(a.HttpRequest request) {
  request.certificate; // Error (from dart:io)
  request.response; // Ok (from dart:io and dart:html)
  request.readyState; // Ok (from dart:html)
  request.hashCode; // Ok
}

testB(b.HttpRequest request) {
  request.certificate; // Error (from dart:io)
  request.response; // Ok (from dart:io and dart:html)
  request.readyState; // Ok (from dart:html)
  request.hashCode; // Ok
}

testC(c.HttpRequest request) {
  request.certificate; // Error
  request.response; // Error
  request.readyState; // Error
  request.hashCode; // Ok
}

void main() {
  expect(false, const bool.fromEnvironment("dart.library.io"));
  expect(true, const bool.fromEnvironment("dart.library.html"));
  expect(false, const bool.fromEnvironment("dart.library.foo"));
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
