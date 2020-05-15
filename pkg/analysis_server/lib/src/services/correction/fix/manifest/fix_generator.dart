// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/src/utilities/strings.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/manifest/manifest_warning_code.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:html/dom.dart';
import 'package:meta/meta.dart';

/// An object used to locate the HTML [Node] associated with a source range.
/// More specifically, it will return the deepest HTML [Node] which completely
/// encompasses the specified range.
class HtmlNodeLocator {
  /// The inclusive start offset of the range used to identify the node.
  final int _startOffset;

  /// The inclusive end offset of the range used to identify the node.
  final int _endOffset;

  /// Initialize a newly created locator to locate the deepest [Node] for
  /// which `node.offset <= [start]` and `[end] < node.end`.
  ///
  /// If the [end] offset is not provided, then it is considered the same as the
  /// [start] offset.
  HtmlNodeLocator({@required int start, int end})
      : _startOffset = start,
        _endOffset = end ?? start;

  /// Search within the given HTML [node] and return the path to the most deeply
  /// nested node that includes the whole target range, or an empty list if no
  /// node was found. The path is represented by all of the elements from the
  /// starting [node] to the most deeply nested node, in reverse order.
  List<Node> searchWithin(Node node) {
    var path = <Node>[];
    _searchWithin(path, node);
    return path;
  }

  void _searchWithin(List<Node> path, Node node) {
    var span = node.sourceSpan;
    if (span.start.offset > _endOffset || span.end.offset < _startOffset) {
      return;
    }
    for (var element in node.children) {
      _searchWithin(path, element);
      if (path.isNotEmpty) {
        path.add(node);
        return;
      }
    }
    path.add(node);
  }
}

/// The generator used to generate fixes in Android manifest files.
class ManifestFixGenerator {
  final AnalysisError error;

  final int errorOffset;

  final int errorLength;

  final String content;

  final DocumentFragment document;

  final LineInfo lineInfo;

  final List<Fix> fixes = <Fix>[];

  List<Node> coveringNodePath;

  ManifestFixGenerator(this.error, this.content, this.document)
      : errorOffset = error.offset,
        errorLength = error.length,
        lineInfo = LineInfo.fromContent(content);

  /// Return the absolute, normalized path to the file in which the error was
  /// reported.
  String get file => error.source.fullName;

  /// Return the list of fixes that apply to the error being fixed.
  Future<List<Fix>> computeFixes() async {
    var locator =
        HtmlNodeLocator(start: errorOffset, end: errorOffset + errorLength - 1);
    coveringNodePath = locator.searchWithin(document);
    if (coveringNodePath.isEmpty) {
      return fixes;
    }

    var errorCode = error.errorCode;
    if (errorCode == ManifestWarningCode.UNSUPPORTED_CHROME_OS_HARDWARE) {
    } else if (errorCode ==
        ManifestWarningCode.PERMISSION_IMPLIES_UNSUPPORTED_HARDWARE) {
    } else if (errorCode ==
        ManifestWarningCode.CAMERA_PERMISSIONS_INCOMPATIBLE) {}
    return fixes;
  }

  /// Add a fix whose edits were built by the [builder] that has the given
  /// [kind]. If [args] are provided, they will be used to fill in the message
  /// for the fix.
  // ignore: unused_element
  void _addFixFromBuilder(ChangeBuilder builder, FixKind kind, {List args}) {
    var change = builder.sourceChange;
    if (change.edits.isEmpty) {
      return;
    }
    change.message = formatList(kind.message, args);
    fixes.add(Fix(kind, change));
  }

  // ignore: unused_element
  int _firstNonWhitespaceBefore(int offset) {
    while (offset > 0 && isWhitespace(content.codeUnitAt(offset - 1))) {
      offset--;
    }
    return offset;
  }

  // ignore: unused_element
  SourceRange _lines(int start, int end) {
    CharacterLocation startLocation = lineInfo.getLocation(start);
    var startOffset = lineInfo.getOffsetOfLine(startLocation.lineNumber - 1);
    CharacterLocation endLocation = lineInfo.getLocation(end);
    var endOffset = lineInfo.getOffsetOfLine(
        math.min(endLocation.lineNumber, lineInfo.lineCount - 1));
    return SourceRange(startOffset, endOffset - startOffset);
  }
}
