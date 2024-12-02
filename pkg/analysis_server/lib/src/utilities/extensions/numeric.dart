// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension DoubleExtensions on double {
  /// Return `true` if this value is between the [lower] and [upper] bound,
  /// inclusive.
  bool between(double lower, double upper) => lower <= this && this <= upper;
}

extension IntExtensions on int {
  /// Returns a string representation of this number with a suffix like 'th',
  /// 'nd' or 'rd'.
  ///
  ///     1 -> 1st
  ///     2 -> 2nd
  ///     11 -> 11th
  ///     21 -> 21st
  String toStringWithSuffix() {
    return switch (this % 100) {
      >= 11 && <= 13 => '${this}th',
      _ => switch (this % 10) {
        1 => '${this}st',
        2 => '${this}nd',
        3 => '${this}rd',
        _ => '${this}th',
      },
    };
  }
}
