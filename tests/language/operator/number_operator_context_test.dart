// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the new context type rules for number operators,
// as modified by Null Safety
import "static_type_helper.dart";

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

  context<I>(i + (contextType(1)..expectStaticType<Exactly<int>>()));
  context<I>(i - (contextType(1)..expectStaticType<Exactly<int>>()));
  context<I>(i * (contextType(1)..expectStaticType<Exactly<int>>()));
  context<I>(i % (contextType(1)..expectStaticType<Exactly<int>>()));
  context<I>(i.remainder(contextType(1)..expectStaticType<Exactly<int>>()));

  context<num>(1 + (contextType(1)..expectStaticType<Exactly<num>>()));
  context<num>(1 - (contextType(1)..expectStaticType<Exactly<num>>()));
  context<num>(1 * (contextType(1)..expectStaticType<Exactly<num>>()));
  context<num>(1 % (contextType(1)..expectStaticType<Exactly<num>>()));
  context<num>(1.remainder(contextType(1)..expectStaticType<Exactly<num>>()));

  var oi = o;
  if (oi is! int) throw "promote oi to O&int";

  context<int>(oi + (contextType(1)..expectStaticType<Exactly<int>>()));
  context<int>(oi - (contextType(1)..expectStaticType<Exactly<int>>()));
  context<int>(oi * (contextType(1)..expectStaticType<Exactly<int>>()));
  context<int>(oi % (contextType(1)..expectStaticType<Exactly<int>>()));
  context<int>(oi.remainder(contextType(1)..expectStaticType<Exactly<int>>()));

  i += contextType(1)..expectStaticType<Exactly<int>>();
  i -= contextType(1)..expectStaticType<Exactly<int>>();
  i *= contextType(1)..expectStaticType<Exactly<int>>();
  i %= contextType(1)..expectStaticType<Exactly<int>>();

  oi += contextType(1)..expectStaticType<Exactly<int>>();
  oi -= contextType(1)..expectStaticType<Exactly<int>>();
  oi *= contextType(1)..expectStaticType<Exactly<int>>();
  oi %= contextType(2)..expectStaticType<Exactly<int>>();

  context<int>(1.clamp(contextType(1)..expectStaticType<Exactly<int>>(),
      contextType(1)..expectStaticType<Exactly<int>>()));

  context<int>(i.clamp(contextType(1)..expectStaticType<Exactly<int>>(),
      contextType(1)..expectStaticType<Exactly<int>>()));

  context<I>(i.clamp(contextType(1)..expectStaticType<Exactly<I>>(),
      contextType(1)..expectStaticType<Exactly<I>>()));

  context<int>(oi.clamp(contextType(1)..expectStaticType<Exactly<int>>(),
      contextType(1)..expectStaticType<Exactly<int>>()));

  context<I>(i.clamp(contextType(1)..expectStaticType<Exactly<I>>(),
      contextType(1)..expectStaticType<Exactly<I>>()));
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

  context<D>(1 + (contextType(1)..expectStaticType<Exactly<double>>()));
  context<D>(1 - (contextType(1)..expectStaticType<Exactly<double>>()));
  context<D>(1 * (contextType(1)..expectStaticType<Exactly<double>>()));
  context<D>(1 % (contextType(1)..expectStaticType<Exactly<double>>()));
  context<D>(1.remainder(contextType(1)..expectStaticType<Exactly<double>>()));

  context<D>(d + (contextType(1.0)..expectStaticType<Exactly<num>>()));
  context<D>(d - (contextType(1.0)..expectStaticType<Exactly<num>>()));
  context<D>(d * (contextType(1.0)..expectStaticType<Exactly<num>>()));
  context<D>(d % (contextType(1.0)..expectStaticType<Exactly<num>>()));
  context<D>(d.remainder(contextType(1.0)..expectStaticType<Exactly<num>>()));

  // The context type also causes double literals.
  context<double>(1 + (1..expectStaticType<double>()));
  context<double>(1 - (1..expectStaticType<double>()));
  context<double>(1 * (1..expectStaticType<double>()));
  context<double>(1 % (1..expectStaticType<double>()));
  context<double>(1.remainder(1..expectStaticType<double>()));

  var od = o;
  if (od is! double) throw "promote od to O&double";

  context<double>(od + (contextType(1.0)..expectStaticType<Exactly<num>>()));
  context<double>(od - (contextType(1.0)..expectStaticType<Exactly<num>>()));
  context<double>(od * (contextType(1.0)..expectStaticType<Exactly<num>>()));
  context<double>(od % (contextType(1.0)..expectStaticType<Exactly<num>>()));
  context<double>(
      od.remainder(contextType(1.0)..expectStaticType<Exactly<num>>()));

  d += contextType(1)..expectStaticType<Exactly<num>>();
  d -= contextType(1)..expectStaticType<Exactly<num>>();
  d *= contextType(1)..expectStaticType<Exactly<num>>();
  d %= contextType(2)..expectStaticType<Exactly<num>>();

  od += contextType(1)..expectStaticType<Exactly<num>>();
  od -= contextType(1)..expectStaticType<Exactly<num>>();
  od *= contextType(1)..expectStaticType<Exactly<num>>();
  od %= contextType(2)..expectStaticType<Exactly<num>>();

  context<double>(1.1.clamp(
      contextType(1.0)..expectStaticType<Exactly<double>>(),
      contextType(1.0)..expectStaticType<Exactly<double>>()));

  context<double>(d.clamp(contextType(1.0)..expectStaticType<Exactly<double>>(),
      contextType(1.0)..expectStaticType<Exactly<double>>()));

  context<D>(d.clamp(contextType(1.0)..expectStaticType<Exactly<D>>(),
      contextType(1.0)..expectStaticType<Exactly<D>>()));

  context<double>(od.clamp(
      contextType(1.0)..expectStaticType<Exactly<double>>(),
      contextType(1.0)..expectStaticType<Exactly<double>>()));

  context<D>(od.clamp(contextType(1.0)..expectStaticType<Exactly<D>>(),
      contextType(1.0)..expectStaticType<Exactly<D>>()));
}

void testNumContext<N extends num, O extends Object>(N n, O o) {
  if (o is! num) throw "promote o to O&num";

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

  context<N>(n.clamp(contextType(1)..expectStaticType<Exactly<N>>(),
      contextType(1)..expectStaticType<Exactly<N>>()));
}
