// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the rules for static types of number operators,
// as modified by Null Safety
import "static_type_helper.dart";

// ignore_for_file: receiver_of_type_never

// The typing rules for `e` of the form:
// * `e1 op e2` (op in `+`, `-`, `*` or `%`), or
// * `e1.remainder(e2)`,
//
// where *T* is the static type of `e1`, *S* is the static type of `e2`
// and *T* is a non-`Never` subtype of `num`.
//
// * If *T* <: `double`, then the static type of `e` is *T*.
// * Otherwise, if *S* is a non-`Never` subtype of `double`
//   then the static type of `e` is `double`.
// * Otherwise, if *S* is a non-`Never` subtype of `int`
//   then the static type of `e` is *T*.
// * Otherwise, if *S* is a non-`Never` subtype of *T*,
//   then the static type of `e` is *T*.
// * Otherwise the static type of *e* is `num`.
//
// For `e1.clamp(e2, e3)` where
// * *T1* is the static type of `e1`,
// * *T2* is the static type of `e2`,
// * *T3* is the static type of `e3`,
//
// and T1 is a non-`Never` subtype of `num`, the static type is:
//    min(num, LUB(T1, T2, T3))
// (That is, the LUB if it's a subtype of `num`, otherwise `num`.)

main() {
  testPlainVariables(1, 1.0, 1);
  testPromotedVariables(1, 1.0, 1);
  testTypeVariables<int, double, int>(1, 1.0, 1);
  testPromotedTypeVariables<Object>(1, 1.0, 1);
  testComplex<int, double, num, Object, num>(1, 1.0, 1, 1, 1);
  const TestConst<int, double, num>(1, 1.0, 1);
}

final num n1 = 1;
final num n2 = 2;
final int i1 = 1;
final int i2 = 2;
final dynamic dyn1 = 1;
final dynamic dyn2 = 2;
late final Never never = throw "unreachable"; // Only used for static tests.

// Check the static type of operations on plain variables.
void testPlainVariables(int i, double d, num n) {
  (i + i).expectStaticType<Exactly<int>>();
  (i - i).expectStaticType<Exactly<int>>();
  (i * i).expectStaticType<Exactly<int>>();
  (i % i).expectStaticType<Exactly<int>>();
  i.remainder(i).expectStaticType<Exactly<int>>();

  (d + i).expectStaticType<Exactly<double>>();
  (d - i).expectStaticType<Exactly<double>>();
  (d * i).expectStaticType<Exactly<double>>();
  (d % i).expectStaticType<Exactly<double>>();
  d.remainder(i).expectStaticType<Exactly<double>>();

  (i + d).expectStaticType<Exactly<double>>();
  (i - d).expectStaticType<Exactly<double>>();
  (i * d).expectStaticType<Exactly<double>>();
  (i % d).expectStaticType<Exactly<double>>();
  i.remainder(d).expectStaticType<Exactly<double>>();

  (n + i).expectStaticType<Exactly<num>>();
  (n - i).expectStaticType<Exactly<num>>();
  (n * i).expectStaticType<Exactly<num>>();
  (n % i).expectStaticType<Exactly<num>>();
  n.remainder(i).expectStaticType<Exactly<num>>();

  (i + n).expectStaticType<Exactly<num>>();
  (i - n).expectStaticType<Exactly<num>>();
  (i * n).expectStaticType<Exactly<num>>();
  (i % n).expectStaticType<Exactly<num>>();
  i.remainder(n).expectStaticType<Exactly<num>>();

  (i + dyn1).expectStaticType<Exactly<num>>();
  (i - dyn1).expectStaticType<Exactly<num>>();
  (i * dyn1).expectStaticType<Exactly<num>>();
  (i % dyn1).expectStaticType<Exactly<num>>();
  i.remainder(dyn1).expectStaticType<Exactly<num>>();

  (d + d).expectStaticType<Exactly<double>>();
  (d - d).expectStaticType<Exactly<double>>();
  (d * d).expectStaticType<Exactly<double>>();
  (d % d).expectStaticType<Exactly<double>>();
  d.remainder(d).expectStaticType<Exactly<double>>();

  (d + n).expectStaticType<Exactly<double>>();
  (d - n).expectStaticType<Exactly<double>>();
  (d * n).expectStaticType<Exactly<double>>();
  (d % n).expectStaticType<Exactly<double>>();
  d.remainder(n).expectStaticType<Exactly<double>>();

  (d + dyn1).expectStaticType<Exactly<double>>();
  (d - dyn1).expectStaticType<Exactly<double>>();
  (d * dyn1).expectStaticType<Exactly<double>>();
  (d % dyn1).expectStaticType<Exactly<double>>();
  d.remainder(dyn1).expectStaticType<Exactly<double>>();

  (n + d).expectStaticType<Exactly<double>>();
  (n - d).expectStaticType<Exactly<double>>();
  (n * d).expectStaticType<Exactly<double>>();
  (n % d).expectStaticType<Exactly<double>>();
  n.remainder(d).expectStaticType<Exactly<double>>();

  (n + n).expectStaticType<Exactly<num>>();
  (n - n).expectStaticType<Exactly<num>>();
  (n * n).expectStaticType<Exactly<num>>();
  (n % n).expectStaticType<Exactly<num>>();
  n.remainder(n).expectStaticType<Exactly<num>>();

  (n + dyn1).expectStaticType<Exactly<num>>();
  (n - dyn1).expectStaticType<Exactly<num>>();
  (n * dyn1).expectStaticType<Exactly<num>>();
  (n % dyn1).expectStaticType<Exactly<num>>();
  n.remainder(dyn1).expectStaticType<Exactly<num>>();

  if (false) {
    // Only for the static checks
    // since we have sub-expressions of type Never.
    (i + never).expectStaticType<Exactly<num>>();
    (i - never).expectStaticType<Exactly<num>>();
    (i * never).expectStaticType<Exactly<num>>();
    (i % never).expectStaticType<Exactly<num>>();
    i.remainder(never).expectStaticType<Exactly<num>>();

    (d + never).expectStaticType<Exactly<double>>();
    (d - never).expectStaticType<Exactly<double>>();
    (d * never).expectStaticType<Exactly<double>>();
    (d % never).expectStaticType<Exactly<double>>();
    d.remainder(never).expectStaticType<Exactly<double>>();

    (n + never).expectStaticType<Exactly<num>>();
    (n - never).expectStaticType<Exactly<num>>();
    (n * never).expectStaticType<Exactly<num>>();
    (n % never).expectStaticType<Exactly<num>>();
    n.remainder(never).expectStaticType<Exactly<num>>();

    (never + d).expectStaticType<Exactly<Never>>();
    (never - d).expectStaticType<Exactly<Never>>();
    (never * d).expectStaticType<Exactly<Never>>();
    (never % d).expectStaticType<Exactly<Never>>();
    never.remainder(d).expectStaticType<Exactly<Never>>();
  }

  i.clamp(i, i).expectStaticType<Exactly<int>>();
  d.clamp(d, d).expectStaticType<Exactly<double>>();

  i.clamp(i, d).expectStaticType<Exactly<num>>();
  i.clamp(d, i).expectStaticType<Exactly<num>>();
  d.clamp(i, i).expectStaticType<Exactly<num>>();
  i.clamp(d, d).expectStaticType<Exactly<num>>();
  d.clamp(i, d).expectStaticType<Exactly<num>>();
  d.clamp(d, i).expectStaticType<Exactly<num>>();

  i.clamp(i, n).expectStaticType<Exactly<num>>();
  i.clamp(n, i).expectStaticType<Exactly<num>>();
  n.clamp(i, i).expectStaticType<Exactly<num>>();
  d.clamp(d, n).expectStaticType<Exactly<num>>();
  d.clamp(n, d).expectStaticType<Exactly<num>>();
  n.clamp(d, d).expectStaticType<Exactly<num>>();

  i.clamp(i, dyn1).expectStaticType<Exactly<num>>();
  i.clamp(dyn1, i).expectStaticType<Exactly<num>>();
  d.clamp(d, dyn1).expectStaticType<Exactly<num>>();
  d.clamp(dyn1, d).expectStaticType<Exactly<num>>();
  n.clamp(n, dyn1).expectStaticType<Exactly<num>>();
  n.clamp(dyn1, n).expectStaticType<Exactly<num>>();

  if (false) {
    i.clamp(i, never).expectStaticType<Exactly<int>>();
    d.clamp(d, never).expectStaticType<Exactly<double>>();
    n.clamp(n, never).expectStaticType<Exactly<num>>();
    never.clamp(i, i).expectStaticType<Exactly<Never>>();
  }
  ;

  (i += i1).expectStaticType<Exactly<int>>();
  (i -= i1).expectStaticType<Exactly<int>>();
  (i *= i1).expectStaticType<Exactly<int>>();
  (i %= i2).expectStaticType<Exactly<int>>();
  (i++).expectStaticType<Exactly<int>>();
  (i--).expectStaticType<Exactly<int>>();
  (++i).expectStaticType<Exactly<int>>();
  (--i).expectStaticType<Exactly<int>>();

  (d += i1).expectStaticType<Exactly<double>>();
  (d -= i1).expectStaticType<Exactly<double>>();
  (d *= i1).expectStaticType<Exactly<double>>();
  (d %= i2).expectStaticType<Exactly<double>>();
  (d += 1.0).expectStaticType<Exactly<double>>();
  (d -= 1.0).expectStaticType<Exactly<double>>();
  (d *= 1.0).expectStaticType<Exactly<double>>();
  (d %= 1.0).expectStaticType<Exactly<double>>();
  (d += n1).expectStaticType<Exactly<double>>();
  (d -= n1).expectStaticType<Exactly<double>>();
  (d *= n1).expectStaticType<Exactly<double>>();
  (d %= n2).expectStaticType<Exactly<double>>();
  (d += dyn1).expectStaticType<Exactly<double>>();
  (d -= dyn1).expectStaticType<Exactly<double>>();
  (d *= dyn1).expectStaticType<Exactly<double>>();
  (d %= dyn2).expectStaticType<Exactly<double>>();
  (d++).expectStaticType<Exactly<double>>();
  (d--).expectStaticType<Exactly<double>>();
  (++d).expectStaticType<Exactly<double>>();
  (--d).expectStaticType<Exactly<double>>();

  (n += i1).expectStaticType<Exactly<num>>();
  (n -= i1).expectStaticType<Exactly<num>>();
  (n *= i1).expectStaticType<Exactly<num>>();
  (n %= i2).expectStaticType<Exactly<num>>();
  (n += 1.0).expectStaticType<Exactly<double>>();
  (n -= 1.0).expectStaticType<Exactly<double>>();
  (n *= 1.0).expectStaticType<Exactly<double>>();
  (n %= 1.0).expectStaticType<Exactly<double>>();
  (n += n1).expectStaticType<Exactly<num>>();
  (n -= n1).expectStaticType<Exactly<num>>();
  (n *= n1).expectStaticType<Exactly<num>>();
  (n %= n2).expectStaticType<Exactly<num>>();
  (n += dyn1).expectStaticType<Exactly<num>>();
  (n -= dyn1).expectStaticType<Exactly<num>>();
  (n *= dyn1).expectStaticType<Exactly<num>>();
  (n %= dyn2).expectStaticType<Exactly<num>>();
  (n++).expectStaticType<Exactly<num>>();
  (n--).expectStaticType<Exactly<num>>();
  (++n).expectStaticType<Exactly<num>>();
  (--n).expectStaticType<Exactly<num>>();

  if (false) {
    (d += never).expectStaticType<Exactly<double>>();
    (n += never).expectStaticType<Exactly<num>>();
  }
}

// Check the static type of operations on promoted variables.
void testPromotedVariables(Object i, Object d, Object n) {
  if (i is! int) throw "promote i to int";
  if (d is! double) throw "promote d to double";
  if (n is! num) throw "promote n to num";
  i.expectStaticType<Exactly<int>>();
  d.expectStaticType<Exactly<double>>();
  n.expectStaticType<Exactly<num>>();

  (i + i).expectStaticType<Exactly<int>>();
  (i - i).expectStaticType<Exactly<int>>();
  (i * i).expectStaticType<Exactly<int>>();
  (i % i).expectStaticType<Exactly<int>>();
  i.remainder(i).expectStaticType<Exactly<int>>();

  (d + i).expectStaticType<Exactly<double>>();
  (d - i).expectStaticType<Exactly<double>>();
  (d * i).expectStaticType<Exactly<double>>();
  (d % i).expectStaticType<Exactly<double>>();
  d.remainder(i).expectStaticType<Exactly<double>>();

  (i + d).expectStaticType<Exactly<double>>();
  (i - d).expectStaticType<Exactly<double>>();
  (i * d).expectStaticType<Exactly<double>>();
  (i % d).expectStaticType<Exactly<double>>();
  i.remainder(d).expectStaticType<Exactly<double>>();

  (n + i).expectStaticType<Exactly<num>>();
  (n - i).expectStaticType<Exactly<num>>();
  (n * i).expectStaticType<Exactly<num>>();
  (n % i).expectStaticType<Exactly<num>>();
  n.remainder(i).expectStaticType<Exactly<num>>();

  (i + n).expectStaticType<Exactly<num>>();
  (i - n).expectStaticType<Exactly<num>>();
  (i * n).expectStaticType<Exactly<num>>();
  (i % n).expectStaticType<Exactly<num>>();
  i.remainder(n).expectStaticType<Exactly<num>>();

  (i + dyn1).expectStaticType<Exactly<num>>();
  (i - dyn1).expectStaticType<Exactly<num>>();
  (i * dyn1).expectStaticType<Exactly<num>>();
  (i % dyn1).expectStaticType<Exactly<num>>();
  i.remainder(dyn1).expectStaticType<Exactly<num>>();

  (d + d).expectStaticType<Exactly<double>>();
  (d - d).expectStaticType<Exactly<double>>();
  (d * d).expectStaticType<Exactly<double>>();
  (d % d).expectStaticType<Exactly<double>>();
  d.remainder(d).expectStaticType<Exactly<double>>();

  (d + n).expectStaticType<Exactly<double>>();
  (d - n).expectStaticType<Exactly<double>>();
  (d * n).expectStaticType<Exactly<double>>();
  (d % n).expectStaticType<Exactly<double>>();
  d.remainder(n).expectStaticType<Exactly<double>>();

  (d + dyn1).expectStaticType<Exactly<double>>();
  (d - dyn1).expectStaticType<Exactly<double>>();
  (d * dyn1).expectStaticType<Exactly<double>>();
  (d % dyn1).expectStaticType<Exactly<double>>();
  d.remainder(dyn1).expectStaticType<Exactly<double>>();

  (n + d).expectStaticType<Exactly<double>>();
  (n - d).expectStaticType<Exactly<double>>();
  (n * d).expectStaticType<Exactly<double>>();
  (n % d).expectStaticType<Exactly<double>>();
  n.remainder(d).expectStaticType<Exactly<double>>();

  (n + n).expectStaticType<Exactly<num>>();
  (n - n).expectStaticType<Exactly<num>>();
  (n * n).expectStaticType<Exactly<num>>();
  (n % n).expectStaticType<Exactly<num>>();
  n.remainder(n).expectStaticType<Exactly<num>>();

  (n + dyn1).expectStaticType<Exactly<num>>();
  (n - dyn1).expectStaticType<Exactly<num>>();
  (n * dyn1).expectStaticType<Exactly<num>>();
  (n % dyn1).expectStaticType<Exactly<num>>();
  n.remainder(dyn1).expectStaticType<Exactly<num>>();

  if (false) {
    (i + never).expectStaticType<Exactly<num>>();
    (i - never).expectStaticType<Exactly<num>>();
    (i * never).expectStaticType<Exactly<num>>();
    (i % never).expectStaticType<Exactly<num>>();
    i.remainder(never).expectStaticType<Exactly<num>>();

    (d + never).expectStaticType<Exactly<double>>();
    (d - never).expectStaticType<Exactly<double>>();
    (d * never).expectStaticType<Exactly<double>>();
    (d % never).expectStaticType<Exactly<double>>();
    d.remainder(never).expectStaticType<Exactly<double>>();

    (n + never).expectStaticType<Exactly<num>>();
    (n - never).expectStaticType<Exactly<num>>();
    (n * never).expectStaticType<Exactly<num>>();
    (n % never).expectStaticType<Exactly<num>>();
    n.remainder(never).expectStaticType<Exactly<num>>();

    (never + d).expectStaticType<Exactly<Never>>();
    (never - d).expectStaticType<Exactly<Never>>();
    (never * d).expectStaticType<Exactly<Never>>();
    (never % d).expectStaticType<Exactly<Never>>();
    never.remainder(double).expectStaticType<Exactly<Never>>();
  }

  i.clamp(i, i).expectStaticType<Exactly<int>>();
  d.clamp(d, d).expectStaticType<Exactly<double>>();

  i.clamp(i, d).expectStaticType<Exactly<num>>();
  i.clamp(d, i).expectStaticType<Exactly<num>>();
  d.clamp(i, i).expectStaticType<Exactly<num>>();
  i.clamp(d, d).expectStaticType<Exactly<num>>();
  d.clamp(i, d).expectStaticType<Exactly<num>>();
  d.clamp(d, i).expectStaticType<Exactly<num>>();

  i.clamp(i, n).expectStaticType<Exactly<num>>();
  i.clamp(n, i).expectStaticType<Exactly<num>>();
  n.clamp(i, i).expectStaticType<Exactly<num>>();
  d.clamp(d, n).expectStaticType<Exactly<num>>();
  d.clamp(n, d).expectStaticType<Exactly<num>>();
  n.clamp(d, d).expectStaticType<Exactly<num>>();

  i.clamp(i, dyn1).expectStaticType<Exactly<num>>();
  i.clamp(dyn1, i).expectStaticType<Exactly<num>>();
  d.clamp(d, dyn1).expectStaticType<Exactly<num>>();
  d.clamp(dyn1, d).expectStaticType<Exactly<num>>();
  n.clamp(n, dyn1).expectStaticType<Exactly<num>>();
  n.clamp(dyn1, n).expectStaticType<Exactly<num>>();

  if (false) {
    i.clamp(i, never).expectStaticType<Exactly<int>>();
    d.clamp(d, never).expectStaticType<Exactly<double>>();
    n.clamp(n, never).expectStaticType<Exactly<num>>();
    never.clamp(i, i).expectStaticType<Exactly<Never>>();
  }
  ;
  (i += i1).expectStaticType<Exactly<int>>();
  (i -= i1).expectStaticType<Exactly<int>>();
  (i *= i1).expectStaticType<Exactly<int>>();
  (i %= i2).expectStaticType<Exactly<int>>();
  (i++).expectStaticType<Exactly<int>>();
  (i--).expectStaticType<Exactly<int>>();
  (++i).expectStaticType<Exactly<int>>();
  (--i).expectStaticType<Exactly<int>>();

  (d += i1).expectStaticType<Exactly<double>>();
  (d -= i1).expectStaticType<Exactly<double>>();
  (d *= i1).expectStaticType<Exactly<double>>();
  (d %= i2).expectStaticType<Exactly<double>>();
  (d += 1.0).expectStaticType<Exactly<double>>();
  (d -= 1.0).expectStaticType<Exactly<double>>();
  (d *= 1.0).expectStaticType<Exactly<double>>();
  (d %= 1.0).expectStaticType<Exactly<double>>();
  (d += n1).expectStaticType<Exactly<double>>();
  (d -= n1).expectStaticType<Exactly<double>>();
  (d *= n1).expectStaticType<Exactly<double>>();
  (d %= n2).expectStaticType<Exactly<double>>();
  (d += dyn1).expectStaticType<Exactly<double>>();
  (d -= dyn1).expectStaticType<Exactly<double>>();
  (d *= dyn1).expectStaticType<Exactly<double>>();
  (d %= dyn2).expectStaticType<Exactly<double>>();
  (d++).expectStaticType<Exactly<double>>();
  (d--).expectStaticType<Exactly<double>>();
  (++d).expectStaticType<Exactly<double>>();
  (--d).expectStaticType<Exactly<double>>();

  (n += i1).expectStaticType<Exactly<num>>();
  (n -= i1).expectStaticType<Exactly<num>>();
  (n *= i1).expectStaticType<Exactly<num>>();
  (n %= i2).expectStaticType<Exactly<num>>();
  (n += 1.0).expectStaticType<Exactly<double>>();
  (n -= 1.0).expectStaticType<Exactly<double>>();
  (n *= 1.0).expectStaticType<Exactly<double>>();
  (n %= 1.0).expectStaticType<Exactly<double>>();
  (n += n1).expectStaticType<Exactly<num>>();
  (n -= n1).expectStaticType<Exactly<num>>();
  (n *= n1).expectStaticType<Exactly<num>>();
  (n %= n2).expectStaticType<Exactly<num>>();
  (n += dyn1).expectStaticType<Exactly<num>>();
  (n -= dyn1).expectStaticType<Exactly<num>>();
  (n *= dyn1).expectStaticType<Exactly<num>>();
  (n %= dyn2).expectStaticType<Exactly<num>>();
  (n++).expectStaticType<Exactly<num>>();
  (n--).expectStaticType<Exactly<num>>();
  (++n).expectStaticType<Exactly<num>>();
  (--n).expectStaticType<Exactly<num>>();

  if (false) {
    (d += never).expectStaticType<Exactly<double>>();
    (n += never).expectStaticType<Exactly<num>>();
  }
}

// Check the static type of operations on promoted variables.
void testTypeVariables<I extends int, D extends double, N extends num>(
    I i, D d, N n) {
  int ii = i; // Actual int type.

  (ii + i).expectStaticType<Exactly<int>>();
  (ii - i).expectStaticType<Exactly<int>>();
  (ii * i).expectStaticType<Exactly<int>>();
  (ii % i).expectStaticType<Exactly<int>>();
  ii.remainder(i).expectStaticType<Exactly<int>>();

  (i + ii).expectStaticType<Exactly<I>>();
  (i - ii).expectStaticType<Exactly<I>>();
  (i * ii).expectStaticType<Exactly<I>>();
  (i % ii).expectStaticType<Exactly<I>>();
  i.remainder(ii).expectStaticType<Exactly<I>>();

  (i + i).expectStaticType<Exactly<I>>();
  (i - i).expectStaticType<Exactly<I>>();
  (i * i).expectStaticType<Exactly<I>>();
  (i % i).expectStaticType<Exactly<I>>();
  i.remainder(i).expectStaticType<Exactly<I>>();

  (d + i).expectStaticType<Exactly<D>>();
  (d - i).expectStaticType<Exactly<D>>();
  (d * i).expectStaticType<Exactly<D>>();
  (d % i).expectStaticType<Exactly<D>>();
  d.remainder(i).expectStaticType<Exactly<D>>();

  (i + d).expectStaticType<Exactly<double>>();
  (i - d).expectStaticType<Exactly<double>>();
  (i * d).expectStaticType<Exactly<double>>();
  (i % d).expectStaticType<Exactly<double>>();
  i.remainder(d).expectStaticType<Exactly<double>>();

  (n + i).expectStaticType<Exactly<N>>();
  (n - i).expectStaticType<Exactly<N>>();
  (n * i).expectStaticType<Exactly<N>>();
  (n % i).expectStaticType<Exactly<N>>();
  n.remainder(i).expectStaticType<Exactly<N>>();

  (i + n).expectStaticType<Exactly<num>>();
  (i - n).expectStaticType<Exactly<num>>();
  (i * n).expectStaticType<Exactly<num>>();
  (i % n).expectStaticType<Exactly<num>>();
  i.remainder(n).expectStaticType<Exactly<num>>();

  (i + dyn1).expectStaticType<Exactly<num>>();
  (i - dyn1).expectStaticType<Exactly<num>>();
  (i * dyn1).expectStaticType<Exactly<num>>();
  (i % dyn1).expectStaticType<Exactly<num>>();
  i.remainder(dyn1).expectStaticType<Exactly<num>>();

  double dd = d; // Actual double type.

  (dd + d).expectStaticType<Exactly<double>>();
  (dd - d).expectStaticType<Exactly<double>>();
  (dd * d).expectStaticType<Exactly<double>>();
  (dd % d).expectStaticType<Exactly<double>>();
  dd.remainder(d).expectStaticType<Exactly<double>>();

  (d + dd).expectStaticType<Exactly<D>>();
  (d - dd).expectStaticType<Exactly<D>>();
  (d * dd).expectStaticType<Exactly<D>>();
  (d % dd).expectStaticType<Exactly<D>>();
  d.remainder(dd).expectStaticType<Exactly<D>>();

  (d + d).expectStaticType<Exactly<D>>();
  (d - d).expectStaticType<Exactly<D>>();
  (d * d).expectStaticType<Exactly<D>>();
  (d % d).expectStaticType<Exactly<D>>();
  d.remainder(d).expectStaticType<Exactly<D>>();

  (d + n).expectStaticType<Exactly<D>>();
  (d - n).expectStaticType<Exactly<D>>();
  (d * n).expectStaticType<Exactly<D>>();
  (d % n).expectStaticType<Exactly<D>>();
  d.remainder(n).expectStaticType<Exactly<D>>();

  (d + dyn1).expectStaticType<Exactly<D>>();
  (d - dyn1).expectStaticType<Exactly<D>>();
  (d * dyn1).expectStaticType<Exactly<D>>();
  (d % dyn1).expectStaticType<Exactly<D>>();
  d.remainder(dyn1).expectStaticType<Exactly<D>>();

  (n + d).expectStaticType<Exactly<double>>();
  (n - d).expectStaticType<Exactly<double>>();
  (n * d).expectStaticType<Exactly<double>>();
  (n % d).expectStaticType<Exactly<double>>();
  n.remainder(d).expectStaticType<Exactly<double>>();

  num nn = n; // Actual num type.

  (nn + n).expectStaticType<Exactly<num>>();
  (nn - n).expectStaticType<Exactly<num>>();
  (nn * n).expectStaticType<Exactly<num>>();
  (nn % n).expectStaticType<Exactly<num>>();
  nn.remainder(n).expectStaticType<Exactly<num>>();

  (n + nn).expectStaticType<Exactly<num>>();
  (n - nn).expectStaticType<Exactly<num>>();
  (n * nn).expectStaticType<Exactly<num>>();
  (n % nn).expectStaticType<Exactly<num>>();
  n.remainder(nn).expectStaticType<Exactly<num>>();

  (n + n).expectStaticType<Exactly<N>>();
  (n - n).expectStaticType<Exactly<N>>();
  (n * n).expectStaticType<Exactly<N>>();
  (n % n).expectStaticType<Exactly<N>>();
  n.remainder(n).expectStaticType<Exactly<N>>();

  (n + dyn1).expectStaticType<Exactly<num>>();
  (n - dyn1).expectStaticType<Exactly<num>>();
  (n * dyn1).expectStaticType<Exactly<num>>();
  (n % dyn1).expectStaticType<Exactly<num>>();
  n.remainder(dyn1).expectStaticType<Exactly<num>>();

  if (false) {
    (i + never).expectStaticType<Exactly<num>>();
    (i - never).expectStaticType<Exactly<num>>();
    (i * never).expectStaticType<Exactly<num>>();
    (i % never).expectStaticType<Exactly<num>>();
    i.remainder(never).expectStaticType<Exactly<num>>();

    (d + never).expectStaticType<Exactly<D>>();
    (d - never).expectStaticType<Exactly<D>>();
    (d * never).expectStaticType<Exactly<D>>();
    (d % never).expectStaticType<Exactly<D>>();
    d.remainder(never).expectStaticType<Exactly<D>>();

    (n + never).expectStaticType<Exactly<num>>();
    (n - never).expectStaticType<Exactly<num>>();
    (n * never).expectStaticType<Exactly<num>>();
    (n % never).expectStaticType<Exactly<num>>();
    n.remainder(never).expectStaticType<Exactly<num>>();

    (never + d).expectStaticType<Exactly<Never>>();
    (never - d).expectStaticType<Exactly<Never>>();
    (never * d).expectStaticType<Exactly<Never>>();
    (never % d).expectStaticType<Exactly<Never>>();
    never.remainder(d).expectStaticType<Exactly<Never>>();
  }
  i.clamp(i, i).expectStaticType<Exactly<I>>();
  i.clamp(i, ii).expectStaticType<Exactly<int>>();
  i.clamp(ii, i).expectStaticType<Exactly<int>>();
  ii.clamp(i, i).expectStaticType<Exactly<int>>();

  d.clamp(d, d).expectStaticType<Exactly<D>>();
  d.clamp(d, dd).expectStaticType<Exactly<double>>();
  d.clamp(dd, d).expectStaticType<Exactly<double>>();
  dd.clamp(d, d).expectStaticType<Exactly<double>>();

  n.clamp(n, n).expectStaticType<Exactly<N>>();
  n.clamp(n, nn).expectStaticType<Exactly<num>>();
  n.clamp(nn, n).expectStaticType<Exactly<num>>();
  nn.clamp(n, n).expectStaticType<Exactly<num>>();

  i.clamp(i, d).expectStaticType<Exactly<num>>();
  i.clamp(d, i).expectStaticType<Exactly<num>>();
  d.clamp(i, i).expectStaticType<Exactly<num>>();
  i.clamp(d, d).expectStaticType<Exactly<num>>();
  d.clamp(i, d).expectStaticType<Exactly<num>>();
  d.clamp(d, i).expectStaticType<Exactly<num>>();

  i.clamp(i, n).expectStaticType<Exactly<num>>();
  i.clamp(n, i).expectStaticType<Exactly<num>>();
  n.clamp(i, i).expectStaticType<Exactly<num>>();
  d.clamp(d, n).expectStaticType<Exactly<num>>();
  d.clamp(n, d).expectStaticType<Exactly<num>>();
  n.clamp(d, d).expectStaticType<Exactly<num>>();

  i.clamp(i, dyn1).expectStaticType<Exactly<num>>();
  i.clamp(dyn1, i).expectStaticType<Exactly<num>>();
  d.clamp(d, dyn1).expectStaticType<Exactly<num>>();
  d.clamp(dyn1, d).expectStaticType<Exactly<num>>();
  n.clamp(i, dyn1).expectStaticType<Exactly<num>>();
  n.clamp(dyn1, d).expectStaticType<Exactly<num>>();

  if (false) {
    i.clamp(i, never).expectStaticType<Exactly<I>>();
    d.clamp(d, never).expectStaticType<Exactly<D>>();
    n.clamp(n, never).expectStaticType<Exactly<N>>();
    never.clamp(i, i).expectStaticType<Exactly<Never>>();
  }
  ;

  (i += i1).expectStaticType<Exactly<I>>();
  (i -= i1).expectStaticType<Exactly<I>>();
  (i *= i1).expectStaticType<Exactly<I>>();
  (i %= i2).expectStaticType<Exactly<I>>();
  (i++).expectStaticType<Exactly<I>>();
  (i--).expectStaticType<Exactly<I>>();
  (++i).expectStaticType<Exactly<I>>();
  (--i).expectStaticType<Exactly<I>>();

  (d += i1).expectStaticType<Exactly<D>>();
  (d -= i1).expectStaticType<Exactly<D>>();
  (d *= i1).expectStaticType<Exactly<D>>();
  (d %= i2).expectStaticType<Exactly<D>>();
  (d += 1.0).expectStaticType<Exactly<D>>();
  (d -= 1.0).expectStaticType<Exactly<D>>();
  (d *= 1.0).expectStaticType<Exactly<D>>();
  (d %= 1.0).expectStaticType<Exactly<D>>();
  (d += n1).expectStaticType<Exactly<D>>();
  (d -= n1).expectStaticType<Exactly<D>>();
  (d *= n1).expectStaticType<Exactly<D>>();
  (d %= n2).expectStaticType<Exactly<D>>();
  (d += dyn1).expectStaticType<Exactly<D>>();
  (d -= dyn1).expectStaticType<Exactly<D>>();
  (d *= dyn1).expectStaticType<Exactly<D>>();
  (d %= dyn2).expectStaticType<Exactly<D>>();
  (d++).expectStaticType<Exactly<D>>();
  (d--).expectStaticType<Exactly<D>>();
  (++d).expectStaticType<Exactly<D>>();
  (--d).expectStaticType<Exactly<D>>();

  (n += i1).expectStaticType<Exactly<N>>();
  (n -= i1).expectStaticType<Exactly<N>>();
  (n *= i1).expectStaticType<Exactly<N>>();
  (n %= i2).expectStaticType<Exactly<N>>();
  (n += 1.0).expectStaticType<Exactly<double>>();
  (n -= 1.0).expectStaticType<Exactly<double>>();
  (n *= 1.0).expectStaticType<Exactly<double>>();
  (n %= 1.0).expectStaticType<Exactly<double>>();
  (n += n1).expectStaticType<Exactly<num>>();
  (n -= n1).expectStaticType<Exactly<num>>();
  (n *= n1).expectStaticType<Exactly<num>>();
  (n %= n2).expectStaticType<Exactly<num>>();
  (n += dyn1).expectStaticType<Exactly<num>>();
  (n -= dyn1).expectStaticType<Exactly<num>>();
  (n *= dyn1).expectStaticType<Exactly<num>>();
  (n %= dyn2).expectStaticType<Exactly<num>>();
  (n++).expectStaticType<Exactly<N>>();
  (n--).expectStaticType<Exactly<N>>();
  (++n).expectStaticType<Exactly<N>>();
  (--n).expectStaticType<Exactly<N>>();

  if (false) {
    (d += never).expectStaticType<Exactly<D>>();
  }

  Object on = 1;
  if (on is! N) throw "promote on to O&N";
  var onn = on;
  if (onn is! num) throw "promote onn O&N&num";

  // With three different type variable types,
  // still pick the LUB.
  n.clamp(on, onn).expectStaticType<Exactly<N>>();
  on.clamp(n, onn).expectStaticType<Exactly<N>>();
  onn.clamp(on, n).expectStaticType<Exactly<N>>();

  /// If the second operand of a binary oprator is a subtype of the first,
  /// the type is that of the first, even if both are subtypes of `num`.
  ///
  /// If one or more of the operands of `clamp` is a
  /// supertype of the others, the LUB is undefined.
  <X extends num, Y extends X, Z extends Y>(X x, Y y, Z z) {
    X n = x;
    (n += y).expectStaticType<Exactly<X>>();
    (n -= y).expectStaticType<Exactly<X>>();
    (n *= y).expectStaticType<Exactly<X>>();
    (n %= y).expectStaticType<Exactly<X>>();

    x.clamp(y, z).expectStaticType<Exactly<X>>();
    y.clamp(x, z).expectStaticType<Exactly<X>>();
    z.clamp(x, y).expectStaticType<Exactly<X>>();
    if (x is! Y) throw "promote x to X&Y";
    y.clamp(x, z).expectStaticType<Exactly<Y>>();
    if (x is! Z) throw "promote x to X&Y&Z";
    if (y is! Z) throw "promote x to Y&Z";
    y.clamp(x, z).expectStaticType<Exactly<Y>>();
    z.clamp(x, y).expectStaticType<Exactly<Z>>();
  }<num, num, num>(1, 1, 1);
}

// Check the static type of operations on promoted type variables.
void testPromotedTypeVariables<T>(T i, T d, T n) {
  if (i is! int) throw "promote i to T & int";
  if (d is! double) throw "promote d to T & double";
  if (n is! num) throw "promote n to T & num";
  // We cannot pass intersection types to type parameters,
  // so we need to check them in-place.
  // We check that the value is assignable to both types,
  // and are not dynamic (assignable to `Object`).
  checkIntersectionType<int, T>(i, i, i);
  checkIntersectionType<double, T>(d, d, d);
  checkIntersectionType<num, T>(n, n, n);

  int ii = i; // Actual integer type.

  (ii + i).expectStaticType<Exactly<int>>();
  (ii - i).expectStaticType<Exactly<int>>();
  (ii * i).expectStaticType<Exactly<int>>();
  (ii % i).expectStaticType<Exactly<int>>();
  ii.remainder(i).expectStaticType<Exactly<int>>();

  // Result type T&int
  var result11 = i + i;
  checkIntersectionType<int, T>(result11, result11, result11);
  var result12 = i - i;
  checkIntersectionType<int, T>(result12, result12, result12);
  var result13 = i * i;
  checkIntersectionType<int, T>(result13, result13, result13);
  var result14 = i % i;
  checkIntersectionType<int, T>(result14, result14, result14);
  var result15 = i.remainder(i);
  checkIntersectionType<int, T>(result15, result15, result15);

  // Result type T&int
  var result16 = i + ii;
  checkIntersectionType<int, T>(result16, result16, result16);
  var result17 = i - ii;
  checkIntersectionType<int, T>(result17, result17, result17);
  var result18 = i * ii;
  checkIntersectionType<int, T>(result18, result18, result18);
  var result19 = i % ii;
  checkIntersectionType<int, T>(result19, result19, result19);
  var result20 = i.remainder(ii);
  checkIntersectionType<int, T>(result20, result20, result20);

  // Result type T&double
  var result21 = (d + i);
  checkIntersectionType<double, T>(result21, result21, result21);
  var result22 = (d - i);
  checkIntersectionType<double, T>(result22, result22, result22);
  var result23 = (d * i);
  checkIntersectionType<double, T>(result23, result23, result23);
  var result24 = (d % i);
  checkIntersectionType<double, T>(result24, result24, result24);
  var result25 = d.remainder(i);
  checkIntersectionType<double, T>(result25, result25, result25);

  (i + d).expectStaticType<Exactly<double>>();
  (i - d).expectStaticType<Exactly<double>>();
  (i * d).expectStaticType<Exactly<double>>();
  (i % d).expectStaticType<Exactly<double>>();
  i.remainder(d).expectStaticType<Exactly<double>>();

  // Result type T&num
  var result26 = (n + i);
  checkIntersectionType<num, T>(result26, result26, result26);
  var result27 = (n - i);
  checkIntersectionType<num, T>(result27, result27, result27);
  var result28 = (n * i);
  checkIntersectionType<num, T>(result28, result28, result28);
  var result29 = (n % i);
  checkIntersectionType<num, T>(result29, result29, result29);
  var result30 = n.remainder(i);
  checkIntersectionType<num, T>(result30, result30, result30);

  (i + n).expectStaticType<Exactly<num>>();
  (i - n).expectStaticType<Exactly<num>>();
  (i * n).expectStaticType<Exactly<num>>();
  (i % n).expectStaticType<Exactly<num>>();
  i.remainder(n).expectStaticType<Exactly<num>>();

  (i + dyn1).expectStaticType<Exactly<num>>();
  (i - dyn1).expectStaticType<Exactly<num>>();
  (i * dyn1).expectStaticType<Exactly<num>>();
  (i % dyn1).expectStaticType<Exactly<num>>();
  i.remainder(dyn1).expectStaticType<Exactly<num>>();

  double dd = d; // Actual double type.

  (dd + d).expectStaticType<Exactly<double>>();
  (dd - d).expectStaticType<Exactly<double>>();
  (dd * d).expectStaticType<Exactly<double>>();
  (dd % d).expectStaticType<Exactly<double>>();
  dd.remainder(d).expectStaticType<Exactly<double>>();

  // Result type T&double;
  var result41 = d + dd;
  checkIntersectionType<double, T>(result41, result41, result41);
  var result42 = d - dd;
  checkIntersectionType<double, T>(result42, result42, result42);
  var result43 = d * dd;
  checkIntersectionType<double, T>(result43, result43, result43);
  var result44 = d % dd;
  checkIntersectionType<double, T>(result44, result44, result44);
  var result45 = d.remainder(dd);
  checkIntersectionType<double, T>(result45, result45, result45);

  var result46 = d + d;
  checkIntersectionType<double, T>(result46, result46, result46);
  var result47 = d - d;
  checkIntersectionType<double, T>(result47, result47, result47);
  var result48 = d * d;
  checkIntersectionType<double, T>(result48, result48, result48);
  var result49 = d % d;
  checkIntersectionType<double, T>(result49, result49, result49);
  var result50 = d.remainder(d);
  checkIntersectionType<double, T>(result50, result50, result50);

  var result51 = (d + n);
  checkIntersectionType<double, T>(result51, result51, result51);
  var result52 = (d - n);
  checkIntersectionType<double, T>(result52, result52, result52);
  var result53 = (d * n);
  checkIntersectionType<double, T>(result53, result53, result53);
  var result54 = (d % n);
  checkIntersectionType<double, T>(result54, result54, result54);
  var result55 = d.remainder(n);
  checkIntersectionType<double, T>(result55, result55, result55);

  var result56 = (d + dyn1);
  checkIntersectionType<num, T>(result56, result56, result56);
  var result57 = (d - dyn1);
  checkIntersectionType<num, T>(result57, result57, result57);
  var result58 = (d * dyn1);
  checkIntersectionType<num, T>(result58, result58, result58);
  var result59 = (d % dyn1);
  checkIntersectionType<num, T>(result59, result59, result59);
  var result60 = d.remainder(dyn1);
  checkIntersectionType<num, T>(result60, result60, result60);

  (n + d).expectStaticType<Exactly<double>>();
  (n - d).expectStaticType<Exactly<double>>();
  (n * d).expectStaticType<Exactly<double>>();
  (n % d).expectStaticType<Exactly<double>>();
  n.remainder(d).expectStaticType<Exactly<double>>();

  num nn = n; // Actual num-typed value.

  (nn + n).expectStaticType<Exactly<num>>();
  (nn - n).expectStaticType<Exactly<num>>();
  (nn * n).expectStaticType<Exactly<num>>();
  (nn % n).expectStaticType<Exactly<num>>();
  nn.remainder(n).expectStaticType<Exactly<num>>();

  (nn + dyn1).expectStaticType<Exactly<num>>();
  (nn - dyn1).expectStaticType<Exactly<num>>();
  (nn * dyn1).expectStaticType<Exactly<num>>();
  (nn % dyn1).expectStaticType<Exactly<num>>();
  nn.remainder(dyn1).expectStaticType<Exactly<num>>();

  (n + nn).expectStaticType<num>();
  (n - nn).expectStaticType<num>();
  (n * nn).expectStaticType<num>();
  (n % nn).expectStaticType<num>();
  n.remainder(nn).expectStaticType<num>();

  var result71 = n + n;
  checkIntersectionType<num, T>(result71, result71, result71);
  var result72 = n - n;
  checkIntersectionType<num, T>(result72, result72, result72);
  var result73 = n * n;
  checkIntersectionType<num, T>(result73, result73, result73);
  var result74 = n % n;
  checkIntersectionType<num, T>(result74, result74, result74);
  var result75 = n.remainder(n);
  checkIntersectionType<num, T>(result75, result75, result75);

  if (false) {
    (i + never).expectStaticType<Exactly<num>>();
    (i - never).expectStaticType<Exactly<num>>();
    (i * never).expectStaticType<Exactly<num>>();
    (i % never).expectStaticType<Exactly<num>>();
    i.remainder(never).expectStaticType<Exactly<num>>();

    var result81 = d + never;
    checkIntersectionType<double, T>(result81, result81, result81);
    var result82 = d - never;
    checkIntersectionType<double, T>(result82, result82, result82);
    var result83 = d * never;
    checkIntersectionType<double, T>(result83, result83, result83);
    var result84 = d % never;
    checkIntersectionType<double, T>(result84, result84, result84);
    var result85 = d.remainder(never);
    checkIntersectionType<double, T>(result85, result85, result85);

    (n + never).expectStaticType<Exactly<num>>();
    (n - never).expectStaticType<Exactly<num>>();
    (n * never).expectStaticType<Exactly<num>>();
    (n % never).expectStaticType<Exactly<num>>();
    n.remainder(never).expectStaticType<Exactly<num>>();

    (never + d).expectStaticType<Exactly<Never>>();
    (never - d).expectStaticType<Exactly<Never>>();
    (never * d).expectStaticType<Exactly<Never>>();
    (never % d).expectStaticType<Exactly<Never>>();
    never.remainder(d).expectStaticType<Exactly<Never>>();
  }

  var clamp01 = i.clamp(i, i);
  checkIntersectionType<int, T>(clamp01, clamp01, clamp01);
  i.clamp(i, ii).expectStaticType<Exactly<int>>();
  i.clamp(ii, i).expectStaticType<Exactly<int>>();
  ii.clamp(i, i).expectStaticType<Exactly<int>>();

  var clamp05 = d.clamp(d, d);
  checkIntersectionType<double, T>(clamp01, clamp01, clamp01);
  d.clamp(d, dd).expectStaticType<Exactly<double>>();
  d.clamp(dd, d).expectStaticType<Exactly<double>>();
  dd.clamp(d, d).expectStaticType<Exactly<double>>();

  var clamp09 = n.clamp(n, n);
  checkIntersectionType<num, T>(clamp09, clamp09, clamp09);
  n.clamp(n, nn).expectStaticType<Exactly<num>>();
  n.clamp(nn, n).expectStaticType<Exactly<num>>();
  nn.clamp(n, n).expectStaticType<Exactly<num>>();

  i.clamp(i, d).expectStaticType<Exactly<num>>();
  i.clamp(d, i).expectStaticType<Exactly<num>>();
  d.clamp(i, i).expectStaticType<Exactly<num>>();
  i.clamp(d, d).expectStaticType<Exactly<num>>();
  d.clamp(i, d).expectStaticType<Exactly<num>>();
  d.clamp(d, i).expectStaticType<Exactly<num>>();

  i.clamp(i, dyn1).expectStaticType<Exactly<num>>();
  i.clamp(dyn1, i).expectStaticType<Exactly<num>>();
  d.clamp(d, dyn1).expectStaticType<Exactly<num>>();
  d.clamp(dyn1, d).expectStaticType<Exactly<num>>();
  n.clamp(n, dyn1).expectStaticType<Exactly<num>>();
  n.clamp(dyn1, n).expectStaticType<Exactly<num>>();

  // The type T&num is a supertype of T&int/T&double, so it is the result type.
  var clamp19 = i.clamp(i, n);
  checkIntersectionType<num, T>(clamp19, clamp19, clamp19);
  var clamp20 = i.clamp(n, i);
  checkIntersectionType<num, T>(clamp20, clamp20, clamp20);
  var clamp26 = n.clamp(i, i);
  checkIntersectionType<num, T>(clamp26, clamp26, clamp26);
  var clamp27 = d.clamp(d, n);
  checkIntersectionType<num, T>(clamp27, clamp27, clamp27);
  var clamp28 = d.clamp(n, d);
  checkIntersectionType<num, T>(clamp28, clamp28, clamp28);
  var clamp29 = n.clamp(d, d);
  checkIntersectionType<num, T>(clamp29, clamp29, clamp29);
  var clamp30 = i.clamp(d, n);
  checkIntersectionType<num, T>(clamp30, clamp30, clamp30);

  var clamp31 = d.clamp(i, n);
  checkIntersectionType<num, T>(clamp31, clamp31, clamp31);

  var clamp32 = n.clamp(i, d);
  checkIntersectionType<num, T>(clamp32, clamp32, clamp32);

  if (false) {
    var clamp33 = i.clamp(i, never);
    checkIntersectionType<int, T>(clamp33, clamp33, clamp33);
    var clamp34 = d.clamp(d, never);
    checkIntersectionType<double, T>(clamp34, clamp34, clamp34);
    var clamp35 = n.clamp(n, never);
    checkIntersectionType<num, T>(clamp35, clamp35, clamp35);
    never.clamp(i, i).expectStaticType<Exactly<Never>>();
  }
  ;

  i += 1;
  checkIntersectionType<int, T>(i, i, i);
  i += i;
  checkIntersectionType<int, T>(i, i, i);
  d += 1;
  checkIntersectionType<double, T>(d, d, d);
  d += 1.0;
  checkIntersectionType<double, T>(d, d, d);
  d += i;
  checkIntersectionType<double, T>(d, d, d);
  d += d;
  checkIntersectionType<double, T>(d, d, d);
  d += n;
  checkIntersectionType<double, T>(d, d, d);
  n += 1;
  checkIntersectionType<num, T>(n, n, n);
  n += i;
  checkIntersectionType<num, T>(n, n, n);
}

/// Creative combinations of types.
void testComplex<I extends int, D extends double, N extends num,
    O extends Object, NN extends N>(I i, D d, N n, O o, NN nn) {
  O p = 1 as O;
  if (p is! N) throw "promote to O&N";
  if (p is! NN) throw "promote to O&N&NN";

  checkIntersectionType<O, N>(p, p, p);
  checkIntersectionType<N, NN>(p, p, p);

  var result01 = p + p;
  checkIntersectionType<O, N>(result01, result01, result01);
  checkIntersectionType<N, NN>(result01, result01, result01);

  var clamp01 = p.clamp(p, p);
  checkIntersectionType<O, N>(clamp01, clamp01, clamp01);
  checkIntersectionType<N, NN>(clamp01, clamp01, clamp01);

  // Having different unrelated subtypes of int.
  // Return the first operand's type.
  N ni = n;
  if (ni is! int) throw "promote ni to N&int";
  (i + ni).expectStaticType<Exactly<I>>();
  (i - ni).expectStaticType<Exactly<I>>();
  (i * ni).expectStaticType<Exactly<I>>();
  (i % ni).expectStaticType<Exactly<I>>();
  i.remainder(ni).expectStaticType<Exactly<I>>();

  // Use LUB for clamp.
  i.clamp(ni, ni).expectStaticType<Exactly<int>>();
  i.clamp(ni, i).expectStaticType<Exactly<int>>();

  // Having different unrelated subtypes of double.
  N nd = 1.0 as N;
  if (nd is! double) throw "promote ni to N&double";
  (d + nd).expectStaticType<Exactly<D>>();
  (d - nd).expectStaticType<Exactly<D>>();
  (d * nd).expectStaticType<Exactly<D>>();
  (d % nd).expectStaticType<Exactly<D>>();
  d.remainder(nd).expectStaticType<Exactly<D>>();

  (d.clamp(nd, nd)).expectStaticType<Exactly<double>>();
  (d.clamp(nd, d)).expectStaticType<Exactly<double>>();
  (nd.clamp(d, d)).expectStaticType<Exactly<double>>();
}

/// Perform constant operations and check that they are still valid.
class TestConst<I extends int, D extends double, N extends num> {
  static const dynamic dyn = 1;
  final int int1;
  final int int2;
  final double dbl1;
  final double dbl2;
  final double dbl3;
  final double dbl4;
  final double dbl5;
  final double dbl6;
  final num num1;
  final num num2;
  final I i1;
  final I i2;
  final D d1;
  final D d2;
  final D d3;
  final D d4;
  final N n1;
  final N n2;
  const TestConst(I i, D d, N n)
      : int1 = 1 + i,
        int2 = i + 1,
        i1 = i + 1,
        i2 = i + i,
        dbl1 = 1.0 + i,
        dbl2 = 1.0 + d,
        dbl3 = 1.0 + n,
        dbl4 = 1.0 + dyn,
        dbl5 = 1 + 1, // Checking context type of "double = int + _".
        dbl6 = n + 1, // Checking context type of "double = num + _".
        d1 = d + i,
        d2 = d + d,
        d3 = d + n,
        d4 = d + dyn,
        num1 = i + n,
        num2 = n + d,
        n1 = n + n,
        n2 = n + i;
}
