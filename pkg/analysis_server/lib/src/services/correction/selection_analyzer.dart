// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// A visitor for visiting [AstNode]s covered by a selection [SourceRange].
class SelectionAnalyzer extends GeneralizingAstVisitor<void> {
  final SourceRange selection;

  AstNode _coveringNode;
  List<AstNode> _selectedNodes;

  SelectionAnalyzer(this.selection);

  /// Return the [AstNode] with the shortest length which completely covers the
  /// specified selection.
  AstNode get coveringNode => _coveringNode;

  /// Returns the first selected [AstNode], may be `null`.
  AstNode get firstSelectedNode {
    if (_selectedNodes == null || _selectedNodes.isEmpty) {
      return null;
    }
    return _selectedNodes[0];
  }

  /// Returns `true` if there are [AstNode]s fully covered by the
  /// selection [SourceRange].
  bool get hasSelectedNodes =>
      _selectedNodes != null && _selectedNodes.isNotEmpty;

  /// Returns `true` if there was no selected nodes yet.
  bool get isFirstNode => _selectedNodes == null;

  /// Returns the last selected [AstNode], may be `null`.
  AstNode get lastSelectedNode {
    if (_selectedNodes == null || _selectedNodes.isEmpty) {
      return null;
    }
    return _selectedNodes[_selectedNodes.length - 1];
  }

  /// Return the [AstNode]s fully covered by the selection [SourceRange].
  List<AstNode> get selectedNodes {
    if (_selectedNodes == null || _selectedNodes.isEmpty) {
      return [];
    }
    return _selectedNodes;
  }

  /// Adds first selected [AstNode].
  void handleFirstSelectedNode(AstNode node) {
    _selectedNodes = [];
    _selectedNodes.add(node);
  }

  /// Adds second or more selected [AstNode].
  void handleNextSelectedNode(AstNode node) {
    if (firstSelectedNode.parent == node.parent) {
      _selectedNodes.add(node);
    }
  }

  /// Notifies that selection ends in given [AstNode].
  void handleSelectionEndsIn(AstNode node) {}

  /// Notifies that selection starts in given [AstNode].
  void handleSelectionStartsIn(AstNode node) {}

  /// Resets selected nodes.
  void reset() {
    _selectedNodes = null;
  }

  @override
  void visitNode(AstNode node) {
    var nodeRange = range.node(node);
    if (selection.covers(nodeRange)) {
      if (isFirstNode) {
        handleFirstSelectedNode(node);
      } else {
        handleNextSelectedNode(node);
      }
      return;
    } else if (selection.coveredBy(nodeRange)) {
      _coveringNode = node;
      node.visitChildren(this);
      return;
    } else if (selection.startsIn(nodeRange)) {
      handleSelectionStartsIn(node);
      node.visitChildren(this);
      return;
    } else if (selection.endsIn(nodeRange)) {
      handleSelectionEndsIn(node);
      node.visitChildren(this);
      return;
    }
    // no intersection
  }
}
