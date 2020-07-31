// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.bytecode.local_vars;

import 'dart:math' show min, max;

import 'package:kernel/ast.dart';
import 'package:kernel/transformations/continuation.dart'
    show ContinuationVariables;
import 'package:kernel/type_environment.dart';
import 'package:vm/bytecode/generics.dart';

import 'dbc.dart';
import 'options.dart' show BytecodeOptions;
import '../metadata/direct_call.dart' show DirectCallMetadata;

// Keep in sync with runtime/vm/object.h:Context::kAwaitJumpVarIndex.
const int awaitJumpVarContextIndex = 0;
const int asyncCompleterContextIndex = 1;
const int controllerContextIndex = 1;

class LocalVariables {
  final _scopes = new Map<TreeNode, Scope>();
  final _vars = new Map<VariableDeclaration, VarDesc>();
  Map<TreeNode, List<int>> _temps;
  Map<TreeNode, VariableDeclaration> _capturedSavedContextVars;
  Map<TreeNode, VariableDeclaration> _capturedExceptionVars;
  Map<TreeNode, VariableDeclaration> _capturedStackTraceVars;
  Map<ForInStatement, VariableDeclaration> _capturedIteratorVars;
  final BytecodeOptions options;
  final StaticTypeContext staticTypeContext;
  final Map<TreeNode, DirectCallMetadata> directCallMetadata;

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
      (throw 'Variable $variable does not have originalParamSlotIndex');

  int tempIndexInFrame(TreeNode node, {int tempIndex: 0}) {
    final temps = _temps[node];
    if (temps == null) {
      throw 'Temp is not allocated for node ${node.runtimeType} $node';
    }
    return temps[tempIndex];
  }

  int get currentContextSize => _currentScope.contextSize;
  int get currentContextLevel => _currentScope.contextLevel;
  int get currentContextId => _currentScope.contextId;

  int get contextLevelAtEntry =>
      _currentFrame.contextLevelAtEntry ??
      (throw "Current frame is top level and it doesn't have a context at entry");

  int getContextLevelOfVar(VariableDeclaration variable) {
    final v = _getVarDesc(variable);
    assert(v.isCaptured);
    return v.scope.contextLevel;
  }

  int getVarContextId(VariableDeclaration variable) {
    final v = _getVarDesc(variable);
    assert(v.isCaptured);
    return v.scope.contextId;
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

  VariableDeclaration get asyncStackTraceVar {
    assert(options.causalAsyncStacks);
    assert(_currentFrame.isSyncYielding);
    return _currentFrame.parent
        .getSyntheticVar(ContinuationVariables.asyncStackTraceVar);
  }

  VariableDeclaration capturedSavedContextVar(TreeNode node) =>
      _capturedSavedContextVars != null
          ? _capturedSavedContextVars[node]
          : null;
  VariableDeclaration capturedExceptionVar(TreeNode node) =>
      _capturedExceptionVars != null ? _capturedExceptionVars[node] : null;
  VariableDeclaration capturedStackTraceVar(TreeNode node) =>
      _capturedStackTraceVars != null ? _capturedStackTraceVars[node] : null;
  VariableDeclaration capturedIteratorVar(ForInStatement node) =>
      _capturedIteratorVars != null ? _capturedIteratorVars[node] : null;

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

  List<VariableDeclaration> get originalNamedParameters =>
      _currentFrame.originalNamedParameters;
  List<VariableDeclaration> get sortedNamedParameters =>
      _currentFrame.sortedNamedParameters;

  LocalVariables(Member node, this.options, this.staticTypeContext,
      this.directCallMetadata) {
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

  void withTemp(TreeNode node, int temp, void action()) {
    final old = _temps[node];
    assert(old == null || old.length == 1);
    _temps[node] = [temp];
    action();
    _temps[node] = old;
  }
}

class VarDesc {
  final VariableDeclaration declaration;
  Scope scope;
  bool isCaptured = false;
  int index;
  int originalParamSlotIndex;

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
  final Frame parent;
  Scope topScope;

  List<VariableDeclaration> originalNamedParameters;
  List<VariableDeclaration> sortedNamedParameters;
  int numParameters = 0;
  int numTypeArguments = 0;
  bool hasOptionalParameters = false;
  bool hasCapturedParameters = false;
  bool hasClosures = false;
  AsyncMarker dartAsyncMarker = AsyncMarker.Sync;
  bool isSyncYielding = false;
  VariableDeclaration receiverVar;
  VariableDeclaration capturedReceiverVar;
  VariableDeclaration functionTypeArgsVar;
  VariableDeclaration factoryTypeArgsVar;
  VariableDeclaration closureVar;
  VariableDeclaration contextVar;
  VariableDeclaration scratchVar;
  VariableDeclaration returnVar;
  Map<String, VariableDeclaration> syntheticVars;
  int frameSize = 0;
  List<int> temporaries = <int>[];
  int contextLevelAtEntry;

  Frame(this.function, this.parent);

  VariableDeclaration getSyntheticVar(String name) {
    if (syntheticVars == null) {
      throw 'No synthetic variables declared in ${function}!';
    }
    if (syntheticVars[name] == null) {
      throw '${name} variable is not declared in ${function}';
    }
    return syntheticVars[name];
  }
}

class Scope {
  final Scope parent;
  final Frame frame;
  final int loopDepth;
  final List<VarDesc> vars = <VarDesc>[];

  int localsUsed;
  int tempsUsed;

  Scope contextOwner;
  int contextUsed = 0;
  int contextSize = 0;
  int contextLevel;
  int contextId;

  Scope(this.parent, this.frame, this.loopDepth);

  bool get hasContext => contextSize > 0;
}

bool _hasReceiverParameter(TreeNode node) {
  return node is Constructor ||
      (node is Procedure && !node.isStatic) ||
      (node is Field && !node.isStatic);
}

class _ScopeBuilder extends RecursiveVisitor<Null> {
  final LocalVariables locals;

  // Set of synthetic variables we need to keep track of in Frame.
  static final registeredSyntheticVars = RegExp(r'^(' +
      '${ContinuationVariables.awaitJumpVar}|' +
      '${ContinuationVariables.awaitContextVar}|' +
      '${ContinuationVariables.asyncCompleter}|' +
      '${ContinuationVariables.asyncStackTraceVar}|' +
      '${ContinuationVariables.controller}|' +
      '${ContinuationVariables.controllerStreamVar}|' +
      // :exception0, :stack_trace17, etc..
      '${ContinuationVariables.savedTryContextVarPrefix}[0-9]+|' +
      '${ContinuationVariables.exceptionVarPrefix}[0-9]+|' +
      '${ContinuationVariables.stackTraceVarPrefix}[0-9]+' +
      r')$');

  Scope _currentScope;
  Frame _currentFrame;
  List<TreeNode> _enclosingTryBlocks;
  List<TreeNode> _enclosingTryCatches;
  int _loopDepth;

  _ScopeBuilder(this.locals);

  List<VariableDeclaration> _sortNamedParameters(FunctionNode function) {
    final params = function.namedParameters.toList();
    params.sort((VariableDeclaration a, VariableDeclaration b) =>
        a.name.compareTo(b.name));
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
        _currentFrame.receiverVar = new VariableDeclaration('this');
        _declareVariable(_currentFrame.receiverVar);
      }
      node.initializer?.accept(this);
    } else {
      assert(node is Procedure ||
          node is Constructor ||
          node is FunctionDeclaration ||
          node is FunctionExpression);

      FunctionNode function = (node as dynamic).function;
      assert(function != null);

      _currentFrame.dartAsyncMarker = function.dartAsyncMarker;

      _currentFrame.isSyncYielding =
          function.asyncMarker == AsyncMarker.SyncYielding;

      if (node is Procedure && node.isFactory) {
        assert(_currentFrame.parent == null);
        _currentFrame.numTypeArguments = 0;
        _currentFrame.factoryTypeArgsVar =
            new VariableDeclaration(':type_arguments');
        _declareVariable(_currentFrame.factoryTypeArgsVar);
      } else {
        _currentFrame.numTypeArguments =
            (_currentFrame.parent?.numTypeArguments ?? 0) +
                function.typeParameters.length;

        if (_currentFrame.numTypeArguments > 0) {
          _currentFrame.functionTypeArgsVar =
              new VariableDeclaration(':function_type_arguments_var')
                ..fileOffset = function.fileOffset;
          _declareVariable(_currentFrame.functionTypeArgsVar);
        }

        if (_currentFrame.parent?.factoryTypeArgsVar != null) {
          _currentFrame.factoryTypeArgsVar =
              _currentFrame.parent.factoryTypeArgsVar;
        }
      }

      if (_hasReceiverParameter(node)) {
        _currentFrame.receiverVar = new VariableDeclaration('this');
        _declareVariable(_currentFrame.receiverVar);
      } else if (_currentFrame.parent?.receiverVar != null) {
        _currentFrame.receiverVar = _currentFrame.parent.receiverVar;
      }
      if (node is FunctionDeclaration || node is FunctionExpression) {
        _currentFrame.closureVar = new VariableDeclaration(':closure');
        _declareVariable(_currentFrame.closureVar);
      }

      _currentFrame.originalNamedParameters = function.namedParameters;
      _currentFrame.sortedNamedParameters = _sortNamedParameters(function);

      visitList(function.positionalParameters, this);
      visitList(_currentFrame.sortedNamedParameters, this);

      // Inner (a)sync_op(..).
      if (_currentFrame.isSyncYielding) {
        // The following variables from parent frame are used implicitly and need
        // to be captured to preserve state across closure invocations.
        _useVariable(_currentFrame.parent
            .getSyntheticVar(ContinuationVariables.awaitJumpVar));
        _useVariable(_currentFrame.parent
            .getSyntheticVar(ContinuationVariables.awaitContextVar));

        // Debugger looks for :controller_stream variable among captured
        // variables in a context, so make sure to capture it.
        if (_currentFrame.parent.dartAsyncMarker == AsyncMarker.AsyncStar) {
          _useVariable(_currentFrame.parent
              .getSyntheticVar(ContinuationVariables.controllerStreamVar));
        }

        if (locals.options.causalAsyncStacks &&
            (_currentFrame.parent.dartAsyncMarker == AsyncMarker.Async ||
                _currentFrame.parent.dartAsyncMarker ==
                    AsyncMarker.AsyncStar)) {
          _useVariable(_currentFrame.parent
              .getSyntheticVar(ContinuationVariables.asyncStackTraceVar));
        }
      } // _currentFrame.isSyncYielding

      if (node is Constructor) {
        for (var field in node.enclosingClass.fields) {
          if (!field.isStatic && field.initializer != null) {
            field.initializer.accept(this);
          }
        }
        visitList(node.initializers, this);
      }

      function.body?.accept(this);

      // sync* is transformed to have two nested synthetic functions.
      // The first such function defines :await_jump_var, which needs to be
      // made part of the outer function's scope.
      if (_currentFrame.parent?.dartAsyncMarker == AsyncMarker.SyncStar) {
        locals
            ._getVarDesc(_currentFrame
                .getSyntheticVar(ContinuationVariables.awaitJumpVar))
            .moveToScope(_currentScope);
      }

      // Outer, original async/async*.
      if (_currentFrame.dartAsyncMarker == AsyncMarker.Async ||
          _currentFrame.dartAsyncMarker == AsyncMarker.AsyncStar) {
        locals
            ._getVarDesc(_currentFrame
                .getSyntheticVar(ContinuationVariables.awaitJumpVar))
            .moveToScope(_currentScope);

        // Depending on the type of async, an additional synth. var. is needed.
        if (_currentFrame.dartAsyncMarker == AsyncMarker.Async) {
          locals
              ._getVarDesc(_currentFrame
                  .getSyntheticVar(ContinuationVariables.asyncCompleter))
              .moveToScope(_currentScope);
        } else if (_currentFrame.dartAsyncMarker == AsyncMarker.AsyncStar) {
          locals
              ._getVarDesc(_currentFrame
                  .getSyntheticVar(ContinuationVariables.controller))
              .moveToScope(_currentScope);
        }
      }
    }

    if (node is FunctionDeclaration ||
        node is FunctionExpression ||
        _currentFrame.hasClosures) {
      _currentFrame.contextVar = new VariableDeclaration(':context');
      _declareVariable(_currentFrame.contextVar);
      _currentFrame.scratchVar = new VariableDeclaration(':scratch');
      _declareVariable(_currentFrame.scratchVar);
    }

    if (_hasReceiverParameter(node)) {
      if (locals.isCaptured(_currentFrame.receiverVar)) {
        // Duplicate receiver variable for local use.
        _currentFrame.capturedReceiverVar = _currentFrame.receiverVar;
        _currentFrame.receiverVar = new VariableDeclaration('this');
        _declareVariable(_currentFrame.receiverVar);
      }
    }

    _leaveFrame();

    _enclosingTryBlocks = savedEnclosingTryBlocks;
    _enclosingTryCatches = savedEnclosingTryCatches;
    _loopDepth = saveLoopDepth;
  }

  _enterFrame(TreeNode node) {
    _currentFrame = new Frame(node, _currentFrame);
    _enterScope(node);
    _currentFrame.topScope = _currentScope;
  }

  _leaveFrame() {
    _leaveScope();
    _currentFrame = _currentFrame.parent;
  }

  void _enterScope(TreeNode node) {
    _currentScope = new Scope(_currentScope, _currentFrame, _loopDepth);
    assert(locals._scopes[node] == null);
    locals._scopes[node] = _currentScope;
  }

  void _leaveScope() {
    _currentScope = _currentScope.parent;
  }

  void _declareVariable(VariableDeclaration variable, [Scope scope]) {
    if (scope == null) {
      scope = _currentScope;
    }
    final VarDesc v = new VarDesc(variable, scope);
    assert(locals._vars[variable] == null,
        'Double declaring variable ${variable}!');
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
        _currentFrame.functionTypeArgsVar,
        _currentFrame.closureVar,
        _currentFrame.contextVar,
        _currentFrame.scratchVar,
        _currentFrame.returnVar,
      ]);
    transient.addAll((_currentFrame.function as LocalFunction)
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
      locals._capturedSavedContextVars ??=
          new Map<TreeNode, VariableDeclaration>();
      _captureSyntheticVariable(ContinuationVariables.savedTryContextVar(depth),
          tryBlock, locals._capturedSavedContextVars);
      ++depth;
    }
    depth = 0;
    for (TreeNode tryBlock in _enclosingTryCatches) {
      locals._capturedExceptionVars ??=
          new Map<TreeNode, VariableDeclaration>();
      locals._capturedStackTraceVars ??=
          new Map<TreeNode, VariableDeclaration>();
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
    if (_currentFrame.receiverVar != null) {
      // Closure creation may load receiver to get instantiator type arguments.
      _useThis();
    }
    node.variable.accept(this);
    _visitFunction(node);
  }

  @override
  visitFunctionExpression(FunctionExpression node) {
    _currentFrame.hasClosures = true;
    if (_currentFrame.receiverVar != null) {
      // Closure creation may load receiver to get instantiator type arguments.
      _useThis();
    }
    _visitFunction(node);
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    _declareVariable(node);
    // Register synthetic variables so we can reference them later where
    // they're implicitely used.
    if (node.name != null && registeredSyntheticVars.hasMatch(node.name)) {
      _currentFrame.syntheticVars ??= <String, VariableDeclaration>{};
      assert(_currentFrame.syntheticVars[node.name] == null,
          "Synthetic variable ${node} double declared!");
      _currentFrame.syntheticVars[node.name] = node;
    }

    node.visitChildren(this);
  }

  @override
  visitVariableGet(VariableGet node) {
    _useVariable(node.variable);
    if (node.variable.isLate && node.variable.initializer != null) {
      node.variable.initializer.accept(this);
    }
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
    var parent = node.parameter.parent;
    if (parent is Class) {
      _useThis();
    } else if (parent is FunctionNode) {
      parent = parent.parent;
      if (parent is Procedure && parent.isFactory) {
        assert(_currentFrame.factoryTypeArgsVar != null);
        _useVariable(_currentFrame.factoryTypeArgsVar);
      }
    }

    // Erase promoted bound in type parameter types as it makes no
    // difference at run time, but types which are different only in
    // promoted bounds are not equal when compared using DartType.operator==,
    // which prevents reusing of type arguments.
    // See dartbug.com/39240 for context.
    node.promotedBound = null;

    node.visitChildren(this);
  }

  @override
  visitBlock(Block node) {
    _visitWithScope(node);
  }

  @override
  visitBlockExpression(BlockExpression node) {
    // Not using _visitWithScope as Block inside BlockExpression does not have
    // a scope.
    _enterScope(node);
    visitList(node.body.statements, this);
    node.value.accept(this);
    _leaveScope();
  }

  @override
  visitAssertStatement(AssertStatement node) {
    if (!locals.options.enableAsserts) {
      return;
    }
    super.visitAssertStatement(node);
  }

  @override
  visitAssertBlock(AssertBlock node) {
    if (!locals.options.enableAsserts) {
      return;
    }
    _visitWithScope(node);
  }

  @override
  visitForStatement(ForStatement node) {
    ++_loopDepth;
    _visitWithScope(node);
    --_loopDepth;
  }

  @override
  visitForInStatement(ForInStatement node) {
    node.iterable.accept(this);

    VariableDeclaration iteratorVar;
    if (_currentFrame.isSyncYielding) {
      // Declare a variable to hold 'iterator' so it could be captured.
      iteratorVar = VariableDeclaration(':for-in-iterator');
      _declareVariable(iteratorVar);
      locals._capturedIteratorVars ??=
          new Map<ForInStatement, VariableDeclaration>();
      locals._capturedIteratorVars[node] = iteratorVar;
    }

    ++_loopDepth;
    _enterScope(node);
    node.variable.accept(this);
    node.body.accept(this);
    _leaveScope();
    --_loopDepth;

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

  @override
  visitReturnStatement(ReturnStatement node) {
    // If returning from within a try-finally block, need to allocate
    // an extra variable to hold a return value.
    // Return value can't be kept on the stack as try-catch statements
    // inside finally can zap expression stack.
    // Literals (including implicit 'null' in 'return;') do not require
    // an extra variable as they can be generated after all finally blocks.
    if (_enclosingTryBlocks.isNotEmpty &&
        (node.expression != null && node.expression is! BasicLiteral)) {
      _currentFrame.returnVar = new VariableDeclaration(':return');
      _declareVariable(_currentFrame.returnVar, _currentFrame.topScope);
    }
    node.visitChildren(this);
  }

  @override
  visitWhileStatement(WhileStatement node) {
    ++_loopDepth;
    node.visitChildren(this);
    --_loopDepth;
  }

  @override
  visitDoStatement(DoStatement node) {
    ++_loopDepth;
    node.visitChildren(this);
    --_loopDepth;
  }
}

// Allocate context slots for each local variable.
class _Allocator extends RecursiveVisitor<Null> {
  final LocalVariables locals;

  Scope _currentScope;
  Frame _currentFrame;
  int _contextIdCounter = 0;

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

    assert(_currentScope.contextOwner == null);
    assert(_currentScope.contextLevel == null);
    assert(_currentScope.contextId == null);

    final int parentContextLevel =
        _currentScope.parent != null ? _currentScope.parent.contextLevel : -1;

    assert(parentContextLevel != null);

    final int numCaptured =
        _currentScope.vars.where((v) => v.isCaptured).length;
    if (numCaptured > 0) {
      // Share contexts between scopes which belong to the same frame and
      // have the same loop depth.
      _currentScope.contextOwner = _currentScope;
      for (Scope contextOwner = _currentScope;
          contextOwner != null &&
              contextOwner.frame == _currentScope.frame &&
              contextOwner.loopDepth == _currentScope.loopDepth;
          contextOwner = contextOwner.parent) {
        if (contextOwner.hasContext) {
          _currentScope.contextOwner = contextOwner;
          break;
        }
      }

      _currentScope.contextOwner.contextSize += numCaptured;

      if (_currentScope.contextOwner == _currentScope) {
        _currentScope.contextLevel = parentContextLevel + 1;
        int saturatedContextId = min(_contextIdCounter++, contextIdLimit - 1);
        _currentScope.contextId = saturatedContextId;
      } else {
        _currentScope.contextLevel = _currentScope.contextOwner.contextLevel;
        _currentScope.contextId = _currentScope.contextOwner.contextId;
      }
    } else {
      _currentScope.contextLevel = parentContextLevel;
    }
  }

  void _leaveScope() {
    assert(_currentScope.contextUsed == _currentScope.contextSize);

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
    locals._temps ??= new Map<TreeNode, List<int>>();
    assert(locals._temps[node] == null);
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

    assert(!v.isAllocated);
    assert(v.scope == _currentScope);

    if (v.isCaptured) {
      v.index = _currentScope.contextOwner.contextUsed++;
      if (v.index >= capturedVariableIndexLimit) {
        throw new LocalVariableIndexOverflowException();
      }
      v.originalParamSlotIndex = paramSlotIndex;
      return;
    }

    if (paramSlotIndex != null) {
      assert(paramSlotIndex < 0 ||
          (_currentFrame.hasOptionalParameters &&
              paramSlotIndex < _currentFrame.numParameters));
      v.index = paramSlotIndex;
    } else {
      v.index = _currentScope.localsUsed++;
      if (v.index >= localVariableIndexLimit) {
        throw new LocalVariableIndexOverflowException();
      }
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
        (isFactory && locals.isCaptured(_currentFrame.factoryTypeArgsVar)) ||
            (hasReceiver && _currentFrame.capturedReceiverVar != null) ||
            function.positionalParameters.any(locals.isCaptured) ||
            function.namedParameters.any(locals.isCaptured);

    int count = 0;
    if (isFactory) {
      _allocateParameter(_currentFrame.factoryTypeArgsVar, count++);
    }
    if (hasReceiver) {
      assert(!locals.isCaptured(_currentFrame.receiverVar));
      _allocateParameter(_currentFrame.receiverVar, count++);

      if (_currentFrame.capturedReceiverVar != null) {
        _allocateVariable(_currentFrame.capturedReceiverVar);
      }
    }
    if (hasClosureArg) {
      assert(!locals.isCaptured(_currentFrame.closureVar));
      _allocateParameter(_currentFrame.closureVar, count++);
    }
    for (var param in function.positionalParameters) {
      _allocateParameter(param, count++);
    }
    for (var param in _currentFrame.sortedNamedParameters) {
      _allocateParameter(param, count++);
    }
    assert(count == _currentFrame.numParameters);

    if (_currentFrame.hasOptionalParameters) {
      _currentScope.localsUsed = _currentFrame.numParameters;
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
        _allocateParameter(_currentFrame.receiverVar, 0);
        if (_currentFrame.capturedReceiverVar != null) {
          _allocateVariable(_currentFrame.capturedReceiverVar);
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
      assert(function != null);

      // Specially allocate implicit variables before anything else to ensure
      // reserved spot in context.

      // Outer async/async* function.
      if (_currentFrame.dartAsyncMarker == AsyncMarker.Async ||
          _currentFrame.dartAsyncMarker == AsyncMarker.AsyncStar) {
        final awaitJumpVar =
            _currentFrame.getSyntheticVar(ContinuationVariables.awaitJumpVar);
        _allocateVariable(awaitJumpVar);
        assert(
            locals._getVarDesc(awaitJumpVar).index == awaitJumpVarContextIndex);
      }

      // :await_jump_var is declared in sync_op_gen, and implicitely used in sync_op.
      if (_currentFrame.parent?.dartAsyncMarker == AsyncMarker.SyncStar) {
        final awaitJumpVar =
            _currentFrame.getSyntheticVar(ContinuationVariables.awaitJumpVar);
        _allocateVariable(awaitJumpVar);
        assert(
            locals._getVarDesc(awaitJumpVar).index == awaitJumpVarContextIndex);
      }

      if (_currentFrame.dartAsyncMarker == AsyncMarker.Async) {
        final asyncCompleter =
            _currentFrame.getSyntheticVar(ContinuationVariables.asyncCompleter);
        _allocateVariable(asyncCompleter);
        assert(locals._getVarDesc(asyncCompleter).index ==
            asyncCompleterContextIndex);
      } else if (_currentFrame.dartAsyncMarker == AsyncMarker.AsyncStar) {
        final controller =
            _currentFrame.getSyntheticVar(ContinuationVariables.controller);
        _allocateVariable(controller);
        assert(locals._getVarDesc(controller).index == controllerContextIndex);
      }

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

      // The visit the function body.
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
    // Since these synthetic vars are specially allocated at a set index,
    // verify these slots, and only allocate normal vars.
    if (node.name == ContinuationVariables.awaitJumpVar) {
      assert(locals._getVarDesc(node).index == awaitJumpVarContextIndex);
    } else if (node.name == ContinuationVariables.asyncCompleter) {
      assert(locals._getVarDesc(node).index == asyncCompleterContextIndex);
    } else if (node.name == ContinuationVariables.controller) {
      assert(locals._getVarDesc(node).index == controllerContextIndex);
    } else {
      _allocateVariable(node);
    }

    node.visitChildren(this);
  }

  @override
  visitBlock(Block node) {
    _visit(node, scope: true);
  }

  @override
  visitBlockExpression(BlockExpression node) {
    // Not using _visit as Block inside BlockExpression does not have a scope.
    _enterScope(node);
    visitList(node.body.statements, this);
    node.value.accept(this);
    _leaveScope();
  }

  @override
  visitAssertStatement(AssertStatement node) {
    if (!locals.options.enableAsserts) {
      return;
    }
    super.visitAssertStatement(node);
  }

  @override
  visitAssertBlock(AssertBlock node) {
    if (!locals.options.enableAsserts) {
      return;
    }
    _visit(node, scope: true);
  }

  @override
  visitForStatement(ForStatement node) {
    _visit(node, scope: true);
  }

  @override
  visitForInStatement(ForInStatement node) {
    _allocateTemp(node);
    if (locals._capturedIteratorVars != null) {
      _ensureVariableAllocated(locals._capturedIteratorVars[node]);
    }

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
  visitMethodInvocation(MethodInvocation node) {
    int numTemps = 0;
    if (isUncheckedClosureCall(
        node, locals.staticTypeContext, locals.options)) {
      numTemps = 1;
    } else if (locals.directCallMetadata != null) {
      final directCall = locals.directCallMetadata[node];
      if (directCall != null && directCall.checkReceiverForNull) {
        numTemps = 1;
      }
    }
    _visit(node, temps: numTemps);
  }

  @override
  visitPropertySet(PropertySet node) {
    _visit(node, temps: 1);
  }

  @override
  visitPropertyGet(PropertyGet node) {
    int numTemps = 0;
    if (locals.directCallMetadata != null) {
      final directCall = locals.directCallMetadata[node];
      if (directCall != null && directCall.checkReceiverForNull) {
        numTemps = 1;
      }
    }
    _visit(node, temps: numTemps);
  }

  @override
  visitDirectPropertySet(DirectPropertySet node) {
    _visit(node, temps: 1);
  }

  @override
  visitSuperMethodInvocation(SuperMethodInvocation node) {
    _visit(node, temps: 1);
  }

  @override
  visitSuperPropertyGet(SuperPropertyGet node) {
    _visit(node, temps: 1);
  }

  @override
  visitSuperPropertySet(SuperPropertySet node) {
    _visit(node, temps: 1);
  }

  @override
  visitSwitchStatement(SwitchStatement node) {
    _visit(node, temps: 1);
  }

  @override
  visitVariableGet(VariableGet node) {
    _visit(node, temps: node.variable.isLate ? 1 : 0);
  }

  @override
  visitVariableSet(VariableSet node) {
    final v = node.variable;
    final bool needsTemp = locals.isCaptured(v) || v.isLate && v.isFinal;
    _visit(node, temps: needsTemp ? 1 : 0);
  }

  @override
  visitStaticSet(StaticSet node) {
    _visit(node, temps: 1);
  }

  @override
  visitTryCatch(TryCatch node) {
    _visit(node, temps: 2);
  }

  @override
  visitTryFinally(TryFinally node) {
    _visit(node, temps: 2);
  }

  @override
  visitInstantiation(Instantiation node) {
    _visit(node, temps: 3);
  }

  @override
  visitNullCheck(NullCheck node) {
    _visit(node, temps: 1);
  }
}

class LocalVariableIndexOverflowException
    extends BytecodeLimitExceededException {}
