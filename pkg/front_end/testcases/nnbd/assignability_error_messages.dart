// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The test checks that if one type isn't assignable to the other only because
// of the nullability modifiers, the error message reflects that.

import 'dart:async';

class A {
  const A();
}

class B extends A {}

class C {
  num? call() {}
}

void fooContext(A x) {}

void barContext(List<A> x) {}

void bazContext(num Function() f) {}

A foo(B? x, List<B?> l, Map<B?, B?> m, List<B>? l2, Map<B, B>? m2) {
  fooContext(x); // Error.
  A a = x; // Error.
  <A>[...l]; // Error.
  <A>[...l2]; // Error.
  <A, A>{...m}; // Error.
  <A, A>{...m2}; // Error.
  for (A y in l) {} // Error.
  for (A y in l2) {} // Error.
  switch (x) /*  Error. */ {
    case const A():
      break;
    default:
      break;
  }
  FutureOr<A> local() async {
    if (true) {
      return x; // Error.
    } else {
      return new Future<B?>.value(x); // Error.
    }
  }

  return x; // Error.
}

List<A> bar(List<B?> x, List<List<B?>> l, Map<List<B?>, List<B?>> m) {
  barContext(x); // Error.
  List<A> y = x; // Error.
  <List<A>>[...l]; // Error.
  <List<A>, List<A>>{...m}; // Error.
  for (List<A> y in l) {} // Error.
  return x; // Error.
}

void baz(C c) {
  bazContext(c);
}

A boz(Null x) {
  fooContext(x); // Error.
  fooContext(null); // Error.
  A a1 = x; // Error.
  A a2 = null; // Error.
  if (true) {
    return x; // Error.
  } else {
    return null; // Error.
  }
  FutureOr<A> local() async {
    if (true) {
      return null; // Error.
    } else {
      return new Future<Null>.value(null); // Error.
    }
  }
}

main() {}
