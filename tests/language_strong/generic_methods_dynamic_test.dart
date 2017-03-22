// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that if the type of a parameter of a generic method is a type parameter,
// the type of the passed argument is checked (01) at compile time
// if the receiver is given via an interface-type variable, and (02) at runtime
// if the receiver is dynamic.

library generic_methods_dynamic_test;

import "package:expect/expect.dart";

class A {}

class B {}

class C {
  T foo<T>(T t) => t;
  List<T> bar<T>(Iterable<T> t) => <T>[t.first];
}

main() {
  B b = new B();
  C c = new C();
  dynamic obj = c;

  c.foo<A>(b); //# 01: compile-time error
  obj.foo<A>(b); //# 02: runtime error

  c.bar<A>(<B>[new B()]); //# 03: compile-time error
  obj.bar<A>(<B>[new B()]); //# 04: runtime error

  Expect.equals(c.foo<B>(b), b); //# 05: ok
  Expect.equals(obj.foo<B>(b), b); //# 05: continued

  dynamic x = c.bar<B>(<B>[new B()]); //# 05: continued
  Expect.isTrue(x is List<B>); //# 05: continued
  Expect.equals(x.length, 1); //# 05: continued

  dynamic y = obj.bar<B>(<B>[new B()]); //# 05: continued
  Expect.isTrue(y is List<B>); //# 05: continued
  Expect.equals(y.length, 1); //# 05: continued
}
