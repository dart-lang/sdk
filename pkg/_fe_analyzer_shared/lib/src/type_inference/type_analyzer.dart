// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../flow_analysis/flow_analysis.dart';
import 'type_analysis_result.dart';
import 'type_operations.dart';

/// Information supplied by the client to [TypeAnalyzer.analyzeSwitchExpression]
/// or [TypeAnalyzer.analyzeSwitchStatement] about a single case head or
/// `default` clause.
///
/// The client is free to `implement` or `extend` this class.
class CaseHeadOrDefaultInfo<Node extends Object, Expression extends Node> {
  /// For a `case` clause, the case pattern.  For a `default` clause, `null`.
  final Node? pattern;

  /// For a `case` clause that has a guard clause, the expression following
  /// `when`.  Otherwise `null`.
  final Expression? guard;

  CaseHeadOrDefaultInfo({required this.pattern, this.guard});
}

/// Information supplied by the client to [TypeAnalyzer.analyzeSwitchExpression]
/// about an individual `case` or `default` clause.
///
/// The client is free to `implement` or `extend` this class.
class SwitchExpressionMemberInfo<Node extends Object, Expression extends Node> {
  /// The [CaseOrDefaultHead] associated with this clause.
  final CaseHeadOrDefaultInfo<Node, Expression> head;

  /// The body of the `case` or `default` clause.
  final Expression expression;

  SwitchExpressionMemberInfo({required this.head, required this.expression});
}

/// Information supplied by the client to [TypeAnalyzer.analyzeSwitchStatement]
/// about an individual `case` or `default` clause.
///
/// The client is free to `implement` or `extend` this class.
class SwitchStatementMemberInfo<Node extends Object, Statement extends Node,
    Expression extends Node> {
  /// The list of case heads for this case.
  ///
  /// The reason this is a list rather than a single head is because the front
  /// end merges together cases that share a body at parse time.
  final List<CaseHeadOrDefaultInfo<Node, Expression>> heads;

  /// The labels preceding this `case` or `default` clause, if any.
  final List<Node> labels;

  /// The statements following this `case` or `default` clause.  If this list is
  /// empty, and this is not the last `case` or `default` clause, this clause
  /// will be considered to share a body with the `case` or `default` clause
  /// that follows.
  final List<Statement> body;

  SwitchStatementMemberInfo(this.heads, this.body, {this.labels = const []});
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
///
/// Note that calling an `analyzeX` method is guaranteed to call `dispatch` on
/// all its subexpressions.  However, we don't specify the precise order in
/// which this will happen, nor do we always specify which callbacks will be
/// invoked during analysis, because these details are considered part of the
/// implementation of type analysis, not its API.  Instead, we specify the
/// effect that each method has on a conceptual "stack" of entities.
///
/// In documentation, the entities in the stack are listed in low-to-high order.
/// So, for example, if the documentation says the stack contains "(K, L)", then
/// an entity of kind L is on the top of the stack, with an entity of kind K
/// under it.  This low-to-high order is used when describing pushes and pops
/// too, so, for example a method documented with "pushes (K, L)" pushes K
/// first, then L, whereas a method documented with "pops (K, L)" pops L first,
/// then K.
///
/// In the paragraph above, "K" and "L" are just variables for illustrating the
/// conventions.  The actual kinds used by the analyzer are concepts from the
/// language itself such as "Statement", "Expression", "Pattern", etc.  See the
/// `Kind` enum in `test/mini_ir.dart` for a discussion of all possible kinds of
/// stack entries.
///
/// If multiple stack entries share a kind, we will sometimes add a name to
/// clarify which stack entry is which, e.g. analyzeIfStatement pushes
/// "(Expression condition, Statement ifTrue, Statement ifFalse)".
///
/// We'll also use the convention that "n * K" represents n consecutive entities
/// in the stack, each with kind K.
///
/// The kind associated with all pushes and pops is statically known (and
/// documented, and unit tested), and entities never change from one kind to
/// another.  This fact gives the client considerable freedom in how to actually
/// represent the stack in practice; for example, they might choose to ignore
/// some kinds entirely, or represent certain kinds with a block of multiple
/// stack entries instead of just one.  Or they might choose to multiple stacks,
/// one for each kind.  It's also possible that some clients won't need to keep
/// a stack at all.
///
/// Reasons a client might want to actually have a stack include:
/// - Constructing a lowered intermediate representation of the code as a side
///   effect of analysis,
/// - Building up a symbolic representation of the program's runtime behavior,
/// - Or keeping track of AST nodes that need to be replaced (e.g. replacing an
///   `integer literal` node with a `double literal` node when int->double
///   conversion happens).
///
/// The unit tests in the `_fe_analyzer_shared` package associate a simple
/// intermediate representation with each stack entry, and also record the kind
/// of each entry in order to verify that when an entity is popped, it has the
/// expected kind.
mixin TypeAnalyzer<Node extends Object, Statement extends Node,
    Expression extends Node, Variable extends Object, Type extends Object> {
  /// Returns the type `bool`.
  Type get boolType;

  /// Returns the type `double`.
  Type get doubleType;

  /// Returns the type `dynamic`.
  Type get dynamicType;

  TypeAnalyzerErrors<Node, Statement, Expression, Variable, Type>? get errors;

  /// Returns the client's [FlowAnalysis] object.
  ///
  /// May be `null`, because the analyzer doesn't have a flow analysis object
  /// in play when analyzing top level initializers (see
  /// https://github.com/dart-lang/sdk/issues/49701).
  FlowAnalysis<Node, Statement, Expression, Variable, Type>? get flow;

  /// Returns the type `int`.
  Type get intType;

  /// Returns the type `Object?`.
  Type get objectQuestionType;

  /// Options affecting the behavior of [TypeAnalyzer].
  TypeAnalyzerOptions get options;

  /// Returns the client's implementation of the [TypeOperations] class.
  TypeOperations2<Type> get typeOperations;

  /// Returns the unknown type context (`?`) used in type inference.
  Type get unknownType;

  /// Analyzes a cast pattern.  [innerPattern] is the sub-pattern] and [type] is
  /// the type to cast to.
  ///
  /// See [dispatchPattern] for the meanings of [matchedType], [typeInfos], and
  /// [context].
  ///
  /// Stack effect: pushes (Pattern innerPattern).
  void analyzeCastPattern(
      Type matchedType,
      Map<Variable, VariableTypeInfo<Node, Type>> typeInfos,
      MatchContext<Node, Expression> context,
      Node innerPattern,
      Type type) {
    dispatchPattern(type, typeInfos, context, innerPattern);
    // Stack: (Pattern)
  }

  /// Computes the type schema for a cast pattern.
  ///
  /// Stack effect: none.
  Type analyzeCastPatternSchema() => objectQuestionType;

  /// Analyzes a constant pattern.  [node] is the pattern itself, and
  /// [expression] is the constant expression.  Depending on the client's
  /// representation, [node] and [expression] might or might not be identical.
  ///
  /// See [dispatchPattern] for the meanings of [matchedType], [typeInfos], and
  /// [context].
  ///
  /// Stack effect: pushes (Expression).
  void analyzeConstantPattern(
      Type matchedType,
      Map<Variable, VariableTypeInfo<Node, Type>> typeInfos,
      MatchContext<Node, Expression> context,
      Node node,
      Expression expression) {
    // Stack: ()
    TypeAnalyzerErrors<Node, Node, Expression, Variable, Type>? errors =
        this.errors;
    Node? irrefutableContext = context.irrefutableContext;
    if (irrefutableContext != null) {
      errors?.refutablePatternInIrrefutableContext(node, irrefutableContext);
    }
    Type staticType = analyzeExpression(expression, matchedType);
    // Stack: (Expression)
    if (errors != null && !options.patternsEnabled) {
      Expression? switchScrutinee = context.getSwitchScrutinee(node);
      if (switchScrutinee != null) {
        bool nullSafetyEnabled = options.nullSafetyEnabled;
        bool matches = nullSafetyEnabled
            ? typeOperations.isSubtypeOf(staticType, matchedType)
            : typeOperations.isAssignableTo(staticType, matchedType);
        if (!matches) {
          errors.caseExpressionTypeMismatch(
              caseExpression: expression,
              scrutinee: switchScrutinee,
              caseExpressionType: staticType,
              scrutineeType: matchedType,
              nullSafetyEnabled: nullSafetyEnabled);
        }
      }
    }
  }

  /// Computes the type schema for a constant pattern.
  ///
  /// Stack effect: none.
  Type analyzeConstantPatternSchema() {
    // Constant patterns are only allowed in refutable contexts, and refutable
    // contexts don't propagate a type schema into the scrutinee.  So this
    // code path is only reachable if the user's code contains errors.
    errors?.assertInErrorRecovery();
    return unknownType;
  }

  /// Analyzes an expression.  [node] is the expression to analyze, and
  /// [context] is the type schema which should be used for type inference.
  ///
  /// Stack effect: pushes (Expression).
  Type analyzeExpression(Expression node, Type? context) {
    // Stack: ()
    if (context == null || typeOperations.isDynamic(context)) {
      context = unknownType;
    }
    ExpressionTypeAnalysisResult<Type> result =
        dispatchExpression(node, context);
    // Stack: (Expression)
    if (typeOperations.isNever(result.provisionalType)) {
      flow?.handleExit();
    }
    return result.resolveShorting();
  }

  /// Analyzes a statement of the form `if (expression case pattern) ifTrue` or
  /// `if (expression case pattern) ifTrue else ifFalse`.
  ///
  /// [node] should be the AST node for the entire statement, [expression] for
  /// the expression, [pattern] for the pattern to match, [ifTrue] for the
  /// "then" branch, and [ifFalse] for the "else" branch (if present).
  ///
  /// Stack effect: pushes (Expression scrutinee, Pattern, Expression guard,
  /// Statement ifTrue, Statement ifFalse).  If there is no `else` clause, the
  /// representation for `ifFalse` will be pushed by [handleNoStatement].  If
  /// there is no guard, the representation for `guard` will be pushed by
  /// [handleNoGuard].
  void analyzeIfCaseStatement(Statement node, Expression expression,
      Node pattern, Expression? guard, Statement ifTrue, Statement? ifFalse) {
    // Stack: ()
    flow?.ifStatement_conditionBegin();
    Type initializerType = analyzeExpression(expression, unknownType);
    // Stack: (Expression)
    Map<Variable, VariableTypeInfo<Node, Type>> typeInfos = {};
    // TODO(paulberry): rework handling of isFinal
    dispatchPattern(initializerType, typeInfos,
        new MatchContext(isFinal: false, topPattern: pattern), pattern);
    // Stack: (Expression, Pattern)
    if (guard != null) {
      _checkGuardType(guard, analyzeExpression(guard, boolType));
    } else {
      handleNoGuard(node, 0);
    }
    // Stack: (Expression, Pattern, Guard)
    flow?.ifStatement_thenBegin(null, node);
    _analyzeIfCommon(node, ifTrue, ifFalse);
  }

  /// Analyzes a statement of the form `if (condition) ifTrue` or
  /// `if (condition) ifTrue else ifFalse`.
  ///
  /// [node] should be the AST node for the entire statement, [condition] for
  /// the condition expression, [ifTrue] for the "then" branch, and [ifFalse]
  /// for the "else" branch (if present).
  ///
  /// Stack effect: pushes (Expression condition, Statement ifTrue, Statement
  /// ifFalse).  Note that if there is no `else` clause, the representation for
  /// `ifFalse` will be pushed by [handleNoStatement].
  void analyzeIfStatement(Statement node, Expression condition,
      Statement ifTrue, Statement? ifFalse) {
    // Stack: ()
    flow?.ifStatement_conditionBegin();
    analyzeExpression(condition, boolType);
    handle_ifStatement_conditionEnd(node);
    // Stack: (Expression condition)
    flow?.ifStatement_thenBegin(condition, node);
    _analyzeIfCommon(node, ifTrue, ifFalse);
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
  /// Stack effect: pushes (Expression, Pattern).
  void analyzeInitializedVariableDeclaration(
      Node node, Node pattern, Expression initializer,
      {required bool isFinal, required bool isLate}) {
    // Stack: ()
    if (isLate && !isVariablePattern(pattern)) {
      errors?.patternDoesNotAllowLate(pattern);
    }
    if (isLate) {
      flow?.lateInitializer_begin(node);
    }
    Type initializerType =
        analyzeExpression(initializer, dispatchPatternSchema(pattern));
    // Stack: (Expression)
    if (isLate) {
      flow?.lateInitializer_end();
    }
    Map<Variable, VariableTypeInfo<Node, Type>> typeInfos = {};
    dispatchPattern(
        initializerType,
        typeInfos,
        new MatchContext(
            isFinal: isFinal,
            isLate: isLate,
            initializer: initializer,
            irrefutableContext: node,
            topPattern: pattern),
        pattern);
    // Stack: (Expression, Pattern)
  }

  /// Analyzes an integer literal, given the type context [context].
  ///
  /// Stack effect: none.
  IntTypeAnalysisResult<Type> analyzeIntLiteral(Type context) {
    bool convertToDouble = !typeOperations.isSubtypeOf(intType, context) &&
        typeOperations.isSubtypeOf(doubleType, context);
    Type type = convertToDouble ? doubleType : intType;
    return new IntTypeAnalysisResult<Type>(
        type: type, convertedToDouble: convertToDouble);
  }

  /// Analyzes a list pattern.  [node] is the pattern itself, [elementType] is
  /// the list element type (if explicitly supplied), and [elements] is the
  /// list of subpatterns.
  ///
  /// See [dispatchPattern] for the meanings of [matchedType], [typeInfos], and
  /// [context].
  ///
  /// Stack effect: pushes (n * Pattern) where n = elements.length.
  Type analyzeListPattern(
      Type matchedType,
      Map<Variable, VariableTypeInfo<Node, Type>> typeInfos,
      MatchContext<Node, Expression> context,
      Node node,
      {Type? elementType,
      required List<Node> elements}) {
    // Stack: ()
    Type? matchedElementType = typeOperations.matchListType(matchedType);
    if (matchedElementType == null) {
      if (typeOperations.isDynamic(matchedType)) {
        matchedElementType = dynamicType;
      } else {
        matchedElementType = objectQuestionType;
      }
    }
    for (Node element in elements) {
      dispatchPattern(matchedElementType, typeInfos, context, element);
    }
    // Stack: (n * Pattern) where n = elements.length
    Type requiredType = listType(elementType ?? matchedElementType);
    Node? irrefutableContext = context.irrefutableContext;
    if (irrefutableContext != null &&
        !typeOperations.isAssignableTo(matchedType, requiredType)) {
      errors?.patternTypeMismatchInIrrefutableContext(
          pattern: node,
          context: irrefutableContext,
          matchedType: matchedType,
          requiredType: requiredType);
    }
    return requiredType;
  }

  /// Computes the type schema for a list pattern.  [elementType] is the list
  /// element type (if explicitly supplied), and [elements] is the list of
  /// subpatterns.
  ///
  /// Stack effect: none.
  Type analyzeListPatternSchema(
      {Type? elementType, required List<Node> elements}) {
    if (elementType == null) {
      if (elements.isEmpty) {
        return objectQuestionType;
      }
      elementType = dispatchPatternSchema(elements[0]);
      for (int i = 1; i < elements.length; i++) {
        elementType = typeOperations.glb(
            elementType!, dispatchPatternSchema(elements[i]));
      }
    }
    return listType(elementType!);
  }

  /// Analyzes a logical-or or logical-and pattern.  [node] is the pattern
  /// itself, and [lhs] and [rhs] are the left and right sides of the `|` or `&`
  /// operator.  [isAnd] indicates whether [node] is a logical-or or a
  /// logical-and.
  ///
  /// See [dispatchPattern] for the meanings of [matchedType], [typeInfos], and
  /// [context].
  ///
  /// Stack effect: pushes (Pattern left, Pattern right)
  void analyzeLogicalPattern(
      Type matchedType,
      Map<Variable, VariableTypeInfo<Node, Type>> typeInfos,
      MatchContext<Node, Expression> context,
      Node node,
      Node lhs,
      Node rhs,
      {required bool isAnd}) {
    // Stack: ()
    if (!isAnd) {
      Node? irrefutableContext = context.irrefutableContext;
      if (irrefutableContext != null) {
        errors?.refutablePatternInIrrefutableContext(node, irrefutableContext);
        // Avoid cascading errors
        context = context.makeRefutable();
      }
    }
    dispatchPattern(matchedType, typeInfos, context, lhs);
    // Stack: (Pattern left)
    dispatchPattern(matchedType, typeInfos, context, rhs);
    // Stack: (Pattern left, Pattern right)
  }

  /// Computes the type schema for a logical-or or logical-and pattern.  [lhs]
  /// and [rhs] are the left and right sides of the `|` or `&` operator.
  /// [isAnd] indicates whether [node] is a logical-or or a logical-and.
  ///
  /// Stack effect: none.
  Type analyzeLogicalPatternSchema(Node lhs, Node rhs, {required bool isAnd}) {
    if (isAnd) {
      return typeOperations.glb(
          dispatchPatternSchema(lhs), dispatchPatternSchema(rhs));
    } else {
      // Logical-or patterns are only allowed in refutable contexts, and
      // refutable contexts don't propagate a type schema into the scrutinee.
      // So this code path is only reachable if the user's code contains errors.
      errors?.assertInErrorRecovery();
      return unknownType;
    }
  }

  /// Analyzes a null-check or null-assert pattern.  [node] is the pattern
  /// itself, [innerPattern] is the sub-pattern, and [isAssert] indicates
  /// whether this is a null-check or a null-assert pattern.
  ///
  /// See [dispatchPattern] for the meanings of [matchedType], [typeInfos], and
  /// [context].
  ///
  /// Stack effect: pushes (Pattern innerPattern).
  void analyzeNullCheckOrAssertPattern(
      Type matchedType,
      Map<Variable, VariableTypeInfo<Node, Type>> typeInfos,
      MatchContext<Node, Expression> context,
      Node node,
      Node innerPattern,
      {required bool isAssert}) {
    // Stack: ()
    Type innerMatchedType = typeOperations.promoteToNonNull(matchedType);
    Node? irrefutableContext = context.irrefutableContext;
    if (irrefutableContext != null && !isAssert) {
      errors?.refutablePatternInIrrefutableContext(node, irrefutableContext);
      // Avoid cascading errors
      context = context.makeRefutable();
    }
    dispatchPattern(innerMatchedType, typeInfos, context, innerPattern);
    // Stack: (Pattern)
  }

  /// Computes the type schema for a null-check or null-assert pattern.
  /// [innerPattern] is the sub-pattern and [isAssert] indicates whether this is
  /// a null-check or a null-assert pattern.
  ///
  /// Stack effect: none.
  Type analyzeNullCheckOrAssertPatternSchema(Node innerPattern,
      {required bool isAssert}) {
    if (isAssert) {
      return typeOperations.makeNullable(dispatchPatternSchema(innerPattern));
    } else {
      // Null-check patterns are only allowed in refutable contexts, and
      // refutable contexts don't propagate a type schema into the scrutinee.
      // So this code path is only reachable if the user's code contains errors.
      errors?.assertInErrorRecovery();
      return unknownType;
    }
  }

  /// Analyzes an expression of the form `switch (expression) { cases }`.
  ///
  /// Stack effect: pushes (Expression, n * ExpressionCase), where n is the
  /// number of cases.
  SimpleTypeAnalysisResult<Type> analyzeSwitchExpression(
      Expression node, Expression scrutinee, int numCases, Type context) {
    // Stack: ()
    Type expressionType = analyzeExpression(scrutinee, unknownType);
    // Stack: (Expression)
    handleSwitchScrutinee(expressionType);
    flow?.switchStatement_expressionEnd(null);
    Type? lubType;
    for (int i = 0; i < numCases; i++) {
      // Stack: (Expression, i * ExpressionCase)
      SwitchExpressionMemberInfo<Node, Expression> memberInfo =
          getSwitchExpressionMemberInfo(node, i);
      flow?.switchStatement_beginCase();
      Map<Variable, VariableTypeInfo<Node, Type>> typeInfos = {};
      Node? pattern = memberInfo.head.pattern;
      if (pattern != null) {
        dispatchPattern(
            expressionType,
            typeInfos,
            new MatchContext<Node, Expression>(
                isFinal: false,
                switchScrutinee: scrutinee,
                topPattern: pattern),
            pattern);
        // Stack: (Expression, i * ExpressionCase, Pattern)
        Expression? guard = memberInfo.head.guard;
        bool hasGuard = guard != null;
        if (hasGuard) {
          _checkGuardType(guard, analyzeExpression(guard, boolType));
          // Stack: (Expression, i * ExpressionCase, Pattern, Expression)
          flow?.switchStatement_afterGuard(guard);
        } else {
          handleNoGuard(node, i);
          // Stack: (Expression, i * ExpressionCase, Pattern, Expression)
        }
        handleCaseHead(node, caseIndex: i, subIndex: 0);
      } else {
        handleDefault(node, i);
      }
      // Stack: (Expression, i * ExpressionCase, CaseHead)
      Type type = analyzeExpression(memberInfo.expression, context);
      // Stack: (Expression, i * ExpressionCase, CaseHead, Expression)
      if (lubType == null) {
        lubType = type;
      } else {
        lubType = typeOperations.lub(lubType, type);
      }
      finishExpressionCase(node, i);
      // Stack: (Expression, (i + 1) * ExpressionCase)
    }
    // Stack: (Expression, numCases * ExpressionCase)
    flow?.switchStatement_end(true);
    return new SimpleTypeAnalysisResult<Type>(type: lubType!);
  }

  /// Analyzes a statement of the form `switch (expression) { cases }`.
  ///
  /// Stack effect: pushes (Expression, n * StatementCase), where n is the
  /// number of cases after merging together cases that share a body.
  SwitchStatementTypeAnalysisResult<Type> analyzeSwitchStatement(
      Statement node, Expression scrutinee, int numCases) {
    // Stack: ()
    Type scrutineeType = analyzeExpression(scrutinee, unknownType);
    // Stack: (Expression)
    handleSwitchScrutinee(scrutineeType);
    flow?.switchStatement_expressionEnd(node);
    int numExecutionPaths = 0;
    int i = 0;
    bool hasDefault = false;
    bool lastCaseTerminates = true;
    while (i < numCases) {
      // Stack: (Expression, numExecutionPaths * StatementCase)
      int firstCaseInThisExecutionPath = i;
      int numHeads = 0;
      Map<Variable, VariableTypeInfo<Node, Type>> typeInfos = {};
      flow?.switchStatement_beginCase();
      flow?.switchStatement_beginAlternatives();
      bool hasLabels = false;
      List<Statement> body = const [];
      while (i < numCases) {
        // Stack: (Expression, numExecutionPaths * StatementCase,
        //         numHeads * CaseHead)
        SwitchStatementMemberInfo<Node, Statement, Expression> memberInfo =
            getSwitchStatementMemberInfo(node, i);
        if (memberInfo.labels.isNotEmpty) {
          hasLabels = true;
        }
        List<CaseHeadOrDefaultInfo<Node, Expression>> heads = memberInfo.heads;
        for (int j = 0; j < heads.length; j++) {
          CaseHeadOrDefaultInfo<Node, Expression> head = heads[j];
          Node? pattern = head.pattern;
          if (pattern != null) {
            dispatchPattern(
                scrutineeType,
                typeInfos,
                new MatchContext<Node, Expression>(
                    isFinal: false,
                    switchScrutinee: scrutinee,
                    topPattern: pattern),
                pattern);
            // Stack: (Expression, numExecutionPaths * StatementCase,
            //         numHeads * CaseHead, Pattern),
            Expression? guard = head.guard;
            bool hasGuard = guard != null;
            if (hasGuard) {
              _checkGuardType(guard, analyzeExpression(guard, boolType));
              // Stack: (Expression, numExecutionPaths * StatementCase,
              //         numHeads * CaseHead, Pattern, Expression),
              flow?.switchStatement_afterGuard(guard);
            } else {
              handleNoGuard(node, i);
            }
            handleCaseHead(node, caseIndex: i, subIndex: j);
          } else {
            hasDefault = true;
            handleDefault(node, i);
          }
          numHeads++;
          // Stack: (Expression, numExecutionPaths * StatementCase,
          //         numHeads * CaseHead),
          flow?.switchStatement_endAlternative();
          body = memberInfo.body;
        }
        i++;
        if (body.isNotEmpty) break;
      }
      // Stack: (Expression, numExecutionPaths * StatementCase,
      //         numHeads * CaseHead)
      flow?.switchStatement_endAlternatives(node, hasLabels: hasLabels);
      handleCase_afterCaseHeads(node, firstCaseInThisExecutionPath, numHeads);
      // Stack: (Expression, numExecutionPaths * StatementCase, CaseHeads)
      for (Statement statement in body) {
        dispatchStatement(statement);
      }
      // Stack: (Expression, numExecutionPaths * StatementCase, CaseHeads,
      //         n * Statement), where n = body.length
      lastCaseTerminates = flow == null || !flow!.isReachable;
      if (i < numCases &&
          options.nullSafetyEnabled &&
          !options.patternsEnabled &&
          !lastCaseTerminates) {
        errors?.switchCaseCompletesNormally(node, firstCaseInThisExecutionPath,
            i - firstCaseInThisExecutionPath);
      }
      handleMergedStatementCase(node,
          caseIndex: i - 1,
          executionPathIndex: numExecutionPaths,
          numStatements: body.length);
      // Stack: (Expression, (numExecutionPaths + 1) * StatementCase)
      hasLabels = false;
      numExecutionPaths++;
    }
    // Stack: (Expression, numExecutionPaths * StatementCase)
    bool isExhaustive = hasDefault || isSwitchExhaustive(node, scrutineeType);
    flow?.switchStatement_end(isExhaustive);
    return new SwitchStatementTypeAnalysisResult<Type>(
        hasDefault: hasDefault,
        isExhaustive: isExhaustive,
        lastCaseTerminates: lastCaseTerminates,
        numExecutionPaths: numExecutionPaths,
        scrutineeType: scrutineeType);
  }

  /// Analyzes a variable declaration of the form `type variable;` or
  /// `var variable;`.
  ///
  /// [node] should be the AST node for the entire declaration, [variable] for
  /// the variable, and [declaredType] for the type (if present).  [isFinal] and
  /// [isLate] indicate whether this is a final declaration and/or a late
  /// declaration, respectively.
  ///
  /// Stack effect: none.
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
  /// the variable, [declaredType] is the explicitly declared type (if present),
  /// and [isFinal] indicates whether the variable is final.
  ///
  /// See [dispatchPattern] for the meanings of [matchedType], [typeInfos], and
  /// [context].
  ///
  /// If this is a wildcard pattern (it doesn't bind any variable), [variable]
  /// should be `null`.
  ///
  /// Stack effect: none.
  Type analyzeVariablePattern(
      Type matchedType,
      Map<Variable, VariableTypeInfo<Node, Type>> typeInfos,
      MatchContext<Node, Expression> context,
      Node node,
      Variable? variable,
      Type? declaredType,
      {required bool isFinal}) {
    Type staticType =
        declaredType ?? variableTypeFromInitializerType(matchedType);
    Node? irrefutableContext = context.irrefutableContext;
    if (irrefutableContext != null &&
        !typeOperations.isAssignableTo(matchedType, staticType)) {
      errors?.patternTypeMismatchInIrrefutableContext(
          pattern: node,
          context: irrefutableContext,
          matchedType: matchedType,
          requiredType: staticType);
    }
    bool isImplicitlyTyped = declaredType == null;
    if (variable != null) {
      bool isFirstMatch = _recordTypeInfo(typeInfos,
          pattern: node,
          variable: variable,
          staticType: staticType,
          isImplicitlyTyped: isImplicitlyTyped);
      if (isFirstMatch) {
        flow?.declare(variable, false);
        setVariableType(variable, staticType);
        // TODO(paulberry): are we handling _isFinal correctly?
        // TODO(paulberry): do we need to verify that all instances of a
        // variable are final or all are not final?
        flow?.initialize(variable, matchedType, context.getInitializer(node),
            isFinal: context.isFinal || isFinal,
            isLate: context.isLate,
            isImplicitlyTyped: isImplicitlyTyped);
      }
    }
    return staticType;
  }

  /// Computes the type schema for a variable pattern.  [declaredType] is the
  /// explicitly declared type (if present).
  ///
  /// Stack effect: none.
  Type analyzeVariablePatternSchema(Type? declaredType) =>
      declaredType ?? unknownType;

  /// Calls the appropriate `analyze` method according to the form of
  /// [expression], and then adjusts the stack as needed to combine any
  /// sub-structures into a single expression.
  ///
  /// For example, if [node] is a binary expression (`a + b`), calls
  /// [analyzeBinaryExpression].
  ///
  /// Stack effect: pushes (Expression).
  ExpressionTypeAnalysisResult<Type> dispatchExpression(
      Expression node, Type context);

  /// Calls the appropriate `analyze` method according to the form of [pattern].
  ///
  /// [matchedType] is the type of the thing being matched (for a variable
  /// declaration, this is the type of the initializer or substructure thereof;
  /// for a switch statement this is the type of the scrutinee or substructure
  /// thereof).
  ///
  /// [typeInfos] is a data structure keeping track of the variable patterns
  /// seen so far and their type information.
  ///
  /// [context] keeps track of other contextual information pertinent to the
  /// match, such as whether it is late and/or final, whether there is an
  /// initializer expression (and if so, what it is), and whether the match is
  /// happening in an irrefutable context (and if so, what surrounding construct
  /// causes it to be irrefutable).
  ///
  /// Stack effect: pushes (Pattern).
  void dispatchPattern(
      Type matchedType,
      Map<Variable, VariableTypeInfo<Node, Type>> typeInfos,
      MatchContext<Node, Expression> context,
      Node node);

  /// Calls the appropriate `analyze...Schema` method according to the form of
  /// [pattern].
  ///
  /// Stack effect: none.
  Type dispatchPatternSchema(Node pattern);

  /// Calls the appropriate `analyze` method according to the form of
  /// [statement], and then adjusts the stack as needed to combine any
  /// sub-structures into a single statement.
  ///
  /// For example, if [statement] is a `while` loop, calls [analyzeWhileLoop].
  ///
  /// Stack effect: pushes (Statement).
  void dispatchStatement(Statement statement);

  /// Called after visiting an expression case.
  ///
  /// [node] is the enclosing switch expression, and [caseIndex] is the index of
  /// this code path within the switch expression's cases.
  ///
  /// Stack effect: pops (CaseHead, Expression) and pushes (ExpressionCase).
  void finishExpressionCase(Expression node, int caseIndex);

  /// Returns an [ExpressionCaseInfo] object describing the [index]th `case` or
  /// `default` clause in the switch expression [node].
  ///
  /// Note: it is allowed for the client's AST nodes for `case` and `default`
  /// clauses to implement [ExpressionCaseInfo], in which case this method can
  /// simply return the [index]th `case` or `default` clause.
  ///
  /// See [analyzeSwitchExpression].
  SwitchExpressionMemberInfo<Node, Expression> getSwitchExpressionMemberInfo(
      Expression node, int index);

  /// Returns a [StatementCaseInfo] object describing the [index]th `case` or
  /// `default` clause in the switch statement [node].
  ///
  /// Note: it is allowed for the client's AST nodes for `case` and `default`
  /// clauses to implement [StatementCaseInfo], in which case this method can
  /// simply return the [index]th `case` or `default` clause.
  ///
  /// See [analyzeSwitchStatement].
  SwitchStatementMemberInfo<Node, Statement, Expression>
      getSwitchStatementMemberInfo(Statement node, int caseIndex);

  /// Called after visiting the expression of an `if` statement.
  void handle_ifStatement_conditionEnd(Statement node) {}

  /// Called after visiting the `else` statement of an `if` statement.
  void handle_ifStatement_elseEnd(Statement node, Statement ifFalse) {}

  /// Called after visiting the `then` statement of an `if` statement.
  void handle_ifStatement_thenEnd(Statement node, Statement ifTrue) {}

  /// Called after visiting a merged set of `case` / `default` clauses.
  ///
  /// [node] is the enclosing switch statement, [caseIndex] is the index of the
  /// first `case` / `default` clause to be merged, and [numHeads] is the number
  /// of `case` / `default` clauses to be merged.
  ///
  /// Stack effect: pops (numHeads * CaseHead) and pushes (CaseHeads).
  void handleCase_afterCaseHeads(Statement node, int caseIndex, int numHeads);

  /// Called after visiting a single `case` clause, consisting of a pattern and
  /// an optional guard.
  ///
  /// [node] is the enclosing switch statement or switch expression and
  /// [caseIndex] is the index of the `case` clause.
  ///
  /// Stack effect: pops (Pattern, Expression) and pushes (CaseHead).
  void handleCaseHead(Node node,
      {required int caseIndex, required int subIndex});

  /// Called after visiting a `default` clause.
  ///
  /// [node] is the enclosing switch statement or switch expression and
  /// [caseIndex] is the index of the `default` clause.
  ///
  /// Stack effect: pushes (CaseHead).
  void handleDefault(Node node, int caseIndex);

  /// Called after visiting a merged statement case.
  ///
  /// [node] is enclosing switch statement, [caseIndex] is the index of the last
  /// `case` or `default` clause in the merged statement case, and
  /// [numStatements] is the number of statements in the case body.
  ///
  /// Stack effect: pops (CaseHeads, numStatements * Statement) and pushes
  /// (StatementCase).
  void handleMergedStatementCase(Statement node,
      {required int caseIndex,
      required int executionPathIndex,
      required int numStatements});

  /// Called when visiting a `case` that lacks a guard clause.  Since the lack
  /// of a guard clause is semantically equivalent to `when true`, this method
  /// should behave similarly to visiting the boolean literal `true`.
  ///
  /// [node] is the enclosing switch statement, switch expression, or `if`, and
  /// [caseIndex] is the index of the `case` within [node].
  ///
  /// Stack effect: pushes (Expression).
  void handleNoGuard(Node node, int caseIndex);

  /// Called when visiting a syntactic construct where there is an implicit
  /// no-op statement.  For example, this is called in place of the missing
  /// `else` part of an `if` statement that lacks an `else` clause.
  ///
  /// Stack effect: pushes (Statement).
  void handleNoStatement(Statement node);

  /// Called after visiting the scrutinee part of a switch statement or switch
  /// expression.  This is a hook to allow the client to start exhaustiveness
  /// analysis.
  ///
  /// [type] is the static type of the scrutinee expression.
  ///
  /// TODO(paulberry): move exhaustiveness analysis into the shared code and
  /// eliminate this method.
  ///
  /// Stack effect: none.
  void handleSwitchScrutinee(Type type);

  /// Queries whether the switch statement or expression represented by [node]
  /// was exhaustive.  [expressionType] is the static type of the scrutinee.
  ///
  /// Will only be called if the switch statement or expression lacks a
  /// `default` clause.
  bool isSwitchExhaustive(Node node, Type expressionType);

  /// Queries whether [pattern] is a variable pattern.
  bool isVariablePattern(Node pattern);

  /// Returns the type `List`, with type parameter [elementType].
  Type listType(Type elementType);

  /// Records that type inference has assigned a [type] to a [variable].  This
  /// is called once per variable, regardless of whether the variable's type is
  /// explicit or inferred.
  void setVariableType(Variable variable, Type type);

  /// Computes the type that should be inferred for an implicitly typed variable
  /// whose initializer expression has static type [type].
  Type variableTypeFromInitializerType(Type type);

  /// Common functionality shared by [analyzeIfStatement] and
  /// [analyzeIfCaseStatement].
  ///
  /// Stack effect: pushes (Statement ifTrue, Statement ifFalse).
  void _analyzeIfCommon(Statement node, Statement ifTrue, Statement? ifFalse) {
    // Stack: ()
    dispatchStatement(ifTrue);
    handle_ifStatement_thenEnd(node, ifTrue);
    // Stack: (Statement ifTrue)
    if (ifFalse == null) {
      handleNoStatement(node);
      flow?.ifStatement_end(false);
    } else {
      flow?.ifStatement_elseBegin();
      dispatchStatement(ifFalse);
      flow?.ifStatement_end(true);
      handle_ifStatement_elseEnd(node, ifFalse);
    }
    // Stack: (Statement ifTrue, Statement ifFalse)
  }

  void _checkGuardType(Expression expression, Type type) {
    // TODO(paulberry): harmonize this with analyzer's checkForNonBoolExpression
    // TODO(paulberry): spec says the type must be `bool` or `dynamic`.  This
    // logic permits `T extends bool`, `T promoted to bool`, or `Never`.  What
    // do we want?
    if (!typeOperations.isAssignableTo(type, boolType)) {
      errors?.nonBooleanCondition(expression);
    }
  }

  /// Records in [typeInfos] that a [pattern] binds a [variable] with a given
  /// [staticType], and reports any errors caused by type inconsistency.
  /// [isImplicitlyTyped] indicates whether the variable is implicitly typed in
  /// this pattern.
  bool _recordTypeInfo(Map<Variable, VariableTypeInfo<Node, Type>> typeInfos,
      {required Node pattern,
      required Variable variable,
      required Type staticType,
      required bool isImplicitlyTyped}) {
    VariableTypeInfo<Node, Type>? typeInfo = typeInfos[variable];
    if (typeInfo == null) {
      typeInfos[variable] =
          new VariableTypeInfo(pattern, staticType, isImplicitlyTyped);
      return true;
    } else {
      TypeAnalyzerErrors<Node, Statement, Expression, Variable, Type>? errors =
          this.errors;
      if (errors != null) {
        if (!typeOperations.isSameType(
            typeInfo._latestStaticType, staticType)) {
          errors.inconsistentMatchVar(
              pattern: pattern,
              type: staticType,
              previousPattern: typeInfo._latestPattern,
              previousType: typeInfo._latestStaticType);
        } else if (typeInfo._isImplicitlyTyped != isImplicitlyTyped) {
          errors.inconsistentMatchVarExplicitness(
              pattern: pattern, previousPattern: typeInfo._latestPattern);
        }
      }
      typeInfo._latestStaticType = staticType;
      typeInfo._latestPattern = pattern;
      typeInfo._isImplicitlyTyped = isImplicitlyTyped;
      return false;
    }
  }
}

/// Interface used by the shared [TypeAnalyzer] logic to report error conditions
/// up to the client during the "visit" phase of type analysis.
abstract class TypeAnalyzerErrors<
    Node extends Object,
    Statement extends Node,
    Expression extends Node,
    Variable extends Object,
    Type extends Object> implements TypeAnalyzerErrorsBase {
  /// Called if pattern support is disabled and a case constant's static type
  /// doesn't properly match the scrutinee's static type.
  void caseExpressionTypeMismatch(
      {required Expression scrutinee,
      required Expression caseExpression,
      required scrutineeType,
      required caseExpressionType,
      required bool nullSafetyEnabled});

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

  /// Called if the static type of a condition is not assignable to `bool`.
  void nonBooleanCondition(Expression node);

  /// Called if a pattern is illegally used in a variable declaration statement
  /// that is marked `late`, and that pattern is not allowed in such a
  /// declaration.  The only kind of pattern that may be used in a late variable
  /// declaration is a variable pattern.
  ///
  /// [pattern] is the AST node of the illegal pattern.
  void patternDoesNotAllowLate(Node pattern);

  /// Called if, for a pattern in an irrefutable context, the matched type of
  /// the pattern is not assignable to the required type.
  ///
  /// [pattern] is the AST node of the pattern with the type error, [context] is
  /// the containing AST node that established an irrefutable context,
  /// [matchedType] is the matched type, and [requiredType] is the required
  /// type.
  void patternTypeMismatchInIrrefutableContext(
      {required Node pattern,
      required Node context,
      required Type matchedType,
      required Type requiredType});

  /// Called if a refutable pattern is illegally used in an irrefutable context.
  ///
  /// [pattern] is the AST node of the refutable pattern, and [context] is the
  /// containing AST node that established an irrefutable context.
  ///
  /// TODO(paulberry): move this error reporting to the parser.
  void refutablePatternInIrrefutableContext(Node pattern, Node context);

  /// Called if one of the case bodies of a switch statement completes normally
  /// (other than the last case body), and the "patterns" feature is not
  /// enabled.
  ///
  /// [node] is the AST node of the switch statement.  [caseIndex] is the index
  /// of the first case sharing the erroneous case body.  [numMergedCases] is
  /// the number of case heads sharing the erroneous case body.
  void switchCaseCompletesNormally(
      Statement node, int caseIndex, int numMergedCases);
}

/// Base class for error reporting callbacks that might be reported either in
/// the "pre-visit" or the "visit" phase of type analysis.
abstract class TypeAnalyzerErrorsBase {
  /// Called when the [TypeAnalyzer] encounters a condition which should be
  /// impossible if the user's code is free from static errors, but which might
  /// arise as a result of error recovery.  To verify this invariant, the client
  /// should double check (preferably using an assertion) that at least one
  /// error is reported.
  ///
  /// Note that the error might be reported after this method is called.
  void assertInErrorRecovery();
}

/// Options affecting the behavior of [TypeAnalyzer].
///
/// The client is free to `implement` or `extend` this class.
class TypeAnalyzerOptions {
  final bool nullSafetyEnabled;

  final bool patternsEnabled;

  TypeAnalyzerOptions(
      {required this.nullSafetyEnabled, required this.patternsEnabled});
}

/// Data structure tracking information about the type of a variable bound by
/// one or more patterns.
class VariableTypeInfo<Node extends Object, Type extends Object> {
  Node _latestPattern;

  /// The static type of [_latestPattern].  This is used to detect
  /// [TypeAnalyzerErrors.inconsistentMatchVar].
  Type _latestStaticType;

  /// Indicates whether [_latestPattern] used an implicit type.  This is used to
  /// detect [TypeAnalyzerErrors.inconsistentMatchVarExplicitness].
  bool _isImplicitlyTyped;

  VariableTypeInfo(
      this._latestPattern, this._latestStaticType, this._isImplicitlyTyped);

  /// Indicates whether this variable was implicitly typed.
  bool get isImplicitlyTyped => _isImplicitlyTyped;

  /// The static type of this variable.
  Type get staticType => _latestStaticType;
}
