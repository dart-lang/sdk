// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A<T> {
  A() : x = null;

  const A.constant(this.x);

  factory A.factory() {
    return new B<Set>();
  }

  factory A.test01() = T; // //# 01: compile-time error

  factory A.test02() = dynamic; // //# 02: compile-time error

  factory A.test03() = Undefined; // //# 03: compile-time error

  factory A.test04() = C.test04; // //# 04: compile-time error

  final T x;
}

class B<T> extends A<T> {
  B();

  factory B.A() = A<T>;

  const factory B.A_constant(T x) = A<T>.constant;

  factory B.A_factory() = A<T>.factory;

  factory B.test04() = A.test04; // //# 04: continued

  factory B.test05(int incompatible) = A<T>.factory; // //# 05: compile-time error

  factory B.test05(int incompatible) = A<T>.factory; // //# 06: compile-time error
}

class C<K, V> extends B<V> {
  C();

  factory C.A() = A<V>; // //# none: compile-time error

  factory C.A_factory() = A<V>.factory;  // //# none: compile-time error

  const factory C.B_constant(V x) = B<V>.A_constant;

  factory C.test04() = B.test04; // //# 04: continued

  factory C.test06(int incompatible) = B<K>.test05; // //# 06: continued

  const factory C.test07(V x) = B<V>.A; // //# 07: compile-time error
}

main() {
  new A<List>.test01(); // //# 01: continued
  new A<List>.test02(); // //# 02: continued
  new A<List>.test03(); // //# 03: continued
  new C.test04(); // //# 04: continued
  new B.test05(0); // //# 05: continued
  new C<int, int>.test06(0); // //# 06: continued
  new C<int, int>.test07(0); // //# 07: continued
  Expect.isTrue(new A<List>() is A<List>);
  Expect.isTrue(new A<bool>.constant(true).x);
  Expect.isTrue(new A<Set>.factory() is B<Set>);
  Expect.isTrue(new B<List>.A() is A<List>); // //# 08: compile-time error
  Expect.isFalse(new B<List>.A() is A<Set>); // //# 09: compile-time error
  Expect.isTrue(new B<bool>.A_constant(true).x); // //# 10: compile-time error
  Expect.isTrue(new B<List>.A_factory() is B<Set>); // //# 11: compile-time error
  Expect.isTrue(new C<String, num>.A() is A<num>); // //# 12: compile-time error
  Expect.isTrue(new C<String, num>.A_factory() is B<Set>); // //# 13: compile-time error
  Expect.isTrue(new C<String, bool>.B_constant(true).x); // //# 14: compile-time error
}
