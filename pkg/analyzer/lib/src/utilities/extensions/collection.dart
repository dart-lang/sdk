// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:collection/collection.dart';

extension IterableExtension<E> on Iterable<E> {
  /// Returns the fixed-length [List] with elements of `this`.
  List<E> toFixedList() {
    var result = toList(growable: false);
    if (result.isEmpty) {
      return const <Never>[];
    }
    return result;
  }

  Iterable<E> whereNotType<U>() {
    return whereNot((element) => element is U);
  }
}

extension IterableIterableExtension<T> on Iterable<Iterable<T>> {
  /// Elements of each iterable in this iterable.
  ///
  /// At the moment of writing, this method is `2.75` times faster than
  /// `expand((e) => e)`, and `3.5` faster than `flattened` from
  /// `package:collection`.
  List<T> get flattenedToList2 {
    return [
      for (final elements in this) ...elements,
    ];
  }

  /// Elements of each iterable in this iterable.
  Set<T> get flattenedToSet2 {
    return {
      for (final elements in this) ...elements,
    };
  }
}

extension IterableMapEntryExtension<K, V> on Iterable<MapEntry<K, V>> {
  Map<K, V> get mapFromEntries => Map.fromEntries(this);
}

extension ListExtension<E> on List<E> {
  Iterable<E> get withoutLast {
    final length = this.length;
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
    final index = indexOf(element);
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
    return [
      ...where(predicate),
      ...whereNot(predicate),
    ];
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
}

extension MapOfListValuesExtension<K, V> on Map<K, List<V>> {
  void add(K key, V value) {
    (this[key] ??= []).add(value);
  }
}

extension SetExtension<E> on Set<E> {
  void addIfNotNull(E? element) {
    if (element != null) {
      add(element);
    }
  }
}
