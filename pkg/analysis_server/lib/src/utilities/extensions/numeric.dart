// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension DoubleExtensions on double {
  /// Return `true` if this value is between the [lower] and [upper] bound,
  /// inclusive.
  bool between(double lower, double upper) => lower <= this && this <= upper;
}
