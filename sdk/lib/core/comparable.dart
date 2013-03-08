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
   * Compare one comparable to another.
   *
   * This utility function is used as the default comparator
   * for the [List] sort function.
   */
  static int compare(Comparable a, Comparable b) => a.compareTo(b);
}
