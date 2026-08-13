// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'abstract_single_unit.dart';

mixin SelectionMixin on AbstractSingleUnitTest {
  late int offset;
  late int length;

  void setPosition(int index) {
    if (index < 0 || index >= parsedTestCode.positions.length) {
      throw ArgumentError('Index out of bounds for positions.');
    }
    offset = parsedTestCode.positions[index].offset;
    length = 0;
  }

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

  void setRange(int index) {
    if (index < 0 || index >= parsedTestCode.ranges.length) {
      throw ArgumentError('Index out of bounds for ranges.');
    }
    var range = parsedTestCode.ranges[index].sourceRange;
    offset = range.offset;
    length = range.length;
  }
}
