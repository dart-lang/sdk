// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';

extension ResolvedUnitResultExtension on ResolvedUnitResult {
  /// Returns the whitespace prefix of the line which contains the given
  /// [offset].
  String linePrefix(int offset) {
    var lineStartOffset =
        lineInfo.getOffsetOfLine(lineInfo.getLocation(offset).lineNumber - 1);
    var length = content.length;
    var whitespaceEndOffset = lineStartOffset;
    while (whitespaceEndOffset < length) {
      var c = content.codeUnitAt(whitespaceEndOffset);
      if (c.isEOL || !c.isSpace) break;
      whitespaceEndOffset++;
    }
    return content.substring(lineStartOffset, whitespaceEndOffset);
  }
}
