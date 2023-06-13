// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
}

extension ListExtension<E> on List<E> {
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

  E? nextOrNull(E element) {
    final index = indexOf(element);
    if (index >= 0 && index < length - 1) {
      return this[index + 1];
    } else {
      return null;
    }
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

extension SetExtension<E> on Set<E> {
  void addIfNotNull(E? element) {
    if (element != null) {
      add(element);
    }
  }
}
