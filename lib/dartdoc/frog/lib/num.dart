// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart core library.

interface num extends Comparable, Hashable {
  // Arithmetic operations.
  num operator +(num other);
  num operator -(num other);
  num operator *(num other);
  num operator %(num other);
  num operator /(num other);
  // Truncating division.
  num operator ~/(num other);
  // The unary '-' operator.
  num operator negate();
  num remainder(num other);

  // Relational operations.
  bool operator <(num other);
  bool operator <=(num other);
  bool operator >(num other);
  bool operator >=(num other);

  // TODO(jimhug): Cheap trick...
  bool operator ==(var other);


  // Predicates.
  bool isEven();
  bool isOdd();
  bool isNaN();
  bool isNegative();
  bool isInfinite();

  num abs();
  num round();
  num floor();
  num ceil();
  num truncate();

  int toInt();
  double toDouble();

  String toStringAsFixed(int fractionDigits);
  String toStringAsExponential(int fractionDigits);
  String toStringAsPrecision(int precision);
  String toRadixString(int radix);

  // TODO(jmesserly): we need to do something in the Frog type system to know
  // to know that most int operations are closed over integers.

  // TODO(jimhug): Bit-operations stolen from int
  int operator &(int other);
  int operator |(int other);
  int operator ^(int other);
  int operator ~();
  int operator <<(int shiftAmount);
  int operator >>(int shiftAmount);
}
