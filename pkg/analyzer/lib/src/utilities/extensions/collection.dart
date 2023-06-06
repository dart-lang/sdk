// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

  E? nextOrNull(E element) {
    final index = indexOf(element);
    if (index >= 0 && index < length - 1) {
      return this[index + 1];
    } else {
      return null;
    }
  }
}

extension SetExtension<E> on Set<E> {
  void addIfNotNull(E? element) {
    if (element != null) {
      add(element);
    }
  }
}
