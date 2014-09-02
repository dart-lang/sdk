// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart.pkg.math;

/**
 * Computes the greatest common divisor between [a] and [b].
 *
 * The result is always positive even if either `a` or `b` is negative.
 */
int gcd(int a, int b) {
  if (a == null) throw new ArgumentError(a);
  if (b == null) throw new ArgumentError(b);
  a = a.abs();
  b = b.abs();

  // Iterative Binary GCD algorithm.
  if (a == 0) return b;
  if (b == 0) return a;
  int powerOfTwo = 1;
  while (((a | b) & 1) == 0) {
    powerOfTwo *= 2;
    a ~/= 2;
    b ~/= 2;
  }

  while (a.isEven) a ~/= 2;

  do {
    while (b.isEven) b ~/= 2;
    if (a > b) {
      int temp = b;
      b = a;
      a = temp;
    }
    b -= a;
  } while (b != 0);

  return a * powerOfTwo;
}

/**
 * Computes the greatest common divisor between [a] and [b], as well as [x] and
 * [y] such that `ax+by == gcd(a,b)`.
 *
 * The return value is a List of three ints: the greatest common divisor, `x`,
 * and `y`, in that order.
 */
List<int> gcdext(int a, int b) {
  if (a == null) throw new ArgumentError(a);
  if (b == null) throw new ArgumentError(b);

  if (a < 0) {
    List<int> result = gcdext(-a, b);
    result[1] = -result[1];
    return result;
  }
  if (b < 0) {
    List<int> result = gcdext(a, -b);
    result[2] = -result[2];
    return result;
  }

  int r0 = a;
  int r1 = b;
  int x0, x1, y0, y1;
  x0 = y1 = 1;
  x1 = y0 = 0;

  while (r1 != 0) {
    int q = r0 ~/ r1;
    int tmp = r0;
    r0 = r1;
    r1 = tmp - q*r1;

    tmp = x0;
    x0 = x1;
    x1 = tmp - q*x1;

    tmp = y0;
    y0 = y1;
    y1 = tmp - q*y1;
  }

  return new List<int>(3)
      ..[0] = r0
      ..[1] = x0
      ..[2] = y0;
}

/**
 * Computes the inverse of [a] modulo [m].
 *
 * Throws an [IntegerDivisionByZeroException] if `a` has no inverse modulo `m`:
 *
 *     invert(4, 7); // 2
 *     invert(4, 10); // throws IntegerDivisionByZeroException
 */
int invert(int a, int m) {
  List<int> results = gcdext(a, m);
  int g = results[0];
  int x = results[1];
  if (g != 1) {
    throw new IntegerDivisionByZeroException();
  }
  return x % m;
}

/**
 * Computes the least common multiple between [a] and [b].
 */
int lcm(int a, int b) {
  if (a == null) throw new ArgumentError(a);
  if (b == null) throw new ArgumentError(b);
  if (a == 0 && b == 0) return 0;

  return a.abs() ~/ gcd(a, b) * b.abs();
}

/**
 * Computes [base] raised to [exp] modulo [mod].
 *
 * The result is always positive, in keeping with the behavior of modulus
 * operator (`%`).
 *
 * Throws an [IntegerDivisionByZeroException] if `exp` is negative and `base`
 * has no inverse modulo `mod`.
 */
int powmod(int base, int exp, int mod) {
  if (base == null) throw new ArgumentError(base);
  if (exp == null) throw new ArgumentError(exp);
  if (mod == null) throw new ArgumentError(mod);

  // Right-to-left binary method of modular exponentiation.
  if (exp < 0) {
    base = invert(base, mod);
    exp = -exp;
  }
  if (exp == 0) { return 1; }

  int result = 1;
  base = base % mod;
  while (true) {
    if (exp.isOdd) {
      result = (result * base) % mod;
    }
    exp ~/= 2;
    if (exp == 0) {
      return result;
    }
    base = (base * base) % mod;
  }
}
