// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../closure.dart';
import 'closure.dart';

/// This builder walks the code to determine what variables are captured/free at
/// various points to build CapturedScope that can respond to queries
/// about how a particular variable is being used at any point in the code.
class CapturedScopeBuilder extends ir.Visitor {
  ScopeModel _model;

  /// A map of each visited call node with the associated information about what
  /// variables are captured/used. Each ir.Node key corresponds to a scope that
  /// was encountered while visiting a closure (initially called through
  /// [translateLazyIntializer] or [translateConstructorOrProcedure]).
  Map<ir.Node, KernelCapturedScope> get _scopesCapturedInClosureMap =>
      _model.capturedScopesMap;

  /// A map of the nodes that we have flagged as necessary to generate closure
  /// classes for in a later stage. We map that node to information ascertained
  /// about variable usage in the surrounding scope.
  Map<ir.TreeNode, KernelScopeInfo> get _closuresToGenerate =>
      _model.closuresToGenerate;

  /// The local variables that have been declared in the current scope.
  List<ir.VariableDeclaration> _scopeVariables;

  /// Pointer to the context in which this closure is executed.
  /// For example, in the expression `var foo = () => 3 + i;`, the executable
  /// context as we walk the nodes in that expression is the ir.Field `foo`.
  ir.TreeNode _executableContext;

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

  /// The current scope we are in.
  KernelScopeInfo _currentScopeInfo;

  final bool _hasThisLocal;

  /// Keeps track of the number of boxes that we've created so that they each
  /// have unique names.
  int _boxCounter = 0;

  CapturedScopeBuilder(this._model, {bool hasThisLocal})
      : this._hasThisLocal = hasThisLocal;

  /// Update the [CapturedScope] object corresponding to
  /// this node if any variables are captured.
  void attachCapturedScopeVariables(ir.TreeNode node) {
    Set<ir.VariableDeclaration> capturedVariablesForScope =
        new Set<ir.VariableDeclaration>();

    for (ir.VariableDeclaration variable in _scopeVariables) {
      // No need to box non-assignable elements.
      if (variable.isFinal || variable.isConst) continue;
      if (!_mutatedVariables.contains(variable)) continue;
      if (_capturedVariables.contains(variable)) {
        capturedVariablesForScope.add(variable);
      }
    }
    if (!capturedVariablesForScope.isEmpty) {
      assert(_model.scopeInfo != null);
      KernelScopeInfo from = _model.scopeInfo;
      var capturedScope = new KernelCapturedScope(
          capturedVariablesForScope,
          new NodeBox(getBoxName(), _executableContext),
          from.localsUsedInTryOrSync,
          from.freeVariables,
          _hasThisLocal);
      _model.scopeInfo = _scopesCapturedInClosureMap[node] = capturedScope;
    }
  }

  /// Generate a unique name for the [_boxCounter]th box field.
  ///
  /// The result is used as the name of [NodeBox]s and [BoxLocal]s, and must
  /// therefore be unique to avoid breaking an invariant in the element model
  /// (classes cannot declare multiple fields with the same name).
  ///
  /// Also, the names should be distinct from real field names to prevent
  /// clashes with selectors for those fields.
  ///
  /// These names are not used in generated code, just as element name.
  String getBoxName() {
    return "_box_${_boxCounter++}";
  }

  /// Perform book-keeping with the current set of local variables that have
  /// been seen thus far before entering this new scope.
  void enterNewScope(ir.Node node, void visitNewScope()) {
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
    _mutatedVariables.add(node.variable);
    _markVariableAsUsed(node.variable);
    node.visitChildren(this);
  }

  @override
  visitVariableDeclaration(ir.VariableDeclaration declaration) {
    if (!declaration.isFieldFormal) {
      _scopeVariables.add(declaration);
    }

    declaration.visitChildren(this);
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
      _currentScopeInfo.localsUsedInTryOrSync.add(variable);
    }
  }

  @override
  void visitThisExpression(ir.ThisExpression thisExpression) {
    if (_hasThisLocal) _registerNeedsThis();
  }

  @override
  void visitTypeParameter(ir.TypeParameter typeParameter) {
    ir.TreeNode context = _executableContext;
    if (_isInsideClosure && context is ir.Procedure && context.isFactory) {
      // This is a closure in a factory constructor.  Since there is no
      // [:this:], we have to mark the type arguments as free variables to
      // capture them in the closure.
      // TODO(efortuna): Implement for in the case of RTI.
      // useTypeVariableAsLocal(typeParameter.bound);
    }

    if (_executableContext is ir.Member &&
        _executableContext is! ir.Field &&
        _hasThisLocal) {
      // In checked mode, using a type variable in a type annotation may lead
      // to a runtime type check that needs to access the type argument and
      // therefore the closure needs a this-element, if it is not in a field
      // initializer; field initializers are evaluated in a context where
      // the type arguments are available in locals.
      _registerNeedsThis();
    }
  }

  /// Add `this` as a variable that needs to be accessed (and thus may become a
  /// free/captured variable.
  void _registerNeedsThis() {
    if (_isInsideClosure) {
      _currentScopeInfo.thisUsedAsFreeVariable = true;
    }
  }

  @override
  void visitForStatement(ir.ForStatement node) {
    List<ir.VariableDeclaration> boxedLoopVariables =
        <ir.VariableDeclaration>[];
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
          boxedLoopVariables.add(variable);
        }
      }
    });
    KernelCapturedScope scope = _scopesCapturedInClosureMap[node];
    if (scope == null) return;
    _scopesCapturedInClosureMap[node] = new KernelCapturedLoopScope(
        scope.boxedVariables,
        scope.capturedVariablesAccessor,
        boxedLoopVariables,
        scope.localsUsedInTryOrSync,
        scope.freeVariables,
        scope.hasThisLocal);
  }

  void visitInvokable(ir.TreeNode node) {
    assert(node is ir.Member ||
        node is ir.FunctionExpression ||
        node is ir.FunctionDeclaration);
    bool oldIsInsideClosure = _isInsideClosure;
    ir.TreeNode oldExecutableContext = _executableContext;
    KernelScopeInfo oldScopeInfo = _currentScopeInfo;

    // _outermostNode is only null the first time we enter the body of the
    // field, constructor, or method that is being analyzed.
    _isInsideClosure = _outermostNode != null;
    _executableContext = node;

    _currentScopeInfo = new KernelScopeInfo(_hasThisLocal);
    if (_isInsideClosure) {
      _closuresToGenerate[node] = _currentScopeInfo;
    } else {
      _outermostNode = node;
    }
    _model.scopeInfo = _currentScopeInfo;

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
      _capturedVariables.add(freeVariable);
      _markVariableAsUsed(freeVariable);
    }
  }

  /// Return true if [variable]'s context is the same as the current executable
  /// context.
  bool _inCurrentContext(ir.VariableDeclaration variable) {
    ir.TreeNode node = variable;
    while (node != _outermostNode && node != _executableContext) {
      node = node.parent;
    }
    return node == _executableContext;
  }

  @override
  void visitField(ir.Field field) {
    visitInvokable(field);
  }

  @override
  void visitConstructor(ir.Constructor constructor) {
    visitInvokable(constructor);
  }

  @override
  void visitProcedure(ir.Procedure procedure) {
    visitInvokable(procedure);
  }

  @override
  void visitFunctionExpression(ir.FunctionExpression functionExpression) {
    visitInvokable(functionExpression);
  }

  @override
  void visitFunctionDeclaration(ir.FunctionDeclaration functionDeclaration) {
    visitInvokable(functionDeclaration);
  }
}
