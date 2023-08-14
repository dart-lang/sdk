// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/type_environment.dart';

/// Implements the `Finalizable` semantics.
///
/// Designed to be mixed in. Calls super.visitXXX() to visit all nodes (except
/// the ones created by this transformation).
///
/// This transformation is not AST-node preserving. [Expression]s and
/// [Statement]s can be replaced by other [Expression]s and [Statement]s
/// respectively. This means one cannot do `visitX() { super.visitX() as X }`.
///
/// This transform must be run on the standard libraries as well. For example
/// `NativeFinalizer`s `attach` implementation depends on it.
mixin FinalizableTransformer on Transformer {
  TypeEnvironment get env;
  Procedure get reachabilityFenceFunction;
  Class get finalizableClass;

  StaticTypeContext? staticTypeContext;

  _Scope? _currentScope;

  bool thisIsFinalizable = false;

  /// Traverses [f] in a newly created [_Scope].
  ///
  /// Any declarations added to this new scope will be fenced in
  /// [appendFencesToStatement] and [appendFencesToExpression] if provided.
  ///
  /// Captures need to be precomputed (by [FindCaptures]) and can be passed in
  /// through [precomputedCaptureScope].
  ///
  /// [declaresThis] is true if `this` in the scope is `Finalizable` and
  /// defined.
  T inScope<T>(
    TreeNode node,
    T Function() f, {
    Statement? appendFencesToStatement,
    Expression? appendFencesToExpression,
    bool? declaresThis,
    _Scope? precomputedCaptureScope,
    Block? addLateValueVariablesTo,
  }) {
    final scope =
        _Scope(node, parent: _currentScope, declaresThis: declaresThis);
    if (precomputedCaptureScope != null) {
      scope._capturesThis = precomputedCaptureScope._capturesThis;
      scope._captures = precomputedCaptureScope._captures;
    }
    _currentScope = scope;
    final result = f();
    if (appendFencesToStatement != null) {
      _appendReachabilityFences(
          appendFencesToStatement, scope.toFenceThisScope);
    }
    if (appendFencesToExpression != null) {
      appendFencesToExpression.replaceWith(_wrapReachabilityFences(
          appendFencesToExpression, scope.toFenceThisScope));
    }
    final lateValueDeclarations = _currentScope?._lateDeclarations ?? {};
    for (final entry in lateValueDeclarations.entries) {
      final lateVariable = entry.key;
      final lateValueVariable = entry.value;
      addLateValueVariablesTo!.statements.insert(
        addLateValueVariablesTo.statements.indexOf(lateVariable),
        lateValueVariable,
      );
    }
    assert(_currentScope == scope);
    _currentScope = _currentScope!.parent;
    return result;
  }

  Map<LocalFunction, _Scope> _precomputedCaptures = {};

  _Scope? _precomputeCaptures(LocalFunction node) {
    if (_currentScope!.allDeclarationsIsEmpty) {
      // There's nothing we can capture.
      return null;
    }
    final lookup = _precomputedCaptures[node];
    if (lookup != null) {
      return lookup;
    }
    final visitor =
        FindCaptures(_currentScope!, thisIsFinalizable, _isFinalizable);
    visitor.visitLocalFunction(node);
    _precomputedCaptures = visitor.precomputedScopes;
    return _precomputedCaptures[node]!;
  }

  @override
  visitField(Field node) {
    assert(staticTypeContext == null);
    staticTypeContext = StaticTypeContext(node, env);
    assert(_currentScope == null);
    assert(thisIsFinalizable == false);
    thisIsFinalizable = _thisIsFinalizableFromMember(node);
    final result = inScope(
      node,
      () => super.visitField(node),
      declaresThis: thisIsFinalizable,
    );
    thisIsFinalizable = false;
    staticTypeContext = null;
    return result;
  }

  @override
  visitConstructor(Constructor node) {
    assert(staticTypeContext == null);
    staticTypeContext = StaticTypeContext(node, env);
    assert(_currentScope == null);
    assert(thisIsFinalizable == false);
    thisIsFinalizable = _thisIsFinalizableFromMember(node);
    final result = inScope(
      node,
      () => super.visitConstructor(node),
      appendFencesToStatement: node.function.body,
      declaresThis: thisIsFinalizable,
    );
    thisIsFinalizable = false;
    staticTypeContext = null;
    return result;
  }

  @override
  visitProcedure(Procedure node) {
    assert(staticTypeContext == null);
    staticTypeContext = StaticTypeContext(node, env);
    assert(_currentScope == null);
    assert(thisIsFinalizable == false);
    thisIsFinalizable = _thisIsFinalizableFromMember(node);
    final result = inScope(
      node,
      () => super.visitProcedure(node),
      appendFencesToStatement: node.function.body,
      declaresThis: thisIsFinalizable,
    );
    thisIsFinalizable = false;
    staticTypeContext = null;
    return result;
  }

  @override
  TreeNode visitBlock(Block node) {
    return inScope(
      node,
      () => super.visitBlock(node),
      appendFencesToStatement: node,
      addLateValueVariablesTo: node,
    );
  }

  @override
  TreeNode visitForInStatement(ForInStatement node) {
    // This does not use [inScope], because it would visit [iterable] with
    // [variable] in scope.

    // First, transform the iterable, which does not have variable in scope.
    node.iterable = transform(node.iterable);
    node.iterable.parent = node;

    final scope = _Scope(node, parent: _currentScope);
    _currentScope = scope;

    // Then, transform the variable, adding it to the new scope.
    assert(node.variable.initializer == null);
    node.variable = transform(node.variable);
    node.variable.parent = node;

    // Then transform the body, with the new variable in scope.
    node.body = transform(node.body);
    node.body.parent = node;

    _appendReachabilityFences(node.body, scope.toFenceThisScope);

    _currentScope = _currentScope!.parent;
    return node;
  }

  @override
  TreeNode visitForStatement(ForStatement node) {
    return inScope(
      node,
      () => super.visitForStatement(node),
      appendFencesToStatement: node.body,
    );
  }

  @override
  TreeNode visitLet(Let node) {
    return inScope(
      node,
      () => super.visitLet(node),
      appendFencesToExpression: node.body,
    );
  }

  @override
  TreeNode visitFunctionDeclaration(FunctionDeclaration node) {
    return inScope(
      node,
      () => super.visitFunctionDeclaration(node),
      appendFencesToStatement: node.function.body,
      precomputedCaptureScope: _precomputeCaptures(node),
    );
  }

  @override
  TreeNode visitFunctionExpression(FunctionExpression node) {
    return inScope(
      node,
      () => super.visitFunctionExpression(node),
      appendFencesToStatement: node.function.body,
      precomputedCaptureScope: _precomputeCaptures(node),
    );
  }

  @override
  TreeNode visitTryCatch(TryCatch node) {
    return inScope(
      node,
      () => super.visitTryCatch(node),
    );
  }

  @override
  TreeNode visitCatch(Catch node) {
    return inScope(
      node,
      () => super.visitCatch(node),
    );
  }

  @override
  TreeNode visitSwitchStatement(SwitchStatement node) {
    return inScope(
      node,
      () => super.visitSwitchStatement(node),
    );
  }

  @override
  TreeNode visitVariableDeclaration(VariableDeclaration node) {
    node = super.visitVariableDeclaration(node) as VariableDeclaration;
    if (_currentScope == null) {
      // Global variable.
      return node;
    }
    if (_isFinalizable(node.type)) {
      if (node.isLate) {
        final lateValueDeclaration = VariableDeclaration(
          ':${node.name}:finalizableValue',
          type: node.type.withDeclaredNullability(Nullability.nullable),
        );
        _currentScope!.addLateDeclaration(node, lateValueDeclaration);
        final initializer = node.initializer;
        if (initializer != null) {
          final newInitializer = VariableSet(lateValueDeclaration, initializer);
          node.initializer = newInitializer;
          newInitializer.parent = node;
        }
      } else {
        _currentScope!.addDeclaration(node);
      }
    }
    return node;
  }

  @override
  TreeNode visitVariableSet(VariableSet node) {
    node = super.visitVariableSet(node) as VariableSet;
    final variable = node.variable;
    if (!_isFinalizable(variable.type)) {
      return node;
    }

    final expression = node.value;

    if (variable.isLate && variable.initializer == null) {
      // We can't fence late variables, they might not have been set yet.
      // Instead we fence the value variable and assign the late variable
      // value to the value variable.
      final valueVariable = _currentScope!
          .lateVariableValueVariable(variable, checkAncestorScopes: true)!;
      final newExpression = _wrapReachabilityFences(
        expression,
        [VariableGet(valueVariable)],
      );
      node.value = newExpression;
      newExpression.parent = node;
      return VariableSet(valueVariable, node);
    }

    final newExpression = _wrapReachabilityFences(
      expression,
      [VariableGet(variable)],
    );
    node.value = newExpression;
    newExpression.parent = node;
    return node;
  }

  @override
  TreeNode visitReturnStatement(ReturnStatement node) {
    final declarations = _currentScope!.toFenceReturn;
    node = super.visitReturnStatement(node) as ReturnStatement;
    if (declarations.isEmpty) {
      return node;
    }

    final expression = node.expression;
    if (expression == null) {
      final newStatement = Block([
        ..._reachabilityFences(declarations),
        node,
      ]);
      return newStatement;
    }

    final newExpression = _wrapReachabilityFences(expression, declarations);

    node.expression = newExpression;
    newExpression.parent = node;

    return node;
  }

  /// The async transform runs after this transform. It transforms
  /// [YieldStatement]s in async* functions into:
  /// ```
  /// _AsyncStarStreamController controller;
  /// if(controller.add(...){
  ///   return ...
  /// } else {
  ///   yield ...
  /// }
  /// ```
  /// We don't want to run this transform after the async transform because that
  /// introduces new scoping and control flow and it would create another
  /// traversal over the AST.
  /// So, we need to insert fences for yields as if they were returns in async*
  /// functions.
  ///
  /// However, there is more. The body of async* and sync* functions is
  /// transformed into a 'closure', which branches on the yield index and is
  /// executed multiple times. The context of this closure is restored on
  /// re-execution. These two things make it a continuation.
  /// The [YieldStatement]s are compiled into returns from that closure.
  /// When inlining the iterator machinery and eliminating dead code, the
  /// compiler can see that we will never execute a re-entry if we just ask for
  /// only the first value of a stream from a sync* function.
  /// So, we need to insert fences for yields as if they were returns in sync*
  /// functions as well.
  @override
  TreeNode visitYieldStatement(YieldStatement node) {
    final declarations = _currentScope!.toFenceReturn;
    node = super.visitYieldStatement(node) as YieldStatement;
    if (declarations.isEmpty) {
      return node;
    }

    final newExpression =
        _wrapReachabilityFences(node.expression, declarations);

    node.expression = newExpression;
    newExpression.parent = node;

    return node;
  }

  /// [AwaitExpression]s are transformed into [YieldStatement]s by the
  /// async transform. See the comment on [visitYieldStatement].
  @override
  TreeNode visitAwaitExpression(AwaitExpression node) {
    final declarations = _currentScope!.toFenceReturn;
    node = super.visitAwaitExpression(node) as AwaitExpression;
    if (declarations.isEmpty) {
      return node;
    }

    final newExpression = _wrapReachabilityFences(node.operand, declarations);

    node.operand = newExpression;
    newExpression.parent = node;

    return node;
  }

  @override
  TreeNode visitThrow(Throw node) {
    final declarations = _currentScope!.toFenceThrow(
        staticTypeContext!.getExpressionType(node.expression), env);
    node = super.visitThrow(node) as Throw;
    if (declarations.isEmpty) {
      return node;
    }

    final newExpression =
        _wrapReachabilityFences(node.expression, declarations);

    node.expression = newExpression;
    newExpression.parent = node;

    return node;
  }

  @override
  TreeNode visitRethrow(Rethrow node) {
    final declarations = _currentScope!.toFenceRethrow(
      _currentScope!.rethrowType,
      env,
    );
    node = super.visitRethrow(node) as Rethrow;
    if (declarations.isEmpty) {
      return node;
    }

    return BlockExpression(
      Block(<Statement>[
        ..._reachabilityFences(declarations),
      ]),
      node,
    );
  }

  @override
  TreeNode visitBreakStatement(BreakStatement node) {
    final declarations = _currentScope!.toFenceBreak(node.target);

    if (declarations.isEmpty) {
      return node;
    }

    final newStatement = Block([
      ..._reachabilityFences(declarations),
      node,
    ]);
    return newStatement;
  }

  @override
  TreeNode visitLabeledStatement(LabeledStatement node) {
    _currentScope!._labels.add(node);
    return super.visitLabeledStatement(node);
  }

  @override
  TreeNode visitContinueSwitchStatement(ContinueSwitchStatement node) {
    final switchStatement = node.target.parent as SwitchStatement;
    final declarations = _currentScope!.toFenceSwitchContinue(switchStatement);

    if (declarations.isEmpty) {
      return node;
    }

    final newStatement = Block([
      ..._reachabilityFences(declarations),
      node,
    ]);
    return newStatement;
  }

  /// Cache for [_isFinalizable].
  ///
  /// Speeds up the type checks by about a factor of 2 on Flutter Gallery.
  Map<DartType, bool> _isFinalizableCache = {};

  /// Whether [type] is something that subtypes `FutureOr<Finalizable?>?`.
  bool _isFinalizable(DartType type) => type.isFinalizable(
        finalizableClass: finalizableClass,
        typeEnvironment: env,
        cache: _isFinalizableCache,
      );

  bool _thisIsFinalizableFromMember(Member member) {
    final enclosingClass_ = member.enclosingClass;
    if (enclosingClass_ == null) {
      return false;
    }
    if (member.isAbstract) {
      return false;
    }
    if (member.isExternal) {
      return false;
    }
    if (member is Constructor && member.isSynthetic) {
      return false;
    }
    if (member is Procedure && member.isStatic) {
      return false;
    }
    return _isFinalizable(
        InterfaceType(enclosingClass_, Nullability.nonNullable));
  }

  List<Statement> _reachabilityFences(List<Expression> declarations) =>
      <Statement>[
        for (var declaration in declarations)
          ExpressionStatement(
            StaticInvocation(
              reachabilityFenceFunction,
              Arguments(<Expression>[declaration]),
            ),
          ),
      ];

  /// Turns an [expression] into a block expression with reachability fences.
  ///
  /// ```
  /// block {
  /// final <expression type> #t1 = <expression>;
  /// _in::reachabilityFence(finalizable0);
  /// _in::reachabilityFence(finalizable1);
  /// // ..
  /// } =>#t1
  /// ```
  ///
  /// Note that this modifies the parent of [expression].
  Expression _wrapReachabilityFences(
      Expression expression, List<Expression> declarations) {
    final resultVariable = VariableDeclaration(
        ":expressionValueWrappedFinalizable",
        initializer: expression,
        type: staticTypeContext!.getExpressionType(expression),
        isFinal: true,
        isSynthesized: true);
    return BlockExpression(
      Block(<Statement>[
        resultVariable,
        ..._reachabilityFences(declarations),
      ]),
      VariableGet(resultVariable),
    );
  }

  Statement _appendReachabilityFences(
      Statement statement, List<Expression> declarations) {
    if (declarations.isEmpty) {
      return statement;
    }
    if (statement is! Block && statement.endsWithAbnormalControlFlow) {
      // This would just wrap the statement in a block for no reason.
      return statement;
    }
    Block block = () {
      if (statement is Block) {
        return statement;
      }
      final replacement = Block(<Statement>[]);
      statement.replaceWith(replacement);
      replacement.statements.add(statement);
      return replacement;
    }();
    if (block.statements.isEmpty ||
        (!block.statements.last.endsWithAbnormalControlFlow)) {
      block.statements.addAll(_reachabilityFences(declarations));
    }
    return block;
  }
}

/// A lightweight version of the above transform that precomputes scopes.
///
/// We need to precompute scopes and captures because a variable can be captured
/// later in a closure than the first return.
///
/// We cannot use the precomputed scopes for their declarations, because we
/// could see returns in a scope before a declaration.
class FindCaptures extends RecursiveVisitor<void> {
  final bool Function(DartType) _isFinalizable;

  final bool thisIsFinalizable;

  final Map<LocalFunction, _Scope> precomputedScopes = {};

  _Scope _currentScope;

  FindCaptures(this._currentScope, this.thisIsFinalizable, this._isFinalizable);

  void inScope(LocalFunction node, void Function() f) {
    final scope = _Scope(node, parent: _currentScope, declaresThis: false);
    assert(precomputedScopes[node] == null);
    precomputedScopes[node] = scope;
    _currentScope = scope;
    final result = f();
    assert(_currentScope == scope);
    _currentScope = _currentScope.parent!;
    return result;
  }

  void visitLocalFunction(LocalFunction node) {
    if (node is FunctionDeclaration) {
      return visitFunctionDeclaration(node);
    }
    if (node is FunctionExpression) {
      return visitFunctionExpression(node);
    }
    assert(false);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    inScope(
      node,
      () => super.visitFunctionDeclaration(node),
    );
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    inScope(
      node,
      () => super.visitFunctionExpression(node),
    );
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (_isFinalizable(node.type)) {
      _currentScope.addDeclaration(node);
    }
    super.visitVariableDeclaration(node);
  }

  @override
  void visitVariableGet(VariableGet node) {
    super.visitVariableGet(node);
    if (_isFinalizable(node.variable.type)) {
      _currentScope.addCapture(node.variable);
    }
  }

  @override
  void visitVariableSet(VariableSet node) {
    super.visitVariableSet(node);
    if (_isFinalizable(node.variable.type)) {
      _currentScope.addCapture(node.variable);
    }
  }

  @override
  void visitThisExpression(ThisExpression node) {
    if (thisIsFinalizable) {
      _currentScope.addCaptureThis();
    }
    super.visitThisExpression(node);
  }
}

/// A scope contains all `Finalizable` declarations and captures.
class _Scope {
  /// Parent scope if any.
  final _Scope? parent;

  /// The [node] introducing this scope.
  final TreeNode node;

  /// The declarations in this scope.
  ///
  /// The list is mutable, because we populate it during visiting statements.
  ///
  /// We use a list rather than a set because declarations are unique and we'd
  /// like to prevent arbitrary reorderings when generating code from this.
  ///
  /// Includes [_lateDeclarations] keys.
  final List<VariableDeclaration> _declarations = [];

  /// The late Finalizable declarations in this scope mapped to nullable non-
  /// late variables that contain the same value.
  ///
  /// The map is mutable, because we populate it during visiting statements.
  final Map<VariableDeclaration, VariableDeclaration> _lateDeclarations = {};

  /// [ThisExpression] is not a [VariableDeclaration] and needs to be tracked
  /// separately.
  final bool declaresThis;

  /// Labels defined in this scope.
  ///
  /// Used for seeing which declarations need to be fenced when encountering
  /// a [BreakStatement];
  final Set<LabeledStatement> _labels = {};

  _Scope(this.node, {this.parent, bool? declaresThis})
      : this.declaresThis = declaresThis ?? false,
        this.allDeclarationsIsEmpty =
            (parent?.allDeclarationsIsEmpty ?? true) &&
                !(declaresThis ?? false);

  @override
  String toString() => toStringIndented();

  toStringIndented({int indentation = 0}) {
    final nonIndented = '''node: $node
declarations:${_declarations.map((e) => '''
  $e''').join()}
declaresThis: $declaresThis
labels:${_labels.map((e) => '''
  $e''').join()}
parent:
${parent?.toStringIndented(indentation: indentation + 2)}
''';
    return nonIndented.replaceAll('\n', (' ' * indentation) + '\n');
  }

  void addDeclaration(VariableDeclaration declaration) {
    _declarations.add(declaration);
    allDeclarationsIsEmpty = false;
  }

  void addLateDeclaration(VariableDeclaration declaration,
      VariableDeclaration lateValueDeclaration) {
    _lateDeclarations[declaration] = lateValueDeclaration;
    addDeclaration(declaration);
  }

  VariableDeclaration? lateVariableValueVariable(
      VariableDeclaration lateVariable,
      {required bool checkAncestorScopes}) {
    final resultThisScope = _lateDeclarations[lateVariable];
    if (resultThisScope != null) {
      return resultThisScope;
    }
    if (!checkAncestorScopes) {
      return null;
    }
    return parent?.lateVariableValueVariable(lateVariable,
        checkAncestorScopes: checkAncestorScopes);
  }

  VariableDeclaration variableToFence(VariableDeclaration declaration,
      {required bool checkAncestorScopes}) {
    final possibleValueToFence = lateVariableValueVariable(declaration,
        checkAncestorScopes: checkAncestorScopes);
    if (possibleValueToFence != null) {
      return possibleValueToFence;
    }

    return declaration;
  }

  /// Whether [allDeclarations] is empty.
  ///
  /// Manually cached for performance.
  bool allDeclarationsIsEmpty;

  /// All declarations in this and parent scopes.
  ///
  /// Excluding `this`.
  List<VariableDeclaration> get allDeclarations => [
        ...?parent?.allDeclarations,
        ..._declarations,
      ];

  bool get canCapture => node is LocalFunction;

  /// Which of the ancestor scopes (or this) captures variables.
  late final _Scope? capturingScope = () {
    if (canCapture) {
      return this;
    }
    return parent?.capturingScope;
  }();

  Map<VariableDeclaration, bool>? _captures;

  Map<VariableDeclaration, bool> get captures {
    if (_captures != null) {
      return _captures!;
    }

    assert(canCapture);
    _captures = {for (var d in parent!.allDeclarations) d: false};
    return _captures!;
  }

  bool _capturesThis = false;

  void addCapture(VariableDeclaration declaration) {
    final capturingScope_ = capturingScope;
    if (capturingScope_ == null) {
      // We're not in a nested closure.
      return;
    }

    final captures = capturingScope_.captures;
    if (!captures.containsKey(declaration)) {
      // This is a local variable, not a captured one.
      return;
    }
    captures[declaration] = true;

    capturingScope_.parent?.addCapture(declaration);
  }

  void addCaptureThis() {
    final capturingScope_ = capturingScope;
    if (capturingScope_ == null) {
      // We're not in a nested closure.
      return;
    }

    capturingScope_._capturesThis = true;

    capturingScope_.parent?.addCaptureThis();
  }

  /// Get declarations in this scope.
  List<Expression> get toFenceThisScope {
    final captures = _captures;
    return [
      if (declaresThis || _capturesThis) ThisExpression(),
      for (var d in _declarations)
        VariableGet(variableToFence(d, checkAncestorScopes: false)),
      if (captures != null)
        for (var d in captures.entries.where((e) => e.value).map((e) => e.key))
          VariableGet(variableToFence(d, checkAncestorScopes: true)),
    ];
  }

  /// Whether when a return is found, this is the last ancestor of which
  /// declarations should be considered.
  bool get scopesReturn {
    assert(node is Block ||
        node is Catch ||
        node is ForInStatement ||
        node is ForStatement ||
        node is Let ||
        node is LocalFunction ||
        node is Member ||
        node is SwitchStatement ||
        node is TryCatch);
    return node is Member || node is LocalFunction;
  }

  /// Get all declarations that should stay alive on a return.
  ///
  /// This include all declarations in scopes until we see a function scope.
  List<Expression> get toFenceReturn {
    return [
      if (!scopesReturn) ...parent!.toFenceReturn,
      ...toFenceThisScope,
    ];
  }

  List<Expression> toFenceBreak(LabeledStatement label) {
    if (_labels.contains(label)) {
      return [];
    }
    return [
      ...parent!.toFenceBreak(label),
      ...toFenceThisScope,
    ];
  }

  List<Expression> toFenceSwitchContinue(SwitchStatement switchStatement) {
    if (node == switchStatement) {
      return [];
    }
    return [
      ...parent!.toFenceSwitchContinue(switchStatement),
      ...toFenceThisScope,
    ];
  }

  bool scopesThrow(DartType exceptionType, TypeEnvironment typeEnvironment) {
    final node_ = node;
    if (node_ is! TryCatch) {
      return false;
    }
    final catches = node_.catches;
    for (final catch_ in catches) {
      if (typeEnvironment.isSubtypeOf(
          exceptionType, catch_.guard, SubtypeCheckMode.withNullabilities)) {
        return true;
      }
    }
    return false;
  }

  List<Expression> toFenceThrow(
    DartType exceptionType,
    TypeEnvironment typeEnvironment,
  ) =>
      [
        if (!scopesThrow(exceptionType, typeEnvironment))
          ...?parent?.toFenceThrow(exceptionType, typeEnvironment),
        ...toFenceThisScope,
      ];

  DartType get rethrowType {
    final node_ = node;
    if (node_ is Catch) {
      return node_.guard;
    }
    return parent!.rethrowType;
  }

  List<Expression> toFenceRethrow(
      DartType exceptionType, TypeEnvironment typeEnvironment) {
    return [
      if (!scopesThrow(exceptionType, typeEnvironment))
        ...?parent?.toFenceRethrow(exceptionType, typeEnvironment),
      if (scopesThrow(exceptionType, typeEnvironment))
        ...?parent?.toFenceThrow(exceptionType, typeEnvironment),
      ...toFenceThisScope,
    ];
  }
}

extension on Statement {
  /// Whether this statement ends with abnormal control flow.
  ///
  /// Used to avoid inserting definitely dead reachabilityFences.
  ///
  /// Recurses into [Block]s to  inspect their last statement.
  ///
  /// Examples:
  ///
  /// ```dart
  /// {
  ///   // ...
  ///   return 5;
  /// }
  /// ```
  ///
  /// returns true.
  ///
  /// ```dart
  /// {
  ///   {
  ///     break L2;
  ///   }
  /// }
  /// ```
  ///
  /// returns true.
  ///
  /// ```dart
  /// print(foo);
  /// ```
  ///
  /// returns false.
  ///
  /// Does not take into consideration full control flow, rather this is best
  /// effort:
  ///
  /// ```dart
  /// {
  ///   return 42;
  ///   var unreachable = true;
  /// }
  /// ```
  ///
  /// returns false, even though inserting fences is superfluous.
  ///
  /// These extra fences are not unsound.
  bool get endsWithAbnormalControlFlow {
    if (this is ReturnStatement) {
      return true;
    }
    if (this is BreakStatement) {
      return true;
    }
    if (this is ContinueSwitchStatement) {
      return true;
    }
    if (this is Throw) {
      return true;
    }
    if (this is Rethrow) {
      return true;
    }
    final this_ = this;
    if (this_ is Block) {
      final statements = this_.statements;
      if (statements.isEmpty) {
        return false;
      }
      return statements.last.endsWithAbnormalControlFlow;
    }
    return false;
  }
}

extension FinalizableDartType on DartType {
  /// Whether `this` is something that subtypes `FutureOr<Finalizable?>?`.
  bool isFinalizable({
    required Class finalizableClass,
    required TypeEnvironment typeEnvironment,
    Map<DartType, bool>? cache,
  }) {
    final type = this;
    final cached = cache?[type];
    if (cached != null) {
      return cached;
    }

    final finalizableType = FutureOrType(
        InterfaceType(finalizableClass, Nullability.nullable),
        Nullability.nullable);
    if (!typeEnvironment.isSubtypeOf(
      type,
      finalizableType,
      SubtypeCheckMode.withNullabilities,
    )) {
      cache?[type] = false;
      return false;
    }

    // Exclude never types.
    final futureOfNeverType =
        FutureOrType(NeverType.nullable(), Nullability.nullable);
    final result = !typeEnvironment.isSubtypeOf(
      type,
      futureOfNeverType,
      SubtypeCheckMode.ignoringNullabilities,
    );
    cache?[type] = result;
    return result;
  }
}
