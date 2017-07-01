// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../closure.dart';
import '../elements/entities.dart';
import 'closure.dart';
import '../kernel/element_map.dart';

/// This builder walks the code to determine what variables are captured/free at
/// various points to build ClosureScope that can respond to queries
/// about how a particular variable is being used at any point in the code.
class ClosureScopeBuilder extends ir.Visitor {
  /// A map of each visited call node with the associated information about what
  /// variables are captured/used. Each ir.Node key corresponds to a scope that
  /// was encountered while visiting a closure (initially called through
  /// [translateLazyIntializer] or [translateConstructorOrProcedure]).
  Map<ir.Node, ClosureScope> _closureInfoMap = <ir.Node, ClosureScope>{};

  /// A map of the nodes that we have flagged as necessary to generate closure
  /// classes for in a later stage. We map that node to information ascertained
  /// about variable usage in the surrounding scope.
  Map<ir.Node /* ir.Field | ir.FunctionNode */, ScopeInfo> _closuresToGenerate =
      <ir.Node, ScopeInfo>{};

  /// The local variables that have been declared in the current scope.
  List<ir.VariableDeclaration> _scopeVariables;

  /// Pointer to the context in which this closure is executed.
  /// For example, in the expression `var foo = () => 3 + i;`, the executable
  /// context as we walk the nodes in that expression is the ir.Field `foo`.
  ir.Node _executableContext;

  /// A flag to indicate if we are currently inside a closure.
  bool _isInsideClosure = false;

  /// Pointer to the original node where this closure builder started.
  ir.Node _outermostNode;

  /// Keep track of the mutated local variables so that we don't need to box
  /// non-mutated variables.
  Set<ir.VariableDeclaration> _mutatedVariables =
      new Set<ir.VariableDeclaration>();

  /// The set of variables that are accessed in some form, whether they are
  /// mutated or not.
  Set<ir.VariableDeclaration> _capturedVariables =
      new Set<ir.VariableDeclaration>();

  /// If true, the visitor is currently traversing some nodes that are inside a
  /// try block.
  bool _inTry = false;

  /// Lookup the local entity that corresponds to a kernel variable declaration.
  final KernelToLocalsMap _localsMap;

  /// The current scope we are in.
  KernelScopeInfo _currentScopeInfo;

  final KernelToElementMap _kernelToElementMap;

  ClosureScopeBuilder(this._closureInfoMap, this._closuresToGenerate,
      this._localsMap, this._kernelToElementMap);

  /// Update the [ClosureScope] object corresponding to
  /// this node if any variables are captured.
  void attachCapturedScopeVariables(ir.Node node) {
    Set<Local> capturedVariablesForScope = new Set<Local>();

    for (ir.VariableDeclaration variable in _scopeVariables) {
      // No need to box non-assignable elements.
      if (variable.isFinal || variable.isConst) continue;
      if (!_mutatedVariables.contains(variable)) continue;
      if (_capturedVariables.contains(variable)) {
        capturedVariablesForScope.add(_localsMap.getLocal(variable));
      }
    }
    if (!capturedVariablesForScope.isEmpty) {
      ThisLocal thisLocal = null;
      if (node is ir.Member && node.isInstanceMember) {
        if (node is ir.Procedure) {
          thisLocal = new ThisLocal(_kernelToElementMap.getMethod(node));
        } else if (node is ir.Field) {
          thisLocal = new ThisLocal(_kernelToElementMap.getField(node));
        }
      } else if (node is ir.Constructor) {
        thisLocal = new ThisLocal(_kernelToElementMap.getConstructor(node));
      }

      Entity context;
      if (_executableContext is ir.Member) {
        context = _kernelToElementMap.getMember(_executableContext);
      } else {
        context = _kernelToElementMap.getLocalFunction(_executableContext);
      }
      _closureInfoMap[node] =
          new KernelClosureScope(capturedVariablesForScope, context, thisLocal);
    }
  }

  /// Perform book-keeping with the current set of local variables that have
  /// been seen thus far before entering this new scope.
  void enterNewScope(ir.Node node, Function visitNewScope) {
    List<ir.VariableDeclaration> oldScopeVariables = _scopeVariables;
    _scopeVariables = <ir.VariableDeclaration>[];
    visitNewScope();
    attachCapturedScopeVariables(node);
    _mutatedVariables.removeAll(_scopeVariables);
    _scopeVariables = oldScopeVariables;
  }

  @override
  void defaultNode(ir.Node node) {
    node.visitChildren(this);
  }

  @override
  visitTryCatch(ir.TryCatch node) {
    bool oldInTry = _inTry;
    _inTry = true;
    node.visitChildren(this);
    _inTry = oldInTry;
  }

  @override
  visitTryFinally(ir.TryFinally node) {
    bool oldInTry = _inTry;
    _inTry = true;
    node.visitChildren(this);
    _inTry = oldInTry;
  }

  @override
  visitVariableGet(ir.VariableGet node) {
    _markVariableAsUsed(node.variable);
  }

  @override
  visitVariableSet(ir.VariableSet node) {
    _mutatedVariables.add(node);
    _markVariableAsUsed(node.variable);
    node.visitChildren(this);
  }

  /// Add this variable to the set of free variables if appropriate and add to
  /// the tally of variables used in try or sync blocks.
  void _markVariableAsUsed(ir.VariableDeclaration variable) {
    if (_isInsideClosure && !_inCurrentContext(variable)) {
      // If the element is not declared in the current function and the element
      // is not the closure itself we need to mark the element as free variable.
      // Note that the check on [insideClosure] is not just an
      // optimization: factories have type parameters as function
      // parameters, and type parameters are declared in the class, not
      // the factory.
      _currentScopeInfo.freeVariables.add(variable);
    }
    if (_inTry) {
      _currentScopeInfo.localsUsedInTryOrSync
          .add(_localsMap.getLocal(variable));
    }
  }

  @override
  void visitForStatement(ir.ForStatement node) {
    List<Local> boxedLoopVariables = <Local>[];
    enterNewScope(node, () {
      // First visit initialized variables and update steps so we can easily
      // check if a loop variable was captured in one of these subexpressions.
      node.variables
          .forEach((ir.VariableDeclaration variable) => variable.accept(this));
      node.updates
          .forEach((ir.Expression expression) => expression.accept(this));

      // Loop variables that have not been captured yet can safely be flagged as
      // non-mutated, because no nested function can observe the mutation.
      for (ir.VariableDeclaration variable in node.variables) {
        if (!_capturedVariables.contains(variable)) {
          _mutatedVariables.remove(variable);
        }
      }

      // Visit condition and body.
      // This must happen after the above, so any loop variables mutated in the
      // condition or body are indeed flagged as mutated.
      if (node.condition != null) node.condition.accept(this);
      node.body.accept(this);

      // See if we have declared loop variables that need to be boxed.
      for (ir.VariableDeclaration variable in node.variables) {
        // Non-mutated variables should not be boxed.  The _mutatedVariables set
        // gets cleared when `enterNewScope` returns, so check it here.
        if (_capturedVariables.contains(variable) &&
            _mutatedVariables.contains(variable)) {
          boxedLoopVariables.add(_localsMap.getLocal(variable));
        }
      }
    });
    KernelClosureScope scope = _closureInfoMap[node];
    if (scope == null) return;
    _closureInfoMap[node] = new KernelLoopClosureScope(scope.boxedVariables,
        boxedLoopVariables, scope.context, scope.thisLocal);
  }

  void visitInvokable(ir.Node node) {
    bool oldIsInsideClosure = _isInsideClosure;
    ir.Node oldExecutableContext = _executableContext;
    KernelScopeInfo oldScopeInfo = _currentScopeInfo;

    // _outermostNode is only null the first time we enter the body of the
    // field, constsructor, or method that is being analyzed.
    _isInsideClosure = _outermostNode != null;
    _executableContext = node;
    if (!_isInsideClosure) {
      _outermostNode = node;
    }
    _closuresToGenerate[node] = _currentScopeInfo;

    enterNewScope(node, () {
      node.visitChildren(this);
    });

    KernelScopeInfo savedScopeInfo = _currentScopeInfo;
    bool savedIsInsideClosure = _isInsideClosure;

    // Restore old values.
    _isInsideClosure = oldIsInsideClosure;
    _currentScopeInfo = oldScopeInfo;
    _executableContext = oldExecutableContext;

    // Mark all free variables as captured and expect to encounter them in the
    // outer function.
    Iterable<ir.VariableDeclaration> freeVariables =
        savedScopeInfo.freeVariables;
    assert(freeVariables.isEmpty || savedIsInsideClosure);
    for (ir.VariableDeclaration freeVariable in freeVariables) {
      assert(!_capturedVariables.contains(freeVariable));
      _capturedVariables.add(freeVariable);
      _markVariableAsUsed(freeVariable);
    }
  }

  /// Return true if [variable]'s context is the same as the current executable
  /// context.
  bool _inCurrentContext(ir.VariableDeclaration variable) {
    ir.TreeNode node = variable;
    while (node != _outermostNode) {
      if (node == _executableContext) return true;
      node = node.parent;
    }
    return node == _executableContext;
  }

  void translateLazyInitializer(ir.Field field) {
    _currentScopeInfo =
        new KernelScopeInfo(new ThisLocal(_kernelToElementMap.getField(field)));
    visitInvokable(field);
  }

  void translateConstructorOrProcedure(ir.Node constructorOrProcedure) {
    Entity element;
    if (constructorOrProcedure is ir.Constructor ||
        (constructorOrProcedure is ir.Procedure &&
            constructorOrProcedure.kind == ir.ProcedureKind.Factory)) {
      element = _kernelToElementMap.getConstructor(constructorOrProcedure);
    } else {
      assert(constructorOrProcedure is ir.Procedure);
      element = _kernelToElementMap.getMethod(constructorOrProcedure);
    }
    _currentScopeInfo = new KernelScopeInfo(new ThisLocal(element));
    constructorOrProcedure.accept(this);
  }

  void visitFunctionNode(ir.FunctionNode functionNode) {
    visitInvokable(functionNode);
  }
}
