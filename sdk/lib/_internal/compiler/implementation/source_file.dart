// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_file;

import 'dart:math';
import 'dart:convert' show UTF8;

/**
 * Represents a file of source code. The content can be either a [String] or
 * a UTF-8 encoded [List<int>] of bytes.
 */
abstract class SourceFile {

  /** The name of the file. */
  final String filename;

  SourceFile(this.filename);

  /** The text content of the file represented as a String. */
  String slowText();

  /** The content of the file represented as a UTF-8 encoded [List<int>]. */
  List<int> slowUtf8Bytes();

  /**
   * The length of the string representation of this source file, i.e.,
   * equivalent to [:slowText().length:], but faster.
   */
  int get length;

  /**
   * Sets the string length of this source file. For source files based on UTF-8
   * byte arrays, the string length is computed and assigned by the scanner.
   */
  set length(int v);

  /**
   * A map from line numbers to offsets in the string text representation of
   * this source file.
   */
  List<int> get lineStarts {
    if (lineStartsCache == null) {
      // When reporting errors during scanning, the line numbers are not yet
      // available and need to be computed using this slow path.
      lineStartsCache = lineStartsFromString(slowText());
    }
    return lineStartsCache;
  }

  /**
   * Sets the line numbers map for this source file. This map is computed and
   * assigned by the scanner, avoiding a separate traversal of the source file.
   *
   * The map contains one additional entry at the end of the file, as if the
   * source file had one more empty line at the end. This simplifies the binary
   * search in [getLine].
   */
  set lineStarts(List<int> v) => lineStartsCache = v;

  List<int> lineStartsCache;

  List<int> lineStartsFromString(String text) {
    var starts = [0];
    var index = 0;
    while (index < text.length) {
      index = text.indexOf('\n', index) + 1;
      if (index <= 0) break;
      starts.add(index);
    }
    starts.add(text.length + 1); // One additional line start at the end.
    return starts;
  }

  /**
   * Returns the line number for the offset [position] in the string
   * representation of this source file.
   */
  int getLine(int position) {
    List<int> starts = lineStarts;
    if (position < 0 || starts.last <= position) {
      throw 'bad position #$position in file $filename with '
            'length ${length}.';
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

  /**
   * Returns the column number for the offset [position] in the string
   * representation of this source file.
   */
  int getColumn(int line, int position) {
    return position - lineStarts[line];
  }

  String slowSubstring(int start, int end);

  /**
   * Create a pretty string representation from a character position
   * in the file.
   */
  String getLocationMessage(String message, int start, int end,
                            bool includeText, String color(String x)) {
    var line = getLine(start);
    var column = getColumn(line, start);

    var buf = new StringBuffer('${filename}:');
    if (start != end || start != 0) {
      // Line/column info is relevant.
      buf.write('${line + 1}:${column + 1}:');
    }
    buf.write('\n$message\n');

    if (start != end && includeText) {
      String textLine;
      // +1 for 0-indexing, +1 again to avoid the last line of the file
      if ((line + 2) < lineStarts.length) {
        textLine = slowSubstring(lineStarts[line], lineStarts[line+1]);
      } else {
        textLine = '${slowSubstring(lineStarts[line], length)}\n';
      }

      int toColumn = min(column + (end-start), textLine.length);
      buf.write(textLine.substring(0, column));
      buf.write(color(textLine.substring(column, toColumn)));
      buf.write(textLine.substring(toColumn));

      int i = 0;
      for (; i < column; i++) {
        buf.write(' ');
      }

      for (; i < toColumn; i++) {
        buf.write(color('^'));
      }
    }

    return buf.toString();
  }
}

class Utf8BytesSourceFile extends SourceFile {

  /** The UTF-8 encoded content of the source file. */
  final List<int> content;

  Utf8BytesSourceFile(String filename, this.content) : super(filename);

  String slowText() => UTF8.decode(content);

  List<int> slowUtf8Bytes() => content;

  String slowSubstring(int start, int end) {
    // TODO(lry): to make this faster, the scanner could record the UTF-8 slack
    // for all positions of the source text. We could use [:content.sublist:].
    return slowText().substring(start, end);
  }

  int get length {
    if (lengthCache == -1) {
      // During scanning the length is not yet assigned, so we use a slow path.
      length = slowText().length;
    }
    return lengthCache;
  }
  set length(int v) => lengthCache = v;
  int lengthCache = -1;
}

class CachingUtf8BytesSourceFile extends Utf8BytesSourceFile {
  String cachedText;

  CachingUtf8BytesSourceFile(String filename, List<int> content)
      : super(filename, content);

  String slowText() {
    if (cachedText == null) {
      cachedText = super.slowText();
    }
    return cachedText;
  }
}

class StringSourceFile extends SourceFile {

  final String text;

  StringSourceFile(String filename, this.text) : super(filename);

  int get length => text.length;
  set length(int v) { }

  String slowText() => text;

  List<int> slowUtf8Bytes() => UTF8.encode(text);

  String slowSubstring(int start, int end) => text.substring(start, end);
}
