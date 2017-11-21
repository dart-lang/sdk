// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:source_maps/source_maps.dart' hide Printer;
import 'package:source_span/source_span.dart' show SourceLocation;
import 'package:kernel/kernel.dart';

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

  List<FileUriNode> parentsStack = [];

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
    bool mark = true;
    if (srcInfo is TreeNode) {
      offset = srcInfo.fileOffset;

      if (srcInfo is FileUriNode) {
        parentsStack.add(srcInfo);
        if (srcInfo is Procedure) mark = false;
      }
      if (mark && srcInfo is Block) mark = false;
    } else {
      throw "Unexpected source information: ${srcInfo.runtimeType}";
    }

    if (offset == -1 || !mark) return;

    _mark(offset);
  }

  void exitNode(JS.Node jsNode) {
    var srcInfo = jsNode.sourceInformation;
    if (srcInfo == null) return;

    int offset = -1;
    if (srcInfo is Member) {
      offset = srcInfo.fileEndOffset;
    } else if (srcInfo is FunctionNode) {
      offset = srcInfo.fileEndOffset;
    } else if (srcInfo is Class) {
      offset = srcInfo.fileEndOffset;
    }
    if (offset != -1) _mark(offset);

    if (srcInfo is FileUriNode) {
      parentsStack.removeLast();
    }
  }

  void _mark(int offset) {
    if (_previousColumn == _column && _previousLine == _line) return;

    if (parentsStack.isEmpty) {
      //  TODO(jensj): This for instance happens for top level fields.
      return;
    }

    FileUriNode fileParent = parentsStack.last;
    Program p = fileParent.enclosingProgram;
    String fileUri = fileParent.fileUri;

    var loc = p.getLocation(fileUri, offset);

    // Chrome Devtools wants a mapping for the beginning of
    // a line, so bump locations at the end of a line to the beginning of
    // the next line.
    var next = p.getLocation(fileUri, offset + 1);
    if (next.line == loc.line + 1) {
      loc = next;
    }
    _previousLine = _line;
    _previousColumn = _column;
    sourceMap.addLocation(
        new SourceLocation(offset,
            sourceUrl: fileUri, line: loc.line - 1, column: loc.column - 1),
        new SourceLocation(buffer.length, line: _line, column: _column),
        null);
  }
}

const int _LF = 10;
const int _CR = 13;
