// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:collection/collection.dart';

extension IterableExtension<E> on Iterable<E> {
  /// Note, elements must be unique.
  Map<E, int> get asElementToIndexMap {
    return {for (var (index, element) in indexed) element: index};
  }

  /// Creates a sorted list of the elements of the iterable.
  ///
  /// The elements are ordered first by the natural ordering of the
  /// property returned by [keyOf1], and for elements with equal
  /// [keyOf1] values, by the natural ordering of the property
  /// returned by [keyOf2].
  List<E> sortedBy2<K1 extends Comparable, K2 extends Comparable>(
    K1 Function(E element) keyOf1,
    K2 Function(E element) keyOf2,
  ) {
    return sorted((a, b) {
      var c1 = keyOf1(a).compareTo(keyOf1(b));
      if (c1 != 0) return c1;
      return keyOf2(a).compareTo(keyOf2(b));
    });
  }

  /// Returns the fixed-length [List] with elements of `this`.
  List<E> toFixedList() {
    if (isEmpty) {
      return const <Never>[];
    }
    return toList(growable: false);
  }

  Iterable<E> whereNotType<U>() {
    return whereNot((element) => element is U);
  }
}

extension IterableOfMapEntryExtension<K, V> on Iterable<MapEntry<K, V>> {
  Map<K, V> get mapFromEntries => Map.fromEntries(this);

  Iterable<MapEntry<K, V2>> mapValue<V2>(V2 Function(V) convert) {
    return map((entry) {
      var key = entry.key;
      var value = entry.value;
      var value2 = convert(value);
      return MapEntry(key, value2);
    });
  }
}

extension ListExtension<E> on List<E> {
  Iterable<E> get withoutLast {
    var length = this.length;
    return length > 0 ? take(length - 1) : Iterable.empty();
  }

  void addIfNotNull(E? element) {
    if (element != null) {
      add(element);
    }
  }

  /// Returns the element at [index].
  ///
  /// Returns `null`, if [index] is negative or greater than the length.
  E? elementAtOrNull2(int index) {
    if (0 <= index && index < length) {
      return this[index];
    } else {
      return null;
    }
  }

  bool endsWith(List<E> expected) {
    var thisIndex = length - expected.length;
    if (thisIndex < 0) {
      return false;
    }

    var expectedIndex = 0;
    for (; expectedIndex < expected.length;) {
      if (this[thisIndex++] != expected[expectedIndex++]) {
        return false;
      }
    }
    return true;
  }

  E? nextOrNull(E element) {
    var index = indexOf(element);
    if (index >= 0 && index < length - 1) {
      return this[index + 1];
    } else {
      return null;
    }
  }

  E? removeLastOrNull() {
    if (isNotEmpty) {
      return removeLast();
    }
    return null;
  }

  /// Returns a new list with all elements of the target, arranged such that
  /// all elements for which the [predicate] specified returns `true` come
  /// before those for which the [predicate] returns `false`. The partitioning
  /// is stable, i.e. the relative ordering of the elements is preserved.
  List<E> stablePartition(bool Function(E element) predicate) {
    return [...where(predicate), ...whereNot(predicate)];
  }
}

extension ListQueueExtension<T> on ListQueue<T> {
  T? removeFirstOrNull() {
    return isNotEmpty ? removeFirst() : null;
  }
}

extension MapExtension<K, V> on Map<K, V> {
  K? get firstKey {
    return keys.firstOrNull;
  }

  Map<K2, V> mapKey<K2>(K2 Function(K) convert) {
    return map((key, value) {
      var key2 = convert(key);
      return MapEntry(key2, value);
    });
  }

  Map<K, V2> mapValue<V2>(V2 Function(V) convert) {
    return map((key, value) {
      var value2 = convert(value);
      return MapEntry(key, value2);
    });
  }
}

extension MapOfListExtension<K, V> on Map<K, List<V>> {
  void add(K key, V value) {
    (this[key] ??= []).add(value);
  }

  /// Ensure that [key] is present in the target, maybe with the empty list.
  void addKey(K key) {
    this[key] ??= [];
  }
}

extension SetExtension<E> on Set<E> {
  void addIfNotNull(E? element) {
    if (element != null) {
      add(element);
    }
  }
}
