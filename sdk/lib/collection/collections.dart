// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

/**
 * This class provides default implementations for Iterables (including Lists).
 *
 * Once Dart receives Mixins it will be replaced with mixin classes.
 */
class IterableMixinWorkaround {
  static bool contains(Iterable iterable, var element) {
    for (final e in iterable) {
      if (element == e) return true;
    }
    return false;
  }

  static void forEach(Iterable iterable, void f(o)) {
    for (final e in iterable) {
      f(e);
    }
  }

  static bool any(Iterable iterable, bool f(o)) {
    for (final e in iterable) {
      if (f(e)) return true;
    }
    return false;
  }

  static bool every(Iterable iterable, bool f(o)) {
    for (final e in iterable) {
      if (!f(e)) return false;
    }
    return true;
  }

  static dynamic reduce(Iterable iterable,
                        dynamic initialValue,
                        dynamic combine(dynamic previousValue, element)) {
    for (final element in iterable) {
      initialValue = combine(initialValue, element);
    }
    return initialValue;
  }

  /**
   * Simple implementation for [Collection.removeAll].
   *
   * This implementation assumes that [Collection.remove] on [collection]
   * is efficient. The [:remove:] method on [List] objects is typically
   * not efficient since it requires linear search to find an element.
   */
  static void removeAll(Collection collection, Iterable elementsToRemove) {
    for (Object object in elementsToRemove) {
      collection.remove(object);
    }
  }

  /**
   * Implementation of [Collection.removeAll] for lists.
   *
   * This implementation assumes that [Collection.remove] is not efficient
   * (as it usually isn't on a [List]) and uses [Collection.removeMathcing]
   * instead of just repeatedly calling remove.
   */
  static void removeAllList(Collection collection, Iterable elementsToRemove) {
    Set setToRemove;
    // Assume [contains] is efficient on a Set.
    if (elementsToRemove is Set) {
      setToRemove = elementsToRemove;
    } else {
      setToRemove = elementsToRemove.toSet();
    }
    collection.removeMatching(setToRemove.contains);
  }

  /**
   * Simple implemenation for [Collection.retainAll].
   *
   * This implementation assumes that [Collecton.retainMatching] on [collection]
   * is efficient.
   */
  static void retainAll(Collection collection, Iterable elementsToRetain) {
    Set lookup;
    if (elementsToRetain is Set) {
      lookup = elementsToRetain;
    } else {
      lookup = elementsToRetain.toSet();
    }
    if (lookup.isEmpty) {
      collection.clear();
      return;
    }
    collection.retainMatching(lookup.contains);
  }

  /**
   * Simple implemenation for [Collection.removeMatching].
   *
   * This implementation assumes that [Collecton.removeAll] on [collection] is
   * efficient.
   */
  static void removeMatching(Collection collection, bool test(var element)) {
    List elementsToRemove = [];
    for (var element in collection) {
      if (test(element)) elementsToRemove.add(element);
    }
    collection.removeAll(elementsToRemove);
  }

  /**
   * Removes elements matching [test] from [list].
   *
   * This is performed in two steps, to avoid exposing an inconsistent state
   * to the [test] function. First the elements to ratain are found, and then
   * the original list is updated to contain those elements.
   */
  static void removeMatchingList(List list, bool test(var element)) {
    List retained = [];
    int length = list.length;
    for (int i = 0; i < length; i++) {
      var element = list[i];
      if (!test(element)) {
        retained.add(element);
      }
      if (length != list.length) {
        throw new ConcurrentModificationError(list);
      }
    }
    if (retained.length == length) return;
    for (int i = 0; i < retained.length; i++) {
      list[i] = retained[i];
    }
    list.length = retained.length;
  }

  /**
   * Simple implemenation for [Collection.retainMatching].
   *
   * This implementation assumes that [Collecton.removeAll] on [collection] is
   * efficient.
   */
  static void retainMatching(Collection collection, bool test(var element)) {
    List elementsToRemove = [];
    for (var element in collection) {
      if (!test(element)) elementsToRemove.add(element);
    }
    collection.removeAll(elementsToRemove);
  }

  static bool isEmpty(Iterable iterable) {
    return !iterable.iterator.moveNext();
  }

  static dynamic first(Iterable iterable) {
    Iterator it = iterable.iterator;
    if (!it.moveNext()) {
      throw new StateError("No elements");
    }
    return it.current;
  }

  static dynamic last(Iterable iterable) {
    Iterator it = iterable.iterator;
    if (!it.moveNext()) {
      throw new StateError("No elements");
    }
    dynamic result;
    do {
      result = it.current;
    } while(it.moveNext());
    return result;
  }

  static dynamic min(Iterable iterable, [int compare(var a, var b)]) {
    if (compare == null) compare = Comparable.compare;
    Iterator it = iterable.iterator;
    if (!it.moveNext()) {
      return null;
    }
    var min = it.current;
    while (it.moveNext()) {
      if (compare(min, it.current) > 0) min = it.current;
    }
    return min;
  }

  static dynamic max(Iterable iterable, [int compare(var a, var b)]) {
    if (compare == null) compare = Comparable.compare;
    Iterator it = iterable.iterator;
    if (!it.moveNext()) {
      return null;
    }
    var max = it.current;
    while (it.moveNext()) {
      if (compare(max, it.current) < 0) max = it.current;
    }
    return max;
  }

  static dynamic single(Iterable iterable) {
    Iterator it = iterable.iterator;
    if (!it.moveNext()) throw new StateError("No elements");
    dynamic result = it.current;
    if (it.moveNext()) throw new StateError("More than one element");
    return result;
  }

  static dynamic firstMatching(Iterable iterable,
                               bool test(dynamic value),
                               dynamic orElse()) {
    for (dynamic element in iterable) {
      if (test(element)) return element;
    }
    if (orElse != null) return orElse();
    throw new StateError("No matching element");
  }

  static dynamic lastMatching(Iterable iterable,
                              bool test(dynamic value),
                              dynamic orElse()) {
    dynamic result = null;
    bool foundMatching = false;
    for (dynamic element in iterable) {
      if (test(element)) {
        result = element;
        foundMatching = true;
      }
    }
    if (foundMatching) return result;
    if (orElse != null) return orElse();
    throw new StateError("No matching element");
  }

  static dynamic lastMatchingInList(List list,
                                    bool test(dynamic value),
                                    dynamic orElse()) {
    // TODO(floitsch): check that arguments are of correct type?
    for (int i = list.length - 1; i >= 0; i--) {
      dynamic element = list[i];
      if (test(element)) return element;
    }
    if (orElse != null) return orElse();
    throw new StateError("No matching element");
  }

  static dynamic singleMatching(Iterable iterable, bool test(dynamic value)) {
    dynamic result = null;
    bool foundMatching = false;
    for (dynamic element in iterable) {
      if (test(element)) {
        if (foundMatching) {
          throw new StateError("More than one matching element");
        }
        result = element;
        foundMatching = true;
      }
    }
    if (foundMatching) return result;
    throw new StateError("No matching element");
  }

  static dynamic elementAt(Iterable iterable, int index) {
    if (index is! int || index < 0) throw new RangeError.value(index);
    int remaining = index;
    for (dynamic element in iterable) {
      if (remaining == 0) return element;
      remaining--;
    }
    throw new RangeError.value(index);
  }

  static String join(Iterable iterable, [String separator]) {
    Iterator iterator = iterable.iterator;
    if (!iterator.moveNext()) return "";
    StringBuffer buffer = new StringBuffer();
    if (separator == null || separator == "") {
      do {
        buffer.add("${iterator.current}");
      } while (iterator.moveNext());
    } else {
      buffer.add("${iterator.current}");
      while (iterator.moveNext()) {
        buffer.add(separator);
        buffer.add("${iterator.current}");
      }
    }
    return buffer.toString();
  }

  static String joinList(List list, [String separator]) {
    if (list.isEmpty) return "";
    if (list.length == 1) return "${list[0]}";
    StringBuffer buffer = new StringBuffer();
    if (separator == null || separator == "") {
      for (int i = 0; i < list.length; i++) {
        buffer.add("${list[i]}");
      }
    } else {
      buffer.add("${list[0]}");
      for (int i = 1; i < list.length; i++) {
        buffer.add(separator);
        buffer.add("${list[i]}");
      }
    }
    return buffer.toString();
  }

  static Iterable where(Iterable iterable, bool f(var element)) {
    return new WhereIterable(iterable, f);
  }

  static List mappedByList(List list, f(var element)) {
    return new MappedList(list, f);
  }

  static List takeList(List list, int n) {
    // The generic type is currently lost. It will be fixed with mixins.
    return new ListView(list, 0, n);
  }

  static Iterable takeWhile(Iterable iterable, bool test(var value)) {
    // The generic type is currently lost. It will be fixed with mixins.
    return new TakeWhileIterable(iterable, test);
  }

  static List skipList(List list, int n) {
    // The generic type is currently lost. It will be fixed with mixins.
    return new ListView(list, n, null);
  }

  static Iterable skipWhile(Iterable iterable, bool test(var value)) {
    // The generic type is currently lost. It will be fixed with mixins.
    return new SkipWhileIterable(iterable, test);
  }

  static void sortList(List l, int compare(a, b)) {
    if (compare == null) compare = Comparable.compare;
    Sort.sort(l, compare);
  }
}

/**
 * The [Collections] class implements static methods useful when
 * writing a class that implements [Collection] and the [iterator]
 * method.
 */
class Collections {
  /** Deprecated. Use the same method in [IterableMixinWorkaround] instead.*/
  static bool contains(Iterable iterable, var element)
      => IterableMixinWorkaround.contains(iterable, element);

  /** Deprecated. Use the same method in [IterableMixinWorkaround] instead.*/
  static void forEach(Iterable iterable, void f(o)) {
    IterableMixinWorkaround.forEach(iterable, f);
  }

  /** Deprecated. Use the same method in [IterableMixinWorkaround] instead.*/
  static bool any(Iterable iterable, bool f(o))
      => IterableMixinWorkaround.any(iterable, f);

  /** Deprecated. Use the same method in [IterableMixinWorkaround] instead.*/
  static bool every(Iterable iterable, bool f(o))
      => IterableMixinWorkaround.every(iterable, f);

  /** Deprecated. Use the same method in [IterableMixinWorkaround] instead.*/
  static dynamic reduce(Iterable iterable,
                        dynamic initialValue,
                        dynamic combine(dynamic previousValue, element))
      => IterableMixinWorkaround.reduce(iterable, initialValue, combine);

  /** Deprecated. Use the same method in [IterableMixinWorkaround] instead.*/
  static bool isEmpty(Iterable iterable)
      => IterableMixinWorkaround.isEmpty(iterable);

  /** Deprecated. Use the same method in [IterableMixinWorkaround] instead.*/
  static dynamic first(Iterable iterable)
      => IterableMixinWorkaround.first(iterable);

  /** Deprecated. Use the same method in [IterableMixinWorkaround] instead.*/
  static dynamic last(Iterable iterable)
      => IterableMixinWorkaround.last(iterable);

  /** Deprecated. Use the same method in [IterableMixinWorkaround] instead.*/
  static dynamic min(Iterable iterable, [int compare(var a, var b)])
      => IterableMixinWorkaround.min(iterable, compare);

  /** Deprecated. Use the same method in [IterableMixinWorkaround] instead.*/
  static dynamic max(Iterable iterable, [int compare(var a, var b)])
      => IterableMixinWorkaround.max(iterable, compare);

  /** Deprecated. Use the same method in [IterableMixinWorkaround] instead.*/
  static dynamic single(Iterable iterable)
      => IterableMixinWorkaround.single(iterable);

  /** Deprecated. Use the same method in [IterableMixinWorkaround] instead.*/
  static dynamic firstMatching(Iterable iterable,
                               bool test(dynamic value),
                               dynamic orElse())
      => IterableMixinWorkaround.firstMatching(iterable, test, orElse);

  /** Deprecated. Use the same method in [IterableMixinWorkaround] instead.*/
  static dynamic lastMatching(Iterable iterable,
                              bool test(dynamic value),
                              dynamic orElse())
      => IterableMixinWorkaround.lastMatching(iterable, test, orElse);

  /** Deprecated. Use the same method in [IterableMixinWorkaround] instead.*/
  static dynamic lastMatchingInList(List list,
                                    bool test(dynamic value),
                                    dynamic orElse())
      => IterableMixinWorkaround.lastMatchingInList(list, test, orElse);

  /** Deprecated. Use the same method in [IterableMixinWorkaround] instead.*/
  static dynamic singleMatching(Iterable iterable, bool test(dynamic value))
      => IterableMixinWorkaround.singleMatching(iterable, test);

  /** Deprecated. Use the same method in [IterableMixinWorkaround] instead.*/
  static dynamic elementAt(Iterable iterable, int index)
      => IterableMixinWorkaround.elementAt(iterable, index);

  /** Deprecated. Use the same method in [IterableMixinWorkaround] instead.*/
  static String join(Iterable iterable, [String separator])
      => IterableMixinWorkaround.join(iterable, separator);

  /** Deprecated. Use the same method in [IterableMixinWorkaround] instead.*/
  static String joinList(List list, [String separator])
      => IterableMixinWorkaround.joinList(list, separator);

  /** Deprecated. Use the same method in [IterableMixinWorkaround] instead.*/
  static Iterable where(Iterable iterable, bool f(var element))
      => IterableMixinWorkaround.where(iterable, f);

  /** Deprecated. Use the same method in [IterableMixinWorkaround] instead.*/
  static List mappedByList(List list, f(var element))
      => IterableMixinWorkaround.mappedByList(list, f);

  /** Deprecated. Use the same method in [IterableMixinWorkaround] instead.*/
  static List takeList(List list, int n)
      => IterableMixinWorkaround.takeList(list, n);

  /** Deprecated. Use the same method in [IterableMixinWorkaround] instead.*/
  static Iterable takeWhile(Iterable iterable, bool test(var value))
      => IterableMixinWorkaround.takeWhile(iterable, test);

  /** Deprecated. Use the same method in [IterableMixinWorkaround] instead.*/
  static List skipList(List list, int n)
      => IterableMixinWorkaround.skipList(list, n);

  /** Deprecated. Use the same method in [IterableMixinWorkaround] instead.*/
  static Iterable skipWhile(Iterable iterable, bool test(var value))
      => IterableMixinWorkaround.skipWhile(iterable, test);

  static String collectionToString(Collection c)
      => ToString.collectionToString(c);
}
