// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Provides efficient [EnumSet] which only works when 64 bit integers are
/// available.
library;

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
