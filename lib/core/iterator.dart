// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * The [Iterator] class provides methods to iterate over an object. It
 * is transparently used by the for-in construct to test for the end
 * of the iteration, and to get the elements.
 */
interface Iterator<E> {
  /**
   * Gets the next element in the iteration. Throws a
   * [NoMoreElementsException] if no element is left.
   */
  E next();

  /**
   * Returns whether the [Iterator] has elements left.
   */
  bool hasNext();
}
