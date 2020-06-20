// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;
import 'package:front_end/src/api_prototype/constant_evaluator.dart' as ir;

import 'closure.dart';
import 'scope.dart';

/// This builder walks the code to determine what variables are
/// assigned/captured/free at various points to build a [ClosureScopeModel] and
/// a [VariableScopeModel] that can respond to queries about how a particular
/// variable is being used at any point in the code.
class ScopeModelBuilder extends ir.Visitor<InitializerComplexity>
    with VariableCollectorMixin {
  final ir.ConstantEvaluator _constantEvaluator;
  ir.StaticTypeContext _staticTypeContext;

  final ClosureScopeModel _model = new ClosureScopeModel();

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

  bool _hasThisLocal;

  /// Keeps track of the number of boxes that we've created so that they each
  /// have unique names.
  int _boxCounter = 0;

  /// The current usage of a type annotation.
  ///
  /// This is updated in the visitor to distinguish between unconditional
  /// type variable usage, such as type literals and is tests, and conditional
  /// type variable usage, such as type argument in method invocations.
  VariableUse _currentTypeUsage;

  ScopeModelBuilder(this._constantEvaluator);

  ScopeModel computeModel(ir.Member node) {
    if (node.isAbstract && !node.isExternal) {
      return const ScopeModel(
          initializerComplexity: const InitializerComplexity.lazy());
    }

    _staticTypeContext =
        new ir.StaticTypeContext(node, _constantEvaluator.typeEnvironment);
    if (node is ir.Constructor) {
      _hasThisLocal = true;
    } else if (node is ir.Procedure && node.kind == ir.ProcedureKind.Factory) {
      _hasThisLocal = false;
    } else if (node.isInstanceMember) {
      _hasThisLocal = true;
    } else {
      _hasThisLocal = false;
    }

    InitializerComplexity initializerComplexity =
        const InitializerComplexity.lazy();
    if (node is ir.Field) {
      if (node.initializer != null) {
        initializerComplexity = node.accept(this);
      } else {
        initializerComplexity = const InitializerComplexity.constant();
        _model.scopeInfo = new KernelScopeInfo(_hasThisLocal);
      }
    } else {
      assert(node is ir.Procedure || node is ir.Constructor);
      node.accept(this);
    }
    return new ScopeModel(
        closureScopeModel: _model,
        variableScopeModel: variableScopeModel,
        initializerComplexity: initializerComplexity);
  }

  @override
  InitializerComplexity defaultNode(ir.Node node) =>
      throw UnsupportedError('Unhandled node $node (${node.runtimeType})');

  InitializerComplexity visitNode(ir.Node node) {
    return node?.accept(this);
  }

  InitializerComplexity visitNodes(List<ir.Node> nodes) {
    InitializerComplexity complexity = const InitializerComplexity.constant();
    for (ir.Node node in nodes) {
      complexity = complexity.combine(visitNode(node));
    }
    return complexity;
  }

  /// Update the [CapturedScope] object corresponding to
  /// this node if any variables are captured.
  void attachCapturedScopeVariables(ir.TreeNode node) {
    Set<ir.VariableDeclaration> capturedVariablesForScope =
        new Set<ir.VariableDeclaration>();

    for (ir.Node variable in _scopeVariables) {
      // No need to box non-assignable elements.
      if (variable is ir.VariableDeclaration) {
        if (variable.isConst) continue;
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
  InitializerComplexity visitNamedExpression(ir.NamedExpression node) {
    return visitNode(node.value);
  }

  @override
  InitializerComplexity visitTryCatch(ir.TryCatch node) {
    bool oldInTry = _inTry;
    _inTry = true;
    visitInVariableScope(node, () {
      visitNode(node.body);
    });
    visitNodes(node.catches);
    _inTry = oldInTry;
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitTryFinally(ir.TryFinally node) {
    bool oldInTry = _inTry;
    _inTry = true;
    visitInVariableScope(node, () {
      visitNode(node.body);
    });
    visitNode(node.finalizer);
    _inTry = oldInTry;
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitVariableGet(ir.VariableGet node) {
    _markVariableAsUsed(node.variable, VariableUse.explicit);
    // Don't visit `node.promotedType`.
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitVariableSet(ir.VariableSet node) {
    _mutatedVariables.add(node.variable);
    _markVariableAsUsed(node.variable, VariableUse.explicit);
    visitInContext(node.variable.type, VariableUse.localType);
    visitNode(node.value);
    registerAssignedVariable(node.variable);
    return const InitializerComplexity.lazy();
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
  InitializerComplexity visitVariableDeclaration(ir.VariableDeclaration node) {
    _handleVariableDeclaration(node, VariableUse.localType);
    return const InitializerComplexity.lazy();
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
  InitializerComplexity visitThisExpression(ir.ThisExpression thisExpression) {
    if (_hasThisLocal) {
      _registerNeedsThis(VariableUse.explicit);
    }
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitTypeParameter(ir.TypeParameter typeParameter) {
    TypeVariableTypeWithContext typeVariable(ir.Library library) =>
        new TypeVariableTypeWithContext(
            ir.TypeParameterType.withDefaultNullabilityForLibrary(
                typeParameter, library),
            // If this typeParameter is part of a typedef then its parent is
            // null because it has no context. Just pass in null for the
            // context in that case.
            typeParameter.parent != null ? typeParameter.parent.parent : null);

    ir.TreeNode context = _executableContext;
    if (_isInsideClosure && context is ir.Procedure && context.isFactory) {
      // This is a closure in a factory constructor.  Since there is no
      // [:this:], we have to mark the type arguments as free variables to
      // capture them in the closure.
      _useTypeVariableAsLocal(
          typeVariable(context.enclosingLibrary), _currentTypeUsage);
    }

    if (context is ir.Member && context is! ir.Field) {
      // In checked mode, using a type variable in a type annotation may lead
      // to a runtime type check that needs to access the type argument and
      // therefore the closure needs a this-element, if it is not in a field
      // initializer; field initializers are evaluated in a context where
      // the type arguments are available in locals.

      if (_hasThisLocal) {
        _registerNeedsThis(_currentTypeUsage);
      } else {
        _useTypeVariableAsLocal(
            typeVariable(context.enclosingLibrary), _currentTypeUsage);
      }
    }

    visitNode(typeParameter.bound);

    return const InitializerComplexity.constant();
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
  InitializerComplexity visitForInStatement(ir.ForInStatement node) {
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
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitWhileStatement(ir.WhileStatement node) {
    enterNewScope(node, () {
      visitInVariableScope(node, () {
        visitNode(node.condition);
        visitNode(node.body);
      });
    });
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitDoStatement(ir.DoStatement node) {
    enterNewScope(node, () {
      visitInVariableScope(node, () {
        visitNode(node.body);
        visitNode(node.condition);
      });
    });
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitForStatement(ir.ForStatement node) {
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
    if (scope != null) {
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
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitSuperMethodInvocation(
      ir.SuperMethodInvocation node) {
    if (_hasThisLocal) {
      _registerNeedsThis(VariableUse.explicit);
    }
    if (node.arguments.types.isNotEmpty) {
      visitNodesInContext(node.arguments.types,
          new VariableUse.staticTypeArgument(node.interfaceTarget));
    }
    visitNodes(node.arguments.positional);
    visitNodes(node.arguments.named);
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitSuperPropertySet(ir.SuperPropertySet node) {
    if (_hasThisLocal) {
      _registerNeedsThis(VariableUse.explicit);
    }
    visitNode(node.value);
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitSuperPropertyGet(ir.SuperPropertyGet node) {
    if (_hasThisLocal) {
      _registerNeedsThis(VariableUse.explicit);
    }
    return const InitializerComplexity.lazy();
  }

  void visitInvokable(ir.TreeNode node, void f()) {
    assert(node is ir.Member || node is ir.LocalFunction);
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
  InitializerComplexity visitField(ir.Field node) {
    _currentTypeUsage = VariableUse.fieldType;
    InitializerComplexity complexity;
    visitInvokable(node, () {
      complexity = visitNode(node.initializer);
    });
    _currentTypeUsage = null;
    return complexity;
  }

  @override
  InitializerComplexity visitConstructor(ir.Constructor node) {
    visitInvokable(node, () {
      visitNodes(node.initializers);
      visitNode(node.function);
    });
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitProcedure(ir.Procedure node) {
    visitInvokable(node, () {
      visitNode(node.function);
    });
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitFunctionExpression(ir.FunctionExpression node) {
    visitInvokable(node, () {
      visitInVariableScope(node, () {
        visitNode(node.function);
      });
    });
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitFunctionDeclaration(ir.FunctionDeclaration node) {
    visitInvokable(node, () {
      visitInVariableScope(node, () {
        visitNode(node.function);
      });
    });
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitDynamicType(ir.DynamicType node) =>
      const InitializerComplexity.constant();

  @override
  InitializerComplexity visitBottomType(ir.BottomType node) =>
      const InitializerComplexity.lazy();

  @override
  InitializerComplexity visitNeverType(ir.NeverType node) =>
      const InitializerComplexity.lazy();

  @override
  InitializerComplexity visitInvalidType(ir.InvalidType node) =>
      const InitializerComplexity.lazy();

  @override
  InitializerComplexity visitVoidType(ir.VoidType node) =>
      const InitializerComplexity.constant();

  @override
  InitializerComplexity visitInterfaceType(ir.InterfaceType node) {
    return visitNodes(node.typeArguments);
  }

  @override
  InitializerComplexity visitFutureOrType(ir.FutureOrType node) {
    return visitNode(node.typeArgument);
  }

  @override
  InitializerComplexity visitFunctionType(ir.FunctionType node) {
    InitializerComplexity complexity = visitNode(node.returnType);
    complexity = complexity.combine(visitNodes(node.positionalParameters));
    complexity = complexity.combine(visitNodes(node.namedParameters));
    return complexity.combine(visitNodes(node.typeParameters));
  }

  @override
  InitializerComplexity visitNamedType(ir.NamedType node) {
    return visitNode(node.type);
  }

  @override
  InitializerComplexity visitTypeParameterType(ir.TypeParameterType node) {
    _analyzeTypeVariable(node, _currentTypeUsage);
    return const InitializerComplexity.lazy();
  }

  InitializerComplexity visitInContext(ir.Node node, VariableUse use) {
    VariableUse oldCurrentTypeUsage = _currentTypeUsage;
    _currentTypeUsage = use;
    InitializerComplexity complexity = visitNode(node);
    _currentTypeUsage = oldCurrentTypeUsage;
    return complexity;
  }

  InitializerComplexity visitNodesInContext(
      List<ir.Node> nodes, VariableUse use) {
    VariableUse oldCurrentTypeUsage = _currentTypeUsage;
    _currentTypeUsage = use;
    InitializerComplexity complexity = visitNodes(nodes);
    _currentTypeUsage = oldCurrentTypeUsage;
    return complexity;
  }

  @override
  InitializerComplexity visitTypeLiteral(ir.TypeLiteral node) {
    return visitInContext(node.type, VariableUse.explicit);
  }

  @override
  InitializerComplexity visitIsExpression(ir.IsExpression node) {
    visitNode(node.operand);
    visitInContext(node.type, VariableUse.explicit);
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitAsExpression(ir.AsExpression node) {
    visitNode(node.operand);
    visitInContext(node.type,
        node.isTypeError ? VariableUse.implicitCast : VariableUse.explicit);
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitNullCheck(ir.NullCheck node) {
    visitNode(node.operand);
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitAwaitExpression(ir.AwaitExpression node) {
    visitNode(node.operand);
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitYieldStatement(ir.YieldStatement node) {
    visitNode(node.expression);
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitLoadLibrary(ir.LoadLibrary node) {
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitCheckLibraryIsLoaded(
      ir.CheckLibraryIsLoaded node) {
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitFunctionNode(ir.FunctionNode node) {
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
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitListLiteral(ir.ListLiteral node) {
    InitializerComplexity complexity =
        visitInContext(node.typeArgument, VariableUse.listLiteral);
    complexity = complexity.combine(visitNodes(node.expressions));
    if (node.isConst) {
      return const InitializerComplexity.constant();
    } else {
      return complexity.makeEager();
    }
  }

  @override
  InitializerComplexity visitSetLiteral(ir.SetLiteral node) {
    InitializerComplexity complexity =
        visitInContext(node.typeArgument, VariableUse.setLiteral);
    complexity = complexity.combine(visitNodes(node.expressions));
    if (node.isConst) {
      return const InitializerComplexity.constant();
    } else {
      return complexity.makeEager();
    }
  }

  @override
  InitializerComplexity visitMapLiteral(ir.MapLiteral node) {
    InitializerComplexity complexity =
        visitInContext(node.keyType, VariableUse.mapLiteral);
    complexity = complexity
        .combine(visitInContext(node.valueType, VariableUse.mapLiteral));
    complexity = complexity.combine(visitNodes(node.entries));
    if (node.isConst) {
      return const InitializerComplexity.constant();
    } else {
      return complexity.makeEager();
    }
  }

  @override
  InitializerComplexity visitMapEntry(ir.MapEntry node) {
    InitializerComplexity complexity = visitNode(node.key);
    return complexity.combine(visitNode(node.value));
  }

  @override
  InitializerComplexity visitNullLiteral(ir.NullLiteral node) =>
      const InitializerComplexity.constant();

  @override
  InitializerComplexity visitStringLiteral(ir.StringLiteral node) =>
      const InitializerComplexity.constant();

  @override
  InitializerComplexity visitIntLiteral(ir.IntLiteral node) =>
      const InitializerComplexity.constant();

  @override
  InitializerComplexity visitDoubleLiteral(ir.DoubleLiteral node) =>
      const InitializerComplexity.constant();

  @override
  InitializerComplexity visitSymbolLiteral(ir.SymbolLiteral node) =>
      const InitializerComplexity.constant();

  @override
  InitializerComplexity visitBoolLiteral(ir.BoolLiteral node) =>
      const InitializerComplexity.constant();

  @override
  InitializerComplexity visitStringConcatenation(ir.StringConcatenation node) {
    visitNodes(node.expressions);
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitStaticGet(ir.StaticGet node) {
    ir.Member target = node.target;
    if (target is ir.Field) {
      return target.isConst
          ? const InitializerComplexity.constant()
          : new InitializerComplexity.eager(fields: <ir.Field>{target});
    } else if (target is ir.Procedure &&
        target.kind == ir.ProcedureKind.Method) {
      return const InitializerComplexity.constant();
    }
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitStaticSet(ir.StaticSet node) {
    visitNode(node.value);
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitStaticInvocation(ir.StaticInvocation node) {
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
    return node.isConst
        ? const InitializerComplexity.constant()
        : const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitConstructorInvocation(
      ir.ConstructorInvocation node) {
    if (node.arguments.types.isNotEmpty) {
      visitNodesInContext(node.arguments.types,
          new VariableUse.constructorTypeArgument(node.target));
    }
    visitNodes(node.arguments.positional);
    visitNodes(node.arguments.named);
    return node.isConst
        ? const InitializerComplexity.constant()
        : const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitConditionalExpression(
      ir.ConditionalExpression node) {
    InitializerComplexity complexity = visitNode(node.condition);
    complexity = complexity.combine(visitNode(node.then));
    return complexity.combine(visitNode(node.otherwise));
    // Don't visit `node.staticType`.
  }

  @override
  InitializerComplexity visitMethodInvocation(ir.MethodInvocation node) {
    ir.TreeNode receiver = node.receiver;
    visitNode(receiver);
    if (node.arguments.types.isNotEmpty) {
      VariableUse usage;
      if (receiver is ir.VariableGet &&
          (receiver.variable.parent is ir.LocalFunction)) {
        usage =
            new VariableUse.localTypeArgument(receiver.variable.parent, node);
      } else {
        usage = new VariableUse.instanceTypeArgument(node);
      }
      visitNodesInContext(node.arguments.types, usage);
    }
    visitNodes(node.arguments.positional);
    visitNodes(node.arguments.named);
    // TODO(johnniwinther): Recognize constant operations.
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitPropertyGet(ir.PropertyGet node) {
    visitNode(node.receiver);
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitPropertySet(ir.PropertySet node) {
    visitNode(node.receiver);
    visitNode(node.value);
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitDirectPropertyGet(ir.DirectPropertyGet node) {
    visitNode(node.receiver);
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitDirectPropertySet(ir.DirectPropertySet node) {
    visitNode(node.receiver);
    visitNode(node.value);
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitNot(ir.Not node) {
    return visitNode(node.operand);
  }

  @override
  InitializerComplexity visitLogicalExpression(ir.LogicalExpression node) {
    InitializerComplexity complexity = visitNode(node.left);
    return complexity.combine(visitNode(node.right));
  }

  @override
  InitializerComplexity visitLet(ir.Let node) {
    visitNode(node.variable);
    visitNode(node.body);
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitBlockExpression(ir.BlockExpression node) {
    visitNode(node.body);
    visitNode(node.value);
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitCatch(ir.Catch node) {
    visitInContext(node.guard, VariableUse.explicit);
    visitNode(node.exception);
    visitNode(node.stackTrace);
    visitInVariableScope(node, () {
      visitNode(node.body);
    });
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitInstantiation(ir.Instantiation node) {
    InitializerComplexity complexity = visitNodesInContext(
        node.typeArguments, new VariableUse.instantiationTypeArgument(node));
    return complexity.combine(visitNode(node.expression));
  }

  @override
  InitializerComplexity visitThrow(ir.Throw node) {
    visitNode(node.expression);
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitRethrow(ir.Rethrow node) =>
      const InitializerComplexity.lazy();

  @override
  InitializerComplexity visitBlock(ir.Block node) {
    visitNodes(node.statements);
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitAssertStatement(ir.AssertStatement node) {
    visitInVariableScope(node, () {
      visitNode(node.condition);
      visitNode(node.message);
    });
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitReturnStatement(ir.ReturnStatement node) {
    visitNode(node.expression);
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitEmptyStatement(ir.EmptyStatement node) {
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitExpressionStatement(ir.ExpressionStatement node) {
    visitNode(node.expression);
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitSwitchStatement(ir.SwitchStatement node) {
    visitNode(node.expression);
    visitInVariableScope(node, () {
      visitNodes(node.cases);
    });
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitSwitchCase(ir.SwitchCase node) {
    visitNode(node.body);
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitContinueSwitchStatement(
      ir.ContinueSwitchStatement node) {
    registerContinueSwitch();
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitBreakStatement(ir.BreakStatement node) {
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitLabeledStatement(ir.LabeledStatement node) {
    visitNode(node.body);
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitFieldInitializer(ir.FieldInitializer node) {
    visitNode(node.value);
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitLocalInitializer(ir.LocalInitializer node) {
    visitNode(node.variable.initializer);
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitSuperInitializer(ir.SuperInitializer node) {
    if (node.arguments.types.isNotEmpty) {
      visitNodesInContext(node.arguments.types,
          new VariableUse.constructorTypeArgument(node.target));
    }
    visitNodes(node.arguments.positional);
    visitNodes(node.arguments.named);
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitRedirectingInitializer(
      ir.RedirectingInitializer node) {
    if (node.arguments.types.isNotEmpty) {
      visitNodesInContext(node.arguments.types,
          new VariableUse.constructorTypeArgument(node.target));
    }
    visitNodes(node.arguments.positional);
    visitNodes(node.arguments.named);
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitAssertInitializer(ir.AssertInitializer node) {
    visitNode(node.statement);
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitIfStatement(ir.IfStatement node) {
    visitNode(node.condition);
    visitNode(node.then);
    visitNode(node.otherwise);
    return const InitializerComplexity.lazy();
  }

  @override
  InitializerComplexity visitConstantExpression(ir.ConstantExpression node) {
    if (node.constant is ir.UnevaluatedConstant) {
      node.constant = _constantEvaluator.evaluate(_staticTypeContext, node);
    }
    return const InitializerComplexity.constant();
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

enum ComplexityLevel {
  constant,
  potentiallyEager,
  definitelyLazy,
}

class InitializerComplexity {
  final ComplexityLevel level;
  final Set<ir.Field> fields;

  // TODO(johnniwinther): This should hold the constant literal from CFE when
  // provided.
  const InitializerComplexity.constant()
      : level = ComplexityLevel.constant,
        fields = null;

  // TODO(johnniwinther): Use this to collect data on the size of the
  //  initializer.
  InitializerComplexity.eager({this.fields})
      : level = ComplexityLevel.potentiallyEager;

  const InitializerComplexity.lazy()
      : level = ComplexityLevel.definitelyLazy,
        fields = null;

  InitializerComplexity combine(InitializerComplexity other) {
    if (identical(this, other)) {
      return this;
    } else if (isLazy || other.isLazy) {
      return const InitializerComplexity.lazy();
    } else if (isEager || other.isEager) {
      if (fields != null && other.fields != null) {
        fields.addAll(other.fields);
        return this;
      } else if (fields != null) {
        return this;
      } else {
        return other;
      }
    } else if (isConstant && other.isConstant) {
      // TODO(johnniwinther): This is case doesn't work if InitializerComplexity
      // objects of constant complexity hold the constant literal.
      return this;
    } else if (isEager) {
      assert(other.isConstant);
      return this;
    } else {
      assert(isConstant);
      assert(other.isEager);
      return other;
    }
  }

  InitializerComplexity makeEager() {
    if (isLazy || isEager) {
      return this;
    } else {
      return new InitializerComplexity.eager();
    }
  }

  bool get isConstant => level == ComplexityLevel.constant;

  bool get isEager => level == ComplexityLevel.potentiallyEager;

  bool get isLazy => level == ComplexityLevel.definitelyLazy;

  /// Returns a short textual representation used for testing.
  String get shortText {
    StringBuffer sb = new StringBuffer();
    switch (level) {
      case ComplexityLevel.constant:
        sb.write('constant');
        break;
      case ComplexityLevel.potentiallyEager:
        sb.write('eager');
        if (fields != null) {
          sb.write('&fields=[');
          List<String> names = fields.map((f) => f.name.name).toList()..sort();
          sb.write(names.join(','));
          sb.write(']');
        }
        break;
      case ComplexityLevel.definitelyLazy:
        sb.write('lazy');
        break;
      default:
        throw new UnsupportedError("Unexpected complexity level $level");
    }
    return sb.toString();
  }

  @override
  String toString() => 'InitializerComplexity($shortText)';
}
