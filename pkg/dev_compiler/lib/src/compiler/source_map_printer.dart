// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/generated/source.dart' show LineInfo;
import 'package:source_maps/source_maps.dart' hide Printer;
import 'package:source_span/source_span.dart' show SourceLocation;

import '../js_ast/js_ast.dart' as JS;

class SourceMapPrintingContext extends JS.SimpleJavaScriptPrintingContext {
  /// Current line in the buffer;
  int _line = 0;

  /// Current column in the buffer.
  int _column = 0;

  /// The source_maps builder we write JavaScript code to.
  final sourceMap = new SourceMapBuilder();

  Uri _sourceUri;
  LineInfo _lineInfo;
  AstNode _topLevelNode;

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
    AstNode node = jsNode.sourceInformation;
    if (node == null || node.offset == -1 || node.isSynthetic) return;
    if (_topLevelNode == null) {
      // This is a top-level declaration.  Note: consecutive top-level
      // declarations may come from different compilation units due to
      // parts.
      var unit =
          node.getAncestor((n) => n is CompilationUnit) as CompilationUnit;
      // This happens for synthetic nodes created by AstFactory.
      // We don't need to mark positions for them because we'll have a position
      // for the next thing down.
      if (unit == null) return;

      _topLevelNode = node;
      var source = unit.element.source;
      _lineInfo = unit.lineInfo;
      // TODO(jmesserly): this needs serious cleanup.
      // There does appear to be something strange going on with Analyzer
      // Source URIs if we try and use them directly on Windows.
      // See also compiler.dart placeSourceMap, which could use cleanup too.
      var sourcePath = source.fullName;
      _sourceUri = source.isInSystemLibrary
          ? source.uri // this gives cleaner stack traces for SDK libs
          : (sourcePath.startsWith('package:')
              ? Uri.parse(sourcePath)
              // TODO(jmesserly): shouldn't this be path.toUri?
              : new Uri.file(sourcePath));
    }

    _mark(node.offset, _getIdentifier(node));
  }

  void exitNode(JS.Node jsNode) {
    AstNode node = jsNode.sourceInformation;
    if (_topLevelNode == null ||
        node == null ||
        node.offset == -1 ||
        node.isSynthetic) {
      return;
    }

    // TODO(jmesserly): in most cases marking the end will be unnecessary.
    _mark(node.end);

    if (identical(node, _topLevelNode)) {
      _sourceUri = null;
      _lineInfo = null;
      _topLevelNode = null;
    }
  }

  // TODO(jmesserly): prefix identifiers too, if they map to a named element.
  String _getIdentifier(AstNode node) =>
      node is SimpleIdentifier ? node.name : null;

  void _mark(int offset, [String identifier]) {
    var loc = _lineInfo.getLocation(offset);
    // Chrome Devtools wants a mapping for the beginning of
    // a line, so bump locations at the end of a line to the beginning of
    // the next line.
    var next = _lineInfo.getLocation(offset + 1);
    if (next.lineNumber == loc.lineNumber + 1) {
      loc = next;
    }
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
