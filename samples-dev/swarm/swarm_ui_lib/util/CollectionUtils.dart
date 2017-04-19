// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of utilslib;

typedef num NumericValueSelector<T>(T value);

/**
 * General purpose collection utilities.
 * TODO(jmesserly): make these top level functions?
 */
class CollectionUtils {
  static void insertAt(List arr, int pos, value) {
    assert(pos >= 0);
    assert(pos <= arr.length);

    if (pos == arr.length) {
      arr.add(value);
    } else {
      // TODO(sigmund): replace this push with a call that ensures capacity
      // (currently not supported in the JS implementation of list). E.g.
      // [: arr.length = arr.length + 1; :]
      arr.add(null);

      // shift elements from [pos] (note: arr already has null @ length - 1)
      for (int i = arr.length - 2; i >= pos; i--) {
        arr[i + 1] = arr[i];
      }
      arr[pos] = value;

      // TODO(jmesserly): we won't need to do this once List
      // implements insertAt
      if (arr is ObservableList) {
        // TODO(jmesserly): shouldn't need to cast after testing instanceof
        ObservableList obs = arr;
        obs.recordListInsert(pos, value);
      }
    }
  }

  /**
   * Finds the item in [source] that matches [test].  Returns null if
   * no item matches.  The typing should be:
   * T find(Iterable<T> source, bool test(T item)), but we don't have generic
   * functions.
   */
  static find(Iterable source, bool test(item)) {
    for (final item in source) {
      if (test(item)) return item;
    }

    return null;
  }

  /** Compute the minimum of an iterable. Returns null if empty. */
  static num min(Iterable source) {
    final iter = source.iterator;
    if (!iter.moveNext()) {
      return null;
    }
    num best = iter.current;
    while (iter.moveNext()) {
      best = Math.min(best, iter.current);
    }
    return best;
  }

  /** Compute the maximum of an iterable. Returns null if empty. */
  static num max(Iterable source) {
    final iter = source.iterator;
    if (!iter.moveNext()) {
      return null;
    }
    num best = iter.current;
    while (iter.moveNext()) {
      best = Math.max(best, iter.current);
    }
    return best;
  }

  /** Orders an iterable by its values, or by a key selector. */
  static List orderBy(Iterable source, [NumericValueSelector selector = null]) {
    final result = new List.from(source);
    sortBy(result, selector);
    return result;
  }

  /** Sorts a list by its values, or by a key selector. */
  // TODO(jmesserly): we probably don't want to call the key selector more than
  // once for a given element. This would improve performance and the API
  // contract could be stronger.
  static void sortBy(List list, [NumericValueSelector selector = null]) {
    if (selector != null) {
      list.sort((x, y) => selector(x) - selector(y));
    } else {
      list.sort((x, y) => x - y);
    }
  }

  /** Compute the sum of an iterable. An empty iterable is an error. */
  static num sum(Iterable source, [NumericValueSelector selector = null]) {
    final iter = source.iterator;
    bool wasEmpty = true;
    num total = 0;
    if (selector != null) {
      for (var element in source) {
        wasEmpty = false;
        total += selector(element);
      }
    } else {
      for (num element in source) {
        wasEmpty = false;
        total += element;
      }
    }
    if (wasEmpty) throw new StateError("No elements");
    return total;
  }

  // TODO(jmesserly): something like should exist on Map, either a method or a
  // constructor, see bug #5340679
  static void copyMap(Map dest, Map source) {
    for (final k in source.keys) {
      dest[k] = source[k];
    }
  }
}
