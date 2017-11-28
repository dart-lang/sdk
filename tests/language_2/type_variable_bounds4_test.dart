// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test instantiation of object with malbounded types.

class A<
    T
          extends num //# 01: compile-time error
    > {}

class B<T> implements A<T> {}

class C<
    T
          extends num //# 01: continued
    > implements B<T> {}

class Class<T> {
  newA() {
    new A<T>();
  }
  newB() {
    new B<T>();
  }
  newC() {
    new C<T>();
  }
}

void test(f()) {
  var v = f();
}

void main() {
  test(() => new A<int>());
  // TODO(eernst): Should it be a compile-time error to create an instance
  // of this class in #01?
  test(() => new B<int>());
  test(() => new C<int>());

  test(() => new A<String>());
  test(() => new B<String>());
  test(() => new C<String>());

  dynamic c = new Class<int>();
  test(() => c.newA());
  test(() => c.newB());
  test(() => c.newC());

  c = new Class<String>();
  test(() => c.newA());
  test(() => c.newB());
  test(() => c.newC());
}
