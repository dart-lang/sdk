// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// There are a few circumstances where implicit tear-off of `call` methods does
// not occur; this test exercises the user-visible static analysis behaviors
// arising from those circumstances.

// NOTICE: This test checks the currently implemented behavior, even though the
// implemented behavior does not match the language specification.  Until an
// official decision has been made about whether to change the implementation to
// match the specification, or vice versa, this regression test is intended to
// protect against inadvertent implementation changes.

// A note on how the tests work: in several places we use the pattern
// `context<C>(b ? d : (E..expectStaticType<Exactly<T>>()))` (where `b` has type
// `bool` and `d` has type `dynamic`).  This pattern ensures that `E` will be
// type analyzed with a context of `C`, and tests that the resulting expression
// has a type of `T`.  However, the presence of `b ? d :` at the beginning
// ensures that the overall expression has type `dynamic`, so no assignability
// error will occur if types `C` and `T` are different.

// @dart = 2.9

import "package:expect/expect.dart";

import '../static_type_helper.dart';

class A {}

class C extends A {
  void call() {}
  void m() {}
}

// These are top level getters rather than local variables to avoid triggering
// flow analysis.
bool get bTrue => true;
bool get bFalse => false;

void testCascadeTarget() {
  C c = C();
  // Even though the subexpression `c` has type `C` and context `void
  // Function()`, we don't tear off `.call` for subexpressions that are the
  // target of a cascade; instead, we tear-off `.call` on the full cascade
  // expression.  So `c..m()` is equivalent to `(c..m()).call` (which is valid)
  // rather than `(c.call)..m()` (which is not).
  context<void Function()>(c..m());

  // Same as above, but confirm that extra parens around `c` don't change the
  // behavior.
  context<void Function()>((c)..m());
  context<void Function()>(((c))..m());
}

void testConditional() {
  A a = A();
  C c = C();
  dynamic d = null;
  // Even though the subexpression `c` has type `C` and context `void
  // Function()`, we don't tear off `.call` for the `then` or `else`
  // subexpressions of a conditional expression; instead, we tear off `.call`
  // for the conditional expression as a whole (if appropriate).  So, in
  // `(bTrue ? c : a)..expectStaticType<...>()`, no implicit tearoff of `c`
  // occurs, and the subexpression `bTrue ? c : a` gets assigned a static type
  // of `A`.
  Expect.throws(() => context<void Function()>(
      bFalse ? d : ((bTrue ? c : a)..expectStaticType<Exactly<A>>())));
  Expect.throws(() => context<void Function()>(
      bFalse ? d : ((bFalse ? a : c)..expectStaticType<Exactly<A>>())));

  // Same as above, but confirm that extra parens around `c` don't change the
  // behavior.
  Expect.throws(() => context<void Function()>(
      bFalse ? d : ((bTrue ? (c) : a)..expectStaticType<Exactly<A>>())));
  Expect.throws(() => context<void Function()>(
      bFalse ? d : ((bFalse ? a : (c))..expectStaticType<Exactly<A>>())));
  Expect.throws(() => context<void Function()>(
      bFalse ? d : ((bTrue ? ((c)) : a)..expectStaticType<Exactly<A>>())));
  Expect.throws(() => context<void Function()>(
      bFalse ? d : ((bFalse ? a : ((c)))..expectStaticType<Exactly<A>>())));
}

void testIfNull() {
  A a = A();
  A aq = null;
  C c = C();
  dynamic d = null;
  // Even though the subexpression `c` has type `C` and context `void
  // Function()`, we don't tear off `.call` for the LHS of a `??` expression;
  // instead, we tear off `.call` for the `??` expression as a whole (if
  // appropriate).  So, in
  // `(c ?? a)..expectStaticType<...>()`, no implicit tearoff of `c` occurs, and
  // the subexpression `c ?? a` gets assigned a static type of `A`.
  Expect.throws(() => context<void Function()>(
      bFalse ? d : ((c ?? a)..expectStaticType<Exactly<A>>())));
  Expect.throws(() => context<void Function()>(
      bFalse ? d : ((aq ?? c)..expectStaticType<Exactly<A>>())));

  // Same as above, but confirm that extra parens around `c` don't change the
  // behavior.
  Expect.throws(() => context<void Function()>(
      bFalse ? d : (((c) ?? a)..expectStaticType<Exactly<A>>())));
  Expect.throws(() => context<void Function()>(
      bFalse ? d : ((aq ?? (c))..expectStaticType<Exactly<A>>())));
  Expect.throws(() => context<void Function()>(
      bFalse ? d : ((((c)) ?? a)..expectStaticType<Exactly<A>>())));
  Expect.throws(() => context<void Function()>(
      bFalse ? d : ((aq ?? ((c)))..expectStaticType<Exactly<A>>())));
}

main() {
  testCascadeTarget();
  testConditional();
  testIfNull();
}
