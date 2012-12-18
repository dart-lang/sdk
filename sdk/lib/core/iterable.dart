// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * The [Iterable] interface allows to get an [Iterator] out of an
 * [Iterable] object.
 *
 * This interface is used by the for-in construct to iterate over an
 * [Iterable] object.
 * The for-in construct takes an [Iterable] object at the right-hand
 * side, and calls its [iterator] method to get an [Iterator] on it.
 *
 * A user-defined class that implements the [Iterable] interface can
 * be used as the right-hand side of a for-in construct.
 */
abstract class Iterable<E> {
  /**
   * Returns an [Iterator] that iterates over this [Iterable] object.
   */
  Iterator<E> iterator();
}
