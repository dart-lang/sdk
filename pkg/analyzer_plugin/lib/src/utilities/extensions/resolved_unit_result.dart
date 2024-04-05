// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';

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
      if (_isEol(c) || !_isSpace(c)) break;
      whitespaceEndOffset++;
    }
    return content.substring(lineStartOffset, whitespaceEndOffset);
  }

  // TODO(srawlins): Move this to a shared extension in new plugin package when
  // this code is moved to new plugin package.
  bool _isEol(int c) {
    return c == 0x0D || c == 0x0A;
  }

  // TODO(srawlins): Move this to a shared extension in new plugin package when
  // this code is moved to new plugin package.
  bool _isSpace(int c) => c == 0x20 || c == 0x09;
}
