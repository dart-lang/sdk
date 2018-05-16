// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * The location of a character represented as a line and column pair.
 */
// ignore: deprecated_member_use
class CharacterLocation extends LineInfo_Location {
  // TODO(brianwilkerson) Replace the body of this class with the body of
  // LineInfo_Location and remove LineInfo_Location.
  /**
   * Initialize a newly created location to represent the location of the
   * character at the given [lineNumber] and [columnNumber].
   */
  CharacterLocation(int lineNumber, int columnNumber)
      : super(lineNumber, columnNumber);
}

/**
 * Information about line and column information within a source file.
 */
class LineInfo {
  /**
   * A list containing the offsets of the first character of each line in the
   * source code.
   */
  final List<int> lineStarts;

  /**
   * The zero-based [lineStarts] index resulting from the last call to
   * [getLocation].
   */
  int _previousLine = 0;

  /**
   * Initialize a newly created set of line information to represent the data
   * encoded in the given list of [lineStarts].
   */
  LineInfo(this.lineStarts) {
    if (lineStarts == null) {
      throw new ArgumentError("lineStarts must be non-null");
    } else if (lineStarts.length < 1) {
      throw new ArgumentError("lineStarts must be non-empty");
    }
  }

  /**
   * Initialize a newly created set of line information corresponding to the
   * given file [content].
   */
  factory LineInfo.fromContent(String content) =>
      new LineInfo(StringUtilities.computeLineStarts(content));

  /**
   * The number of lines.
   */
  int get lineCount => lineStarts.length;

  /**
   * Return the location information for the character at the given [offset].
   *
   * A future version of this API will return a [CharacterLocation] rather than
        // ignore: deprecated_member_use
   * a [LineInfo_Location].
   */
  // ignore: deprecated_member_use
  LineInfo_Location getLocation(int offset) {
    var min = 0;
    var max = lineStarts.length - 1;

    // Subsequent calls to [getLocation] are often for offsets near each other.
    // To take advantage of that, we cache the index of the line start we found
    // when this was last called. If the current offset is on that line or
    // later, we'll skip those early indices completely when searching.
    if (offset >= lineStarts[_previousLine]) {
      min = _previousLine;

      // Before kicking off a full binary search, do a quick check here to see
      // if the new offset is on that exact line.
      if (min == lineStarts.length - 1 || offset < lineStarts[min + 1]) {
        return new CharacterLocation(min + 1, offset - lineStarts[min] + 1);
      }
    }

    // Binary search to fine the line containing this offset.
    while (min < max) {
      var midpoint = (max - min + 1) ~/ 2 + min;

      if (lineStarts[midpoint] > offset) {
        max = midpoint - 1;
      } else {
        min = midpoint;
      }
    }

    _previousLine = min;

    return new CharacterLocation(min + 1, offset - lineStarts[min] + 1);
  }

  /**
   * Return the offset of the first character on the line with the given
   * [lineNumber].
   */
  int getOffsetOfLine(int lineNumber) {
    if (lineNumber < 0 || lineNumber >= lineCount) {
      throw new ArgumentError(
          'Invalid line number: $lineNumber; must be between 0 and ${lineCount - 1}');
    }
    return lineStarts[lineNumber];
  }

  /**
   * Return the offset of the first character on the line following the line
   * containing the given [offset].
   */
  int getOffsetOfLineAfter(int offset) {
    return getOffsetOfLine(getLocation(offset).lineNumber);
  }
}
