// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../closure.dart';
import '../options.dart';
import 'closure.dart';

/// This builder walks the code to determine what variables are captured/free at
/// various points to build CapturedScope that can respond to queries
/// about how a particular variable is being used at any point in the code.
class CapturedScopeBuilder extends ir.Visitor {
  ScopeModel _model;

  CompilerOptions _options;

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

  /// The current usage of a type annotation.
  ///
  /// This is updated in the visitor to distinguish between unconditional
  /// type variable usage, such as type literals and is tests, and conditional
  /// type variable usage, such as type argument in method invocations.
  VariableUse _currentTypeUsage;

  CapturedScopeBuilder(this._model, this._options, {bool hasThisLocal})
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
    _markVariableAsUsed(node.variable, VariableUse.explicit);
    // Don't visit `node.promotedType`.
  }

  @override
  visitVariableSet(ir.VariableSet node) {
    _mutatedVariables.add(node.variable);
    _markVariableAsUsed(node.variable, VariableUse.explicit);
    visitInContext(node.variable.type, VariableUse.localType);
    node.visitChildren(this);
  }

  void handleVariableDeclaration(
      ir.VariableDeclaration node, VariableUse usage) {
    if (!node.isFieldFormal) {
      _scopeVariables.add(node);
    }

    visitInContext(node.type, usage);
    node.initializer?.accept(this);
  }

  @override
  visitVariableDeclaration(ir.VariableDeclaration node) {
    handleVariableDeclaration(node, VariableUse.localType);
  }

  /// Add this variable to the set of free variables if appropriate and add to
  /// the tally of variables used in try or sync blocks.
  /// If [onlyForRtiChecks] is true, add to the freeVariablesForRti set instead
  /// of freeVariables as we will only use it if runtime type information is
  /// checked.
  void _markVariableAsUsed(
      ir.Node /* VariableDeclaration | TypeParameterTypeWithContext */ variable,
      VariableUse usage) {
    assert(variable is ir.VariableDeclaration ||
        variable is TypeVariableTypeWithContext);
    assert(usage != null);
    if (_isInsideClosure && !_inCurrentContext(variable)) {
      // If the element is not declared in the current function and the element
      // is not the closure itself we need to mark the element as free variable.
      // Note that the check on [insideClosure] is not just an
      // optimization: factories have type parameters as function
      // parameters, and type parameters are declared in the class, not
      // the factory.
      if (usage == VariableUse.explicit) {
        _currentScopeInfo.freeVariables.add(variable);
      } else {
        _currentScopeInfo.freeVariablesForRti
            .putIfAbsent(variable, () => new Set<VariableUse>())
            .add(usage);
      }
    }
    if (_inTry && variable is ir.VariableDeclaration) {
      _currentScopeInfo.localsUsedInTryOrSync.add(variable);
    }
  }

  @override
  void visitThisExpression(ir.ThisExpression thisExpression) {
    if (_hasThisLocal) _registerNeedsThis(VariableUse.explicit);
  }

  @override
  void visitTypeParameter(ir.TypeParameter typeParameter) {
    ir.TreeNode context = _executableContext;
    TypeVariableTypeWithContext typeVariable = new TypeVariableTypeWithContext(
        new ir.TypeParameterType(typeParameter),
        // If this typeParameter is part of a typedef then its parent is
        // null because it has no context. Just pass in null for the
        // context in that case.
        typeParameter.parent != null ? typeParameter.parent.parent : null);
    if (_isInsideClosure && context is ir.Procedure && context.isFactory) {
      // This is a closure in a factory constructor.  Since there is no
      // [:this:], we have to mark the type arguments as free variables to
      // capture them in the closure.
      _useTypeVariableAsLocal(typeVariable, _currentTypeUsage);
    }

    if (_executableContext is ir.Member && _executableContext is! ir.Field) {
      // In checked mode, using a type variable in a type annotation may lead
      // to a runtime type check that needs to access the type argument and
      // therefore the closure needs a this-element, if it is not in a field
      // initializer; field initializers are evaluated in a context where
      // the type arguments are available in locals.

      if (_hasThisLocal) {
        _registerNeedsThis(_currentTypeUsage);
      } else {
        _useTypeVariableAsLocal(typeVariable, _currentTypeUsage);
      }
    }
  }

  /// Add `this` as a variable that needs to be accessed (and thus may become a
  /// free/captured variable.
  /// If [onlyIfNeedsRti] is true, set thisUsedAsFreeVariableIfNeedsRti to true
  /// instead of thisUsedAsFreeVariable as we will only use `this` if runtime
  /// type information is checked.
  void _registerNeedsThis(VariableUse usage) {
    if (_isInsideClosure) {
      if (usage == VariableUse.explicit) {
        _currentScopeInfo.thisUsedAsFreeVariable = true;
      } else {
        _currentScopeInfo.thisUsedAsFreeVariableIfNeedsRti.add(usage);
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

  void visitSuperMethodInvocation(ir.SuperMethodInvocation node) {
    if (_hasThisLocal) {
      _registerNeedsThis(VariableUse.explicit);
    }
    if (node.arguments.types.isNotEmpty) {
      visitListInContext(node.arguments.types,
          new VariableUse.staticTypeArgument(node.interfaceTarget));
    }
    ir.visitList(node.arguments.positional, this);
    ir.visitList(node.arguments.named, this);
  }

  void visitSuperPropertySet(ir.SuperPropertySet node) {
    if (_hasThisLocal) {
      _registerNeedsThis(VariableUse.explicit);
    }
    node.visitChildren(this);
  }

  void visitSuperPropertyGet(ir.SuperPropertyGet node) {
    if (_hasThisLocal) {
      _registerNeedsThis(VariableUse.explicit);
    }
    node.visitChildren(this);
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
      _markVariableAsUsed(freeVariable, VariableUse.explicit);
    }
    savedScopeInfo.freeVariablesForRti.forEach(
        (TypeVariableTypeWithContext freeVariableForRti,
            Set<VariableUse> useSet) {
      for (VariableUse usage in useSet) {
        _markVariableAsUsed(freeVariableForRti, usage);
      }
    });
    if (_isInsideClosure && savedScopeInfo.thisUsedAsFreeVariable) {
      _currentScopeInfo.thisUsedAsFreeVariable = true;
    }
    if (_isInsideClosure) {
      _currentScopeInfo.thisUsedAsFreeVariableIfNeedsRti
          .addAll(savedScopeInfo.thisUsedAsFreeVariableIfNeedsRti);
    }
  }

  /// Return true if [variable]'s context is the same as the current executable
  /// context.
  bool _inCurrentContext(ir.Node variable) {
    assert(variable is ir.VariableDeclaration ||
        variable is TypeVariableTypeWithContext);
    if (variable is TypeVariableTypeWithContext) {
      return variable.context == _executableContext;
    }
    ir.TreeNode node = variable;
    while (node != _outermostNode && node != _executableContext) {
      node = node.parent;
    }
    return node == _executableContext;
  }

  @override
  void visitField(ir.Field field) {
    _currentTypeUsage = VariableUse.fieldType;
    visitInvokable(field);
    _currentTypeUsage = null;
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
    _analyzeTypeVariable(type, _currentTypeUsage);
  }

  visitInContext(ir.Node node, VariableUse use) {
    VariableUse oldCurrentTypeUsage = _currentTypeUsage;
    _currentTypeUsage = use;
    node?.accept(this);
    _currentTypeUsage = oldCurrentTypeUsage;
  }

  visitListInContext(List<ir.Node> nodes, VariableUse use) {
    VariableUse oldCurrentTypeUsage = _currentTypeUsage;
    _currentTypeUsage = use;
    ir.visitList(nodes, this);
    _currentTypeUsage = oldCurrentTypeUsage;
  }

  visitChildrenInContext(ir.Node node, VariableUse use) {
    VariableUse oldCurrentTypeUsage = _currentTypeUsage;
    _currentTypeUsage = use;
    node.visitChildren(this);
    _currentTypeUsage = oldCurrentTypeUsage;
  }

  @override
  visitTypeLiteral(ir.TypeLiteral node) {
    visitChildrenInContext(node, VariableUse.explicit);
  }

  @override
  visitIsExpression(ir.IsExpression node) {
    node.operand.accept(this);
    visitInContext(node.type, VariableUse.explicit);
  }

  @override
  visitAsExpression(ir.AsExpression node) {
    node.operand.accept(this);
    visitInContext(node.type,
        node.isTypeError ? VariableUse.implicitCast : VariableUse.explicit);
  }

  @override
  visitFunctionNode(ir.FunctionNode node) {
    VariableUse parameterUsage = node.parent is ir.Member
        ? new VariableUse.memberParameter(node.parent)
        : new VariableUse.localParameter(node.parent);
    visitListInContext(node.typeParameters, parameterUsage);
    for (ir.VariableDeclaration declaration in node.positionalParameters) {
      handleVariableDeclaration(declaration, parameterUsage);
    }
    for (ir.VariableDeclaration declaration in node.namedParameters) {
      handleVariableDeclaration(declaration, parameterUsage);
    }
    visitInContext(
        node.returnType,
        node.parent is ir.Member
            ? new VariableUse.memberReturnType(node.parent)
            : new VariableUse.localReturnType(node.parent));
    node.body?.accept(this);
  }

  @override
  visitListLiteral(ir.ListLiteral node) {
    visitInContext(node.typeArgument, VariableUse.listLiteral);
    ir.visitList(node.expressions, this);
  }

  @override
  visitMapLiteral(ir.MapLiteral node) {
    visitInContext(node.keyType, VariableUse.mapLiteral);
    visitInContext(node.valueType, VariableUse.mapLiteral);
    ir.visitList(node.entries, this);
  }

  @override
  visitStaticInvocation(ir.StaticInvocation node) {
    if (node.arguments.types.isNotEmpty) {
      VariableUse usage;
      if (node.target.kind == ir.ProcedureKind.Factory) {
        usage = new VariableUse.constructorTypeArgument(node.target);
      } else {
        usage = new VariableUse.staticTypeArgument(node.target);
      }

      visitListInContext(node.arguments.types, usage);
    }
    ir.visitList(node.arguments.positional, this);
    ir.visitList(node.arguments.named, this);
  }

  @override
  visitConstructorInvocation(ir.ConstructorInvocation node) {
    if (node.arguments.types.isNotEmpty) {
      visitListInContext(node.arguments.types,
          new VariableUse.constructorTypeArgument(node.target));
    }
    ir.visitList(node.arguments.positional, this);
    ir.visitList(node.arguments.named, this);
  }

  @override
  visitConditionalExpression(ir.ConditionalExpression node) {
    node.condition.accept(this);
    node.then.accept(this);
    node.otherwise.accept(this);
    // Don't visit `node.staticType`.
  }

  @override
  visitMethodInvocation(ir.MethodInvocation node) {
    ir.TreeNode receiver = node.receiver;
    receiver.accept(this);
    if (node.arguments.types.isNotEmpty) {
      VariableUse usage;
      if (receiver is ir.VariableGet &&
          (receiver.variable.parent is ir.FunctionDeclaration ||
              receiver.variable.parent is ir.FunctionExpression)) {
        usage =
            new VariableUse.localTypeArgument(receiver.variable.parent, node);
      } else {
        usage = new VariableUse.instanceTypeArgument(node);
      }
      visitListInContext(node.arguments.types, usage);
    }
    ir.visitList(node.arguments.positional, this);
    ir.visitList(node.arguments.named, this);
  }

  @override
  visitCatch(ir.Catch node) {
    visitInContext(node.guard, VariableUse.explicit);
    node.exception?.accept(this);
    node.stackTrace?.accept(this);
    node.body.accept(this);
  }

  /// Returns true if the node is a field, or a constructor (factory or
  /// generative).
  bool _isFieldOrConstructor(ir.Node node) =>
      node is ir.Constructor ||
      node is ir.Field ||
      (node is ir.Procedure && node.isFactory);

  void _analyzeTypeVariable(ir.TypeParameterType type, VariableUse usage) {
    assert(usage != null);
    if (_outermostNode is ir.Member) {
      TypeVariableTypeWithContext typeVariable =
          new TypeVariableTypeWithContext(type, _outermostNode);
      switch (typeVariable.kind) {
        case TypeVariableKind.cls:
          if (_isFieldOrConstructor(_outermostNode)) {
            // Class type variable used in a field or constructor.
            _useTypeVariableAsLocal(typeVariable, usage);
          } else {
            // Class type variable used in a method.
            _registerNeedsThis(usage);
          }
          break;
        case TypeVariableKind.method:
        case TypeVariableKind.local:
          _useTypeVariableAsLocal(typeVariable, usage);
          break;
        case TypeVariableKind.function:
        // The type variable is a function type variable, like `T` in
        //
        //     List<void Function<T>(T)> list;
        //
        // which doesn't correspond to a captured local variable.
      }
    }
  }

  /// If [onlyForRtiChecks] is true, the variable will be added to a list
  /// indicating it *may* be used only if runtime type information is checked.
  void _useTypeVariableAsLocal(
      TypeVariableTypeWithContext typeVariable, VariableUse usage) {
    if (typeVariable.kind != TypeVariableKind.cls && !_options.strongMode) {
      return;
    }
    _markVariableAsUsed(typeVariable, usage);
  }
}
