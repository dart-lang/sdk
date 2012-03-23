// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('source_file');

#import('../../frog/leg/colors.dart');

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

  List<int> get lineStarts() {
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
    // TODO(jimhug): Implement as binary search.
    var starts = lineStarts;
    for (int i=0; i < starts.length; i++) {
      if (starts[i] > position) return i-1;
    }
    throw 'bad position';
  }

  int getColumn(int line, int position) {
    return position - lineStarts[line];
  }

  /**
   * Create a pretty string representation from a character position
   * in the file.
   */
  String getLocationMessage(String message, int start,
      [int end, bool includeText=false, bool useColors = true]) {
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
        textLine = text.substring(_lineStarts[line]) + '\n';
      }

      int toColumn = Math.min(column + (end-start), textLine.length);
      if (useColors) {
        buf.add(textLine.substring(0, column));
        buf.add(RED_COLOR);
        buf.add(textLine.substring(column, toColumn));
        buf.add(NO_COLOR);
        buf.add(textLine.substring(toColumn));
      } else {
        buf.add(textLine);
      }

      int i = 0;
      for (; i < column; i++) {
        buf.add(' ');
      }

      if (useColors) buf.add(RED_COLOR);
      for (; i < toColumn; i++) {
        buf.add('^');
      }
      if (useColors) buf.add(NO_COLOR);
    }

    return buf.toString();
  }
}
