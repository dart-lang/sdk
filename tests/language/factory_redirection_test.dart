// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<T> {
  A() : x = null;

  const A.constant(T x) : this.x = x;

  factory A.factory() {
    return new B<Set>();
  }

  final T x;
}

class B<T> extends A<T> {
  B();

  factory B.A() = A<T>;

  const factory B.A_constant(T x) = A<T>.constant;

  factory B.A_factory() = A<T>.factory;
}

class C<K, V> extends B<V> {
  C();

  factory C.A() = A<V>;

  factory C.A_factory() = A<V>.factory;

  const factory C.B_constant(V x) = B<V>.A_constant;
}

main() {
  Expect.isTrue(new A<List>() is A<List>);
  Expect.isTrue(new A<bool>.constant(true).x);
  Expect.isTrue(new A<List>.factory() is B<Set>);
  Expect.isTrue(new B<List>.A() is A<List>);
  Expect.isTrue(new B<bool>.A_constant(true).x);
  Expect.isTrue(new B<List>.A_factory() is B<Set>);
  Expect.isTrue(new C<String, num>.A() is A<num>);
  Expect.isTrue(new C<String, num>.A_factory() is B<Set>);
  Expect.isTrue(new C<String, bool>.B_constant(true).x);
}
