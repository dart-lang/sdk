// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import 'closure.dart';
import 'scope.dart';

/// This builder walks the code to determine what variables are
/// assigned/captured/free at various points to build a [ClosureScopeModel] and
/// a [VariableScopeModel] that can respond to queries about how a particular
/// variable is being used at any point in the code.
class ScopeModelBuilder extends ir.Visitor<void> with VariableCollectorMixin {
  ClosureScopeModel _model;

  /// A map of each visited call node with the associated information about what
  /// variables are captured/used. Each ir.Node key corresponds to a scope that
  /// was encountered while visiting a closure (initially called through
  /// [translateLazyInitializer] or [translateConstructorOrProcedure]).
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

  ScopeModelBuilder(this._model, {bool hasThisLocal})
      : this._hasThisLocal = hasThisLocal;

  @override
  ir.DartType defaultNode(ir.Node node) =>
      throw UnsupportedError('Unhandled node $node (${node.runtimeType})');

  void visitNode(ir.Node node) {
    return node?.accept(this);
  }

  void visitNodes(List<ir.Node> nodes) {
    for (ir.Node node in nodes) {
      visitNode(node);
    }
  }

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
  void visitNamedExpression(ir.NamedExpression node) {
    visitNode(node.value);
  }

  @override
  void visitTryCatch(ir.TryCatch node) {
    bool oldInTry = _inTry;
    _inTry = true;
    visitInVariableScope(node, () {
      visitNode(node.body);
    });
    visitNodes(node.catches);
    _inTry = oldInTry;
  }

  @override
  void visitTryFinally(ir.TryFinally node) {
    bool oldInTry = _inTry;
    _inTry = true;
    visitInVariableScope(node, () {
      visitNode(node.body);
    });
    visitNode(node.finalizer);
    _inTry = oldInTry;
  }

  @override
  void visitVariableGet(ir.VariableGet node) {
    _markVariableAsUsed(node.variable, VariableUse.explicit);
    // Don't visit `node.promotedType`.
  }

  @override
  void visitVariableSet(ir.VariableSet node) {
    _mutatedVariables.add(node.variable);
    _markVariableAsUsed(node.variable, VariableUse.explicit);
    visitInContext(node.variable.type, VariableUse.localType);
    visitNode(node.value);
    registerAssignedVariable(node.variable);
  }

  void _handleVariableDeclaration(
      ir.VariableDeclaration node, VariableUse usage) {
    if (!node.isFieldFormal) {
      _scopeVariables.add(node);
    }

    visitInContext(node.type, usage);
    visitNode(node.initializer);
  }

  @override
  void visitVariableDeclaration(ir.VariableDeclaration node) {
    _handleVariableDeclaration(node, VariableUse.localType);
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
      visitNode(node.variable);
      visitInVariableScope(node, () {
        visitNode(node.iterable);
        visitNode(node.body);
      });
    });
    if (node.isAsync) {
      _inTry = oldInTry;
    }
  }

  void visitWhileStatement(ir.WhileStatement node) {
    enterNewScope(node, () {
      visitInVariableScope(node, () {
        visitNode(node.condition);
        visitNode(node.body);
      });
    });
  }

  void visitDoStatement(ir.DoStatement node) {
    enterNewScope(node, () {
      visitInVariableScope(node, () {
        visitNode(node.body);
        visitNode(node.condition);
      });
    });
  }

  @override
  void visitForStatement(ir.ForStatement node) {
    List<ir.VariableDeclaration> boxedLoopVariables =
        <ir.VariableDeclaration>[];
    enterNewScope(node, () {
      // First visit initialized variables and update steps so we can easily
      // check if a loop variable was captured in one of these subexpressions.
      visitNodes(node.variables);
      visitInVariableScope(node, () {
        visitNodes(node.updates);
      });

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
      visitInVariableScope(node, () {
        visitNode(node.condition);
        visitNode(node.body);
      });

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
      visitNodesInContext(node.arguments.types,
          new VariableUse.staticTypeArgument(node.interfaceTarget));
    }
    visitNodes(node.arguments.positional);
    visitNodes(node.arguments.named);
  }

  void visitSuperPropertySet(ir.SuperPropertySet node) {
    if (_hasThisLocal) {
      _registerNeedsThis(VariableUse.explicit);
    }
    visitNode(node.value);
  }

  void visitSuperPropertyGet(ir.SuperPropertyGet node) {
    if (_hasThisLocal) {
      _registerNeedsThis(VariableUse.explicit);
    }
  }

  void visitInvokable(ir.TreeNode node, void f()) {
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

    enterNewScope(node, f);

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
  void visitField(ir.Field node) {
    _currentTypeUsage = VariableUse.fieldType;
    visitInvokable(node, () {
      visitNode(node.initializer);
    });
    _currentTypeUsage = null;
  }

  @override
  void visitConstructor(ir.Constructor node) {
    visitInvokable(node, () {
      visitNodes(node.initializers);
      visitNode(node.function);
    });
  }

  @override
  void visitProcedure(ir.Procedure node) {
    visitInvokable(node, () {
      visitNode(node.function);
    });
  }

  @override
  void visitFunctionExpression(ir.FunctionExpression node) {
    visitInvokable(node, () {
      visitInVariableScope(node, () {
        visitNode(node.function);
      });
    });
  }

  @override
  void visitFunctionDeclaration(ir.FunctionDeclaration node) {
    visitInvokable(node, () {
      visitInVariableScope(node, () {
        visitNode(node.function);
      });
    });
  }

  @override
  void visitDynamicType(ir.DynamicType node) {}

  @override
  void visitBottomType(ir.BottomType node) {}

  @override
  void visitInvalidType(ir.InvalidType node) {}

  @override
  void visitVoidType(ir.VoidType node) {}

  @override
  void visitInterfaceType(ir.InterfaceType node) {
    visitNodes(node.typeArguments);
  }

  @override
  void visitFunctionType(ir.FunctionType node) {
    visitNode(node.returnType);
    visitNodes(node.positionalParameters);
    visitNodes(node.namedParameters);
    visitNodes(node.typeParameters);
  }

  @override
  void visitNamedType(ir.NamedType node) {
    visitNode(node.type);
  }

  @override
  void visitTypeParameterType(ir.TypeParameterType node) {
    _analyzeTypeVariable(node, _currentTypeUsage);
  }

  void visitInContext(ir.Node node, VariableUse use) {
    VariableUse oldCurrentTypeUsage = _currentTypeUsage;
    _currentTypeUsage = use;
    visitNode(node);
    _currentTypeUsage = oldCurrentTypeUsage;
  }

  void visitNodesInContext(List<ir.Node> nodes, VariableUse use) {
    VariableUse oldCurrentTypeUsage = _currentTypeUsage;
    _currentTypeUsage = use;
    visitNodes(nodes);
    _currentTypeUsage = oldCurrentTypeUsage;
  }

  @override
  void visitTypeLiteral(ir.TypeLiteral node) {
    visitInContext(node.type, VariableUse.explicit);
  }

  @override
  void visitIsExpression(ir.IsExpression node) {
    visitNode(node.operand);
    visitInContext(node.type, VariableUse.explicit);
  }

  @override
  void visitAsExpression(ir.AsExpression node) {
    visitNode(node.operand);
    visitInContext(node.type,
        node.isTypeError ? VariableUse.implicitCast : VariableUse.explicit);
  }

  @override
  void visitAwaitExpression(ir.AwaitExpression node) {
    visitNode(node.operand);
  }

  @override
  void visitYieldStatement(ir.YieldStatement node) {
    visitNode(node.expression);
  }

  @override
  void visitLoadLibrary(ir.LoadLibrary node) {}

  @override
  void visitCheckLibraryIsLoaded(ir.CheckLibraryIsLoaded node) {}

  @override
  void visitFunctionNode(ir.FunctionNode node) {
    VariableUse parameterUsage = node.parent is ir.Member
        ? new VariableUse.memberParameter(node.parent)
        : new VariableUse.localParameter(node.parent);
    visitNodesInContext(node.typeParameters, parameterUsage);
    for (ir.VariableDeclaration declaration in node.positionalParameters) {
      _handleVariableDeclaration(declaration, parameterUsage);
    }
    for (ir.VariableDeclaration declaration in node.namedParameters) {
      _handleVariableDeclaration(declaration, parameterUsage);
    }
    visitInContext(
        node.returnType,
        node.parent is ir.Member
            ? new VariableUse.memberReturnType(node.parent)
            : new VariableUse.localReturnType(node.parent));
    visitNode(node.body);
  }

  @override
  void visitListLiteral(ir.ListLiteral node) {
    visitInContext(node.typeArgument, VariableUse.listLiteral);
    visitNodes(node.expressions);
  }

  @override
  void visitMapLiteral(ir.MapLiteral node) {
    visitInContext(node.keyType, VariableUse.mapLiteral);
    visitInContext(node.valueType, VariableUse.mapLiteral);
    visitNodes(node.entries);
  }

  @override
  void visitMapEntry(ir.MapEntry node) {
    visitNode(node.key);
    visitNode(node.value);
  }

  @override
  void visitNullLiteral(ir.NullLiteral node) {}

  @override
  void visitStringLiteral(ir.StringLiteral node) {}
  @override
  void visitIntLiteral(ir.IntLiteral node) {}

  @override
  void visitDoubleLiteral(ir.DoubleLiteral node) {}

  @override
  void visitSymbolLiteral(ir.SymbolLiteral node) {}

  @override
  void visitBoolLiteral(ir.BoolLiteral node) {}

  @override
  void visitStringConcatenation(ir.StringConcatenation node) {
    visitNodes(node.expressions);
  }

  @override
  void visitStaticGet(ir.StaticGet node) {}

  @override
  void visitStaticSet(ir.StaticSet node) {
    visitNode(node.value);
  }

  @override
  void visitStaticInvocation(ir.StaticInvocation node) {
    if (node.arguments.types.isNotEmpty) {
      VariableUse usage;
      if (node.target.kind == ir.ProcedureKind.Factory) {
        usage = new VariableUse.constructorTypeArgument(node.target);
      } else {
        usage = new VariableUse.staticTypeArgument(node.target);
      }

      visitNodesInContext(node.arguments.types, usage);
    }
    visitNodes(node.arguments.positional);
    visitNodes(node.arguments.named);
  }

  @override
  void visitConstructorInvocation(ir.ConstructorInvocation node) {
    if (node.arguments.types.isNotEmpty) {
      visitNodesInContext(node.arguments.types,
          new VariableUse.constructorTypeArgument(node.target));
    }
    visitNodes(node.arguments.positional);
    visitNodes(node.arguments.named);
  }

  @override
  void visitConditionalExpression(ir.ConditionalExpression node) {
    visitNode(node.condition);
    visitNode(node.then);
    visitNode(node.otherwise);
    // Don't visit `node.staticType`.
  }

  @override
  void visitMethodInvocation(ir.MethodInvocation node) {
    ir.TreeNode receiver = node.receiver;
    visitNode(receiver);
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
      visitNodesInContext(node.arguments.types, usage);
    }
    visitNodes(node.arguments.positional);
    visitNodes(node.arguments.named);
  }

  @override
  void visitPropertyGet(ir.PropertyGet node) {
    visitNode(node.receiver);
  }

  @override
  void visitPropertySet(ir.PropertySet node) {
    visitNode(node.receiver);
    visitNode(node.value);
  }

  @override
  void visitDirectPropertyGet(ir.DirectPropertyGet node) {
    visitNode(node.receiver);
  }

  @override
  void visitDirectPropertySet(ir.DirectPropertySet node) {
    visitNode(node.receiver);
    visitNode(node.value);
  }

  @override
  void visitNot(ir.Not node) {
    visitNode(node.operand);
  }

  @override
  void visitLogicalExpression(ir.LogicalExpression node) {
    visitNode(node.left);
    visitNode(node.right);
  }

  @override
  void visitLet(ir.Let node) {
    visitNode(node.variable);
    visitNode(node.body);
  }

  @override
  void visitCatch(ir.Catch node) {
    visitInContext(node.guard, VariableUse.explicit);
    visitNode(node.exception);
    visitNode(node.stackTrace);
    visitInVariableScope(node, () {
      visitNode(node.body);
    });
  }

  @override
  void visitInstantiation(ir.Instantiation node) {
    visitNodesInContext(
        node.typeArguments, new VariableUse.instantiationTypeArgument(node));
    visitNode(node.expression);
  }

  @override
  void visitThrow(ir.Throw node) {
    visitNode(node.expression);
  }

  @override
  void visitRethrow(ir.Rethrow node) {}

  @override
  void visitBlock(ir.Block node) {
    visitNodes(node.statements);
  }

  @override
  void visitAssertStatement(ir.AssertStatement node) {
    visitInVariableScope(node, () {
      visitNode(node.condition);
      visitNode(node.message);
    });
  }

  @override
  void visitReturnStatement(ir.ReturnStatement node) {
    visitNode(node.expression);
  }

  @override
  void visitEmptyStatement(ir.EmptyStatement node) {}

  @override
  void visitExpressionStatement(ir.ExpressionStatement node) {
    visitNode(node.expression);
  }

  @override
  void visitSwitchStatement(ir.SwitchStatement node) {
    visitNode(node.expression);
    visitInVariableScope(node, () {
      visitNodes(node.cases);
    });
  }

  @override
  void visitSwitchCase(ir.SwitchCase node) {
    visitNode(node.body);
  }

  @override
  void visitContinueSwitchStatement(ir.ContinueSwitchStatement node) {
    registerContinueSwitch();
  }

  @override
  void visitBreakStatement(ir.BreakStatement node) {}

  @override
  void visitLabeledStatement(ir.LabeledStatement node) {
    visitNode(node.body);
  }

  @override
  void visitFieldInitializer(ir.FieldInitializer node) {
    visitNode(node.value);
  }

  @override
  void visitLocalInitializer(ir.LocalInitializer node) {
    visitNode(node.variable.initializer);
  }

  @override
  void visitSuperInitializer(ir.SuperInitializer node) {
    if (node.arguments.types.isNotEmpty) {
      visitNodesInContext(node.arguments.types,
          new VariableUse.constructorTypeArgument(node.target));
    }
    visitNodes(node.arguments.positional);
    visitNodes(node.arguments.named);
  }

  @override
  void visitRedirectingInitializer(ir.RedirectingInitializer node) {
    if (node.arguments.types.isNotEmpty) {
      visitNodesInContext(node.arguments.types,
          new VariableUse.constructorTypeArgument(node.target));
    }
    visitNodes(node.arguments.positional);
    visitNodes(node.arguments.named);
  }

  @override
  void visitAssertInitializer(ir.AssertInitializer node) {
    visitNode(node.statement);
  }

  @override
  void visitIfStatement(ir.IfStatement node) {
    visitNode(node.condition);
    visitNode(node.then);
    visitNode(node.otherwise);
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
    _markVariableAsUsed(typeVariable, usage);
  }
}
