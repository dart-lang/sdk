// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';

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
    var node = NodeLocator(_offset).searchWithin(_unit);
    if (node == null) {
      return [];
    }

    while (node != null && node != _unit) {
      _recordRange(node);
      node = node.parent;
    }

    return _selectionRanges;
  }

  /// Record the range for [node] if it is not the same as the last-recorded
  /// range.
  void _recordRange(AstNode node) {
    // Ignore this node if its range is the same as the last one.
    if (_selectionRanges.isNotEmpty) {
      final last = _selectionRanges.last;
      if (node.offset == last.offset && node.length == last.length) {
        return;
      }
    }

    _selectionRanges.add(SelectionRange(node.offset, node.length));
  }
}

class SelectionRange {
  final int offset;
  final int length;

  SelectionRange(this.offset, this.length);
}
