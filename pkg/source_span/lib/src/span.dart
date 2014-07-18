// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_span.span;

import 'location.dart';
import 'span_mixin.dart';

/// A class that describes a segment of source text.
abstract class SourceSpan implements Comparable<SourceSpan> {
  /// The start location of this span.
  final SourceLocation start;

  /// The end location of this span, exclusive.
  final SourceLocation end;

  /// The source text for this span.
  final String text;

  /// The URL of the source (typically a file) of this span.
  ///
  /// This may be null, indicating that the source URL is unknown or
  /// unavailable.
  final Uri sourceUrl;

  /// The length of this span, in characters.
  final int length;

  /// Creates a new span from [start] to [end] (exclusive) containing [text].
  ///
  /// [start] and [end] must have the same source URL and [start] must come
  /// before [end]. [text] must have a number of characters equal to the
  /// distance between [start] and [end].
  factory SourceSpan(SourceLocation start, SourceLocation end, String text) =>
      new SourceSpanBase(start, end, text);

  /// Creates a new span that's the union of [this] and [other].
  ///
  /// The two spans must have the same source URL and may not be disjoint.
  /// [text] is computed by combining [this.text] and [other.text].
  SourceSpan union(SourceSpan other);

  /// Compares two spans.
  ///
  /// [other] must have the same source URL as [this]. This orders spans by
  /// [start] then [length].
  int compareTo(SourceSpan other);

  /// Formats [message] in a human-friendly way associated with this span.
  ///
  /// [color] may either be a [String], a [bool], or `null`. If it's a string,
  /// it indicates an ANSII terminal color escape that should be used to
  /// highlight the span's text. If it's `true`, it indicates that the text
  /// should be highlighted using the default color. If it's `false` or `null`,
  /// it indicates that the text shouldn't be highlighted.
  String message(String message, {color});
}

/// A base class for source spans with [start], [end], and [text] known at
/// construction time.
class SourceSpanBase extends SourceSpanMixin {
  final SourceLocation start;
  final SourceLocation end;
  final String text;

  SourceSpanBase(this.start, this.end, this.text) {
    if (end.sourceUrl != start.sourceUrl) {
      throw new ArgumentError("Source URLs \"${start.sourceUrl}\" and "
          " \"${end.sourceUrl}\" don't match.");
    } else if (end.offset < start.offset) {
      throw new ArgumentError('End $end must come after start $start.');
    } else if (text.length != start.distance(end)) {
      throw new ArgumentError('Text "$text" must be ${start.distance(end)} '
          'characters long.');
    }
  }
}
