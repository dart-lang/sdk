// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'serialization.dart';

/// Visitor that ascribes an index to all [ir.TreeNode]s that potentially
/// needed for serialization and deserialization.
class _TreeNodeIndexerVisitor extends ir.Visitor<void> {
  int _currentIndex = 0;
  final Map<int, ir.TreeNode> _indexToNodeMap;
  final Map<ir.TreeNode, int> _nodeToIndexMap;

  _TreeNodeIndexerVisitor(this._indexToNodeMap, this._nodeToIndexMap);

  void registerNode(ir.TreeNode node) {
    _indexToNodeMap[_currentIndex] = node;
    _nodeToIndexMap[node] = _currentIndex;
    _currentIndex++;
  }

  @override
  void defaultTreeNode(ir.TreeNode node) {
    node.visitChildren(this);
  }

  @override
  void visitFunctionExpression(ir.FunctionExpression node) {
    registerNode(node);
    super.visitFunctionExpression(node);
  }

  @override
  void visitFunctionDeclaration(ir.FunctionDeclaration node) {
    registerNode(node);
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitBlock(ir.Block node) {
    registerNode(node);
    super.visitBlock(node);
  }

  @override
  void visitVariableDeclaration(ir.VariableDeclaration node) {
    if (node.parent is! ir.FunctionDeclaration) {
      registerNode(node);
    }
    super.visitVariableDeclaration(node);
  }

  @override
  void visitSwitchStatement(ir.SwitchStatement node) {
    registerNode(node);
    super.visitSwitchStatement(node);
  }

  @override
  void visitForStatement(ir.ForStatement node) {
    registerNode(node);
    super.visitForStatement(node);
  }

  @override
  void visitForInStatement(ir.ForInStatement node) {
    registerNode(node);
    super.visitForInStatement(node);
  }

  @override
  void visitWhileStatement(ir.WhileStatement node) {
    registerNode(node);
    super.visitWhileStatement(node);
  }

  @override
  void visitDoStatement(ir.DoStatement node) {
    registerNode(node);
    super.visitDoStatement(node);
  }

  @override
  void visitBreakStatement(ir.BreakStatement node) {
    registerNode(node);
    super.visitBreakStatement(node);
  }

  @override
  void visitListLiteral(ir.ListLiteral node) {
    registerNode(node);
    super.visitListLiteral(node);
  }

  @override
  void visitSetLiteral(ir.SetLiteral node) {
    registerNode(node);
    super.visitSetLiteral(node);
  }

  @override
  void visitMapLiteral(ir.MapLiteral node) {
    registerNode(node);
    super.visitMapLiteral(node);
  }

  @override
  void visitPropertyGet(ir.PropertyGet node) {
    registerNode(node);
    super.visitPropertyGet(node);
  }

  @override
  void visitPropertySet(ir.PropertySet node) {
    registerNode(node);
    super.visitPropertySet(node);
  }

  @override
  void visitMethodInvocation(ir.MethodInvocation node) {
    registerNode(node);
    super.visitMethodInvocation(node);
  }

  @override
  void visitStaticInvocation(ir.StaticInvocation node) {
    registerNode(node);
    super.visitStaticInvocation(node);
  }

  @override
  void visitLabeledStatement(ir.LabeledStatement node) {
    registerNode(node);
    super.visitLabeledStatement(node);
  }

  @override
  void visitSwitchCase(ir.SwitchCase node) {
    registerNode(node);
    super.visitSwitchCase(node);
  }

  @override
  void visitContinueSwitchStatement(ir.ContinueSwitchStatement node) {
    registerNode(node);
    super.visitContinueSwitchStatement(node);
  }

  @override
  void visitConstructorInvocation(ir.ConstructorInvocation node) {
    registerNode(node);
    super.visitConstructorInvocation(node);
  }

  @override
  void visitVariableGet(ir.VariableGet node) {
    registerNode(node);
    super.visitVariableGet(node);
  }

  @override
  void visitInstantiation(ir.Instantiation node) {
    registerNode(node);
    super.visitInstantiation(node);
  }

  @override
  void visitSuperMethodInvocation(ir.SuperMethodInvocation node) {
    registerNode(node);
    super.visitSuperMethodInvocation(node);
  }

  @override
  void visitSuperPropertyGet(ir.SuperPropertyGet node) {
    registerNode(node);
    super.visitSuperPropertyGet(node);
  }

  @override
  void visitConstantExpression(ir.ConstantExpression node) {
    registerNode(node);
    super.visitConstantExpression(node);
  }

  @override
  void visitNullCheck(ir.NullCheck node) {
    registerNode(node);
    super.visitNullCheck(node);
  }
}

/// Visitor that ascribes an index to all [ir.Constant]s that we potentially
/// need to reference for serialization and deserialization.
///
/// Currently this is only list, map, and set constants, which are used as
/// allocation identities in the global inference.
class _ConstantNodeIndexerVisitor implements ir.ConstantVisitor<void> {
  int _currentIndex = 0;
  final Map<int, ir.Constant> _indexToNodeMap = {};
  final Map<ir.Constant, int> _nodeToIndexMap = {};
  final Set<ir.Constant> _visitedNonindexedNodes = {};

  /// Returns `true` if node not already registered.
  bool _register(ir.Constant node) {
    int index = _nodeToIndexMap[node];
    if (index != null) return false;
    _indexToNodeMap[_currentIndex] = node;
    _nodeToIndexMap[node] = _currentIndex;
    _currentIndex++;
    return true;
  }

  int getIndex(ir.Constant node) {
    assert(_nodeToIndexMap.containsKey(node), "Constant without index: $node");
    return _nodeToIndexMap[node];
  }

  ir.Constant getConstant(int index) {
    assert(
        _indexToNodeMap.containsKey(index), "Index without constant: $index");
    return _indexToNodeMap[index];
  }

  @override
  void visitUnevaluatedConstant(ir.UnevaluatedConstant node) {}

  @override
  void visitTypeLiteralConstant(ir.TypeLiteralConstant node) {}

  @override
  void visitTearOffConstant(ir.TearOffConstant node) {}

  @override
  void visitPartialInstantiationConstant(ir.PartialInstantiationConstant node) {
    node.tearOffConstant.accept(this);
  }

  @override
  void visitInstanceConstant(ir.InstanceConstant node) {
    if (_visitedNonindexedNodes.add(node)) {
      node.fieldValues.forEach((_, ir.Constant value) {
        value.accept(this);
      });
    }
  }

  @override
  void visitSetConstant(ir.SetConstant node) {
    if (_register(node)) {
      for (ir.Constant element in node.entries) {
        element.accept(this);
      }
    }
  }

  @override
  void visitListConstant(ir.ListConstant node) {
    if (_register(node)) {
      for (ir.Constant element in node.entries) {
        element.accept(this);
      }
    }
  }

  @override
  void visitMapConstant(ir.MapConstant node) {
    if (_register(node)) {
      for (ir.ConstantMapEntry entry in node.entries) {
        entry.key.accept(this);
        entry.value.accept(this);
      }
    }
  }

  @override
  void visitSymbolConstant(ir.SymbolConstant node) {}

  @override
  void visitStringConstant(ir.StringConstant node) {}

  @override
  void visitDoubleConstant(ir.DoubleConstant node) {}

  @override
  void visitIntConstant(ir.IntConstant node) {}

  @override
  void visitBoolConstant(ir.BoolConstant node) {}

  @override
  void visitNullConstant(ir.NullConstant node) {}

  @override
  void defaultConstant(ir.Constant node) {
    throw new UnimplementedError(
        "Unexpected constant: $node (${node.runtimeType})");
  }
}
