// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Returns `true` if a and b contain equal elements in the same order.
bool listsEqual(List a, List b) {
  // TODO(rnystrom): package:collection also implements this, and analyzer
  // already transitively depends on that package. Consider using it instead.
  if (identical(a, b)) {
    return true;
  }

  if (a.length != b.length) {
    return false;
  }

  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }

  return true;
}

/// The set of [Enum] values, backed by [int].
extension type EnumSet<T extends Enum>(int _bits) {
  EnumSet.empty() : this(0);

  /// Whether [constant] is present.
  bool operator [](T constant) {
    var index = constant.index;
    _checkIndex(index);

    var mask = 1 << index;
    return (_bits & mask) != 0;
  }

  /// Returns a new set, with presence of [constant] updated.
  EnumSet<T> updated(T constant, bool value) {
    var index = constant.index;
    _checkIndex(index);

    var mask = 1 << index;
    if (value) {
      return EnumSet<T>(_bits | mask);
    } else {
      return EnumSet<T>(_bits & ~mask);
    }
  }

  /// Throws an exception if the [index] does not fit [int].
  static void _checkIndex(int index) {
    if (index < 0 || index > 60) {
      throw RangeError("Index not between 0 and 60: $index");
    }
  }
}
