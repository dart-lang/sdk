// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the new context type rules for number operators,
// as modified by Null Safety
import "../static_type_helper.dart";

// The context rules for `e` of the form:
// For e1 + e2, e1 - e2, e1 * e2, e1 % e2 or e1.remainder(e2),,
// if the static type of e1 is a non-`Never` subtype of `int`,
// and the context type of the entire expression is `int`,
// then the context type of e2 is `int`.
// If the static type of e1 is a non-`Never` subtype of `num`
// that is not a subtype of `double`,
// and the context type of the entire expression is `double`,
// then the context type of e2 is `double`.

// If the context type of `e1.clamp(e2, e3)`, *C*,
// and the  the static type of `e1`, *T*,
// are both is a non-`Never` subtypes of `num`,
// then the context types of `e2` and `e3` are both *C*.
// Otherwise the context types of `e2` and `e3` are `num`.

void main() {
  testIntContext<int, Object>(1, 1);
  testDoubleContext<int, double, num, Object>(1, 1.1, 1.1, 1.1);
  testNumContext<num, Object>(1, 1);
}

void testIntContext<I extends int, O extends Object>(I i, O o) {
  context<int>(1 + (contextType(1)..expectStaticType<Exactly<int>>()));
  context<int>(1 - (contextType(1)..expectStaticType<Exactly<int>>()));
  context<int>(1 * (contextType(1)..expectStaticType<Exactly<int>>()));
  context<int>(1 % (contextType(1)..expectStaticType<Exactly<int>>()));
  context<int>(1.remainder(contextType(1)..expectStaticType<Exactly<int>>()));

  context<int>(i + (contextType(1)..expectStaticType<Exactly<int>>()));
  context<int>(i - (contextType(1)..expectStaticType<Exactly<int>>()));
  context<int>(i * (contextType(1)..expectStaticType<Exactly<int>>()));
  context<int>(i % (contextType(1)..expectStaticType<Exactly<int>>()));
  context<int>(i.remainder(contextType(1)..expectStaticType<Exactly<int>>()));

  context<num>(1 + (contextType(1)..expectStaticType<Exactly<num>>()));
  context<num>(1 - (contextType(1)..expectStaticType<Exactly<num>>()));
  context<num>(1 * (contextType(1)..expectStaticType<Exactly<num>>()));
  context<num>(1 % (contextType(1)..expectStaticType<Exactly<num>>()));
  context<num>(1.remainder(contextType(1)..expectStaticType<Exactly<num>>()));

  O oi = 1 as O;
  if (oi is! int) throw "promote oi to O&int";
  context<int>(oi + (contextType(1)..expectStaticType<Exactly<int>>()));
  context<int>(oi - (contextType(1)..expectStaticType<Exactly<int>>()));
  context<int>(oi * (contextType(1)..expectStaticType<Exactly<int>>()));
  context<int>(oi % (contextType(1)..expectStaticType<Exactly<int>>()));
  context<int>(oi.remainder(contextType(1)..expectStaticType<Exactly<int>>()));

  int ii = 0;
  ii += contextType(1)..expectStaticType<Exactly<int>>();
  ii -= contextType(1)..expectStaticType<Exactly<int>>();
  ii *= contextType(1)..expectStaticType<Exactly<int>>();
  ii %= contextType(1)..expectStaticType<Exactly<int>>();
  if (ii != 0) throw "use ii";

  context<int>(1.clamp(contextType(1)..expectStaticType<Exactly<int>>(),
      contextType(1)..expectStaticType<Exactly<int>>()));

  context<int>(i.clamp(contextType(1)..expectStaticType<Exactly<int>>(),
      contextType(1)..expectStaticType<Exactly<int>>()));

  context<int>(oi.clamp(contextType(1)..expectStaticType<Exactly<int>>(),
      contextType(1)..expectStaticType<Exactly<int>>()));
}

void testDoubleContext<I extends int, D extends double, N extends num,
    O extends Object>(I i, D d, N n, O o) {
  context<double>(1 + (contextType(1.0)..expectStaticType<Exactly<double>>()));
  context<double>(1 - (contextType(1.0)..expectStaticType<Exactly<double>>()));
  context<double>(1 * (contextType(1.0)..expectStaticType<Exactly<double>>()));
  context<double>(1 % (contextType(1.0)..expectStaticType<Exactly<double>>()));
  context<double>(
      1.remainder(contextType(1.0)..expectStaticType<Exactly<double>>()));

  context<double>(n + (contextType(1.0)..expectStaticType<Exactly<double>>()));
  context<double>(n - (contextType(1.0)..expectStaticType<Exactly<double>>()));
  context<double>(n * (contextType(1.0)..expectStaticType<Exactly<double>>()));
  context<double>(n % (contextType(1.0)..expectStaticType<Exactly<double>>()));
  context<double>(
      n.remainder(contextType(1.0)..expectStaticType<Exactly<double>>()));

  context<double>(i + (contextType(1.0)..expectStaticType<Exactly<double>>()));
  context<double>(i - (contextType(1.0)..expectStaticType<Exactly<double>>()));
  context<double>(i * (contextType(1.0)..expectStaticType<Exactly<double>>()));
  context<double>(i % (contextType(1.0)..expectStaticType<Exactly<double>>()));
  context<double>(
      i.remainder(contextType(1.0)..expectStaticType<Exactly<double>>()));

  context<double>(d + (contextType(1.0)..expectStaticType<Exactly<num>>()));
  context<double>(d - (contextType(1.0)..expectStaticType<Exactly<num>>()));
  context<double>(d * (contextType(1.0)..expectStaticType<Exactly<num>>()));
  context<double>(d % (contextType(1.0)..expectStaticType<Exactly<num>>()));
  context<double>(
      d.remainder(contextType(1.0)..expectStaticType<Exactly<num>>()));

  var od = (1.0 as O);
  if (od is! double) throw "promote od to O&double";
  context<double>(od + (contextType(1.0)..expectStaticType<Exactly<num>>()));
  context<double>(od - (contextType(1.0)..expectStaticType<Exactly<num>>()));
  context<double>(od * (contextType(1.0)..expectStaticType<Exactly<num>>()));
  context<double>(od % (contextType(1.0)..expectStaticType<Exactly<num>>()));
  context<double>(
      od.remainder(contextType(1.0)..expectStaticType<Exactly<num>>()));

  // The context type also causes double literals.
  context<double>(1 + (1..expectStaticType<Exactly<double>>()));
  context<double>(1 - (1..expectStaticType<Exactly<double>>()));
  context<double>(1 * (1..expectStaticType<Exactly<double>>()));
  context<double>(1 % (1..expectStaticType<Exactly<double>>()));
  context<double>(1.remainder(1..expectStaticType<Exactly<double>>()));

  double dd = 0.0;
  dd += contextType(1)..expectStaticType<Exactly<num>>();
  dd -= contextType(1)..expectStaticType<Exactly<num>>();
  dd *= contextType(1)..expectStaticType<Exactly<num>>();
  dd %= contextType(2)..expectStaticType<Exactly<num>>();

  context<double>(1.1.clamp(
      contextType(1.0)..expectStaticType<Exactly<double>>(),
      contextType(1.0)..expectStaticType<Exactly<double>>()));

  context<double>(d.clamp(contextType(1.0)..expectStaticType<Exactly<double>>(),
      contextType(1.0)..expectStaticType<Exactly<double>>()));

  context<double>(od.clamp(
      contextType(1.0)..expectStaticType<Exactly<double>>(),
      contextType(1.0)..expectStaticType<Exactly<double>>()));
}

void testNumContext<N extends num, O extends Object>(N n, O o) {
  var i1 = 1;
  var d1 = 1.0;
  num n1 = 1;
  if (o is! num) throw "promote o to O&num";

  context<num>(i1 + (contextType(1)..expectStaticType<Exactly<num>>()));
  context<num>(i1 - (contextType(1)..expectStaticType<Exactly<num>>()));
  context<num>(i1 * (contextType(1)..expectStaticType<Exactly<num>>()));
  context<num>(i1 % (contextType(1)..expectStaticType<Exactly<num>>()));
  context<num>(i1.remainder(contextType(1)..expectStaticType<Exactly<num>>()));

  context<num>(d1 + (contextType(1)..expectStaticType<Exactly<num>>()));
  context<num>(d1 - (contextType(1)..expectStaticType<Exactly<num>>()));
  context<num>(d1 * (contextType(1)..expectStaticType<Exactly<num>>()));
  context<num>(d1 % (contextType(1)..expectStaticType<Exactly<num>>()));
  context<num>(d1.remainder(contextType(1)..expectStaticType<Exactly<num>>()));

  context<num>(n1 + (contextType(1)..expectStaticType<Exactly<num>>()));
  context<num>(n1 - (contextType(1)..expectStaticType<Exactly<num>>()));
  context<num>(n1 * (contextType(1)..expectStaticType<Exactly<num>>()));
  context<num>(n1 % (contextType(1)..expectStaticType<Exactly<num>>()));
  context<num>(n1.remainder(contextType(1)..expectStaticType<Exactly<num>>()));

  context<num>(n + (contextType(1)..expectStaticType<Exactly<num>>()));
  context<num>(n - (contextType(1)..expectStaticType<Exactly<num>>()));
  context<num>(n * (contextType(1)..expectStaticType<Exactly<num>>()));
  context<num>(n % (contextType(1)..expectStaticType<Exactly<num>>()));
  context<num>(n.remainder(contextType(1)..expectStaticType<Exactly<num>>()));

  context<num>(o + (contextType(1)..expectStaticType<Exactly<num>>()));
  context<num>(o - (contextType(1)..expectStaticType<Exactly<num>>()));
  context<num>(o * (contextType(1)..expectStaticType<Exactly<num>>()));
  context<num>(o % (contextType(1)..expectStaticType<Exactly<num>>()));
  context<num>(o.remainder(contextType(1)..expectStaticType<Exactly<num>>()));

  context<num>(o.clamp(contextType(1)..expectStaticType<Exactly<num>>(),
      contextType(1)..expectStaticType<Exactly<num>>()));
}
