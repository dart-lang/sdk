// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'package:analyzer/dart/ast/ast.dart'
    show AstNode, CompilationUnit, Identifier;
import 'package:analyzer/dart/element/element.dart'
    show Element, CompilationUnitElement;
import 'package:analyzer/src/generated/source.dart' show LineInfo, Source;
import 'package:source_maps/source_maps.dart' hide Printer;
import 'package:source_span/source_span.dart' show SourceLocation;

import '../js_ast/js_ast.dart' as JS;

class SourceMapPrintingContext extends JS.SimpleJavaScriptPrintingContext {
  /// Current line in the buffer.
  int _line = 0;

  /// Current column in the buffer.
  int _column = 0;

  /// The source_maps builder we write JavaScript code to.
  final sourceMap = new SourceMapBuilder();

  /// The last marked line in the buffer.
  int _previousLine = -1;

  /// The last marked column in the buffer.
  int _previousColumn = -1;

  Uri _sourceUri;
  LineInfo _lineInfo;
  JS.Node _topLevelNode;

  final _ends = new HashMap<JS.Node, int>.identity();

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

  void enterNode(JS.Node jsNode) {
    var srcInfo = jsNode.sourceInformation;
    if (srcInfo == null) return;

    int offset;
    int end;
    CompilationUnitElement unit;
    String identifier;
    if (srcInfo is AstNode) {
      if (srcInfo.isSynthetic) return;
      offset = srcInfo.offset;
      end = srcInfo.end;
      if (srcInfo is Identifier) {
        identifier = srcInfo.name;
      }
      if (_topLevelNode == null) {
        unit = (srcInfo.getAncestor((n) => n is CompilationUnit)
                as CompilationUnit)
            ?.element;
      }
    } else {
      var element = srcInfo as Element;
      if (element.isSynthetic) return;
      offset = element.nameOffset;
      end = offset + element.nameLength;
      identifier = element.name;
      if (identifier == '') identifier = null;
      if (_topLevelNode == null) {
        unit = element.getAncestor((n) => n is CompilationUnitElement);
      }
    }

    if (offset == -1) return;

    // Make sure source locations are associated with the correct source file.
    //
    // Consecutive top-level declarations may come from different compilation
    // units due to ordering within the JS module, and due to parts. Libraries
    // and parts are not necessarily emitted in contiguous blocks.
    if (_topLevelNode == null) {
      // This happens for synthetic nodes created by AstFactory.
      // We don't need to mark positions for them because we'll have a position
      // for the next thing down.
      if (unit == null) return;
      if (unit.source.isInSystemLibrary) {
        _sourceUri = unit.source.uri;
      } else {
        // TODO(jmesserly): this needs serious cleanup.
        // There does appear to be something strange going on with Analyzer
        // URIs if we try and use them directly on Windows.
        // See also compiler.dart placeSourceMap, which could use cleanup too.
        var sourcePath = unit.source.fullName;
        _sourceUri = sourcePath.startsWith('package:')
            ? Uri.parse(sourcePath)
            // TODO(jmesserly): shouldn't this be path.toUri?
            : new Uri.file(sourcePath);
      }

      _topLevelNode = jsNode;
      _lineInfo = unit.lineInfo;
    }

    _mark(offset, identifier);
    _ends[jsNode] = end;
  }

  void exitNode(JS.Node jsNode) {
    if (_topLevelNode == null) return;

    var end = _ends.remove(jsNode);
    if (end != null) _mark(end);

    if (identical(jsNode, _topLevelNode)) {
      _sourceUri = null;
      _lineInfo = null;
      _topLevelNode = null;
    }
  }

  void _mark(int offset, [String identifier]) {
    if (_previousColumn == _column && _previousLine == _line) return;

    var loc = _lineInfo.getLocation(offset);
    // Chrome Devtools wants a mapping for the beginning of
    // a line, so bump locations at the end of a line to the beginning of
    // the next line.
    var next = _lineInfo.getLocation(offset + 1);
    if (next.lineNumber == loc.lineNumber + 1) {
      loc = next;
    }
    _previousLine = _line;
    _previousColumn = _column;
    sourceMap.addLocation(
        new SourceLocation(offset,
            sourceUrl: _sourceUri,
            line: loc.lineNumber - 1,
            column: loc.columnNumber - 1),
        new SourceLocation(buffer.length, line: _line, column: _column),
        identifier);
  }
}

const int _LF = 10;
const int _CR = 13;
