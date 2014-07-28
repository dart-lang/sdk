// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_maps.span_wrapper;

import 'package:source_span/source_span.dart' as source_span;

import '../span.dart';

/// A wrapper that exposes a [source_span.SourceSpan] as a [Span].
class SpanWrapper extends Span {
  final source_span.SourceSpan _inner;

  String get text => _inner.text;

  SpanWrapper(source_span.SourceSpan inner, bool isIdentifier)
      : _inner = inner,
        super(
            new LocationWrapper(inner.start),
            new LocationWrapper(inner.end),
            isIdentifier);

  static Span wrap(span, [bool isIdentifier = false]) {
    if (span is Span) return span;
    return new SpanWrapper(span, isIdentifier);
  }
}

/// A wrapper that exposes a [source_span.SourceLocation] as a [Location].
class LocationWrapper extends Location {
  final source_span.SourceLocation _inner;

  String get sourceUrl => _inner.sourceUrl.toString();
  int get line => _inner.line;
  int get column => _inner.column;

  LocationWrapper(source_span.SourceLocation inner)
      : _inner = inner,
        super(inner.offset);

  static Location wrap(location) {
    if (location is Location) return location;
    return new LocationWrapper(location);
  }
}

/// A wrapper that exposes a [source_span.SourceFile] as a [SourceFile].
class SourceFileWrapper implements SourceFile {
  final source_span.SourceFile _inner;

  // These are necessary to avoid analyzer warnings;
  final _lineStarts = null;
  final _decodedChars = null;

  String get url => _inner.url.toString();

  SourceFileWrapper(this._inner);

  static SourceFile wrap(sourceFile) {
    if (sourceFile is SourceFile) return sourceFile;
    return new SourceFileWrapper(sourceFile);
  }

  Span span(int start, [int end, bool isIdentifier = false]) {
    if (end == null) end = start;
    return new SpanWrapper(_inner.span(start, end), isIdentifier);
  }

  Location location(int offset) => new LocationWrapper(_inner.location(offset));

  int getLine(int offset) => _inner.getLine(offset);

  int getColumn(int line, int offset) => _inner.getColumn(offset, line: line);

  int getOffset(int line, int column) => _inner.getOffset(line, column);

  String getText(int start, [int end]) => _inner.getText(start, end);

  String getLocationMessage(String message, int start, int end,
      {bool useColors: false, String color}) {
    return span(start, end).getLocationMessage(message,
        useColors: useColors, color: color);
  }
}
