// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_maps.span_wrapper;

import 'package:source_maps/source_maps.dart';
import 'package:source_span/source_span.dart' as source_span;

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
