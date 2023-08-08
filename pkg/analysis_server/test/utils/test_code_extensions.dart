// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart'
    show Position, Range;
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';

extension ListTestCodePositionExtension on List<TestCodePosition> {
  /// Return the LSP [Position]s of the markers.
  ///
  /// Positions are based on [TestCode.code], with all parsed markers removed.
  List<Position> get positions => map((position) => position.position).toList();
}

extension ListTestCodeRangeExtension on List<TestCodeRange> {
  /// The LSP [Range]s indicated by the markers.
  ///
  /// Ranges are based on [TestCode.code], with all parsed markers removed.
  List<Range> get ranges => map((range) => range.range).toList();
}

extension TestCodePositionExtension on TestCodePosition {
  /// Return the LSP [Position] of the marker.
  ///
  /// Positions are based on [TestCode.code], with all parsed markers removed.
  Position get position => toPosition(lineInfo.getLocation(offset));
}

extension TestCodeRangeExtension on TestCodeRange {
  /// The LSP [Range] indicated by the markers.
  ///
  /// Ranges are based on [TestCode.code], with all parsed markers removed.
  Range get range => toRange(lineInfo, sourceRange.offset, sourceRange.length);
}
