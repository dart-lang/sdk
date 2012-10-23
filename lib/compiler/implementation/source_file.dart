// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('source_file');

#import('dart:math');

#import('colors.dart', prefix: 'colors');

/**
 * Represents a file of source code.
 */
class SourceFile {

  /** The name of the file. */
  final String filename;

  /** The text content of the file. */
  final String text;

  List<int> _lineStarts;

  SourceFile(this.filename, this.text);

  List<int> get lineStarts {
    if (_lineStarts == null) {
      var starts = [0];
      var index = 0;
      while (index < text.length) {
        index = text.indexOf('\n', index) + 1;
        if (index <= 0) break;
        starts.add(index);
      }
      starts.add(text.length + 1);
      _lineStarts = starts;
    }
    return _lineStarts;
  }

  int getLine(int position) {
    List<int> starts = lineStarts;
    if (position < 0 || starts.last() <= position) {
      throw 'bad position #$position in file $filename with '
            'length ${text.length}.';
    }
    int first = 0;
    int count = starts.length;
    while (count > 1) {
      int step = count ~/ 2;
      int middle = first + step;
      int lineStart = starts[middle];
      if (position < lineStart) {
        count = step;
      } else {
        first = middle;
        count -= step;
      }
    }
    return first;
  }

  int getColumn(int line, int position) {
    return position - lineStarts[line];
  }

  /**
   * Create a pretty string representation from a character position
   * in the file.
   */
  String getLocationMessage(String message, int start, int end,
                            bool includeText, String color(String x)) {
    var line = getLine(start);
    var column = getColumn(line, start);

    var buf = new StringBuffer(
        '${filename}:${line + 1}:${column + 1}: $message');
    if (includeText) {
      buf.add('\n');
      var textLine;
      // +1 for 0-indexing, +1 again to avoid the last line of the file
      if ((line + 2) < _lineStarts.length) {
        textLine = text.substring(_lineStarts[line], _lineStarts[line+1]);
      } else {
        textLine = '${text.substring(_lineStarts[line])}\n';
      }

      int toColumn = min(column + (end-start), textLine.length);
      buf.add(textLine.substring(0, column));
      buf.add(color(textLine.substring(column, toColumn)));
      buf.add(textLine.substring(toColumn));

      int i = 0;
      for (; i < column; i++) {
        buf.add(' ');
      }

      for (; i < toColumn; i++) {
        buf.add(color('^'));
      }
    }

    return buf.toString();
  }
}
