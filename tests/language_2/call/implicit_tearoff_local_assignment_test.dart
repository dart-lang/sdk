// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test is the pre-null-safety variant of the null safety test
// `implicit_tearoff_local_assignment_test.dart`, which verifies that when
// considering whether to perform a `.call` tearoff on the RHS of an assignment,
// the implementations use the unpromoted type of the variable (rather than the
// promoted type).  For the pre-null-safety variant, the same logic doesn't
// really apply, because a variable can't be promoted in a block that contains
// an assignment to it.  But we can still test the unpromoted cases.

// @dart = 2.9

import "package:expect/expect.dart";

import '../static_type_helper.dart';

class B {
  Object call() => 'B.call called';
}

class C extends B {
  String call() => 'C.call called';
}

void testClassUnpromoted() {
  B x = B();
  var y = x = C(); // No implicit tearoff of `.call`, no promotion
  x.expectStaticType<Exactly<B>>();
  Expect.type<C>(x);
  Expect.equals('C.call called', x());
  y.expectStaticType<Exactly<C>>();
  Expect.type<C>(y);
  Expect.equals('C.call called', y());
}

void testFunctionUnpromoted() {
  Object f() => 'f called';
  Object Function() x = f;
  var y = x = B(); // Implicit tearoff of `.call`, no promotion
  x.expectStaticType<Exactly<Object Function()>>();
  Expect.type<Object Function()>(x);
  Expect.equals('B.call called', x());
  y.expectStaticType<Exactly<Object Function()>>();
  Expect.type<Object Function()>(y);
  Expect.equals('B.call called', y());
}

void testObjectUnpromoted() {
  Object x = 'initial value';
  var y = x = B(); // No implicit tearoff of `.call`, no promotion
  x.expectStaticType<Exactly<Object>>();
  Expect.type<B>(x);
  Expect.equals('B.call called', (x as B)());
  y.expectStaticType<Exactly<B>>();
  Expect.type<B>(y);
  Expect.equals('B.call called', y());
}

main() {
  testClassUnpromoted();
  testFunctionUnpromoted();
  testObjectUnpromoted();
}
