// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the rules for static types of number operators,
// as modified by Null Safety
import "../static_type_helper.dart";

// ignore_for_file: receiver_of_type_never

// The typing rules for `e` of the form:
// * `e1 op e2` (op in `+`, `-`, `*` or `%`), or
// * `e1.remainder(e2)`,
//
// where *T* is the static type of `e1`, *S* is the static type of `e2`
// and *T* is a non-`Never` subtype of `num` and *S* is assignable to `num`.
//
// * If *T* <: `double` then the static type of `e` is `double`.
// * Otherwise, if *S* <: `double` and not *S* <: `Never`,
//   then the static type of `e` is `double`.
// * Otherwise, if *T* <: `int`, *S* <: `int` and not *S* <: `Never`,
//   then the static type of `e` is `int`.
// * Otherwise the static type of *e* is `num`.
//
// For `e1.clamp(e2, e3)` where
// *T1* is the static type of `e1`, *T1* a non-`Never` subtype of `num`,
// *T2* is the static type of `e2`, and
// *T3* is the static type of `e3`:
//
// * If all of *T1*, *T2* and *T3* are non-`Never` subtypes of `int`,
//   then the static type of `e` is `int`.
// * If all of *T1*, *T2* and *T3* are non-`Never` subtypes of `double`,
//   then the static type of `e` is `double`.
// * Otherwise the static type of `e` is num`.

main() {
  testPlainVariables(1, 1.0, 1);
  testPromotedVariables(1, 1.0, 1);
  testTypeVariables<int, double, int>(1, 1.0, 1);
  testPromotedTypeVariables<Object>(1, 1.0, 1);
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

  (i + d).expectStaticType<Exactly<double>>();
  (i - d).expectStaticType<Exactly<double>>();
  (i * d).expectStaticType<Exactly<double>>();
  (i % d).expectStaticType<Exactly<double>>();
  i.remainder(d).expectStaticType<Exactly<double>>();

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

  if (false) {
    // Only for the static checks
    // since we have sub-expressions of type Never.
    (i + never).expectStaticType<Exactly<num>>();
    (i - never).expectStaticType<Exactly<num>>();
    (i * never).expectStaticType<Exactly<num>>();
    (i % never).expectStaticType<Exactly<num>>();
    i.remainder(never).expectStaticType<Exactly<num>>();
  }

  (d + i).expectStaticType<Exactly<double>>();
  (d - i).expectStaticType<Exactly<double>>();
  (d * i).expectStaticType<Exactly<double>>();
  (d % i).expectStaticType<Exactly<double>>();
  d.remainder(i).expectStaticType<Exactly<double>>();

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

  if (false) {
    (d + never).expectStaticType<Exactly<double>>();
    (d - never).expectStaticType<Exactly<double>>();
    (d * never).expectStaticType<Exactly<double>>();
    (d % never).expectStaticType<Exactly<double>>();
    d.remainder(never).expectStaticType<Exactly<double>>();
  }

  (n + i).expectStaticType<Exactly<num>>();
  (n - i).expectStaticType<Exactly<num>>();
  (n * i).expectStaticType<Exactly<num>>();
  (n % i).expectStaticType<Exactly<num>>();
  n.remainder(i).expectStaticType<Exactly<num>>();

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
    (n + never).expectStaticType<Exactly<num>>();
    (n - never).expectStaticType<Exactly<num>>();
    (n * never).expectStaticType<Exactly<num>>();
    (n % never).expectStaticType<Exactly<num>>();
    n.remainder(never).expectStaticType<Exactly<num>>();
  }

  var dyn1a = dyn1 + d;
  if (false) {
    // Check that the static type of [dyn1a] is dynamic:
    Never n = dyn1a;
    dyn1a = 0;
    dyn1a = false;
  }
  var dyn1b = dyn1 - d;
  if (false) {
    // Check that the static type of [dyn1b] is dynamic:
    Never n = dyn1b;
    dyn1b = 0;
    dyn1b = false;
  }
  var dyn1c = dyn1 * d;
  if (false) {
    // Check that the static type of [dyn1c] is dynamic:
    Never n = dyn1c;
    dyn1c = 0;
    dyn1c = false;
  }
  var dyn1d = dyn1 % d;
  if (false) {
    // Check that the static type of [dyn1d] is dynamic:
    Never n = dyn1d;
    dyn1d = 0;
    dyn1d = false;
  }
  var dyn1e = dyn1.remainder(d);
  if (false) {
    // Check that the static type of [dyn1e] is dynamic:
    Never n = dyn1a;
    dyn1a = 0;
    dyn1a = false;
  }

  if (false) {
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
    i.clamp(i, never).expectStaticType<Exactly<num>>();
    d.clamp(d, never).expectStaticType<Exactly<num>>();
    n.clamp(n, never).expectStaticType<Exactly<num>>();
    never.clamp(i, i).expectStaticType<Exactly<Never>>();
  }

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

  (i + d).expectStaticType<Exactly<double>>();
  (i - d).expectStaticType<Exactly<double>>();
  (i * d).expectStaticType<Exactly<double>>();
  (i % d).expectStaticType<Exactly<double>>();
  i.remainder(d).expectStaticType<Exactly<double>>();

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

  if (false) {
    (i + never).expectStaticType<Exactly<num>>();
    (i - never).expectStaticType<Exactly<num>>();
    (i * never).expectStaticType<Exactly<num>>();
    (i % never).expectStaticType<Exactly<num>>();
    i.remainder(never).expectStaticType<Exactly<num>>();
  }

  (d + i).expectStaticType<Exactly<double>>();
  (d - i).expectStaticType<Exactly<double>>();
  (d * i).expectStaticType<Exactly<double>>();
  (d % i).expectStaticType<Exactly<double>>();
  d.remainder(i).expectStaticType<Exactly<double>>();

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

  if (false) {
    (d + never).expectStaticType<Exactly<double>>();
    (d - never).expectStaticType<Exactly<double>>();
    (d * never).expectStaticType<Exactly<double>>();
    (d % never).expectStaticType<Exactly<double>>();
    d.remainder(never).expectStaticType<Exactly<double>>();
  }

  (n + i).expectStaticType<Exactly<num>>();
  (n - i).expectStaticType<Exactly<num>>();
  (n * i).expectStaticType<Exactly<num>>();
  (n % i).expectStaticType<Exactly<num>>();
  n.remainder(i).expectStaticType<Exactly<num>>();

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
    (n + never).expectStaticType<Exactly<num>>();
    (n - never).expectStaticType<Exactly<num>>();
    (n * never).expectStaticType<Exactly<num>>();
    (n % never).expectStaticType<Exactly<num>>();
    n.remainder(never).expectStaticType<Exactly<num>>();
  }

  var dyn1a = dyn1 + d;
  if (false) {
    // Check that the static type of [dyn1a] is dynamic:
    Never n = dyn1a;
    dyn1a = 0;
    dyn1a = false;
  }
  var dyn1b = dyn1 - d;
  if (false) {
    // Check that the static type of [dyn1b] is dynamic:
    Never n = dyn1b;
    dyn1b = 0;
    dyn1b = false;
  }
  var dyn1c = dyn1 * d;
  if (false) {
    // Check that the static type of [dyn1c] is dynamic:
    Never n = dyn1c;
    dyn1c = 0;
    dyn1c = false;
  }
  var dyn1d = dyn1 % d;
  if (false) {
    // Check that the static type of [dyn1d] is dynamic:
    Never n = dyn1d;
    dyn1d = 0;
    dyn1d = false;
  }
  var dyn1e = dyn1.remainder(d);
  if (false) {
    // Check that the static type of [dyn1e] is dynamic:
    Never n = dyn1a;
    dyn1a = 0;
    dyn1a = false;
  }

  if (false) {
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
    i.clamp(i, never).expectStaticType<Exactly<num>>();
    d.clamp(d, never).expectStaticType<Exactly<num>>();
    n.clamp(n, never).expectStaticType<Exactly<num>>();
    never.clamp(i, i).expectStaticType<Exactly<Never>>();
  }

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

  (i + ii).expectStaticType<Exactly<int>>();
  (i - ii).expectStaticType<Exactly<int>>();
  (i * ii).expectStaticType<Exactly<int>>();
  (i % ii).expectStaticType<Exactly<int>>();
  i.remainder(ii).expectStaticType<Exactly<int>>();

  (i + i).expectStaticType<Exactly<int>>();
  (i - i).expectStaticType<Exactly<int>>();
  (i * i).expectStaticType<Exactly<int>>();
  (i % i).expectStaticType<Exactly<int>>();
  i.remainder(i).expectStaticType<Exactly<int>>();

  (i + d).expectStaticType<Exactly<double>>();
  (i - d).expectStaticType<Exactly<double>>();
  (i * d).expectStaticType<Exactly<double>>();
  (i % d).expectStaticType<Exactly<double>>();
  i.remainder(d).expectStaticType<Exactly<double>>();

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

  if (false) {
    (i + never).expectStaticType<Exactly<num>>();
    (i - never).expectStaticType<Exactly<num>>();
    (i * never).expectStaticType<Exactly<num>>();
    (i % never).expectStaticType<Exactly<num>>();
    i.remainder(never).expectStaticType<Exactly<num>>();
  }

  (d + i).expectStaticType<Exactly<double>>();
  (d - i).expectStaticType<Exactly<double>>();
  (d * i).expectStaticType<Exactly<double>>();
  (d % i).expectStaticType<Exactly<double>>();
  d.remainder(i).expectStaticType<Exactly<double>>();

  double dd = d; // Actual double type.

  (dd + d).expectStaticType<Exactly<double>>();
  (dd - d).expectStaticType<Exactly<double>>();
  (dd * d).expectStaticType<Exactly<double>>();
  (dd % d).expectStaticType<Exactly<double>>();
  dd.remainder(d).expectStaticType<Exactly<double>>();

  (d + dd).expectStaticType<Exactly<double>>();
  (d - dd).expectStaticType<Exactly<double>>();
  (d * dd).expectStaticType<Exactly<double>>();
  (d % dd).expectStaticType<Exactly<double>>();
  d.remainder(dd).expectStaticType<Exactly<double>>();

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

  if (false) {
    (d + never).expectStaticType<Exactly<double>>();
    (d - never).expectStaticType<Exactly<double>>();
    (d * never).expectStaticType<Exactly<double>>();
    (d % never).expectStaticType<Exactly<double>>();
    d.remainder(never).expectStaticType<Exactly<double>>();
  }

  (n + i).expectStaticType<Exactly<num>>();
  (n - i).expectStaticType<Exactly<num>>();
  (n * i).expectStaticType<Exactly<num>>();
  (n % i).expectStaticType<Exactly<num>>();
  n.remainder(i).expectStaticType<Exactly<num>>();

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
    (n + never).expectStaticType<Exactly<num>>();
    (n - never).expectStaticType<Exactly<num>>();
    (n * never).expectStaticType<Exactly<num>>();
    (n % never).expectStaticType<Exactly<num>>();
    n.remainder(never).expectStaticType<Exactly<num>>();
  }

  var dyn1a = dyn1 + d;
  if (false) {
    // Check that the static type of [dyn1a] is dynamic:
    Never n = dyn1a;
    dyn1a = 0;
    dyn1a = false;
  }
  var dyn1b = dyn1 - d;
  if (false) {
    // Check that the static type of [dyn1b] is dynamic:
    Never n = dyn1b;
    dyn1b = 0;
    dyn1b = false;
  }
  var dyn1c = dyn1 * d;
  if (false) {
    // Check that the static type of [dyn1c] is dynamic:
    Never n = dyn1c;
    dyn1c = 0;
    dyn1c = false;
  }
  var dyn1d = dyn1 % d;
  if (false) {
    // Check that the static type of [dyn1d] is dynamic:
    Never n = dyn1d;
    dyn1d = 0;
    dyn1d = false;
  }
  var dyn1e = dyn1.remainder(d);
  if (false) {
    // Check that the static type of [dyn1e] is dynamic:
    Never n = dyn1a;
    dyn1a = 0;
    dyn1a = false;
  }

  if (false) {
    (never + d).expectStaticType<Exactly<Never>>();
    (never - d).expectStaticType<Exactly<Never>>();
    (never * d).expectStaticType<Exactly<Never>>();
    (never % d).expectStaticType<Exactly<Never>>();
    never.remainder(d).expectStaticType<Exactly<Never>>();
  }

  i.clamp(i, i).expectStaticType<Exactly<int>>();
  i.clamp(i, ii).expectStaticType<Exactly<int>>();
  i.clamp(ii, i).expectStaticType<Exactly<int>>();
  ii.clamp(i, i).expectStaticType<Exactly<int>>();

  d.clamp(d, d).expectStaticType<Exactly<double>>();
  d.clamp(d, dd).expectStaticType<Exactly<double>>();
  d.clamp(dd, d).expectStaticType<Exactly<double>>();
  dd.clamp(d, d).expectStaticType<Exactly<double>>();

  n.clamp(n, n).expectStaticType<Exactly<num>>();
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
    i.clamp(i, never).expectStaticType<Exactly<num>>();
    d.clamp(d, never).expectStaticType<Exactly<num>>();
    n.clamp(n, never).expectStaticType<Exactly<num>>();
    never.clamp(i, i).expectStaticType<Exactly<Never>>();
  }

  Object on = 1;
  if (on is! N) throw "promote on to O&N";
  var onn = on;
  if (onn is! num) throw "promote onn O&N&num";

  // With three different type variable types,
  // still pick num.
  n.clamp(on, onn).expectStaticType<Exactly<num>>();
  on.clamp(n, onn).expectStaticType<Exactly<num>>();
  onn.clamp(on, n).expectStaticType<Exactly<num>>();
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

  (i + i).expectStaticType<Exactly<int>>();
  (i - i).expectStaticType<Exactly<int>>();
  (i * i).expectStaticType<Exactly<int>>();
  (i % i).expectStaticType<Exactly<int>>();
  i.remainder(i).expectStaticType<Exactly<int>>();

  (i + ii).expectStaticType<Exactly<int>>();
  (i - ii).expectStaticType<Exactly<int>>();
  (i * ii).expectStaticType<Exactly<int>>();
  (i % ii).expectStaticType<Exactly<int>>();
  i.remainder(ii).expectStaticType<Exactly<int>>();

  (i + d).expectStaticType<Exactly<double>>();
  (i - d).expectStaticType<Exactly<double>>();
  (i * d).expectStaticType<Exactly<double>>();
  (i % d).expectStaticType<Exactly<double>>();
  i.remainder(d).expectStaticType<Exactly<double>>();

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

  if (false) {
    (i + never).expectStaticType<Exactly<num>>();
    (i - never).expectStaticType<Exactly<num>>();
    (i * never).expectStaticType<Exactly<num>>();
    (i % never).expectStaticType<Exactly<num>>();
    i.remainder(never).expectStaticType<Exactly<num>>();
  }

  (d + i).expectStaticType<Exactly<double>>();
  (d - i).expectStaticType<Exactly<double>>();
  (d * i).expectStaticType<Exactly<double>>();
  (d % i).expectStaticType<Exactly<double>>();
  d.remainder(i).expectStaticType<Exactly<double>>();

  double dd = d; // Actual double type.

  (dd + d).expectStaticType<Exactly<double>>();
  (dd - d).expectStaticType<Exactly<double>>();
  (dd * d).expectStaticType<Exactly<double>>();
  (dd % d).expectStaticType<Exactly<double>>();
  dd.remainder(d).expectStaticType<Exactly<double>>();

  // Result type T&double;
  (d + dd).expectStaticType<Exactly<double>>();
  (d - dd).expectStaticType<Exactly<double>>();
  (d * dd).expectStaticType<Exactly<double>>();
  (d % dd).expectStaticType<Exactly<double>>();
  d.remainder(dd).expectStaticType<Exactly<double>>();

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

  if (false) {
    d + never.expectStaticType<Exactly<double>>();
    d - never.expectStaticType<Exactly<double>>();
    d * never.expectStaticType<Exactly<double>>();
    d % never.expectStaticType<Exactly<double>>();
    d.remainder(never).expectStaticType<Exactly<double>>();
  }

  (n + i).expectStaticType<Exactly<num>>();
  (n - i).expectStaticType<Exactly<num>>();
  (n * i).expectStaticType<Exactly<num>>();
  (n % i).expectStaticType<Exactly<num>>();
  n.remainder(i).expectStaticType<Exactly<num>>();

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

  (n + nn).expectStaticType<Exactly<num>>();
  (n - nn).expectStaticType<Exactly<num>>();
  (n * nn).expectStaticType<Exactly<num>>();
  (n % nn).expectStaticType<Exactly<num>>();
  n.remainder(nn).expectStaticType<Exactly<num>>();

  (n + n).expectStaticType<Exactly<num>>();
  (n - n).expectStaticType<Exactly<num>>();
  (n * n).expectStaticType<Exactly<num>>();
  (n % n).expectStaticType<Exactly<num>>();
  n.remainder(n).expectStaticType<Exactly<num>>();

  if (false) {
    (n + never).expectStaticType<Exactly<num>>();
    (n - never).expectStaticType<Exactly<num>>();
    (n * never).expectStaticType<Exactly<num>>();
    (n % never).expectStaticType<Exactly<num>>();
    n.remainder(never).expectStaticType<Exactly<num>>();
  }

  var dyn1a = dyn1 + d;
  if (false) {
    // Check that the static type of [dyn1a] is dynamic:
    Never n = dyn1a;
    dyn1a = 0;
    dyn1a = false;
  }
  var dyn1b = dyn1 - d;
  if (false) {
    // Check that the static type of [dyn1b] is dynamic:
    Never n = dyn1b;
    dyn1b = 0;
    dyn1b = false;
  }
  var dyn1c = dyn1 * d;
  if (false) {
    // Check that the static type of [dyn1c] is dynamic:
    Never n = dyn1c;
    dyn1c = 0;
    dyn1c = false;
  }
  var dyn1d = dyn1 % d;
  if (false) {
    // Check that the static type of [dyn1d] is dynamic:
    Never n = dyn1d;
    dyn1d = 0;
    dyn1d = false;
  }
  var dyn1e = dyn1.remainder(d);
  if (false) {
    // Check that the static type of [dyn1e] is dynamic:
    Never n = dyn1a;
    dyn1a = 0;
    dyn1a = false;
  }

  if (false) {
    (never + d).expectStaticType<Exactly<Never>>();
    (never - d).expectStaticType<Exactly<Never>>();
    (never * d).expectStaticType<Exactly<Never>>();
    (never % d).expectStaticType<Exactly<Never>>();
    never.remainder(d).expectStaticType<Exactly<Never>>();
  }

  i.clamp(i, i).expectStaticType<Exactly<int>>();
  i.clamp(i, ii).expectStaticType<Exactly<int>>();
  i.clamp(ii, i).expectStaticType<Exactly<int>>();
  ii.clamp(i, i).expectStaticType<Exactly<int>>();

  d.clamp(d, d).expectStaticType<Exactly<double>>();
  d.clamp(d, dd).expectStaticType<Exactly<double>>();
  d.clamp(dd, d).expectStaticType<Exactly<double>>();
  dd.clamp(d, d).expectStaticType<Exactly<double>>();

  n.clamp(n, n).expectStaticType<Exactly<num>>();
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
  i.clamp(i, n).expectStaticType<Exactly<num>>();
  i.clamp(n, i).expectStaticType<Exactly<num>>();
  n.clamp(i, i).expectStaticType<Exactly<num>>();
  d.clamp(d, n).expectStaticType<Exactly<num>>();
  d.clamp(n, d).expectStaticType<Exactly<num>>();
  n.clamp(d, d).expectStaticType<Exactly<num>>();
  i.clamp(d, n).expectStaticType<Exactly<num>>();
  d.clamp(i, n).expectStaticType<Exactly<num>>();
  n.clamp(i, d).expectStaticType<Exactly<num>>();

  if (false) {
    i.clamp(i, never).expectStaticType<Exactly<num>>();
    d.clamp(d, never).expectStaticType<Exactly<num>>();
    n.clamp(n, never).expectStaticType<Exactly<num>>();
    never.clamp(i, i).expectStaticType<Exactly<Never>>();
  }
}

/// Perform constant operations and check that they are still valid.
class TestConst<I extends int, D extends double, N extends num> {
  static const dynamic dyn = 1;
  final int int1;
  final int int2;
  final int int3;
  final int int4;
  final double dbl1;
  final double dbl2;
  final double dbl3;
  final double dbl4;
  final double dbl5;
  final double dbl6;
  final double dbl7;
  final double dbl8;
  final double dbl9;
  final double dbl10;
  final num num1;
  final num num2;
  final num num3;
  final num num4;
  final num num5;
  const TestConst(I i, D d, N n)
      : int1 = 1 + i,
        int2 = i + 1,
        int3 = i + 1,
        int4 = i + i,
        dbl1 = 1.0 + i,
        dbl2 = 1.0 + d,
        dbl3 = 1.0 + n,
        dbl4 = 1.0 + dyn,
        dbl5 = 1 + 1, // Checking context type of "double = int + _".
        dbl6 = n + 1, // Checking context type of "double = num + _".
        dbl7 = d + i,
        dbl8 = d + d,
        dbl9 = d + n,
        dbl10 = d + dyn,
        num1 = i + n,
        num2 = n + d,
        num3 = n + n,
        num4 = n + i,
        num5 = n + dyn;
}
