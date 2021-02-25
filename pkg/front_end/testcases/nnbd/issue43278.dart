// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  int? foo;
  A bar;

  A(this.bar);
}

test<T extends A?>(A? a, T t, dynamic d, int x) {
  a.foo ??= x; // Error.
  t.foo ??= x; // Error.
  d.foo ??= x; // Ok.
  a?.bar.foo ??= x; // Ok.
}

class B {}

extension Extension on B {
  int? get fooExtension => null;
  void set fooExtension(int? value) {}
  B get barExtension => new B();
}

testExtension<T extends B?>(B? b, T t, int x) {
  b.fooExtension ??= x; // Error.
  t.fooExtension ??= x; // Error.
  b?.barExtension.fooExtension ??= x; // Ok.
}

main() {}
