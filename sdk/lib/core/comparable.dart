// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * The signature of a generic comparison function.
 *
 * A comparison function represents an ordering on a type of objects.
 * A total ordering on a type means that for two values, either they
 * are equal or one is greater than the other (and the latter must then be
 * smaller than the former).
 *
 * A [Comparator] function represents such a total ordering by returning
 *
 * * a negative integer if [a] is smaller than [b],
 * * zero if [a] is equal to [b], and
 * * a positive integer if [a] is greater than [b].
 */
typedef int Comparator<T>(T a, T b);

/**
 * Interface used by types that have an intrinsic ordering.
 *
 * The comparison operations is intended to be a total ordering of objects,
 * which can be used for ordering and sorting.
 *
 * When possible a the order of a `Comparable` class should agree with its
 * `operator==` equality. That is, `a.compareTo(b) == 0` iff `a == b`.
 *
 * There are cases where this fail to be the case, in either direction.
 * See [double] where the `compareTo` method is more precise than equality, or
 * [DateTime] where the `compareTo` method is less precise than equality.
 *
 * If equality and `compareTo` agrees,
 * and the ordering represents a less-than/greater-than ordering,
 * consider implementing the comparison operators `<`, `<=`, `>` and `>=`,
 * for the class as well.
 * If equality and `compareTo` disagrees,
 * and the class has a less-than/greater-than ordering,
 * the comparison operators should match equality
 * (`a <= b && a >= b` implies `a == b`).
 *
 * The `double` class has the comparison operators
 * that are compatible with equality.
 * They differ from [double.compareTo] on -0.0 and NaN.
 *
 * The `DateTime` class has no comparison operators, instead it has the more
 * precisely named [DateTime.isBefore] and [DateTime.isAfter].
 */
abstract class Comparable<T> {
  /**
   * Compares this object to another [Comparable]
   *
   * Returns a value like a [Comparator] when comparing [:this:] to [other].
   *
   * May throw an [ArgumentError] if [other] is of a type that
   * is not comparable to [:this:].
   */
  int compareTo(T other);

  /**
   * A [Comparator] that compares one comparable to another.
   *
   * It returns the result of `a.compareTo(b)`.
   *
   * This utility function is used as the default comparator
   * for ordering collections, for example in the [List] sort function.
   */
  static int compare(Comparable a, Comparable b) => a.compareTo(b);
}
