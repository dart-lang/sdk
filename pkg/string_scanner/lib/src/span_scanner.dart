// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library string_scanner.span_scanner;

import 'package:source_span/source_span.dart';

import 'exception.dart';
import 'line_scanner.dart';
import 'string_scanner.dart';
import 'utils.dart';

/// A subclass of [LineScanner] that exposes matched ranges as source map
/// [Span]s.
class SpanScanner extends StringScanner implements LineScanner {
  /// The source of the scanner.
  ///
  /// This caches line break information and is used to generate [Span]s.
  final SourceFile _sourceFile;

  int get line => _sourceFile.getLine(position);
  int get column => _sourceFile.getColumn(position);

  LineScannerState get state => new _SpanScannerState(this, position);

  set state(LineScannerState state) {
    if (state is! _SpanScannerState ||
        !identical((state as _SpanScannerState)._scanner, this)) {
      throw new ArgumentError("The given LineScannerState was not returned by "
          "this LineScanner.");
    }

    this.position = state.position;
  }

  /// The [FileSpan] for [lastMatch].
  ///
  /// This is the span for the entire match. There's no way to get spans for
  /// subgroups since [Match] exposes no information about their positions.
  FileSpan get lastSpan => _lastSpan;
  FileSpan _lastSpan;

  /// The current location of the scanner.
  FileLocation get location => _sourceFile.location(position);

  /// Returns an empty span at the current location.
  FileSpan get emptySpan => location.pointSpan();

  /// Creates a new [SpanScanner] that starts scanning from [position].
  ///
  /// [sourceUrl] is used as [SourceLocation.sourceUrl] for the returned
  /// [FileSpan]s as well as for error reporting. It can be a [String], a
  /// [Uri], or `null`.
  SpanScanner(String string, {sourceUrl, int position})
      : _sourceFile = new SourceFile(string, url: sourceUrl),
        super(string, sourceUrl: sourceUrl, position: position);

  /// Creates a [FileSpan] representing the source range between [startState]
  /// and the current position.
  FileSpan spanFrom(LineScannerState startState) =>
      _sourceFile.span(startState.position, position);

  bool matches(Pattern pattern) {
    if (!super.matches(pattern)) {
      _lastSpan = null;
      return false;
    }

    _lastSpan = _sourceFile.span(position, lastMatch.end);
    return true;
  }

  void error(String message, {Match match, int position, int length}) {
    validateErrorArgs(string, match, position, length);

    if (match == null && position == null && length == null) match = lastMatch;
    if (position == null) {
      position = match == null ? this.position : match.start;
    }
    if (length == null) length = match == null ? 1 : match.end - match.start;

    var span = _sourceFile.span(position, position + length);
    throw new StringScannerException(message, span, string);
  }
}

/// A class representing the state of a [SpanScanner].
class _SpanScannerState implements LineScannerState {
  /// The [SpanScanner] that created this.
  final SpanScanner _scanner;

  final int position;
  int get line => _scanner._sourceFile.getLine(position);
  int get column => _scanner._sourceFile.getColumn(position);

  _SpanScannerState(this._scanner, this.position);
}
