// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';

extension PositionExtension on Position {
  /// Check if this position is after or equal to [other].
  bool isAfterOrEqual(Position other) =>
      line > other.line || (line == other.line && character >= other.character);

  /// Check if this position is before or equal to [other].
  bool isBeforeOrEqual(Position other) =>
      line < other.line || (line == other.line && character <= other.character);
}

extension RangeExtension on Range {
  /// Check if this range intersects with [other].
  bool intersects(Range other) {
    var endsBefore = end.isBeforeOrEqual(other.start);
    var startsAfter = start.isAfterOrEqual(other.end);
    return !(endsBefore || startsAfter);
  }
}
