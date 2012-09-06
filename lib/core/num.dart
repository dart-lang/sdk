// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart core library.

abstract class num implements Comparable, Hashable {
  // Arithmetic operations.
  abstract num operator +(num other);
  abstract num operator -(num other);
  abstract num operator *(num other);
  abstract num operator %(num other);
  abstract double operator /(num other);
  // Truncating division.
  abstract num operator ~/(num other);
  // The unary '-' operator.
  abstract num operator negate();
  abstract num remainder(num other);

  // Relational operations.
  abstract bool operator <(num other);
  abstract bool operator <=(num other);
  abstract bool operator >(num other);
  abstract bool operator >=(num other);

  // Predicates.
  abstract bool isNaN();
  abstract bool isNegative();
  abstract bool isInfinite();

  abstract num abs();
  abstract num round();
  abstract num floor();
  abstract num ceil();
  abstract num truncate();

  abstract int toInt();
  abstract double toDouble();

  abstract String toStringAsFixed(int fractionDigits);
  abstract String toStringAsExponential(int fractionDigits);
  abstract String toStringAsPrecision(int precision);
  abstract String toRadixString(int radix);
}
