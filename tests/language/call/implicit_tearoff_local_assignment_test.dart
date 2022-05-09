// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that when considering whether to perform a `.call` tearoff
// on the RHS of an assignment, the implementations use the unpromoted type of
// the variable (rather than the promoted type).

// NOTICE: This test checks the currently implemented behavior, even though the
// implemented behavior does not match the language specification.  Until an
// official decision has been made about whether to change the implementation to
// match the specification, or vice versa, this regression test is intended to
// protect against inadvertent implementation changes.

import "package:expect/expect.dart";

import '../static_type_helper.dart';

class B {
  Object call() => 'B.call called';
}

class C extends B {
  String call() => 'C.call called';
}

void testClassPromoted() {
  B x = C();
  x as C;
  x.expectStaticType<Exactly<C>>();
  var y = x = C(); // No implicit tearoff of `.call`, no demotion
  x.expectStaticType<Exactly<C>>();
  Expect.type<C>(x);
  Expect.equals('C.call called', x());
  y.expectStaticType<Exactly<C>>();
  Expect.type<C>(y);
  Expect.equals('C.call called', y());
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

void testFunctionPromoted() {
  String f() => 'f called';
  Object Function() x = f;
  x as String Function();
  x.expectStaticType<Exactly<String Function()>>();
  var y = x = C(); // Implicit tearoff of `.call`, no demotion
  x.expectStaticType<Exactly<String Function()>>();
  Expect.type<String Function()>(x);
  Expect.equals('C.call called', x());
  y.expectStaticType<Exactly<String Function()>>();
  Expect.type<String Function()>(y);
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

void testObjectPromotedToClass() {
  Object x = B();
  x as B;
  x.expectStaticType<Exactly<B>>();
  var y = x = C(); // No implicit tearoff of `.call`, x remains promoted
  x.expectStaticType<Exactly<B>>();
  Expect.type<C>(x);
  Expect.equals('C.call called', x());
  y.expectStaticType<Exactly<C>>();
  Expect.type<C>(y);
  Expect.equals('C.call called', y());
}

void testObjectPromotedToFunction() {
  Object f() => 'f called';
  Object x = f;
  x as Object Function();
  x.expectStaticType<Exactly<Object Function()>>();
  var y = x = B(); // No implicit tearoff of `.call`, demotes x
  x.expectStaticType<Exactly<Object>>();
  Expect.type<B>(x);
  Expect.equals('B.call called', (x as B)());
  y.expectStaticType<Exactly<B>>();
  Expect.type<B>(y);
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
  testClassPromoted();
  testClassUnpromoted();
  testFunctionPromoted();
  testFunctionUnpromoted();
  testObjectPromotedToClass();
  testObjectPromotedToFunction();
  testObjectUnpromoted();
}
