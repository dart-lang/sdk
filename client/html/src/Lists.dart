// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jacobr): move into a core library or at least merge with the copy
// in client/dom/src
class Lists {

  /**
   * Returns the index in the array [a] of the given [element], starting
   * the search at index [startIndex] to [endIndex] (exclusive).
   * Returns -1 if [element] is not found.
   */
  static int indexOf(List a,
                     Object element,
                     int startIndex,
                     int endIndex) {
    if (startIndex >= a.length) {
      return -1;
    }
    if (startIndex < 0) {
      startIndex = 0;
    }
    for (int i = startIndex; i < endIndex; i++) {
      if (a[i] == element) {
        return i;
      }
    }
    return -1;
  }

  /**
   * Returns the last index in the array [a] of the given [element], starting
   * the search at index [startIndex] to 0.
   * Returns -1 if [element] is not found.
   */
  static int lastIndexOf(List a, Object element, int startIndex) {
    if (startIndex < 0) {
      return -1;
    }
    if (startIndex >= a.length) {
      startIndex = a.length - 1;
    }
    for (int i = startIndex; i >= 0; i--) {
      if (a[i] == element) {
        return i;
      }
    }
    return -1;
  }

  static void setRange(List to, int start, int length, List from,
      int startFrom) {
    // TODO(nweiz): remove these IndexOutOfRange checks once Frog has bounds
    // checking for List indexing
    if (start < 0) {
      throw new IndexOutOfRangeException(start);
    } else if (startFrom < 0) {
      throw new IndexOutOfRangeException(startFrom);
    } else if (length < 0) {
      throw new IllegalArgumentException("negative length $length");
    } else if (start + length > to.length) {
      throw new IndexOutOfRangeException(Math.min(to.length, start));
    } else if (startFrom + length > from.length) {
      throw new IndexOutOfRangeException(Math.min(from.length, startFrom));
    }

    for (var i = 0; i < length; i++) {
      to[start + i] = from[startFrom + i];
    }
  }

  static void removeRange(List a, int start, int length,
      void removeOne(int index)) {
    // TODO(nweiz): remove these IndexOutOfRange checks once Frog has bounds
    // checking for List indexing
    if (start < 0) {
      throw new IndexOutOfRangeException(start);
    } else if (length < 0) {
      throw new IllegalArgumentException("negative length $length");
    } else if (start + length > a.length) {
      throw new IndexOutOfRangeException(Math.min(a.length, start));
    }

    for (var i = 0; i < length; i++) {
      removeOne(start);
    }
  }

  static List getRange(List a, int start, int length) {
    // TODO(nweiz): remove these IndexOutOfRange checks once Frog has bounds
    // checking for List indexing
    if (start < 0) {
      throw new IndexOutOfRangeException(start);
    } else if (length < 0) {
      throw new IllegalArgumentException("negative length $length");
    } else if (start + length > a.length) {
      throw new IndexOutOfRangeException(Math.min(a.length, start));
    }

    var result = [];
    for (var i = 0; i < length; i++) {
      result.add(a[start + i]);
    }
    return result;
  }
}
