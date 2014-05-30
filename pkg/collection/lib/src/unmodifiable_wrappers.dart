// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Wrappers that prevent a List, Set, or Map object from being modified.
 *
 * The [Set] and [Map] wrappers allow reading from the wrapped collection,
 * but prohibit writing.
 *
 * The [List] wrapper prevents changes to the length of the wrapped list,
 * but allows changes to the contents.
 */
part of dart.pkg.collection.wrappers;

/**
 * A fixed-length list.
 *
 * A `NonGrowableListView` contains a [List] object and ensures that
 * its length does not change.
 * Methods that would change the length of the list,
 * such as [add] and [remove], throw an [UnsupportedError].
 * All other methods work directly on the underlying list.
 *
 * This class _does_ allow changes to the contents of the wrapped list.
 * You can, for example, [sort] the list.
 * Permitted operations defer to the wrapped list.
 */
class NonGrowableListView<E> extends DelegatingList<E>
                             with NonGrowableListMixin<E> {
  NonGrowableListView(List<E> listBase) : super(listBase);
}

/**
 * Mixin class that implements a throwing version of all list operations that
 * change the List's length.
 */
abstract class NonGrowableListMixin<E> implements List<E> {
  static _throw() {
    throw new UnsupportedError(
        "Cannot change the length of a fixed-length list");
  }

  /**
   * Throws an [UnsupportedError];
   * operations that change the length of the list are disallowed.
   */
  void set length(int newLength) => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the length of the list are disallowed.
   */
  bool add(E value) => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the length of the list are disallowed.
   */
  void addAll(Iterable<E> iterable) => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the length of the list are disallowed.
   */
  void insert(int index, E element) => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the length of the list are disallowed.
   */
  void insertAll(int index, Iterable<E> iterable) => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the length of the list are disallowed.
   */
  bool remove(Object value) => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the length of the list are disallowed.
   */
  E removeAt(int index) => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the length of the list are disallowed.
   */
  E removeLast() => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the length of the list are disallowed.
   */
  void removeWhere(bool test(E element)) => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the length of the list are disallowed.
   */
  void retainWhere(bool test(E element)) => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the length of the list are disallowed.
   */
  void removeRange(int start, int end) => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the length of the list are disallowed.
   */
  void replaceRange(int start, int end, Iterable<E> iterable) => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the length of the list are disallowed.
   */
  void clear() => _throw();
}

/**
 * An unmodifiable set.
 *
 * An UnmodifiableSetView contains a [Set] object and ensures
 * that it does not change.
 * Methods that would change the set,
 * such as [add] and [remove], throw an [UnsupportedError].
 * Permitted operations defer to the wrapped set.
 */
class UnmodifiableSetView<E> extends DelegatingSet<E>
                             with UnmodifiableSetMixin<E> {
  UnmodifiableSetView(Set<E> setBase) : super(setBase);
}

/**
 * Mixin class that implements a throwing version of all set operations that
 * change the Set.
 */
abstract class UnmodifiableSetMixin<E> implements Set<E> {
  _throw() {
    throw new UnsupportedError("Cannot modify an unmodifiable Set");
  }

  /**
   * Throws an [UnsupportedError];
   * operations that change the set are disallowed.
   */
  bool add(E value) => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the set are disallowed.
   */
  void addAll(Iterable<E> elements) => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the set are disallowed.
   */
  bool remove(Object value) => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the set are disallowed.
   */
  void removeAll(Iterable elements) => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the set are disallowed.
   */
  void retainAll(Iterable elements) => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the set are disallowed.
   */
  void removeWhere(bool test(E element)) => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the set are disallowed.
   */
  void retainWhere(bool test(E element)) => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the set are disallowed.
   */
  void clear() => _throw();
}

/**
 * An unmodifiable map.
 *
 * An UnmodifiableMapView contains a [Map] object and ensures
 * that it does not change.
 * Methods that would change the map,
 * such as [addAll] and [remove], throw an [UnsupportedError].
 * Permitted operations defer to the wrapped map.
 */
class UnmodifiableMapView<K, V> extends DelegatingMap<K, V>
                                with UnmodifiableMapMixin<K, V> {
  UnmodifiableMapView(Map<K, V> baseMap) : super(baseMap);
}

/**
 * Mixin class that implements a throwing version of all map operations that
 * change the Map.
 */
abstract class UnmodifiableMapMixin<K, V> implements Map<K, V> {
  static _throw() {
    throw new UnsupportedError("Cannot modify an unmodifiable Map");
  }

  /**
   * Throws an [UnsupportedError];
   * operations that change the map are disallowed.
   */
  void operator []=(K key, V value) => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the map are disallowed.
   */
  V putIfAbsent(K key, V ifAbsent()) => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the map are disallowed.
   */
  void addAll(Map<K, V> other) => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the map are disallowed.
   */
  V remove(K key) => _throw();

  /**
   * Throws an [UnsupportedError];
   * operations that change the map are disallowed.
   */
  void clear() => _throw();
}
