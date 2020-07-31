// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test least upper bound through type checking of conditionals.
import 'package:expect/expect.dart';
class Expect {
  static isTrue(bool cond, String message) {
    if (!cond) throw message;
  }
}

class A {}
class B {}
class C extends B {}
class D extends B {}
class E<T> {}
class F<T> extends E<T> {}

void main() {
  checkType(true ? A() : B())<Object>();
  checkType(true ? B() : C())<B>();
  checkType(true ? C() : D())<B>();
  checkType(true ? E<B>() : E<C>())<E<B>>();
  checkType(true ? E<B>() : F<C>())<E<B>>();
}

/// Tests that [A] (which should be inferred from the expression for [actual]
/// is the same as [E].
void Function<E>() checkType<A>(A actual) {
  return <E>() {
    Expect.isTrue(<E>[] is List<A> && <A>[] is List<E>,
        "Argument expression should have inferred type '$E' but was '$A'.");
  };
}
