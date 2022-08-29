// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../flow_analysis/flow_analysis.dart';
import 'type_analysis_result.dart';
import 'variable_bindings.dart';

/// Information supplied by the client to [TypeAnalyzer.analyzeSwitchExpression]
/// about an individual `case` or `default` clause.
///
/// The client is free to `implement` or `extend` this class.
class ExpressionCaseInfo<Expression, Node> {
  /// For a `case` clause, the case pattern.  For a `default` clause, `null`.
  final Node? pattern;

  /// For a `case` clause that has a `when` part, the expression following
  /// `when`.  Otherwise `null`.
  final Expression? when;

  /// The body of the `case` or `default` clause.
  final Expression body;

  ExpressionCaseInfo({required this.pattern, this.when, required this.body});
}

/// Information supplied by the client to [TypeAnalyzer.analyzeSwitchStatement]
/// about an individual `case` or `default` clause.
///
/// The client is free to `implement` or `extend` this class.
class StatementCaseInfo<Statement, Expression, Node> {
  /// The AST node for this `case` or `default` clause.  This is used for error
  /// reporting, in case errors arise from mismatch among the variables bound by
  /// various cases that share a body.
  final Node node;

  /// The labels preceding this `case` or `default` clause, if any.
  final List<Node> labels;

  /// For a `case` clause, the case pattern.  For a `default` clause, `null`.
  final Node? pattern;

  /// For a `case` clause that has a `when` part, the expression following
  /// `when`.  Otherwise `null`.
  final Expression? when;

  /// The statements following this `case` or `default` clause.  If this list is
  /// empty, and this is not the last `case` or `default` clause, this clause
  /// will be considered to share a body with the `case` or `default` clause
  /// that follows.
  final List<Statement> body;

  StatementCaseInfo(
      {required this.node,
      this.labels = const [],
      required this.pattern,
      this.when,
      required this.body});
}

/// Type analysis logic to be shared between the analyzer and front end.  The
/// intention is that the client's main type inference visitor class can include
/// this mix-in and call shared analysis logic as needed.
///
/// Concrete methods in this mixin, typically named `analyzeX` for some `X`,
/// are intended to be called by the client in order to analyze an AST node (or
/// equivalent) of type `X`; a client's `visit` method shouldn't have to do much
/// than call the corresponding `analyze` method, passing in AST node's children
/// and other properties, possibly take some client-specific actions with the
/// returned value (such as storing intermediate inference results), and then
/// return the returned value up the call stack.
///
/// Abstract methods in this mixin are intended to be implemented by the client;
/// these are called by the `analyzeX` methods to report analysis results, to
/// query the client-specific information (e.g. to obtain the client's
/// representation of core types), and to trigger recursive analysis of child
/// AST nodes.
mixin TypeAnalyzer<Node extends Object, Statement extends Node,
        Expression extends Node, Variable extends Object, Type extends Object>
    implements VariableBindingCallbacks<Node, Variable, Type> {
  /// Returns the type `bool`.
  Type get boolType;

  /// Returns the type `double`.
  Type get doubleType;

  /// Returns the type `dynamic`.
  Type get dynamicType;

  /// Returns the client's [FlowAnalysis] object.
  ///
  /// May be `null`, because the analyzer doesn't have a flow analysis object
  /// in play when analyzing top level initializers (see
  /// https://github.com/dart-lang/sdk/issues/49701).
  FlowAnalysis<Node, Statement, Expression, Variable, Type>? get flow;

  /// Returns the type `int`.
  Type get intType;

  /// Returns the unknown type context (`?`) used in type inference.
  Type get unknownType;

  /// Analyzes a constant pattern or literal pattern.  [node] is the pattern
  /// itself, and [expression] is the constant or literal expression.  Depending
  /// on the client's representation, [node] and [expression] might or might not
  /// be identical.
  ///
  /// These [TypeAnalyzer] methods will be invoked at the time the pattern is
  /// matched (in order):
  /// - [analyzeExpression]
  /// - [handleConstOrLiteralPattern]
  PatternDispatchResult<Node, Expression, Variable, Type>
      analyzeConstOrLiteralPattern(Node node, Expression expression) {
    return new _ConstOrLiteralPatternDispatchResult<Node, Expression, Variable,
        Type>(this, node, expression);
  }

  /// Analyzes an expression.  [node] is the expression to analyze, and
  /// [context] is the type schema which should be used for type inference.
  ///
  /// Invokes the following [TypeAnalyzer] methods (in order):
  /// - [dispatchExpression]
  /// - [ExpressionTypeAnalysisResult.resolveShorting]
  Type analyzeExpression(Expression node, Type context) {
    ExpressionTypeAnalysisResult<Type> result =
        dispatchExpression(node, context);
    if (typeOperations.isNever(result.provisionalType)) {
      flow?.handleExit();
    }
    return result.resolveShorting();
  }

  /// Analyzes a variable declaration statement of the form
  /// `pattern = initializer;`.
  ///
  /// [node] should be the AST node for the entire declaration, [pattern] for
  /// the pattern, and [initializer] for the initializer.  [isFinal] and
  /// [isLate] indicate whether this is a final declaration and/or a late
  /// declaration, respectively.
  ///
  /// Note that the only kind of pattern allowed in a late declaration is a
  /// variable pattern; [TypeAnalyzerErrors.patternDoesNotAllowLate] will be
  /// reported if any other kind of pattern is used.
  ///
  /// Invokes the following [TypeAnalyzer] methods (in order):
  /// - [dispatchPattern]
  /// - [analyzeExpression]
  /// - Whatever calls are invoked from recursively matching the pattern (see
  ///   the `analyze...` methods for the various pattern types).
  void analyzeInitializedVariableDeclaration(
      Node node, Node pattern, Expression initializer,
      {required bool isFinal, required bool isLate}) {
    PatternDispatchResult<Node, Expression, Variable, Type>
        patternDispatchResult = dispatchPattern(pattern);
    if (isLate &&
        patternDispatchResult is! _VariablePatternDispatchResult<Object, Object,
            Object, Object>) {
      errors.patternDoesNotAllowLate(pattern);
    }
    if (isLate) {
      flow?.lateInitializer_begin(node);
    }
    Type initializerType =
        analyzeExpression(initializer, patternDispatchResult.typeSchema);
    if (isLate) {
      flow?.lateInitializer_end();
    }
    VariableBindings<Node, Variable, Type> bindings =
        new VariableBindings(this);
    patternDispatchResult.match(initializerType, bindings,
        isFinal: isFinal, isLate: isLate, initializer: initializer);
  }

  /// Analyzes an integer literal, given the type context [context].
  IntTypeAnalysisResult<Type> analyzeIntLiteral(Type context) {
    bool convertToDouble = !typeOperations.isSubtypeOf(intType, context) &&
        typeOperations.isSubtypeOf(doubleType, context);
    Type type = convertToDouble ? doubleType : intType;
    return new IntTypeAnalysisResult<Type>(
        type: type, convertedToDouble: convertToDouble);
  }

  /// Analyzes an expression of the form `switch (expression) { cases }`.
  ///
  /// Invokes the following [TypeAnalyzer] methods (in order):
  /// - [analyzeExpression]
  /// - For each `case` or `default` clause:
  ///   - [dispatchPattern] if this is a `case` clause
  ///   - [analyzeExpression] if this is a `case` clause with a `when` part
  ///   - [handleCaseHead] if this is a `case` clause
  ///   - [handleDefault] if this is a `default` clause
  ///   - [handleCase_afterCaseHeads]
  ///   - [analyzeExpression]
  ///   - [finishExpressionCase]
  SimpleTypeAnalysisResult<Type> analyzeSwitchExpression(
      Expression node,
      Expression scrutinee,
      List<ExpressionCaseInfo<Expression, Node>> cases,
      Type context) {
    Type expressionType = analyzeExpression(scrutinee, unknownType);
    flow?.switchStatement_expressionEnd(null);
    Type? lubType;
    for (int i = 0; i < cases.length; i++) {
      ExpressionCaseInfo<Expression, Node> caseInfo = cases[i];
      flow?.switchStatement_beginCase(false, null);
      VariableBindings<Node, Variable, Type> bindings =
          new VariableBindings(this);
      Node? pattern = caseInfo.pattern;
      if (pattern != null) {
        dispatchPattern(pattern)
            .match(expressionType, bindings, isFinal: true, isLate: false);
        Expression? when = caseInfo.when;
        bool hasWhen = when != null;
        if (hasWhen) {
          analyzeExpression(when, boolType);
          flow?.switchStatement_afterWhen(when);
        }
        handleCaseHead(hasWhen: hasWhen);
      } else {
        handleDefault();
      }
      handleCase_afterCaseHeads(const [], 1);
      Type type = analyzeExpression(caseInfo.body, context);
      if (lubType == null) {
        lubType = type;
      } else {
        lubType = typeOperations.lub(lubType, type);
      }
      finishExpressionCase(node, i);
    }
    flow?.switchStatement_end(true);
    return new SimpleTypeAnalysisResult<Type>(type: lubType!);
  }

  /// Analyzes a statement of the form `switch (expression) { cases }`.
  ///
  /// Invokes the following [TypeAnalyzer] methods (in order):
  /// - [dispatchExpression]
  /// - For each `case` or `default` body:
  ///   - For each `case` or `default` clause associated with the body:
  ///     - [dispatchPattern] if this is a `case` clause
  ///     - [analyzeExpression] if this is a `case` clause with a `when` part
  ///     - [handleCaseHead] if this is a `case` clause
  ///     - [handleDefault] if this is a `default` clause
  ///   - [handleCase_afterCaseHeads]
  ///   - [dispatchStatement] for each statement in the body
  ///   - [finishStatementCase]
  /// - [isSwitchExhaustive]
  ///
  /// Returns the total number of execution paths (this is not the same as the
  /// length of [cases] because a case with no statements get merged into the
  /// case that follows).
  int analyzeSwitchStatement(Statement node, Expression scrutinee,
      List<StatementCaseInfo<Statement, Expression, Node>> cases) {
    Type expressionType = analyzeExpression(scrutinee, unknownType);
    flow?.switchStatement_expressionEnd(node);
    List<Node> labels = [];
    List<StatementCaseInfo<Statement, Expression, Node>>?
        casesInThisExecutionPath;
    int numExecutionPaths = 0;
    for (int i = 0; i < cases.length; i++) {
      StatementCaseInfo<Statement, Expression, Node> caseInfo = cases[i];
      labels.addAll(caseInfo.labels);
      (casesInThisExecutionPath ??= []).add(caseInfo);
      if (i == cases.length - 1 || caseInfo.body.isNotEmpty) {
        numExecutionPaths++;
        flow?.switchStatement_beginCase(labels.isNotEmpty, node);
        VariableBindings<Node, Variable, Type> bindings =
            new VariableBindings(this);
        bindings.startAlternatives();
        // Labels count as empty patterns for the purposes of bindings.
        for (Node label in labels) {
          bindings.startAlternative(label);
          bindings.finishAlternative();
        }
        int numCasesInThisExecutionPath = casesInThisExecutionPath.length;
        if (numCasesInThisExecutionPath > 1) {
          flow?.switchStatement_beginAlternatives();
        }
        for (int i = 0; i < numCasesInThisExecutionPath; i++) {
          StatementCaseInfo<Statement, Expression, Node> caseInfo =
              casesInThisExecutionPath[i];
          bindings.startAlternative(caseInfo.node);
          Node? pattern = caseInfo.pattern;
          if (pattern != null) {
            dispatchPattern(pattern)
                .match(expressionType, bindings, isFinal: true, isLate: false);
            Expression? when = caseInfo.when;
            bool hasWhen = when != null;
            if (hasWhen) {
              analyzeExpression(when, boolType);
              flow?.switchStatement_afterWhen(when);
            }
            handleCaseHead(hasWhen: hasWhen);
          } else {
            handleDefault();
          }
          bindings.finishAlternative();
          if (numCasesInThisExecutionPath > 1) {
            flow?.switchStatement_endAlternative();
          }
        }
        bindings.finishAlternatives();
        if (numCasesInThisExecutionPath > 1) {
          flow?.switchStatement_endAlternatives();
        }
        handleCase_afterCaseHeads(labels, numCasesInThisExecutionPath);
        for (Statement statement in caseInfo.body) {
          dispatchStatement(statement);
        }
        finishStatementCase(node, i, caseInfo.body.length);
        labels.clear();
        casesInThisExecutionPath = null;
      }
    }
    flow?.switchStatement_end(isSwitchExhaustive(node, expressionType));
    return numExecutionPaths;
  }

  /// Analyzes a variable declaration of the form `type variable;` or
  /// `var variable;`.
  ///
  /// [node] should be the AST node for the entire declaration, [variable] for
  /// the variable, and [declaredType] for the type (if present).  [isFinal] and
  /// [isLate] indicate whether this is a final declaration and/or a late
  /// declaration, respectively.
  ///
  /// Invokes the following [TypeAnalyzer] methods (in order):
  /// - [setVariableType]
  ///
  /// Returns the inferred type of the variable.
  Type analyzeUninitializedVariableDeclaration(
      Node node, Variable variable, Type? declaredType,
      {required bool isFinal, required bool isLate}) {
    Type inferredType = declaredType ?? dynamicType;
    flow?.declare(variable, false);
    setVariableType(variable, inferredType);
    return inferredType;
  }

  /// Analyzes a variable pattern.  [node] is the pattern itself, [variable] is
  /// the variable, and [declaredType] is the explicitly declared type (if
  /// present).
  ///
  /// These [TypeAnalyzer] methods will be invoked at the time the pattern is
  /// matched (in order):
  /// - [setVariableType] (if this variable hasn't been seen before)
  /// - [handleVariablePattern]
  PatternDispatchResult<Node, Expression, Variable, Type>
      analyzeVariablePattern(Node node, Variable variable, Type? declaredType) {
    return new _VariablePatternDispatchResult<Node, Expression, Variable, Type>(
        this, node, variable, declaredType);
  }

  /// Calls the appropriate `analyze` method according to the form of
  /// [expression].
  ///
  /// For example, if [node] is a binary expression (`a + b`), calls
  /// [analyzeBinaryExpression].
  ExpressionTypeAnalysisResult<Type> dispatchExpression(
      Expression expression, Type context);

  /// Calls the appropriate `analyze` method according to the form of [pattern].
  ///
  /// For example, if [pattern] is a variable pattern, calls
  /// [analyzeVariablePattern].
  PatternDispatchResult<Node, Expression, Variable, Type> dispatchPattern(
      Node pattern);

  /// Calls the appropriate `analyze` method according to the form of
  /// [statement].
  ///
  /// For example, if [statement] is a `while` loop, calls [analyzeWhileLoop].
  void dispatchStatement(Statement statement);

  /// See [analyzeSwitchExpression].
  void finishExpressionCase(Expression node, int caseIndex);

  /// See [analyzeSwitchStatement].
  void finishStatementCase(Statement node, int caseIndex, int numStatements);

  /// See [analyzeSwitchStatement] and [analyzeSwitchExpression].
  void handleCase_afterCaseHeads(List<Node> labels, int numHeads);

  /// See [analyzeSwitchStatement] and [analyzeSwitchExpression].
  void handleCaseHead({required bool hasWhen});

  /// See [analyzeConstOrLiteralPattern].
  void handleConstOrLiteralPattern();

  /// See [analyzeSwitchStatement] and [analyzeSwitchExpression].
  void handleDefault();

  /// See [analyzeVariablePattern].
  void handleVariablePattern(Node node, Type? type);

  /// Queries whether the switch statement or expression represented by [node]
  /// was exhaustive.  See [analyzeSwitchStatement] and
  /// [analyzeSwitchExpression].
  bool isSwitchExhaustive(Node node, Type expressionType);

  /// See [analyzeUninitializedVariableDeclaration] and
  /// [analyzeVariablePattern].
  void setVariableType(Variable variable, Type type);

  /// Computes the type that should be inferred for an implicitly typed variable
  /// whose initializer expression has static type [type].
  Type variableTypeFromInitializerType(Type type);
}

/// Interface used by the shared [TypeAnalyzer] logic to report error conditions
/// up to the client.
abstract class TypeAnalyzerErrors<Node extends Object, Variable extends Object,
    Type extends Object> {
  /// Called when the [TypeAnalyzer] encounters a condition which should be
  /// impossible if the user's code is free from static errors, but which might
  /// arise as a result of error recovery.  To verify this invariant, the client
  /// should double check (preferably using an assertion) that at least one
  /// error has already been reported.
  void assertInErrorRecovery();

  /// Called if a single variable is bound using two different types within the
  /// same pattern, or between two patterns in a set of case clauses that share
  /// a body.
  ///
  /// [pattern] is the variable pattern that was being processed at the time the
  /// inconsistency was discovered, and [type] is its type (which might have
  /// been inferred).  [previousPattern] is the previous variable pattern that
  /// was binding the same variable, and [previousType] is its type.
  void inconsistentMatchVar(
      {required Node pattern,
      required Type type,
      required Node previousPattern,
      required Type previousType});

  /// Called if a single variable is bound both with an explicit type and with
  /// an implicit type within the same pattern, or between two patterns in a set
  /// of case clauses that share a body.
  ///
  /// [pattern] is the variable pattern that was being processed at the time the
  /// inconsistency was discovered.  [previousPattern] is the previous variable
  /// pattern that was binding the same variable.
  ///
  /// TODO(paulberry): the spec might be changed so that this is not an error
  /// condition.  See https://github.com/dart-lang/language/issues/2424.
  void inconsistentMatchVarExplicitness(
      {required Node pattern, required Node previousPattern});

  /// Called if two subpatterns of a pattern attempt to declare the same
  /// variable (with the exception of `_` and logical-or patterns).
  ///
  /// [pattern] is the variable pattern that was being processed at the time the
  /// overlap was discovered.  [previousPattern] is the previous variable
  /// pattern that overlaps with it.
  void matchVarOverlap({required Node pattern, required Node previousPattern});

  /// Called if a variable is bound by one of the alternatives of a logical-or
  /// pattern but not the other, or if it is bound by one of the cases in a set
  /// of case clauses that share a body, but not all of them.
  ///
  /// [alternative] is the AST node which fails to bind the variable.  This will
  /// either be one of the immediate sub-patterns of a logical-or pattern, or a
  /// value of [StatementCaseInfo.node].
  ///
  /// [variable] is the variable that is not bound within [alternative].
  void missingMatchVar(Node alternative, Variable variable);

  /// Called if a pattern is illegally used in a variable declaration statement
  /// that is marked `late`, and that pattern is not allowed in such a
  /// declaration.  The only kind of pattern that may be used in a late variable
  /// declaration is a variable pattern.
  ///
  /// [pattern] is the AST node of the illegal pattern.
  void patternDoesNotAllowLate(Node pattern);
}

/// Specialization of [PatternDispatchResult] returned by
/// [TypeAnalyzer.analyzeConstOrLiteralPattern]
class _ConstOrLiteralPatternDispatchResult<Node extends Object,
        Expression extends Node, Variable extends Object, Type extends Object>
    extends _PatternDispatchResultImpl<Node, Expression, Variable, Type> {
  /// The constant or literal expression.
  ///
  /// Depending on the client's representation, this might or might not be
  /// identical to [node].
  final Expression _expression;

  _ConstOrLiteralPatternDispatchResult(
      super.typeAnalyzer, super.node, this._expression);

  @override
  Type get typeSchema {
    // Note: the type schema only matters for patterns that appear in variable
    // declarations, and variable declarations are not allowed to contain
    // constant patterns.  So this code should only be reachable during error
    // recovery.
    _typeAnalyzer.errors.assertInErrorRecovery();
    return _typeAnalyzer.unknownType;
  }

  @override
  void match(Type matchedType, VariableBindings<Node, Variable, Type> bindings,
      {required bool isFinal, required bool isLate, Expression? initializer}) {
    _typeAnalyzer.analyzeExpression(_expression, matchedType);
    _typeAnalyzer.handleConstOrLiteralPattern();
  }
}

/// Common base class for all specializations of [PatternDispatchResult]
/// returned by methods in [TypeAnalyzer].
abstract class _PatternDispatchResultImpl<Node extends Object,
        Expression extends Node, Variable extends Object, Type extends Object>
    implements PatternDispatchResult<Node, Expression, Variable, Type> {
  /// Pointer back to the [TypeAnalyzer].
  final TypeAnalyzer<Node, Node, Expression, Variable, Type> _typeAnalyzer;

  @override
  final Node node;

  _PatternDispatchResultImpl(this._typeAnalyzer, this.node);
}

class _VariablePatternDispatchResult<Node extends Object,
        Expression extends Node, Variable extends Object, Type extends Object>
    extends _PatternDispatchResultImpl<Node, Expression, Variable, Type> {
  final Variable _variable;

  final Type? _declaredType;

  _VariablePatternDispatchResult(
      super._typeAnalyzer, super.node, this._variable, this._declaredType);

  @override
  Type get typeSchema => _declaredType ?? _typeAnalyzer.unknownType;

  @override
  void match(Type matchedType, VariableBindings<Node, Variable, Type> bindings,
      {required bool isFinal, required bool isLate, Expression? initializer}) {
    Type inferredType = _declaredType ??
        _typeAnalyzer.variableTypeFromInitializerType(matchedType);
    bool isImplicitlyTyped = _declaredType == null;
    bool added = bindings.add(node, _variable,
        inferredType: inferredType, isImplicitlyTyped: isImplicitlyTyped);
    if (added) {
      _typeAnalyzer.flow?.declare(_variable, false);
      _typeAnalyzer.setVariableType(_variable, inferredType);
      _typeAnalyzer.flow?.initialize(_variable, matchedType, initializer,
          isFinal: isFinal,
          isLate: isLate,
          isImplicitlyTyped: isImplicitlyTyped);
    }
    _typeAnalyzer.handleVariablePattern(node, added ? inferredType : null);
  }
}
