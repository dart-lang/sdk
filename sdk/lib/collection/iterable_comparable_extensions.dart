// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.6

part of dart.collection;

extension IterableComparableExtensions<T extends Comparable> on Iterable<T> {
  /*
  * Returns the largest value in the iterable determined via
  * [Comparable.toCompare()].
  *
  * The iterable must have at least one element, otherwise
  * [IterableElementError] gets thrown.
  * If it has only one element, that element is returned.
  *
  * If multiple items are maximal, the function returns the first one encountered.
  */
  Comparable get max {
    return this.reduce((Comparable value, Comparable element) =>
        value.compareTo(element) >= 0 ? value : element);
  }

  /*
  * Returns the largest value in the iterable determined via
  * [Comparable.toCompare()].
  *
  * The iterable must have at least one element, otherwise
  * [IterableElementError] gets thrown.
  * If it has only one element, that element is returned.
  *
  * If multiple items are maximal, the function returns the first one encountered.
  */
  Comparable get min {
    return this.reduce((Comparable value, Comparable element) =>
        value.compareTo(element) <= 0 ? value : element);
  }
}