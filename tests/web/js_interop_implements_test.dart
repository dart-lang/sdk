// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that methods implemented (not extended) in js-interop classes are still
// considered live.

@JS()
library anonymous_js_test;

import 'package:js/js.dart';

@JS()
@anonymous
abstract class A {
  external factory A();
  external String get a;
  external set a(String a);
}

@JS()
@anonymous
abstract class B implements A {
  external factory B();
  external String get b;
  external set b(String b);
}

void main() {
  final b = B();
  // This setter is missing if we don't assume the receiver could be an
  // unknown but concrete implementation of A.
  b.a = 'Hi';
  b.b = 'Hello';
  if (b.a != 'Hi') throw 'b.a';
  if (b.b != 'Hello') throw 'b.b';
}
