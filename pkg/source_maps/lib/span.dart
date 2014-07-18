// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Dart classes representing the souce spans and source files.
library source_maps.span;

import 'dart:math' show min, max;

import 'package:path/path.dart' as p;

import 'src/utils.dart';

/// A simple class that describe a segment of source text.
abstract class Span implements Comparable {
  /// The start location of this span.
  final Location start;

  /// The end location of this span, exclusive.
  final Location end;

  /// Url of the source (typically a file) containing this span.
  String get sourceUrl => start.sourceUrl;

  /// The length of this span, in characters.
  int get length => end.offset - start.offset;

  /// The source text for this span, if available.
  String get text;

  /// Whether [text] corresponds to an identifier symbol.
  final bool isIdentifier;

  Span(this.start, this.end, bool isIdentifier)
      : isIdentifier = isIdentifier != null ? isIdentifier : false {
    _checkRange();
  }

  /// Creates a new span that is the union of two existing spans [start] and
  /// [end]. Note that the resulting span might contain some positions that were
  /// not in either of the original spans if [start] and [end] are disjoint.
  Span.union(Span start, Span end)
      : start = start.start, end = end.end, isIdentifier = false {
    _checkRange();
  }

  void _checkRange() {
    if (start.offset < 0) throw new ArgumentError('start $start must be >= 0');
    if (end.offset < start.offset) {
      throw new ArgumentError('end $end must be >= start $start');
    }
  }

  /// Compares two spans. If the spans are not in the same source, this method
  /// generates an error.
  int compareTo(Span other) {
    int d = start.compareTo(other.start);
    return d == 0 ? end.compareTo(other.end) : d;
  }

  /// Gets the location in standard printed form `filename:line:column`, where
  /// line and column are adjusted by 1 to match the convention in editors.
  String get formatLocation => start.formatString;

  String getLocationMessage(String message,
      {bool useColors: false, String color}) {
    var source = start.sourceUrl == null ? '' :
        ' of ${p.prettyUri(start.sourceUrl)}';
    return 'line ${start.line + 1}, column ${start.column + 1}$source: ' +
        message;
  }

  bool operator ==(Span other) =>
    sourceUrl == other.sourceUrl && start == other.start && end == other.end;

  int get hashCode => sourceUrl.hashCode + start.offset + (31 * length);

  String toString() => '<$runtimeType: $start $end $formatLocation $text>';
}

/// A location in the source text
abstract class Location implements Comparable {
  /// Url of the source containing this span.
  String get sourceUrl;

  /// The offset of this location, 0-based.
  final int offset;

  /// The 0-based line in the source of this location.
  int get line;

  /// The 0-based column in the source of this location.
  int get column;

  Location(this.offset);

  /// Compares two locations. If the locations are not in the same source, this
  /// method generates an error.
  int compareTo(Location other) {
    if (sourceUrl != other.sourceUrl) {
      throw new ArgumentError('can only compare locations of the same source');
    }
    return offset - other.offset;
  }

  bool operator ==(Location other) =>
      sourceUrl == other.sourceUrl && offset == other.offset;

  int get hashCode => sourceUrl.hashCode + offset;

  String toString() => '(Location $offset)';
  String get formatString => '$sourceUrl:${line + 1}:${column + 1}';
}

/// Implementation of [Location] with fixed values given at allocation time.
class FixedLocation extends Location {
  final String sourceUrl;
  final int line;
  final int column;

  FixedLocation(int offset, this.sourceUrl, this.line, this.column)
      : super(offset);
}

/// Implementation of [Span] where all the values are given at allocation time.
class FixedSpan extends Span {
  /// The source text for this span, if available.
  final String text;

  /// Creates a span which starts and end in the same line.
  FixedSpan(String sourceUrl, int start, int line, int column,
            {String text: '', bool isIdentifier: false})
      : text = text, super(new FixedLocation(start, sourceUrl, line, column),
            new FixedLocation(start + text.length, sourceUrl, line,
                column + text.length),
            isIdentifier);
}

/// [Location] with values computed from an underling [SourceFile].
class FileLocation extends Location {
  /// The source file containing this location.
  final SourceFile file;

  String get sourceUrl => file.url;
  int get line => file.getLine(offset);
  int get column => file.getColumn(line, offset);

  FileLocation(this.file, int offset): super(offset);
}

/// [Span] where values are computed from an underling [SourceFile].
class FileSpan extends Span {
  /// The source file containing this span.
  final SourceFile file;

  /// The source text for this span, if available.
  String get text => file.getText(start.offset, end.offset);

  factory FileSpan(SourceFile file, int start,
      [int end, bool isIdentifier = false]) {
    var startLoc = new FileLocation(file, start);
    var endLoc = end == null ? startLoc : new FileLocation(file, end);
    return new FileSpan.locations(startLoc, endLoc, isIdentifier);
  }

  FileSpan.locations(FileLocation start, FileLocation end,
      bool isIdentifier)
      : file = start.file, super(start, end, isIdentifier);

  /// Creates a new span that is the union of two existing spans [start] and
  /// [end]. Note that the resulting span might contain some positions that were
  /// not in either of the original spans if [start] and [end] are disjoint.
  FileSpan.union(FileSpan start, FileSpan end)
      : file = start.file, super.union(start, end) {
    if (start.file != end.file) {
      throw new ArgumentError('start and end must be from the same file');
    }
  }

  String getLocationMessage(String message,
      {bool useColors: false, String color}) {
    return file.getLocationMessage(message, start.offset, end.offset,
        useColors: useColors, color: color);
  }
}

// Constants to determine end-of-lines.
const int _LF = 10;
const int _CR = 13;

// Color constants used for generating messages.
const String _RED_COLOR = '\u001b[31m';
const String _NO_COLOR = '\u001b[0m';

/// Stores information about a source file, to permit computation of the line
/// and column. Also contains a nice default error message highlighting the code
/// location.
class SourceFile {
  /// Url where the source file is located.
  final String url;
  final List<int> _lineStarts;
  final List<int> _decodedChars;

  SourceFile(this.url, this._lineStarts, this._decodedChars);

  SourceFile.text(this.url, String text)
      : _lineStarts = <int>[0],
        _decodedChars = text.runes.toList() {
    for (int i = 0; i < _decodedChars.length; i++) {
      var c = _decodedChars[i];
      if (c == _CR) {
        // Return not followed by newline is treated as a newline
        int j = i + 1;
        if (j >= _decodedChars.length || _decodedChars[j] != _LF) {
          c = _LF;
        }
      }
      if (c == _LF) _lineStarts.add(i + 1);
    }
  }

  /// Returns a span in this [SourceFile] with the given offsets.
  Span span(int start, [int end, bool isIdentifier = false]) =>
      new FileSpan(this, start, end, isIdentifier);

  /// Returns a location in this [SourceFile] with the given offset.
  Location location(int offset) => new FileLocation(this, offset);

  /// Gets the 0-based line corresponding to an offset.
  int getLine(int offset) => binarySearch(_lineStarts, (o) => o > offset) - 1;

  /// Gets the 0-based column corresponding to an offset.
  int getColumn(int line, int offset) {
    if (line < 0 || line >= _lineStarts.length) return 0;
    return offset - _lineStarts[line];
  }

  /// Get the offset for a given line and column
  int getOffset(int line, int column) {
    if (line < 0) return getOffset(0, 0);
    if (line < _lineStarts.length) {
      return _lineStarts[line] + column;
    } else {
      return _decodedChars.length;
    }
  }

  /// Gets the text at the given offsets.
  String getText(int start, [int end]) =>
      new String.fromCharCodes(_decodedChars.sublist(max(start, 0), end));

  /// Create a pretty string representation from a span.
  String getLocationMessage(String message, int start, int end,
      {bool useColors: false, String color}) {
    // TODO(jmesserly): it would be more useful to pass in an object that
    // controls how the errors are printed. This method is a bit too smart.
    var line = getLine(start);
    var column = getColumn(line, start);

    var source = url == null ? '' : ' of ${p.prettyUri(url)}';
    var msg = 'line ${line + 1}, column ${column + 1}$source: $message';

    if (_decodedChars == null) {
      // We don't have any text to include, so exit.
      return msg;
    }

    var buf = new StringBuffer(msg);
    buf.write('\n');

    // +1 for 0-indexing, +1 again to avoid the last line
    var textLine = getText(getOffset(line, 0), getOffset(line + 1, 0));

    column = min(column, textLine.length - 1);
    int toColumn = min(column + end - start, textLine.length);
    if (useColors) {
      if (color == null) {
        color = _RED_COLOR;
      }
      buf.write(textLine.substring(0, column));
      buf.write(color);
      buf.write(textLine.substring(column, toColumn));
      buf.write(_NO_COLOR);
      buf.write(textLine.substring(toColumn));
    } else {
      buf.write(textLine);
      if (textLine != '' && !textLine.endsWith('\n')) buf.write('\n');
    }

    int i = 0;
    for (; i < column; i++) {
      buf.write(' ');
    }

    if (useColors) buf.write(color);
    for (; i < toColumn; i++) {
      buf.write('^');
    }
    if (useColors) buf.write(_NO_COLOR);
    return buf.toString();
  }
}

/// A convenience type to treat a code segment as if it were a separate
/// [SourceFile]. A [SourceFileSegment] shifts all locations by an offset, which
/// allows you to set source-map locations based on the locations relative to
/// the start of the segment, but that get translated to absolute locations in
/// the original source file.
class SourceFileSegment extends SourceFile {
  final int _baseOffset;
  final int _baseLine;
  final int _baseColumn;
  final int _maxOffset;

  SourceFileSegment(String url, String textSegment, Location startOffset)
      : _baseOffset = startOffset.offset,
        _baseLine = startOffset.line,
        _baseColumn = startOffset.column,
        _maxOffset = startOffset.offset + textSegment.length,
        super.text(url, textSegment);

  /// Craete a span, where [start] is relative to this segment's base offset.
  /// The returned span stores the real offset on the file, so that error
  /// messages are reported at the real location.
  Span span(int start, [int end, bool isIdentifier = false]) =>
      super.span(start + _baseOffset,
          end == null ? null : end + _baseOffset, isIdentifier);

  /// Create a location, where [offset] relative to this segment's base offset.
  /// The returned span stores the real offset on the file, so that error
  /// messages are reported at the real location.
  Location location(int offset) => super.location(offset + _baseOffset);

  /// Return the line on the underlying file associated with the [offset] of the
  /// underlying file. This method operates on the real offsets from the
  /// original file, so that error messages can be reported accurately. When the
  /// requested offset is past the length of the segment, this returns the line
  /// number after the end of the segment (total lines + 1).
  int getLine(int offset) {
    var res = super.getLine(max(offset - _baseOffset, 0)) + _baseLine;
    return (offset > _maxOffset) ? res + 1 : res;
  }

  /// Return the column on the underlying file associated with [line] and
  /// [offset], where [line] is absolute from the beginning of the underlying
  /// file. This method operates on the real offsets from the original file, so
  /// that error messages can be reported accurately.
  int getColumn(int line, int offset) {
    var col = super.getColumn(line - _baseLine, max(offset - _baseOffset, 0));
    return line == _baseLine ? col + _baseColumn : col;
  }

  /// Return the offset associated with a line and column. This method operates
  /// on the real offsets from the original file, so that error messages can be
  /// reported accurately.
  int getOffset(int line, int column) =>
    super.getOffset(line - _baseLine,
        line == _baseLine ? column - _baseColumn : column) + _baseOffset;

  /// Retrieve the text associated with the specified range. This method
  /// operates on the real offsets from the original file, so that error
  /// messages can be reported accurately.
  String getText(int start, [int end]) =>
    super.getText(start - _baseOffset, end == null ? null : end - _baseOffset);
}

/// A class for exceptions that have source span information attached.
class SpanException implements Exception {
  /// A message describing the exception.
  final String message;

  /// The span associated with this exception.
  ///
  /// This may be `null` if the source location can't be determined.
  final Span span;

  SpanException(this.message, this.span);

  String toString({bool useColors: false, String color}) {
    if (span == null) return message;
    return "Error on " + span.getLocationMessage(message,
        useColors: useColors, color: color);
  }
}

/// A [SpanException] that's also a [FormatException].
class SpanFormatException extends SpanException implements FormatException {
  final source;

  SpanFormatException(String message, Span span, [this.source])
      : super(message, span);

  int get offset => span == null ? null : span.start.offset;
}
