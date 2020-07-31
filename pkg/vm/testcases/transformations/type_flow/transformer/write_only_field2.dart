// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for tree shaking of write-only fields.

import "package:expect/expect.dart";

foo() {}

class A {
  // Should be removed.
  var unused1;

  // Should be removed.
  var unused2 = 42;

  // Not removed due to a non-trivial initializer.
  var unused3 = foo();
}

class B {
  // Should be removed.
  var unused4;

  // Should be removed.
  var unused5;

  B(this.unused4) : unused5 = foo();
}

class C<T> {
  // Should be replaced with setter.
  T bar;
}

class D implements C<int> {
  // Should be replaced with setter.
  int bar;
}

class E {
  // Should be replaced with getter.
  final int bar;

  E(this.bar);
}

class F implements E {
  int get bar => 42;
}

class G {
  // Not removed because used in a constant.
  final int bazz;

  const G(this.bazz);
}

class H {
  // Should be replaced with setter.
  int unused6;
}

class I extends H {
  foo() {
    super.unused6 = 3;
  }
}

// Should be removed.
int unusedStatic7 = foo();

void main() {
  new A();
  new B('hi');

  C<num> c = new D();
  Expect.throws(() {
    c.bar = 3.14;
  });

  E e = new F();
  Expect.equals(42, e.bar);

  Expect.isTrue(!identical(const G(1), const G(2)));

  new I().foo();

  unusedStatic7 = 5;
}
