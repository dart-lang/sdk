// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jimhug): This should be an interface to work better with tools.
/**
 * Represents a file of source code.
 */
class SourceFile implements Comparable {
  // TODO(terry): This filename for in memory buffer.  May need to rework if
  //              filename is used for more than informational.
  static String IN_MEMORY_FILE = '<buffer>';

  /** The name of the file. */
  final String filename;

  /** The text content of the file. */
  String _text;

  /**
   * The order of the source file in a given library. This is used while we're
   * writing code for a library. A single source file can be used
   */
  // TODO(jmesserly): I don't like having properties that are only valid
  // sometimes. An alternative would be to store it in a Map that's used by
  // WorldGenerator while it's emitting code. This seems simpler.
  int orderInLibrary;

  List<int> _lineStarts;

  SourceFile(this.filename, this._text);

  String get text() => _text;

  set text(String newText) {
    if (newText != _text) {
      _text = newText;
      _lineStarts = null;
      orderInLibrary = null;
    }
  }

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
    world.internalError('bad position');
  }

  int getColumn(int line, int position) {
    return position - lineStarts[line];
  }

  /**
   * Create a pretty string representation from a character position
   * in the file.
   */
  String getLocationMessage(String message, int start,
      [int end, bool includeText=false]) {
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
      if (options.useColors) {
        buf.add(textLine.substring(0, column));
        buf.add(_RED_COLOR);
        buf.add(textLine.substring(column, toColumn));
        buf.add(_NO_COLOR);
        buf.add(textLine.substring(toColumn));
      } else {
        buf.add(textLine);
      }

      int i = 0;
      for (; i < column; i++) {
        buf.add(' ');
      }

      if (options.useColors) buf.add(_RED_COLOR);
      for (; i < toColumn; i++) {
        buf.add('^');
      }
      if (options.useColors) buf.add(_NO_COLOR);
    }

    return buf.toString();
  }

  /** Compares two source files. */
  int compareTo(SourceFile other) {
    if (orderInLibrary != null && other.orderInLibrary != null) {
      return orderInLibrary - other.orderInLibrary;
    } else {
      return filename.compareTo(other.filename);
    }
  }
}


/**
 * A range of characters in a [SourceFile].  Used to represent the source
 * positions of [Token]s and [Node]s for error reporting or other tooling
 * work.
 */
 // TODO(jmesserly): Rename to Span - but first write cool refactoring tool
class SourceSpan implements Comparable {
  /** The [SourceFile] that contains this span. */
  final SourceFile file;

  /** The character position of the start of this span. */
  final int start;

  /** The character position of the end of this span. */
  final int end;

  SourceSpan(this.file, this.start, this.end);

  /** Returns the source text corresponding to this [Span]. */
  String get text() {
    return file.text.substring(start, end);
  }

  toMessageString(String message) {
    return file.getLocationMessage(message, start, end: end, includeText: true);
  }

  int get line() {
    return file.getLine(start);
  }

  int get column() {
    return file.getColumn(line, start);
  }

  int get endLine() {
    return file.getLine(end);
  }

  int get endColumn() {
    return file.getColumn(endLine, end);
  }

  String get locationText() {
    var line = file.getLine(start);
    var column = file.getColumn(line, start);
    return '${file.filename}:${line + 1}:${column + 1}';
  }

  /** Compares two source spans by file and position. Handles nulls. */
  int compareTo(SourceSpan other) {
    if (file == other.file) {
      int d = start - other.start;
      return d == 0 ? (end - other.end) : d;
    }
    return file.compareTo(other.file);
  }
}
