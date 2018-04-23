// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.bytecode.local_vars;

import 'dart:math' show max;

import 'package:kernel/ast.dart';
import 'package:vm/bytecode/dbc.dart';

class LocalVariables extends RecursiveVisitor<Null> {
  final Map<VariableDeclaration, int> _vars = <VariableDeclaration, int>{};
  final Map<TreeNode, int> _temps = <TreeNode, int>{};
  final List<int> _scopes = <int>[];
  int _localVars = 0;
  int _frameSize = 0;
  int _thisVarIndex;
  int _functionTypeArgsVarIndex;

  int get thisVarIndex =>
      _thisVarIndex ?? (throw '\'this\' variable is not allocated');

  int get functionTypeArgsVarIndex =>
      _functionTypeArgsVarIndex ??
      (throw '\'functionTypeArgs\' variable is not allocated');

  int get frameSize => _frameSize;

  int varIndex(VariableDeclaration variable) =>
      _vars[variable] ?? (throw '\'$variable\' variable is not allocated');

  int tempIndex(TreeNode node) =>
      _temps[node] ??
      (throw 'Temp is not allocated for node ${node.runtimeType} $node');

  int _allocateVar(VariableDeclaration node, {int index}) {
    if (index == null) {
      index = _localVars++;
    } else {
      assert(index < 0); // Should be a parameter.
    }
    _frameSize = max(_frameSize, _localVars);
    if (node != null) {
      assert(_vars[node] == null);
      _vars[node] = index;
    }
    return index;
  }

  // TODO(alexmarkov): allocate temporaries more efficiently.
  void _allocateTemp(TreeNode node) {
    _temps[node] = _allocateVar(null);
  }

  int _allocateParameter(VariableDeclaration node, int i, int paramNum) {
    assert(0 <= i && i < paramNum);
    int paramSlotIndex = -kParamEndSlotFromFp - paramNum + i;
    return _allocateVar(node, index: paramSlotIndex);
  }

  void _enterScope() {
    _scopes.add(_localVars);
  }

  void _leaveScope() {
    final int enclosingScopeLocalVars = _scopes.removeLast();
    assert(_localVars >= enclosingScopeLocalVars);
    _localVars = enclosingScopeLocalVars;
  }

  @override
  visitField(Field node) {
    if (node.initializer != null) {
      assert(_vars.isEmpty);
      assert(_localVars == 0);

      _enterScope();
      node.initializer.accept(this);
      _leaveScope();

      assert(_scopes.isEmpty);
    }
  }

  @override
  defaultMember(Member node) {
    assert(_vars.isEmpty);
    assert(_localVars == 0);

    final function = node.function;
    final bool hasTypeArgs = function.typeParameters.isNotEmpty;
    final bool hasReceiver =
        node is Constructor || ((node is Procedure) && !node.isStatic);
    final int numParams = function.positionalParameters.length +
        function.namedParameters.length +
        (hasTypeArgs ? 1 : 0) +
        (hasReceiver ? 1 : 0);
    int count = 0;

    if (hasTypeArgs) {
      _functionTypeArgsVarIndex = _allocateParameter(null, count++, numParams);
    }

    if (hasReceiver) {
      _thisVarIndex = _allocateParameter(null, count++, numParams);
    }

    for (var param in function.positionalParameters) {
      _allocateParameter(param, count++, numParams);
    }

    List<VariableDeclaration> namedParams = function.namedParameters;
    namedParams.sort((VariableDeclaration a, VariableDeclaration b) =>
        a.name.compareTo(b.name));
    for (var param in namedParams) {
      _allocateParameter(param, count++, numParams);
    }

    _enterScope();
    if (node is Constructor) {
      _enterScope();
      visitList(node.initializers, this);
      _leaveScope();
    }
    function.body?.accept(this);
    _leaveScope();

    assert(_scopes.isEmpty);
  }

  @override
  visitBlock(Block node) {
    _enterScope();
    node.visitChildren(this);
    _leaveScope();
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    _allocateVar(node);
    node.visitChildren(this);
  }

  @override
  visitLet(Let node) {
    _enterScope();
    node.variable.accept(this);
    node.body.accept(this);
    _leaveScope();
  }

  // -------------- Allocation of temporaries --------------

  @override
  visitConstructorInvocation(ConstructorInvocation node) {
    if (node.isConst) {
      return;
    }
    _allocateTemp(node);
    super.visitConstructorInvocation(node);
  }

  @override
  visitListLiteral(ListLiteral node) {
    if (node.isConst) {
      return;
    }
    _allocateTemp(node);
    super.visitListLiteral(node);
  }

  @override
  visitMapLiteral(MapLiteral node) {
    if (node.isConst) {
      return;
    }
    super.visitMapLiteral(node);
  }

  @override
  visitStringConcatenation(StringConcatenation node) {
    _allocateTemp(node);
    super.visitStringConcatenation(node);
  }

  @override
  visitConditionalExpression(ConditionalExpression node) {
    _allocateTemp(node);
    super.visitConditionalExpression(node);
  }

  @override
  visitLogicalExpression(LogicalExpression node) {
    _allocateTemp(node);
    super.visitLogicalExpression(node);
  }

  @override
  visitPropertySet(PropertySet node) {
    _allocateTemp(node);
    super.visitPropertySet(node);
  }
}
