// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_span.location;

import 'span.dart';

// A class that describes a single location within a source file.
class SourceLocation implements Comparable<SourceLocation> {
  /// URL of the source containing this location.
  ///
  /// This may be null, indicating that the source URL is unknown or
  /// unavailable.
  final Uri sourceUrl;

  /// The 0-based offset of this location in the source.
  final int offset;

  /// The 0-based line of this location in the source.
  final int line;

  /// The 0-based column of this location in the source
  final int column;

  /// Returns a representation of this location in the `source:line:column`
  /// format used by text editors.
  ///
  /// This prints 1-based lines and columns.
  String get toolString {
    var source = sourceUrl == null ? 'unknown source' : sourceUrl;
    return '$source:${line + 1}:${column + 1}';
  }

  /// Creates a new location indicating [offset] within [sourceUrl].
  ///
  /// [line] and [column] default to assuming the source is a single line. This
  /// means that [line] defaults to 0 and [column] defaults to [offset].
  ///
  /// [sourceUrl] may be either a [String], a [Uri], or `null`.
  SourceLocation(int offset, {sourceUrl, int line, int column})
      : sourceUrl = sourceUrl is String ? Uri.parse(sourceUrl) : sourceUrl,
        offset = offset,
        line = line == null ? 0 : line,
        column = column == null ? offset : column {
    if (this.offset < 0) {
      throw new RangeError("Offset may not be negative, was $offset.");
    } else if (this.line < 0) {
      throw new RangeError("Line may not be negative, was $line.");
    } else if (this.column < 0) {
      throw new RangeError("Column may not be negative, was $column.");
    }
  }

  /// Returns the distance in characters between [this] and [other].
  ///
  /// This always returns a non-negative value.
  int distance(SourceLocation other) {
    if (sourceUrl != other.sourceUrl) {
      throw new ArgumentError("Source URLs \"${sourceUrl}\" and "
          "\"${other.sourceUrl}\" don't match.");
    }
    return (offset - other.offset).abs();
  }

  /// Returns a span that covers only a single point: this location.
  SourceSpan pointSpan() => new SourceSpan(this, this, "");

  /// Compares two locations.
  ///
  /// [other] must have the same source URL as [this].
  int compareTo(SourceLocation other) {
    if (sourceUrl != other.sourceUrl) {
      throw new ArgumentError("Source URLs \"${sourceUrl}\" and "
          "\"${other.sourceUrl}\" don't match.");
    }
    return offset - other.offset;
  }

  bool operator ==(SourceLocation other) =>
      sourceUrl == other.sourceUrl && offset == other.offset;

  int get hashCode => sourceUrl.hashCode + offset;

  String toString() => '<$runtimeType: $offset $toolString>';
}
