// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';

/// Computes selection ranges for a specific offset of a Dart [CompilationUnit].
///
/// Select ranges support IDE functionality for "expand range" to increase the
/// selection based on the syntax node of the language.
class DartSelectionRangeComputer {
  final CompilationUnit _unit;
  final int _offset;
  final _selectionRanges = <SelectionRange>[];

  DartSelectionRangeComputer(this._unit, this._offset);

  /// Returns selection ranges for nodes containing [_offset], starting with the
  /// closest working up to the outer-most node.
  List<SelectionRange> compute() {
    var node = _unit.nodeCovering(offset: _offset);
    if (node == null) {
      return [];
    }

    while (node != null && node != _unit) {
      _recordRange(node);
      node = node.parent;
    }

    return _selectionRanges;
  }

  int? _formalParameterEndWithoutDefault(FormalParameter node) {
    if (node.functionTypedSuffix case var functionTypedSuffix?) {
      return functionTypedSuffix.end;
    }
    if (node.name case var name?) {
      return name.end;
    }
    if (node.type case var type?) {
      return type.end;
    }
    if (node.constFinalOrVarKeyword case var constFinalOrVarKeyword?) {
      return constFinalOrVarKeyword.end;
    }
    if (node.requiredKeyword case var requiredKeyword?) {
      return requiredKeyword.end;
    }
    if (node.covariantKeyword case var covariantKeyword?) {
      return covariantKeyword.end;
    }
    return null;
  }

  void _recordOffsetLength(int offset, int length) {
    // Ignore this node if its range is the same as the last one.
    if (_selectionRanges.isNotEmpty) {
      var last = _selectionRanges.last;
      if (offset == last.offset && length == last.length) {
        return;
      }
    }

    _selectionRanges.add(SelectionRange(offset, length));
  }

  /// Record the range for [node] if it is not the same as the last-recorded
  /// range.
  void _recordRange(AstNode node) {
    // Ignore certain kinds of nodes.
    if (node is NameWithTypeParameters) {
      return;
    }

    if (node case FormalParameter(
      defaultClause: var defaultClause?,
    ) when _offset < defaultClause.offset) {
      var end = _formalParameterEndWithoutDefault(node);
      if (end != null) {
        _recordOffsetLength(node.offset, end - node.offset);
      }
    }

    if (node is NamedArgument && _offset <= node.colon.end) {
      _recordOffsetLength(node.name.offset, node.name.length);
      _recordOffsetLength(node.name.offset, node.colon.end - node.name.offset);
    } else if (node is RecordLiteralNamedField && _offset <= node.colon.end) {
      _recordOffsetLength(node.name.offset, node.name.length);
      _recordOffsetLength(node.name.offset, node.colon.end - node.name.offset);
    }

    _recordOffsetLength(node.offset, node.length);
  }
}

class SelectionRange {
  final int offset;
  final int length;

  SelectionRange(this.offset, this.length);
}
