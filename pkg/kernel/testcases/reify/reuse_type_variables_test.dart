// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library reuse_type_variables_test;

import 'test_base.dart';

class X {}

class Y {}

class Z {}

class C<T, U, V> {
  foo() => new D<T, U, V>();
  bar() => new E<T, U>();
  hest() => new D<T, V, U>();
}

class D<T, U, V> {
  baz() => new C<T, U, V>();
}

class E<T, U> {
  qux() => new C<T, U, U>();
}

main() {
  var c = new C<X, Y, Z>();
  var d = c.foo();
  expectTrue(d is D<X, Y, Z>);
  d = c.hest();
  expectTrue(d is! D<X, Y, Z>);
  expectTrue(d is D<X, Z, Y>);
  c = d.baz();
  expectTrue(c is C<X, Z, Y>);
  var e = c.bar();
  expectTrue(e is E<X, Z>);
  c = e.qux();
  expectTrue(c is C<X, Z, Z>);
}
