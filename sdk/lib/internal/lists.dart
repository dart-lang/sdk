// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._internal;

class Lists {
  static void copy(List src, int srcStart,
                   List dst, int dstStart, int count) {
    if (srcStart < dstStart) {
      for (int i = srcStart + count - 1, j = dstStart + count - 1;
           i >= srcStart; i--, j--) {
        dst[j] = src[i];
      }
    } else {
      for (int i = srcStart, j = dstStart; i < srcStart + count; i++, j++) {
        dst[j] = src[i];
      }
    }
  }

  static bool areEqual(List a, var b) {
    if (identical(a, b)) return true;
    if (!(b is List)) return false;
    int length = a.length;
    if (length != b.length) return false;

    for (int i = 0; i < length; i++) {
      if (!identical(a[i], b[i])) return false;
    }
    return true;
  }

  /**
   * Returns the index in the list [a] of the given [element], starting
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
   * Returns the last index in the list [a] of the given [element], starting
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

  static void indicesCheck(List a, int start, int end) {
    if (start < 0 || start > a.length) {
      throw new RangeError.range(start, 0, a.length);
    }
    if (end != null && (end < start || end > a.length)) {
      throw new RangeError.range(end, start, a.length);
    }
  }

  static void rangeCheck(List a, int start, int length) {
    if (length < 0) {
      throw new ArgumentError("negative length $length");
    }
    if (start < 0 ) {
      String message = "$start must be greater than or equal to 0";
      throw new RangeError(message);
    }
    if (start + length > a.length) {
      String message = "$start + $length must be in the range [0..${a.length})";
      throw new RangeError(message);
    }
  }
}
