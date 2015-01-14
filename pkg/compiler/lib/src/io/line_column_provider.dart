// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.io.line_column;

import 'code_output.dart';

/// Interface for providing line/column information.
abstract class LineColumnProvider {
  /// Returns the line number (0-based) for [offset].
  int getLine(int offset);

  /// Returns the column number (0-based) for [offset] at the given [line].
  int getColumn(int line, int offset);
}

/// [CodeOutputListener] that collects line information.
class LineColumnCollector extends CodeOutputListener
    implements LineColumnProvider {
  int lastLineStart = 0;
  List<int> lineStarts = <int>[0];

  void _collect(String text) {
    int offset = lastLineStart;
    int index = 0;
    while (index < text.length) {
      // Unix uses '\n' and Windows uses '\r\n', so this algorithm works for
      // both platforms.
      index = text.indexOf('\n', index) + 1;
      if (index <= 0) break;
      lastLineStart = offset + index;
      lineStarts.add(lastLineStart);
    }
  }

  @override
  void onText(String text) {
    _collect(text);
  }

  @override
  int getLine(int offset) {
    List<int> starts = lineStarts;
    if (offset < 0 || starts.last <= offset) {
      throw 'bad position #$offset in buffer with length ${lineStarts.last}.';
    }
    int first = 0;
    int count = starts.length;
    while (count > 1) {
      int step = count ~/ 2;
      int middle = first + step;
      int lineStart = starts[middle];
      if (offset < lineStart) {
        count = step;
      } else {
        first = middle;
        count -= step;
      }
    }
    return first;
  }

  @override
  int getColumn(int line, int offset) {
    return offset - lineStarts[line];
  }

  @override
  void onDone(int length) {
    lineStarts.add(length);
  }
}
