// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' show min, max;

import 'package:kernel/ast.dart';
import 'package:kernel/type_environment.dart';

import 'dbc.dart';
import 'options.dart' show BytecodeOptions;

class LocalVariables {
  final _scopes = new Map<TreeNode, Scope>();
  final _vars = new Map<VariableDeclaration, VarDesc>();
  Map<TreeNode, List<int>>? _temps;
  Map<TreeNode, VariableDeclaration>? _capturedSavedContextVars;
  Map<TreeNode, VariableDeclaration>? _capturedExceptionVars;
  Map<TreeNode, VariableDeclaration>? _capturedStackTraceVars;
  Map<ForInStatement, VariableDeclaration>? _capturedIteratorVars;
  final BytecodeOptions options;
  final StaticTypeContext staticTypeContext;

  Scope? _currentScopeInternal;
  Scope get _currentScope => _currentScopeInternal!;

  Frame? _currentFrameInternal;
  Frame get _currentFrame => _currentFrameInternal!;

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
      (throw 'Variable $variable does not have originalParamSlotIndex');

  int getParamIndexInFrame(VariableDeclaration variable) => isCaptured(variable)
      ? getOriginalParamSlotIndex(variable)
      : getVarIndexInFrame(variable);

  int tempIndexInFrame(TreeNode node, {int tempIndex = 0}) {
    final temps = _temps![node];
    if (temps == null) {
      throw 'Temp is not allocated for node ${node.runtimeType} $node';
    }
    return temps[tempIndex];
  }

  int get currentContextSize => _currentScope.contextSize;
  int get currentContextLevel => _currentScope.contextLevel!;
  int get currentContextId => _currentScope.contextId!;

  int get contextLevelAtEntry =>
      _currentFrame.contextLevelAtEntry ??
      (throw "Current frame is top level and it doesn't have a context at entry");

  int getContextLevelOfVar(VariableDeclaration variable) {
    final v = _getVarDesc(variable);
    assert(v.isCaptured);
    return v.scope.contextLevel!;
  }

  int getVarContextId(VariableDeclaration variable) {
    final v = _getVarDesc(variable);
    assert(v.isCaptured);
    return v.scope.contextId!;
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

  int get returnVarIndexInFrame => getVarIndexInFrame(_currentFrame.returnVar ??
      (throw 'Return variable is not declared in ${_currentFrame.function}'));

  int get suspendStateVarIndexInFrame => getVarIndexInFrame(_currentFrame
          .suspendStateVar ??
      (throw 'Suspend state variable is not declared in ${_currentFrame.function}'));

  VariableDeclaration get functionTypeArgsVar =>
      _currentFrame.functionTypeArgsVar ??
      (throw 'FunctionTypeArgs variable is not declared in ${_currentFrame.function}');

  int get functionTypeArgsVarIndexInFrame =>
      getVarIndexInFrame(functionTypeArgsVar);

  bool get hasFunctionTypeArgsVar => _currentFrame.functionTypeArgsVar != null;

  VariableDeclaration get factoryTypeArgsVar =>
      _currentFrame.factoryTypeArgsVar ??
      (throw 'FactoryTypeArgs variable is not declared in ${_currentFrame.function}');

  bool get hasFactoryTypeArgsVar => _currentFrame.factoryTypeArgsVar != null;

  VariableDeclaration get receiverVar =>
      _currentFrame.receiverVar ??
      (throw 'Receiver variable is not declared in ${_currentFrame.function}');

  bool get hasCapturedReceiverVar => _currentFrame.capturedReceiverVar != null;

  VariableDeclaration get capturedReceiverVar =>
      _currentFrame.capturedReceiverVar ??
      (throw 'Captured receiver variable is not declared in ${_currentFrame.function}');

  bool get hasReceiver => _currentFrame.receiverVar != null;

  VariableDeclaration? capturedSavedContextVar(TreeNode node) =>
      _capturedSavedContextVars?[node];
  VariableDeclaration? capturedExceptionVar(TreeNode node) =>
      _capturedExceptionVars?[node];
  VariableDeclaration? capturedStackTraceVar(TreeNode node) =>
      _capturedStackTraceVars?[node];
  VariableDeclaration? capturedIteratorVar(ForInStatement node) =>
      _capturedIteratorVars?[node];

  int get frameSize => _currentFrame.frameSize;

  int get numParameters => _currentFrame.numParameters;

  int get numParentTypeArguments => _currentFrame.parent?.numTypeArguments ?? 0;

  bool get hasOptionalParameters => _currentFrame.hasOptionalParameters;
  bool get hasCapturedParameters => _currentFrame.hasCapturedParameters;
  bool get isSuspendableFunction => _currentFrame.isSuspendableFunction;
  bool get makesCopyOfParameters => _currentFrame.makesCopyOfParameters;

  List<VariableDeclaration> get originalNamedParameters =>
      _currentFrame.originalNamedParameters;
  List<VariableDeclaration> get sortedNamedParameters =>
      _currentFrame.sortedNamedParameters;

  LocalVariables(Member node, this.options, this.staticTypeContext) {
    final scopeBuilder = new _ScopeBuilder(this);
    node.accept(scopeBuilder);

    final allocator = new _Allocator(this);
    node.accept(allocator);
  }

  void enterScope(TreeNode node) {
    _currentScopeInternal = _scopes[node];
    _currentFrameInternal = _currentScope.frame;
  }

  void leaveScope() {
    _currentScopeInternal = _currentScope.parent;
    _currentFrameInternal = _currentScopeInternal?.frame;
  }

  void withTemp(TreeNode node, int temp, void action()) {
    final old = _temps![node];
    assert(old == null || old.length == 1);
    _temps![node] = [temp];
    action();
    if (old == null) {
      _temps!.remove(node);
    } else {
      _temps![node] = old;
    }
  }
}

class VarDesc {
  final VariableDeclaration declaration;
  Scope scope;
  bool isCaptured = false;
  int? index;
  int? originalParamSlotIndex;

  VarDesc(this.declaration, this.scope) {
    scope.vars.add(this);
  }

  Frame get frame => scope.frame;

  bool get isAllocated => index != null;

  void capture() {
    assert(!isAllocated);
    isCaptured = true;
  }

  void moveToScope(Scope newScope) {
    assert(index == null);
    scope.vars.remove(this);
    newScope.vars.add(this);
    scope = newScope;
  }

  String toString() => 'var ${declaration.name}';
}

class Frame {
  final TreeNode function;
  final Frame? parent;
  late Scope topScope;

  late List<VariableDeclaration> originalNamedParameters;
  late List<VariableDeclaration> sortedNamedParameters;
  int numParameters = 0;
  int numTypeArguments = 0;
  bool hasOptionalParameters = false;
  bool hasCapturedParameters = false;
  bool hasClosures = false;
  VariableDeclaration? receiverVar;
  VariableDeclaration? capturedReceiverVar;
  VariableDeclaration? functionTypeArgsVar;
  VariableDeclaration? factoryTypeArgsVar;
  VariableDeclaration? closureVar;
  VariableDeclaration? contextVar;
  VariableDeclaration? scratchVar;
  VariableDeclaration? returnVar;
  VariableDeclaration? suspendStateVar;
  Map<String, VariableDeclaration>? syntheticVars;
  int frameSize = 0;
  List<int> temporaries = <int>[];
  int? contextLevelAtEntry;

  Frame(this.function, this.parent);

  VariableDeclaration getSyntheticVar(String name) {
    final syntheticVars = this.syntheticVars;
    if (syntheticVars == null) {
      throw 'No synthetic variables declared in ${function}!';
    }
    final v = syntheticVars[name];
    if (v == null) {
      throw '${name} variable is not declared in ${function}';
    }
    return v;
  }

  bool get isSuspendableFunction => suspendStateVar != null;
  bool get makesCopyOfParameters =>
      hasOptionalParameters || isSuspendableFunction;
}

class Scope {
  final Scope? parent;
  final Frame frame;
  final int loopDepth;
  final List<VarDesc> vars = <VarDesc>[];

  int localsUsed = 0;
  int tempsUsed = 0;

  Scope? contextOwner;
  int contextUsed = 0;
  int contextSize = 0;
  int? contextLevel;
  int? contextId;

  Scope(this.parent, this.frame, this.loopDepth);

  bool get hasContext => contextSize > 0;
}

bool _hasReceiverParameter(TreeNode node) {
  return node is Constructor ||
      (node is Procedure && !node.isStatic) ||
      (node is Field && !node.isStatic);
}

class _ScopeBuilder extends RecursiveVisitor {
  final LocalVariables locals;

  Scope? _currentScopeInternal;
  Scope get _currentScope => _currentScopeInternal!;

  Frame? _currentFrameInternal;
  Frame get _currentFrame => _currentFrameInternal!;

  List<TreeNode> _enclosingTryBlocks = const [];
  List<TreeNode> _enclosingTryCatches = const [];
  int _loopDepth = 0;

  _ScopeBuilder(this.locals);

  List<VariableDeclaration> _sortNamedParameters(FunctionNode function) {
    final params = function.namedParameters.toList();
    params.sort((VariableDeclaration a, VariableDeclaration b) =>
        a.name!.compareTo(b.name!));
    return params;
  }

  void _visitFunction(TreeNode node) {
    final savedEnclosingTryBlocks = _enclosingTryBlocks;
    _enclosingTryBlocks = <TreeNode>[];
    final savedEnclosingTryCatches = _enclosingTryCatches;
    _enclosingTryCatches = <TreeNode>[];
    final saveLoopDepth = _loopDepth;
    _loopDepth = 0;

    _enterFrame(node);

    if (node is Field) {
      if (_hasReceiverParameter(node)) {
        final receiverVar =
            _currentFrame.receiverVar = VariableDeclaration('this');
        _declareVariable(receiverVar);
      }
      node.initializer?.accept(this);
    } else {
      assert(node is Procedure ||
          node is Constructor ||
          node is FunctionDeclaration ||
          node is FunctionExpression);

      FunctionNode function = (node as dynamic).function;

      if (function.dartAsyncMarker != AsyncMarker.Sync) {
        final suspendStateVar = _currentFrame.suspendStateVar =
            VariableDeclaration(':suspend_state');
        _declareVariable(suspendStateVar);
      }

      if (node is Procedure && node.isFactory) {
        assert(_currentFrame.parent == null);
        _currentFrame.numTypeArguments = 0;
        final factoryTypeArgsVar = _currentFrame.factoryTypeArgsVar =
            VariableDeclaration(':type_arguments');
        _declareVariable(factoryTypeArgsVar);
      } else {
        _currentFrame.numTypeArguments =
            (_currentFrame.parent?.numTypeArguments ?? 0) +
                function.typeParameters.length;

        if (_currentFrame.numTypeArguments > 0) {
          final functionTypeArgsVar = _currentFrame.functionTypeArgsVar =
              VariableDeclaration(':function_type_arguments_var')
                ..fileOffset = function.fileOffset;
          _declareVariable(functionTypeArgsVar);
        }

        final parentFactoryTypeArgsVar =
            _currentFrame.parent?.factoryTypeArgsVar;
        if (parentFactoryTypeArgsVar != null) {
          _currentFrame.factoryTypeArgsVar = parentFactoryTypeArgsVar;
        }
      }

      if (_hasReceiverParameter(node)) {
        final receiverVar =
            _currentFrame.receiverVar = VariableDeclaration('this');
        _declareVariable(receiverVar);
      } else {
        final parentReceiverVar = _currentFrame.parent?.receiverVar;
        if (parentReceiverVar != null) {
          _currentFrame.receiverVar = parentReceiverVar;
        }
      }
      if (node is FunctionDeclaration || node is FunctionExpression) {
        final closureVar =
            _currentFrame.closureVar = VariableDeclaration(':closure');
        _declareVariable(closureVar);
      }

      _currentFrame.originalNamedParameters = function.namedParameters;
      _currentFrame.sortedNamedParameters = _sortNamedParameters(function);

      visitList(function.positionalParameters, this);
      visitList(_currentFrame.sortedNamedParameters, this);
      function.emittedValueType?.accept(this);

      if (node is Constructor) {
        for (var field in node.enclosingClass.fields) {
          if (!field.isStatic && field.initializer != null) {
            field.initializer!.accept(this);
          }
        }
        visitList(node.initializers, this);
      }

      function.body?.accept(this);
    }

    if (node is FunctionDeclaration ||
        node is FunctionExpression ||
        _currentFrame.hasClosures) {
      final contextVar =
          _currentFrame.contextVar = VariableDeclaration(':context');
      _declareVariable(contextVar);
      final scratchVar =
          _currentFrame.scratchVar = VariableDeclaration(':scratch');
      _declareVariable(scratchVar);
    }

    if (_hasReceiverParameter(node)) {
      if (locals.isCaptured(_currentFrame.receiverVar!)) {
        // Duplicate receiver variable for local use.
        _currentFrame.capturedReceiverVar = _currentFrame.receiverVar;
        final localReceiverVar =
            _currentFrame.receiverVar = VariableDeclaration('this');
        _declareVariable(localReceiverVar);
      }
    }

    _leaveFrame();

    _enclosingTryBlocks = savedEnclosingTryBlocks;
    _enclosingTryCatches = savedEnclosingTryCatches;
    _loopDepth = saveLoopDepth;
  }

  _enterFrame(TreeNode node) {
    _currentFrameInternal = new Frame(node, _currentFrameInternal);
    _enterScope(node);
    _currentFrame.topScope = _currentScope;
  }

  _leaveFrame() {
    _leaveScope();
    _currentFrameInternal = _currentFrame.parent;
  }

  void _enterScope(TreeNode node) {
    _currentScopeInternal =
        new Scope(_currentScopeInternal, _currentFrame, _loopDepth);
    assert(locals._scopes[node] == null);
    locals._scopes[node] = _currentScope;
  }

  void _leaveScope() {
    _currentScopeInternal = _currentScope.parent;
  }

  void _declareVariable(VariableDeclaration variable, [Scope? scope]) {
    if (scope == null) {
      scope = _currentScope;
    }
    final VarDesc v = new VarDesc(variable, scope);
    assert(locals._vars[variable] == null,
        'Double declaring variable ${variable}!');
    locals._vars[variable] = v;
  }

  void _useVariable(VariableDeclaration variable) {
    final VarDesc? v = locals._vars[variable];
    if (v == null) {
      throw 'Variable $variable is used before declared';
    }
    if (v.frame != _currentFrame) {
      v.capture();
    }
  }

  void _useThis() {
    _useVariable(_currentFrame.receiverVar!);
  }

  void _visitWithScope(TreeNode node) {
    _enterScope(node);
    node.visitChildren(this);
    _leaveScope();
  }

  @override
  void defaultMember(Member node) {
    _visitFunction(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _currentFrame.hasClosures = true;
    if (_currentFrame.receiverVar != null) {
      // Closure creation may load receiver to get instantiator type arguments.
      _useThis();
    }
    node.variable.accept(this);
    _visitFunction(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    _currentFrame.hasClosures = true;
    if (_currentFrame.receiverVar != null) {
      // Closure creation may load receiver to get instantiator type arguments.
      _useThis();
    }
    _visitFunction(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    _declareVariable(node);
    node.visitChildren(this);
  }

  @override
  void visitVariableGet(VariableGet node) {
    _useVariable(node.variable);
    if (node.variable.isLate) {
      node.variable.initializer?.accept(this);
    }
  }

  @override
  void visitVariableSet(VariableSet node) {
    _useVariable(node.variable);
    node.visitChildren(this);
  }

  @override
  void visitThisExpression(ThisExpression node) {
    _useThis();
  }

  @override
  void visitSuperMethodInvocation(SuperMethodInvocation node) {
    _useThis();
    node.visitChildren(this);
  }

  @override
  void visitSuperPropertyGet(SuperPropertyGet node) {
    _useThis();
    node.visitChildren(this);
  }

  @override
  void visitSuperPropertySet(SuperPropertySet node) {
    _useThis();
    node.visitChildren(this);
  }

  @override
  void visitTypeParameterType(TypeParameterType node) {
    var parent = node.parameter.declaration;
    if (parent is Class) {
      _useThis();
    } else if (parent is Procedure && parent.isFactory) {
      _useVariable(_currentFrame.factoryTypeArgsVar!);
    }
    node.visitChildren(this);
  }

  @override
  void visitBlock(Block node) {
    _visitWithScope(node);
  }

  @override
  void visitBlockExpression(BlockExpression node) {
    // Not using _visitWithScope as Block inside BlockExpression does not have
    // a scope.
    _enterScope(node);
    visitList(node.body.statements, this);
    node.value.accept(this);
    _leaveScope();
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    if (!locals.options.enableAsserts) {
      return;
    }
    super.visitAssertStatement(node);
  }

  @override
  void visitAssertBlock(AssertBlock node) {
    if (!locals.options.enableAsserts) {
      return;
    }
    _visitWithScope(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    ++_loopDepth;
    _visitWithScope(node);
    --_loopDepth;
  }

  @override
  void visitForInStatement(ForInStatement node) {
    node.iterable.accept(this);
    ++_loopDepth;
    _enterScope(node);
    node.variable.accept(this);
    node.body.accept(this);
    _leaveScope();
    --_loopDepth;
  }

  @override
  void visitCatch(Catch node) {
    _visitWithScope(node);
  }

  @override
  void visitLet(Let node) {
    _visitWithScope(node);
  }

  @override
  void visitTryCatch(TryCatch node) {
    _enclosingTryBlocks.add(node);
    node.body.accept(this);
    _enclosingTryBlocks.removeLast();

    _enclosingTryCatches.add(node);
    visitList(node.catches, this);
    _enclosingTryCatches.removeLast();
  }

  @override
  void visitTryFinally(TryFinally node) {
    _enclosingTryBlocks.add(node);
    node.body.accept(this);
    _enclosingTryBlocks.removeLast();

    _enclosingTryCatches.add(node);
    node.finalizer.accept(this);
    _enclosingTryCatches.removeLast();
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    // If returning from within a try-finally block, need to allocate
    // an extra variable to hold a return value.
    // Return value can't be kept on the stack as try-catch statements
    // inside finally can zap expression stack.
    // Literals (including implicit 'null' in 'return;') do not require
    // an extra variable as they can be generated after all finally blocks.
    if (_enclosingTryBlocks.isNotEmpty &&
        (node.expression != null && node.expression is! BasicLiteral)) {
      final returnVar =
          _currentFrame.returnVar = VariableDeclaration(':return');
      _declareVariable(returnVar, _currentFrame.topScope);
    }
    node.visitChildren(this);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    ++_loopDepth;
    node.visitChildren(this);
    --_loopDepth;
  }

  @override
  void visitDoStatement(DoStatement node) {
    ++_loopDepth;
    node.visitChildren(this);
    --_loopDepth;
  }
}

// Allocate context slots for each local variable.
class _Allocator extends RecursiveVisitor {
  final LocalVariables locals;

  Scope? _currentScopeInternal;
  Scope get _currentScope => _currentScopeInternal!;

  Frame? _currentFrameInternal;
  Frame get _currentFrame => _currentFrameInternal!;

  int _contextIdCounter = 0;

  _Allocator(this.locals);

  void _enterScope(TreeNode node) {
    final scope = locals._scopes[node];
    assert(scope!.parent == _currentScopeInternal);
    _currentScopeInternal = scope;
    final parentScope = _currentScope.parent;

    if (_currentScope.frame != _currentFrameInternal) {
      _currentFrameInternal = _currentScope.frame;

      if (parentScope != null) {
        _currentFrame.contextLevelAtEntry = parentScope.contextLevel;
      }

      _currentScope.localsUsed = 0;
      _currentScope.tempsUsed = 0;
    } else {
      _currentScope.localsUsed = parentScope!.localsUsed;
      _currentScope.tempsUsed = parentScope.tempsUsed;
    }

    assert(_currentScope.contextOwner == null);
    assert(_currentScope.contextLevel == null);
    assert(_currentScope.contextId == null);

    final int parentContextLevel =
        parentScope != null ? parentScope.contextLevel! : -1;

    final int numCaptured =
        _currentScope.vars.where((v) => v.isCaptured).length;
    if (numCaptured > 0) {
      // Share contexts between scopes which belong to the same frame and
      // have the same loop depth.
      _currentScope.contextOwner = _currentScope;
      for (Scope? contextOwner = _currentScope;
          contextOwner != null &&
              contextOwner.frame == _currentScope.frame &&
              contextOwner.loopDepth == _currentScope.loopDepth;
          contextOwner = contextOwner.parent) {
        if (contextOwner.hasContext) {
          _currentScope.contextOwner = contextOwner;
          break;
        }
      }

      final contextOwner = _currentScope.contextOwner!;
      contextOwner.contextSize += numCaptured;

      if (contextOwner == _currentScope) {
        _currentScope.contextLevel = parentContextLevel + 1;
        int saturatedContextId = min(_contextIdCounter++, contextIdLimit - 1);
        _currentScope.contextId = saturatedContextId;
      } else {
        _currentScope.contextLevel = contextOwner.contextLevel;
        _currentScope.contextId = contextOwner.contextId;
      }
    } else {
      _currentScope.contextLevel = parentContextLevel;
    }
  }

  void _leaveScope() {
    assert(_currentScope.contextUsed == _currentScope.contextSize);

    _currentScopeInternal = _currentScope.parent;
    _currentFrameInternal = _currentScopeInternal?.frame;

    // Remove temporary variables which are out of scope.
    if (_currentScopeInternal != null) {
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

  void _allocateTemp(TreeNode node, {int count = 1}) {
    locals._temps ??= new Map<TreeNode, List<int>>();
    assert(locals._temps![node] == null);
    if (_currentScope.tempsUsed + count > _currentFrame.temporaries.length) {
      // Allocate new local slots for temporary variables.
      final int newSlots =
          (_currentScope.tempsUsed + count) - _currentFrame.temporaries.length;
      int local = _currentScope.localsUsed;
      _currentScope.localsUsed += newSlots;
      if (_currentScope.localsUsed > localVariableIndexLimit) {
        throw new LocalVariableIndexOverflowException();
      }
      _updateFrameSize();
      for (int i = 0; i < newSlots; i++) {
        _currentFrame.temporaries.add(local + i);
      }
    }
    locals._temps![node] = _currentFrame.temporaries
        .sublist(_currentScope.tempsUsed, _currentScope.tempsUsed + count);
    _currentScope.tempsUsed += count;
  }

  void _freeTemp(TreeNode node, {int count = 1}) {
    assert(_currentScope.tempsUsed >= count);
    _currentScope.tempsUsed -= count;
    assert(listEquals(
        locals._temps![node]!,
        _currentFrame.temporaries.sublist(
            _currentScope.tempsUsed, _currentScope.tempsUsed + count)));
  }

  void _allocateVariable(VariableDeclaration variable, {int? paramSlotIndex}) {
    final VarDesc v = locals._getVarDesc(variable);

    assert(!v.isAllocated);
    assert(v.scope == _currentScope);

    if (v.isCaptured) {
      final index = v.index = _currentScope.contextOwner!.contextUsed++;
      if (index >= capturedVariableIndexLimit) {
        throw new LocalVariableIndexOverflowException();
      }
      v.originalParamSlotIndex = paramSlotIndex;
      return;
    }

    if (paramSlotIndex != null) {
      assert(paramSlotIndex < 0 ||
          (_currentFrame.makesCopyOfParameters &&
              paramSlotIndex <
                  _currentScope.localsUsed + _currentFrame.numParameters));
      v.index = paramSlotIndex;
    } else {
      final index = v.index = _currentScope.localsUsed++;
      if (index >= localVariableIndexLimit) {
        throw new LocalVariableIndexOverflowException();
      }
    }
    _updateFrameSize();
  }

  void _ensureVariableAllocated(VariableDeclaration? variable) {
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
    assert(_currentScope.localsUsed ==
        (_currentFrame.isSuspendableFunction ? 1 : 0));
    int paramSlotIndex = _currentFrame.makesCopyOfParameters
        ? _currentScope.localsUsed + i
        : -kParamEndSlotFromFp - numParameters + i;
    _allocateVariable(node, paramSlotIndex: paramSlotIndex);
  }

  void _allocateParameters(TreeNode node, FunctionNode function) {
    final bool isFactory = node is Procedure && node.isFactory;
    final bool hasReceiver = _hasReceiverParameter(node);
    final bool hasClosureArg =
        node is FunctionDeclaration || node is FunctionExpression;

    _currentFrame.numParameters = function.positionalParameters.length +
        function.namedParameters.length +
        (isFactory ? 1 : 0) +
        (hasReceiver ? 1 : 0) +
        (hasClosureArg ? 1 : 0);

    _currentFrame.hasOptionalParameters = function.requiredParameterCount <
            function.positionalParameters.length ||
        function.namedParameters.isNotEmpty;

    _currentFrame.hasCapturedParameters =
        (isFactory && locals.isCaptured(_currentFrame.factoryTypeArgsVar!)) ||
            (hasReceiver && _currentFrame.capturedReceiverVar != null) ||
            function.positionalParameters.any(locals.isCaptured) ||
            function.namedParameters.any(locals.isCaptured);

    int count = 0;
    if (isFactory) {
      _allocateParameter(_currentFrame.factoryTypeArgsVar!, count++);
    }
    if (hasReceiver) {
      assert(!locals.isCaptured(_currentFrame.receiverVar!));
      _allocateParameter(_currentFrame.receiverVar!, count++);

      if (_currentFrame.capturedReceiverVar != null) {
        _allocateVariable(_currentFrame.capturedReceiverVar!);
      }
    }
    if (hasClosureArg) {
      assert(!locals.isCaptured(_currentFrame.closureVar!));
      _allocateParameter(_currentFrame.closureVar!, count++);
    }
    for (var param in function.positionalParameters) {
      _allocateParameter(param, count++);
    }
    for (var param in _currentFrame.sortedNamedParameters) {
      _allocateParameter(param, count++);
    }
    assert(count == _currentFrame.numParameters);

    if (_currentFrame.makesCopyOfParameters) {
      _currentScope.localsUsed += _currentFrame.numParameters;
      _updateFrameSize();
    }
  }

  void _allocateSpecialVariables() {
    _ensureVariableAllocated(_currentFrame.functionTypeArgsVar);
    _ensureVariableAllocated(_currentFrame.contextVar);
    _ensureVariableAllocated(_currentFrame.scratchVar);
    _ensureVariableAllocated(_currentFrame.returnVar);
  }

  void _visitFunction(TreeNode node) {
    _enterScope(node);

    if (node is Field) {
      if (_hasReceiverParameter(node)) {
        _currentFrame.numParameters = 1;
        _allocateParameter(_currentFrame.receiverVar!, 0);
        if (_currentFrame.capturedReceiverVar != null) {
          _allocateVariable(_currentFrame.capturedReceiverVar!);
        }
      }
      _allocateSpecialVariables();
      node.initializer?.accept(this);
    } else {
      assert(node is Procedure ||
          node is Constructor ||
          node is FunctionDeclaration ||
          node is FunctionExpression);

      final FunctionNode function = (node as dynamic).function;

      if (_currentFrame.isSuspendableFunction) {
        // Allocate suspend state variable at fixed slot before parameters.
        _ensureVariableAllocated(_currentFrame.suspendStateVar);
      }
      _allocateParameters(node, function);
      _allocateSpecialVariables();

      if (node is Constructor) {
        for (var field in node.enclosingClass.fields) {
          if (!field.isStatic) {
            field.initializer?.accept(this);
          }
        }
        visitList(node.initializers, this);
      }

      // The visit the function body.
      function.body?.accept(this);
    }

    _leaveScope();
  }

  void _visit(TreeNode node, {bool scope = false, int temps = 0}) {
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
  void defaultMember(Member node) {
    _visitFunction(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _allocateVariable(node.variable);
    _allocateTemp(node);
    _visitFunction(node);
    _freeTemp(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    _allocateTemp(node);
    _visitFunction(node);
    _freeTemp(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    _allocateVariable(node);
    node.visitChildren(this);
  }

  @override
  void visitBlock(Block node) {
    _visit(node, scope: true);
  }

  @override
  void visitBlockExpression(BlockExpression node) {
    // Not using _visit as Block inside BlockExpression does not have a scope.
    _enterScope(node);
    visitList(node.body.statements, this);
    node.value.accept(this);
    _leaveScope();
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    if (!locals.options.enableAsserts) {
      return;
    }
    super.visitAssertStatement(node);
  }

  @override
  void visitAssertBlock(AssertBlock node) {
    if (!locals.options.enableAsserts) {
      return;
    }
    _visit(node, scope: true);
  }

  @override
  void visitForStatement(ForStatement node) {
    _visit(node, scope: true);
  }

  @override
  void visitForInStatement(ForInStatement node) {
    _allocateTemp(node);
    if (locals._capturedIteratorVars != null) {
      _ensureVariableAllocated(locals._capturedIteratorVars![node]);
    }

    node.iterable.accept(this);

    _enterScope(node);
    node.variable.accept(this);
    node.body.accept(this);
    _leaveScope();

    _freeTemp(node);
  }

  @override
  void visitCatch(Catch node) {
    _visit(node, scope: true);
  }

  @override
  void visitLet(Let node) {
    _visit(node, scope: true);
  }

  // -------------- Allocation of temporaries --------------

  @override
  void visitConstructorInvocation(ConstructorInvocation node) {
    if (node.isConst) {
      return;
    }
    _visit(node, temps: 1);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    if (node.isConst) {
      return;
    }
    _visit(node, temps: 1);
  }

  @override
  void visitMapLiteral(MapLiteral node) {
    if (node.isConst) {
      return;
    }
    _visit(node, temps: 1);
  }

  @override
  void visitStringConcatenation(StringConcatenation node) {
    _visit(node, temps: 1);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    _visit(node, temps: 1);
  }

  @override
  void visitLogicalExpression(LogicalExpression node) {
    _visit(node, temps: 1);
  }

  @override
  void visitFunctionInvocation(FunctionInvocation node) {
    int numTemps = 0;
    if (node.kind == FunctionAccessKind.FunctionType) {
      numTemps = 1;
    }
    _visit(node, temps: numTemps);
  }

  @override
  void visitLocalFunctionInvocation(LocalFunctionInvocation node) {
    _visit(node, temps: 1);
  }

  @override
  void visitDynamicSet(DynamicSet node) {
    _visit(node, temps: 1);
  }

  @override
  void visitInstanceSet(InstanceSet node) {
    _visit(node, temps: 1);
  }

  @override
  void visitSuperMethodInvocation(SuperMethodInvocation node) {
    _visit(node, temps: 1);
  }

  @override
  void visitSuperPropertyGet(SuperPropertyGet node) {
    _visit(node, temps: 1);
  }

  @override
  void visitSuperPropertySet(SuperPropertySet node) {
    _visit(node, temps: 1);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _visit(node, temps: 1);
  }

  @override
  void visitVariableGet(VariableGet node) {
    _visit(node, temps: node.variable.isLate ? 1 : 0);
  }

  @override
  void visitVariableSet(VariableSet node) {
    final v = node.variable;
    final bool needsTemp = locals.isCaptured(v) || v.isLate && v.isFinal;
    _visit(node, temps: needsTemp ? 1 : 0);
  }

  @override
  void visitStaticSet(StaticSet node) {
    _visit(node, temps: 1);
  }

  @override
  void visitTryCatch(TryCatch node) {
    _visit(node, temps: 2);
  }

  @override
  void visitTryFinally(TryFinally node) {
    _visit(node, temps: 2);
  }

  @override
  void visitInstantiation(Instantiation node) {
    _visit(node, temps: 3);
  }

  @override
  void visitNullCheck(NullCheck node) {
    _visit(node, temps: 1);
  }
}

class LocalVariableIndexOverflowException
    extends BytecodeLimitExceededException {}
