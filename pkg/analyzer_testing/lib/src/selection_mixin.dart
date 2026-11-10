// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/single_unit.dart';

/// A mixin on [SingleUnitTest] that provides support for setting the selection
/// [offset] and [length] from position or range markers in [parsedTestCode].
mixin SelectionMixin on SingleUnitTest {
  /// The offset of the current selection in the test file.
  late int offset;

  /// The length of the current selection in the test file (`0` for a cursor
  /// position).
  late int length;

  /// Sets [offset] to the position marker at [index] in [parsedTestCode], and
  /// sets [length] to `0`.
  void setPosition(int index) {
    if (index < 0 || index >= parsedTestCode.positions.length) {
      throw ArgumentError('Index out of bounds for positions.');
    }
    offset = parsedTestCode.positions[index].offset;
    length = 0;
  }

  /// Sets [offset] and [length] from the position or range marker at [index] in
  /// [parsedTestCode].
  ///
  /// Uses [setPosition] if [parsedTestCode] contains position markers, or
  /// [setRange] if it contains range markers.
  void setPositionOrRange(int index) {
    if (index < 0) {
      throw ArgumentError('Index must be non-negative.');
    }
    if (parsedTestCode.positions.isNotEmpty) {
      setPosition(index);
    } else if (parsedTestCode.ranges.isNotEmpty) {
      setRange(index);
    } else {
      throw ArgumentError('Test code must contain a position or range marker.');
    }
  }

  /// Sets [offset] and [length] from the range marker at [index] in
  /// [parsedTestCode].
  void setRange(int index) {
    if (index < 0 || index >= parsedTestCode.ranges.length) {
      throw ArgumentError('Index out of bounds for ranges.');
    }
    var range = parsedTestCode.ranges[index].sourceRange;
    offset = range.offset;
    length = range.length;
  }
}
