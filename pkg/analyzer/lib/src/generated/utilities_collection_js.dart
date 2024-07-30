// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Provides [EnumSet] which works when compiled to JS.
library;

/// The set of [Enum] values, up to `60` constants.
extension type EnumSet<T extends Enum>((int, int) _bits) {
  EnumSet.empty() : this((0, 0));

  /// Whether [constant] is present.
  bool operator [](T constant) {
    var index = constant.index;
    _checkIndex(index);

    // In JavaScript bitwise operations are performed on 32-bit integers.
    if (index <= 30) {
      var mask = 1 << index;
      return (_bits.$1 & mask) != 0;
    } else {
      var mask = 1 << (index - 30);
      return (_bits.$2 & mask) != 0;
    }
  }

  /// Returns a new set, with presence of [constant] updated.
  EnumSet<T> updated(T constant, bool value) {
    var index = constant.index;
    _checkIndex(index);

    if (index <= 30) {
      var mask = 1 << index;
      var field = _bits.$1;
      var newField = value ? field | mask : field & ~mask;
      return EnumSet<T>((newField, _bits.$2));
    } else {
      var mask = 1 << (index - 30);
      var field = _bits.$2;
      var newField = value ? field | mask : field & ~mask;
      return EnumSet<T>((_bits.$1, newField));
    }
  }

  /// Throws an exception if the [index] does not fit the storage.
  static void _checkIndex(int index) {
    if (index < 0 || index > 60) {
      throw RangeError("Index not between 0 and 60: $index");
    }
  }
}
