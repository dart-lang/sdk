// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a type variable can be used to declare local variables, and that
// these local variables are of correct type.

library generic_methods_local_variable_declaration_test;

import "package:expect/expect.dart";

class X {}

abstract class Generator<T> {
  T generate();
}

class A implements Generator<A> {
  generate() {
    return new A();
  }

  String toString() => "instance of A";
}

class B implements Generator<B> {
  generate() {
    return new B();
  }

  String toString() => "instance of B";
}

String fun<T extends Generator<T>>(T t) {
  T another = t.generate();
  String anotherName = "$another";

  Expect.isTrue(another is T);
  Expect.isTrue(another is Generator<T>);

  return anotherName;
}

main() {
  A a = new A();
  B b = new B();

  Expect.equals(fun<A>(a), "instance of A");
  Expect.equals(fun<B>(b), "instance of B");
}
