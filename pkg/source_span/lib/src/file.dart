// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_span.file;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'colors.dart' as colors;
import 'location.dart';
import 'span.dart';
import 'span_mixin.dart';
import 'utils.dart';

// Constants to determine end-of-lines.
const int _LF = 10;
const int _CR = 13;

/// A class representing a source file.
///
/// This doesn't necessarily have to correspond to a file on disk, just a chunk
/// of text usually with a URL associated with it.
class SourceFile {
  /// The URL where the source file is located.
  ///
  /// This may be null, indicating that the URL is unknown or unavailable.
  final Uri url;

  /// An array of offsets for each line beginning in the file.
  ///
  /// Each offset refers to the first character *after* the newline. If the
  /// source file has a trailing newline, the final offset won't actually be in
  /// the file.
  final _lineStarts = <int>[0];

  /// The code points of the characters in the file.
  final Uint32List _decodedChars;

  /// The length of the file in characters.
  int get length => _decodedChars.length;

  /// The number of lines in the file.
  int get lines => _lineStarts.length;

  /// Creates a new source file from [text].
  ///
  /// [url] may be either a [String], a [Uri], or `null`.
  SourceFile(String text, {url})
      : this.decoded(text.runes, url: url);

  /// Creates a new source file from a list of decoded characters.
  ///
  /// [url] may be either a [String], a [Uri], or `null`.
  SourceFile.decoded(Iterable<int> decodedChars, {url})
      : url = url is String ? Uri.parse(url) : url,
        _decodedChars = new Uint32List.fromList(decodedChars.toList()) {
    for (var i = 0; i < _decodedChars.length; i++) {
      var c = _decodedChars[i];
      if (c == _CR) {
        // Return not followed by newline is treated as a newline
        var j = i + 1;
        if (j >= _decodedChars.length || _decodedChars[j] != _LF) c = _LF;
      }
      if (c == _LF) _lineStarts.add(i + 1);
    }
  }

  /// Returns a span in [this] from [start] to [end] (exclusive).
  ///
  /// If [end] isn't passed, it defaults to the end of the file.
  FileSpan span(int start, [int end]) {
    if (end == null) end = length - 1;
    return new FileSpan._(this, location(start), location(end));
  }

  /// Returns a location in [this] at [offset].
  FileLocation location(int offset) => new FileLocation._(this, offset);

  /// Gets the 0-based line corresponding to [offset].
  int getLine(int offset) {
    if (offset < 0) {
      throw new RangeError("Offset may not be negative, was $offset.");
    } else if (offset > length) {
      throw new RangeError("Offset $offset must not be greater than the number "
          "of characters in the file, $length.");
    }
    return binarySearch(_lineStarts, (o) => o > offset) - 1;
  }

  /// Gets the 0-based column corresponding to [offset].
  ///
  /// If [line] is passed, it's assumed to be the line containing [offset] and
  /// is used to more efficiently compute the column.
  int getColumn(int offset, {int line}) {
    if (offset < 0) {
      throw new RangeError("Offset may not be negative, was $offset.");
    } else if (offset > length) {
      throw new RangeError("Offset $offset must be not be greater than the "
          "number of characters in the file, $length.");
    }

    if (line == null) {
      line = getLine(offset);
    } else if (line < 0) {
      throw new RangeError("Line may not be negative, was $line.");
    } else if (line >= lines) {
      throw new RangeError("Line $line must be less than the number of "
          "lines in the file, $lines.");
    }

    var lineStart = _lineStarts[line];
    if (lineStart > offset) {
      throw new RangeError("Line $line comes after offset $offset.");
    }

    return offset - lineStart;
  }

  /// Gets the offset for a [line] and [column].
  ///
  /// [column] defaults to 0.
  int getOffset(int line, [int column]) {
    if (column == null) column = 0;

    if (line < 0) {
      throw new RangeError("Line may not be negative, was $line.");
    } else if (line >= lines) {
      throw new RangeError("Line $line must be less than the number of "
          "lines in the file, $lines.");
    } else if (column < 0) {
      throw new RangeError("Column may not be negative, was $column.");
    }

    var result = _lineStarts[line] + column;
    if (result > length ||
        (line + 1 < lines && result >= _lineStarts[line + 1])) {
      throw new RangeError("Line $line doesn't have $column columns.");
    }

    return result;
  }

  /// Returns the text of the file from [start] to [end] (exclusive).
  ///
  /// If [end] isn't passed, it defaults to the end of the file.
  String getText(int start, [int end]) =>
      new String.fromCharCodes(_decodedChars.sublist(start, end));
}

/// A [SourceLocation] within a [SourceFile].
///
/// Unlike the base [SourceLocation], [FileLocation] lazily computes its line
/// and column values based on its offset and the contents of [file].
///
/// A [FileLocation] can be created using [SourceFile.location].
class FileLocation extends SourceLocation {
  /// The [file] that [this] belongs to.
  final SourceFile file;

  Uri get sourceUrl => file.url;
  int get line => file.getLine(offset);
  int get column => file.getColumn(offset);

  FileLocation._(this.file, int offset)
      : super(offset) {
    if (offset > file.length) {
      throw new RangeError("Offset $offset must not be greater than the number "
          "of characters in the file, ${file.length}.");
    }
  }

  FileSpan pointSpan() => new FileSpan._(file, this, this);
}

/// A [SourceSpan] within a [SourceFile].
///
/// Unlike the base [SourceSpan], [FileSpan] lazily computes its line and column
/// values based on its offset and the contents of [file]. [FileSpan.message] is
/// also able to provide more context then [SourceSpan.message], and
/// [FileSpan.union] will return a [FileSpan] if possible.
///
/// A [FileSpan] can be created using [SourceFile.span].
class FileSpan extends SourceSpanMixin {
  /// The [file] that [this] belongs to.
  final SourceFile file;

  final FileLocation start;
  final FileLocation end;

  String get text => file.getText(start.offset, end.offset);

  FileSpan._(this.file, this.start, this.end) {
    if (end.offset < start.offset) {
      throw new ArgumentError('End $end must come after start $start.');
    }
  }

  SourceSpan union(SourceSpan other) {
    if (other is! FileSpan) return super.union(other);

    var span = expand(other);
    var beginSpan = span.start == this.start ? this : other;
    var endSpan = span.end == this.end ? this : other;

    if (beginSpan.end.compareTo(endSpan.start) < 0) {
      throw new ArgumentError("Spans $this and $other are disjoint.");
    }

    return span;
  }

  /// Returns a new span that covers both [this] and [other].
  ///
  /// Unlike [union], [other] may be disjoint from [this]. If it is, the text
  /// between the two will be covered by the returned span.
  FileSpan expand(FileSpan other) {
    if (sourceUrl != other.sourceUrl) {
      throw new ArgumentError("Source URLs \"${sourceUrl}\" and "
          " \"${other.sourceUrl}\" don't match.");
    }

    var start = min(this.start, other.start);
    var end = max(this.end, other.end);
    return new FileSpan._(file, start, end);    
  }

  String message(String message, {color}) {
    if (color == true) color = colors.RED;
    if (color == false) color = null;

    var line = start.line;
    var column = start.column;

    var buffer = new StringBuffer();
    buffer.write('line ${start.line + 1}, column ${start.column + 1}');
    if (sourceUrl != null) buffer.write(' of ${p.prettyUri(sourceUrl)}');
    buffer.write(': $message\n');

    var textLine = file.getText(file.getOffset(line),
        line == file.lines - 1 ? null : file.getOffset(line + 1));

    column = math.min(column, textLine.length - 1);
    var toColumn =
        math.min(column + end.offset - start.offset, textLine.length);

    if (color != null) {
      buffer.write(textLine.substring(0, column));
      buffer.write(color);
      buffer.write(textLine.substring(column, toColumn));
      buffer.write(colors.NONE);
      buffer.write(textLine.substring(toColumn));
    } else {
      buffer.write(textLine);
    }
    if (!textLine.endsWith('\n')) buffer.write('\n');

    buffer.write(' ' * column);
    if (color != null) buffer.write(color);
    buffer.write('^' * math.max(toColumn - column, 1));
    if (color != null) buffer.write(colors.NONE);
    return buffer.toString();
  }
}
