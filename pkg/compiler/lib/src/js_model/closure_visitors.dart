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
  List<ir.Node /* ir.VariableDeclaration | TypeParameterTypeWithContext */ >
      _scopeVariables;

  /// Pointer to the context in which this closure is executed.
  /// For example, in the expression `var foo = () => 3 + i;`, the executable
  /// context as we walk the nodes in that expression is the ir.Field `foo`.
  ir.TreeNode _executableContext;

  /// A flag to indicate if we are currently inside a closure.
  bool _isInsideClosure = false;

  /// Pointer to the original node where this closure builder started.
  ir.Node _outermostNode;

  /// Keep track of the mutated local variables so that we don't need to box
  /// non-mutated variables. We know these are only VariableDeclarations because
  /// type variable types and `this` types can't be mutated!
  Set<ir.VariableDeclaration> _mutatedVariables =
      new Set<ir.VariableDeclaration>();

  /// The set of variables that are accessed in some form, whether they are
  /// mutated or not.
  Set<ir.Node /* ir.VariableDeclaration | TypeParameterTypeWithContext */ >
      _capturedVariables = new Set<ir.Node>();

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

    for (ir.Node variable in _scopeVariables) {
      // No need to box non-assignable elements.
      if (variable is ir.VariableDeclaration) {
        if (variable.isFinal || variable.isConst) continue;
        if (!_mutatedVariables.contains(variable)) continue;
        if (_capturedVariables.contains(variable)) {
          capturedVariablesForScope.add(variable);
        }
      }
    }
    if (!capturedVariablesForScope.isEmpty) {
      assert(_model.scopeInfo != null);
      KernelScopeInfo from = _model.scopeInfo;

      KernelCapturedScope capturedScope;
      var nodeBox = new NodeBox(getBoxName(), _executableContext);
      if (node is ir.ForStatement ||
          node is ir.ForInStatement ||
          node is ir.WhileStatement ||
          node is ir.DoStatement) {
        capturedScope = new KernelCapturedLoopScope(
            capturedVariablesForScope,
            nodeBox,
            [],
            from.localsUsedInTryOrSync,
            from.freeVariables,
            from.freeVariablesForRti,
            from.thisUsedAsFreeVariable,
            from.thisUsedAsFreeVariableIfNeedsRti,
            _hasThisLocal);
      } else {
        capturedScope = new KernelCapturedScope(
            capturedVariablesForScope,
            nodeBox,
            from.localsUsedInTryOrSync,
            from.freeVariables,
            from.freeVariablesForRti,
            from.thisUsedAsFreeVariable,
            from.thisUsedAsFreeVariableIfNeedsRti,
            _hasThisLocal);
      }
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
    List<ir.Node> oldScopeVariables = _scopeVariables;
    _scopeVariables = <ir.Node>[];
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
  /// If [onlyForRtiChecks] is true, add to the freeVariablesForRti set instead
  /// of freeVariables as we will only use it if runtime type information is
  /// checked.
  void _markVariableAsUsed(
      ir.Node /* VariableDeclaration | TypeParameterTypeWithContext */ variable,
      {bool onlyForRtiChecks = false}) {
    assert(variable is ir.VariableDeclaration ||
        variable is TypeParameterTypeWithContext);
    if (_isInsideClosure && !_inCurrentContext(variable)) {
      // If the element is not declared in the current function and the element
      // is not the closure itself we need to mark the element as free variable.
      // Note that the check on [insideClosure] is not just an
      // optimization: factories have type parameters as function
      // parameters, and type parameters are declared in the class, not
      // the factory.
      if (!onlyForRtiChecks) {
        _currentScopeInfo.freeVariables.add(variable);
      } else {
        _currentScopeInfo.freeVariablesForRti.add(variable);
      }
    }
    if (_inTry && variable is ir.VariableDeclaration) {
      _currentScopeInfo.localsUsedInTryOrSync.add(variable);
    }
  }

  @override
  void visitThisExpression(ir.ThisExpression thisExpression) {
    if (_hasThisLocal) _registerNeedsThis();
  }

  @override
  void visitTypeParameter(ir.TypeParameter typeParameter) {
    // TODO(efortuna): Only perform execute the below code if
    // compiler.options.enableTypeAssertions is true.
    if (false == true) {
      ir.TreeNode context = _executableContext;
      if (_isInsideClosure && context is ir.Procedure && context.isFactory) {
        // This is a closure in a factory constructor.  Since there is no
        // [:this:], we have to mark the type arguments as free variables to
        // capture them in the closure.
        _useTypeVariableAsLocal(new ir.TypeParameterType(typeParameter));
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
  }

  /// Add `this` as a variable that needs to be accessed (and thus may become a
  /// free/captured variable.
  /// If [onlyIfNeedsRti] is true, set thisUsedAsFreeVariableIfNeedsRti to true
  /// instead of thisUsedAsFreeVariable as we will only use `this` if runtime
  /// type information is checked.
  void _registerNeedsThis({bool onlyIfNeedsRti = false}) {
    if (_isInsideClosure) {
      if (!onlyIfNeedsRti) {
        _currentScopeInfo.thisUsedAsFreeVariable = true;
      } else {
        _currentScopeInfo.thisUsedAsFreeVariableIfNeedsRti = true;
      }
    }
  }

  @override
  void visitForInStatement(ir.ForInStatement node) {
    // We need to set `inTry` to true if this is an async for-in because we
    // desugar it into a try-finally in the SSA phase.
    bool oldInTry = _inTry;
    if (node.isAsync) {
      _inTry = true;
    }
    enterNewScope(node, () {
      node.visitChildren(this);
    });
    if (node.isAsync) {
      _inTry = oldInTry;
    }
  }

  void visitWhileStatement(ir.WhileStatement node) {
    enterNewScope(node, () {
      node.visitChildren(this);
    });
  }

  void visitDoStatement(ir.DoStatement node) {
    enterNewScope(node, () {
      node.visitChildren(this);
    });
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
        scope.freeVariablesForRti,
        scope.thisUsedAsFreeVariable,
        scope.thisUsedAsFreeVariableIfNeedsRti,
        scope.hasThisLocal);
  }

  void visitSuperMethodInvocation(ir.SuperMethodInvocation invocation) {
    if (_hasThisLocal) _registerNeedsThis();
    invocation.visitChildren(this);
  }

  void visitSuperPropertySet(ir.SuperPropertySet propertySet) {
    if (_hasThisLocal) _registerNeedsThis();
    propertySet.visitChildren(this);
  }

  void visitSuperPropertyGet(ir.SuperPropertyGet propertyGet) {
    if (_hasThisLocal) _registerNeedsThis();
    propertyGet.visitChildren(this);
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
      _model.scopeInfo = _currentScopeInfo;
    }

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
    Iterable<ir.Node> freeVariables = savedScopeInfo.freeVariables;
    assert(freeVariables.isEmpty || savedIsInsideClosure);
    for (ir.Node freeVariable in freeVariables) {
      _capturedVariables.add(freeVariable);
      _markVariableAsUsed(freeVariable);
    }
    if (_isInsideClosure && savedScopeInfo.thisUsedAsFreeVariable) {
      _currentScopeInfo.thisUsedAsFreeVariable = true;
    }
  }

  /// Return true if [variable]'s context is the same as the current executable
  /// context.
  bool _inCurrentContext(ir.Node variable) {
    assert(variable is ir.VariableDeclaration ||
        variable is TypeParameterTypeWithContext);
    if (variable is TypeParameterTypeWithContext) {
      return variable.memberContext == _executableContext;
    }
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

  @override
  visitTypeParameterType(ir.TypeParameterType type) {
    _analyzeType(type);
  }

  /// Returns true if the node is a field, or a constructor (factory or
  /// generative).
  bool _isFieldOrConstructor(ir.Node node) =>
      node is ir.Constructor ||
      node is ir.Field ||
      (node is ir.Procedure && node.isFactory);

  void _analyzeType(ir.TypeParameterType type) {
    if (_outermostNode is ir.Member) {
      ir.Member outermostMember = _outermostNode;
      if (_isFieldOrConstructor(_outermostNode)) {
        _useTypeVariableAsLocal(type, onlyForRtiChecks: true);
      } else if (outermostMember.isInstanceMember) {
        _registerNeedsThis(onlyIfNeedsRti: true);
      }
    }
  }

  /// If [onlyForRtiChecks] is true, the variable will be added to a list
  /// indicating it *may* be used only if runtime type information is checked.
  void _useTypeVariableAsLocal(ir.TypeParameterType type,
      {bool onlyForRtiChecks = false}) {
    _markVariableAsUsed(new TypeParameterTypeWithContext(type, _outermostNode),
        onlyForRtiChecks: onlyForRtiChecks);
  }
}
