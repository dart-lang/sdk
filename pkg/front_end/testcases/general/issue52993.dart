// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() { foo<Object>(false, D(), D()); }
void foo<X>(bool not, X b, X c) {
  if (b is! B) return;
  // Promoted to X&B. Proof:
  {
    X v1 = b;
    B v2 = b;
  }
  if (c is! C) return;
  // Promoted to X&C
  {
    X v1 = c;
    C v2 = c;
  }
  var bc = not ? b : c;
  // BY THE RULES, UP(X&B, X&C) which is X.
  // THE RULES are:
  //
  // UP(X1 & B1, T2) =
  // * T2 if X1 <: T2
  // * otherwise X1 if T2 <: X1
  // * otherwise UP(B1a, T2) where B1a is the greatest closure of B1 with respect to
  //    X1, as defined in inference.md.
  //
  //  Here X1 is X, B1 is B, T2 is (X & C)
  //     * X <: X&C  - not true,
  //     * X&C <: X - true!, so result is X.
  // So declared and static type of bc is `X`, with no further promotion.

  {
    X v1 = bc; // bc assignable to X.
    // B v2 = bc; // Error in front-end
    // C v3 = bc; // Error in front-end
    if (not) {
      bc = 0 as X;  // X assignable to bc.
      throw "never got here, never go back"; // Don't flow demotion back.
    }
  }

  bc.st<E<X>>; // Requires (reified as type argument) static type of `v` to be exactly X.
  St(bc).st<E<X>>;
  Rt(bc).rt<E<X>>;
}

// Diamond hierarchy
class A {}
class B implements A {}
class C implements A {}
class D implements B, C {}

// Static type-checking helper.
typedef E<T> = T Function(T);
extension St<T> on T {
  void st<T2 extends E<T>>(){}
}
// Non-extension based static type checker.
// (In case we thought it was just extensions being wrong.)
class Rt<T> {
  Rt(T t);
  void rt<T2 extends E<T>>() {}
}
