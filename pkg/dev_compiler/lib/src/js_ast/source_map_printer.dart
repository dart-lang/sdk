// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// ignore_for_file: always_declare_return_types, omit_local_variable_types

import 'package:source_maps/source_maps.dart' hide Printer;
import 'package:source_span/source_span.dart' show SourceLocation;
import 'js_ast.dart';

class NodeEnd {
  final SourceLocation end;
  NodeEnd(this.end);
  @override
  toString() => '#<NodeEnd $end>';
}

class NodeSpan {
  final SourceLocation start, end;
  NodeSpan(this.start, this.end);
  @override
  toString() => '#<NodeSpan $start to $end>';
}

class HoverComment {
  final SourceLocation start, end;
  final Expression expression;
  HoverComment(this.expression, this.start, this.end);
  @override
  toString() => '#<HoverComment `$expression` @ $start to $end>';
}

class SourceMapPrintingContext extends SimpleJavaScriptPrintingContext {
  /// Current line in the buffer.
  int _line = 0;

  /// Current column in the buffer.
  int _column = 0;

  /// The source_maps builder we write JavaScript code to.
  final sourceMap = SourceMapBuilder();

  /// The last marked line in the buffer.
  int _previousDartOffset = -1;

  SourceLocation _pendingDartOffset;
  SourceLocation _pendingJSLocation;

  @override
  void emit(String code) {
    var chars = code.runes.toList();
    var length = chars.length;
    for (int i = 0; i < length; i++) {
      var c = chars[i];
      if (c == _LF || (c == _CR && (i + 1 == length || chars[i + 1] != _LF))) {
        // Return not followed by line-feed is treated as a new line.
        _line++;
        _column = 0;
      } else {
        _column++;
      }
    }
    super.emit(code);
  }

  @override
  void enterNode(Node node) {
    var srcInfo = node.sourceInformation;
    if (srcInfo == null) return;

    SourceLocation dartStart;
    if (srcInfo is SourceLocation) {
      dartStart = srcInfo;
    } else if (srcInfo is NodeSpan) {
      dartStart = srcInfo.start;
    } else if (srcInfo is HoverComment) {
      emit('/*');
      _mark(srcInfo.start);
      srcInfo.expression.accept(printer);
      _mark(srcInfo.end);
      emit('*/');
    } else if (srcInfo is! NodeEnd) {
      throw StateError(
          'wrong kind of source map data: `$srcInfo` <${srcInfo.runtimeType}>');
    }

    if (dartStart != null) {
      if (node is Expression) {
        _markExpressionStart(dartStart);
      } else {
        _mark(dartStart);
      }
    }
  }

  @override
  void exitNode(Node node) {
    if (node is! Expression) _flushPendingMarks();

    var srcInfo = node.sourceInformation;
    if (srcInfo == null) return;

    SourceLocation dartEnd;
    if (srcInfo is NodeSpan) {
      dartEnd = srcInfo.end;
    } else if (srcInfo is NodeEnd) {
      dartEnd = srcInfo.end;
    } else if (srcInfo is! SourceLocation && srcInfo is! HoverComment) {
      throw StateError(
          'wrong kind of source map data: `$srcInfo` <${srcInfo.runtimeType}>');
    }

    if (dartEnd != null) {
      if (node is Fun || node is Method || node is NamedFunction) {
        // Mark the exit point of a function. V8 steps to the end of a function
        // at its exit, so this provides a mapping for that location.
        int column = _column - 1;
        if (column >= 0) {
          // Adjust the colum, because any ending brace or semicolon is already in
          // the output.
          var jsEnd =
              SourceLocation(buffer.length - 1, line: _line, column: column);
          _mark(dartEnd, jsEnd);
        }
      } else {
        _mark(dartEnd);
      }
    }
  }

  /// Marks that we entered a Dart node at this offset.
  ///
  /// Multiple nested Dart expressions will appear to start at the same Dart
  /// location, but they can have different JavaScript locations. For example:
  ///
  ///     get foo => _foo.bar && _baz;
  ///     //         ^^^^^^^^^^^^^^^^ binary-op, JS code `dart.test(...) && ...`
  ///     //         ^^^^^^^^         property access, JS code `this[_foo].bar`
  ///     //         ^^^^             identifier, JS code `this[_foo]`
  ///
  /// To ensure hover works, we must not include `dart.test` at the start of
  /// `_foo`. Also to ensure `_foo` and `_foo.bar` works, we must mark the end
  /// of `_foo`.
  void _markExpressionStart(SourceLocation dartOffset) {
    if (_pendingDartOffset != dartOffset) _flushPendingMarks();
    _pendingDartOffset = dartOffset;
    _pendingJSLocation = _getJSLocation();
  }

  /// Mark any pending marks from [_markExpressionStart].
  ///
  /// This ensures we get the innermost JS offset for a given Dart offset.
  void _flushPendingMarks() {
    var pending = _pendingDartOffset;
    if (pending != null) {
      _markInternal(pending, _pendingJSLocation);
      _pendingDartOffset = null;
      _pendingJSLocation = null;
    }
  }

  void _mark(SourceLocation dartLocation, [SourceLocation jsLocation]) {
    _flushPendingMarks();
    jsLocation ??= _getJSLocation();
    _markInternal(dartLocation, jsLocation);
  }

  void _markInternal(SourceLocation dartLocation, SourceLocation jsLocation) {
    // Don't mark the same JS location to two different Dart locations.
    if (_previousDartOffset == dartLocation.offset) return;
    _previousDartOffset = dartLocation.offset;
    sourceMap.addLocation(dartLocation, jsLocation, null);
  }

  SourceLocation _getJSLocation() =>
      SourceLocation(buffer.length, line: _line, column: _column);
}

const int _LF = 10;
const int _CR = 13;
