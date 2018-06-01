// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.bytecode.local_vars;

import 'dart:math' show max;

import 'package:kernel/ast.dart';
import 'package:kernel/transformations/continuation.dart'
    show ContinuationVariables;
import 'package:vm/bytecode/dbc.dart';

class LocalVariables {
  final Map<TreeNode, Scope> _scopes = <TreeNode, Scope>{};
  final Map<VariableDeclaration, VarDesc> _vars =
      <VariableDeclaration, VarDesc>{};
  final Map<TreeNode, List<int>> _temps = <TreeNode, List<int>>{};
  final Map<TreeNode, VariableDeclaration> _capturedSavedContextVars =
      <TreeNode, VariableDeclaration>{};
  final Map<TreeNode, VariableDeclaration> _capturedExceptionVars =
      <TreeNode, VariableDeclaration>{};
  final Map<TreeNode, VariableDeclaration> _capturedStackTraceVars =
      <TreeNode, VariableDeclaration>{};
  final Map<ForInStatement, VariableDeclaration> _capturedIteratorVars =
      <ForInStatement, VariableDeclaration>{};

  Scope _currentScope;
  Frame _currentFrame;

  VarDesc _getVarDesc(VariableDeclaration variable) =>
      _vars[variable] ??
      (throw 'Variable descriptor is not created for $variable');

  int _getVarIndex(VariableDeclaration variable, bool isCaptured) {
    final v = _getVarDesc(variable);
    if (v.isCaptured != isCaptured) {
      throw 'Mismatch in captured state of $variable';
    }
    return v.index ?? (throw 'Variable $variable is not allocated');
  }

  bool isCaptured(VariableDeclaration variable) =>
      _getVarDesc(variable).isCaptured;

  int getVarIndexInFrame(VariableDeclaration variable) =>
      _getVarIndex(variable, false);

  int getVarIndexInContext(VariableDeclaration variable) =>
      _getVarIndex(variable, true);

  int getOriginalParamSlotIndex(VariableDeclaration variable) =>
      _getVarDesc(variable).originalParamSlotIndex ??
      (throw 'Variablie $variable does not have originalParamSlotIndex');

  int tempIndexInFrame(TreeNode node, {int tempIndex: 0}) {
    final temps = _temps[node];
    if (temps == null) {
      throw 'Temp is not allocated for node ${node.runtimeType} $node';
    }
    return temps[tempIndex];
  }

  int get currentContextSize => _currentScope.contextSize;
  int get currentContextLevel => _currentScope.contextLevel;

  int get contextLevelAtEntry =>
      _currentFrame.contextLevelAtEntry ??
      (throw "Current frame is top level and it doesn't have a context at entry");

  int getContextLevelOfVar(VariableDeclaration variable) {
    final v = _getVarDesc(variable);
    assert(v.isCaptured);
    return v.scope.contextLevel;
  }

  int get closureVarIndexInFrame => getVarIndexInFrame(_currentFrame
          .closureVar ??
      (throw 'Closure variable is not declared in ${_currentFrame.function}'));

  int get contextVarIndexInFrame => getVarIndexInFrame(_currentFrame
          .contextVar ??
      (throw 'Context variable is not declared in ${_currentFrame.function}'));

  bool get hasContextVar => _currentFrame.contextVar != null;

  int get scratchVarIndexInFrame => getVarIndexInFrame(_currentFrame
          .scratchVar ??
      (throw 'Scratch variable is not declared in ${_currentFrame.function}'));

  int get typeArgsVarIndexInFrame => getVarIndexInFrame(_currentFrame
          .typeArgsVar ??
      (throw 'TypeArgs variable is not declared in ${_currentFrame.function}'));

  bool get hasTypeArgsVar => _currentFrame.typeArgsVar != null;

  VariableDeclaration get receiverVar =>
      _currentFrame.receiverVar ??
      (throw 'Receiver variable is not declared in ${_currentFrame.function}');

  bool get hasReceiver => _currentFrame.receiverVar != null;

  bool get isSyncYieldingFrame => _currentFrame.isSyncYielding;

  VariableDeclaration get awaitJumpVar {
    assert(_currentFrame.isSyncYielding);
    return _currentFrame.parent
        .getSyntheticVar(ContinuationVariables.awaitJumpVar);
  }

  VariableDeclaration get awaitContextVar {
    assert(_currentFrame.isSyncYielding);
    return _currentFrame.parent
        .getSyntheticVar(ContinuationVariables.awaitContextVar);
  }

  VariableDeclaration capturedSavedContextVar(TreeNode node) =>
      _capturedSavedContextVars[node];
  VariableDeclaration capturedExceptionVar(TreeNode node) =>
      _capturedExceptionVars[node];
  VariableDeclaration capturedStackTraceVar(TreeNode node) =>
      _capturedStackTraceVars[node];
  VariableDeclaration capturedIteratorVar(ForInStatement node) =>
      _capturedIteratorVars[node];

  int get asyncExceptionParamIndexInFrame {
    assert(_currentFrame.isSyncYielding);
    final function = (_currentFrame.function as FunctionDeclaration).function;
    final param = function.positionalParameters
        .firstWhere((p) => p.name == ContinuationVariables.exceptionParam);
    return getVarIndexInFrame(param);
  }

  int get asyncStackTraceParamIndexInFrame {
    assert(_currentFrame.isSyncYielding);
    final function = (_currentFrame.function as FunctionDeclaration).function;
    final param = function.positionalParameters
        .firstWhere((p) => p.name == ContinuationVariables.stackTraceParam);
    return getVarIndexInFrame(param);
  }

  int get frameSize => _currentFrame.frameSize;

  int get numParameters => _currentFrame.numParameters;

  int get numParentTypeArguments => _currentFrame.parent?.numTypeArguments ?? 0;

  bool get hasOptionalParameters => _currentFrame.hasOptionalParameters;
  bool get hasCapturedParameters => _currentFrame.hasCapturedParameters;

  LocalVariables(Member node) {
    final scopeBuilder = new _ScopeBuilder(this);
    node.accept(scopeBuilder);

    final allocator = new _Allocator(this);
    node.accept(allocator);
  }

  void enterScope(TreeNode node) {
    _currentScope = _scopes[node];
    _currentFrame = _currentScope.frame;
  }

  void leaveScope() {
    _currentScope = _currentScope.parent;
    _currentFrame = _currentScope?.frame;
  }
}

class VarDesc {
  final VariableDeclaration declaration;
  final Scope scope;
  bool isCaptured = false;
  int index;
  int originalParamSlotIndex;

  VarDesc(this.declaration, this.scope) {
    scope.vars.add(this);
  }

  Frame get frame => scope.frame;

  bool get isAllocated => index != null;

  void capture() {
    if (!isCaptured) {
      assert(!isAllocated);
      // TODO(alexmarkov): Consider sharing context between scopes.
      index = scope.contextSize++;
      isCaptured = true;
    }
  }
}

class Frame {
  final TreeNode function;
  final Frame parent;

  int numParameters = 0;
  int numTypeArguments = 0;
  bool hasOptionalParameters = false;
  bool hasCapturedParameters = false;
  bool hasClosures = false;
  bool isDartSync = true;
  bool isSyncYielding = false;
  VariableDeclaration receiverVar;
  VariableDeclaration typeArgsVar;
  VariableDeclaration closureVar;
  VariableDeclaration contextVar;
  VariableDeclaration scratchVar;
  Map<String, VariableDeclaration> syntheticVars;
  int frameSize = 0;
  List<int> temporaries = <int>[];
  int contextLevelAtEntry;

  Frame(this.function, this.parent);

  VariableDeclaration getSyntheticVar(String name) =>
      syntheticVars[name] ??
      (throw '${name} variable is not declared in ${function}');
}

class Scope {
  final Scope parent;
  final Frame frame;
  final List<VarDesc> vars = <VarDesc>[];

  int localsUsed;
  int tempsUsed;
  int contextSize = 0;
  int contextLevel;

  Scope(this.parent, this.frame);

  bool get hasContext => contextSize > 0;
}

class _ScopeBuilder extends RecursiveVisitor<Null> {
  final LocalVariables locals;

  Scope _currentScope;
  Frame _currentFrame;
  List<TreeNode> _enclosingTryBlocks;
  List<TreeNode> _enclosingTryCatches;

  _ScopeBuilder(this.locals);

  void _sortNamedParameters(FunctionNode function) {
    function.namedParameters.sort(
        (VariableDeclaration a, VariableDeclaration b) =>
            a.name.compareTo(b.name));
  }

  void _visitFunction(TreeNode node) {
    _enterFrame(node);

    final savedEnclosingTryBlocks = _enclosingTryBlocks;
    _enclosingTryBlocks = <TreeNode>[];
    final savedEnclosingTryCatches = _enclosingTryCatches;
    _enclosingTryCatches = <TreeNode>[];

    if (node is Field) {
      node.initializer.accept(this);
    } else {
      assert(node is Procedure ||
          node is Constructor ||
          node is FunctionDeclaration ||
          node is FunctionExpression);

      FunctionNode function = (node as dynamic).function;
      assert(function != null);

      _currentFrame.isDartSync = function.dartAsyncMarker == AsyncMarker.Sync;

      _currentFrame.isSyncYielding =
          function.asyncMarker == AsyncMarker.SyncYielding;

      _currentFrame.numTypeArguments =
          (_currentFrame.parent?.numTypeArguments ?? 0) +
              function.typeParameters.length;

      if (_currentFrame.numTypeArguments > 0) {
        _currentFrame.typeArgsVar =
            new VariableDeclaration(':function_type_arguments_var');
        _declareVariable(_currentFrame.typeArgsVar);
      }
      if (node is Constructor || (node is Procedure && !node.isStatic)) {
        _currentFrame.receiverVar = new VariableDeclaration('this');
        _declareVariable(_currentFrame.receiverVar);
      } else if (_currentFrame.parent?.receiverVar != null) {
        _currentFrame.receiverVar = _currentFrame.parent.receiverVar;
      }
      if (node is FunctionDeclaration || node is FunctionExpression) {
        _currentFrame.closureVar = new VariableDeclaration(':closure');
        _declareVariable(_currentFrame.closureVar);
      }

      _sortNamedParameters(function);

      visitList(function.positionalParameters, this);
      visitList(function.namedParameters, this);

      if (_currentFrame.isSyncYielding) {
        // The following variables from parent frame are used implicitly and need
        // to be captured to preserve state across closure invocations.
        _useVariable(_currentFrame.parent
            .getSyntheticVar(ContinuationVariables.awaitJumpVar));
        _useVariable(_currentFrame.parent
            .getSyntheticVar(ContinuationVariables.awaitContextVar));
      }

      if (node is Constructor) {
        for (var field in node.enclosingClass.fields) {
          if (!field.isStatic && field.initializer != null) {
            field.initializer.accept(this);
          }
        }
        visitList(node.initializers, this);
      }

      function.body?.accept(this);
    }

    if (node is FunctionDeclaration ||
        node is FunctionExpression ||
        _currentFrame.hasClosures) {
      _currentFrame.contextVar = new VariableDeclaration(':context');
      _declareVariable(_currentFrame.contextVar);
      _currentFrame.scratchVar = new VariableDeclaration(':scratch');
      _declareVariable(_currentFrame.scratchVar);
    }

    _enclosingTryBlocks = savedEnclosingTryBlocks;
    _enclosingTryCatches = savedEnclosingTryCatches;

    _leaveFrame();
  }

  _enterFrame(TreeNode node) {
    _currentFrame = new Frame(node, _currentFrame);
    _enterScope(node);
  }

  _leaveFrame() {
    _leaveScope();
    _currentFrame = _currentFrame.parent;
  }

  void _enterScope(TreeNode node) {
    _currentScope = new Scope(_currentScope, _currentFrame);
    assert(locals._scopes[node] == null);
    locals._scopes[node] = _currentScope;
  }

  void _leaveScope() {
    _currentScope = _currentScope.parent;
  }

  void _declareVariable(VariableDeclaration variable) {
    final VarDesc v = new VarDesc(variable, _currentScope);
    assert(locals._vars[variable] == null);
    locals._vars[variable] = v;
  }

  void _useVariable(VariableDeclaration variable) {
    assert(variable != null);
    final VarDesc v = locals._vars[variable];
    if (v == null) {
      throw 'Variable $variable is used before declared';
    }
    if (v.frame != _currentFrame) {
      v.capture();
    }
  }

  void _useThis() {
    assert(_currentFrame.receiverVar != null);
    _useVariable(_currentFrame.receiverVar);
  }

  void _captureAllVisibleVariablesInCurrentFrame() {
    assert(_currentFrame.isSyncYielding);
    final transient = new Set<VariableDeclaration>();
    transient
      ..addAll([
        _currentFrame.typeArgsVar,
        _currentFrame.closureVar,
        _currentFrame.contextVar,
        _currentFrame.scratchVar,
      ]);
    transient.addAll((_currentFrame.function as FunctionDeclaration)
        .function
        .positionalParameters);
    for (Scope scope = _currentScope;
        scope != null && scope.frame == _currentFrame;
        scope = scope.parent) {
      for (VarDesc v in scope.vars) {
        if (!transient.contains(v.declaration)) {
          v.capture();
        }
      }
    }
  }

  // Capture synthetic variables for control flow statements.
  void _captureSyntheticVariables() {
    int depth = 0;
    for (TreeNode tryBlock in _enclosingTryBlocks) {
      _captureSyntheticVariable(ContinuationVariables.savedTryContextVar(depth),
          tryBlock, locals._capturedSavedContextVars);
      ++depth;
    }
    depth = 0;
    for (TreeNode tryBlock in _enclosingTryCatches) {
      _captureSyntheticVariable(ContinuationVariables.exceptionVar(depth),
          tryBlock, locals._capturedExceptionVars);
      _captureSyntheticVariable(ContinuationVariables.stackTraceVar(depth),
          tryBlock, locals._capturedStackTraceVars);
      ++depth;
    }
  }

  void _captureSyntheticVariable(
      String name, TreeNode node, Map<TreeNode, VariableDeclaration> map) {
    final variable = _currentFrame.parent.getSyntheticVar(name);
    _useVariable(variable);
    assert(map[node] == null || map[node] == variable);
    map[node] = variable;
  }

  void _visitWithScope(TreeNode node) {
    _enterScope(node);
    node.visitChildren(this);
    _leaveScope();
  }

  @override
  defaultMember(Member node) {
    _visitFunction(node);
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    _currentFrame.hasClosures = true;
    node.variable.accept(this);
    _visitFunction(node);
  }

  @override
  visitFunctionExpression(FunctionExpression node) {
    _currentFrame.hasClosures = true;
    _visitFunction(node);
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    _declareVariable(node);

    if (!_currentFrame.isDartSync && node.name[0] == ':') {
      _currentFrame.syntheticVars ??= <String, VariableDeclaration>{};
      assert(_currentFrame.syntheticVars[node.name] == null);
      _currentFrame.syntheticVars[node.name] = node;
    }

    node.visitChildren(this);
  }

  @override
  visitVariableGet(VariableGet node) {
    _useVariable(node.variable);
  }

  @override
  visitVariableSet(VariableSet node) {
    _useVariable(node.variable);
    node.visitChildren(this);
  }

  @override
  visitThisExpression(ThisExpression node) {
    _useThis();
  }

  @override
  visitSuperMethodInvocation(SuperMethodInvocation node) {
    _useThis();
    node.visitChildren(this);
  }

  @override
  visitSuperPropertyGet(SuperPropertyGet node) {
    _useThis();
    node.visitChildren(this);
  }

  @override
  visitSuperPropertySet(SuperPropertySet node) {
    _useThis();
    node.visitChildren(this);
  }

  @override
  visitTypeParameterType(TypeParameterType node) {
    if (node.parameter.parent is Class) {
      _useThis();
    }
    node.visitChildren(this);
  }

  @override
  visitBlock(Block node) {
    _visitWithScope(node);
  }

  @override
  visitAssertBlock(AssertBlock node) {
    _visitWithScope(node);
  }

  @override
  visitForStatement(ForStatement node) {
    _visitWithScope(node);
  }

  @override
  visitForInStatement(ForInStatement node) {
    node.iterable.accept(this);

    VariableDeclaration iteratorVar;
    if (_currentFrame.isSyncYielding) {
      // Declare a variable to hold 'iterator' so it could be captured.
      iteratorVar = new VariableDeclaration(null);
      _declareVariable(iteratorVar);
      locals._capturedIteratorVars[node] = iteratorVar;
    }

    _enterScope(node);
    node.variable.accept(this);
    node.body.accept(this);
    _leaveScope();

    if (_currentFrame.isSyncYielding && !locals.isCaptured(iteratorVar)) {
      // Iterator variable was not captured, as there are no yield points
      // inside for-in statement body. The variable is needed only if captured,
      // so undeclare it.
      assert(_currentScope.vars.last == locals._vars[iteratorVar]);
      _currentScope.vars.removeLast();
      locals._vars.remove(iteratorVar);
      locals._capturedIteratorVars.remove(node);
    }
  }

  @override
  visitCatch(Catch node) {
    _visitWithScope(node);
  }

  @override
  visitLet(Let node) {
    _visitWithScope(node);
  }

  @override
  visitYieldStatement(YieldStatement node) {
    assert(_currentFrame.isSyncYielding);
    _captureAllVisibleVariablesInCurrentFrame();
    _captureSyntheticVariables();
    node.visitChildren(this);
  }

  @override
  visitTryCatch(TryCatch node) {
    _enclosingTryBlocks.add(node);
    node.body?.accept(this);
    _enclosingTryBlocks.removeLast();

    _enclosingTryCatches.add(node);
    visitList(node.catches, this);
    _enclosingTryCatches.removeLast();
  }

  @override
  visitTryFinally(TryFinally node) {
    _enclosingTryBlocks.add(node);
    node.body?.accept(this);
    _enclosingTryBlocks.removeLast();

    _enclosingTryCatches.add(node);
    node.finalizer?.accept(this);
    _enclosingTryCatches.removeLast();
  }
}

class _Allocator extends RecursiveVisitor<Null> {
  final LocalVariables locals;

  Scope _currentScope;
  Frame _currentFrame;
  int _contextLevel = 0;

  _Allocator(this.locals);

  void _enterScope(TreeNode node) {
    final scope = locals._scopes[node];
    assert(scope != null);
    assert(scope.parent == _currentScope);
    _currentScope = scope;

    if (_currentScope.frame != _currentFrame) {
      _currentFrame = _currentScope.frame;

      if (_currentScope.parent != null) {
        _currentFrame.contextLevelAtEntry = _currentScope.parent.contextLevel;
      }

      _currentScope.localsUsed = 0;
      _currentScope.tempsUsed = 0;
    } else {
      _currentScope.localsUsed = _currentScope.parent.localsUsed;
      _currentScope.tempsUsed = _currentScope.parent.tempsUsed;
    }

    if (_currentScope.parent == null || _currentScope.hasContext) {
      _currentScope.contextLevel = _contextLevel++;
    } else {
      _currentScope.contextLevel = _currentScope.parent.contextLevel;
    }
  }

  void _leaveScope() {
    if (_currentScope.hasContext) {
      --_contextLevel;
    }

    _currentScope = _currentScope.parent;
    _currentFrame = _currentScope?.frame;

    // Remove temporary variables which are out of scope.
    if (_currentScope != null) {
      int tempsToRetain = _currentFrame.temporaries.length;
      while (tempsToRetain > 0 &&
          _currentFrame.temporaries[tempsToRetain - 1] >=
              _currentScope.localsUsed) {
        --tempsToRetain;
      }
      assert(tempsToRetain >= _currentScope.tempsUsed);
      _currentFrame.temporaries.length = tempsToRetain;
      assert(_currentFrame.temporaries
          .every((index) => index < _currentScope.localsUsed));
    }
  }

  void _updateFrameSize() {
    _currentFrame.frameSize =
        max(_currentFrame.frameSize, _currentScope.localsUsed);
  }

  void _allocateTemp(TreeNode node, {int count: 1}) {
    assert(locals._temps[node] == null);
    if (_currentScope.tempsUsed + count > _currentFrame.temporaries.length) {
      // Allocate new local slots for temporary variables.
      final int newSlots =
          (_currentScope.tempsUsed + count) - _currentFrame.temporaries.length;
      int local = _currentScope.localsUsed;
      _currentScope.localsUsed += newSlots;
      _updateFrameSize();
      for (int i = 0; i < newSlots; i++) {
        _currentFrame.temporaries.add(local + i);
      }
    }
    locals._temps[node] = _currentFrame.temporaries
        .sublist(_currentScope.tempsUsed, _currentScope.tempsUsed + count);
    _currentScope.tempsUsed += count;
  }

  void _freeTemp(TreeNode node, {int count: 1}) {
    assert(_currentScope.tempsUsed >= count);
    _currentScope.tempsUsed -= count;
    assert(listEquals(
        locals._temps[node],
        _currentFrame.temporaries.sublist(
            _currentScope.tempsUsed, _currentScope.tempsUsed + count)));
  }

  void _allocateVariable(VariableDeclaration variable, {int paramSlotIndex}) {
    final VarDesc v = locals._getVarDesc(variable);
    if (v.isCaptured) {
      assert(v.isAllocated);
      v.originalParamSlotIndex = paramSlotIndex;
      return;
    }

    assert(!v.isAllocated);
    assert(v.scope == _currentScope);

    if (paramSlotIndex != null) {
      assert(paramSlotIndex < 0 ||
          (_currentFrame.hasOptionalParameters &&
              paramSlotIndex < _currentFrame.numParameters));
      v.index = paramSlotIndex;
    } else {
      v.index = _currentScope.localsUsed++;
    }
    _updateFrameSize();
  }

  void _ensureVariableAllocated(VariableDeclaration variable) {
    if (variable != null) {
      final VarDesc v = locals._getVarDesc(variable);
      if (!v.isAllocated) {
        _allocateVariable(variable);
      }
    }
  }

  void _allocateParameter(VariableDeclaration node, int i) {
    final numParameters = _currentFrame.numParameters;
    assert(0 <= i && i < numParameters);
    int paramSlotIndex = _currentFrame.hasOptionalParameters
        ? i
        : -kParamEndSlotFromFp - numParameters + i;
    _allocateVariable(node, paramSlotIndex: paramSlotIndex);
  }

  void _allocateParameters(TreeNode node, FunctionNode function) {
    final bool hasTypeArgs = function.typeParameters.isNotEmpty;
    final bool hasReceiver =
        node is Constructor || (node is Procedure && !node.isStatic);
    final bool hasClosureArg =
        node is FunctionDeclaration || node is FunctionExpression;

    _currentFrame.numParameters = function.positionalParameters.length +
        function.namedParameters.length +
        (hasTypeArgs ? 1 : 0) +
        (hasReceiver ? 1 : 0) +
        (hasClosureArg ? 1 : 0);

    _currentFrame.hasOptionalParameters = function.requiredParameterCount <
            function.positionalParameters.length ||
        function.namedParameters.isNotEmpty;

    _currentFrame.hasCapturedParameters =
        (hasReceiver && locals.isCaptured(_currentFrame.receiverVar)) ||
            function.positionalParameters.any(locals.isCaptured) ||
            function.namedParameters.any(locals.isCaptured);

    int count = 0;
    if (hasTypeArgs) {
      assert(!locals.isCaptured(_currentFrame.typeArgsVar));
      _allocateParameter(_currentFrame.typeArgsVar, count++);
    }
    if (hasReceiver) {
      _allocateParameter(_currentFrame.receiverVar, count++);
    }
    if (hasClosureArg) {
      assert(!locals.isCaptured(_currentFrame.closureVar));
      _allocateParameter(_currentFrame.closureVar, count++);
    }
    for (var param in function.positionalParameters) {
      _allocateParameter(param, count++);
    }
    for (var param in function.namedParameters) {
      _allocateParameter(param, count++);
    }
    assert(count == _currentFrame.numParameters);

    if (_currentFrame.hasOptionalParameters) {
      _currentScope.localsUsed = _currentFrame.numParameters;
      _updateFrameSize();
    }
  }

  void _allocateSpecialVariables() {
    _ensureVariableAllocated(_currentFrame.typeArgsVar);
    _ensureVariableAllocated(_currentFrame.contextVar);
    _ensureVariableAllocated(_currentFrame.scratchVar);
  }

  void _visitFunction(TreeNode node) {
    _enterScope(node);

    if (node is Field) {
      _allocateSpecialVariables();
      node.initializer.accept(this);
    } else {
      assert(node is Procedure ||
          node is Constructor ||
          node is FunctionDeclaration ||
          node is FunctionExpression);

      final FunctionNode function = (node as dynamic).function;
      assert(function != null);

      _allocateParameters(node, function);
      _allocateSpecialVariables();

      if (node is Constructor) {
        for (var field in node.enclosingClass.fields) {
          if (!field.isStatic && field.initializer != null) {
            field.initializer.accept(this);
          }
        }
        visitList(node.initializers, this);
      }

      function.body?.accept(this);
    }

    _leaveScope();
  }

  void _visit(TreeNode node, {bool scope: false, int temps: 0}) {
    if (scope) {
      _enterScope(node);
    }
    if (temps > 0) {
      _allocateTemp(node, count: temps);
    }

    node.visitChildren(this);

    if (temps > 0) {
      _freeTemp(node, count: temps);
    }
    if (scope) {
      _leaveScope();
    }
  }

  @override
  defaultMember(Member node) {
    _visitFunction(node);
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    _allocateVariable(node.variable);
    _allocateTemp(node);
    _visitFunction(node);
    _freeTemp(node);
  }

  @override
  visitFunctionExpression(FunctionExpression node) {
    _allocateTemp(node);
    _visitFunction(node);
    _freeTemp(node);
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    _allocateVariable(node);
    node.visitChildren(this);
  }

  @override
  visitBlock(Block node) {
    _visit(node, scope: true);
  }

  @override
  visitAssertBlock(AssertBlock node) {
    _visit(node, scope: true);
  }

  @override
  visitForStatement(ForStatement node) {
    _visit(node, scope: true);
  }

  @override
  visitForInStatement(ForInStatement node) {
    _allocateTemp(node);

    node.iterable.accept(this);

    _enterScope(node);
    node.variable.accept(this);
    node.body.accept(this);
    _leaveScope();

    _freeTemp(node);
  }

  @override
  visitCatch(Catch node) {
    _visit(node, scope: true);
  }

  @override
  visitLet(Let node) {
    _visit(node, scope: true);
  }

  // -------------- Allocation of temporaries --------------

  @override
  visitConstructorInvocation(ConstructorInvocation node) {
    if (node.isConst) {
      return;
    }
    _visit(node, temps: 1);
  }

  @override
  visitListLiteral(ListLiteral node) {
    if (node.isConst) {
      return;
    }
    _visit(node, temps: 1);
  }

  @override
  visitMapLiteral(MapLiteral node) {
    if (node.isConst) {
      return;
    }
    _visit(node, temps: 1);
  }

  @override
  visitStringConcatenation(StringConcatenation node) {
    _visit(node, temps: 1);
  }

  @override
  visitConditionalExpression(ConditionalExpression node) {
    _visit(node, temps: 1);
  }

  @override
  visitLogicalExpression(LogicalExpression node) {
    _visit(node, temps: 1);
  }

  @override
  visitPropertySet(PropertySet node) {
    _visit(node, temps: 1);
  }

  @override
  visitSwitchStatement(SwitchStatement node) {
    _visit(node, temps: 1);
  }

  @override
  visitVariableSet(VariableSet node) {
    _visit(node, temps: locals.isCaptured(node.variable) ? 1 : 0);
  }

  @override
  visitStaticSet(StaticSet node) {
    _allocateTemp(node);
    super.visitStaticSet(node);
  }

  @override
  visitTryCatch(TryCatch node) {
    _visit(node, temps: 2);
  }

  @override
  visitTryFinally(TryFinally node) {
    _visit(node, temps: 2);
  }
}
