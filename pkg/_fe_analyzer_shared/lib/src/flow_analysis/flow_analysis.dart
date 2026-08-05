// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Implementation of flow analysis.
///
/// See the specification document:
/// https://github.com/dart-lang/language/blob/main/resources/type-system/flow-analysis.md
///
/// Throughout this file, differences from the normative text of the spec are
/// noted in parentheses with the prefix "OPTIMIZATION:" (for optimizations that
/// don't affect behavior) or "UNSPECIFIED:" (for behaviors that aren't
/// documented in the spec yet).
///
/// @docImport 'package:_fe_analyzer_shared/src/type_inference/null_shorting.dart';
library;

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis_log.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart';
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:meta/meta.dart';

import '../type_inference/assigned_variables.dart';
import '../type_inference/promotion_key_store.dart';
import 'flow_analysis_operations.dart';
import 'flow_link.dart';

/// Safely downcasts [expressionInfo] to a [_Reference].
///
/// If [expressionInfo] implements [_Reference], it is returned. Otherwise,
/// `null` is returned.
_Reference? _getExpressionReference(ExpressionInfo? expressionInfo) =>
    switch (expressionInfo) {
      _Reference reference => reference,
      _ => null,
    };

/// [PropertyTarget] representing an implicit reference to the target of the
/// innermost enclosing cascade expression.
class CascadePropertyTarget extends PropertyTarget<Never> {
  static const CascadePropertyTarget singleton =
      const CascadePropertyTarget._();

  const CascadePropertyTarget._() : super._();

  @override
  String toString() => 'CascadePropertyTarget()';

  @override
  SsaNode _getSsaNode(_PropertyTargetHelper<Object> helper) =>
      helper._cascadeTargetStack.last.ssaNode;
}

/// Non-promotion reason describing the situation where a variable was not
/// promoted due to an explicit write to the variable appearing somewhere in the
/// source code.
class DemoteViaExplicitWrite<Variable extends Object, Node extends Object>
    extends NonPromotionReason {
  /// The local variable that was not promoted.
  final Variable variable;

  /// The node that wrote to the variable; this corresponds to a node that was
  /// passed to [FlowAnalysis.write].
  final Node node;

  DemoteViaExplicitWrite(this.variable, this.node);

  @override
  NonPromotionDocumentationLink get documentationLink =>
      NonPromotionDocumentationLink.write;

  @override
  String get shortName => 'explicitWrite';

  @override
  R accept<R, Node extends Object, Variable extends Object>(
    NonPromotionReasonVisitor<R, Node, Variable> visitor,
  ) => visitor.visitDemoteViaExplicitWrite(
    this as DemoteViaExplicitWrite<Variable, Node>,
  );

  @override
  String toString() => 'DemoteViaExplicitWrite($node)';
}

/// Non-promotion reason describing the situation where a promotion was lost
/// because the current function was suspended (due to an `await` or `yield`
/// statement) while inside a local function, allowing other code to execute and
/// potentially modify the variable.
class DemoteViaSuspension<Variable extends Object, Node extends Object>
    extends NonPromotionReason {
  /// The local variable that was not promoted.
  final Variable variable;

  /// The node representing the suspension (e.g. an `await` or `yield`).
  ///
  /// This is the node that was passed to [FlowAnalysis.suspension].
  final Node node;

  DemoteViaSuspension(this.variable, this.node);

  @override
  NonPromotionDocumentationLink get documentationLink =>
      NonPromotionDocumentationLink.suspension;

  @override
  String get shortName => 'demoteViaSuspension';

  @override
  R accept<R, Node extends Object, Variable extends Object>(
    NonPromotionReasonVisitor<R, Node, Variable> visitor,
  ) => visitor.visitDemoteViaSuspension(
    this as DemoteViaSuspension<Variable, Node>,
  );

  @override
  String toString() => 'DemoteViaSuspension($node)';
}

/// Information gathered by flow analysis about an expression. This includes its
/// static type, whether it refers to `null` or to something promotable, and the
/// flow models representing execution state after the expression is evaluated.
class ExpressionInfo {
  /// The static type of the expression.
  final SharedTypeView _type;

  /// The flow model representing execution state after the expression is
  /// evaluated, if the expression evaluates to `true`.
  @visibleForTesting
  final FlowModel ifTrue;

  /// The flow model representing execution state after the expression is
  /// evaluated, if the expression evaluates to `false`.
  @visibleForTesting
  final FlowModel ifFalse;

  /// Creates an [ExpressionInfo] for an expression whose value influences the
  /// flow model (e.g. an `!= null` or `is Type` check applied to a promotable
  /// target, which causes a promotion if it evaluates to `true`).
  @visibleForTesting
  ExpressionInfo({
    required SharedTypeView type,
    required this.ifTrue,
    required this.ifFalse,
  }) : _type = type;

  /// Creates an [ExpressionInfo] for an expression whose value doesn't
  /// influence the flow model.
  @visibleForTesting
  ExpressionInfo.trivial({
    required SharedTypeView type,
    required FlowModel model,
  }) : _type = type,
       ifTrue = model,
       ifFalse = model;

  /// Determines if the value of the expression represented by `this` influences
  /// the flow model.
  bool get isNonTrivial => !identical(ifTrue, ifFalse);

  /// Indicates whether the expression represented by `this` is a `null`
  /// literal.
  bool get isNull => false;

  @override
  String toString() =>
      'ExpressionInfo(type: $_type, '
      '_ifTrue: $ifTrue, ifFalse: $ifFalse)';

  /// Creates an [ExpressionInfo] containing information about the logical
  /// inversion of the expression represented by `this`. For example, if `this`
  /// contains information about the expression `x == null`, calling this method
  /// produces an [ExpressionInfo] containing information about the expression
  /// `x != null`.
  ExpressionInfo _invert() => isNonTrivial
      ? new ExpressionInfo(type: _type, ifTrue: ifFalse, ifFalse: ifTrue)
      : this;
}

/// [PropertyTarget] that is an expression appearing explicitly in the source
/// code.
class ExpressionPropertyTarget<Expression extends Object>
    extends PropertyTarget<Expression> {
  /// The expression info for the expression whose property is being accessed.
  final ExpressionInfo? expressionInfo;

  ExpressionPropertyTarget(this.expressionInfo) : super._();

  @override
  String toString() => 'ExpressionPropertyTarget($expressionInfo)';

  @override
  SsaNode? _getSsaNode(covariant _PropertyTargetHelper<Expression> helper) {
    return _getExpressionReference(expressionInfo)?.ssaNode;
  }
}

/// Implementation of flow analysis to be shared between the analyzer and the
/// front end.
///
/// The client should create one instance of this class for every method, field,
/// or top level variable to be analyzed, and call the appropriate methods
/// while visiting the code for type inference.
///
/// The API for flow analysis is event-based, consisting of methods that are
/// intended to be called during a single-pass depth-first pre-order* traversal
/// of the AST of the code being analyzed. The client only needs to make calls
/// into flow analysis when this traversal visits "flow-relevant" AST nodes
/// (i.e. statements and expressions that influence flow control, such as loops,
/// return statements, etc., expressions that reference something potentially
/// promotable, such as a variable and property gets, and anything that performs
/// a type test). Other AST nodes (known as "flow-irrelevant" AST nodes) don't
/// require calls to the flow analysis API on their own, but calls to flow
/// analysis may still be required when visiting their children.
///
/// *Where child nodes are ordered according to when they first execute. Note
/// that for most constructs this matches the order in which the nodes appear in
/// the source text, but there are a small number of exceptions. For example, in
/// `for (INITIALIZERS; CONDITION; UPDATERS) BODY;`, `UPDATERS` is executed
/// after `BODY`, so `UPDATERS` should be visited after `BODY`. Also, in
/// `PATTERN = EXPRESSION;`, `PATTERN` is executed after `EXPRESSION`, so
/// `PATTERN` should be visited after `EXPRESSION`.
///
/// With a few exceptions, the methods in this class are named after a kind of
/// AST node, followed by an underscore, followed by a brief phrase indicating
/// when the method should be called during the visit of that kind of AST node.
/// For example, when visiting an `if` statement, the client should call
/// [ifStatement_thenBegin] after visiting its condition expression but before
/// visiting its "then" block. The precise order for visiting any given AST node
/// is described in comments below.
///
/// Some API calls have arguments representing either the AST node being visited
/// or one of its child nodes. For example, [isExpression_end] has an argument
/// `isExpression` representing the entire "is" expression, and
/// [ifStatement_thenBegin] has an argument `condition` representing the
/// "condition" part of the "if" statement.
///
/// Among other things, these arguments allow flow analysis to recognize
/// parent/child relationships between parts of the syntax tree. For example,
/// when analyzing `if (x is T)`, the AST node for `x is T` is passed first to
/// [isExpression_end]'s `isExpression` argument and then, immediately
/// afterwards, to [ifStatement_thenBegin]'s `condition` argument; this tells
/// flow analysis that the "is" expression is an immediate child of the "if"
/// statement, and therefore a type promotion should occur.
///
/// Whereas when analyzing `if (f(x is T))`, the same sequence of calls is made
/// to flow analysis (since the AST node for the invocation of `f` is
/// flow-irrelevant). But the node passed to [isExpression_end]'s `isExpression`
/// argument is `x is T`, whereas the node passed to [ifStatement_thenBegin]'s
/// `condition` argument is `f(x is T)`. Since these nodes are different, flow
/// analysis knows that the "is" expression is *not* an immediate child of the
/// "if" statement, so therefore no type promotion should occur.
abstract class FlowAnalysis<
  Node extends Object,
  Statement extends Node,
  Expression extends Node,
  Variable extends Object
>
    implements FlowAnalysisNullShortingInterface<Expression, Variable> {
  factory FlowAnalysis(
    FlowAnalysisOperations<Variable> operations,
    AssignedVariables<Node, Variable> assignedVariables, {
    required TypeAnalyzerOptions typeAnalyzerOptions,
    required bool enableLog,
  }) {
    return new _FlowAnalysisImpl(
      operations,
      assignedVariables,
      typeAnalyzerOptions: typeAnalyzerOptions,
      enableLog: enableLog,
    );
  }

  /// Whether the current state is reachable.
  bool get isReachable;

  FlowAnalysisOperations<Variable> get operations;

  /// Retrieves the type that `this` is promoted to, if it is currently
  /// promoted.
  ///
  /// If `this` isn't currently promoted, returns `null`.
  SharedTypeView? get promotedTypeOfThis;

  /// Call this method before visiting an anonymous block body.
  ///
  /// [offset] is the last source offset that should be considered to precede
  /// the anonymous block body. The offset of the `{` that opens the anonymous
  /// block body is probably the best choice.
  ///
  /// Call [anonymousBlockBody_end] after visiting the statement.
  void anonymousBlockBody_begin({int offset = 0});

  /// Call this method after visiting an anonymous block body.
  ///
  /// [offset] is the last source offset that should be considered to be inside
  /// the anonymous block body. The offset of the `}` that closes the anonymous
  /// block body is probably the best choice.
  void anonymousBlockBody_end({int offset = 0});

  /// Call this method after visiting an "as" expression.
  ///
  /// [subExpressionInfo] should be the expression info for the expression to
  /// which the "as" check was applied, and [subExpressionType] should be its
  /// static type. [castType] should be the type being cast to.
  ///
  /// [offset] is the last source offset that should be considered to be prior
  /// to the cast taking effect. Any value from the first character of the `as`
  /// token to the last character of the type should work, since no expressions
  /// can appear in this range, but the last character of the type is probably
  /// the best choice.
  void asExpression_end(
    ExpressionInfo? subExpressionInfo, {
    required SharedTypeView subExpressionType,
    required SharedTypeView castType,
    int offset = 0,
  });

  /// Call this method after visiting the condition part of an assert statement
  /// (or assert initializer).
  ///
  /// [conditionInfo] should be the expression info for the assert statement's
  /// condition.
  ///
  /// [offset] is the last source offset that should be considered to be prior
  /// to the condition being checked. The best choice is probably the offset of
  /// the `,` separating the condition and message, or the `)` if there is no
  /// `,`.
  ///
  /// See [assert_begin] for more information.
  void assert_afterCondition(ExpressionInfo? conditionInfo, {int offset = 0});

  /// Call this method before visiting the condition part of an assert statement
  /// (or assert initializer).
  ///
  /// [offset] is the last source offset that should be considered to be prior
  /// to entry into the `assert`. The offset of any character in the `assert`
  /// keyword should work, since no expressions can appear in this range, but
  /// the first character of the keyword is probably the best choice.
  ///
  /// The order of visiting an assert statement with no "message" part should
  /// be:
  /// - Call [assert_begin]
  /// - Visit the condition
  /// - Call [assert_afterCondition]
  /// - Call [assert_end]
  ///
  /// The order of visiting an assert statement with a "message" part should be:
  /// - Call [assert_begin]
  /// - Visit the condition
  /// - Call [assert_afterCondition]
  /// - Visit the message
  /// - Call [assert_end]
  void assert_begin({int offset = 0});

  /// Call this method after visiting an assert statement (or assert
  /// initializer).
  ///
  /// [offset] is the last source offset that should be considered to be prior
  /// to exiting the `assert`. For an assert statement, the offset of the `;` is
  /// probably the best choice. For an assert initializer, the offset of the `)`
  /// is probably the best choice.
  ///
  /// See [assert_begin] for more information.
  void assert_end({int offset = 0});

  /// Call this method after visiting a reference to a variable inside a pattern
  /// assignment.
  ///
  /// [node] is the pattern, [variable] is the referenced variable, and
  /// [writtenType] is the type that's written to that variable by the
  /// assignment.
  ///
  /// [offset] is the last source offset that should be considered prior to the
  /// variable being considered to be "assigned". The offset of the identifier
  /// that names the variable is probably the best choice.
  void assignedVariablePattern(
    Node node,
    Variable variable,
    SharedTypeView writtenType, {
    int offset = 0,
  });

  /// Call this method when the temporary variable holding the result of a
  /// pattern match is assigned to a user-accessible variable.
  ///
  /// Depending on the client's model, this might happen right after a variable
  /// pattern is matched, or later, after one or more logical-or patterns have
  /// been handled).
  ///
  /// [promotionKey] is the promotion key used by flow analysis to represent the
  /// temporary variable holding the result of the pattern match, and [variable]
  /// is the user-accessible variable that the value is being assigned to.
  ///
  /// Returns the promotion key used by flow analysis to represent [variable].
  /// This may be used in future calls to [assignMatchedPatternVariable] to
  /// handle nested logical-ors, or logical-ors nested within switch cases that
  /// share a body.
  ///
  /// [offset] is the last source offset that should be considered prior to the
  /// variable being considered to be "assigned". The offset of the identifier
  /// that names the variable is probably the best choice.
  void assignMatchedPatternVariable(
    Variable variable,
    int promotionKey, {
    int offset = 0,
  });

  /// Call this method when visiting a boolean literal expression.
  ///
  /// Returns the expression info for the boolean literal.
  ExpressionInfo booleanLiteral(bool value);

  /// Call this method just after visiting the target of a cascade expression.
  ///
  /// [targetInfo] is the expression info for the target expression (the
  /// expression before the first `..` or `?..`), and [targetType] is its static
  /// type. [isNullAware] indicates whether the cascade expression is null-aware
  /// (meaning its first separator is `?..` rather than `..`).
  ///
  /// If the [isNullAware] is `true`, and the client desugars the null-aware
  /// access using a guard variable (e.g., if it desugars `a?.b` into `let x = a
  /// in x == null ? null : x.b`), it should pass in the variable used for
  /// desugaring as [guardVariable]. Flow analysis will ensure that this
  /// variable is promoted to the appropriate type in the "not null" code path.
  ///
  /// Returns the effective type of the target expression during execution of
  /// the cascade sections (this is either the same as [targetType], or its
  /// non-nullable equivalent, if [isNullAware] is `true`).
  ///
  /// [offset] is the last source offset that should be considered to precede
  /// the cascade sections. The offset of the cascade's first `..` or `?..`
  /// token is probably the best choice.
  ///
  /// The order of visiting a cascade expression should be:
  /// - Visit the target
  /// - Call [cascadeExpression_afterTarget].
  /// - Visit each cascade section
  /// - If this is a null-aware cascade, call [nullAwareAccess_end].
  /// - Call [cascadeExpression_end].
  SharedTypeView cascadeExpression_afterTarget(
    ExpressionInfo? targetInfo,
    SharedTypeView targetType, {
    required bool isNullAware,
    Variable? guardVariable,
    int offset = 0,
  });

  /// Call this method just after visiting a cascade expression.
  ///
  /// See [cascadeExpression_afterTarget] for details.
  ///
  /// Returns the expression info for the whole cascade expression.
  ExpressionInfo cascadeExpression_end();

  /// Checks that the given [offset] is greater than or equal to any offset
  /// previously passed to flow analysis, allowing exceptions for constructs
  /// that are purposefully not visited in source order*.
  ///
  /// *For example, in C-style `for` loops, the "updater" part is visited after
  /// the body. And in pattern assignments, the pattern is visited after the
  /// expression.
  ///
  /// Has no effect if assertions are disabled.
  void checkOffset(int offset);

  /// Call this method just before visiting a conditional expression ("?:").
  ///
  /// [offset] is the last source offset that should be considered to be prior
  /// to entry into the conditional expression. The offset of the first
  /// character of the conditional expression is probably the best choice.
  void conditional_conditionBegin({int offset = 0});

  /// Call this method upon reaching the ":" part of a conditional expression
  /// ("?:").
  ///
  /// [thenExpressionInfo] should be the expression info for the expression
  /// preceding the ":". [thenType] should be the static type of the expression
  /// preceding the ":".
  ///
  /// [offset] is the last source offset that should be considered to be part of
  /// the "then" part of the conditional expression. The offset of the `:` token
  /// is probably the best choice.
  void conditional_elseBegin(
    ExpressionInfo? thenExpressionInfo,
    SharedTypeView thenType, {
    int offset = 0,
  });

  /// Call this method when finishing the visit of a conditional expression
  /// ("?:").
  ///
  /// [elseExpressionInfo] should be the expression info for the expression
  /// following the ":". [elseType] should be the static type of the expression
  /// following the ":", and [conditionalExpressionType] should be the static
  /// type of the whole conditional expression.
  ///
  /// [offset] is the last source offset that should be considered to be part of
  /// the "else" part of the conditional expression. The end offset of the
  /// conditional expression is probably the best choice.
  ///
  /// Returns the expression info for the whole conditional expression.
  ExpressionInfo conditional_end(
    SharedTypeView conditionalExpressionType,
    ExpressionInfo? elseExpressionInfo,
    SharedTypeView elseType, {
    int offset = 0,
  });

  /// Call this method upon reaching the "?" part of a conditional expression
  /// ("?:").
  ///
  /// [conditionInfo] should be the expression info for the expression preceding
  /// the "?". [conditionalExpression] should be the entire conditional
  /// expression.
  ///
  /// [offset] is the last source offset that should be considered to be part of
  /// the "condition" part of the conditional expression. The offset of the `?`
  /// token is probably the best choice.
  void conditional_thenBegin(
    ExpressionInfo? conditionInfo,
    Node conditionalExpression, {
    int offset = 0,
  });

  /// Call this method after processing a constant pattern.
  ///
  /// [expressionInfo] should be the expression info for the pattern's constant
  /// expression, and [type] should be its static type.
  ///
  /// [matchedValueType] should be the type returned by [getMatchedValueType].
  ///
  /// If [patternsEnabled] is `true`, pattern support is enabled and this is an
  /// ordinary constant pattern. If [patternsEnabled] is `false`, pattern
  /// support is disabled and this constant pattern is one of the cases of a
  /// legacy switch statement.
  ///
  /// [offset] is the last source offset that should be considered to be prior
  /// to the constant pattern being matched. The end offset of the constant
  /// pattern is probably the best choice.
  void constantPattern_end(
    ExpressionInfo? expressionInfo,
    SharedTypeView type, {
    required bool patternsEnabled,
    required SharedTypeView matchedValueType,
    int offset = 0,
  });

  /// Copies promotion data associated with one promotion key to another.
  ///
  /// This is used after analyzing a branch of a logical-or pattern, to move the
  /// promotion data associated with the result of a pattern match on the left
  /// hand and right hand sides of the logical-or into a common promotion key,
  /// so that promotions will be properly unified when the control flow paths
  /// are joined.
  ///
  /// [offset] is the last source offset that should be considered to be prior
  /// to the copy. The end offset of the logical-or pattern is probably the best
  /// choice.
  void copyPromotionData({
    required int sourceKey,
    required int destinationKey,
    int offset = 0,
  });

  /// Registers a declaration of the [variable] in the current state.
  ///
  /// Should also be called for function parameters.
  ///
  /// [staticType] should be the static type of the variable (after type
  /// inference).
  ///
  /// A local variable is [initialized] if its declaration has an initializer.
  /// A function parameter is always initialized, so [initialized] is `true`.
  ///
  /// In debug builds, an assertion will normally verify that no variable gets
  /// declared more than once.
  ///
  /// [offset] is the last source offset that should be considered prior to the
  /// variable being considered "assigned". The offset of the `;` that ends the
  /// variable declaration is probably the best choice.
  void declare(
    Variable variable,
    SharedTypeView staticType, {
    required bool initialized,
    int offset = 0,
  });

  /// Call this method after visiting a variable pattern in a non-assignment
  /// context (or a wildcard pattern).
  ///
  /// [matchedType] should be the static type of the value being matched.
  /// [staticType] should be the static type of the variable pattern itself.
  /// [isFinal] indicates whether the variable is final, and [isImplicitlyTyped]
  /// indicates whether the variable has an explicit type annotation.
  ///
  /// Although pattern variables in Dart cannot be late, the client is allowed
  /// to model a traditional (non-patterned) variable declaration statement
  /// using the same flow analysis machinery as it uses for pattern variable
  /// declaration statements; when it does so, it may use [isLate] to indicate
  /// whether the variable in question is a `late` variable.
  ///
  /// Returns the promotion key used by flow analysis to track the temporary
  /// variable that holds the matched value.
  ///
  /// [offset] is the last source offset that should be considered prior to the
  /// variable being considered to be "assigned". The offset of the identifier
  /// that names the variable is probably the best choice.
  int declaredVariablePattern({
    required SharedTypeView matchedType,
    required SharedTypeView staticType,
    bool isFinal = false,
    bool isLate = false,
    required bool isImplicitlyTyped,
    int offset = 0,
  });

  /// Call this method before visiting the body of a "do-while" statement.
  ///
  /// [doStatement] should be the same node that was passed to
  /// [AssignedVariables.endNode] for the do-while statement.
  ///
  /// [offset] is the last source offset that should be considered to be prior
  /// to entry into the loop. The offset of either character of the `do` keyword
  /// should work, since no expressions can appear in this range, but the first
  /// character of the keyword is probably the best choice.
  void doStatement_bodyBegin(Statement doStatement, {int offset = 0});

  /// Call this method after visiting the body of a "do-while" statement, and
  /// before visiting its condition.
  ///
  /// [offset] is the last source offset that should be considered to be inside
  /// the loop body. The offset of any character of the `while` keyword should
  /// work, since no expressions can appear in this range, but the first
  /// character of the keyword is probably the best choice.
  void doStatement_conditionBegin({int offset = 0});

  /// Call this method after visiting the condition of a "do-while" statement.
  /// [conditionInfo] should be the expression info for the condition of the
  /// loop.
  ///
  /// [offset] is the last source offset that should be considered to be prior
  /// to exiting the loop. The offset of the `;` is probably the best choice.
  void doStatement_end(ExpressionInfo? conditionInfo, {int offset = 0});

  /// Call this method just after visiting the operands of a binary `==` or `!=`
  /// expression, or an invocation of `identical`.
  ///
  /// [leftOperandInfo] and [rightOperandInfo] should be the expression info for
  /// the left and right operands. [leftOperandType] and [rightOperandType]
  /// should be the static types of the left and right operands.
  ///
  /// Returns the expression info for the `==` or `!=` expression.
  ExpressionInfo? equalityOperation_end(
    ExpressionInfo? leftOperandInfo,
    SharedTypeView leftOperandType,
    ExpressionInfo? rightOperandInfo,
    SharedTypeView rightOperandType, {
    bool notEqual = false,
  });

  /// Call this method after processing a relational pattern that uses an
  /// equality operator (either `==` or `!=`).
  ///
  /// [operandInfo] should be the expression info for the operand to the right
  /// of the operator, [operandType] should be its static type, and [notEqual]
  /// should be `true` iff the operator was `!=`.
  ///
  /// [matchedValueType] should be the type returned by [getMatchedValueType].
  ///
  /// [offset] is the last source offset that should be considered prior to the
  /// equality check taking place. The end offset of the pattern is probably the
  /// best choice.
  void equalityRelationalPattern_end(
    ExpressionInfo? operandInfo,
    SharedTypeView operandType, {
    bool notEqual = false,
    required SharedTypeView matchedValueType,
    int offset = 0,
  });

  /// Performs assertion checks at the conclusion of flow analysis.
  ///
  /// This method should be called at the conclusion of flow analysis for a top
  /// level function or method, when `this` is no longer needed.
  void finish();

  /// Call this method just before visiting the body of a conventional "for"
  /// statement or collection element.
  ///
  /// See [for_conditionBegin] for details.
  ///
  /// If a "for" statement is being entered, [node] is an opaque representation
  /// of the loop, for use as the target of future calls to [handleBreak] or
  /// [handleContinue]. If a "for" collection element is being entered, [node]
  /// should be `null`.
  ///
  /// [conditionInfo] is the expression info for the loop condition. If the loop
  /// condition is empty, the caller should pass in the result of calling
  /// [booleanLiteral] and passing in a value of `true`.
  ///
  /// [offset] is the last source offset that should be considered prior to
  /// entry into the loop body. The offset of the `)` is probably the best
  /// choice.
  void for_bodyBegin(
    Statement? node,
    ExpressionInfo? conditionInfo, {
    int offset = 0,
  });

  /// Call this method just before visiting the condition of a conventional
  /// "for" statement or collection element.
  ///
  /// Note that a conventional "for" statement is a statement of the form
  /// `for (initializers; condition; updaters) body`. Statements of the form
  /// `for (variable in iterable) body` should use [forEach_bodyBegin]. Similar
  /// for "for" collection elements.
  ///
  /// The order of visiting a "for" statement or collection element should be:
  /// - Visit the initializers.
  /// - Call [for_conditionBegin].
  /// - Visit the condition.
  /// - Call [for_bodyBegin].
  /// - Visit the body.
  /// - Call [for_updaterBegin].
  /// - Visit the updaters.
  /// - Call [for_end].
  ///
  /// [node] should be the same node that was passed to
  /// [AssignedVariables.endNode] for the for statement.
  ///
  /// [offset] is the last source offset that should be considered to be prior
  /// to entry into the `for`. The offset of any character in the `for` keyword
  /// (or `await` keyword, if present) should work, since no expressions can
  /// appear in this range, but the first such character is probably the best
  /// choice.
  void for_conditionBegin(Node node, {int offset = 0});

  /// Call this method just after visiting the updaters of a conventional "for"
  /// statement or collection element.
  ///
  /// See [for_conditionBegin] for details.
  ///
  /// [offset] is the last source offset that should be considered to be inside
  /// the body of the `for`. The end offset of the body is probably the best
  /// choice.
  void for_end({int offset = 0});

  /// Call this method just before visiting the updaters of a conventional "for"
  /// statement or collection element.
  ///
  /// See [for_conditionBegin] for details.
  ///
  /// [offset] is the last source offset that should be considered to be part of
  /// the loop condition. The offset of the `;` separating the condition from
  /// any updaters is probably the best choice.
  void for_updaterBegin({int offset = 0});

  /// Call this method just before visiting the body of a "for-in" statement or
  /// collection element.
  ///
  /// The order of visiting a "for-in" statement or collection element should
  /// be:
  /// - Visit the iterable expression.
  /// - Call [forEach_bodyBegin].
  /// - Visit the body.
  /// - Call [forEach_end].
  ///
  /// [node] should be the same node that was passed to
  /// [AssignedVariables.endNode] for the for statement.
  ///
  /// [offset] is the last source offset that should be considered prior to
  /// entry into the loop body. The offset of the `)` is probably the best
  /// choice.
  void forEach_bodyBegin(Node node, {int offset = 0});

  /// Call this method just before visiting the body of a "for-in" statement or
  /// collection element.
  ///
  /// See [forEach_bodyBegin] for details.
  ///
  /// [offset] is the last source offset that should be considered to be inside
  /// the body of the `for`. The end offset of the body is probably the best
  /// choice.
  void forEach_end({int offset = 0});

  /// Call this method just before visiting the body of a function expression or
  /// local function.
  ///
  /// [node] should be the same node that was passed to
  /// [AssignedVariables.endNode] for the function expression.
  ///
  /// [offset] is the last source offset that should be considered to be before
  /// the body of the function expression. The offset of the `{` or `=>` that
  /// begins the function expression is probably the best choice.
  void functionExpression_begin(Node node, {int offset = 0});

  /// Call this method just after visiting the body of a function expression or
  /// local function.
  ///
  /// [offset] is the last source offset that should be considered to be inside
  /// the body of the function expression. For a block-bodied function
  /// expression, the offset of the `}` is probably the best choice. For an
  /// expression-bodied function expression, the end offset of the function
  /// expression is probably the best choice.
  void functionExpression_end({int offset = 0});

  /// Queries the [PromotionInfo] object from the current internal state of flow
  /// analysis.
  ///
  /// This is used in tests to validate that the information stored in the flow
  /// analysis log is an accurate recording of flow analysis state changes.
  @visibleForTesting
  PromotionInfo? getCurrentPromotionInfo();

  /// Queries the promotion key that represents `this` in the current internal
  /// state of flow analysis.
  ///
  /// This is used in tests to validate that the information stored in the flow
  /// analysis log is an accurate recording of flow analysis state changes.
  @visibleForTesting
  int getCurrentThisBinding();

  /// Retrieves the [FlowAnalysisLog].
  ///
  /// Returns `null` if flow analysis logging is disabled (see the `enableLog`
  /// parameter of the constructor).
  ///
  /// No further calls to this [FlowAnalysis] object should be made after this
  /// call.
  FlowAnalysisLog? getLog();

  /// Gets the matched value type that should be used to type check the pattern
  /// currently being analyzed.
  ///
  /// May only be called in the context of a pattern.
  SharedTypeView getMatchedValueType();

  /// Call this method when visiting a break statement.
  ///
  /// [target] should be the statement targeted by the break.
  ///
  /// To facilitate error recovery, [target] is allowed to be `null`; if this
  /// happens, the break statement is analyzed as though it's an unconditional
  /// branch to nowhere (i.e. similar to a `return` or `throw`).
  ///
  /// [offset] is the last source offset that should be considered to be prior
  /// to the branch taking effect. The offset of the `;` is probably the best
  /// choice.
  void handleBreak(Statement? target, {int offset = 0});

  /// Call this method when visiting a continue statement.
  ///
  /// [target] should be the statement targeted by the continue.
  ///
  /// To facilitate error recovery, [target] is allowed to be `null`; if this
  /// happens, the continue statement is analyzed as though it's an
  /// unconditional branch to nowhere (i.e. similar to a `return` or `throw`).
  ///
  /// [offset] is the last source offset that should be considered to be prior
  /// to the branch taking effect. The offset of the `;` is probably the best
  /// choice.
  void handleContinue(Statement? target, {int offset = 0});

  /// Register the fact that the current state definitely exits, e.g. returns
  /// from the body, throws an exception, etc.
  ///
  /// Should also be called if a subexpression's type is Never.
  ///
  /// [offset] is the last source offset that should be considered to be prior
  /// to the branch taking effect. For a `throw` expression or an expression
  /// whose type is `Never`, the end offset of the expression is probably the
  /// best choice.
  void handleExit({int offset = 0});

  /// Call this method when visiting a return statement.
  ///
  /// [offset] is the last source offset that should be considered to be prior
  /// to the branch taking effect. The offset of the `;` is probably the best
  /// choice.
  void handleReturn({int offset = 0});

  /// Call this method after visiting the scrutinee expression of an if-case
  /// statement.
  ///
  /// [scrutineeInfo] is the expression info for the scrutinee expression, and
  /// [scrutineeType] is its static type.
  ///
  /// [offset] is the last source offset that should be considered to be prior
  /// to entry to the pattern. The offset of any character in the `case` keyword
  /// should work, since no expressions can appear in this range, but the first
  /// character of the keyword is probably the best choice.
  void ifCaseStatement_afterExpression(
    ExpressionInfo? scrutineeInfo,
    SharedTypeView scrutineeType, {
    int offset = 0,
  });

  /// Call this method before visiting an if-case statement.
  ///
  /// The order of visiting an if-case statement with no "else" part should be:
  /// - Call [ifCaseStatement_begin]
  /// - Visit the expression
  /// - Call [ifCaseStatement_afterExpression]
  /// - Visit the pattern
  /// - Visit the guard (if any)
  /// - Call [ifCaseStatement_thenBegin]
  /// - Visit the "then" statement
  /// - Call [ifStatement_end], passing `false` for `hasElse`.
  ///
  /// The order of visiting an if-case statement with an "else" part should be:
  /// - Call [ifCaseStatement_begin]
  /// - Visit the expression
  /// - Call [ifCaseStatement_afterExpression]
  /// - Visit the pattern
  /// - Visit the guard (if any)
  /// - Call [ifCaseStatement_thenBegin]
  /// - Visit the "then" statement
  /// - Call [ifStatement_elseBegin]
  /// - Visit the "else" statement
  /// - Call [ifStatement_end], passing `true` for `hasElse`.
  ///
  /// [offset] is the last source offset that should be considered to be prior
  /// to entry into the if-case statement. The offset of either character in the
  /// `if` keyword should work, since no expressions can appear in this range,
  /// but the first character of the keyword is probably the best choice.
  void ifCaseStatement_begin({int offset = 0});

  /// Call this method after visiting pattern and guard parts of an if-case
  /// statement.
  ///
  /// [guardInfo] should be the expression info for the guard expression. If
  /// there is no guard expression, it should be the value returned by a call to
  /// [booleanLiteral], passing a value of `true`.
  ///
  /// [offset] is the last source offset that should be considered to be part of
  /// the pattern part of the if-case statement. The offset of the `)` is
  /// probably the best choice.
  void ifCaseStatement_thenBegin(ExpressionInfo? guardInfo, {int offset = 0});

  /// Call this method after visiting the RHS of an if-null expression ("??")
  /// or if-null assignment ("??=").
  ///
  /// Note: for an if-null assignment, the call to [write] should occur before
  /// the call to [ifNullExpression_end] (since the write only occurs if the
  /// read resulted in a null value).
  ///
  /// [offset] is the last source offset that should be considered to be part of
  /// the RHS of the if-null expression. The end offset of the if-null
  /// expression is probably the best choice.
  void ifNullExpression_end({int offset = 0});

  /// Call this method after visiting the LHS of an if-null expression ("??")
  /// or if-null assignment ("??=").
  ///
  /// [offset] is the last source offset that should be considered to be part of
  /// the LHS of the if-null expression. The offset of any character in the `??`
  /// or `??=` token should work, since no expressions can appear in this range,
  /// but the first character of the token is probably the best choice.
  void ifNullExpression_rightBegin(
    ExpressionInfo? leftHandSideInfo,
    SharedTypeView leftHandSideType, {
    int offset = 0,
  });

  /// Call this method before visiting the condition part of an if statement.
  ///
  /// The order of visiting an if statement with no "else" part should be:
  /// - Call [ifStatement_conditionBegin]
  /// - Visit the condition
  /// - Call [ifStatement_thenBegin]
  /// - Visit the "then" statement
  /// - Call [ifStatement_end], passing `false` for `hasElse`.
  ///
  /// The order of visiting an if statement with an "else" part should be:
  /// - Call [ifStatement_conditionBegin]
  /// - Visit the condition
  /// - Call [ifStatement_thenBegin]
  /// - Visit the "then" statement
  /// - Call [ifStatement_elseBegin]
  /// - Visit the "else" statement
  /// - Call [ifStatement_end], passing `true` for `hasElse`.
  ///
  /// [offset] is the last source offset that should be considered to be prior
  /// to entry into the if statement. The offset of either character in the `if`
  /// keyword should work, since no expressions can appear in this range, but
  /// the first character of the keyword is probably the best choice.
  void ifStatement_conditionBegin({int offset = 0});

  /// Call this method after visiting the "then" part of an if statement, and
  /// before visiting the "else" part.
  ///
  /// [offset] is the last source offset that should be considered to be part of
  /// the "then" part of the if statement. The offset any character in the
  /// `else` keyword should work, since no expressions can appear in this range,
  /// but the first character of the keyword is probably the best choice.
  void ifStatement_elseBegin({int offset = 0});

  /// Call this method after visiting an if statement.
  ///
  /// [offset] is the last source offset that should be considered to be part of
  /// the "else" part of the if statement (or the "then" part, if no "else" part
  /// is present). The end offset of the if statement is probably the best
  /// choice.
  void ifStatement_end(bool hasElse, {int offset = 0});

  /// Call this method after visiting the condition part of an if statement.
  ///
  /// [conditionInfo] should be the expression info for the if statement's
  /// condition. [ifNode] should be the entire `if` statement (or the collection
  /// literal entry).
  ///
  /// [offset] is the last source offset that should be considered to be part of
  /// the condition part of the if statement. The offset of the `)` is probably
  /// the best choice.
  void ifStatement_thenBegin(
    ExpressionInfo? conditionInfo,
    Node ifNode, {
    int offset = 0,
  });

  /// Call this method after visiting the initializer of a variable declaration,
  /// or a variable pattern that is being matched (and hence being initialized
  /// with an implicit value).
  ///
  /// If the initialized value is not known (i.e. because this is a variable
  /// pattern that's being matched), pass `null` for
  /// [initializerExpressionInfo].
  ///
  /// [offset] is the last source offset that should be considered prior to the
  /// variable being considered "assigned". The offset of the `;` that ends the
  /// variable declaration is probably the best choice.
  void initialize(
    Variable variable,
    SharedTypeView matchedType,
    ExpressionInfo? initializerExpressionInfo, {
    required bool isFinal,
    required bool isLate,
    required bool isImplicitlyTyped,
    bool inheritPromotableProperties = false,
    int offset = 0,
  });

  /// Whether the [variable] is definitely assigned in the current state.
  bool isAssigned(Variable variable);

  /// Call this method after visiting the LHS of an "is" expression.
  ///
  /// [subExpressionInfo] should be the expression info for the expression to
  /// which the "is" check was applied, and [subExpressionType] should be its
  /// static type. [isNot] should be a boolean indicating whether this is an
  /// "is" or an "is!" expression. [checkedType] should be the type being
  /// checked.
  ///
  /// Returns the expression info for the complete "is" expression.
  ExpressionInfo? isExpression_end(
    ExpressionInfo? subExpressionInfo,
    bool isNot, {
    required SharedTypeView subExpressionType,
    required SharedTypeView checkedType,
  });

  /// Whether the [variable] is definitely unassigned in the current state.
  bool isUnassigned(Variable variable);

  /// Call this method before visiting a labeled statement.
  ///
  /// Call [labeledStatement_end] after visiting the statement.
  ///
  /// [offset] is the last source offset that should be considered to be prior
  /// to entry into the labeled statement. The offset of any character in the
  /// label should work, since no expressions can appear in this range, but the
  /// first character of the label is probably the best choice.
  void labeledStatement_begin(Statement node, {int offset = 0});

  /// Call this method after visiting a labeled statement.
  ///
  /// [offset] is the last source offset that should be considered to be within
  /// the label's scope. The end offset of the labeled statement is probably the
  /// best choice.
  void labeledStatement_end({int offset = 0});

  /// Call this method just before visiting the initializer of a late variable.
  ///
  /// [offset] is the last source offset that should be considered to be prior
  /// to entry into the late initializer. The offset of the `=` character in
  /// the declaration is probably the best choice.
  void lateInitializer_begin(Node node, {int offset = 0});

  /// Call this method just after visiting the initializer of a late variable.
  ///
  /// [offset] is the last source offset that should be considered to be within
  /// the late initializer. The end offset of the initializer expression is
  /// probably the best choice.
  void lateInitializer_end({int offset = 0});

  /// Call this method before visiting the LHS of a logical binary operation
  /// ("||" or "&&").
  ///
  /// [offset] is the last source offset that should be considered to be prior
  /// to the logical binary operation. The start offset of the binary operation
  /// expression is probably the best choice.
  void logicalBinaryOp_begin({int offset = 0});

  /// Call this method after visiting the RHS of a logical binary operation
  /// ("||" or "&&").
  ///
  /// [rightOperandInfo] should be the expression info for the RHS. [isAnd]
  /// should indicate whether the logical operator is "&&" or "||".
  ///
  /// Returns the expression info for the whole logical binary expression.
  ///
  /// [offset] is the last source offset that should be considered to be part of
  /// the RHS of the logical binary operation. The end offset of the binary
  /// operation expression is probably the best choice.
  ExpressionInfo logicalBinaryOp_end(
    ExpressionInfo? rightOperandInfo, {
    required bool isAnd,
    int offset = 0,
  });

  /// Call this method after visiting the LHS of a logical binary operation
  /// ("||" or "&&").
  ///
  /// [leftOperandInfo] should be the expression info for the LHS. [isAnd]
  /// should indicate whether the logical operator is "&&" or "||".
  /// [wholeExpression] should be the whole logical binary expression.
  ///
  /// [offset] is the last source offset that should be considered to be part of
  /// the LHS of the logical binary operation. The offset of either character in
  /// the `&&` or `||` token should work, since no expressions can appear in
  /// this range, but the first character of the token is probably the best
  /// choice.
  void logicalBinaryOp_rightBegin(
    ExpressionInfo? leftOperandInfo,
    Node wholeExpression, {
    required bool isAnd,
    int offset = 0,
  });

  /// Call this method after visiting a logical not ("!") expression.
  ///
  /// [operandInfo] should be the [ExpressionInfo] for the subexpression whose
  /// logical value is being negated, or `null` if there is no such info.
  ///
  /// If flow analysis needs to track information about the complete logical not
  /// expression, an [ExpressionInfo] is returned. Otherwise, `null` is
  /// returned.
  ExpressionInfo? logicalNot_end(ExpressionInfo? operandInfo);

  /// Call this method after visiting the left hand side of a logical-or (`||`)
  /// pattern.
  ///
  /// [offset] is the last source offset that should be considered to be part of
  /// the LHS of the logical-or pattern. The offset of either character in the
  /// `&&` or `||` token should work, since no expressions can appear in this
  /// range, but the first character of the token is probably the best choice.
  void logicalOrPattern_afterLhs({int offset = 0});

  /// Call this method before visiting a logical-or (`||`) pattern.
  void logicalOrPattern_begin();

  /// Call this method after visiting a logical-or (`||`) pattern.
  ///
  /// [offset] is the last source offset that should be considered to be part of
  /// the RHS of the logical-or pattern. The end offset of the logical-or
  /// pattern is probably the best choice.
  void logicalOrPattern_end({int offset = 0});

  /// Call this method after processing a relational pattern that uses a
  /// non-equality operator (any operator other than `==` or `!=`).
  void nonEqualityRelationalPattern_end();

  /// Call this method just after visiting a non-null assertion (`x!`)
  /// expression.
  ///
  /// [offset] is the last source offset that should be considered to be part of
  /// the operand. The offset of the `!` token is probably the best choice.
  void nonNullAssert_end(ExpressionInfo? operandInfo, {int offset = 0});

  /// Call this method after visiting the value of a null-aware map entry.
  ///
  /// [offset] is the last source offset that should be considered to be part of
  /// the "value" subexpression. The end offset of the map entry is probably the
  /// best choice.
  void nullAwareMapEntry_end({required bool isKeyNullAware, int offset = 0});

  /// Call this method after visiting the key of a null-aware map entry.
  ///
  /// [offset] is the last source offset that should be considered to be part of
  /// the "key" subexpression. The offset of the `:` token is probably the best
  /// choice.
  void nullAwareMapEntry_valueBegin(
    ExpressionInfo? keyInfo,
    SharedTypeView keyType, {
    required bool isKeyNullAware,
    int offset = 0,
  });

  /// Call this method before visiting the subpattern of a null-check or a
  /// null-assert pattern.
  ///
  /// [isAssert] indicates whether the pattern is a null-check or a null-assert
  /// pattern.
  ///
  /// [matchedValueType] should be the type returned by [getMatchedValueType].
  ///
  /// [offset] is the last source offset that should be considered to be prior
  /// to entry into the pattern. The start offset of the pattern is probably the
  /// best choice.
  bool nullCheckOrAssertPattern_begin({
    required bool isAssert,
    required SharedTypeView matchedValueType,
    int offset = 0,
  });

  /// Call this method after visiting the subpattern of a null-check or a
  /// null-assert pattern.
  void nullCheckOrAssertPattern_end();

  /// Call this method when encountering an expression that is a `null` literal.
  ///
  /// [type] should be the static type of the literal (i.e. the type `Null`).
  ///
  /// Returns the expression info for the null literal.
  ExpressionInfo nullLiteral(SharedTypeView type);

  /// Call this method just after visiting a parenthesized expression.
  ///
  /// [expressionInfo] should be the expression info for the inner expression.
  /// The expression info for the parenthesized expression is returned.
  ExpressionInfo? parenthesizedExpression(ExpressionInfo? expressionInfo);

  /// Call this method just after visiting the right hand side of a pattern
  /// assignment expression, and before visiting the pattern.
  ///
  /// [rhsInfo] is the expression info for the right hand side expression, and
  /// [rhsType] is its static type.
  ///
  /// [offset] is the last source offset that should be considered to be prior
  /// to entry into the pattern. The start offset of the pattern assignment is
  /// probably the best choice.
  void patternAssignment_beforePattern(
    ExpressionInfo? rhsInfo,
    SharedTypeView rhsType, {
    int offset = 0,
  });

  /// Call this method just before visiting the right hand side of a pattern
  /// assignment expression.
  ///
  /// [offset] is the last source offset that should be considered to be part of
  /// the pattern. The offset of the `=` token is probably the best choice.
  void patternAssignment_beforeRhs({int offset = 0});

  /// Call this method after visiting a pattern assignment expression.
  ///
  /// [offset] is the last source offset that should be considered to be part
  /// of the RHS of the assignment. The end offset of the pattern assignment is
  /// probably the best choice.
  void patternAssignment_end({int offset = 0});

  /// Call this method just before visiting the iterable expression in a for-in
  /// loop.
  ///
  /// [offset] is the last source offset that should be considered to be part of
  /// the pattern. The offset of the `in` token is probably the best choice.
  void patternForIn_beforeExpression({int offset = 0});

  /// Call this method just after visiting the expression (which usually
  /// implements `Iterable`, but can also be `dynamic`), and before visiting
  /// the pattern or body.
  ///
  /// [elementType] is the element type of the `Iterable`, or `dynamic`.
  ///
  /// [offset] is the last source offset that should be considered to be prior
  /// to entry into the `for`. The offset of any character in the `for` keyword
  /// (or `await` keyword, if present) should work, since no expressions can
  /// appear in this range, but the first such character is probably the best
  /// choice.
  void patternForIn_beforePattern(SharedTypeView elementType, {int offset = 0});

  /// Call this method after visiting the body.
  ///
  /// [offset] is the last source offset that should be considered to be inside
  /// the body of the `for`. The end offset of the body is probably the best
  /// choice.
  void patternForIn_end({int offset = 0});

  /// Call this method just before visiting the initializer of a pattern
  /// variable declaration.
  ///
  /// [offset] is the last source offset that should be considered to be part of
  /// the pattern. The offset of the `=` token is probably the best choice.
  void patternVariableDeclaration_beforeInitializer({int offset = 0});

  /// Call this method just after visiting the initializer of a pattern variable
  /// declaration, and before visiting the pattern.
  ///
  /// [initializerInfo] is the expression info for the declaration's initializer
  /// expression, and [initializerType] is its static type.
  ///
  /// [offset] is the last source offset that should be considered to be prior
  /// to entry into the pattern. The offset of any character in the `var` or
  /// `final` keyword should work, since no expressions can appear in this
  /// range, but the first character of the keyword is probably the best choice.
  void patternVariableDeclaration_beforePattern(
    ExpressionInfo? initializerInfo,
    SharedTypeView initializerType, {
    int offset = 0,
  });

  /// Call this method after visiting the pattern of a pattern variable
  /// declaration.
  ///
  /// [offset] is the last source offset that should be considered prior to the
  /// variables in the pattern being considered "assigned". The offset of the
  /// `;` that ends the pattern variable declaration is probably the best
  /// choice.
  void patternVariableDeclaration_end({int offset = 0});

  /// Call this method after visiting the subpattern of an object pattern, to
  /// restore the state that was saved by [pushPropertySubpattern].
  void popPropertySubpattern();

  /// Call this method after visiting a pattern's subpattern, to restore the
  /// state that was saved by [pushSubpattern].
  void popSubpattern();

  /// Call this method when writing to the [variable] with type [writtenType] in
  /// a postfix increment or decrement operation.
  ///
  /// There is no return value; it is not necessary for the caller to track any
  /// expression info for the post increment or decrement expression.
  ///
  /// [offset] is the last source offset that should be considered part of the
  /// operand of the postfix increment or decrement operation. The offset of
  /// either character in the `++` or `--` token should work, since no
  /// expressions can appear in this range, but the first character of the token
  /// is probably the best choice.
  void postIncDec(
    Node node,
    Variable variable,
    SharedTypeView writtenType, {
    int offset = 0,
  });

  /// The type that a property named [propertyName] is promoted to, if
  /// the property is currently promoted.
  ///
  /// If the property isn't currently promoted, returns `null`.
  ///
  /// The [target] parameter determines how the property is being looked up. If
  /// it is [ExpressionPropertyTarget], a property of an expression is being
  /// queried, and this method should be called just after visiting the
  /// expression. If it is [ThisPropertyTarget], a property of `this` is being
  /// queried. If it is [SuperPropertyTarget], a property of `super` is being
  /// queried.
  ///
  /// [propertyMember] should be whatever data structure the client uses to keep
  /// track of the field or property being accessed. If not `null`, and field
  /// promotion is enabled for the current library,
  /// [FlowAnalysisOperations.isPropertyPromotable] will be consulted to find
  /// out whether the property is promotable. [unpromotedType] should be the
  /// static type of the value returned by the property get.
  ///
  /// Note: although only fields can be promoted, this method uses the
  /// nomenclature "property" rather than "field", to highlight the fact that
  /// it is not necessary for the client to check whether a property refers to a
  /// field before calling this method; if the property does not refer to a
  /// field, `null` will be returned.
  SharedTypeView? promotedPropertyType(
    PropertyTarget<Expression> target,
    String propertyName,
    Object? propertyMember,
    SharedTypeView unpromotedType,
  );

  /// Retrieves the type that [variable] is promoted to, if it is currently
  /// promoted.
  ///
  /// If the variable isn't currently promoted, returns `null`.
  SharedTypeView? promotedType(Variable variable);

  /// Call this method when visiting a pattern whose semantics constrain the
  /// type of the matched value.
  ///
  /// This could be due to a required type of a declared variable pattern, list
  /// pattern, map pattern, record pattern, object pattern, or wildcard pattern,
  /// or it could be due to the demonstrated type of a record pattern.
  ///
  /// [matchedType] should be the matched value type, and [knownType] should
  /// be the type that the matched value is now known to satisfy.
  ///
  /// If [matchFailsIfWrongType] is `true` (the default), flow analysis models
  /// the usual semantics of a type test in a pattern: if the matched value
  /// fails to have the type [knownType], the pattern will fail to match.
  /// If it is `false`, it models the semantics where the no match failure can
  /// occur (either because the matched value is known, due to other invariants
  /// to have the type [knownType], or because a type test failure would result
  /// in an exception being thrown).
  ///
  /// If [matchMayFailEvenIfCorrectType] is `true`, flow analysis would always
  /// update the unmatched value.
  ///
  /// Returns `true` if [matchedType] is a subtype of [knownType] (and thus the
  /// user might need to be warned of an unnecessary cast or unnecessary
  /// wildcard pattern).
  ///
  /// [offset] is the last source offset that should be considered to be prior
  /// to the promotion taking place.
  bool promoteForPattern({
    required SharedTypeView matchedType,
    required SharedTypeView knownType,
    bool matchFailsIfWrongType = true,
    bool matchMayFailEvenIfCorrectType = false,
    int offset = 0,
  });

  /// Call this method just after visiting a property get expression.
  ///
  /// [propertyName] should be the identifier to the right hand side of the `.`.
  /// [unpromotedType] should be the static type of the value returned by the
  /// property get.
  ///
  /// The [target] parameter determines how the property is being looked up.
  ///
  /// If it is [ExpressionPropertyTarget], a property of an expression was just
  /// visited, and this method should be called just after visiting the
  /// expression. If it is [ThisPropertyTarget], a property of `this` was just
  /// visited. If it is [SuperPropertyTarget], a property of `super` was just
  /// visited.
  ///
  /// [propertyMember] should be whatever data structure the client uses to keep
  /// track of the field or property being accessed. If not `null`, and field
  /// promotion is enabled for the current library,
  /// [FlowAnalysisOperations.isPropertyPromotable] will be consulted to find
  /// out whether the property is promotable. In the event of non-promotion of a
  /// property get, this value can be retrieved from
  /// [PropertyNotPromoted.propertyMember].
  ///
  /// Returns a pair:
  /// - If the property's type is currently promoted, the first element of the
  ///   pair is the promoted type. Otherwise it is `null`.
  /// - The second element of the pair is the expression info for the property
  ///   get.
  (SharedTypeView?, ExpressionInfo?) propertyGet(
    PropertyTarget<Expression> target,
    String propertyName,
    Object? propertyMember,
    SharedTypeView unpromotedType,
  );

  /// The promotion chain associated with the property named [propertyName].
  ///
  /// **For testing only!**
  ///
  /// The promotion chain only contains the promoted-to types, not the original
  /// declared type at the top of the chain. Thus, the list is empty if the
  /// property is not currently promoted.
  ///
  /// The type of [target] determines how the property is looked up:
  /// - If [target] is an [ExpressionPropertyTarget], a property of an
  ///   expression is queried, and this method should be called just after
  ///   calling the method(s) that would normally be called when performing flow
  ///   analysis on the target expression (e.g., [propertyGet] or
  ///   [variableRead]).
  /// - If [target] is [ThisPropertyTarget], a property of `this` is queried.
  /// - If [target] is [SuperPropertyTarget], a property of `super` is queried.
  ///
  /// [propertyMember] should be whatever data structure the client uses to keep
  /// track of the field or property being accessed. If not `null`, and field
  /// promotion is enabled for the current library,
  /// [FlowAnalysisOperations.isPropertyPromotable] will be consulted to find
  /// out whether the property is promotable.
  List<SharedTypeView> propertyPromotionChainForTesting(
    PropertyTarget<Expression> target,
    String propertyName,
    Object? propertyMember,
  );

  /// Call this method just before analyzing a subpattern of an object pattern.
  ///
  /// [propertyName] is the name of the property being accessed by this
  /// subpattern, [propertyMember] is the data structure the client uses to keep
  /// track of the field or property being accessed (as would be passed to
  /// [propertyGet]), and [unpromotedType] is the static type of the field or
  /// property.
  ///
  /// If the property's type is currently promoted, the promoted type is
  /// returned. Otherwise `null` is returned.
  ///
  /// [offset] is the last source offset that should be considered to be prior
  /// to entry into the subpattern. The start offset of the subpattern is
  /// probably the best choice.
  SharedTypeView? pushPropertySubpattern(
    String propertyName,
    Object? propertyMember,
    SharedTypeView unpromotedType, {
    int offset = 0,
  });

  /// Call this method just before analyzing a subpattern of a pattern.
  ///
  /// [matchedType] is the type that should be used to type check the
  /// subpattern.
  ///
  /// Flow analysis makes no assumptions about the relation between the matched
  /// value for the outer pattern and the subpattern.
  ///
  /// [offset] is the last source offset that should be considered to be prior
  /// to entry into the subpattern. The start offset of the subpattern is
  /// probably the best choice.
  void pushSubpattern(SharedTypeView matchedType, {int offset = 0});

  /// Retrieves the SSA node associated with [variable].
  ///
  /// **For testing only!**
  ///
  /// Returns `null` if [variable] is not associated with an SSA node because it
  /// is write captured.
  @visibleForTesting
  SsaNode? ssaNodeForTesting(Variable variable);

  /// Call this method after visiting an `await` expression or `yield`
  /// statement.
  ///
  /// Both of these constructs have the effect of suspending the execution of
  /// the current function and allowing other code to execute, so flow analysis
  /// may need to demote some variables.
  ///
  /// [Node] should be the AST node of the `await` expression or `yield`
  /// statement. This will be reported back via [DemoteViaSuspension.node] if
  /// any promotions are lost due to this suspension.
  ///
  /// [offset] is the last source offset that should be considered to be prior
  /// to the suspension taking place. For an `await` expression, the end offset
  /// of the expression is probably the best choice. For a `yield` statement,
  /// the offset of the `;` is probably the best choice.
  void suspension(Node node, {int offset = 0});

  /// Call this method just after visiting a `case` or `default` body in a
  /// switch statement, or one of the expressions in a branch of a switch
  /// expression.
  ///
  /// See [switch_scrutineeEnd] for details.
  ///
  /// This method returns a boolean indicating whether the end of the case body
  /// is "locally reachable" (i.e. reachable from its start).
  ///
  /// [offset] is the last source offset that should be considered to be part of
  /// the construct that was just visited. For a switch statement, the offset of
  /// the next `case` keyword, `default` keyword, or label is probably the best
  /// choice (or the `}` token, if there are no more branches). For a switch
  /// expression, the offset of the `,` or `}` that terminates the branch is
  /// probably the best choice.
  bool switch_afterCase({int offset = 0});

  /// Call this method just before visiting a `case` or `default` clause in a
  /// switch statement, or one of the patterns in a branch of a switch
  /// expression.
  ///
  /// See [switch_scrutineeEnd] for details.
  ///
  /// [offset] is the last source offset that should be considered prior to
  /// entry to the construct that's about to be visited. For a switch statement,
  /// the offset of `case` keyword, `default` keyword, or label is probably the
  /// best choice. For a switch expression, the start offset of the pattern is
  /// probably the best choice.
  void switch_beginAlternative({int offset = 0});

  /// Call this method just before visiting a sequence of one or more `case` or
  /// `default` clauses in a switch statement that share a body, or before
  /// visiting a branch of a switch expression.
  ///
  /// See [switch_scrutineeEnd] for details.
  void switch_beginAlternatives();

  /// Call this method just after visiting the body of a switch statement.
  ///
  /// See [switch_scrutineeEnd] for details.
  ///
  /// [isExhaustive] indicates whether the switch statement had a "default"
  /// case, or is based on an enumeration and all the enumeration constants
  /// were listed in cases.
  ///
  /// Returns a boolean indicating whether flow analysis was able to prove the
  /// switch statement to be exhaustive (e.g. due to the presence of a `default`
  /// clause, or a pattern that is guaranteed to match the scrutinee type).
  ///
  /// [offset] is the last source offset that should be considered part of the
  /// switch statement or expression. The offset of the `}` token is probably
  /// the best choice.
  bool switch_end(bool isExhaustive, {int offset = 0});

  /// Call this method just after visiting a `case` or `default` clause in a
  /// switch statement, or one of the patterns (with optional guard) in a branch
  /// of a switch expression.
  ///
  /// See [switch_scrutineeEnd] for details.`
  ///
  /// [guardInfo] should be the expression info for the guard expression. If
  /// there is no guard expression, it should be the value returned by a call to
  /// [booleanLiteral], passing a value of `true`.
  ///
  /// If the clause is a `case` clause, [variables] should contain an entry for
  /// all variables defined by the clause's pattern; the key should be the
  /// variable name and the value should be the variable itself. If the clause
  /// is a `default` clause, [variables] should be an empty map.
  ///
  /// [offset] is the last source offset that should be considered part of the
  /// construct that was just visited. For a switch statement, the offset of the
  /// `:` token is probably the best choice. For a switch expression, the offset
  /// of the `=>` token is probably the best choice.
  void switch_endAlternative(
    ExpressionInfo? guardInfo,
    Map<String, Variable> variables, {
    int offset = 0,
  });

  /// Call this method just after visiting a sequence of one or more `case` or
  /// `default` clauses in a switch statement that share a body, or one of the
  /// patterns (with optional guard) in a branch of a switch expression.
  ///
  /// See [switch_scrutineeEnd] for details.
  ///
  /// [node] should be the same node that was passed to
  /// [AssignedVariables.endNode] for the switch statement.
  ///
  /// [hasLabels] indicates whether the case has any labels.
  ///
  /// Returns a data structure describing the relationship among variables
  /// defined by patterns in the various alternatives.
  ///
  /// [offset] is the last source offset that should be considered part of the
  /// construct that was just visited. For a switch statement, the offset of the
  /// `:` token is probably the best choice. For a switch expression, the offset
  /// of the `=>` token is probably the best choice.
  PatternVariableInfo<Variable> switch_endAlternatives(
    Statement? node, {
    required bool hasLabels,
    int offset = 0,
  });

  /// Call this method just after visiting the expression part of a switch
  /// statement or expression.
  ///
  /// [switchStatement] should be the switch statement itself (or `null` if this
  /// is a switch expression).
  ///
  /// The order of visiting a switch statement should be:
  /// - Visit the switch scrutinee.
  /// - Call [switch_scrutineeEnd].
  /// - For each case body:
  ///   - Call [switch_beginAlternatives].
  ///   - For each `case` or `default` clause associated with this case body:
  ///     - Call [switch_beginAlternative].
  ///     - If a pattern is present, visit it.
  ///     - If a guard is present, visit it.
  ///     - Call [switch_endAlternative].
  ///   - Call [switch_endAlternatives].
  ///   - Visit the case body.
  ///   - Call [switch_afterCase].
  /// - Call [switch_end].
  ///
  /// The order of visiting a switch expression should be:
  /// - Visit the switch scrutinee.
  /// - Call [switch_scrutineeEnd].
  /// - For each branch:
  ///   - Call [switch_beginAlternatives].
  ///   - Call [switch_beginAlternative].
  ///   - Visit the branch's pattern.
  ///   - If a guard is present, visit it.
  ///   - Call [switch_endAlternative].
  ///   - Call [switch_endAlternatives].
  ///   - Visit the branch's body.
  ///   - Call [switch_afterCase].
  /// - Call [switch_end].
  ///
  /// [scrutineeInfo] should be the expression info for the expression appearing
  /// in parentheses after the `switch` keyword, and [scrutineeType] should be
  /// its static type.
  ///
  /// [offset] is the last source offset that should be considered to be part of
  /// the scrutinee expression. The offset of the `)` is probably the best
  /// choice.
  void switch_scrutineeEnd(
    Statement? switchStatement,
    ExpressionInfo? scrutineeInfo,
    SharedTypeView scrutineeType, {
    int offset = 0,
  });

  /// Call this method just before changing the binding of `this`.
  ///
  /// [offset] is the last source offset that should be considered to precede
  /// the change to the binding of `this`. For a block-bodied anonymous method,
  /// the offset of the `{` that opens the anonymous block body is probably the
  /// best choice. For an expression-bodied anonymous method, the offset of the
  /// `=>` that opens the anonymous block body is probably the best choice.
  void thisBinding_begin(ExpressionInfo? targetInfo, {int offset = 0});

  /// Call this method just after the end of a `this` binding.
  ///
  /// [offset] is the last source offset that should be considered to precede
  /// restoring the old binding of `this`. For a block-bodied anonymous method,
  /// the offset of the `}` that closes the anonymous block body is probably the
  /// best choice. For an expression-bodied anonymous method, the end offset of
  /// the anonymous method invocation is probably the best choice.
  void thisBinding_end({int offset = 0});

  /// Call this method just after visiting the expression `this` (or the
  /// pseudo-expression `super`, in the case of the analyzer, which represents
  /// `super.x` as a property get whose target is `super`).
  ///
  /// [staticType] should be the static type of `this`.
  ///
  /// [isSuper] indicates whether the expression that was visited was the
  /// pseudo-expression `super`.
  ///
  /// Returns the expression info for the `this` or `super` expression.
  ExpressionInfo thisOrSuper(
    SharedTypeView staticType, {
    required bool isSuper,
  });

  /// Call this method just before visiting the body of a "try/catch" statement.
  ///
  /// The order of visiting a "try/catch" statement should be:
  /// - Call [tryCatchStatement_bodyBegin]
  /// - Visit the try block
  /// - Call [tryCatchStatement_bodyEnd]
  /// - For each catch block:
  ///   - Call [tryCatchStatement_catchBegin]
  ///   - Call [initialize] for the exception and stack trace variables
  ///   - Visit the catch block
  ///   - Call [tryCatchStatement_catchEnd]
  /// - Call [tryCatchStatement_end]
  ///
  /// The order of visiting a "try/catch/finally" statement should be:
  /// - Call [tryFinallyStatement_bodyBegin]
  /// - Call [tryCatchStatement_bodyBegin]
  /// - Visit the try block
  /// - Call [tryCatchStatement_bodyEnd]
  /// - For each catch block:
  ///   - Call [tryCatchStatement_catchBegin]
  ///   - Call [initialize] for the exception and stack trace variables
  ///   - Visit the catch block
  ///   - Call [tryCatchStatement_catchEnd]
  /// - Call [tryCatchStatement_end]
  /// - Call [tryFinallyStatement_finallyBegin]
  /// - Visit the finally block
  /// - Call [tryFinallyStatement_end]
  ///
  /// [offset] is the last source offset that should be considered to be prior
  /// to entry into the `try`. The offset of any character in the `try` keyword
  /// should work, since no expressions can appear in this range, but the first
  /// character of the keyword is probably the best choice.
  void tryCatchStatement_bodyBegin({int offset = 0});

  /// Call this method just after visiting the body of a "try/catch" statement.
  ///
  /// See [tryCatchStatement_bodyBegin] for details.
  ///
  /// [body] should be the same node that was passed to
  /// [AssignedVariables.endNode] for the "try" part of the try/catch statement.
  void tryCatchStatement_bodyEnd(Node body);

  /// Call this method just before visiting a catch clause of a "try/catch"
  /// statement.
  ///
  /// See [tryCatchStatement_bodyBegin] for details.
  ///
  /// [exceptionVariable] should be the exception variable declared by the catch
  /// clause, or `null` if there is no exception variable. Similar for
  /// [stackTraceVariable].
  ///
  /// [offset] is the last source offset that should be considered to be prior
  /// to entry into the catch clause. The offset of the `{` token is probably
  /// the best choice.
  void tryCatchStatement_catchBegin(
    Variable? exceptionVariable,
    Variable? stackTraceVariable, {
    int offset = 0,
  });

  /// Call this method just after visiting a catch clause of a "try/catch"
  /// statement.
  ///
  /// See [tryCatchStatement_bodyBegin] for details.
  void tryCatchStatement_catchEnd();

  /// Call this method just after visiting a "try/catch" statement.
  ///
  /// See [tryCatchStatement_bodyBegin] for details.
  ///
  /// [offset] is the last source offset that should be considered part of the
  /// last catch clause. The offset of the `}` token is probably the best
  /// choice.
  void tryCatchStatement_end({int offset = 0});

  /// Call this method just before visiting the body of a "try/finally"
  /// statement.
  ///
  /// The order of visiting a "try/finally" statement should be:
  /// - Call [tryFinallyStatement_bodyBegin]
  /// - Visit the try block
  /// - Call [tryFinallyStatement_finallyBegin]
  /// - Visit the finally block
  /// - Call [tryFinallyStatement_end]
  ///
  /// See [tryCatchStatement_bodyBegin] for the order of visiting a
  /// "try/catch/finally" statement.
  void tryFinallyStatement_bodyBegin();

  /// Call this method just after visiting a "try/finally" statement.
  ///
  /// See [tryFinallyStatement_bodyBegin] for details.
  ///
  /// [offset] is the last source offset that should be considered part of the
  /// `finally` clause. The offset of the `}` token is probably the best choice.
  void tryFinallyStatement_end({int offset = 0});

  /// Call this method just before visiting the finally block of a "try/finally"
  /// statement.
  ///
  /// See [tryFinallyStatement_bodyBegin] for details.
  ///
  /// [body] should be the same node that was passed to
  /// [AssignedVariables.endNode] for the "try" part of the try/finally
  /// statement.
  ///
  /// [offset] is the last source offset that should be considered to be prior
  /// to entry into the `finally` clause. The offset of the `{` token is
  /// probably the best choice.
  void tryFinallyStatement_finallyBegin(Node body, {int offset = 0});

  /// The promotion chain associated with [variable].
  ///
  /// **For testing only!**
  ///
  /// The promotion chain only contains the promoted-to types, not the original
  /// declared type at the top of the chain. Thus, the list is empty if the
  /// variable is not currently promoted.
  List<SharedTypeView> variablePromotionChainForTesting(Variable variable);

  /// Call this method when encountering an expression that reads the value of
  /// a variable.
  ///
  /// Returns a pair:
  /// - If the variable's type is currently promoted, the first element of the
  ///   pair is the promoted type. Otherwise it is `null`.
  /// - The second element of the pair is the expression info for the variable
  ///   read.
  ///
  /// [offset] is the last source offset that should be considered to be prior
  /// to reading the variable. The offset of the identifier that names the
  /// variable is probably the best choice.
  (SharedTypeView?, ExpressionInfo) variableRead(
    Variable variable, {
    int offset = 0,
  });

  /// Call this method after visiting the condition part of a "while" statement.
  ///
  /// [whileStatement] should be the full while statement. [conditionInfo]
  /// should be the expression info for the condition part of the while
  /// statement.
  ///
  /// [offset] is the last source offset that should be considered to be part of
  /// the condition part of the while statement. The offset of the `)` is
  /// probably the best choice.
  void whileStatement_bodyBegin(
    Statement whileStatement,
    ExpressionInfo? conditionInfo, {
    int offset = 0,
  });

  /// Call this method before visiting the condition part of a "while"
  /// statement.
  ///
  /// [node] should be the same node that was passed to
  /// [AssignedVariables.endNode] for the while statement.
  ///
  /// [offset] is the last source offset that should be considered to be prior
  /// to entry into the while statement. The offset of any character in the
  /// `while` keyword should work, since no expressions can appear in this
  /// range, but the first character of the keyword is probably the best choice.
  void whileStatement_conditionBegin(Node node, {int offset = 0});

  /// Call this method after visiting a "while" statement.
  ///
  /// [offset] is the last source offset that should be considered to be part of
  /// the body of the while statement. The end offset of the while statement is
  /// probably the best choice.
  void whileStatement_end({int offset = 0});

  /// Call this method when an error occurs that may be due to a lack of type
  /// promotion, to retrieve information about why an expression was not
  /// promoted.
  ///
  /// [targetInfo] should be the expression info for the expression of interest.
  ///
  /// The returned value is a function yielding a map whose keys are types that
  /// the user might have been expecting the target to be promoted to, and whose
  /// values are reasons why the corresponding promotion did not occur. The
  /// caller is expected to select which non-promotion reason to report to the
  /// user by seeing which promotion would have prevented the error. (For
  /// example, if an error occurs due to the target having a nullable type, the
  /// caller should report a non-promotion reason associated with non-promotion
  /// to a non-nullable type).
  ///
  /// This method is expected to execute fairly efficiently; the bulk of the
  /// expensive computation is deferred to the function it returns. The reason
  /// for this is that in certain cases, it's not possible to know whether "why
  /// not promoted" information will be needed until long after visiting a node.
  /// (For example, in resolving a call like
  /// `(x as Future<T>).then(y, onError: z)`, we don't know whether an error
  /// should be reported at `y` until we've inferred the type argument to
  /// `then`, which doesn't occur until after visiting `z`). So the caller may
  /// freely call this method after any expression for which an error *might*
  /// need to be generated, and then defer invoking the returned function until
  /// it is determined that an error actually occurred.
  Map<SharedTypeView, NonPromotionReason> Function() whyNotPromoted(
    ExpressionInfo? targetInfo,
  );

  /// Call this method when an error occurs that may be due to a lack of type
  /// promotion, to retrieve information about why an implicit reference to
  /// `this` was not promoted.
  ///
  /// [staticType] is the (unpromoted) type of `this`.
  ///
  /// The returned value is a function yielding a map whose keys are types that
  /// the user might have been expecting `this` to be promoted to, and whose
  /// values are reasons why the corresponding promotion did not occur. The
  /// caller is expected to select which non-promotion reason to report to the
  /// user by seeing which promotion would have prevented the error. (For
  /// example, if an error occurs due to the target having a nullable type, the
  /// caller should report a non-promotion reason associated with non-promotion
  /// to a non-nullable type).
  ///
  /// This method is expected to execute fairly efficiently; the bulk of the
  /// expensive computation is deferred to the function it returns. The reason
  /// for this is that in certain cases, it's not possible to know whether "why
  /// not promoted" information will be needed until long after visiting a node.
  /// (For example, in resolving a call like
  /// `(x as Future<T>).then(y, onError: z)`, we don't know whether an error
  /// should be reported at `y` until we've inferred the type argument to
  /// `then`, which doesn't occur until after visiting `z`). So the caller may
  /// freely call this method after any expression for which an error *might*
  /// need to be generated, and then defer invoking the returned function until
  /// it is determined that an error actually occurred.
  Map<SharedTypeView, NonPromotionReason> Function() whyNotPromotedImplicitThis(
    SharedTypeView staticType,
  );

  /// Registers a write of the given [variable] in the current state.
  ///
  /// [writtenType] should be the type of the value that was written.  [node]
  /// should be the syntactic construct performing the write.
  /// [writtenExpressionInfo] should be the expression info for the expression
  /// that was written, or `null` if the expression that was written is not
  /// directly represented in the source code (this happens, for example, with
  /// compound assignments and with for-each loops).
  ///
  /// Returns the expression info for the full assignment expression.
  ///
  /// This method should not be used for the implicit write to a non-final
  /// variable in its initializer; in that case, use [initialize] instead.
  ///
  /// [offset] is the last source offset that should be considered prior to the
  /// write taking place. For an assignment expression, the expression's end
  /// offset is probably the best choice.
  ExpressionInfo? write(
    Node node,
    Variable variable,
    SharedTypeView writtenType,
    ExpressionInfo? writtenExpressionInfo, {
    int offset = 0,
  });

  /// Prints out a summary of the current state of flow analysis, intended for
  /// debugging use only.
  void _dumpState();
}

/// Alternate implementation of [FlowAnalysis] that prints out inputs and output
/// at the API boundary, for assistance in debugging.
class FlowAnalysisDebug<
  Node extends Object,
  Statement extends Node,
  Expression extends Node,
  Variable extends Object
>
    implements FlowAnalysis<Node, Statement, Expression, Variable> {
  static int _nextCallbackId = 0;

  static Expando<String> _description = new Expando<String>();

  FlowAnalysis<Node, Statement, Expression, Variable> _wrapped;

  bool _exceptionOccurred = false;

  factory FlowAnalysisDebug(
    FlowAnalysisOperations<Variable> operations,
    AssignedVariables<Node, Variable> assignedVariables, {
    required TypeAnalyzerOptions typeAnalyzerOptions,
    required bool enableLog,
  }) {
    print('FlowAnalysisDebug()');
    return new FlowAnalysisDebug._(
      new _FlowAnalysisImpl(
        operations,
        assignedVariables,
        typeAnalyzerOptions: typeAnalyzerOptions,
        enableLog: enableLog,
      ),
    );
  }

  FlowAnalysisDebug._(this._wrapped);

  @override
  bool get isReachable =>
      _wrap('isReachable', () => _wrapped.isReachable, isQuery: true);

  @override
  FlowAnalysisOperations<Variable> get operations => _wrapped.operations;

  @override
  SharedTypeView? get promotedTypeOfThis {
    return _wrap(
      'promotedTypeOfThis',
      () => _wrapped.promotedTypeOfThis,
      isQuery: true,
    );
  }

  @override
  void anonymousBlockBody_begin({int offset = 0}) {
    return _wrap(
      'anonymousBlockBody_begin(offset: $offset)',
      () => _wrapped.anonymousBlockBody_begin(offset: offset),
    );
  }

  @override
  void anonymousBlockBody_end({int offset = 0}) {
    return _wrap(
      'anonymousBlockBody_end(offset: $offset)',
      () => _wrapped.anonymousBlockBody_end(offset: offset),
    );
  }

  @override
  void asExpression_end(
    ExpressionInfo? subExpressionInfo, {
    required SharedTypeView subExpressionType,
    required SharedTypeView castType,
    int offset = 0,
  }) {
    _wrap(
      'asExpression_end($subExpressionInfo, subExpressionType: '
      '$subExpressionType, castType: $castType, offset: $offset)',
      () => _wrapped.asExpression_end(
        subExpressionInfo,
        subExpressionType: subExpressionType,
        castType: castType,
        offset: offset,
      ),
    );
  }

  @override
  void assert_afterCondition(ExpressionInfo? conditionInfo, {int offset = 0}) {
    _wrap(
      'assert_afterCondition($conditionInfo, offset: $offset)',
      () => _wrapped.assert_afterCondition(conditionInfo, offset: offset),
    );
  }

  @override
  void assert_begin({int offset = 0}) {
    _wrap(
      'assert_begin(offset: $offset)',
      () => _wrapped.assert_begin(offset: offset),
    );
  }

  @override
  void assert_end({int offset = 0}) {
    _wrap(
      'assert_end(offset: $offset)',
      () => _wrapped.assert_end(offset: offset),
    );
  }

  @override
  void assignedVariablePattern(
    Node node,
    Variable variable,
    SharedTypeView writtenType, {
    int offset = 0,
  }) {
    _wrap(
      'assignedVariablePattern($node, $variable, $writtenType, '
      'offset: $offset)',
      () => _wrapped.assignedVariablePattern(
        node,
        variable,
        writtenType,
        offset: offset,
      ),
    );
  }

  @override
  void assignMatchedPatternVariable(
    Variable variable,
    int promotionKey, {
    int offset = 0,
  }) {
    _wrap(
      'assignMatchedPatternVariable($variable, $promotionKey, offset: $offset)',
      () => _wrapped.assignMatchedPatternVariable(
        variable,
        promotionKey,
        offset: offset,
      ),
    );
  }

  @override
  ExpressionInfo booleanLiteral(bool value) {
    return _wrap(
      'booleanLiteral($value)',
      () => _wrapped.booleanLiteral(value),
      isQuery: true,
      isPure: false,
    );
  }

  @override
  SharedTypeView cascadeExpression_afterTarget(
    ExpressionInfo? targetInfo,
    SharedTypeView targetType, {
    required bool isNullAware,
    Variable? guardVariable,
    int offset = 0,
  }) {
    return _wrap(
      'cascadeExpression_afterTarget($targetInfo, $targetType, isNullAware: '
      '$isNullAware, guardVariable: $guardVariable, offset: $offset)',
      () => _wrapped.cascadeExpression_afterTarget(
        targetInfo,
        targetType,
        isNullAware: isNullAware,
        guardVariable: guardVariable,
        offset: offset,
      ),
      isQuery: true,
      isPure: false,
    );
  }

  @override
  ExpressionInfo cascadeExpression_end() {
    return _wrap(
      'cascadeExpression_end()',
      () => _wrapped.cascadeExpression_end(),
      isQuery: true,
      isPure: false,
    );
  }

  @override
  void checkOffset(int offset) {
    return _wrap('checkOffset($offset)', () => _wrapped.checkOffset(offset));
  }

  @override
  void conditional_conditionBegin({int offset = 0}) {
    _wrap(
      'conditional_conditionBegin(offset: $offset)',
      () => _wrapped.conditional_conditionBegin(offset: offset),
    );
  }

  @override
  void conditional_elseBegin(
    ExpressionInfo? thenExpressionInfo,
    SharedTypeView thenType, {
    int offset = 0,
  }) {
    _wrap(
      'conditional_elseBegin($thenExpressionInfo, $thenType, offset: $offset)',
      () => _wrapped.conditional_elseBegin(
        thenExpressionInfo,
        thenType,
        offset: offset,
      ),
    );
  }

  @override
  ExpressionInfo conditional_end(
    SharedTypeView conditionalExpressionType,
    ExpressionInfo? elseExpressionInfo,
    SharedTypeView elseType, {
    int offset = 0,
  }) {
    return _wrap(
      'conditional_end($conditionalExpressionType, '
      '$elseExpressionInfo, $elseType, offset: $offset)',
      () => _wrapped.conditional_end(
        conditionalExpressionType,
        elseExpressionInfo,
        elseType,
        offset: offset,
      ),
      isQuery: true,
      isPure: false,
    );
  }

  @override
  void conditional_thenBegin(
    ExpressionInfo? conditionInfo,
    Node conditionalExpression, {
    int offset = 0,
  }) {
    _wrap(
      'conditional_thenBegin($conditionInfo, $conditionalExpression, '
      'offset: $offset)',
      () => _wrapped.conditional_thenBegin(
        conditionInfo,
        conditionalExpression,
        offset: offset,
      ),
    );
  }

  @override
  void constantPattern_end(
    ExpressionInfo? expressionInfo,
    SharedTypeView type, {
    required bool patternsEnabled,
    required SharedTypeView matchedValueType,
    int offset = 0,
  }) {
    _wrap(
      'constantPattern_end($expressionInfo, $type, '
      'patternsEnabled: $patternsEnabled, '
      'matchedValueType: $matchedValueType, offset: $offset)',
      () => _wrapped.constantPattern_end(
        expressionInfo,
        type,
        patternsEnabled: patternsEnabled,
        matchedValueType: matchedValueType,
        offset: offset,
      ),
    );
  }

  @override
  void copyPromotionData({
    required int sourceKey,
    required int destinationKey,
    int offset = 0,
  }) {
    _wrap(
      'copyPromotionData(sourceKey: $sourceKey, '
      'destinationKey: $destinationKey, offset: $offset)',
      () => _wrapped.copyPromotionData(
        sourceKey: sourceKey,
        destinationKey: destinationKey,
        offset: offset,
      ),
    );
  }

  @override
  void declare(
    Variable variable,
    SharedTypeView staticType, {
    required bool initialized,
    int offset = 0,
  }) {
    _wrap(
      'declare($variable, $staticType, initialized: $initialized, '
      'offset: $offset)',
      () => _wrapped.declare(
        variable,
        staticType,
        initialized: initialized,
        offset: offset,
      ),
    );
  }

  @override
  int declaredVariablePattern({
    required SharedTypeView matchedType,
    required SharedTypeView staticType,
    bool isFinal = false,
    bool isLate = false,
    required bool isImplicitlyTyped,
    int offset = 0,
  }) {
    return _wrap(
      'declaredVariablePattern(matchedType: $matchedType, '
      'staticType: $staticType, isFinal: $isFinal, '
      'isLate: $isLate, isImplicitlyTyped: $isImplicitlyTyped, '
      'offset: $offset)',
      () => _wrapped.declaredVariablePattern(
        matchedType: matchedType,
        staticType: staticType,
        isFinal: isFinal,
        isLate: isLate,
        isImplicitlyTyped: isImplicitlyTyped,
        offset: offset,
      ),
      isQuery: true,
      isPure: false,
    );
  }

  @override
  void doStatement_bodyBegin(Statement doStatement, {int offset = 0}) {
    return _wrap(
      'doStatement_bodyBegin($doStatement, offset: $offset)',
      () => _wrapped.doStatement_bodyBegin(doStatement, offset: offset),
    );
  }

  @override
  void doStatement_conditionBegin({int offset = 0}) {
    return _wrap(
      'doStatement_conditionBegin(offset: $offset)',
      () => _wrapped.doStatement_conditionBegin(offset: offset),
    );
  }

  @override
  void doStatement_end(ExpressionInfo? conditionInfo, {int offset = 0}) {
    return _wrap(
      'doStatement_end($conditionInfo, offset: $offset)',
      () => _wrapped.doStatement_end(conditionInfo, offset: offset),
    );
  }

  @override
  ExpressionInfo? equalityOperation_end(
    ExpressionInfo? leftOperandInfo,
    SharedTypeView leftOperandType,
    ExpressionInfo? rightOperandInfo,
    SharedTypeView rightOperandType, {
    bool notEqual = false,
  }) {
    return _wrap(
      'equalityOperation_end($leftOperandInfo, '
      '$leftOperandType, $rightOperandInfo, $rightOperandType, notEqual: '
      '$notEqual)',
      () => _wrapped.equalityOperation_end(
        leftOperandInfo,
        leftOperandType,
        rightOperandInfo,
        rightOperandType,
        notEqual: notEqual,
      ),
      isQuery: true,
      isPure: false,
    );
  }

  @override
  void equalityRelationalPattern_end(
    ExpressionInfo? operandInfo,
    SharedTypeView operandType, {
    bool notEqual = false,
    required SharedTypeView matchedValueType,
    int offset = 0,
  }) {
    _wrap(
      'equalityRelationalPattern_end($operandInfo, $operandType, '
      'notEqual: $notEqual, matchedValueType: $matchedValueType, '
      'offset: $offset)',
      () => _wrapped.equalityRelationalPattern_end(
        operandInfo,
        operandType,
        notEqual: notEqual,
        matchedValueType: matchedValueType,
        offset: offset,
      ),
    );
  }

  @override
  void finish() {
    if (_exceptionOccurred) {
      _wrap('finish() (skipped)', () {}, isPure: true);
    } else {
      _wrap('finish()', () => _wrapped.finish(), isPure: true);
    }
  }

  @override
  void for_bodyBegin(
    Statement? node,
    ExpressionInfo? conditionInfo, {
    int offset = 0,
  }) {
    _wrap(
      'for_bodyBegin($node, $conditionInfo, offset: $offset)',
      () => _wrapped.for_bodyBegin(node, conditionInfo, offset: offset),
    );
  }

  @override
  void for_conditionBegin(Node node, {int offset = 0}) {
    _wrap(
      'for_conditionBegin($node, offset: $offset)',
      () => _wrapped.for_conditionBegin(node, offset: offset),
    );
  }

  @override
  void for_end({int offset = 0}) {
    _wrap('for_end(offset: $offset)', () => _wrapped.for_end(offset: offset));
  }

  @override
  void for_updaterBegin({int offset = 0}) {
    _wrap(
      'for_updaterBegin(offset: $offset)',
      () => _wrapped.for_updaterBegin(offset: offset),
    );
  }

  @override
  void forEach_bodyBegin(Node node, {int offset = 0}) {
    return _wrap(
      'forEach_bodyBegin($node, offset: $offset)',
      () => _wrapped.forEach_bodyBegin(node, offset: offset),
    );
  }

  @override
  void forEach_end({int offset = 0}) {
    return _wrap(
      'forEach_end(offset: $offset)',
      () => _wrapped.forEach_end(offset: offset),
    );
  }

  @override
  void functionExpression_begin(Node node, {int offset = 0}) {
    _wrap(
      'functionExpression_begin($node, offset: $offset)',
      () => _wrapped.functionExpression_begin(node, offset: offset),
    );
  }

  @override
  void functionExpression_end({int offset = 0}) {
    _wrap(
      'functionExpression_end(offset: $offset)',
      () => _wrapped.functionExpression_end(offset: offset),
    );
  }

  @override
  PromotionInfo? getCurrentPromotionInfo() {
    return _wrap(
      'getCurrentPromotionInfo()',
      () => _wrapped.getCurrentPromotionInfo(),
      isQuery: true,
    );
  }

  @override
  int getCurrentThisBinding() {
    return _wrap(
      'getCurrentThisBinding()',
      () => _wrapped.getCurrentThisBinding(),
      isQuery: true,
    );
  }

  @override
  FlowAnalysisLog? getLog() {
    return _wrap(
      'getLog()',
      () => _wrapped.getLog(),
      isQuery: true,
      isPure: false,
    );
  }

  @override
  SharedTypeView getMatchedValueType() {
    return _wrap(
      'getMatchedValueType()',
      () => _wrapped.getMatchedValueType(),
      isQuery: true,
    );
  }

  @override
  void handleBreak(Statement? target, {int offset = 0}) {
    _wrap(
      'handleBreak($target, offset: $offset)',
      () => _wrapped.handleBreak(target, offset: offset),
    );
  }

  @override
  void handleContinue(Statement? target, {int offset = 0}) {
    _wrap(
      'handleContinue($target, offset: $offset)',
      () => _wrapped.handleContinue(target, offset: offset),
    );
  }

  @override
  void handleExit({int offset = 0}) {
    _wrap(
      'handleExit(offset: $offset)',
      () => _wrapped.handleExit(offset: offset),
    );
  }

  @override
  void handleReturn({int offset = 0}) {
    _wrap(
      'handleReturn(offset: $offset)',
      () => _wrapped.handleReturn(offset: offset),
    );
  }

  @override
  void ifCaseStatement_afterExpression(
    ExpressionInfo? scrutineeInfo,
    SharedTypeView scrutineeType, {
    int offset = 0,
  }) {
    _wrap(
      'ifCaseStatement_afterExpression($scrutineeInfo, $scrutineeType, '
      'offset: $offset)',
      () => _wrapped.ifCaseStatement_afterExpression(
        scrutineeInfo,
        scrutineeType,
        offset: offset,
      ),
    );
  }

  @override
  void ifCaseStatement_begin({int offset = 0}) {
    _wrap(
      'ifCaseStatement_begin(offset: $offset)',
      () => _wrapped.ifCaseStatement_begin(offset: offset),
    );
  }

  @override
  void ifCaseStatement_thenBegin(ExpressionInfo? guardInfo, {int offset = 0}) {
    _wrap(
      'ifCaseStatement_thenBegin($guardInfo, offset: $offset)',
      () => _wrapped.ifCaseStatement_thenBegin(guardInfo, offset: offset),
    );
  }

  @override
  void ifNullExpression_end({int offset = 0}) {
    return _wrap(
      'ifNullExpression_end(offset: $offset)',
      () => _wrapped.ifNullExpression_end(offset: offset),
    );
  }

  @override
  void ifNullExpression_rightBegin(
    ExpressionInfo? leftHandSideInfo,
    SharedTypeView leftHandSideType, {
    int offset = 0,
  }) {
    _wrap(
      'ifNullExpression_rightBegin($leftHandSideInfo, $leftHandSideType, '
      'offset: $offset)',
      () => _wrapped.ifNullExpression_rightBegin(
        leftHandSideInfo,
        leftHandSideType,
        offset: offset,
      ),
    );
  }

  @override
  void ifStatement_conditionBegin({int offset = 0}) {
    return _wrap(
      'ifStatement_conditionBegin(offset: $offset)',
      () => _wrapped.ifStatement_conditionBegin(offset: offset),
    );
  }

  @override
  void ifStatement_elseBegin({int offset = 0}) {
    return _wrap(
      'ifStatement_elseBegin(offset: $offset)',
      () => _wrapped.ifStatement_elseBegin(offset: offset),
    );
  }

  @override
  void ifStatement_end(bool hasElse, {int offset = 0}) {
    _wrap(
      'ifStatement_end($hasElse, offset: $offset)',
      () => _wrapped.ifStatement_end(hasElse, offset: offset),
    );
  }

  @override
  void ifStatement_thenBegin(
    ExpressionInfo? conditionInfo,
    Node ifNode, {
    int offset = 0,
  }) {
    _wrap(
      'ifStatement_thenBegin($conditionInfo, $ifNode, offset: $offset)',
      () =>
          _wrapped.ifStatement_thenBegin(conditionInfo, ifNode, offset: offset),
    );
  }

  @override
  void initialize(
    Variable variable,
    SharedTypeView matchedType,
    ExpressionInfo? initializerExpressionInfo, {
    required bool isFinal,
    required bool isLate,
    required bool isImplicitlyTyped,
    bool inheritPromotableProperties = false,
    int offset = 0,
  }) {
    _wrap(
      'initialize($variable, $matchedType, $initializerExpressionInfo, '
      'isFinal: $isFinal, isLate: $isLate, '
      'isImplicitlyTyped: $isImplicitlyTyped, '
      'inheritPromotableProperties: $inheritPromotableProperties, '
      'offset: $offset)',
      () => _wrapped.initialize(
        variable,
        matchedType,
        initializerExpressionInfo,
        isFinal: isFinal,
        isLate: isLate,
        isImplicitlyTyped: isImplicitlyTyped,
        inheritPromotableProperties: inheritPromotableProperties,
        offset: offset,
      ),
    );
  }

  @override
  bool isAssigned(Variable variable) {
    return _wrap(
      'isAssigned($variable)',
      () => _wrapped.isAssigned(variable),
      isQuery: true,
    );
  }

  @override
  ExpressionInfo? isExpression_end(
    ExpressionInfo? subExpressionInfo,
    bool isNot, {
    required SharedTypeView subExpressionType,
    required SharedTypeView checkedType,
  }) {
    return _wrap(
      'isExpression_end($subExpressionInfo, $isNot, '
      'subExpressionType: $subExpressionType, checkedType: $checkedType)',
      () => _wrapped.isExpression_end(
        subExpressionInfo,
        isNot,
        subExpressionType: subExpressionType,
        checkedType: checkedType,
      ),
      isQuery: true,
      isPure: false,
    );
  }

  @override
  bool isUnassigned(Variable variable) {
    return _wrap(
      'isUnassigned($variable)',
      () => _wrapped.isUnassigned(variable),
      isQuery: true,
    );
  }

  @override
  void labeledStatement_begin(Statement node, {int offset = 0}) {
    return _wrap(
      'labeledStatement_begin($node, offset: $offset)',
      () => _wrapped.labeledStatement_begin(node, offset: offset),
    );
  }

  @override
  void labeledStatement_end({int offset = 0}) {
    return _wrap(
      'labeledStatement_end(offset: $offset)',
      () => _wrapped.labeledStatement_end(offset: offset),
    );
  }

  @override
  void lateInitializer_begin(Node node, {int offset = 0}) {
    _wrap(
      'lateInitializer_begin($node, offset: $offset)',
      () => _wrapped.lateInitializer_begin(node, offset: offset),
    );
  }

  @override
  void lateInitializer_end({int offset = 0}) {
    _wrap(
      'lateInitializer_end(offset: $offset)',
      () => _wrapped.lateInitializer_end(offset: offset),
    );
  }

  @override
  void logicalBinaryOp_begin({int offset = 0}) {
    _wrap(
      'logicalBinaryOp_begin(offset: $offset)',
      () => _wrapped.logicalBinaryOp_begin(offset: offset),
    );
  }

  @override
  ExpressionInfo logicalBinaryOp_end(
    ExpressionInfo? rightOperandInfo, {
    required bool isAnd,
    int offset = 0,
  }) {
    return _wrap(
      'logicalBinaryOp_end($rightOperandInfo, isAnd: $isAnd, offset: $offset)',
      () => _wrapped.logicalBinaryOp_end(
        rightOperandInfo,
        isAnd: isAnd,
        offset: offset,
      ),
      isQuery: true,
      isPure: false,
    );
  }

  @override
  void logicalBinaryOp_rightBegin(
    ExpressionInfo? leftOperandInfo,
    Node wholeExpression, {
    required bool isAnd,
    int offset = 0,
  }) {
    _wrap(
      'logicalBinaryOp_rightBegin($leftOperandInfo, $wholeExpression, '
      'isAnd: $isAnd, offset: $offset)',
      () => _wrapped.logicalBinaryOp_rightBegin(
        leftOperandInfo,
        wholeExpression,
        isAnd: isAnd,
        offset: offset,
      ),
    );
  }

  @override
  ExpressionInfo? logicalNot_end(ExpressionInfo? operandInfo) {
    return _wrap(
      'logicalNot_end($operandInfo)',
      () => _wrapped.logicalNot_end(operandInfo),
      isQuery: true,
    );
  }

  @override
  void logicalOrPattern_afterLhs({int offset = 0}) {
    _wrap(
      'logicalOrPattern_afterLhs(offset: $offset)',
      () => _wrapped.logicalOrPattern_afterLhs(offset: offset),
    );
  }

  @override
  void logicalOrPattern_begin() {
    _wrap('logicalOrPattern_begin()', () => _wrapped.logicalOrPattern_begin());
  }

  @override
  void logicalOrPattern_end({int offset = 0}) {
    _wrap(
      'logicalOrPattern_end(offset: $offset)',
      () => _wrapped.logicalOrPattern_end(offset: offset),
    );
  }

  @override
  void nonEqualityRelationalPattern_end() {
    _wrap(
      'nonEqualityRelationalPattern_end()',
      () => _wrapped.nonEqualityRelationalPattern_end(),
    );
  }

  @override
  void nonNullAssert_end(ExpressionInfo? operandInfo, {int offset = 0}) {
    return _wrap(
      'nonNullAssert_end($operandInfo, offset: $offset)',
      () => _wrapped.nonNullAssert_end(operandInfo, offset: offset),
    );
  }

  @override
  void nullAwareAccess_end({int offset = 0}) {
    _wrap(
      'nullAwareAccess_end(offset: $offset)',
      () => _wrapped.nullAwareAccess_end(offset: offset),
    );
  }

  @override
  ExpressionInfo? nullAwareAccess_rightBegin(
    ExpressionInfo? targetInfo,
    SharedTypeView targetType, {
    Variable? guardVariable,
    int offset = 0,
  }) {
    return _wrap(
      'nullAwareAccess_rightBegin($targetInfo, $targetType, '
      'guardVariable: $guardVariable, offset: $offset)',
      () => _wrapped.nullAwareAccess_rightBegin(
        targetInfo,
        targetType,
        guardVariable: guardVariable,
        offset: offset,
      ),
      isQuery: true,
      isPure: false,
    );
  }

  @override
  void nullAwareMapEntry_end({required bool isKeyNullAware, int offset = 0}) {
    return _wrap(
      'nullAwareMapEntry_end(isKeyNullAware: $isKeyNullAware, offset: $offset)',
      () => _wrapped.nullAwareMapEntry_end(
        isKeyNullAware: isKeyNullAware,
        offset: offset,
      ),
    );
  }

  @override
  void nullAwareMapEntry_valueBegin(
    ExpressionInfo? keyInfo,
    SharedTypeView keyType, {
    required bool isKeyNullAware,
    int offset = 0,
  }) {
    _wrap(
      'nullAwareMapEntry_valueBegin($keyInfo, $keyType, '
      'isKeyNullAware: $isKeyNullAware, offset: $offset)',
      () => _wrapped.nullAwareMapEntry_valueBegin(
        keyInfo,
        keyType,
        isKeyNullAware: isKeyNullAware,
        offset: offset,
      ),
    );
  }

  @override
  bool nullCheckOrAssertPattern_begin({
    required bool isAssert,
    required SharedTypeView matchedValueType,
    int offset = 0,
  }) {
    return _wrap(
      'nullCheckOrAssertPattern_begin(isAssert: $isAssert, '
      'matchedValueType: $matchedValueType, offset: $offset)',
      () => _wrapped.nullCheckOrAssertPattern_begin(
        isAssert: isAssert,
        matchedValueType: matchedValueType,
        offset: offset,
      ),
      isQuery: true,
      isPure: false,
    );
  }

  @override
  void nullCheckOrAssertPattern_end() {
    _wrap(
      'nullCheckOrAssertPattern_end()',
      () => _wrapped.nullCheckOrAssertPattern_end(),
    );
  }

  @override
  ExpressionInfo nullLiteral(SharedTypeView type) {
    return _wrap(
      'nullLiteral($type)',
      () => _wrapped.nullLiteral(type),
      isQuery: true,
      isPure: false,
    );
  }

  @override
  ExpressionInfo? parenthesizedExpression(ExpressionInfo? expressionInfo) {
    return _wrap(
      'parenthesizedExpression($expressionInfo)',
      () => _wrapped.parenthesizedExpression(expressionInfo),
      isQuery: true,
      isPure: false,
    );
  }

  @override
  void patternAssignment_beforePattern(
    ExpressionInfo? rhsInfo,
    SharedTypeView rhsType, {
    int offset = 0,
  }) {
    _wrap(
      'patternAssignment_beforePattern($rhsInfo, $rhsType, offset: $offset)',
      () => _wrapped.patternAssignment_beforePattern(
        rhsInfo,
        rhsType,
        offset: offset,
      ),
    );
  }

  @override
  void patternAssignment_beforeRhs({int offset = 0}) {
    _wrap(
      'patternAssignment_beforeRhs(offset: $offset)',
      () => _wrapped.patternAssignment_beforeRhs(offset: offset),
    );
  }

  @override
  void patternAssignment_end({int offset = 0}) {
    _wrap(
      'patternAssignment_end(offset: $offset)',
      () => _wrapped.patternAssignment_end(offset: offset),
    );
  }

  @override
  void patternForIn_beforeExpression({int offset = 0}) {
    _wrap(
      'patternForIn_beforeExpression(offset: $offset)',
      () => _wrapped.patternForIn_beforeExpression(offset: offset),
    );
  }

  @override
  void patternForIn_beforePattern(
    SharedTypeView elementType, {
    int offset = 0,
  }) {
    _wrap(
      'patternForIn_beforePattern($elementType, offset: $offset)',
      () => _wrapped.patternForIn_beforePattern(elementType, offset: offset),
    );
  }

  @override
  void patternForIn_end({int offset = 0}) {
    _wrap(
      'patternForIn_end(offset: $offset)',
      () => _wrapped.patternForIn_end(offset: offset),
    );
  }

  @override
  void patternVariableDeclaration_beforeInitializer({int offset = 0}) {
    _wrap(
      'patternVariableDeclaration_beforeInitializer(offset: $offset)',
      () =>
          _wrapped.patternVariableDeclaration_beforeInitializer(offset: offset),
    );
  }

  @override
  void patternVariableDeclaration_beforePattern(
    ExpressionInfo? initializerInfo,
    SharedTypeView initializerType, {
    int offset = 0,
  }) {
    _wrap(
      'patternVariableDeclaration_beforePattern($initializerInfo, '
      '$initializerType, offset: $offset)',
      () => _wrapped.patternVariableDeclaration_beforePattern(
        initializerInfo,
        initializerType,
        offset: offset,
      ),
    );
  }

  @override
  void patternVariableDeclaration_end({int offset = 0}) {
    _wrap(
      'patternVariableDeclaration_end(offset: $offset)',
      () => _wrapped.patternVariableDeclaration_end(offset: offset),
    );
  }

  @override
  void popPropertySubpattern() {
    _wrap('popPropertySubpattern()', () => _wrapped.popPropertySubpattern());
  }

  @override
  void popSubpattern() {
    _wrap('popSubpattern()', () => _wrapped.popSubpattern());
  }

  @override
  void postIncDec(
    Node node,
    Variable variable,
    SharedTypeView writtenType, {
    int offset = 0,
  }) {
    _wrap(
      'postIncDec(offset: $offset)',
      () => _wrapped.postIncDec(node, variable, writtenType, offset: offset),
    );
  }

  @override
  SharedTypeView? promotedPropertyType(
    PropertyTarget<Expression> target,
    String propertyName,
    Object? propertyMember,
    SharedTypeView unpromotedType,
  ) {
    return _wrap(
      'promotedPropertyType($target, $propertyName, $propertyMember, '
      '$unpromotedType)',
      () => _wrapped.promotedPropertyType(
        target,
        propertyName,
        propertyMember,
        unpromotedType,
      ),
      isQuery: true,
    );
  }

  @override
  SharedTypeView? promotedType(Variable variable) {
    return _wrap(
      'promotedType($variable)',
      () => _wrapped.promotedType(variable),
      isQuery: true,
    );
  }

  @override
  bool promoteForPattern({
    required SharedTypeView matchedType,
    required SharedTypeView knownType,
    bool matchFailsIfWrongType = true,
    bool matchMayFailEvenIfCorrectType = false,
    int offset = 0,
  }) {
    return _wrap(
      'patternRequiredType(matchedType: $matchedType, '
      'requiredType: $knownType, '
      'matchFailsIfWrongType: $matchFailsIfWrongType, '
      'matchMayFailEvenIfCorrectType: $matchMayFailEvenIfCorrectType, '
      'offset: $offset)',
      () => _wrapped.promoteForPattern(
        matchedType: matchedType,
        knownType: knownType,
        matchFailsIfWrongType: matchFailsIfWrongType,
        matchMayFailEvenIfCorrectType: matchMayFailEvenIfCorrectType,
        offset: offset,
      ),
      isQuery: true,
      isPure: false,
    );
  }

  @override
  (SharedTypeView?, ExpressionInfo?) propertyGet(
    PropertyTarget<Expression> target,
    String propertyName,
    Object? propertyMember,
    SharedTypeView unpromotedType,
  ) {
    return _wrap(
      'propertyGet($target, $propertyName, '
      '$propertyMember, $unpromotedType)',
      () => _wrapped.propertyGet(
        target,
        propertyName,
        propertyMember,
        unpromotedType,
      ),
      isQuery: true,
      isPure: false,
    );
  }

  @override
  List<SharedTypeView> propertyPromotionChainForTesting(
    PropertyTarget<Expression> target,
    String propertyName,
    Object? propertyMember,
  ) {
    return _wrap(
      'propertyPromotionChainForTesting($target, $propertyName, '
      '$propertyMember)',
      () => _wrapped.propertyPromotionChainForTesting(
        target,
        propertyName,
        propertyMember,
      ),
      isQuery: true,
    );
  }

  @override
  SharedTypeView? pushPropertySubpattern(
    String propertyName,
    Object? propertyMember,
    SharedTypeView unpromotedType, {
    int offset = 0,
  }) {
    return _wrap(
      'pushPropertySubpattern($propertyName, $propertyMember, '
      '$unpromotedType, offset: $offset)',
      () => _wrapped.pushPropertySubpattern(
        propertyName,
        propertyMember,
        unpromotedType,
        offset: offset,
      ),
      isQuery: true,
      isPure: false,
    );
  }

  @override
  void pushSubpattern(SharedTypeView matchedType, {int offset = 0}) {
    _wrap(
      'pushSubpattern($matchedType, offset: $offset)',
      () => _wrapped.pushSubpattern(matchedType, offset: offset),
    );
  }

  @override
  SsaNode? ssaNodeForTesting(Variable variable) {
    return _wrap(
      'ssaNodeForTesting($variable)',
      () => _wrapped.ssaNodeForTesting(variable),
      isQuery: true,
    );
  }

  @override
  void suspension(Node node, {int offset = 0}) {
    _wrap(
      'suspension($node, offset: $offset)',
      () => _wrapped.suspension(node, offset: offset),
    );
  }

  @override
  bool switch_afterCase({int offset = 0}) {
    return _wrap(
      'switch_afterCase(offset: $offset)',
      () => _wrapped.switch_afterCase(offset: offset),
      isPure: false,
      isQuery: true,
    );
  }

  @override
  void switch_beginAlternative({int offset = 0}) {
    _wrap(
      'switch_beginAlternative(offset: $offset)',
      () => _wrapped.switch_beginAlternative(offset: offset),
    );
  }

  @override
  void switch_beginAlternatives() {
    _wrap(
      'switch_beginAlternatives()',
      () => _wrapped.switch_beginAlternatives(),
    );
  }

  @override
  bool switch_end(bool isExhaustive, {int offset = 0}) {
    return _wrap(
      'switch_end($isExhaustive, offset: $offset)',
      () => _wrapped.switch_end(isExhaustive, offset: offset),
      isQuery: true,
      isPure: false,
    );
  }

  @override
  void switch_endAlternative(
    ExpressionInfo? guardInfo,
    Map<String, Variable> variables, {
    int offset = 0,
  }) {
    _wrap(
      'switch_endAlternative($guardInfo, $variables, offset: $offset)',
      () =>
          _wrapped.switch_endAlternative(guardInfo, variables, offset: offset),
    );
  }

  @override
  PatternVariableInfo<Variable> switch_endAlternatives(
    Statement? node, {
    required bool hasLabels,
    int offset = 0,
  }) {
    return _wrap(
      'switch_endAlternatives($node, hasLabels: $hasLabels, '
      'offset: $offset)',
      () => _wrapped.switch_endAlternatives(
        node,
        hasLabels: hasLabels,
        offset: offset,
      ),
      isQuery: true,
      isPure: false,
    );
  }

  @override
  void switch_scrutineeEnd(
    Statement? switchStatement,
    ExpressionInfo? scrutineeInfo,
    SharedTypeView scrutineeType, {
    int offset = 0,
  }) {
    _wrap(
      'switch_scrutineeEnd($switchStatement, $scrutineeInfo, '
      '$scrutineeType, offset: $offset)',
      () => _wrapped.switch_scrutineeEnd(
        switchStatement,
        scrutineeInfo,
        scrutineeType,
        offset: offset,
      ),
    );
  }

  @override
  void thisBinding_begin(ExpressionInfo? targetInfo, {int offset = 0}) {
    _wrap(
      'thisBinding_begin($targetInfo, offset: $offset)',
      () => _wrapped.thisBinding_begin(targetInfo, offset: offset),
    );
  }

  @override
  void thisBinding_end({int offset = 0}) {
    _wrap(
      'thisBinding_end(offset: $offset)',
      () => _wrapped.thisBinding_end(offset: offset),
    );
  }

  @override
  ExpressionInfo thisOrSuper(
    SharedTypeView staticType, {
    required bool isSuper,
  }) {
    return _wrap(
      'thisOrSuper($staticType, isSuper: $isSuper)',
      () => _wrapped.thisOrSuper(staticType, isSuper: isSuper),
      isQuery: true,
      isPure: false,
    );
  }

  @override
  void tryCatchStatement_bodyBegin({int offset = 0}) {
    return _wrap(
      'tryCatchStatement_bodyBegin(offset: $offset)',
      () => _wrapped.tryCatchStatement_bodyBegin(offset: offset),
    );
  }

  @override
  void tryCatchStatement_bodyEnd(Node body) {
    return _wrap(
      'tryCatchStatement_bodyEnd($body)',
      () => _wrapped.tryCatchStatement_bodyEnd(body),
    );
  }

  @override
  void tryCatchStatement_catchBegin(
    Variable? exceptionVariable,
    Variable? stackTraceVariable, {
    int offset = 0,
  }) {
    return _wrap(
      'tryCatchStatement_catchBegin($exceptionVariable, $stackTraceVariable, '
      'offset: $offset)',
      () => _wrapped.tryCatchStatement_catchBegin(
        exceptionVariable,
        stackTraceVariable,
        offset: offset,
      ),
    );
  }

  @override
  void tryCatchStatement_catchEnd() {
    return _wrap(
      'tryCatchStatement_catchEnd()',
      () => _wrapped.tryCatchStatement_catchEnd(),
    );
  }

  @override
  void tryCatchStatement_end({int offset = 0}) {
    return _wrap(
      'tryCatchStatement_end(offset: $offset)',
      () => _wrapped.tryCatchStatement_end(offset: offset),
    );
  }

  @override
  void tryFinallyStatement_bodyBegin() {
    return _wrap(
      'tryFinallyStatement_bodyBegin()',
      () => _wrapped.tryFinallyStatement_bodyBegin(),
    );
  }

  @override
  void tryFinallyStatement_end({int offset = 0}) {
    return _wrap(
      'tryFinallyStatement_end(offset: $offset)',
      () => _wrapped.tryFinallyStatement_end(offset: offset),
    );
  }

  @override
  void tryFinallyStatement_finallyBegin(Node body, {int offset = 0}) {
    return _wrap(
      'tryFinallyStatement_finallyBegin($body, offset: $offset)',
      () => _wrapped.tryFinallyStatement_finallyBegin(body, offset: offset),
    );
  }

  @override
  List<SharedTypeView> variablePromotionChainForTesting(Variable variable) {
    return _wrap(
      'variablePromotionChainForTesting($variable)',
      () => _wrapped.variablePromotionChainForTesting(variable),
      isQuery: true,
    );
  }

  @override
  (SharedTypeView?, ExpressionInfo) variableRead(
    Variable variable, {
    int offset = 0,
  }) {
    return _wrap(
      'variableRead($variable, offset: $offset)',
      () => _wrapped.variableRead(variable, offset: offset),
      isQuery: true,
      isPure: false,
    );
  }

  @override
  void whileStatement_bodyBegin(
    Statement whileStatement,
    ExpressionInfo? conditionInfo, {
    int offset = 0,
  }) {
    return _wrap(
      'whileStatement_bodyBegin($whileStatement, $conditionInfo, '
      'offset: $offset)',
      () => _wrapped.whileStatement_bodyBegin(
        whileStatement,
        conditionInfo,
        offset: offset,
      ),
    );
  }

  @override
  void whileStatement_conditionBegin(Node node, {int offset = 0}) {
    return _wrap(
      'whileStatement_conditionBegin($node, offset: $offset)',
      () => _wrapped.whileStatement_conditionBegin(node, offset: offset),
    );
  }

  @override
  void whileStatement_end({int offset = 0}) {
    return _wrap(
      'whileStatement_end(offset: $offset)',
      () => _wrapped.whileStatement_end(offset: offset),
    );
  }

  @override
  Map<SharedTypeView, NonPromotionReason> Function() whyNotPromoted(
    ExpressionInfo? targetInfo,
  ) {
    return _wrap(
      'whyNotPromoted($targetInfo)',
      () => _trackWhyNotPromoted(_wrapped.whyNotPromoted(targetInfo)),
      isQuery: true,
    );
  }

  @override
  Map<SharedTypeView, NonPromotionReason> Function() whyNotPromotedImplicitThis(
    SharedTypeView staticType,
  ) {
    return _wrap(
      'whyNotPromotedImplicitThis($staticType)',
      () =>
          _trackWhyNotPromoted(_wrapped.whyNotPromotedImplicitThis(staticType)),
      isQuery: true,
    );
  }

  @override
  ExpressionInfo? write(
    Node node,
    Variable variable,
    SharedTypeView writtenType,
    ExpressionInfo? writtenExpressionInfo, {
    int offset = 0,
  }) {
    return _wrap(
      'write($node, $variable, $writtenType, $writtenExpressionInfo, '
      'offset: $offset)',
      () => _wrapped.write(
        node,
        variable,
        writtenType,
        writtenExpressionInfo,
        offset: offset,
      ),
      isQuery: true,
      isPure: false,
    );
  }

  @override
  void _dumpState() => _wrapped._dumpState();

  /// Wraps [callback] so that when it is called, the call (and its return
  /// value) will be printed to the console.  Also registers the wrapped
  /// callback in [_description] so that it will be given a unique identifier
  /// when printed to the console.
  Map<SharedTypeView, NonPromotionReason> Function() _trackWhyNotPromoted(
    Map<SharedTypeView, NonPromotionReason> Function() callback,
  ) {
    String callbackToString = '#CALLBACK${_nextCallbackId++}';
    Map<SharedTypeView, NonPromotionReason> Function() wrappedCallback = () =>
        _wrap('$callbackToString()', callback, isQuery: true);
    _description[wrappedCallback] = callbackToString;
    return wrappedCallback;
  }

  T _wrap<T>(
    String description,
    T callback(), {
    bool isQuery = false,
    bool? isPure,
  }) {
    isPure ??= isQuery;
    print(description);
    T result;
    try {
      result = callback();
    } catch (e, st) {
      print('  => EXCEPTION $e');
      print('    ' + st.toString().replaceAll('\n', '\n    '));
      _exceptionOccurred = true;
      rethrow;
    }
    if (!isPure) {
      _wrapped._dumpState();
    }
    if (isQuery) {
      print('  => ${_describe(result)}');
    }
    return result;
  }

  static String _describe(Object? value) {
    if (value != null && value is! String && value is! num && value is! bool) {
      String? description = _description[value];
      if (description != null) return description;
    }
    return value.toString();
  }
}

/// Flow analysis interface methods used by [NullShortingMixin].
///
/// These are separated from [FlowAnalysis] in order to isolate
/// [NullShortingMixin] from the type parameters of [FlowAnalysis] that aren't
/// relevant to it.
abstract interface class FlowAnalysisNullShortingInterface<
  Expression extends Object,
  Variable extends Object
> {
  /// Call this method after visiting an expression using `?.`.
  void nullAwareAccess_end({int offset = 0});

  /// Call this method after visiting a null-aware operator such as `?.` or
  /// `?[`.
  ///
  /// It is _not_ necessary to call this method when visiting a cascade; that is
  /// performed automatically by [FlowAnalysis.cascadeExpression_afterTarget].
  ///
  /// [targetInfo] should be the expression info for the expression just before
  /// the null-aware operator, or `null` if the null-aware access starts a
  /// cascade section.
  ///
  /// [targetType] should be the type of the expression just before the
  /// null-aware operator, and should be non-null even if the null-aware access
  /// starts a cascade section.
  ///
  /// If the client desugars the null-aware access using a guard variable (e.g.,
  /// if it desugars `a?.b` into `let x = a in x == null ? null : x.b`), it
  /// should pass in the variable used for desugaring as [guardVariable]. Flow
  /// analysis will ensure that this variable is promoted to the appropriate
  /// type in the "not null" code path.
  ///
  /// Note that [nullAwareAccess_end] should be called after the conclusion
  /// of any null-shorting that is caused by the `?.`.  So, for example, if the
  /// code being analyzed is `x?.y?.z(x)`, [nullAwareAccess_rightBegin] should
  /// be called once upon reaching each `?.`, but [nullAwareAccess_end] should
  /// not be called until after processing the method call to `z(x)`.
  ///
  /// Returns the expression info for the target of the null-aware access, when
  /// it is not null.
  ///
  /// [offset] is the last source offset that should be considered to be part of
  /// the target of the null-aware access. The offset of either character in the
  /// `?.` token should work, since no expressions can appear in this range, but
  /// the first character of the token is probably the best choice.
  ExpressionInfo? nullAwareAccess_rightBegin(
    ExpressionInfo? targetInfo,
    SharedTypeView targetType, {
    Variable? guardVariable,
    int offset = 0,
  });
}

/// An instance of the [FlowModel] class represents the information gathered by
/// flow analysis at a single point in the control flow of the function or
/// method being analyzed.
///
/// Instances of this class are immutable, so the methods below that "update"
/// the state actually leave `this` unchanged and return a new state object.
@visibleForTesting
class FlowModel {
  final Reachability reachable;

  /// [PromotionInfo] object tracking the [PromotionModel]s for each promotable
  /// thing being tracked by flow analysis.
  final PromotionInfo? promotionInfo;

  /// Creates a state object with the given [reachable] status.  All variables
  /// are assumed to be unpromoted and already assigned, so joining another
  /// state with this one will have no effect on it.
  FlowModel(Reachability reachable) : this.withInfo(reachable, null);

  @visibleForTesting
  FlowModel.withInfo(this.reachable, this.promotionInfo);

  /// Updates the state to indicate that the given [writtenVariables] are no
  /// longer promoted and are no longer definitely unassigned, and the given
  /// [capturedVariables] have been captured by closures.
  ///
  /// This is used at the top of loops to conservatively cancel the promotion of
  /// variables that are modified within the loop, so that we correctly analyze
  /// code like the following:
  ///
  ///     if (x is int) {
  ///       x.isEven; // OK, promoted to int
  ///       while (true) {
  ///         x.isEven; // ERROR: promotion lost
  ///         x = 'foo';
  ///       }
  ///     }
  ///
  /// Note that a more accurate analysis would be to iterate to a fixed point,
  /// and only remove promotions if it can be shown that they aren't restored
  /// later in the loop body.  If we switch to a fixed point analysis, we should
  /// be able to remove this method.
  FlowModel conservativeJoin(
    FlowModelHelper helper,
    Iterable<int> writtenVariables,
    Iterable<int> capturedVariables, {
    NonPromotionReason? Function(int variableKey)? getNonPromotionReason,
  }) {
    FlowModel result = this;

    for (int variableKey in writtenVariables) {
      PromotionModel? info = result.promotionInfo?.get(helper, variableKey);
      if (info == null) continue;

      // We don't need to discard promotions for final variables. They are
      // guaranteed to be already assigned and won't be assigned again.
      if (helper.isFinal(variableKey)) continue;

      PromotionModel newInfo = info.discardPromotionsAndMarkNotUnassigned(
        nonPromotionReason: getNonPromotionReason?.call(variableKey),
      );
      if (!identical(info, newInfo)) {
        result = result.updatePromotionInfo(helper, variableKey, newInfo);
      }
    }

    for (int variableKey in capturedVariables) {
      PromotionModel? info = result.promotionInfo?.get(helper, variableKey);
      if (info == null) continue;
      if (!info.writeCaptured) {
        result = result.updatePromotionInfo(
          helper,
          variableKey,
          info.writeCapture(),
        );
        // Note: there's no need to discard dependent property promotions,
        // because when deciding whether a property is promoted,
        // [_FlowAnalysisImpl._handleProperty] checks whether the variable is
        // captured.
      }
    }

    return result;
  }

  /// Register a declaration of the variable whose key is [variableKey].
  /// Should also be called for function parameters.
  ///
  /// A local variable is [initialized] if its declaration has an initializer.
  /// A function parameter is always initialized, so [initialized] is `true`.
  FlowModel declare(FlowModelHelper helper, int variableKey, bool initialized) {
    PromotionModel newInfoForVar = new PromotionModel.fresh(
      assigned: initialized,
      ssaNode: new SsaNode(),
    );

    return updatePromotionInfo(helper, variableKey, newInfoForVar);
  }

  /// Gets the info for the given [promotionKey], creating it if it doesn't
  /// exist.
  ///
  /// If new info must be created, [ssaNode] is used as its SSA node. This
  /// allows the caller to ensure that when the promotion key represents a
  /// promotable property, the SSA node will match the [_PropertySsaNode] found
  /// in the target's [SsaNode._promotableProperties] map.
  PromotionModel infoFor(
    FlowModelHelper helper,
    int promotionKey, {
    required SsaNode ssaNode,
  }) =>
      promotionInfo?.get(helper, promotionKey) ??
      new PromotionModel.fresh(ssaNode: ssaNode);

  /// Builds a [FlowModel] based on `this`, but extending the `tested` set to
  /// include types from [other].  This is used at the bottom of certain kinds
  /// of loops, to ensure that types tested within the body of the loop are
  /// consistently treated as "of interest" in code that follows the loop,
  /// regardless of the type of loop.
  @visibleForTesting
  FlowModel inheritTested(FlowModelHelper helper, FlowModel other) {
    FlowModel result = this;
    for (var FlowLinkDiffEntry(
          key: int promotionKey,
          :PromotionInfo? left,
          :PromotionInfo? right,
        )
        in helper.reader.diff(promotionInfo, other.promotionInfo).entries) {
      PromotionModel? promotionModel = left?.model;
      if (promotionModel == null) continue;
      PromotionModel? otherPromotionModel = right?.model;
      PromotionModel newPromotionModel = otherPromotionModel == null
          ? promotionModel
          : PromotionModel.inheritTested(
              promotionModel,
              otherPromotionModel.tested,
            );
      if (!identical(newPromotionModel, promotionModel)) {
        result = result.updatePromotionInfo(
          helper,
          promotionKey,
          newPromotionModel,
        );
      }
    }
    return result;
  }

  /// Updates `this` flow model to account for any promotions and assignments
  /// present in [base].
  ///
  /// This is called "rebasing" the flow model by analogy to "git rebase"; in
  /// effect, it rewinds any flow analysis state present in `this` but not in
  /// the history of [base], and then reapplies that state using [base] as a
  /// starting point, to the extent possible without creating unsoundness.  For
  /// example, if a variable is promoted in `this` but not in [base], then it
  /// will be promoted in the output model, provided that hasn't been reassigned
  /// since then (which would make the promotion unsound).
  FlowModel rebaseForward(FlowModelHelper helper, FlowModel base) {
    // The rebased model is reachable iff both `this` and the new base are
    // reachable.
    Reachability newReachable = reachable.rebaseForward(base.reachable);
    FlowModel result = base.setReachability(newReachable);

    var (
      :PromotionInfo? ancestor,
      :List<FlowLinkDiffEntry<PromotionInfo>> entries,
    ) = helper.reader.diff(
      promotionInfo,
      base.promotionInfo,
    );
    // If `this` matches the ancestor, then there are no state changes that need
    // to be rewound and applied to `base`.
    if (ancestor == promotionInfo) {
      return result;
    }
    // If `base` matches the ancestor, then the act of rewinding `this` back to
    // the ancestor, and then reapplying the rewound changes to `base`,
    // reproduces `this` exactly (assuming reachability matches up properly).
    if (base.promotionInfo == ancestor && reachable == newReachable) {
      return this;
    }
    // Consider each promotion key in the new base model.
    for (var FlowLinkDiffEntry(
          key: int promotionKey,
          :PromotionInfo? left,
          :PromotionInfo? right,
        )
        in entries) {
      PromotionModel? thisModel = left?.model;
      if (thisModel == null) {
        // Either this promotion key represents a variable that has newly come
        // into scope since `thisModel`, or it represents a property that flow
        // analysis became aware of since `thisModel`. In either case, the
        // information in `baseModel` is up to date.
        continue;
      }
      PromotionModel? baseModel = right?.model;
      if (baseModel == null) {
        // The promotion key exists in `this` model but not in the new `base`
        // model. This happens when either:
        // - The promotion key is associated with a local variable that was in
        //   scope at the time `this` model was created, but is no longer in
        //   scope as of the `base` model, or:
        // - The promotion key is associated with a property that was promoted
        // in `this` model.
        //
        // In the first case, it doesn't matter what we do, because the variable
        // is no longer in scope. But in the second case, we need to preserve
        // the promotion.
        result = result.updatePromotionInfo(helper, promotionKey, thisModel);
        continue;
      }
      // If the variable was write captured in either `this` or the new base,
      // it's captured now.
      bool newWriteCaptured =
          thisModel.writeCaptured || baseModel.writeCaptured;
      List<SharedTypeView> newPromotedTypes;
      if (newWriteCaptured) {
        // Write captured variables can't be promoted.
        newPromotedTypes = const [];
      } else if (baseModel.ssaNode != thisModel.ssaNode) {
        // The variable may have been written to since `thisModel`, so we can't
        // use any of the promotions from `thisModel`.
        newPromotedTypes = baseModel.promotedTypes;
      } else {
        // The variable hasn't been written to since `thisModel`, so we can keep
        // all of the promotions from `thisModel`, provided that we retain the
        // usual "promotion chain" invariant (each promoted type is a subtype of
        // the previous).
        newPromotedTypes = PromotionModel.rebasePromotedTypes(
          basePromotions: baseModel.promotedTypes,
          newPromotions: thisModel.promotedTypes,
          helper: helper,
        );
      }
      // Tests are kept regardless of whether they are in `this` model or the
      // new base model.
      List<SharedTypeView> newTested = PromotionModel.joinTested(
        thisModel.tested,
        baseModel.tested,
      );
      // The variable is definitely assigned if it was definitely assigned
      // either in `this` model or the new base model.
      bool newAssigned = thisModel.assigned || baseModel.assigned;
      // The variable is definitely unassigned if it was definitely unassigned
      // in both `this` model and the new base model.
      bool newUnassigned = thisModel.unassigned && baseModel.unassigned;
      PromotionModel newModel = PromotionModel._identicalOrNew(
        thisModel,
        baseModel,
        newPromotedTypes,
        newTested,
        newAssigned,
        newUnassigned,
        newWriteCaptured ? null : baseModel.ssaNode,
      );
      result = result.updatePromotionInfo(helper, promotionKey, newModel);
    }
    return result;
  }

  FlowModel setReachability(Reachability reachable) {
    if (this.reachable == reachable) return this;

    return new FlowModel.withInfo(reachable, promotionInfo);
  }

  /// Updates the state to indicate that the control flow path is unreachable.
  FlowModel setUnreachable() {
    if (!reachable.locallyReachable) return this;

    return new FlowModel.withInfo(reachable.setUnreachable(), promotionInfo);
  }

  /// Returns a [FlowModel] indicating the result of creating a control flow
  /// split.  See [Reachability.split] for more information.
  FlowModel split() => new FlowModel.withInfo(reachable.split(), promotionInfo);

  @override
  String toString() => '($reachable, $promotionInfo)';

  /// Returns an [ExpressionInfo] indicating the result of checking whether the
  /// given [reference] is non-null.
  ///
  /// Note that the state is only changed if the previous type of [reference]
  /// was potentially nullable.
  ExpressionInfo tryMarkNonNullable(
    FlowModelHelper helper,
    _Reference reference,
  ) {
    PromotionModel info = infoFor(
      helper,
      reference.promotionKey,
      ssaNode: reference.ssaNode,
    );
    if (info.writeCaptured) {
      return new ExpressionInfo.trivial(model: this, type: helper.boolType);
    }

    SharedTypeView previousType = reference._type;
    SharedTypeView newType = helper.typeOperations.promoteToNonNull(
      previousType,
    );
    if (!helper.isValidPromotionStep(
      previousType: previousType,
      newType: newType,
    )) {
      return new ExpressionInfo.trivial(model: this, type: helper.boolType);
    }

    FlowModel ifTrue = _finishTypeTest(helper, reference, info, null, newType);

    return new ExpressionInfo(
      type: helper.boolType,
      ifTrue: ifTrue,
      ifFalse: this,
    );
  }

  /// Returns an [ExpressionInfo] indicating the result of casting the given
  /// [reference] to the given [type], as a consequence of an `as` expression.
  ///
  /// Note that the state is only changed if [type] is a subtype of the
  /// reference's previous (possibly promoted) type.
  ///
  /// TODO(paulberry): if the type is non-nullable, should this method mark the
  /// variable as definitely assigned?  Does it matter?
  FlowModel tryPromoteForTypeCast(
    FlowModelHelper helper,
    _Reference reference,
    SharedTypeView type,
  ) {
    PromotionModel info = infoFor(
      helper,
      reference.promotionKey,
      ssaNode: reference.ssaNode,
    );
    if (info.writeCaptured) {
      return this;
    }

    SharedTypeView previousType = reference._type;
    SharedTypeView? newType = helper.typeOperations.tryPromoteToType(
      type,
      previousType,
    );
    if (newType == null ||
        !helper.isValidPromotionStep(
          previousType: previousType,
          newType: newType,
        )) {
      return this;
    }

    return _finishTypeTest(helper, reference, info, type, newType);
  }

  /// Returns an [ExpressionInfo] indicating the result of checking whether the
  /// given [reference] satisfies the given [type], e.g. as a consequence of an
  /// `is` expression as the condition of an `if` statement.
  ///
  /// Note that the "ifTrue" state is only changed if [type] is a subtype of
  /// the variable's previous (possibly promoted) type.
  ///
  /// TODO(paulberry): if the type is non-nullable, should this method mark the
  /// variable as definitely assigned?  Does it matter?
  ExpressionInfo tryPromoteForTypeCheck(
    FlowModelHelper helper,
    _Reference reference,
    SharedTypeView type,
  ) {
    PromotionModel info = infoFor(
      helper,
      reference.promotionKey,
      ssaNode: reference.ssaNode,
    );
    if (info.writeCaptured) {
      return new ExpressionInfo.trivial(model: this, type: helper.boolType);
    }

    SharedTypeView previousType = reference._type;
    FlowModel ifTrue = this;
    SharedTypeView? typeIfSuccess = helper.typeOperations.tryPromoteToType(
      type,
      previousType,
    );
    if (typeIfSuccess != null &&
        helper.isValidPromotionStep(
          previousType: previousType,
          newType: typeIfSuccess,
        )) {
      ifTrue = _finishTypeTest(helper, reference, info, type, typeIfSuccess);
    }

    SharedTypeView factoredType = helper.typeOperations.factor(
      previousType,
      type,
    );
    SharedTypeView? typeIfFalse;
    bool ifFalseIsUnreachable = false;
    if (helper.typeOperations.isBottomType(factoredType)) {
      // Do not promote to `Never` (even if it would be sound to do so); it's
      // not useful.
      typeIfFalse = null;
      // If not sound, it might still be reachable.
      ifFalseIsUnreachable =
          helper.typeAnalyzerOptions.soundFlowAnalysisEnabled;
    } else if (!helper.isValidPromotionStep(
      previousType: previousType,
      newType: factoredType,
    )) {
      // Don't promote.
      typeIfFalse = null;
    } else {
      typeIfFalse = factoredType;
    }
    FlowModel ifFalse = _finishTypeTest(
      helper,
      reference,
      info,
      type,
      typeIfFalse,
    );

    if (ifFalseIsUnreachable) {
      ifFalse = ifFalse.setUnreachable();
    }

    return new ExpressionInfo(
      type: helper.boolType,
      ifTrue: ifTrue,
      ifFalse: ifFalse,
    );
  }

  /// Returns a [FlowModel] indicating the result of removing a control flow
  /// split.  See [Reachability.unsplit] for more information.
  FlowModel unsplit() =>
      new FlowModel.withInfo(reachable.unsplit(), promotionInfo);

  /// Removes control flow splits until a [FlowModel] is obtained whose
  /// reachability has the given [parent].
  FlowModel unsplitTo(Reachability parent) {
    if (identical(this.reachable.parent, parent)) return this;
    Reachability reachable = this.reachable.unsplit();
    while (!identical(reachable.parent, parent)) {
      reachable = reachable.unsplit();
    }
    return new FlowModel.withInfo(reachable, promotionInfo);
  }

  /// Returns a new [FlowModel] where the information for [promotionKey] is
  /// replaced with [model].
  @visibleForTesting
  FlowModel updatePromotionInfo(
    FlowModelHelper helper,
    int promotionKey,
    PromotionModel model,
  ) {
    PromotionInfo newPromotionInfo = new PromotionInfo._(
      model,
      key: promotionKey,
      previous: promotionInfo,
      previousForKey: helper.reader.get(promotionInfo, promotionKey),
    );
    return new FlowModel.withInfo(reachable, newPromotionInfo);
  }

  /// Updates the state to indicate that an assignment was made to [Variable],
  /// whose key is [variableKey].  The variable is marked as definitely
  /// assigned, and any previous type promotion is removed.
  ///
  /// If there is any chance that the write will cause a demotion, the caller
  /// must pass in a non-null value for [nonPromotionReason] describing the
  /// reason for any potential demotion.
  FlowModel write<Variable extends Object>(
    FlowModelHelper helper,
    NonPromotionReason? nonPromotionReason,
    int variableKey,
    SharedTypeView writtenType,
    SsaNode newSsaNode, {
    bool promoteToTypeOfInterest = true,
    required SharedTypeView unpromotedType,
  }) {
    FlowModel? newModel;
    PromotionModel? infoForVar = promotionInfo?.get(helper, variableKey);
    if (infoForVar != null) {
      PromotionModel newInfoForVar = infoForVar.write(
        helper,
        nonPromotionReason,
        variableKey,
        writtenType,
        newSsaNode,
        promoteToTypeOfInterest: promoteToTypeOfInterest,
        unpromotedType: unpromotedType,
      );
      if (!identical(newInfoForVar, infoForVar)) {
        newModel = updatePromotionInfo(helper, variableKey, newInfoForVar);
      }
    }

    return newModel ?? this;
  }

  /// Common algorithm for [tryMarkNonNullable], [tryPromoteForTypeCast],
  /// and [tryPromoteForTypeCheck].  Builds a [FlowModel] object describing the
  /// effect of updating the [reference] by adding the [testedType] to the
  /// list of tested types (if not `null`, and not there already), adding the
  /// [promotedType] to the chain of promoted types.
  ///
  /// Preconditions:
  /// - [info] should be the result of calling [infoFor] on the reference.
  /// - [promotedType] should be a subtype of the currently-promoted type (i.e.
  ///   no redundant or side-promotions)
  /// - If the reference is a variable, it should not be write-captured.
  FlowModel _finishTypeTest(
    FlowModelHelper helper,
    _Reference reference,
    PromotionModel info,
    SharedTypeView? testedType,
    SharedTypeView? promotedType,
  ) {
    List<SharedTypeView> newTested = info.tested;
    if (testedType != null) {
      newTested = PromotionModel._addTypeToUniqueList(info.tested, testedType);
    }

    List<SharedTypeView> newPromotedTypes = info.promotedTypes;
    if (promotedType != null) {
      newPromotedTypes = PromotionModel._addToPromotedTypes(
        info.promotedTypes,
        promotedType,
      );
    }

    return identical(newTested, info.tested) &&
            identical(newPromotedTypes, info.promotedTypes)
        ? this
        : updatePromotionInfo(
            helper,
            reference.promotionKey,
            new PromotionModel(
              promotedTypes: newPromotedTypes,
              tested: newTested,
              assigned: info.assigned,
              unassigned: info.unassigned,
              ssaNode: info.ssaNode,
              nonPromotionHistory: info.nonPromotionHistory,
            ),
          );
  }

  /// Forms a new state to reflect a control flow path that might have come from
  /// either the [first] or [second] state.
  ///
  /// The control flow path is considered reachable if either of the input
  /// states is reachable.  Variables are considered definitely assigned if they
  /// were definitely assigned in both of the input states.  Promotions are kept
  /// only if they are common to both input states; if a reference is promoted
  /// to one type in one state and a subtype in the other state, the less
  /// specific type promotion is kept.
  static FlowModel join(
    FlowModelHelper helper,
    FlowModel? first,
    FlowModel? second,
  ) {
    if (first == null) return second!;
    if (second == null) return first;

    assert(identical(first.reachable.parent, second.reachable.parent));
    if (first.reachable.locallyReachable &&
        !second.reachable.locallyReachable) {
      return first;
    }
    if (!first.reachable.locallyReachable &&
        second.reachable.locallyReachable) {
      return second;
    }

    // first.reachable and second.reachable are equivalent, so we don't need to
    // join reachabilities.
    assert(
      first.reachable.locallyReachable == second.reachable.locallyReachable,
    );
    assert(first.reachable.parent == second.reachable.parent);
    return FlowModel.joinPromotionInfo(helper, first, second);
  }

  /// Joins two "promotion info" maps.  See [join] for details.
  @visibleForTesting
  static FlowModel joinPromotionInfo(
    FlowModelHelper helper,
    FlowModel first,
    FlowModel second,
  ) {
    if (identical(first, second)) return first;
    if (first.promotionInfo == null) return first;
    if (second.promotionInfo == null) return second;

    var (
      :PromotionInfo? ancestor,
      :List<FlowLinkDiffEntry<PromotionInfo>> entries,
    ) = helper.reader.diff(
      first.promotionInfo,
      second.promotionInfo,
    );
    FlowModel newFlowModel = new FlowModel.withInfo(first.reachable, ancestor);
    for (var FlowLinkDiffEntry(
          key: int promotionKey,
          left: PromotionInfo? leftInfo,
          right: PromotionInfo? rightInfo,
        )
        in entries) {
      PromotionModel? firstModel = leftInfo?.model;
      if (firstModel == null) {
        continue;
      }
      PromotionModel? secondModel = rightInfo?.model;
      if (secondModel == null) {
        continue;
      }
      PromotionModel joined;
      (joined, newFlowModel) = PromotionModel.join(
        helper,
        firstModel,
        first.promotionInfo,
        secondModel,
        second.promotionInfo,
        newFlowModel,
      );
      newFlowModel = newFlowModel.updatePromotionInfo(
        helper,
        promotionKey,
        joined,
      );
    }

    return newFlowModel;
  }
}

/// Convenience methods used by [FlowModel] and [_Reference] methods to access
/// variables in [_FlowAnalysisImpl].
@visibleForTesting
mixin FlowModelHelper {
  /// [FlowLinkReader] object for efficiently looking up [PromotionModel]
  /// objects in [FlowModel.promotionInfo] structures, or for computing the
  /// difference between two [FlowModel.promotionInfo] structures.
  final FlowLinkReader<PromotionInfo> reader =
      new FlowLinkReader<PromotionInfo>();

  /// Returns the client's representation of the type `bool`.
  SharedTypeView get boolType;

  /// The [PromotionKeyStore], which tracks the unique integer assigned to
  /// everything in the control flow that might be promotable.
  @visibleForTesting
  PromotionKeyStore<Object> get promotionKeyStore;

  /// Language features enables affecting the behavior of flow analysis.
  TypeAnalyzerOptions get typeAnalyzerOptions;

  /// The [FlowAnalysisTypeOperations], used to access types and check
  /// subtyping.
  @visibleForTesting
  FlowAnalysisTypeOperations get typeOperations;

  /// Whether the variable of [variableKey] was declared with the `final`
  /// modifier and the `inference-update-4` feature flag is enabled.
  bool isFinal(int variableKey);

  /// Determines whether a promotion from type [previousType] to [newType] is
  /// allowed to occur, given the current configuration of flow analysis.
  ///
  /// Caller is required to ensure that `newType <: previousType`.
  bool isValidPromotionStep({
    required SharedTypeView previousType,
    required SharedTypeView newType,
  });
}

/// Documentation links that might be presented to the user to accompany a "why
/// not promoted" context message.
enum NonPromotionDocumentationLink {
  /// The expression in question is a reference to a private final field, but it
  /// couldn't be promoted because there is another class in the same library
  /// containing a concrete getter with the same name.
  conflictingGetter('https://dart.dev/go/non-promo-conflicting-getter'),

  /// The expression in question is a reference to a private final field, but it
  /// couldn't be promoted because there is another class in the same library
  /// containing a field with the same name that's not promotable (either
  /// because it's not final or because it's external).
  conflictingNonPromotableField(
    'https://dart.dev/go/non-promo-conflicting-non-promotable-field',
  ),

  /// The expression in question is a reference to a private final field, but it
  /// couldn't be promoted because there is a concrete class `C` in the library
  /// whose interface contains a getter with the same name, but `C` does not
  /// have an implementation of that getter (and hence it forwards to
  /// `noSuchMethod`).
  conflictingNoSuchMethodForwarder(
    'https://dart.dev/go/non-promo-conflicting-noSuchMethod-forwarder',
  ),

  /// The expression in question is a reference to a private field, but it
  /// couldn't be promoted because it's external.
  externalField('https://dart.dev/go/non-promo-external-field'),

  /// The expression in question is a reference to a private field, but it
  /// couldn't be promoted because the Dart language version for this library is
  /// prior to field promotion support.
  fieldPromotionUnavailable(
    'https://dart.dev/go/non-promo-field-promotion-unavailable',
  ),

  /// The expression in question is a property get, but it couldn't be promoted
  /// because it doesn't refer to a field (it might refer to a getter or it
  /// might be a tear-off of a method).
  nonField('https://dart.dev/go/non-promo-non-field'),

  /// The expression in question is a reference to a private field, but it
  /// couldn't be promoted because it's not final.
  nonFinalField('https://dart.dev/go/non-promo-non-final-field'),

  /// The expression in question is a property get. It couldn't be promoted
  /// because promotion of property gets is not supported.
  ///
  /// This link is no longer used, but it was used in Dart versions 3.1 and
  /// earlier (so the documentation web site should continue to support it until
  /// most users have upgraded to 3.2 or later).
  @deprecated
  property('https://dart.dev/go/non-promo-property'),

  /// The expression in question is a reference to a field, but it couldn't be
  /// promoted because it's not private.
  publicField('https://dart.dev/go/non-promo-public-field'),

  /// The expression in question is `this`. It couldn't be promoted because
  /// promotion of `this` is not yet supported.
  this_('https://dart.dev/go/non-promo-this'),

  /// The expression in question is a reference to a local variable. It couldn't
  /// be promoted because the variable was written to between the type test and
  /// the usage.
  write('https://dart.dev/go/non-promo-write'),

  /// The expression in question is a reference to a local variable. It couldn't
  /// be promoted because the local variable was demoted due to an 'await' or
  /// 'yield' expression/statement.
  suspension('https://dart.dev/go/non-promo-suspension');

  /// The link URL, as a text string.
  final String url;

  const NonPromotionDocumentationLink(this.url);

  @override
  String toString() => url;
}

/// Linked list node representing a set of reasons why a given expression was
/// not promoted.
///
/// We use a linked list representation because it is very efficient to build;
/// this means that in the "happy path" where no error occurs (so non-promotion
/// history is not needed) we do a minimal amount of work.
class NonPromotionHistory {
  /// The type that was not promoted to.
  final SharedTypeView type;

  /// The reason why the promotion didn't occur.
  final NonPromotionReason nonPromotionReason;

  /// The previous link in the list.
  final NonPromotionHistory? previous;

  NonPromotionHistory(this.type, this.nonPromotionReason, this.previous);

  @override
  String toString() {
    List<String> items = <String>[];
    for (NonPromotionHistory? link = this; link != null; link = link.previous) {
      items.add('${link.type}: ${link.nonPromotionReason}');
    }
    return items.toString();
  }
}

/// Abstract class representing a reason why something was not promoted.
abstract class NonPromotionReason {
  /// Link to documentation describing this non-promotion reason; this should be
  /// presented to the user as a source of additional information about the
  /// error.
  ///
  /// In certain circumstances this link may be `null`, in which case the client
  /// needs to supply a documentation link from the
  /// [NonPromotionDocumentationLink] enum.
  NonPromotionDocumentationLink? get documentationLink;

  /// Short text description of this non-promotion reason; intended for ID
  /// testing.
  String get shortName;

  /// Implementation of the visitor pattern for non-promotion reasons.
  R accept<R, Node extends Object, Variable extends Object>(
    NonPromotionReasonVisitor<R, Node, Variable> visitor,
  );
}

/// Implementation of the visitor pattern for non-promotion reasons.
abstract class NonPromotionReasonVisitor<
  R,
  Node extends Object,
  Variable extends Object
> {
  NonPromotionReasonVisitor._() : assert(false, 'Do not extend this class');

  R visitDemoteViaExplicitWrite(DemoteViaExplicitWrite<Variable, Node> reason);

  R visitDemoteViaSuspension(DemoteViaSuspension<Variable, Node> reason);

  R visitPropertyNotPromotedForInherentReason(
    PropertyNotPromotedForInherentReason reason,
  );

  R visitPropertyNotPromotedForNonInherentReason(
    PropertyNotPromotedForNonInherentReason reason,
  );

  R visitThisNotPromoted(ThisNotPromoted reason);
}

/// Data structure describing the relationship among variables defined by
/// patterns in the various alternatives of a set of switch cases that share a
/// body.
class PatternVariableInfo<Variable> {
  /// Map from variable name to a list of the variables with this name defined
  /// in each case.
  final Map<String, List<Variable>> componentVariables = {};

  /// Map from variable name to the promotion key used by flow analysis to track
  /// the merged variable.
  final Map<String, int> patternVariablePromotionKeys = {};
}

/// Map-like data structure recording the [PromotionModel]s for each promotable
/// thing (variable, property, `this`, or `super`) being tracked by flow
/// analysis.
///
/// Each instance of [PromotionInfo] is an immutable key/value pair binding a
/// single promotion [key] (a unique integer assigned by [PromotionKeyStore] to
/// track a particular promotable thing) with an instance of [PromotionModel]
/// describing the promotion state of that thing.
///
/// Please see the documentation for [FlowLink] for more information about how
/// this data structure works.
///
/// Flow analysis has no awareness of scope, so variables that are out of
/// scope are retained in the map until such time as their declaration no
/// longer dominates the control flow.  So, for example, if a variable is
/// declared inside the `then` branch of an `if` statement, and the `else`
/// branch of the `if` statement ends in a `return` statement, then the
/// variable remains in the map after the `if` statement ends, even though the
/// variable is not in scope anymore.  This should not have any effect on
/// analysis results for error-free code, because it is an error to refer to a
/// variable that is no longer in scope.
base class PromotionInfo extends FlowLink<PromotionInfo> {
  /// The [PromotionModel] associated with [key].
  final PromotionModel model;

  PromotionInfo._(
    this.model, {
    required super.key,
    required super.previous,
    required super.previousForKey,
  });

  /// Looks up the [PromotionModel] associated with [promotionKey] by walking
  /// the linked list formed by [previous] to find the nearest link whose [key]
  /// matches [promotionKey].
  @visibleForTesting
  PromotionModel? get(FlowModelHelper helper, int promotionKey) =>
      helper.reader.get(this, promotionKey)?.model;
}

/// An instance of the [PromotionModel] class represents the information
/// gathered by flow analysis for a single variable or property at a single
/// point in the control flow of the function or method being analyzed.
///
/// Instances of this class are immutable, so the methods below that "update"
/// the state actually leave `this` unchanged and return a new state object.
@visibleForTesting
class PromotionModel {
  /// Sequence of types that the variable or property has been promoted to,
  /// where each element of the sequence is a subtype of the previous.  Null if
  /// the variable or property hasn't been promoted.
  final List<SharedTypeView> promotedTypes;

  /// List of types that the variable has been tested against in all code paths
  /// leading to the given point in the source code. Not relevant for
  /// properties.
  final List<SharedTypeView> tested;

  /// Indicates whether the variable has definitely been assigned. Not relevant
  /// for properties.
  final bool assigned;

  /// Indicates whether the variable is unassigned. Not relevant for properties.
  final bool unassigned;

  /// SSA node associated with this variable.  Every time the variable's value
  /// potentially changes (either through an explicit write or a join with a
  /// control flow path that contains a write), this field is updated to point
  /// to a fresh node.  Thus, it can be used to detect whether a variable's
  /// value has changed since a time in the past.
  ///
  /// `null` if the variable has been write captured.
  ///
  /// For promotable properties, this is is the [_PropertySsaNode] found in the
  /// target's [SsaNode._promotableProperties] map.
  final SsaNode? ssaNode;

  /// Non-promotion history of this variable. Not relevant for properties.
  final NonPromotionHistory? nonPromotionHistory;

  PromotionModel({
    required this.promotedTypes,
    required this.tested,
    required this.assigned,
    required this.unassigned,
    required this.ssaNode,
    this.nonPromotionHistory,
  }) {
    assert(
      !(assigned && unassigned),
      "Can't be both definitely assigned and unassigned",
    );
    assert(
      !writeCaptured || promotedTypes.isEmpty,
      "Write-captured variables can't be promoted",
    );
    assert(
      !(writeCaptured && unassigned),
      "Write-captured variables can't be definitely unassigned",
    );
    // ignore:unnecessary_null_comparison
    assert(tested != null);
  }

  /// Creates a [PromotionModel] representing a variable or property that's
  /// never been seen before.
  PromotionModel.fresh({this.assigned = false, required this.ssaNode})
    : promotedTypes = const [],
      tested = const [],
      unassigned = !assigned,
      nonPromotionHistory = null;

  /// Indicates whether the variable has been write captured. Not relevant for
  /// properties.
  bool get writeCaptured => ssaNode == null;

  /// Returns a new [PromotionModel] in which any promotions present have been
  /// dropped, and the variable has been marked as "not unassigned".
  ///
  /// Used by [FlowModel.conservativeJoin] to update the state of variables at
  /// the top of loops whose bodies write to them.
  PromotionModel discardPromotionsAndMarkNotUnassigned({
    NonPromotionReason? nonPromotionReason,
  }) {
    NonPromotionHistory? newNonPromotionHistory;
    if (nonPromotionReason != null) {
      newNonPromotionHistory = nonPromotionHistory;
      for (int i = promotedTypes.length - 1; i >= 0; i--) {
        newNonPromotionHistory = new NonPromotionHistory(
          promotedTypes[i],
          nonPromotionReason,
          newNonPromotionHistory,
        );
      }
    }
    return new PromotionModel(
      promotedTypes: const [],
      tested: tested,
      assigned: assigned,
      unassigned: false,
      ssaNode: writeCaptured ? null : new SsaNode(),
      nonPromotionHistory: newNonPromotionHistory,
    );
  }

  @override
  String toString() {
    List<String> parts = [ssaNode.toString()];
    if (promotedTypes.isNotEmpty) {
      parts.add('promotedTypes: $promotedTypes');
    }
    if (tested.isNotEmpty) {
      parts.add('tested: $tested');
    }
    if (assigned) {
      parts.add('assigned: true');
    }
    if (!unassigned) {
      parts.add('unassigned: false');
    }
    if (writeCaptured) {
      parts.add('writeCaptured: true');
    }
    if (nonPromotionHistory != null) {
      parts.add('nonPromotionHistory: $nonPromotionHistory');
    }
    return 'PromotionModel(${parts.join(', ')})';
  }

  /// Returns a new [PromotionModel] reflecting the fact that the variable was
  /// just written to.
  ///
  /// If there is any chance that the write will cause a demotion, the caller
  /// must pass in a non-null value for [nonPromotionReason] describing the
  /// reason for any potential demotion.
  PromotionModel write<Variable extends Object>(
    FlowModelHelper helper,
    NonPromotionReason? nonPromotionReason,
    int variableKey,
    SharedTypeView writtenType,
    SsaNode newSsaNode, {
    required bool promoteToTypeOfInterest,
    required SharedTypeView unpromotedType,
  }) {
    if (writeCaptured) {
      return new PromotionModel(
        promotedTypes: promotedTypes,
        tested: tested,
        assigned: true,
        unassigned: false,
        ssaNode: null,
      );
    }

    _DemotionResult demotionResult = _demoteViaAssignment(
      writtenType,
      helper.typeOperations,
      nonPromotionReason,
    );
    List<SharedTypeView> newPromotedTypes = demotionResult.promotedTypes;

    if (promoteToTypeOfInterest) {
      newPromotedTypes = _tryPromoteToTypeOfInterest(
        helper,
        unpromotedType,
        newPromotedTypes,
        writtenType,
      );
    }
    // TODO(paulberry): remove demotions from demotionResult.nonPromotionHistory
    // that are no longer in effect due to re-promotion.
    if (identical(promotedTypes, newPromotedTypes) && assigned) {
      return new PromotionModel(
        promotedTypes: promotedTypes,
        tested: tested,
        assigned: assigned,
        unassigned: unassigned,
        ssaNode: newSsaNode,
      );
    }

    List<SharedTypeView> newTested;
    if (newPromotedTypes.isEmpty &&
        promotedTypes.isNotEmpty &&
        !helper.typeAnalyzerOptions.soundFlowAnalysisEnabled) {
      // A full demotion used to clear types of interest. This behavior was
      // removed as part of the sound-flow-analysis update (see
      // https://github.com/dart-lang/language/issues/4380).
      newTested = const [];
    } else {
      newTested = tested;
    }

    return new PromotionModel(
      promotedTypes: newPromotedTypes,
      tested: newTested,
      assigned: true,
      unassigned: false,
      ssaNode: newSsaNode,
      nonPromotionHistory: demotionResult.nonPromotionHistory,
    );
  }

  /// Returns a new [PromotionModel] reflecting the fact that the variable has
  /// been write-captured.
  PromotionModel writeCapture() {
    return new PromotionModel(
      promotedTypes: const [],
      tested: const [],
      assigned: assigned,
      unassigned: false,
      ssaNode: null,
    );
  }

  /// Computes the result of demoting this variable due to writing a value of
  /// type [writtenType].
  ///
  /// If there is any chance that the write will cause an actual demotion to
  /// occur, the caller must pass in a non-null value for [nonPromotionReason]
  /// describing the reason for the potential demotion.
  _DemotionResult _demoteViaAssignment(
    SharedTypeView writtenType,
    FlowAnalysisTypeOperations typeOperations,
    NonPromotionReason? nonPromotionReason,
  ) {
    List<SharedTypeView> promotedTypes = this.promotedTypes;
    if (promotedTypes.isEmpty) {
      return new _DemotionResult(const [], nonPromotionHistory);
    }

    int numElementsToKeep = promotedTypes.length;
    NonPromotionHistory? newNonPromotionHistory = nonPromotionHistory;
    List<SharedTypeView> newPromotedTypes = const [];
    for (; ; numElementsToKeep--) {
      if (numElementsToKeep == 0) {
        break;
      }
      SharedTypeView promoted = promotedTypes[numElementsToKeep - 1];
      if (typeOperations.isSubtypeOf(writtenType, promoted)) {
        if (numElementsToKeep == promotedTypes.length) {
          newPromotedTypes = promotedTypes;
          break;
        }
        newPromotedTypes = promotedTypes.sublist(0, numElementsToKeep);
        break;
      }
      if (nonPromotionReason == null) {
        assert(false, 'Demotion occurred but nonPromotionReason is null');
      } else {
        newNonPromotionHistory = new NonPromotionHistory(
          promoted,
          nonPromotionReason,
          newNonPromotionHistory,
        );
      }
    }
    return new _DemotionResult(newPromotedTypes, newNonPromotionHistory);
  }

  /// Returns a promotion model that is the same as this one, but with the
  /// variable definitely assigned.
  PromotionModel _setAssigned() => assigned
      ? this
      : new PromotionModel(
          promotedTypes: promotedTypes,
          tested: tested,
          assigned: true,
          unassigned: false,
          ssaNode: ssaNode,
          nonPromotionHistory: nonPromotionHistory,
        );

  /// Determines whether a variable with the given [promotedTypes] should be
  /// promoted to [writtenType] based on types of interest.  If it should,
  /// returns an updated promotion chain; otherwise returns [promotedTypes]
  /// unchanged.
  ///
  /// Note that since promotion chains are considered immutable, if promotion
  /// is required, a new promotion chain will be created and returned.
  List<SharedTypeView> _tryPromoteToTypeOfInterest(
    FlowModelHelper helper,
    SharedTypeView declaredType,
    List<SharedTypeView> promotedTypes,
    SharedTypeView writtenType,
  ) {
    assert(!writeCaptured);

    // Figure out if we have any promotion candidates (types that are a
    // supertype of writtenType and a proper subtype of the currently-promoted
    // type).  If at any point we find an exact match, we take it immediately.
    SharedTypeView currentlyPromotedType = promotedTypes.isNotEmpty
        ? promotedTypes.last
        : declaredType;

    List<SharedTypeView>? result = null;
    List<SharedTypeView>? candidates = null;

    void handleTypeOfInterest(SharedTypeView type) {
      // If the written type is invalid, we assume no promotion.
      if (helper.typeOperations.isInvalidType(writtenType)) {
        return;
      }

      // The written type must be a subtype of the type.
      if (!helper.typeOperations.isSubtypeOf(writtenType, type)) {
        return;
      }

      // Must be more specific that the currently promoted type.
      if (!helper.typeOperations.isSubtypeOf(type, currentlyPromotedType)) {
        return;
      }
      if (!helper.isValidPromotionStep(
        previousType: currentlyPromotedType,
        newType: type,
      )) {
        return;
      }

      // This is precisely the type we want to promote to; take it.
      if (type == writtenType) {
        result = _addToPromotedTypes(promotedTypes, writtenType);
      }

      if (candidates == null) {
        candidates = [type];
        return;
      }

      // Add only unique candidates.
      if (!candidates!.contains(type)) {
        candidates!.add(type);
        return;
      }
    }

    // The declared type is always a type of interest, but we never promote
    // to the declared type. So, try NonNull of it.
    SharedTypeView declaredTypeNonNull = helper.typeOperations.promoteToNonNull(
      declaredType,
    );
    if (declaredTypeNonNull != declaredType) {
      handleTypeOfInterest(declaredTypeNonNull);
      if (result != null) {
        return result!;
      }
    }

    for (int i = 0; i < tested.length; i++) {
      SharedTypeView type = tested[i];

      handleTypeOfInterest(type);
      if (result != null) {
        return result!;
      }

      SharedTypeView typeNonNull = helper.typeOperations.promoteToNonNull(type);
      if (typeNonNull != type) {
        handleTypeOfInterest(typeNonNull);
        if (result != null) {
          return result!;
        }
      }
    }

    List<SharedTypeView>? candidates2 = candidates;
    if (candidates2 != null) {
      // Figure out if we have a unique promotion candidate that's a subtype
      // of all the others.
      SharedTypeView? promoted;
      outer:
      for (int i = 0; i < candidates2.length; i++) {
        for (int j = 0; j < candidates2.length; j++) {
          if (j == i) continue;
          if (!helper.typeOperations.isSubtypeOf(
            candidates2[i],
            candidates2[j],
          )) {
            // Not a subtype of all the others.
            continue outer;
          }
        }
        if (promoted != null) {
          // Not unique.  Do not promote.
          return promotedTypes;
        } else {
          promoted = candidates2[i];
        }
      }
      if (promoted != null) {
        return _addToPromotedTypes(promotedTypes, promoted);
      }
    }
    // No suitable promotion found.
    return promotedTypes;
  }

  /// Builds a [PromotionModel] based on [model], but extending the [tested] set
  /// to include types from [tested].  This is used at the bottom of certain
  /// kinds of loops, to ensure that types tested within the body of the loop
  /// are consistently treated as "of interest" in code that follows the loop,
  /// regardless of the type of loop.
  @visibleForTesting
  static PromotionModel inheritTested(
    PromotionModel model,
    List<SharedTypeView> tested,
  ) {
    List<SharedTypeView> newTested = joinTested(tested, model.tested);
    if (identical(newTested, model.tested)) return model;
    return new PromotionModel(
      promotedTypes: model.promotedTypes,
      tested: newTested,
      assigned: model.assigned,
      unassigned: model.unassigned,
      ssaNode: model.ssaNode,
    );
  }

  /// Joins two promotion models.  See [FlowModel.join] for details.
  ///
  /// Since properties of variables may be promoted, the caller must supply the
  /// promotion info maps for the two flow control paths being joined
  /// ([firstPromotionInfo] and [secondPromotionInfo]), as well as the promotion
  /// info map being built for the join point ([newFlowModel]).
  ///
  /// If a non-null [propertySsaNode] is supplied, it is used as the SSA node
  /// for the joined model, rather than joining the SSA nodes from `first` and
  /// `second`. This avoids redundant join operations for properties, since
  /// properties are joined recursively when this method is used on local
  /// variables.
  static (PromotionModel, FlowModel) join(
    FlowModelHelper helper,
    PromotionModel first,
    PromotionInfo? firstPromotionInfo,
    PromotionModel second,
    PromotionInfo? secondPromotionInfo,
    FlowModel newFlowModel, {
    _PropertySsaNode? propertySsaNode,
  }) {
    FlowAnalysisTypeOperations typeOperations = helper.typeOperations;
    List<SharedTypeView> newPromotedTypes = joinPromotedTypes(
      first.promotedTypes,
      second.promotedTypes,
      typeOperations,
    );
    bool newAssigned = first.assigned && second.assigned;
    bool newUnassigned = first.unassigned && second.unassigned;
    bool newWriteCaptured = first.writeCaptured || second.writeCaptured;
    List<SharedTypeView> newTested = newWriteCaptured
        ? const []
        : joinTested(first.tested, second.tested);
    SsaNode? newSsaNode = propertySsaNode;
    if (newSsaNode == null && !newWriteCaptured) {
      (newSsaNode, newFlowModel) = SsaNode._join(
        helper,
        first.ssaNode!,
        firstPromotionInfo,
        second.ssaNode!,
        secondPromotionInfo,
        newFlowModel,
      );
    }
    PromotionModel newPromotionModel = _identicalOrNew(
      first,
      second,
      newPromotedTypes,
      newTested,
      newAssigned,
      newUnassigned,
      newWriteCaptured ? null : newSsaNode,
    );
    return (newPromotionModel, newFlowModel);
  }

  /// Performs the portion of the "join" algorithm that applies to promotion
  /// chains.  Briefly, we intersect given chains.  The chains are totally
  /// ordered subsets of a global partial order.  Their intersection is a
  /// subset of each, and as such is also totally ordered.
  static List<SharedTypeView> joinPromotedTypes(
    List<SharedTypeView> chain1,
    List<SharedTypeView> chain2,
    FlowAnalysisTypeOperations typeOperations,
  ) {
    if (chain1.isEmpty) return chain1;
    if (chain2.isEmpty) return chain2;

    int index1 = 0;
    int index2 = 0;
    bool skipped1 = false;
    bool skipped2 = false;
    List<SharedTypeView>? result;
    while (index1 < chain1.length && index2 < chain2.length) {
      SharedTypeView type1 = chain1[index1];
      SharedTypeView type2 = chain2[index2];
      if (type1 == type2) {
        result ??= <SharedTypeView>[];
        result.add(type1);
        index1++;
        index2++;
      } else if (typeOperations.isSubtypeOf(type2, type1)) {
        index1++;
        skipped1 = true;
      } else if (typeOperations.isSubtypeOf(type1, type2)) {
        index2++;
        skipped2 = true;
      } else {
        skipped1 = true;
        skipped2 = true;
        break;
      }
    }

    if (index1 == chain1.length && !skipped1) return chain1;
    if (index2 == chain2.length && !skipped2) return chain2;
    return result ?? const [];
  }

  /// Performs the portion of the "join" algorithm that applies to promotion
  /// chains.  Essentially this performs a set union, with the following
  /// caveats:
  /// - The "sets" are represented as lists (since they are expected to be very
  ///   small in real-world cases)
  /// - The sense of equality for the union operation is determined by `==`.
  /// - The types of interests lists are considered immutable.
  static List<Type> joinTested<Type extends Object>(
    List<Type> types1,
    List<Type> types2,
  ) {
    // Ensure that types1 is the shorter list.
    if (types1.length > types2.length) {
      List<Type> tmp = types1;
      types1 = types2;
      types2 = tmp;
    }
    // Determine the length of the common prefix the two lists share.
    int shared = 0;
    for (; shared < types1.length; shared++) {
      if (types1[shared] != types2[shared]) break;
    }
    // Use types2 as a starting point and add any entries from types1 that are
    // not present in it.
    for (int i = shared; i < types1.length; i++) {
      Type typeToAdd = types1[i];
      if (types2.contains(typeToAdd)) continue;
      List<Type> result = types2.toList()..add(typeToAdd);
      for (i++; i < types1.length; i++) {
        typeToAdd = types1[i];
        if (types2.contains(typeToAdd)) continue;
        result.add(typeToAdd);
      }
      return result;
    }
    // No types needed to be added.
    return types2;
  }

  /// Forms a promotion chain by starting with [basePromotions] and applying
  /// promotions from [newPromotions] to it, to the extent possible without
  /// violating the usual ordering invariant (each promoted type must be a
  /// subtype of the previous).
  ///
  /// In degenerate cases, the returned chain will be identical to
  /// [newPromotions] or [basePromotions] (to make it easier for the
  /// caller to detect when data structures may be re-used).
  static List<SharedTypeView> rebasePromotedTypes({
    required List<SharedTypeView> basePromotions,
    required List<SharedTypeView> newPromotions,
    required FlowModelHelper helper,
  }) {
    if (basePromotions.isEmpty) {
      // The base promotion chain contributes nothing so we just use this
      // promotion chain directly.
      return newPromotions;
    } else if (newPromotions.isEmpty) {
      // This promotion chain contributes nothing so we just use the base
      // promotion chain directly. Note: this is a performance optimization of
      // the `else` block below; it is not required by the spec.
      return basePromotions;
    } else {
      // Start with basePromotedTypes and apply each of the promotions in
      // thisPromotedTypes (discarding any that don't follow the ordering
      // invariant)
      SharedTypeView basePromotedType = basePromotions.last;
      for (int i = 0; i < newPromotions.length; i++) {
        SharedTypeView nextType = newPromotions[i];
        // Determine if `nextType` is safe to attach to `basePromotedTypes`.
        if (helper.typeOperations.isSubtypeOf(nextType, basePromotedType) &&
            helper.isValidPromotionStep(
              previousType: basePromotedType,
              newType: nextType,
            )) {
          // Since `newPromotions` is a valid promotion chain, it follows that
          // all the types that follow `nextType` are also safe to attach to the
          // base promotion chain, so simply concatenate `basePromotions` with
          // the remainder of `newPromotions`.
          return basePromotions.toList()..addAll(newPromotions.skip(i));
        }
      }
      // No types from `newPromotions` were safe to attach to
      // `basePromotedTypes`, so return `basePromotions` unchanged.
      return basePromotions;
    }
  }

  static List<Type> _addToPromotedTypes<Type extends Object>(
    List<Type> promotedTypes,
    Type promoted,
  ) => promotedTypes.isEmpty
      ? [promoted]
      : (promotedTypes.toList()..add(promoted));

  static List<Type> _addTypeToUniqueList<Type extends Object>(
    List<Type> types,
    Type newType,
  ) {
    if (types.contains(newType)) return types;
    return new List<Type>.of(types)..add(newType);
  }

  /// Creates a new [PromotionModel] object, unless it is equivalent to either
  /// [first] or [second], in which case one of those objects is re-used.
  static PromotionModel _identicalOrNew(
    PromotionModel first,
    PromotionModel second,
    List<SharedTypeView> newPromotedTypes,
    List<SharedTypeView> newTested,
    bool newAssigned,
    bool newUnassigned,
    SsaNode? newSsaNode,
  ) {
    if (identical(first.promotedTypes, newPromotedTypes) &&
        identical(first.tested, newTested) &&
        first.assigned == newAssigned &&
        first.unassigned == newUnassigned &&
        first.ssaNode == newSsaNode) {
      return first;
    } else if (identical(second.promotedTypes, newPromotedTypes) &&
        identical(second.tested, newTested) &&
        second.assigned == newAssigned &&
        second.unassigned == newUnassigned &&
        second.ssaNode == newSsaNode) {
      return second;
    } else {
      return new PromotionModel(
        promotedTypes: newPromotedTypes,
        tested: newTested,
        assigned: newAssigned,
        unassigned: newUnassigned,
        ssaNode: newSsaNode,
      );
    }
  }
}

/// Non-promotion reason describing the situation where an expression was not
/// promoted due to the fact that it's a property get.
abstract base class PropertyNotPromoted extends NonPromotionReason {
  /// The name of the property.
  final String propertyName;

  /// The field or property being accessed.  This matches a `propertyMember`
  /// value that was passed to [FlowAnalysis.propertyGet].
  final Object? propertyMember;

  /// Whether field promotion is enabled for the current library.
  final bool fieldPromotionEnabled;

  PropertyNotPromoted(
    this.propertyName,
    this.propertyMember, {
    required this.fieldPromotionEnabled,
  });
}

/// Non-promotion reason describing the situation where an expression was not
/// promoted due to the fact that it's a property get, and the target of the
/// property get is something inherently non-promotable.
final class PropertyNotPromotedForInherentReason extends PropertyNotPromoted {
  /// The reason why the property isn't promotable.
  final PropertyNonPromotabilityReason whyNotPromotable;

  PropertyNotPromotedForInherentReason(
    super.propertyName,
    super.propertyMember,
    this.whyNotPromotable, {
    required super.fieldPromotionEnabled,
  });

  @override
  NonPromotionDocumentationLink get documentationLink =>
      switch (whyNotPromotable) {
        PropertyNonPromotabilityReason.isNotField =>
          NonPromotionDocumentationLink.nonField,
        PropertyNonPromotabilityReason.isNotPrivate =>
          NonPromotionDocumentationLink.publicField,
        PropertyNonPromotabilityReason.isExternal =>
          NonPromotionDocumentationLink.externalField,
        PropertyNonPromotabilityReason.isNotFinal =>
          NonPromotionDocumentationLink.nonFinalField,
      };

  @override
  String get shortName => 'propertyNotPromotedForInherentReason';

  @override
  R accept<R, Node extends Object, Variable extends Object>(
    NonPromotionReasonVisitor<R, Node, Variable> visitor,
  ) => visitor.visitPropertyNotPromotedForInherentReason(this);
}

/// Non-promotion reason describing the situation where an expression was not
/// promoted due to the fact that it's a property get, but the target of the
/// property get is not something inherently non-promotable.
///
/// This could happen because the target of the property get has the same name
/// as something else in the library that is not promotable, or because field
/// promotion is disabled in the current library.
///
/// Note that it's possible that field promotion is disabled *and* the property
/// get has the same name as something else in the library that is not
/// promotable. If this happens, the client should report the name conflict as
/// the reason for non-promotability. Since only the client knows about other
/// declarations in the library, flow analysis can't distinguish this situation
/// from the situation in which non-promotability is solely due to field
/// promotion being disabled. So this class is used for both scenarios; it is up
/// to the client to determine the correct non-promotion reason to report to the
/// user.
final class PropertyNotPromotedForNonInherentReason
    extends PropertyNotPromoted {
  PropertyNotPromotedForNonInherentReason(
    super.propertyName,
    super.propertyMember, {
    required super.fieldPromotionEnabled,
  });

  @override
  Null get documentationLink => null;

  @override
  String get shortName => 'PropertyNotPromotedForNonInherentReason';

  @override
  R accept<R, Node extends Object, Variable extends Object>(
    NonPromotionReasonVisitor<R, Node, Variable> visitor,
  ) => visitor.visitPropertyNotPromotedForNonInherentReason(this);
}

/// Target for a property access that might undergo promotion.
sealed class PropertyTarget<Expression extends Object> {
  const PropertyTarget._();

  /// Retrieves the SSA node of the value accessed by this property target.
  SsaNode? _getSsaNode(_PropertyTargetHelper<Object> helper);
}

/// Immutable data structure modeling the reachability of the given point in the
/// source code.  Reachability is tracked relative to checkpoints occurring
/// previously along the control flow path leading up to the current point in
/// the program.  A given point is said to be "locally reachable" if it is
/// reachable from the most recent checkpoint, and "overall reachable" if it is
/// reachable from the top of the function.
@visibleForTesting
class Reachability {
  /// Model of the initial reachability state of the function being analyzed.
  static const Reachability initial = const Reachability._initial();

  /// Reachability of the checkpoint this reachability is relative to, or `null`
  /// if there is no checkpoint.  Reachabilities form a tree structure that
  /// mimics the control flow of the code being analyzed, so this is called the
  /// "parent".
  final Reachability? parent;

  /// Whether this point in the source code is considered reachable from the
  /// most recent checkpoint.
  final bool locallyReachable;

  /// Whether this point in the source code is considered reachable from the
  /// beginning of the function being analyzed.
  final bool overallReachable;

  /// The number of `parent` links between this node and [initial].
  final int depth;

  Reachability._(this.parent, this.locallyReachable, this.overallReachable)
    : depth = parent == null ? 0 : parent.depth + 1 {
    assert(
      overallReachable ==
          (locallyReachable && (parent?.overallReachable ?? true)),
    );
  }

  const Reachability._initial()
    : parent = null,
      locallyReachable = true,
      overallReachable = true,
      depth = 0;

  /// Updates `this` reachability to account for the reachability of [base].
  ///
  /// This is the reachability component of the algorithm in
  /// [FlowModel.rebaseForward].
  Reachability rebaseForward(Reachability base) {
    // If [base] is not reachable, then the result is not reachable.
    if (!base.locallyReachable) return base;
    // If any of the reachability nodes between `this` and its common ancestor
    // with [base] are locally unreachable, that means that there was an exit in
    // the flow control path from the point at which `this` and [base] diverged
    // up to the current point of `this`; therefore we want to mark [base] as
    // unreachable.
    Reachability? ancestor = commonAncestor(this, base);
    for (
      Reachability? self = this;
      self != null && !identical(self, ancestor);
      self = self.parent
    ) {
      if (!self.locallyReachable) return base.setUnreachable();
    }
    // Otherwise, the result is as reachable as [base] was.
    return base;
  }

  /// Returns a reachability with the same checkpoint as `this`, but where the
  /// current point in the program is considered locally unreachable.
  Reachability setUnreachable() {
    if (!locallyReachable) return this;
    return new Reachability._(parent, false, false);
  }

  /// Returns a new reachability whose checkpoint is the current point of
  /// execution.  This models flow control within a control flow split, e.g.
  /// inside an `if` statement.
  Reachability split() => new Reachability._(this, true, overallReachable);

  @override
  String toString() {
    List<bool> values = [];
    for (Reachability? node = this; node != null; node = node.parent) {
      values.add(node.locallyReachable);
    }
    return '[${values.join(', ')}]';
  }

  /// Returns a reachability that drops the most recent checkpoint but maintains
  /// the same notion of reachability relative to the previous two checkpoints.
  Reachability unsplit() {
    if (locallyReachable) {
      return parent!;
    } else {
      return parent!.setUnreachable();
    }
  }

  /// Finds the common ancestor node of [r1] and [r2], if any such node exists;
  /// otherwise `null`.  If [r1] and [r2] are the same node, that node is
  /// returned.
  static Reachability? commonAncestor(Reachability? r1, Reachability? r2) {
    if (r1 == null || r2 == null) return null;
    while (r1!.depth > r2.depth) {
      r1 = r1.parent!;
    }
    while (r2!.depth > r1.depth) {
      r2 = r2.parent!;
    }
    while (!identical(r1, r2)) {
      r1 = r1!.parent;
      r2 = r2!.parent;
    }
    return r1;
  }
}

/// Data structure representing a unique value that a variable might take on
/// during execution of the code being analyzed.  SSA nodes are immutable (so
/// they can be safety shared among data structures) and have identity (so that
/// it is possible to tell whether one SSA node is the same as another).
///
/// This is similar to the nodes used in traditional single assignment analysis
/// (https://en.wikipedia.org/wiki/Static_single_assignment_form) except that it
/// does not store a complete IR of the code being analyzed.
///
/// TODO(paulberry): rename to avoid confusion with other attributes of static
/// single assignment analysis. Tentative new name: "Version".
@visibleForTesting
class SsaNode {
  /// Expando mapping SSA nodes to debug ids.  Only used by `toString`.
  static final Expando<int> _debugIds = new Expando<int>();

  static int _nextDebugId = 0;

  /// Flow analysis information was associated with the expression that
  /// produced the value represented by this SSA node, if it was non-trivial.
  ///
  /// This can be used at a later time to perform promotions if the value is
  /// used in a control flow construct. See
  /// [TrivialVariableReference.restoreConditionVariableState].
  ///
  /// We don't bother storing flow analysis information if it's trivial (see
  /// [ExpressionInfo]) because such information does not lead to promotions.
  @visibleForTesting
  final ExpressionInfo? conditionVariableState;

  /// Map containing the set of promotable properties of the value tracked by
  /// this SSA node. Keys are the names of the properties.
  final Map<String, _PropertySsaNode> _promotableProperties = {};

  /// Map containing the set of non-promotable properties of the value tracked
  /// by this SSA node. These are tracked even though they're not promotable, so
  /// that if an error occurs due to the absence of type promotion, it will be
  /// possible to generate a message explaining to the user why type promotion
  /// failed.
  final Map<String, _PropertySsaNode> _nonPromotableProperties = {};

  SsaNode({this.conditionVariableState});

  /// Gets an SSA node representing the property named [propertyName] of the
  /// value represented by `this`, creating it if necessary.
  ///
  /// If a new SSA node is created, it is allocated a fresh promotion key using
  /// [promotionKeyStore], so that type promotions for it can be tracked
  /// separately from other type promotions.
  _PropertySsaNode getOrCreatePropertyNode(
    String propertyName,
    PromotionKeyStore<Object> promotionKeyStore, {
    required bool isPromotable,
  }) {
    if (isPromotable) {
      // The property is promotable, meaning it is known to produce the same (or
      // equivalent) value every time it is queried. So we only create an SSA
      // node if the property hasn't been accessed before; otherwise we return
      // the old SSA node unchanged.
      return _promotableProperties[propertyName] ??= new _PropertySsaNode(
        promotionKeyStore.makeTemporaryKey(),
      );
    } else {
      // The property isn't promotable, meaning it is not known to produce the
      // same (or equivalent) value every time it is queried. So we create a
      // fresh SSA node for every access; but we record the previous SSA node in
      // `_PropertySsaNode.previousSsaNode` so that the "why not promoted" logic
      // can figure out what promotions *would* have occurred if the field had
      // been promotable.
      _PropertySsaNode? previousSsaNode =
          _nonPromotableProperties[propertyName];
      return _nonPromotableProperties[propertyName] = new _PropertySsaNode(
        promotionKeyStore.makeTemporaryKey(),
        previousSsaNode: previousSsaNode,
      );
    }
  }

  @override
  String toString() {
    int id = _debugIds[this] ??= _nextDebugId++;
    return 'ssa$id';
  }

  /// Applies the property promotions from one SSA node to another. This is done
  /// as part of computing the effect of executing a try/finally's `try` and
  /// `finally` blocks in sequence, to apply the promotions that occurred in the
  /// `finally` block atop the promotions that occurred in the `try` block.
  ///
  /// [afterTrySsaNode] is the SSA node from the end of the `try` block, and
  /// [finallySsaNode] is the SSA node from the end of the `finally` block (this
  /// method is only invoked when the variable in question was not written to in
  /// the `finally` block, so it is also the SSA node from the beginning of the
  /// `finally` block).
  ///
  /// [beforeFinallyInfo] is the promotion info map from the flow state at the
  /// beginning of the `finally` block, and [afterFinallyInfo] is the promotion
  /// info map from the flow state at the end of the `finally` block.
  /// [newFlowModel] is the promotion info map for the flow state being
  /// built (the flow state after the try/finally block).
  FlowModel _applyPropertyPromotions(
    FlowModelHelper helper,
    SsaNode afterTrySsaNode,
    SsaNode finallySsaNode,
    PromotionInfo? beforeFinallyInfo,
    PromotionInfo? afterFinallyInfo,
    FlowModel newFlowModel,
  ) {
    // TODO(paulberry): fix nomenclature to align with caller.
    for (var MapEntry(
          key: String propertyName,
          value: _PropertySsaNode finallyPropertySsaNode,
        )
        in finallySsaNode._promotableProperties.entries) {
      // Since this method is only called when a variable is assigned in a `try`
      // block, a fresh SSA node should have been assigned for the `finally`
      // block by the conservative join in `tryFinallyStatement_finallyBegin`.
      // So the property should have been unpromoted (and unknown) at the
      // beginning of the `finally` block.
      assert(
        beforeFinallyInfo?.get(helper, finallyPropertySsaNode.promotionKey) ==
            null,
      );
      // Therefore all we need to do is apply any promotions that are in force
      // at the end of the `finally` block.
      PromotionModel? afterFinallyModel = afterFinallyInfo?.get(
        helper,
        finallyPropertySsaNode.promotionKey,
      );
      _PropertySsaNode afterTryPropertySsaNode =
          afterTrySsaNode._promotableProperties[propertyName] ??=
              new _PropertySsaNode(helper.promotionKeyStore.makeTemporaryKey());
      // Handle nested properties
      newFlowModel = _applyPropertyPromotions(
        helper,
        afterTryPropertySsaNode,
        finallyPropertySsaNode,
        beforeFinallyInfo,
        afterFinallyInfo,
        newFlowModel,
      );
      if (afterFinallyModel == null) continue;
      List<SharedTypeView> afterFinallyPromotedTypes =
          afterFinallyModel.promotedTypes;
      // The property was accessed in a promotion-relevant way in the `try`
      // block, so we need to apply the promotions from the `finally` block to
      // the flow model from the `try` block, and see what sticks.
      PromotionModel? newModel = newFlowModel.promotionInfo?.get(
        helper,
        afterTryPropertySsaNode.promotionKey,
      );
      if (newModel == null) {
        newModel = new PromotionModel.fresh(ssaNode: afterTryPropertySsaNode);
        newFlowModel = newFlowModel.updatePromotionInfo(
          helper,
          afterTryPropertySsaNode.promotionKey,
          newModel,
        );
      }
      List<SharedTypeView> newPromotedTypes = newModel.promotedTypes;
      List<SharedTypeView> rebasedPromotedTypes =
          PromotionModel.rebasePromotedTypes(
            basePromotions: newPromotedTypes,
            newPromotions: afterFinallyPromotedTypes,
            helper: helper,
          );
      if (!identical(newPromotedTypes, rebasedPromotedTypes)) {
        newFlowModel = newFlowModel.updatePromotionInfo(
          helper,
          afterTryPropertySsaNode.promotionKey,
          new PromotionModel(
            promotedTypes: rebasedPromotedTypes,
            tested: newModel.tested,
            assigned: true,
            unassigned: false,
            ssaNode: newModel.ssaNode,
          ),
        );
      }
    }
    return newFlowModel;
  }

  /// Joins the promotion information for the promotable properties of two SSA
  /// nodes, [first] and [second], and stores the results in
  /// [_promotableProperties].
  ///
  /// Since properties may themselves be promoted, the caller must supply the
  /// promotion info maps for the two flow control paths being joined
  /// ([firstPromotionInfo] and [secondPromotionInfo]), as well as the promotion
  /// info map being built for the join point ([newFlowModel]).
  FlowModel _joinProperties(
    FlowModelHelper helper,
    Map<String, _PropertySsaNode> first,
    PromotionInfo? firstPromotionInfo,
    Map<String, _PropertySsaNode> second,
    PromotionInfo? secondPromotionInfo,
    FlowModel newFlowModel,
  ) {
    // If a property has been accessed along one of the two control flow paths
    // being joined, but not the other, then it shouldn't be promoted after the
    // join point, nor should any of its nested properties. So it is only
    // necessary to examine properties common to the `first` and `second` maps.
    for (var MapEntry(
          key: String propertyName,
          value: _PropertySsaNode firstProperty,
        )
        in first.entries) {
      _PropertySsaNode? secondProperty = second[propertyName];
      if (secondProperty == null) continue;
      // Make a new promotion key to represent the joined property.
      int newPromotionKey = helper.promotionKeyStore.makeTemporaryKey();
      // If the property has a promotion model along both control flow paths,
      // it might be promoted, so join the two promotion models to preserve the
      // promotion.
      PromotionModel? firstPromotionModel = firstPromotionInfo?.get(
        helper,
        firstProperty.promotionKey,
      );
      _PropertySsaNode propertySsaNode = new _PropertySsaNode(newPromotionKey);
      _promotableProperties[propertyName] = propertySsaNode;
      if (firstPromotionModel != null) {
        PromotionModel? secondPromotionModel = secondPromotionInfo?.get(
          helper,
          secondProperty.promotionKey,
        );
        if (secondPromotionModel != null) {
          PromotionModel newPromotionModel;
          (newPromotionModel, newFlowModel) = PromotionModel.join(
            helper,
            firstPromotionModel,
            firstPromotionInfo,
            secondPromotionModel,
            secondPromotionInfo,
            newFlowModel,
            propertySsaNode: propertySsaNode,
          );
          newFlowModel = newFlowModel.updatePromotionInfo(
            helper,
            newPromotionKey,
            newPromotionModel,
          );
        }
      }
      // Join any nested properties.
      newFlowModel = propertySsaNode._joinProperties(
        helper,
        firstProperty._promotableProperties,
        firstPromotionInfo,
        secondProperty._promotableProperties,
        secondPromotionInfo,
        newFlowModel,
      );
    }
    return newFlowModel;
  }

  /// Joins the promotion information for two SSA nodes, [first] and [second].
  ///
  /// Since SSA nodes store information about properties, and properties may
  /// themselves be promoted, the caller must supply the promotion info maps for
  /// the two flow control paths being joined ([firstPromotionInfo] and
  /// [secondPromotionInfo]), as well as the promotion info map being built for
  /// the join point ([newFlowModel]).
  static (SsaNode, FlowModel) _join(
    FlowModelHelper helper,
    SsaNode first,
    PromotionInfo? firstPromotionInfo,
    SsaNode second,
    PromotionInfo? secondPromotionInfo,
    FlowModel newFlowModel,
  ) {
    SsaNode ssaNode;
    if (first == second) {
      ssaNode = first;
    } else {
      ssaNode = new SsaNode();
      newFlowModel = ssaNode._joinProperties(
        helper,
        first._promotableProperties,
        firstPromotionInfo,
        second._promotableProperties,
        secondPromotionInfo,
        newFlowModel,
      );
    }
    return (ssaNode, newFlowModel);
  }
}

/// [PropertyTarget] representing `super`.
class SuperPropertyTarget extends PropertyTarget<Never> {
  static const SuperPropertyTarget singleton = const SuperPropertyTarget._();

  const SuperPropertyTarget._() : super._();

  @override
  String toString() => 'SuperPropertyTarget()';

  @override
  SsaNode _getSsaNode(_PropertyTargetHelper<Object> helper) =>
      helper._superSsaNode;
}

/// Non-promotion reason describing the situation where an expression was not
/// promoted due to the fact that it's a reference to `this`.
class ThisNotPromoted extends NonPromotionReason {
  @override
  NonPromotionDocumentationLink get documentationLink =>
      NonPromotionDocumentationLink.this_;

  @override
  String get shortName => 'thisNotPromoted';

  @override
  R accept<R, Node extends Object, Variable extends Object>(
    NonPromotionReasonVisitor<R, Node, Variable> visitor,
  ) => visitor.visitThisNotPromoted(this);
}

/// [PropertyTarget] representing an implicit reference to `this`.
class ThisPropertyTarget extends PropertyTarget<Never> {
  static const ThisPropertyTarget singleton = const ThisPropertyTarget._();

  const ThisPropertyTarget._() : super._();

  @override
  String toString() => 'ThisPropertyTarget()';

  @override
  SsaNode _getSsaNode(_PropertyTargetHelper<Object> helper) =>
      helper._thisSsaNode;
}

/// Specialization of [ExpressionInfo] for the case where the expression is a
/// reference to a variable, and the information we have about the expression is
/// trivial (meaning we know by construction that the expression's [ifTrue] and
/// [ifFalse] models are the same).
@visibleForTesting
class TrivialVariableReference extends _Reference {
  TrivialVariableReference({
    required super.type,
    required super.model,
    required super.promotionKey,
    required super.isThisOrSuper,
    required super.ssaNode,
  }) : super.trivial();

  /// Produces an updated version of `this` reflecting flow analysis state from
  /// [conditionVariableInfo].
  ///
  /// [current] should be the current flow model, and [helper] should be
  /// the instance of [_FlowAnalysisImpl].
  ///
  /// UNSPECIFIED: This implements the "restore" part of the condition variable
  /// feature, in which writes to local variables cause flow analysis state to
  /// be saved, and reads of local variables cause flow analysis state to be
  /// partially restored. This is what allows type promotion in examples like
  /// the following:
  ///
  ///     int? x = ...;
  ///     var xIsNonNull = x != null; // The following state is now saved: if
  ///                                 // `xIsNonNull` is `true`, `x` is known
  ///                                 // to be non-null
  ///     ...Other statements...
  ///     if (xIsNonNull) {           // The state is now restored
  ///       print(x.isEven);          // Therefore this is ok, because `x` is
  ///                                 // known to be non-null.
  ///     }
  ///
  /// Note that in an example like this, the saved flow analysis state is only
  /// restored to the extent that it's sound to do so. There are two conditions
  /// for soundness, and they are addressed in different ways:
  ///
  /// 1. For the restore to be sound, the value of the condition variable at the
  ///    time of the read must be provably the same as the value that was
  ///    written. That is, there must not be any write captures or intervening
  ///    writes of the condition variable on the control path leading up to the
  ///    read. This is addressed by saving the flow analysis state in the
  ///    [SsaNode.conditionVariableState] field. Since a write to a variable
  ///    causes it to be associated with a new [SsaNode], and a write capture of
  ///    a variable causes its [SsaNode] association to be permanently set to
  ///    `null`, this assures that an attempt to restore the saved state will
  ///    only be made if there are no write captures or intervening writes.
  ///
  /// 2. Considering each variable referred to in the stored state (e.g., `x`,
  ///    in the example above), it is only sound to restore the state of that
  ///    variable if its value is provably the same as it was at the time the
  ///    condition variable was written. That is, there must not be any write
  ///    captures or intervening writes of the referenced variable on the
  ///    control path leading up to the read. This is addressed by
  ///    [FlowModel.rebaseForward] (which is called by this method to do the
  ///    restore); it only updates the [PromotionModel]s of variables whose
  ///    [SsaNode] is (a) non-null (i.e., not write captured) and (b) the same
  ///    as it was at the time the state was saved (i.e., no intervening
  ///    writes).
  ///
  /// Note that this method is also invoked by
  /// [_FlowAnalysisImpl._pushScrutinee]. This ensures that stored flow analysis
  /// state propagates through pattern assignments, e.g.:
  ///
  ///     int? x = ...;
  ///     var (xIsNonNull) = x != null; // Note: pattern assignment
  ///     ...Other statements...
  ///     if (xIsNonNull) {
  ///       print(x.isEven);            // Ok
  ///     }
  ///
  /// See https://github.com/dart-lang/language/issues/1274, the original
  /// feature request for this feature.
  _Reference restoreConditionVariableState(
    ExpressionInfo? conditionVariableInfo,
    FlowModelHelper helper,
    FlowModel current,
  ) {
    if (conditionVariableInfo != null && conditionVariableInfo.isNonTrivial) {
      // `conditionVariableInfo` contained non-trivial flow analysis
      // information, so we need to rebase its [ifTrue] and [ifFalse] flow
      // models.
      return new _Reference(
        promotionKey: promotionKey,
        type: _type,
        isThisOrSuper: isThisOrSuper,
        ifTrue: conditionVariableInfo.ifTrue.rebaseForward(helper, current),
        ifFalse: conditionVariableInfo.ifFalse.rebaseForward(helper, current),
        ssaNode: ssaNode,
      );
    } else {
      // `conditionVariableInfo` didn't contain any non-trivial flow analysis
      // information, so nothing needs to be updated.
      return this;
    }
  }

  @override
  String toString() =>
      'TrivialVariableReference(type: $_type, '
      'promotionKey: $promotionKey, isThisOrSuper: $isThisOrSuper, '
      'ssaNode: $ssaNode)';
}

class WhyNotPromotedInfo {}

/// [_FlowContext] representing a block-bodied anonymous method.
class _AnonymousBlockContext extends _FlowContext {
  /// Accumulated flow model for all `return` statements seen so far, or `null`
  /// if no `return` statements have been seen yet.
  FlowModel? _returnModel;

  /// The reachability checkpoint associated with this block-bodied anonymous
  /// method. When analyzing deeply nested `return` statements, their flow
  /// models need to be unsplit to this point before joining them to
  /// [_returnModel].
  final Reachability _checkpoint;

  /// The [_AnonymousBlockContext] for the immediately enclosing block-bodied
  /// anonymous method, or `null` if there is no enclosing block-bodied
  /// anonymous method.
  final _AnonymousBlockContext? _previousAnonymousBlockContext;

  _AnonymousBlockContext(this._checkpoint, this._previousAnonymousBlockContext);

  @override
  Map<String, Object?> get _debugFields => super._debugFields
    ..['returnModel'] = _returnModel
    ..['checkpoint'] = _checkpoint
    ..['previousAnonymousBlockContext'] = _previousAnonymousBlockContext;

  @override
  String get _debugType => '_AnonymousBlockContext';
}

/// [_FlowContext] representing an assert statement or assert initializer.
class _AssertContext extends _SimpleContext {
  /// Flow model if the condition being asserted is true.
  FlowModel? _conditionTrue;

  _AssertContext(super.previous);

  @override
  Map<String, Object?> get _debugFields =>
      super._debugFields..['conditionTrue'] = _conditionTrue;

  @override
  String get _debugType => '_AssertContext';
}

/// [_FlowContext] representing a language construct that branches on a boolean
/// condition, such as an `if` statement, conditional expression, or a logical
/// binary operator.
class _BranchContext extends _FlowContext {
  /// Flow model if the branch is taken.
  final FlowModel _branchModel;

  _BranchContext(this._branchModel);

  @override
  Map<String, Object?> get _debugFields =>
      super._debugFields..['branchModel'] = _branchModel;

  @override
  String get _debugType => '_BranchContext';
}

/// [_FlowContext] representing a language construct that can be targeted by
/// `break` or `continue` statements, such as a loop or switch statement.
class _BranchTargetContext extends _FlowContext {
  /// Accumulated flow model for all `break` statements seen so far, or `null`
  /// if no `break` statements have been seen yet.
  FlowModel? _breakModel;

  /// Accumulated flow model for all `continue` statements seen so far, or
  /// `null` if no `continue` statements have been seen yet.
  FlowModel? _continueModel;

  /// The reachability checkpoint associated with this loop or switch statement.
  /// When analyzing deeply nested `break` and `continue` statements, their flow
  /// models need to be unsplit to this point before joining them to the control
  /// flow paths for the loop or switch.
  final Reachability _checkpoint;

  _BranchTargetContext(this._checkpoint);

  @override
  Map<String, Object?> get _debugFields => super._debugFields
    ..['breakModel'] = _breakModel
    ..['continueModel'] = _continueModel
    ..['checkpoint'] = _checkpoint;

  @override
  String get _debugType => '_BranchTargetContext';
}

/// [_FlowContext] representing a conditional expression.
class _ConditionalContext extends _BranchContext {
  /// Expression info for the "then" expression, or `null` if the "then"
  /// expression hasn't been analyzed yet.
  ///
  /// This object records flow-analysis-related information about the value of
  /// the "then" expression, such as whether it refers to a promotable value,
  /// and if it's a boolean expression, whether anything should be promoted
  /// in flow control paths where it evaluates to true or false.
  ExpressionInfo? _thenInfo;

  /// Flow model leaving the "then" expression, or `null` if the "then"
  /// expression hasn't been analyzed yet.
  ///
  /// This object records flow-analysis-related information about the state of
  /// the program in the flow control path leaving the "then" expression, such
  /// as whether anything is promoted after the "then" expression executes.
  FlowModel? _thenModel;

  _ConditionalContext(super._branchModel);

  @override
  Map<String, Object?> get _debugFields => super._debugFields
    ..['thenInfo'] = _thenInfo
    ..['thenModel'] = _thenModel;

  @override
  String get _debugType => '_ConditionalContext';
}

/// Data structure representing the result of demoting a variable from one type
/// to another.
class _DemotionResult {
  /// The new set of promoted types.
  final List<SharedTypeView> promotedTypes;

  /// The new non-promotion history (including the types that the variable is
  /// no longer promoted to).
  final NonPromotionHistory? nonPromotionHistory;

  _DemotionResult(this.promotedTypes, this.nonPromotionHistory);
}

/// Specialization of [_EqualityCheckResult] used as the return value for
/// [_FlowAnalysisImpl._equalityCheck] when exactly one of the two operands is a
/// `null` literal (and therefore the equality test is testing whether the other
/// operand is `null`).
///
/// Note that if both operands are `null`, then [_GuaranteedEqual] will be
/// returned instead.
class _EqualityCheckIsNullCheck extends _EqualityCheckResult {
  /// If the operand that is being null-tested is something that can undergo
  /// type promotion, the object recording its promotion key, type information,
  /// etc.  Otherwise, `null`.
  final _Reference? reference;

  /// If `true` the operand that's being null-tested corresponds to
  /// [_FlowAnalysisImpl._equalityCheck]'s `rightOperandInfo` argument; if
  /// `false`, it corresponds to [_FlowAnalysisImpl._equalityCheck]'s
  /// `leftOperandInfo` argument.
  final bool isReferenceOnRight;

  _EqualityCheckIsNullCheck(this.reference, {required this.isReferenceOnRight})
    : super._();
}

/// Result of performing equality check.  This class is used as the return value
/// for [_FlowAnalysisImpl._equalityCheck].
sealed class _EqualityCheckResult {
  const _EqualityCheckResult._();
}

class _FlowAnalysisImpl<
  Node extends Object,
  Statement extends Node,
  Expression extends Node,
  Variable extends Object
>
    with FlowModelHelper
    implements
        FlowAnalysis<Node, Statement, Expression, Variable>,
        _PropertyTargetHelper<Expression> {
  @override
  final TypeAnalyzerOptions typeAnalyzerOptions;

  /// The [FlowAnalysisOperations], used to access types, check subtyping, and
  /// query variable types.
  @override
  final FlowAnalysisOperations<Variable> operations;

  /// Stack of [_FlowContext] objects representing the statements and
  /// expressions that are currently being visited.
  final List<_FlowContext> _stack = [];

  /// The mapping from [Statement]s that can act as targets for `break` and
  /// `continue` statements (i.e. loops and switch statements) to the to their
  /// context information.
  final Map<Statement, _BranchTargetContext> _statementToContext = {};

  /// The current flow model.
  ///
  /// This should only be accessed directly by [_current] and [_setCurrent].
  /// This helps ensure that we don't forget to call
  /// [FlowAnalysisLogBuilder.promotionInfoChanged] when the value of [_current]
  /// changes.
  FlowModel _currentInternal = new FlowModel(Reachability.initial);

  /// If a pattern is being analyzed, flow model representing all code paths
  /// accumulated so far in which the pattern fails to match.  Otherwise `null`.
  FlowModel? _unmatched;

  /// If a pattern is being analyzed, and the scrutinee is something that might
  /// be relevant to type promotion as a consequence of the pattern match,
  /// [_Reference] object referring to the scrutinee.  Otherwise `null`.
  _Reference? _scrutineeReference;

  final AssignedVariables<Node, Variable> _assignedVariables;

  @override
  final PromotionKeyStore<Variable> promotionKeyStore;

  /// For debugging only: the set of [Variable]s that have been passed to
  /// [declare] so far.  This is used to detect unnecessary calls to [declare].
  final Set<Variable> _debugDeclaredVariables =
      // TODO(paulberry): consider changing back to `{}` once
      // https://github.com/dart-lang/sdk/issues/59753 is fixed.
      new Set.identity();

  @override
  late final SsaNode _superSsaNode = new SsaNode();

  final List<SsaNode> _thisSsaNodes = [new SsaNode()];

  late final List<int> _thisPromotionKeys = [_makeInitialThisPromotionKey()];

  @override
  final List<_Reference> _cascadeTargetStack = [];

  /// The [_AnonymousBlockContext] for the immediately enclosing block-bodied
  /// anonymous method, if there is one. Otherwise `null`.
  _AnonymousBlockContext? _anonymousBlockContext;

  /// Stack of [AssignedVariablesNodeInfo] for any local function, function
  /// expression, or late variable initializer expression that encloses the
  /// point in flow control that's currently being analyzed.
  final List<AssignedVariablesNodeInfo> _enclosingFunctionExpressionInfoStack =
      [];

  final FlowAnalysisLogBuilder? _logBuilder;

  _FlowAnalysisImpl(
    this.operations,
    this._assignedVariables, {
    required this.typeAnalyzerOptions,
    required bool enableLog,
  }) : promotionKeyStore = _assignedVariables.promotionKeyStore,
       _logBuilder = enableLog ? new FlowAnalysisLogBuilder() : null {
    if (!_assignedVariables.isFinished) {
      _assignedVariables.finish();
    }
  }

  @override
  SharedTypeView get boolType => operations.boolType;

  @override
  bool get isReachable => _current.reachable.overallReachable;

  @override
  SharedTypeView? get promotedTypeOfThis {
    if (!typeAnalyzerOptions.thisPromotionEnabled) return null;
    return _current.promotionInfo
        ?.get(this, _thisPromotionKeys.last)
        ?.promotedTypes
        .lastOrNull;
  }

  @override
  FlowAnalysisTypeOperations get typeOperations => operations;

  /// Retrieves the current flow model.
  FlowModel get _current => _currentInternal;

  @override
  SsaNode get _thisSsaNode => _thisSsaNodes.last;

  @override
  void anonymousBlockBody_begin({int offset = 0}) {
    _setCurrent(_current.split(), offset: offset);
    _AnonymousBlockContext context = new _AnonymousBlockContext(
      _current.reachable.parent!,
      _anonymousBlockContext,
    );
    _stack.add(context);
    _anonymousBlockContext = context;
  }

  @override
  void anonymousBlockBody_end({int offset = 0}) {
    _AnonymousBlockContext context =
        _stack.removeLast() as _AnonymousBlockContext;
    _setCurrent(
      _join(_current, context._returnModel).unsplit(),
      offset: offset,
    );
    _anonymousBlockContext = context._previousAnonymousBlockContext;
  }

  @override
  void asExpression_end(
    ExpressionInfo? subExpressionInfo, {
    required SharedTypeView subExpressionType,
    required SharedTypeView castType,
    int offset = 0,
  }) {
    // Depending on types, flow analysis may be able to prove that the `as`
    // expression is guaranteed to fail.
    if (_isTypeCheckGuaranteedToFailWithSoundNullSafety(
      staticType: subExpressionType,
      checkedType: castType,
    )) {
      _setCurrent(_current.setUnreachable(), offset: offset);
    }

    _Reference? reference = _getExpressionReference(subExpressionInfo);
    if (reference != null) {
      _setCurrent(
        _current.tryPromoteForTypeCast(this, reference, castType),
        offset: offset,
      );
    }
  }

  @override
  void assert_afterCondition(ExpressionInfo? conditionInfo, {int offset = 0}) {
    _AssertContext context = _stack.last as _AssertContext;
    conditionInfo ??= _makeTrivialExpressionInfo(boolType);
    context._conditionTrue = conditionInfo.ifTrue;
    _setCurrent(conditionInfo.ifFalse, offset: offset);
  }

  @override
  void assert_begin({int offset = 0}) {
    _setCurrent(_current.split(), offset: offset);
    _stack.add(new _AssertContext(_current));
  }

  @override
  void assert_end({int offset = 0}) {
    _AssertContext context = _stack.removeLast() as _AssertContext;
    _setCurrent(
      _join(context._previous, context._conditionTrue!).unsplit(),
      offset: offset,
    );
  }

  @override
  void assignedVariablePattern(
    Node node,
    Variable variable,
    SharedTypeView writtenType, {
    int offset = 0,
  }) {
    _PatternContext context = _stack.last as _PatternContext;
    _write(
      node,
      variable,
      writtenType,
      context._matchedValueInfo,
      offset: offset,
    );
  }

  @override
  void assignMatchedPatternVariable(
    Variable variable,
    int promotionKey, {
    int offset = 0,
  }) {
    int mergedKey = promotionKeyStore.keyForVariable(variable);
    PromotionModel info =
        _current.promotionInfo?.get(this, promotionKey) ??
        new PromotionModel.fresh(ssaNode: new SsaNode());
    // Normally flow analysis is responsible for tracking whether variables are
    // definitely assigned; however for variables appearing in patterns we
    // have other logic to make sure that a value is definitely assigned (e.g.
    // the rule that a variable appearing on one side of an `||` must also
    // appear on the other side).  So to avoid reporting redundant errors, we
    // pretend that the variable is definitely assigned, even if it isn't.
    info = info._setAssigned();
    _setCurrent(
      _current.updatePromotionInfo(this, mergedKey, info),
      offset: offset,
    );
  }

  @override
  ExpressionInfo booleanLiteral(bool value) {
    FlowModel unreachable = _current.setUnreachable();
    if (value) {
      return new ExpressionInfo(
        type: boolType,
        ifTrue: _current,
        ifFalse: unreachable,
      );
    } else {
      return new ExpressionInfo(
        type: boolType,
        ifTrue: unreachable,
        ifFalse: _current,
      );
    }
  }

  @override
  SharedTypeView cascadeExpression_afterTarget(
    ExpressionInfo? targetInfo,
    SharedTypeView targetType, {
    required bool isNullAware,
    Variable? guardVariable,
    int offset = 0,
  }) {
    // If the cascade is null-aware, then during the cascade sections, the
    // effective type of the target is promoted to non-null.
    SharedTypeView promotedTargetType = isNullAware
        ? operations.promoteToNonNull(targetType)
        : targetType;
    // Retrieve the SSA node for the cascade target, if one has been created
    // already, so that field accesses within cascade sections will receive the
    // benefit of previous field promotions. If an SSA node for the target
    // hasn't been created yet (e.g. because it's not a read of a local
    // variable), create a fresh SSA node for it, so that field promotions that
    // occur during cascade sections will persist in later cascade sections.
    _Reference? expressionReference = _getExpressionReference(targetInfo);
    SsaNode ssaNode = expressionReference?.ssaNode ?? new SsaNode();
    // Create a temporary reference to represent the implicit temporary variable
    // that holds the cascade target. It is important that this is different
    // from `expressionReference`, because if the target is a local variable,
    // and that variable is written during one of the cascade sections, future
    // cascade sections should still be understood to act on the value the
    // variable had before the write. (e.g. in
    // `x.._field!.f(x = g()).._field.h()`, no `!` is needed on the second
    // access to `_field`, even though `x` has been written to).
    _cascadeTargetStack.add(
      _makeTemporaryReference(ssaNode, promotedTargetType, offset: offset),
    );
    if (isNullAware) {
      _nullAwareAccess_rightBegin(
        expressionReference,
        targetType,
        guardVariable: guardVariable,
        offset: offset,
      );
    }
    return promotedTargetType;
  }

  @override
  ExpressionInfo cascadeExpression_end() {
    // TODO(paulberry): if the cascade expression is null-aware, do the
    // equivalent of `nullAwareAccess_end`, so that the caller doesn't have to
    // have a separate call to `nullAwareAccess_end`.

    // Pop the reference for the temporary variable that holds the target of the
    // cascade stack. It becomes the reference for the whole expression. This
    // ensures that field accesses performed on the whole cascade expression
    // (e.g. `(x..f())._field` will still receive the benefit of field
    // promotion.
    return _cascadeTargetStack.removeLast();
  }

  @override
  void checkOffset(int offset) {
    _logBuilder?.checkOffset(offset);
  }

  @override
  void conditional_conditionBegin({int offset = 0}) {
    _setCurrent(_current.split(), offset: offset);
  }

  @override
  void conditional_elseBegin(
    ExpressionInfo? thenExpressionInfo,
    SharedTypeView thenType, {
    int offset = 0,
  }) {
    _ConditionalContext context = _stack.last as _ConditionalContext;
    context._thenInfo =
        thenExpressionInfo ?? _makeTrivialExpressionInfo(thenType);
    context._thenModel = _current;
    _setCurrent(context._branchModel, offset: offset);
  }

  @override
  ExpressionInfo conditional_end(
    SharedTypeView conditionalExpressionType,
    ExpressionInfo? elseExpressionInfo,
    SharedTypeView elseType, {
    int offset = 0,
  }) {
    _ConditionalContext context = _stack.removeLast() as _ConditionalContext;
    ExpressionInfo thenInfo = context._thenInfo!;
    FlowModel thenModel = context._thenModel!;
    elseExpressionInfo ??= _makeTrivialExpressionInfo(elseType);
    FlowModel elseModel = _current;
    _setCurrent(_join(thenModel, elseModel).unsplit(), offset: offset);
    return new ExpressionInfo(
      type: conditionalExpressionType,
      ifTrue: _join(thenInfo.ifTrue, elseExpressionInfo.ifTrue).unsplit(),
      ifFalse: _join(thenInfo.ifFalse, elseExpressionInfo.ifFalse).unsplit(),
    );
  }

  @override
  void conditional_thenBegin(
    ExpressionInfo? conditionInfo,
    Node conditionalExpression, {
    int offset = 0,
  }) {
    conditionInfo ??= _makeTrivialExpressionInfo(boolType);
    _stack.add(new _ConditionalContext(conditionInfo.ifFalse));
    _setCurrent(conditionInfo.ifTrue, offset: offset);
  }

  @override
  void constantPattern_end(
    ExpressionInfo? expressionInfo,
    SharedTypeView type, {
    required bool patternsEnabled,
    required SharedTypeView matchedValueType,
    int offset = 0,
  }) {
    assert(_stack.last is _PatternContext);
    if (patternsEnabled) {
      _handleEqualityCheckPattern(
        expressionInfo,
        type,
        notEqual: false,
        matchedValueType: matchedValueType,
        offset: offset,
      );
    } else {
      // Before pattern support was added to Dart, flow analysis didn't do any
      // promotion based on the constants in individual case clauses.  Also, it
      // assumed that all case clauses were equally reachable.  So, when
      // analyzing legacy code that targets a language version before patterns
      // were supported, we need to mimic that old behavior.  The easiest way to
      // do that is to simply assume that the pattern might or might not match,
      // regardless of the constant expression.
      _unmatched = _join(_unmatched!, _current);
    }
  }

  @override
  void copyPromotionData({
    required int sourceKey,
    required int destinationKey,
    int offset = 0,
  }) {
    _setCurrent(
      _current.updatePromotionInfo(
        this,
        destinationKey,
        _current.promotionInfo?.get(this, sourceKey) ??
            new PromotionModel.fresh(ssaNode: new SsaNode()),
      ),
      offset: offset,
    );
  }

  @override
  void declare(
    Variable variable,
    SharedTypeView staticType, {
    required bool initialized,
    int offset = 0,
  }) {
    assert(staticType == operations.variableType(variable));
    assert(
      _debugDeclaredVariables.add(variable),
      'Variable $variable already declared',
    );
    _setCurrent(
      _current.declare(
        this,
        promotionKeyStore.keyForVariable(variable),
        initialized,
      ),
      offset: offset,
    );
  }

  @override
  int declaredVariablePattern({
    required SharedTypeView matchedType,
    required SharedTypeView staticType,
    bool isFinal = false,
    bool isLate = false,
    required bool isImplicitlyTyped,
    int offset = 0,
  }) {
    _PatternContext context = _stack.last as _PatternContext;
    // Choose a fresh promotion key to represent the temporary variable that
    // stores the matched value, and mark it as initialized.
    int promotionKey = promotionKeyStore.makeTemporaryKey();
    _setCurrent(_current.declare(this, promotionKey, true), offset: offset);
    _initialize(
      promotionKey,
      matchedType,
      context._matchedValueInfo,
      isFinal: isFinal,
      isLate: isLate,
      isImplicitlyTyped: isImplicitlyTyped,
      unpromotedType: staticType,
      offset: offset,
    );
    return promotionKey;
  }

  @override
  void doStatement_bodyBegin(Statement doStatement, {int offset = 0}) {
    AssignedVariablesNodeInfo info = _assignedVariables.getInfoForNode(
      doStatement,
    );
    _BranchTargetContext context = new _BranchTargetContext(_current.reachable);
    _stack.add(context);
    _setCurrent(
      _current.split().conservativeJoin(this, info.written, info.captured),
      offset: offset,
    );
    _statementToContext[doStatement] = context;
  }

  @override
  void doStatement_conditionBegin({int offset = 0}) {
    _BranchTargetContext context = _stack.last as _BranchTargetContext;
    _setCurrent(_join(_current, context._continueModel), offset: offset);
  }

  @override
  void doStatement_end(ExpressionInfo? conditionInfo, {int offset = 0}) {
    _BranchTargetContext context = _stack.removeLast() as _BranchTargetContext;
    _setCurrent(
      _join(
        (conditionInfo ?? _makeTrivialExpressionInfo(boolType)).ifFalse,
        context._breakModel,
      ).unsplit(),
      offset: offset,
    );
  }

  @override
  ExpressionInfo? equalityOperation_end(
    ExpressionInfo? leftOperandInfo,
    SharedTypeView leftOperandType,
    ExpressionInfo? rightOperandInfo,
    SharedTypeView rightOperandType, {
    bool notEqual = false,
  }) {
    // Note: leftOperandInfo and rightOperandInfo are nullable in the base class
    // to account for the fact that legacy type promotion doesn't record
    // information about legacy operands.  But since we are currently in full
    // (post null safety) flow analysis logic, we can safely assume that they
    // are not null.
    switch (_equalityCheck(
      leftOperandInfo,
      leftOperandType,
      rightOperandInfo,
      rightOperandType,
    )) {
      case _GuaranteedEqual():
        // Both operands are known by flow analysis to compare equal, so the
        // whole expression behaves equivalently to a boolean (either `true` or
        // `false` depending whether the check uses the `!=` operator).
        return booleanLiteral(!notEqual);
      case _GuaranteedNotEqual():
        // Both operands are known by flow analysis to compare unequal, so the
        // whole expression behaves equivalently to a boolean (either `true` or
        // `false` depending whether the check uses the `!=` operator).
        return booleanLiteral(notEqual);

      // SAFETY: we can assume `reference` is a `_Reference<Type>` because we
      // require clients not to mix data obtained from different
      // instantiations of `FlowAnalysis`.
      case _EqualityCheckIsNullCheck(:var reference):
        if (reference == null) {
          // One side of the equality check is `null`, but the other side is not
          // a promotable reference.  So there's no promotion to do.
          return null;
        }
        // The equality check is a null check of something potentially
        // promotable (e.g. a local variable).  Record the necessary information
        // so that if this null check winds up being used for a conditional
        // branch, the variable's will be promoted on the appropriate code path.
        ExpressionInfo equalityInfo = _current.tryMarkNonNullable(
          this,
          reference,
        );
        return notEqual ? equalityInfo : equalityInfo._invert();

      case _NoEqualityInformation():
        // Since flow analysis can't garner any information from this equality
        // check, nothing needs to be done; by not returning any expression
        // info, we ensure that if this expression winds up being used for a
        // conditional branch, flow analysis will consider both code paths
        // reachable and won't perform any promotions on either path.
        return null;
    }
  }

  @override
  void equalityRelationalPattern_end(
    ExpressionInfo? operandInfo,
    SharedTypeView operandType, {
    bool notEqual = false,
    required SharedTypeView matchedValueType,
    int offset = 0,
  }) {
    _handleEqualityCheckPattern(
      operandInfo,
      operandType,
      notEqual: notEqual,
      matchedValueType: matchedValueType,
      offset: offset,
    );
  }

  @override
  void finish() {
    assert(_stack.isEmpty);
    assert(_current.reachable.parent == null);
    assert(_unmatched == null);
    assert(_scrutineeReference == null);
    assert(_enclosingFunctionExpressionInfoStack.isEmpty);
  }

  @override
  void for_bodyBegin(
    Statement? node,
    ExpressionInfo? conditionInfo, {
    int offset = 0,
  }) {
    conditionInfo ??= _makeTrivialExpressionInfo(boolType);
    _WhileContext context = new _WhileContext(
      _current.reachable.parent!,
      conditionInfo.ifFalse,
    );
    _stack.add(context);
    if (node != null) {
      _statementToContext[node] = context;
    }
    _setCurrent(conditionInfo.ifTrue, offset: offset);
  }

  @override
  void for_conditionBegin(Node node, {int offset = 0}) {
    AssignedVariablesNodeInfo info = _assignedVariables.getInfoForNode(node);
    _setCurrent(
      _current.split().conservativeJoin(this, info.written, info.captured),
      offset: offset,
    );
  }

  @override
  void for_end({int offset = 0}) {
    _WhileContext context = _stack.removeLast() as _WhileContext;
    // Tail of the stack: falseCondition, break
    FlowModel? breakState = context._breakModel;
    FlowModel falseCondition = context._conditionFalse;

    _setCurrent(
      _join(falseCondition, breakState).inheritTested(this, _current).unsplit(),
      offset: offset,
    );
  }

  @override
  void for_updaterBegin({int offset = 0}) {
    // Considering source code order, the updater part of a for loop comes
    // before the loop body, but it's visited by flow analysis after. So we need
    // to make an exception to the usual requirement that offsets are strictly
    // increasing.
    _logBuilder?.allowOutOfOrderOffsets();
    _WhileContext context = _stack.last as _WhileContext;
    _setCurrent(_join(_current, context._continueModel), offset: offset);
  }

  @override
  void forEach_bodyBegin(Node node, {int offset = 0}) {
    AssignedVariablesNodeInfo info = _assignedVariables.getInfoForNode(node);
    _setCurrent(
      _current.split().conservativeJoin(this, info.written, info.captured),
      offset: offset,
    );
    _SimpleStatementContext context = new _SimpleStatementContext(
      _current.reachable.parent!,
      _current,
    );
    _stack.add(context);
  }

  @override
  void forEach_end({int offset = 0}) {
    _SimpleStatementContext context =
        _stack.removeLast() as _SimpleStatementContext;
    _setCurrent(_join(_current, context._previous).unsplit(), offset: offset);
  }

  @override
  void functionExpression_begin(Node node, {int offset = 0}) {
    _functionExpression_begin(node, offset: offset);
  }

  @override
  void functionExpression_end({int offset = 0}) {
    _functionExpression_end(offset: offset);
  }

  @override
  PromotionInfo? getCurrentPromotionInfo() => _current.promotionInfo;

  @override
  int getCurrentThisBinding() => _thisPromotionKeys.last;

  @override
  FlowAnalysisLog? getLog() => _logBuilder?.finish();

  @override
  SharedTypeView getMatchedValueType() => _getMatchedValueType();

  @override
  void handleBreak(Statement? target, {int offset = 0}) {
    _BranchTargetContext? context = _statementToContext[target];
    if (context != null) {
      context._breakModel = _join(
        context._breakModel,
        _current.unsplitTo(context._checkpoint),
      );
    }
    _setCurrent(_current.setUnreachable(), offset: offset);
  }

  @override
  void handleContinue(Statement? target, {int offset = 0}) {
    _BranchTargetContext? context = _statementToContext[target];
    if (context != null) {
      context._continueModel = _join(
        context._continueModel,
        _current.unsplitTo(context._checkpoint),
      );
    }
    _setCurrent(_current.setUnreachable(), offset: offset);
  }

  @override
  void handleExit({int offset = 0}) {
    _setCurrent(_current.setUnreachable(), offset: offset);
  }

  @override
  void handleReturn({int offset = 0}) {
    if (_anonymousBlockContext case var anonymousMethodContext?) {
      // There is a control flow path from the current point to the
      // exit of the anonymous method.
      anonymousMethodContext._returnModel = _join(
        anonymousMethodContext._returnModel,
        _current.unsplitTo(anonymousMethodContext._checkpoint),
      );
    }
    _setCurrent(_current.setUnreachable(), offset: offset);
  }

  @override
  void ifCaseStatement_afterExpression(
    ExpressionInfo? scrutineeInfo,
    SharedTypeView scrutineeType, {
    int offset = 0,
  }) {
    // If S0 is the statement `if (E0 case P when E1) S1 else S2`, then:
    // - before(P) = after(E0),
    // - before(E1) = matched(P).
    // Note that we don't need to take any action to handle
    // `before(E1) = matched(P)`, because we store both the "matched" state for
    // patterns and the "before" state for expressions in `_current`.
    _pushPattern(
      _pushScrutinee(
        scrutineeInfo,
        scrutineeType,
        allowScrutineePromotion: true,
        offset: offset,
      ),
      offset: offset,
    );
  }

  @override
  void ifCaseStatement_begin({int offset = 0}) {
    // If S0 is the statement `if (E0 case P when E1) S1 else S2`, then:
    // - before(E0) = split(before(S0)).
    _setCurrent(_current.split(), offset: offset);
  }

  @override
  void ifCaseStatement_thenBegin(ExpressionInfo? guardInfo, {int offset = 0}) {
    // If S0 is the statement `if (E0 case P when E1) S1 else S2`, then:
    // - before(S1) = true(E1).
    FlowModel branchModel = _popPattern(guardInfo, offset: offset);
    _popScrutinee();
    _stack.add(new _IfContext(branchModel));
  }

  @override
  void ifNullExpression_end({int offset = 0}) {
    _IfNullExpressionContext context =
        _stack.removeLast() as _IfNullExpressionContext;
    _setCurrent(
      _join(_current, context._shortcutState).unsplit(),
      offset: offset,
    );
  }

  @override
  void ifNullExpression_rightBegin(
    ExpressionInfo? leftHandSideInfo,
    SharedTypeView leftHandSideType, {
    int offset = 0,
  }) {
    _Reference? lhsReference = _getExpressionReference(leftHandSideInfo);
    FlowModel shortcutState;
    _setCurrent(_current.split(), offset: offset);
    if (lhsReference != null) {
      shortcutState = _current.tryMarkNonNullable(this, lhsReference).ifTrue;
    } else {
      shortcutState = _current;
    }
    switch (operations.classifyType(leftHandSideType)) {
      case TypeClassification.nullOrEquivalent:
        // The control path that skips the "if null" code is unreachable.
        shortcutState = shortcutState.setUnreachable();
      case TypeClassification.nonNullable:
        // The control path containing the "if null" code is unreachable,
        // assuming sound null safety.
        if (typeAnalyzerOptions.soundFlowAnalysisEnabled) {
          _setCurrent(_current.setUnreachable(), offset: offset);
        }
      case TypeClassification.potentiallyNullable:
        // Both control flow paths are reachable.
        break;
    }
    _stack.add(new _IfNullExpressionContext(shortcutState));
  }

  @override
  void ifStatement_conditionBegin({int offset = 0}) {
    _setCurrent(_current.split(), offset: offset);
  }

  @override
  void ifStatement_elseBegin({int offset = 0}) {
    _IfContext context = _stack.last as _IfContext;
    context._afterThen = _current;
    _setCurrent(context._branchModel, offset: offset);
  }

  @override
  void ifStatement_end(bool hasElse, {int offset = 0}) {
    _IfContext context = _stack.removeLast() as _IfContext;
    FlowModel afterThen;
    FlowModel afterElse;
    if (hasElse) {
      afterThen = context._afterThen!;
      afterElse = _current;
    } else {
      afterThen = _current; // no `else`, so `then` is still current
      afterElse = context._branchModel;
    }
    _setCurrent(_join(afterThen, afterElse).unsplit(), offset: offset);
  }

  @override
  void ifStatement_thenBegin(
    ExpressionInfo? conditionInfo,
    Node ifNode, {
    int offset = 0,
  }) {
    conditionInfo ??= _makeTrivialExpressionInfo(boolType);
    _stack.add(new _IfContext(conditionInfo.ifFalse));
    _setCurrent(conditionInfo.ifTrue, offset: offset);
  }

  @override
  void initialize(
    Variable variable,
    SharedTypeView matchedType,
    ExpressionInfo? initializerExpressionInfo, {
    required bool isFinal,
    required bool isLate,
    required bool isImplicitlyTyped,
    bool inheritPromotableProperties = false,
    int offset = 0,
  }) {
    SharedTypeView unpromotedType = operations.variableType(variable);
    int variableKey = promotionKeyStore.keyForVariable(variable);
    _initialize(
      variableKey,
      matchedType,
      initializerExpressionInfo,
      isFinal: isFinal,
      isLate: isLate,
      isImplicitlyTyped: isImplicitlyTyped,
      unpromotedType: unpromotedType,
      inheritPromotableProperties: inheritPromotableProperties,
      offset: offset,
    );
  }

  @override
  bool isAssigned(Variable variable) {
    return _current.promotionInfo
            ?.get(this, promotionKeyStore.keyForVariable(variable))
            ?.assigned ??
        false;
  }

  @override
  ExpressionInfo? isExpression_end(
    ExpressionInfo? subExpressionInfo,
    bool isNot, {
    required SharedTypeView subExpressionType,
    required SharedTypeView checkedType,
  }) {
    if (operations.isBottomType(checkedType) ||
        _isTypeCheckGuaranteedToFailWithSoundNullSafety(
          staticType: subExpressionType,
          checkedType: checkedType,
        )) {
      return booleanLiteral(isNot);
    } else {
      _Reference? subExpressionReference = _getExpressionReference(
        subExpressionInfo,
      );
      if (subExpressionReference != null) {
        ExpressionInfo expressionInfo = _current.tryPromoteForTypeCheck(
          this,
          subExpressionReference,
          checkedType,
        );
        return isNot ? expressionInfo._invert() : expressionInfo;
      } else if (_isTypeCheckGuaranteedToSucceedWithSoundNullSafety(
        staticType: subExpressionType,
        checkedType: checkedType,
      )) {
        return booleanLiteral(!isNot);
      } else {
        return null;
      }
    }
  }

  @override
  bool isFinal(int variableKey) {
    if (!typeAnalyzerOptions.inferenceUpdate4Enabled) return false;
    Variable? variable = promotionKeyStore.variableForKey(variableKey);
    if (variable != null && operations.isFinal(variable)) return true;
    return false;
  }

  @override
  bool isUnassigned(Variable variable) {
    return _current.promotionInfo
            ?.get(this, promotionKeyStore.keyForVariable(variable))
            ?.unassigned ??
        true;
  }

  @override
  bool isValidPromotionStep({
    required SharedTypeView previousType,
    required SharedTypeView newType,
  }) {
    // Caller must ensure that `newType <: previousType`.
    assert(
      typeOperations.isSubtypeOf(newType, previousType),
      "Expected $newType to be a subtype of $previousType.",
    );
    if (this.typeAnalyzerOptions.soundFlowAnalysisEnabled) {
      // Promotion to a mutual subtype is not allowed. Since the caller has
      // already ensured that `newType <: previousType`, it's only necessary to
      // check whether `previousType <: newType`.
      return !typeOperations.isSubtypeOf(previousType, newType);
    } else {
      // Repeated promotion to the same type is not allowed.
      return newType != previousType;
    }
  }

  @override
  void labeledStatement_begin(Statement node, {int offset = 0}) {
    _setCurrent(_current.split(), offset: offset);
    _BranchTargetContext context = new _BranchTargetContext(
      _current.reachable.parent!,
    );
    _stack.add(context);
    _statementToContext[node] = context;
  }

  @override
  void labeledStatement_end({int offset = 0}) {
    _BranchTargetContext context = _stack.removeLast() as _BranchTargetContext;
    _setCurrent(_join(_current, context._breakModel).unsplit(), offset: offset);
  }

  @override
  void lateInitializer_begin(Node node, {int offset = 0}) {
    // Late initializers are treated the same as function expressions.
    // Essentially we act as though `late x = expr;` is syntactic sugar for
    // `late x = LAZY_MAGIC(() => expr);` (where `LAZY_MAGIC` creates a lazy
    // evaluation thunk that gets replaced by the result of `expr` once it is
    // evaluated).
    _functionExpression_begin(node, offset: offset);
  }

  @override
  void lateInitializer_end({int offset = 0}) {
    // Late initializers are treated the same as function expressions.
    // Essentially we act as though `late x = expr;` is syntactic sugar for
    // `late x = LAZY_MAGIC(() => expr);` (where `LAZY_MAGIC` creates a lazy
    // evaluation thunk that gets replaced by the result of `expr` once it is
    // evaluated).
    _functionExpression_end(offset: offset);
  }

  @override
  void logicalBinaryOp_begin({int offset = 0}) {
    _setCurrent(_current.split(), offset: offset);
  }

  @override
  ExpressionInfo logicalBinaryOp_end(
    ExpressionInfo? rightOperandInfo, {
    required bool isAnd,
    int offset = 0,
  }) {
    _BranchContext context = _stack.removeLast() as _BranchContext;
    rightOperandInfo ??= _makeTrivialExpressionInfo(boolType);

    FlowModel trueResult;
    FlowModel falseResult;
    if (isAnd) {
      trueResult = rightOperandInfo.ifTrue;
      falseResult = _join(context._branchModel, rightOperandInfo.ifFalse);
    } else {
      trueResult = _join(context._branchModel, rightOperandInfo.ifTrue);
      falseResult = rightOperandInfo.ifFalse;
    }
    _setCurrent(_join(trueResult, falseResult).unsplit(), offset: offset);
    return new ExpressionInfo(
      type: boolType,
      ifTrue: trueResult.unsplit(),
      ifFalse: falseResult.unsplit(),
    );
  }

  @override
  void logicalBinaryOp_rightBegin(
    ExpressionInfo? leftOperandInfo,
    Node wholeExpression, {
    required bool isAnd,
    int offset = 0,
  }) {
    leftOperandInfo ??= _makeTrivialExpressionInfo(boolType);
    ExpressionInfo conditionInfo = leftOperandInfo;
    _stack.add(
      new _BranchContext(isAnd ? conditionInfo.ifFalse : conditionInfo.ifTrue),
    );
    _setCurrent(
      isAnd ? conditionInfo.ifTrue : conditionInfo.ifFalse,
      offset: offset,
    );
  }

  @override
  ExpressionInfo? logicalNot_end(ExpressionInfo? operandInfo) {
    return operandInfo?._invert();
  }

  @override
  void logicalOrPattern_afterLhs({int offset = 0}) {
    _OrPatternContext context = _stack.last as _OrPatternContext;
    // The current flow state represents the state if the left hand side
    // matched.  Save this so that we can later join it with the state if the
    // right hand side matched.
    context._lhsMatched = _current;
    // An attempt to match the right hand side will only be made if the left
    // hand side failed to match, so set the current flow state to the
    // "unmatched" flow state from the left hand side.
    _setCurrent(_unmatched!, offset: offset);
    // And reset `_unmatched` to the value it had prior to visiting the left
    // hand side, so that if the right hand side fails to match, the failure
    // will be accumulated into it.
    _unmatched = context._previousUnmatched;
  }

  @override
  void logicalOrPattern_begin() {
    _PatternContext context = _stack.last as _PatternContext;
    // Save the pieces of the current flow state that will be needed later.
    _stack.add(new _OrPatternContext(context._matchedValueInfo, _unmatched!));
    // Initialize `_unmatched` to a fresh unreachable flow state, so that after
    // we visit the left hand side, `_unmatched` will represent the flow state
    // if the left hand side failed to match.
    _unmatched = _current.setUnreachable();
  }

  @override
  void logicalOrPattern_end({int offset = 0}) {
    _OrPatternContext context = _stack.removeLast() as _OrPatternContext;
    // If either the left hand side or the right hand side matched, the
    // logical-or pattern is considered to have matched.
    _setCurrent(_join(context._lhsMatched, _current), offset: offset);
  }

  @override
  void nonEqualityRelationalPattern_end() {
    // Flow analysis has no way of knowing whether the operator will return
    // `true` or `false`, so just assume the worst case--both cases are
    // reachable and no promotions can be done in either case.
    _unmatched = _join(_unmatched!, _current);
  }

  @override
  void nonNullAssert_end(ExpressionInfo? operandInfo, {int offset = 0}) {
    _Reference? operandReference = _getExpressionReference(operandInfo);
    if (operandReference != null) {
      _setCurrent(
        _current.tryMarkNonNullable(this, operandReference).ifTrue,
        offset: offset,
      );
    }
  }

  @override
  void nullAwareAccess_end({int offset = 0}) {
    _NullAwareAccessContext context =
        _stack.removeLast() as _NullAwareAccessContext;
    _setCurrent(_join(_current, context._previous).unsplit(), offset: offset);
  }

  @override
  ExpressionInfo? nullAwareAccess_rightBegin(
    ExpressionInfo? targetInfo,
    SharedTypeView targetType, {
    Variable? guardVariable,
    int offset = 0,
  }) {
    return _nullAwareAccess_rightBegin(
      targetInfo,
      targetType,
      guardVariable: guardVariable,
      offset: offset,
    );
  }

  @override
  void nullAwareMapEntry_end({required bool isKeyNullAware, int offset = 0}) {
    if (!isKeyNullAware) return;
    _NullAwareMapEntryContext context =
        _stack.removeLast() as _NullAwareMapEntryContext;
    _setCurrent(
      _join(_current, context._shortcutState).unsplit(),
      offset: offset,
    );
  }

  @override
  void nullAwareMapEntry_valueBegin(
    ExpressionInfo? keyInfo,
    SharedTypeView keyType, {
    required bool isKeyNullAware,
    int offset = 0,
  }) {
    if (!isKeyNullAware) return;
    _Reference? keyReference = _getExpressionReference(keyInfo);
    FlowModel shortcutState;
    _setCurrent(_current.split(), offset: offset);
    if (keyReference != null) {
      ExpressionInfo expressionInfo = _current.tryMarkNonNullable(
        this,
        keyReference,
      );
      _setCurrent(expressionInfo.ifTrue, offset: offset);
      shortcutState = expressionInfo.ifFalse;
    } else {
      shortcutState = _current;
    }
    switch (operations.classifyType(keyType)) {
      case TypeClassification.nonNullable:
        // The control flow path that skips the value expression is unreachable.
        shortcutState = shortcutState.setUnreachable();
      case TypeClassification.nullOrEquivalent:
        // The control flow path containing the value expression is unreachable.
        // This functionality was added as part of the `sound-flow-analysis`
        // language feature, even though it would have been a sound reasoning
        // step before then.
        if (typeAnalyzerOptions.soundFlowAnalysisEnabled) {
          _setCurrent(_current.setUnreachable(), offset: offset);
        }
      case TypeClassification.potentiallyNullable:
        // Both control flow paths are reachable.
        break;
    }
    _stack.add(new _NullAwareMapEntryContext(shortcutState));
  }

  @override
  bool nullCheckOrAssertPattern_begin({
    required bool isAssert,
    required SharedTypeView matchedValueType,
    int offset = 0,
  }) {
    if (!isAssert) {
      if (typeAnalyzerOptions.soundFlowAnalysisEnabled &&
          operations.classifyType(matchedValueType) ==
              TypeClassification.nonNullable) {
        // The pattern is guaranteed to match.
      } else {
        // The pattern might not match, either because matchedValueType is
        // nullable, or because sound flow analysis is disabled (in which case
        // we presume the user might be running under an older version of Dart
        // that supported weak null safety mode).
        _unmatched = _join(_unmatched, _current);
      }
    }
    FlowModel? ifNotNull = _nullCheckPattern(
      matchedValueType: matchedValueType,
    );
    if (ifNotNull != null) {
      _setCurrent(ifNotNull, offset: offset);
    }
    // Note: we don't need to push a new pattern context for the subpattern,
    // because (a) the subpattern matches the same value as the outer pattern,
    // and (b) promotion of the synthetic cache variable takes care of
    // establishing the correct matched value type.
    return ifNotNull == null;
  }

  @override
  void nullCheckOrAssertPattern_end() {}

  @override
  ExpressionInfo nullLiteral(SharedTypeView type) {
    return new _NullInfo(model: _current, type: type);
  }

  @override
  ExpressionInfo? parenthesizedExpression(ExpressionInfo? expressionInfo) =>
      expressionInfo;

  @override
  void patternAssignment_beforePattern(
    ExpressionInfo? rhsInfo,
    SharedTypeView rhsType, {
    int offset = 0,
  }) {
    // Considering source code order, the pattern part of a pattern assignment
    // comes before the expression being assigned, but it's visited by flow
    // analysis after. So we need to make an exception to the usual requirement
    // that offsets are strictly increasing.
    _logBuilder?.allowOutOfOrderOffsets();
    _pushPattern(
      _pushScrutinee(
        rhsInfo,
        rhsType,
        allowScrutineePromotion: false,
        offset: offset,
      ),
      offset: offset,
    );
  }

  @override
  void patternAssignment_beforeRhs({int offset = 0}) {
    // Since a pattern assignment is analyzed out of order (RHS first, then
    // LHS), it's necessary to record the current promotion info state to the
    // log before analyzing the RHS. That way, if the pattern changes the flow
    // analysis state, then once the log is sorted by offset, the node that gets
    // recorded now will ensure that the promotion info stored in the log after
    // `offset` correctly matches the current promotion info state.
    _logBuilder?.promotionInfoChanged(_current.promotionInfo, offset: offset);
  }

  @override
  void patternAssignment_end({int offset = 0}) {
    _popPattern(null, offset: offset);
    _popScrutinee();
  }

  @override
  void patternForIn_beforeExpression({int offset = 0}) {
    // Since a pattern for-in is analyzed out of order (iterable expression
    // before pattern), it's necessary to record the current promotion info
    // state to the log before analyzing the iterable expression. That way, if
    // the pattern changes the flow analysis state, then once the log is sorted
    // by offset, the node that gets recorded now will ensure that the promotion
    // info stored in the log after `offset` correctly matches the current
    // promotion info state.
    _logBuilder?.promotionInfoChanged(_current.promotionInfo, offset: offset);
  }

  @override
  void patternForIn_beforePattern(
    SharedTypeView elementType, {
    int offset = 0,
  }) {
    // Considering source code order, the pattern part of a pattern for-in
    // statement (or element) comes before the iterable expression, but it's
    // visited by flow analysis after. So we need to make an exception to the
    // usual requirement that offsets are strictly increasing.
    _logBuilder?.allowOutOfOrderOffsets();
    _pushPattern(
      _pushScrutinee(
        null,
        elementType,
        allowScrutineePromotion: false,
        offset: offset,
      ),
      offset: offset,
    );
  }

  @override
  void patternForIn_end({int offset = 0}) {
    _popPattern(null, offset: offset);
    _popScrutinee();
  }

  @override
  void patternVariableDeclaration_beforeInitializer({int offset = 0}) {
    // Since a pattern variable declaration is analyzed out of order
    // (initializer first, then pattern), it's necessary to record the current
    // promotion info state to the log before analyzing the RHS. That way, if
    // the pattern changes the flow analysis state, then once the log is sorted
    // by offset, the node that gets recorded now will ensure that the promotion
    // info stored in the log after `offset` correctly matches the current
    // promotion info state.
    _logBuilder?.promotionInfoChanged(_current.promotionInfo, offset: offset);
  }

  @override
  void patternVariableDeclaration_beforePattern(
    ExpressionInfo? initializerInfo,
    SharedTypeView initializerType, {
    int offset = 0,
  }) {
    // Considering source code order, the pattern part of a pattern variable
    // declaration comes before the initializer expression, but it's visited by
    // flow analysis after. So we need to make an exception to the usual
    // requirement that offsets are strictly increasing.
    _logBuilder?.allowOutOfOrderOffsets();
    _pushPattern(
      _pushScrutinee(
        initializerInfo,
        initializerType,
        allowScrutineePromotion: false,
        offset: offset,
      ),
      offset: offset,
    );
  }

  @override
  void patternVariableDeclaration_end({int offset = 0}) {
    _popPattern(null, offset: offset);
    _popScrutinee();
  }

  @override
  void popPropertySubpattern() {
    _PropertyPatternContext context =
        _stack.removeLast() as _PropertyPatternContext;
    _scrutineeReference = context._previousScrutinee;
  }

  @override
  void popSubpattern() {
    _FlowContext context = _stack.removeLast();
    assert(context is _PatternContext);
  }

  @override
  void postIncDec(
    Node node,
    Variable variable,
    SharedTypeView writtenType, {
    int offset = 0,
  }) {
    _write(
      node,
      variable,
      writtenType,
      null,
      isPostfixIncDec: true,
      offset: offset,
    );
  }

  @override
  SharedTypeView? promotedPropertyType(
    PropertyTarget<Expression> target,
    String propertyName,
    Object? propertyMember,
    SharedTypeView unpromotedType,
  ) {
    SsaNode? targetSsaNode = target._getSsaNode(this);
    if (targetSsaNode == null) return null;
    var (SharedTypeView? type, _) = _handleProperty(
      targetSsaNode,
      propertyName,
      propertyMember,
      unpromotedType,
    );
    return type;
  }

  @override
  SharedTypeView? promotedType(Variable variable) {
    return _current.promotionInfo
        ?.get(this, promotionKeyStore.keyForVariable(variable))
        ?.promotedTypes
        .lastOrNull;
  }

  @override
  bool promoteForPattern({
    required SharedTypeView matchedType,
    required SharedTypeView knownType,
    bool matchFailsIfWrongType = true,
    bool matchMayFailEvenIfCorrectType = false,
    int offset = 0,
  }) {
    if (knownType is SharedInvalidType) {
      _unmatched = _join(_unmatched!, _current);
      return false;
    }

    bool cannotMatch = false;
    switch (operations.classifyType(matchedType)) {
      case TypeClassification.nonNullable:
        if (typeAnalyzerOptions.soundFlowAnalysisEnabled &&
            operations.classifyType(knownType) ==
                TypeClassification.nullOrEquivalent) {
          // `Null()` cannot match a non-nullable matched value, assuming sound
          // null safety.
          cannotMatch = true;
        }
        // The matched type is non-nullable, so promote to a non-nullable type.
        // This allows for code like `case int? x?` to promote `x` to
        // non-nullable.
        knownType = operations.promoteToNonNull(knownType);
      case TypeClassification.nullOrEquivalent:
        if (typeAnalyzerOptions.soundFlowAnalysisEnabled &&
            operations.classifyType(knownType) ==
                TypeClassification.nonNullable) {
          // If `T` is a non-nullable type, `T()` cannot match a matched value
          // of type `Null`. This reasoning step is sound regardless of whether
          // sound null safety, but it is a new reasoning step that was added to
          // flow analysis as part of the `sound-flow-analysis` feature.
          cannotMatch = true;
        }
      case TypeClassification.potentiallyNullable:
        // No conclusions can be drawn about `cannotMatch` or `knownType`.
        break;
    }
    _PatternContext context = _stack.last as _PatternContext;
    _Reference matchedValueReference = context.createReference(
      matchedType,
      _current,
    );
    bool coversMatchedType = operations.isSubtypeOf(
      operations.extensionTypeErasure(matchedType),
      operations.extensionTypeErasure(knownType),
    );
    // Promote the synthetic cache variable the pattern is being matched
    // against.
    ExpressionInfo promotionInfo = _current.tryPromoteForTypeCheck(
      this,
      matchedValueReference,
      knownType,
    );
    FlowModel ifTrue = promotionInfo.ifTrue;
    FlowModel ifFalse = promotionInfo.ifFalse;
    _Reference? scrutineeReference = _scrutineeReference;
    // If the scrutinee is a variable reference, and the variable hasn't changed
    // since the start of the matching operation, promote it too.
    //
    // If the scrutinee is a property reference, promote it too. (This is safe
    // even if the underlying variable whose property is being referenced has
    // changed, because the next time the property is accessed, it will be
    // accessed through a new SSA node, and thus a new promotion key).
    //
    // If the scrutinee is `this`, promote it too.
    if (scrutineeReference != null &&
        (scrutineeReference is _PropertyReference ||
            (scrutineeReference.isThisOrSuper &&
                typeAnalyzerOptions.thisPromotionEnabled) ||
            _current.promotionInfo
                    ?.get(this, matchedValueReference.promotionKey)!
                    .ssaNode ==
                _current.promotionInfo
                    ?.get(this, scrutineeReference.promotionKey)
                    ?.ssaNode)) {
      ifTrue = ifTrue
          .tryPromoteForTypeCheck(this, scrutineeReference, knownType)
          .ifTrue;
      ifFalse = ifFalse
          .tryPromoteForTypeCheck(this, scrutineeReference, knownType)
          .ifFalse;
    }
    FlowModel newState = ifTrue;
    if (cannotMatch) {
      newState = newState.setUnreachable();
    }
    _setCurrent(newState, offset: offset);
    if (matchFailsIfWrongType && !coversMatchedType) {
      // There's a reachable control flow path where the match might fail due to
      // a type mismatch. Therefore, we must update the `_unmatched` flow state
      // based on the state of flow analysis assuming the type check failed.
      _unmatched = _join(_unmatched!, ifFalse);
    }
    if (matchMayFailEvenIfCorrectType) {
      // There's a reachable control flow path where the type might match, but
      // the match might nonetheless fail for some other reason. Therefore, we
      // must update the `_unmatched` flow state based on the state of flow
      // analysis assuming the type check succeeded.
      _unmatched = _join(_unmatched!, ifTrue);
    }
    return coversMatchedType;
  }

  @override
  (SharedTypeView?, ExpressionInfo?) propertyGet(
    PropertyTarget<Expression> target,
    String propertyName,
    Object? propertyMember,
    SharedTypeView unpromotedType,
  ) {
    SsaNode? targetSsaNode = target._getSsaNode(this);
    if (targetSsaNode == null) return (null, null);
    var (
      SharedTypeView? promotedType,
      _PropertySsaNode propertySsaNode,
    ) = _handleProperty(
      targetSsaNode,
      propertyName,
      propertyMember,
      unpromotedType,
    );
    _PropertyReference propertyReference = new _PropertyReference(
      propertyName: propertyName,
      propertyMember: propertyMember,
      promotionKey: propertySsaNode.promotionKey,
      model: _current,
      type: promotedType ?? unpromotedType,
      ssaNode: propertySsaNode,
    );
    return (promotedType, propertyReference);
  }

  @override
  List<SharedTypeView> propertyPromotionChainForTesting(
    PropertyTarget<Expression> target,
    String propertyName,
    Object? propertyMember,
  ) {
    SsaNode? targetSsaNode = target._getSsaNode(this);
    if (targetSsaNode == null) return const [];
    // Find the SSA node for the target of the property access, and figure out
    // whether the property in question is promotable.
    bool isPromotable =
        propertyMember != null &&
        typeAnalyzerOptions.fieldPromotionEnabled &&
        operations.isPropertyPromotable(propertyMember);
    if (!isPromotable) return const [];
    _PropertySsaNode propertySsaNode = targetSsaNode.getOrCreatePropertyNode(
      propertyName,
      promotionKeyStore,
      isPromotable: isPromotable,
    );
    PromotionModel? promotionInfo = _current.promotionInfo?.get(
      this,
      propertySsaNode.promotionKey,
    );
    if (promotionInfo == null) return const [];
    assert(promotionInfo.ssaNode == propertySsaNode);
    return promotionInfo.promotedTypes;
  }

  @override
  SharedTypeView? pushPropertySubpattern(
    String propertyName,
    Object? propertyMember,
    SharedTypeView unpromotedType, {
    int offset = 0,
  }) {
    _PatternContext context = _stack.last as _PatternContext;
    assert(_unmatched != null);
    var (
      SharedTypeView? promotedType,
      _PropertySsaNode? propertySsaNode,
    ) = _handleProperty(
      context._matchedValueInfo.ssaNode,
      propertyName,
      propertyMember,
      unpromotedType,
    );
    _PropertyReference propertyReference = new _PropertyReference(
      propertyName: propertyName,
      propertyMember: propertyMember,
      promotionKey: propertySsaNode.promotionKey,
      model: _current,
      type: promotedType ?? unpromotedType,
      ssaNode: propertySsaNode,
    );
    _stack.add(
      new _PropertyPatternContext(
        _makeTemporaryReference(
          propertySsaNode,
          promotedType ?? unpromotedType,
          offset: offset,
        ),
        _scrutineeReference,
      ),
    );
    _scrutineeReference = propertyReference;
    return promotedType;
  }

  @override
  void pushSubpattern(SharedTypeView matchedType, {int offset = 0}) {
    assert(_stack.last is _PatternContext);
    assert(_unmatched != null);
    _stack.add(
      new _PatternContext(
        _makeTemporaryReference(new SsaNode(), matchedType, offset: offset),
      ),
    );
  }

  @override
  SsaNode? ssaNodeForTesting(Variable variable) => _current.promotionInfo
      ?.get(this, promotionKeyStore.keyForVariable(variable))
      ?.ssaNode;

  @override
  void suspension(Node node, {int offset = 0}) {
    // During an async suspension or yield, other code may execute. If the
    // current point in flow control is inside a local function, this means that
    // enclosing functions may resume executing.
    //
    // Therefore, any variables that are read within the current local function,
    // and written to anywhere, but not declared in the current local function,
    // might potentially get written to, blowing away any promotions that are
    // currently in effect.
    if (_enclosingFunctionExpressionInfoStack case [..., var info]) {
      Set<int> variablesToDemote = info.read
          .intersection(_assignedVariables.anywhere.written)
          .difference(info.declared);
      _setCurrent(
        _current.conservativeJoin(
          this,
          variablesToDemote,
          const [],
          getNonPromotionReason: (variableKey) {
            Variable? variable = promotionKeyStore.variableForKey(variableKey);
            // `variableKey` should be one of the keys in `variableToDemote`;
            // those keys in turn should always correspond to actual variables
            // declared by the user. So `variable` should never be `null`.
            assert(variablesToDemote.contains(variableKey));
            return new DemoteViaSuspension<Variable, Node>(variable!, node);
          },
        ),
        offset: offset,
      );
    }
  }

  @override
  bool switch_afterCase({int offset = 0}) {
    _SwitchContext context = _stack.last as _SwitchContext;
    bool isLocallyReachable = _current.reachable.locallyReachable;
    _setCurrent(_current.unsplit(), offset: offset);
    if (isLocallyReachable) {
      context._breakModel = _join(context._breakModel, _current);
    }
    return isLocallyReachable;
  }

  @override
  void switch_beginAlternative({int offset = 0}) {
    _SwitchAlternativesContext<Variable> context =
        _stack.last as _SwitchAlternativesContext<Variable>;
    _setCurrent(context._switchContext._unmatched, offset: offset);
    _pushPattern(context._switchContext._matchedValueInfo, offset: offset);
  }

  @override
  void switch_beginAlternatives() {
    _SwitchContext context = _stack.last as _SwitchContext;
    _stack.add(new _SwitchAlternativesContext<Variable>(context));
  }

  @override
  bool switch_end(bool isExhaustive, {int offset = 0}) {
    _SwitchContext context = _stack.removeLast() as _SwitchContext;
    bool isProvenExhaustive = !context._unmatched.reachable.locallyReachable;
    FlowModel? breakState = context._breakModel;

    // If there is an implicit fall-through default, join it to any breaks.
    if (!isExhaustive) breakState = _join(breakState, context._unmatched);

    // If there were no breaks (neither implicit nor explicit), then
    // `breakState` will be `null`.  This means this is an empty switch
    // statement and the type of the scrutinee is an exhaustive type.  This
    // could happen, for instance, if the scrutinee type is an abstract sealed
    // class that has no subclasses.  It makes the most sense to treat the code
    // after the switch as unreachable, because that's the normal behavior of a
    // switch over an exhaustive type with no `break`s.  It is sound to do so
    // because the type is uninhabited, therefore the body of the switch
    // statement itself will never be reached.
    breakState ??= context._previous.setUnreachable();

    _setCurrent(breakState.unsplit(), offset: offset);
    _popScrutinee();
    return isProvenExhaustive;
  }

  @override
  void switch_endAlternative(
    ExpressionInfo? guardInfo,
    Map<String, Variable> variables, {
    int offset = 0,
  }) {
    FlowModel unmatched = _popPattern(guardInfo, offset: offset);
    _SwitchAlternativesContext<Variable> context =
        _stack.last as _SwitchAlternativesContext<Variable>;
    // Future alternatives will be analyzed under the assumption that this
    // alternative didn't match.  This models the fact that a switch statement
    // behaves like a chain of if/else tests.
    context._switchContext._unmatched = unmatched;

    PatternVariableInfo<Variable> patternVariableInfo =
        context._patternVariableInfo;
    for (MapEntry<String, Variable> entry in variables.entries) {
      String variableName = entry.key;
      Variable variable = entry.value;
      (patternVariableInfo.componentVariables[variableName] ??= []).add(
        variable,
      );
      int promotionKey = promotionKeyStore.keyForVariable(variable);
      // See if this variable appeared in any previous patterns that share the
      // same case body.
      int? previousPromotionKey =
          patternVariableInfo.patternVariablePromotionKeys[variableName];
      if (previousPromotionKey == null) {
        // This variable hasn't been seen in any previous patterns that share
        // the same body.  So we can safely use the promotion key we have to
        // store information about this variable.
        patternVariableInfo.patternVariablePromotionKeys[variableName] =
            promotionKey;
      } else {
        // This variable has been seen in previous patterns, so we have to
        // copy promotion data into the previously-used promotion key, to
        // ensure that the promotion information is properly joined.
        copyPromotionData(
          sourceKey: promotionKey,
          destinationKey: previousPromotionKey,
          offset: offset,
        );
      }
    }
    context._combinedModel = _join(context._combinedModel, _current);
  }

  @override
  PatternVariableInfo<Variable> switch_endAlternatives(
    Statement? node, {
    required bool hasLabels,
    int offset = 0,
  }) {
    _SwitchAlternativesContext<Variable> alternativesContext =
        _stack.removeLast() as _SwitchAlternativesContext<Variable>;
    _SwitchContext switchContext = _stack.last as _SwitchContext;
    if (hasLabels) {
      AssignedVariablesNodeInfo info = _assignedVariables.getInfoForNode(node!);
      _setCurrent(
        switchContext._previous.conservativeJoin(
          this,
          info.written,
          info.captured,
        ),
        offset: offset,
      );
    } else {
      _setCurrent(
        alternativesContext._combinedModel ?? switchContext._unmatched,
        offset: offset,
      );
    }
    // Do a control flow split so that in switch_afterCase, we'll be
    // able to tell whether the end of the case body was reachable from its
    // start.
    _setCurrent(_current.split(), offset: offset);
    return alternativesContext._patternVariableInfo;
  }

  @override
  void switch_scrutineeEnd(
    Statement? switchStatement,
    ExpressionInfo? scrutineeInfo,
    SharedTypeView scrutineeType, {
    int offset = 0,
  }) {
    _Reference matchedValueInfo = _pushScrutinee(
      scrutineeInfo,
      scrutineeType,
      allowScrutineePromotion: true,
      offset: offset,
    );
    _setCurrent(_current.split(), offset: offset);
    _SwitchContext context = new _SwitchContext(
      _current.reachable.parent!,
      _current,
      matchedValueInfo,
    );
    _stack.add(context);
    if (switchStatement != null) {
      _statementToContext[switchStatement] = context;
    }
  }

  @override
  void thisBinding_begin(ExpressionInfo? targetInfo, {int offset = 0}) {
    _Reference? expressionReference = _getExpressionReference(targetInfo);
    SsaNode ssaNode =
        expressionReference?.ssaNode ??
        new SsaNode(
          conditionVariableState: targetInfo != null && targetInfo.isNonTrivial
              ? targetInfo
              : null,
        );
    _thisSsaNodes.add(ssaNode);
    int thisPromotionKey = promotionKeyStore.makeTemporaryKey();
    _thisPromotionKeys.add(thisPromotionKey);
    _logBuilder?.thisBindingChanged(thisPromotionKey, offset: offset);
  }

  @override
  void thisBinding_end({int offset = 0}) {
    _thisSsaNodes.removeLast();
    _thisPromotionKeys.removeLast();
    _logBuilder?.thisBindingChanged(_thisPromotionKeys.last, offset: offset);
  }

  @override
  ExpressionInfo thisOrSuper(
    SharedTypeView staticType, {
    required bool isSuper,
  }) {
    return _thisOrSuperReference(staticType, isSuper: isSuper);
  }

  @override
  void tryCatchStatement_bodyBegin({int offset = 0}) {
    _setCurrent(_current.split(), offset: offset);
    _stack.add(new _TryContext(_current));
  }

  @override
  void tryCatchStatement_bodyEnd(Node body) {
    FlowModel afterBody = _current;

    _TryContext context = _stack.last as _TryContext;
    FlowModel beforeBody = context._previous;

    AssignedVariablesNodeInfo info = _assignedVariables.getInfoForNode(body);
    FlowModel beforeCatch = beforeBody.conservativeJoin(
      this,
      info.written,
      info.captured,
    );

    context._beforeCatch = beforeCatch;
    context._afterBodyAndCatches = afterBody;
  }

  @override
  void tryCatchStatement_catchBegin(
    Variable? exceptionVariable,
    Variable? stackTraceVariable, {
    int offset = 0,
  }) {
    _TryContext context = _stack.last as _TryContext;
    FlowModel current = context._beforeCatch!;
    if (exceptionVariable != null) {
      int exceptionVariableKey = promotionKeyStore.keyForVariable(
        exceptionVariable,
      );
      current = current.declare(this, exceptionVariableKey, true);
    }
    if (stackTraceVariable != null) {
      int stackTraceVariableKey = promotionKeyStore.keyForVariable(
        stackTraceVariable,
      );
      current = current.declare(this, stackTraceVariableKey, true);
    }
    _setCurrent(current, offset: offset);
  }

  @override
  void tryCatchStatement_catchEnd() {
    _TryContext context = _stack.last as _TryContext;
    context._afterBodyAndCatches = _join(
      context._afterBodyAndCatches,
      _current,
    );
  }

  @override
  void tryCatchStatement_end({int offset = 0}) {
    _TryContext context = _stack.removeLast() as _TryContext;
    _setCurrent(context._afterBodyAndCatches!.unsplit(), offset: offset);
  }

  @override
  void tryFinallyStatement_bodyBegin() {
    _stack.add(new _TryFinallyContext(_current));
  }

  @override
  void tryFinallyStatement_end({int offset = 0}) {
    // See the "try finally" bullet in
    // https://github.com/dart-lang/language/blob/main/resources/type-system/flow-analysis.md#statements.

    var _TryFinallyContext(
      _beforeTry: beforeTry,
      _afterTry: afterTry!,
      _beforeFinally: beforeFinally!,
    ) = _stack.removeLast() as _TryFinallyContext;
    FlowModel afterFinally = _current;

    // (OPTIMIZATION: the computation of `attachFinally` may be skipped in two
    // circumstances:
    // - If `before(B2)` and `after(B2)` are identical flow models (meaning
    //   nothing of consequence to flow analysis occurred in `B2`), then
    //   `after(N) = after(B1)`.
    if (beforeFinally == afterFinally) {
      _setCurrent(afterTry, offset: offset);
      return;
    }
    // - If `before(B1)`, `after(B1)`, and `before(B2)` are identical flow
    //   models (meaning nothing of consequence to flow analysis happened in
    //   `B1`), then `after(N) = after(B2)`.)
    if (beforeFinally == beforeTry && beforeTry == afterTry) {
      _setCurrent(afterFinally, offset: offset);
      return;
    }

    // - Let `after(N) = attachFinally(after(B1), before(B2), after(B2))`.
    _setCurrent(
      _attachFinally(
        afterTry: afterTry,
        beforeFinally: beforeFinally,
        afterFinally: afterFinally,
      ),
      offset: offset,
    );
  }

  @override
  void tryFinallyStatement_finallyBegin(Node body, {int offset = 0}) {
    AssignedVariablesNodeInfo info = _assignedVariables.getInfoForNode(body);
    _TryFinallyContext context = _stack.last as _TryFinallyContext;
    context._afterTry = _current;
    _setCurrent(
      _join(
        _current,
        context._beforeTry.conservativeJoin(this, info.written, info.captured),
      ),
      offset: offset,
    );
    context._beforeFinally = _current;
  }

  @override
  List<SharedTypeView> variablePromotionChainForTesting(Variable variable) =>
      _current.promotionInfo
          ?.get(this, promotionKeyStore.keyForVariable(variable))
          ?.promotedTypes ??
      const [];

  @override
  (SharedTypeView?, ExpressionInfo) variableRead(
    Variable variable, {
    int offset = 0,
  }) {
    SharedTypeView unpromotedType = operations.variableType(variable);
    int variableKey = promotionKeyStore.keyForVariable(variable);
    PromotionModel? promotionModel = _current.promotionInfo?.get(
      this,
      variableKey,
    );
    if (promotionModel == null) {
      promotionModel = new PromotionModel.fresh(ssaNode: new SsaNode());
      _setCurrent(
        _current.updatePromotionInfo(this, variableKey, promotionModel),
        offset: offset,
      );
    }
    _Reference expressionInfo = _variableReference(variableKey, unpromotedType)
        .restoreConditionVariableState(
          promotionModel.ssaNode?.conditionVariableState,
          this,
          _current,
        );
    return (promotionModel.promotedTypes.lastOrNull, expressionInfo);
  }

  @override
  void whileStatement_bodyBegin(
    Statement whileStatement,
    ExpressionInfo? conditionInfo, {
    int offset = 0,
  }) {
    conditionInfo ??= _makeTrivialExpressionInfo(boolType);
    _WhileContext context = new _WhileContext(
      _current.reachable.parent!,
      conditionInfo.ifFalse,
    );
    _stack.add(context);
    _statementToContext[whileStatement] = context;
    _setCurrent(conditionInfo.ifTrue, offset: offset);
  }

  @override
  void whileStatement_conditionBegin(Node node, {int offset = 0}) {
    AssignedVariablesNodeInfo info = _assignedVariables.getInfoForNode(node);
    _setCurrent(
      _current.split().conservativeJoin(this, info.written, info.captured),
      offset: offset,
    );
  }

  @override
  void whileStatement_end({int offset = 0}) {
    _WhileContext context = _stack.removeLast() as _WhileContext;
    _setCurrent(
      _join(
        context._conditionFalse,
        context._breakModel,
      ).unsplit().inheritTested(this, _current),
      offset: offset,
    );
  }

  @override
  Map<SharedTypeView, NonPromotionReason> Function() whyNotPromoted(
    ExpressionInfo? targetInfo,
  ) {
    if (targetInfo case _Reference reference) {
      PromotionModel? currentPromotionInfo = _current.promotionInfo?.get(
        this,
        reference.promotionKey,
      );
      return _getNonPromotionReasons(reference, currentPromotionInfo);
    } else {
      return () => {};
    }
  }

  @override
  Map<SharedTypeView, NonPromotionReason> Function() whyNotPromotedImplicitThis(
    SharedTypeView staticType,
  ) {
    if (typeAnalyzerOptions.thisPromotionEnabled) {
      return () => {};
    }
    PromotionModel? currentThisInfo = _current.promotionInfo?.get(
      this,
      _thisPromotionKeys.last,
    );
    if (currentThisInfo == null) {
      return () => {};
    }
    return _getNonPromotionReasons(
      _thisOrSuperReference(staticType, isSuper: false),
      currentThisInfo,
    );
  }

  @override
  ExpressionInfo? write(
    Node node,
    Variable variable,
    SharedTypeView writtenType,
    ExpressionInfo? writtenExpressionInfo, {
    int offset = 0,
  }) {
    return _write(
      node,
      variable,
      writtenType,
      writtenExpressionInfo,
      offset: offset,
    );
  }

  /// Computes a [FlowModel] representing the state of execution after the
  /// statement `try B1 finally B2`.
  ///
  /// [afterTry] is the flow models from `B1` after the `try` block (`B1`).
  ///
  /// [beforeFinally] and [afterFinally] are the flow models from before and
  /// after the `finally` block (`B2`), respectively.
  FlowModel _attachFinally({
    required FlowModel afterTry,
    required FlowModel beforeFinally,
    required FlowModel afterFinally,
  }) {
    // See the `attachFinally` function in
    // https://github.com/dart-lang/language/blob/main/resources/type-system/flow-analysis.md#models.

    // Let `afterTry = FlowModel(r1, VI1)`,
    // `beforeFinally = FlowModel(r2, VI2)`, and
    // `afterFinally = FlowModel(r3, VI3)`.
    var FlowModel(reachable: r1, promotionInfo: VI1) = afterTry;
    var FlowModel(promotionInfo: VI2) = beforeFinally;
    var FlowModel(reachable: r3, promotionInfo: VI3) = afterFinally;

    // Let `r4` be defined as follows:
    // - If `top(r3)` is `true`, then let `r4 = r1`.
    // - Otherwise, let `r4 = unreachable(r1)`.
    assert(identical(r1.parent, r3.parent));
    Reachability r4 = r3.locallyReachable ? r1 : r1.setUnreachable();

    // Let `VI4` be the map which maps each variable `v` in the domain of either
    // `VI1` or `VI3` as follows (OPTIMIZATION: we implement this by using
    // `afterTry` as a starting point, and iterating through the promotion keys
    // that differ between `VI1` and `VI3`):
    FlowModel result = afterTry.setReachability(r4);
    List<({SsaNode from, SsaNode to})> fieldPromotionsToReapply = [];
    for (var FlowLinkDiffEntry(
          key: int promotionKey,
          :PromotionInfo? left,
          :PromotionInfo? right,
        )
        in reader.diff(VI1, VI3).entries) {
      PromotionModel? v1 = left?.model;
      PromotionModel? v3 = right?.model;

      // - If `v` is in the domain of `VI1` but not `VI3`, then
      //   `VI4(v) = VI1(v)`.
      if (v3 == null) {
        if (v1 == null) {
          // This should never happen, because we are iterating through
          // promotion keys that are different between the `afterTry` and
          // `afterFinally` models.
          assert(false);
        } else {
          result = result.updatePromotionInfo(this, promotionKey, v1);
        }
        continue;
      }

      // - If `v` is in the domain of `VI3` but not `VI1`, then
      //   `VI4(v) = VI3(v)`.
      if (v1 == null) {
        // Spec: If `v` is in the domain of `VI3` but not `VI1`, then `VI4(v) =
        // VI3(v)`.
        result = result.updatePromotionInfo(this, promotionKey, v3);
        continue;
      }

      // - If `v` is in the domain of both `VI1` and `VI3`, then
      //   `VI4(v) = attachFinallyV(VI1(v), VI2(v), VI3(v))`. Note that if `v`
      //   is in the domain of both `VI1` and `VI3`, it must have been declared
      //   before the `try-finally` statement, therefore it must also be in the
      //   domain of `VI2`.
      //   (UNSPECIFIED: however, field promotion breaks this, because there
      //   could be a field that's accessed, and promoted, in both the `try` and
      //   `finally` blocks, but not accessed before the `try-finally`
      //   statement, and in that case its promotion key would appear in `VI1`
      //   and `VI3` but not `VI2`.)
      PromotionModel? v2 = VI2?.get(this, promotionKey);

      PromotionModel newModel = _attachFinallyV(
        afterTry: v1,
        beforeFinally: v2,
        afterFinally: v3,
        fieldPromotionsToReapply: fieldPromotionsToReapply,
      );
      result = result.updatePromotionInfo(this, promotionKey, newModel);
    }

    // (UNSPECIFIED: if any variable was written in the try block but not the
    // finally block, then it has a different SSA node now than it had in the
    // finally block. Hence, if any fields of that variable were promoted in the
    // finally block, those field promotions need to be reapplied to the new SSA
    // node for the variable.)
    for (var (from: SsaNode? from, to: SsaNode? to)
        in fieldPromotionsToReapply) {
      result = to._applyPropertyPromotions(
        this,
        to,
        from,
        beforeFinally.promotionInfo,
        afterFinally.promotionInfo,
        result,
      );
    }
    return result;
  }

  PromotionModel _attachFinallyV({
    required PromotionModel afterTry,
    required PromotionModel? beforeFinally,
    required PromotionModel afterFinally,
    required List<({SsaNode from, SsaNode to})> fieldPromotionsToReapply,
  }) {
    // See the `attachFinally` function in
    // https://github.com/dart-lang/language/blob/main/resources/type-system/flow-analysis.md#models.

    // (UNSPECIFIED: the spec is inconsistent about how it refers to the
    // "tested" booleans. Sometimes it uses `s1`, `s2`, and `s3`, and other
    // times `t1`, `t2`, and `t3`. `t1`, `t2`, and `t3` is better.)

    // Let `afterTry = VariableModel(d1, p1, t1, a1, u1, c1)`.
    // (UNSPECIFIED: and we denote the SSA node of the variable in `afterTry` as
    // `v1`, since the plan is to rename "SSA node" to "version").
    var PromotionModel(promotedTypes: p1, assigned: a1, ssaNode: v1) = afterTry;
    // Let `beforeFinally = VariableModel(d2, p2, t2, a2, u2, c2)`.
    // (UNSPECIFIED: beforeFinally may be `null` when fields are promoted, so
    // we can't use pattern syntax to deconstruct this. Instead we deconstruct
    // it after null checking `beforeFinally`, below.)
    // Let `afterFinally = VariableModel(d3, p3, t3, a3, u3, c3)`.
    // (UNSPECIFIED: and we denote the SSA node of the variable in
    // `afterFinally` as `v3`, since the plan is to rename "SSA node" to
    // "version").
    var PromotionModel(
      promotedTypes: p3,
      tested: t3,
      assigned: a3,
      unassigned: u3,
      ssaNode: v3,
    ) = afterFinally;

    // Let `d4 = d3`.
    // (OPTIMIZATION: flow analysis doesn't store the declared types of
    // variables, so we don't need to do anything here.)

    // Let `p4` be determined as follows:
    List<SharedTypeView> p4;
    // (UNSPECIFIED: and also let `v4`, the SSA node after the `try-finally`
    // statement, be determined as follows.)
    SsaNode? v4;
    // - If the variable's value might have been changed by the `finally`
    //   block, then `p4 = p3`.
    // (UNSPECIFIED: a necessary and sufficient check for whether the variable
    // might have been changed by the `finally` block is to see if (a) the
    // variable was write captured at some point before the conclusion of the
    // `finally` block (this is represented using a `null` SSA node), or (b) the
    // variable's SSA node after the `finally` block is different from its SSA
    // node before the `finally` block.)
    bool variableWasWriteCaptured = v3 == null;
    bool variableMightHaveChanged =
        variableWasWriteCaptured ||
        (beforeFinally != null && beforeFinally.ssaNode != v3);
    if (variableMightHaveChanged) {
      p4 = p3;
      // (UNSPECIFIED: and the SSA node after the `try-finally` statement is the
      // SSA node after the `finally` block.)
      v4 = v3;
    } else {
      // UNSPECIFIED: the variable must not have been write captured, so its SSA
      // node can't be `null`.
      v1!;
      // - Otherwise, `p4 = rebasePromotedTypes(p1, p3)`.
      p4 = typeAnalyzerOptions.soundFlowAnalysisEnabled
          ? PromotionModel.rebasePromotedTypes(
              basePromotions: p1,
              newPromotions: p3,
              helper: this,
            )
          :
            // (UNSPECIFIED: reproduce old buggy behavior prior to the fix for
            // https://github.com/dart-lang/language/issues/4382.)
            PromotionModel.rebasePromotedTypes(
              basePromotions: p3,
              newPromotions: p1,
              helper: this,
            );
      // (UNSPECIFIED: and the SSA node after the `try-finally` statement is the
      // SSA node after the `try` block.)
      v4 = v1;
      if (v4 != v3) {
        // (UNSPECIFIED: if the `try` block wrote to the variable, any field
        // promotions that were applied in the `finally` block should be
        // reapplied to the new SSA node for the variable.)
        fieldPromotionsToReapply.add((from: v3, to: v4));
      }
    }
    // Let `t4 = t3`.
    List<SharedTypeView> t4 = t3;
    // Let `a4 = a1 || a3`.
    bool a4 = a1 || a3;
    // Let `u4 = u3`.
    bool u4 = u3;
    // Let `c4 = c3`.
    // (OPTIMIZATION: write-captured variables are represented using a `null`
    // SSA node. So this is handled implicitly: if the variable was write
    // captured at some point before the conclusion of the `finally` block, then
    // `v3` is `null` and `variableMightHaveChanged` is `true`, therefore `v4`
    // was set to `v3` above, and hence `v4` is `null`.)
    PromotionModel newModel = PromotionModel._identicalOrNew(
      afterTry,
      afterFinally,
      p4,
      t4,
      a4,
      u4,
      v4,
    );
    return newModel;
  }

  @override
  void _dumpState() {
    print('  current: $_current');
    if (_unmatched != null) {
      print('  unmatched: $_unmatched');
    }
    if (_scrutineeReference != null) {
      print('  scrutineeReference: $_scrutineeReference');
    }
    if (_stack.isNotEmpty) {
      print('  stack:');
      for (_FlowContext stackEntry in _stack.reversed) {
        print('    $stackEntry');
      }
    }
  }

  /// Analyzes an equality check between the operands described by
  /// [lhsInfo] and [rhsInfo], having static types [lhsType] and [rhsType].
  _EqualityCheckResult _equalityCheck(
    ExpressionInfo? lhsInfo,
    SharedTypeView lhsType,
    ExpressionInfo? rhsInfo,
    SharedTypeView rhsType,
  ) {
    TypeClassification leftOperandTypeClassification = operations.classifyType(
      lhsType,
    );
    TypeClassification rightOperandTypeClassification = operations.classifyType(
      rhsType,
    );
    if (leftOperandTypeClassification == TypeClassification.nullOrEquivalent &&
        rightOperandTypeClassification == TypeClassification.nullOrEquivalent) {
      return const _GuaranteedEqual();
    } else if ((leftOperandTypeClassification ==
                TypeClassification.nullOrEquivalent &&
            rightOperandTypeClassification == TypeClassification.nonNullable) ||
        (rightOperandTypeClassification ==
                TypeClassification.nullOrEquivalent &&
            leftOperandTypeClassification == TypeClassification.nonNullable)) {
      // In strong mode the test is guaranteed to produce a "not equal" result,
      // but weak mode it might produce an "equal" result. If sound flow
      // analysis is enabled, we assume that the user isn't running in weak mode
      // and so we propagate the known "not equal" result. Otherwise, we
      // conservatively assume that either result is possible.
      if (typeAnalyzerOptions.soundFlowAnalysisEnabled) {
        return const _GuaranteedNotEqual();
      } else {
        return const _NoEqualityInformation();
      }
    } else if (lhsInfo != null && lhsInfo.isNull) {
      return new _EqualityCheckIsNullCheck(
        rhsInfo is _Reference ? rhsInfo : null,
        isReferenceOnRight: true,
      );
    } else if (rhsInfo != null && rhsInfo.isNull) {
      return new _EqualityCheckIsNullCheck(
        lhsInfo is _Reference ? lhsInfo : null,
        isReferenceOnRight: false,
      );
    } else {
      return const _NoEqualityInformation();
    }
  }

  void _functionExpression_begin(Node node, {required int offset}) {
    AssignedVariablesNodeInfo info = _assignedVariables.getInfoForNode(node);
    _enclosingFunctionExpressionInfoStack.add(info);
    FlowModel current = _current.conservativeJoin(this, const [], info.written);
    _stack.add(new _FunctionExpressionContext(current, _anonymousBlockContext));
    _anonymousBlockContext = null;
    _setCurrent(
      current.conservativeJoin(
        this,
        _assignedVariables.anywhere.written,
        _assignedVariables.anywhere.captured,
      ),
      offset: offset,
    );
  }

  void _functionExpression_end({required int offset}) {
    _FunctionExpressionContext context =
        _stack.removeLast() as _FunctionExpressionContext;
    _enclosingFunctionExpressionInfoStack.removeLast();
    _setCurrent(context._previous, offset: offset);
    _anonymousBlockContext = context._previousAnonymousBlockContext;
  }

  /// Gets the matched value type that should be used to type check the pattern
  /// currently being analyzed.
  ///
  /// May only be called in the context of a pattern.
  SharedTypeView _getMatchedValueType() {
    _PatternContext context = _stack.last as _PatternContext;
    return _current.promotionInfo
            ?.get(this, context._matchedValueInfo.promotionKey)
            ?.promotedTypes
            .lastOrNull ??
        context._matchedValueInfo._type;
  }

  Map<SharedTypeView, NonPromotionReason> Function() _getNonPromotionReasons(
    _Reference reference,
    PromotionModel? currentPromotionInfo,
  ) {
    if (reference is _PropertyReference) {
      Object? propertyMember = reference.propertyMember;
      if (propertyMember != null) {
        PropertyNonPromotabilityReason? whyNotPromotable =
            reference.propertyName.startsWith('_')
            ? operations.whyPropertyIsNotPromotable(propertyMember)
            : PropertyNonPromotabilityReason.isNotPrivate;
        _PropertySsaNode? ssaNode =
            (reference.ssaNode as _PropertySsaNode).previousSsaNode;
        List<List<SharedTypeView>>? allPreviouslyPromotedTypes;
        while (ssaNode != null) {
          PromotionModel previousPromotionInfo = _current.infoFor(
            this,
            ssaNode.promotionKey,
            ssaNode: ssaNode,
          );
          List<SharedTypeView> promotedTypes =
              previousPromotionInfo.promotedTypes;
          if (promotedTypes.isNotEmpty) {
            (allPreviouslyPromotedTypes ??= []).add(promotedTypes);
          }
          ssaNode = ssaNode.previousSsaNode;
        }
        if (allPreviouslyPromotedTypes != null) {
          return () {
            Map<SharedTypeView, NonPromotionReason> result =
                <SharedTypeView, NonPromotionReason>{};
            for (List<SharedTypeView> previouslyPromotedTypes
                in allPreviouslyPromotedTypes!) {
              for (SharedTypeView type in previouslyPromotedTypes) {
                result[type] = whyNotPromotable == null
                    ? new PropertyNotPromotedForNonInherentReason(
                        reference.propertyName,
                        propertyMember,
                        fieldPromotionEnabled:
                            typeAnalyzerOptions.fieldPromotionEnabled,
                      )
                    : new PropertyNotPromotedForInherentReason(
                        reference.propertyName,
                        propertyMember,
                        whyNotPromotable,
                        fieldPromotionEnabled:
                            typeAnalyzerOptions.fieldPromotionEnabled,
                      );
              }
            }
            return result;
          };
        }
      }
    } else if (currentPromotionInfo != null) {
      Variable? variable = promotionKeyStore.variableForKey(
        reference.promotionKey,
      );
      if (variable == null) {
        if (!typeAnalyzerOptions.thisPromotionEnabled) {
          List<SharedTypeView> promotedTypes =
              currentPromotionInfo.promotedTypes;
          if (promotedTypes.isNotEmpty) {
            return () {
              Map<SharedTypeView, NonPromotionReason> result =
                  <SharedTypeView, NonPromotionReason>{};
              for (SharedTypeView type in promotedTypes) {
                result[type] = new ThisNotPromoted();
              }
              return result;
            };
          }
        }
      } else {
        return () {
          Map<SharedTypeView, NonPromotionReason> result =
              <SharedTypeView, NonPromotionReason>{};
          SharedTypeView currentType =
              currentPromotionInfo.promotedTypes.lastOrNull ??
              operations.variableType(variable);
          NonPromotionHistory? nonPromotionHistory =
              currentPromotionInfo.nonPromotionHistory;
          while (nonPromotionHistory != null) {
            SharedTypeView nonPromotedType = nonPromotionHistory.type;
            if (!operations.isSubtypeOf(currentType, nonPromotedType)) {
              result[nonPromotedType] ??=
                  nonPromotionHistory.nonPromotionReason;
            }
            nonPromotionHistory = nonPromotionHistory.previous;
          }
          return result;
        };
      }
    }
    return () => {};
  }

  /// Common code for handling patterns that perform an equality check.
  /// [operandInfo] is the expression info for the expression that the matched
  /// value is being compared to, and [operandType] is its type.
  ///
  /// If [notEqual] is `true`, the pattern matches if the matched value is *not*
  /// equal to the operand; otherwise, it matches if the matched value is
  /// *equal* to the operand.
  void _handleEqualityCheckPattern(
    ExpressionInfo? operandInfo,
    SharedTypeView operandType, {
    required bool notEqual,
    required SharedTypeView matchedValueType,
    required int offset,
  }) {
    assert(identical(matchedValueType, _getMatchedValueType()));
    _PatternContext context = _stack.last as _PatternContext;
    // Create a `_Reference` to represent the matched value; this will be the
    // LHS of the equality comparison. Note that it's not necessary to use
    // `restoreConditionVariableState` because `_equalityCheck` uses the
    // `_Reference` solely to decide if the matched value needs to be promoted
    // to non-null; it doesn't attempt to read any stored condition variable
    // state from it.
    _Reference lhsReference = context.createReference(
      matchedValueType,
      _current,
    );
    switch (_equalityCheck(
      lhsReference,
      matchedValueType,
      operandInfo,
      operandType,
    )) {
      case _NoEqualityInformation():
        // We have no information so we have to assume the pattern might or
        // might not match.
        _unmatched = _join(_unmatched!, _current);
      case _EqualityCheckIsNullCheck(:var isReferenceOnRight):
        FlowModel? ifNotNull;
        if (!isReferenceOnRight) {
          // The `null` literal is on the right hand side of the implicit
          // equality check, meaning it is the constant value.  So the user is
          // doing something like this:
          //
          //     if (v case == null) { ... }
          //
          // So we want to promote the type of `v` in the case where the
          // constant pattern *didn't* match.
          ifNotNull = _nullCheckPattern(matchedValueType: matchedValueType);
          if (ifNotNull == null) {
            // `_nullCheckPattern` returns `null` in the case where the matched
            // value type is non-nullable.  In fully sound programs, this would
            // mean that the pattern cannot possibly match.  However, in mixed
            // mode programs it might match due to unsoundness.  Since we don't
            // want type inference results to change when a program becomes
            // fully sound, we have to assume that we're in mixed mode, and thus
            // the pattern might match.
            ifNotNull = _current;
          }
        } else {
          // The `null` literal is on the left hand side of the implicit
          // equality check, meaning it is the scrutinee.  So the user is doing
          // something silly like this:
          //
          //     if (null case == c) { ... }
          //
          // (where `c` is some constant).  There's no variable to promote.
          //
          // Since flow analysis can't make use of the results of constant
          // evaluation, we can't really assume anything; as far as we know, the
          // pattern might or might not match.
          ifNotNull = _current;
        }
        if (notEqual) {
          _unmatched = _join(_unmatched!, _current);
          _setCurrent(ifNotNull, offset: offset);
        } else {
          _unmatched = _join(_unmatched!, ifNotNull);
        }
      case _GuaranteedEqual():
        if (notEqual) {
          // Both operands are known by flow analysis to compare equal, so the
          // pattern is guaranteed *not* to match.
          _unmatched = _join(_unmatched!, _current);
          _setCurrent(_current.setUnreachable(), offset: offset);
        } else {
          // Both operands are known by flow analysis to compare equal, so the
          // pattern is guaranteed to match.  Since our approach to handling
          // patterns in flow analysis uses "implicit and" semantics (initially
          // assuming that the pattern always matches, and then updating the
          // `_current` and `_unmatched` states to reflect what values the
          // pattern rejects), we don't have to do any updates.
        }
      case _GuaranteedNotEqual():
        if (notEqual) {
          // Both operands are known by flow analysis to compare unequal, so the
          // pattern is guaranteed to match.  Since our approach to handling
          // patterns in flow analysis uses "implicit and" semantics (initially
          // assuming that the pattern always matches, and then updating the
          // `_current` and `_unmatched` states to reflect what values the
          // pattern rejects), we don't have to do any updates.
        } else {
          // Both operands are known by flow analysis to compare unequal, so the
          // pattern is guaranteed *not* to match.
          _unmatched = _join(_unmatched!, _current);
          _setCurrent(_current.setUnreachable(), offset: offset);
        }
    }
  }

  (SharedTypeView?, _PropertySsaNode) _handleProperty(
    SsaNode targetSsaNode,
    String propertyName,
    Object? propertyMember,
    SharedTypeView unpromotedType,
  ) {
    // Find the SSA node for the target of the property access, and figure out
    // whether the property in question is promotable.
    bool isPromotable =
        propertyMember != null &&
        typeAnalyzerOptions.fieldPromotionEnabled &&
        operations.isPropertyPromotable(propertyMember);
    _PropertySsaNode propertySsaNode = targetSsaNode.getOrCreatePropertyNode(
      propertyName,
      promotionKeyStore,
      isPromotable: isPromotable,
    );
    SharedTypeView? promotedType;
    if (isPromotable) {
      PromotionModel? promotionInfo = _current.promotionInfo?.get(
        this,
        propertySsaNode.promotionKey,
      );
      if (promotionInfo != null) {
        assert(promotionInfo.ssaNode == propertySsaNode);
      }
      promotedType = promotionInfo?.promotedTypes.lastOrNull;
      if (promotedType != null &&
          !operations.isSubtypeOf(promotedType, unpromotedType)) {
        promotedType = null;
      }
    }
    return (promotedType, propertySsaNode);
  }

  void _initialize(
    int promotionKey,
    SharedTypeView matchedType,
    ExpressionInfo? expressionInfo, {
    required bool isFinal,
    required bool isLate,
    required bool isImplicitlyTyped,
    required SharedTypeView unpromotedType,
    bool inheritPromotableProperties = false,
    required int offset,
  }) {
    if (isLate) {
      // Don't use expression info for late variables, since we don't know when
      // they'll be initialized.
      expressionInfo = null;
    } else if (isImplicitlyTyped &&
        !typeAnalyzerOptions.respectImplicitlyTypedVarInitializers) {
      // If the language version is too old, SSA analysis has to ignore
      // initializer expressions for implicitly typed variables, in order to
      // preserve the buggy behavior of
      // https://github.com/dart-lang/language/issues/1785.
      expressionInfo = null;
    }
    SsaNode newSsaNode =
        inheritPromotableProperties && expressionInfo is _Reference
        ? expressionInfo.ssaNode
        : new SsaNode(
            conditionVariableState:
                expressionInfo != null && expressionInfo.isNonTrivial
                ? expressionInfo
                : null,
          );
    FlowModel current = _current.write(
      this,
      null,
      promotionKey,
      matchedType,
      newSsaNode,
      promoteToTypeOfInterest: !isImplicitlyTyped && !isFinal,
      unpromotedType: unpromotedType,
    );
    if (isImplicitlyTyped && operations.isTypeParameterType(matchedType)) {
      current = current
          .tryPromoteForTypeCheck(
            this,
            _variableReference(promotionKey, unpromotedType),
            matchedType,
          )
          .ifTrue;
    }
    _setCurrent(current, offset: offset);
  }

  /// Determines whether an expression having the given [staticType] is
  /// guaranteed to fail an `is` or `as` check using [checkedType] due to sound
  /// null safety.
  ///
  /// If [TypeAnalyzerOptions.soundFlowAnalysisEnabled] is `false`, this method
  /// will return `false` regardless of its input. This reflects the fact that
  /// in language versions prior to the introduction of sound flow analysis,
  /// flow analysis assumed that the program might be executing in unsound null
  /// safety mode.
  bool _isTypeCheckGuaranteedToFailWithSoundNullSafety({
    required SharedTypeView staticType,
    required SharedTypeView checkedType,
  }) {
    if (!typeAnalyzerOptions.soundFlowAnalysisEnabled) return false;
    switch (typeOperations.classifyType(staticType)) {
      case TypeClassification.nonNullable
          when typeOperations.classifyType(checkedType) ==
              TypeClassification.nullOrEquivalent:
      case TypeClassification.nullOrEquivalent
          when typeOperations.classifyType(checkedType) ==
              TypeClassification.nonNullable:
        // Guaranteed to fail due to nullability mismatch.
        return true;
      default:
        return false;
    }
  }

  /// Whether an expression having the given [staticType] is guaranteed to fail
  /// an `is` or `as` check using [checkedType] due to sound null safety.
  ///
  /// If [TypeAnalyzerOptions.soundFlowAnalysisEnabled] is `false`, this method
  /// will return `false` regardless of its input. This reflects the fact that
  /// in language versions prior to the introduction of sound flow analysis,
  /// flow analysis assumed that the program might be executing in unsound null
  /// safety mode.
  bool _isTypeCheckGuaranteedToSucceedWithSoundNullSafety({
    required SharedTypeView staticType,
    required SharedTypeView checkedType,
  }) {
    return typeAnalyzerOptions.soundFlowAnalysisEnabled &&
        typeOperations.isSubtypeOf(staticType, checkedType);
  }

  FlowModel _join(FlowModel? first, FlowModel? second) =>
      FlowModel.join(this, first, second);

  int _makeInitialThisPromotionKey() {
    int key = promotionKeyStore.makeTemporaryKey();

    // Record the initial `this` promotion key at offset 0, so that it takes
    // effect starting at the beginning of the code being analyzed.
    _logBuilder?.recordInitialThisBinding(key);

    return key;
  }

  /// Creates a promotion key representing a temporary variable that doesn't
  /// correspond to any variable in the user's source code.  This is used by
  /// flow analysis to model the synthetic variables used during pattern
  /// matching to cache the values that the pattern, and its subpatterns, are
  /// being matched against.
  TrivialVariableReference _makeTemporaryReference(
    SsaNode ssaNode,
    SharedTypeView type, {
    required int offset,
  }) {
    int promotionKey = promotionKeyStore.makeTemporaryKey();
    _setCurrent(
      _current.updatePromotionInfo(
        this,
        promotionKey,
        new PromotionModel(
          promotedTypes: const [],
          tested: const [],
          assigned: true,
          unassigned: false,
          ssaNode: ssaNode,
        ),
      ),
      offset: offset,
    );
    return new TrivialVariableReference(
      promotionKey: promotionKey,
      model: _current,
      type: type,
      isThisOrSuper: false,
      ssaNode: ssaNode,
    );
  }

  /// Creates a fresh [ExpressionInfo] recording the current flow analysis
  /// state.
  ExpressionInfo _makeTrivialExpressionInfo(SharedTypeView type) =>
      new ExpressionInfo.trivial(model: _current, type: type);

  ExpressionInfo? _nullAwareAccess_rightBegin(
    ExpressionInfo? targetInfo,
    SharedTypeView targetType, {
    required Variable? guardVariable,
    required int offset,
  }) {
    _setCurrent(_current.split(), offset: offset);
    FlowModel shortcutControlPath = _current;
    _Reference? targetReference = _getExpressionReference(targetInfo);
    if (targetReference != null) {
      _setCurrent(
        _current.tryMarkNonNullable(this, targetReference).ifTrue,
        offset: offset,
      );
    }
    switch (operations.classifyType(targetType)) {
      case TypeClassification.nullOrEquivalent:
        // The control flow path containing the null-aware code is unreachable.
        _setCurrent(_current.setUnreachable(), offset: offset);
      case TypeClassification.nonNullable:
        // The control flow path that skips the null-aware code is unreachable,
        // assuming sound null safety.
        if (typeAnalyzerOptions.soundFlowAnalysisEnabled) {
          shortcutControlPath = shortcutControlPath.setUnreachable();
        }
      case TypeClassification.potentiallyNullable:
        // Both control flow paths are reachable.
        break;
    }
    _stack.add(new _NullAwareAccessContext(shortcutControlPath));
    SsaNode? targetSsaNode;
    ExpressionInfo? nullAwareExpressionInfo = targetReference;
    if (typeAnalyzerOptions.soundFlowAnalysisEnabled) {
      // Pick up the target SSA node so that it can be used for field promotion.
      targetSsaNode = targetReference?.ssaNode;
    } else {
      // Field promotion was broken for null-aware field accesses prior to the
      // implementation of sound flow analysis. So to replicate the bug, destroy
      // the target reference so that it can't be used for field promotion.
      nullAwareExpressionInfo = null;
    }
    if (guardVariable != null) {
      // Promote the guard variable as well.
      int promotionKey = promotionKeyStore.keyForVariable(guardVariable);
      SharedTypeView nonNullType = operations.promoteToNonNull(targetType);
      _setCurrent(
        _current.updatePromotionInfo(
          this,
          promotionKey,
          new PromotionModel(
            promotedTypes: nonNullType == targetType ? const [] : [nonNullType],
            tested: const [],
            assigned: true,
            unassigned: false,
            ssaNode: targetSsaNode ?? new SsaNode(),
          ),
        ),
        offset: offset,
      );
    }
    return nullAwareExpressionInfo;
  }

  /// Computes an updated flow model representing the result of a null check
  /// performed by a pattern.  The returned flow model represents what is known
  /// about the program state if the matched value is determined to be not equal
  /// to `null`.
  ///
  /// If the matched value's type is non-nullable, then `null` is returned.
  FlowModel? _nullCheckPattern({required SharedTypeView matchedValueType}) {
    _PatternContext context = _stack.last as _PatternContext;
    assert(identical(matchedValueType, _getMatchedValueType()));
    _Reference matchedValueReference = context.createReference(
      matchedValueType,
      _current,
    );
    // Promote
    TypeClassification typeClassification = operations.classifyType(
      matchedValueType,
    );
    if (typeClassification == TypeClassification.nonNullable) {
      return null;
    } else {
      FlowModel? ifNotNull = _current
          .tryMarkNonNullable(this, matchedValueReference)
          .ifTrue;
      _Reference? scrutineeReference = _scrutineeReference;
      // If the scrutinee is a variable reference, and the variable hasn't
      // changed since the start of the matching operation, promote it too.
      //
      // If the scrutinee is a property reference, promote it too. (This is safe
      // even if the underlying variable whose property is being referenced has
      // changed, because the next time the property is accessed, it will be
      // accessed through a new SSA node, and thus a new promotion key).
      if (scrutineeReference != null &&
          (scrutineeReference is _PropertyReference ||
              _current.promotionInfo
                      ?.get(this, matchedValueReference.promotionKey)!
                      .ssaNode ==
                  _current.promotionInfo
                      ?.get(this, scrutineeReference.promotionKey)
                      ?.ssaNode)) {
        ifNotNull = ifNotNull
            .tryMarkNonNullable(this, scrutineeReference)
            .ifTrue;
      }
      if (typeClassification == TypeClassification.nullOrEquivalent) {
        ifNotNull = ifNotNull.setUnreachable();
      }
      return ifNotNull;
    }
  }

  FlowModel _popPattern(ExpressionInfo? guardInfo, {required int offset}) {
    _TopPatternContext context = _stack.removeLast() as _TopPatternContext;
    FlowModel unmatched = _unmatched!;
    _unmatched = context._previousUnmatched;
    guardInfo ??= _makeTrivialExpressionInfo(boolType);
    _setCurrent(guardInfo.ifTrue.unsplit(), offset: offset);
    unmatched = _join(unmatched, guardInfo.ifFalse);
    return unmatched.unsplit();
  }

  void _popScrutinee() {
    _ScrutineeContext context = _stack.removeLast() as _ScrutineeContext;
    _scrutineeReference = context.previousScrutineeReference;
  }

  /// Updates the [_stack] to reflect the fact that flow analysis is entering
  /// into a pattern or subpattern match.  [matchedValueInfo] should be the
  /// [_Reference] representing the value being matched.
  void _pushPattern(_Reference matchedValueInfo, {int offset = 0}) {
    _setCurrent(_current.split(), offset: offset);
    _stack.add(new _TopPatternContext(matchedValueInfo, _unmatched));
    _unmatched = _current.setUnreachable();
  }

  /// Updates the [_stack] to reflect the fact that flow analysis is entering
  /// into a construct that performs pattern matching.  [scrutineeInfo] should
  /// be the expression info for the expression that is being matched (or `null`
  /// if there is no expression that's being matched directly, as happens when
  /// in `for-in` loops). [scrutineeType] should be the static type of the
  /// scrutinee.
  ///
  /// [allowScrutineePromotion] indicates whether pattern matches should cause
  /// the scrutinee to be promoted.
  ///
  /// The returned value is the [_Reference] representing the value being
  /// matched.  It should be passed to [_pushPattern].
  _Reference _pushScrutinee(
    ExpressionInfo? scrutineeInfo,
    SharedTypeView scrutineeType, {
    required bool allowScrutineePromotion,
    required int offset,
  }) {
    _stack.add(
      new _ScrutineeContext(previousScrutineeReference: _scrutineeReference),
    );
    _Reference? scrutineeReference = scrutineeInfo is _Reference
        ? scrutineeInfo
        : null;
    _scrutineeReference = scrutineeReference;
    SsaNode? scrutineeSsaNode;
    if (allowScrutineePromotion && scrutineeReference != null) {
      scrutineeSsaNode = scrutineeReference.ssaNode;
    }
    return _makeTemporaryReference(
      scrutineeSsaNode ?? new SsaNode(),
      scrutineeType,
      offset: offset,
    ).restoreConditionVariableState(scrutineeInfo, this, _current);
  }

  void _setCurrent(FlowModel value, {required int offset}) {
    _currentInternal = value;
    _logBuilder?.promotionInfoChanged(value.promotionInfo, offset: offset);
  }

  _Reference _thisOrSuperReference(
    SharedTypeView staticType, {
    required bool isSuper,
  }) {
    SsaNode ssaNode = isSuper ? _superSsaNode : _thisSsaNode;
    return new TrivialVariableReference(
      promotionKey: _thisPromotionKeys.last,
      model: _current,
      type: staticType,
      isThisOrSuper: true,
      ssaNode: ssaNode,
    ).restoreConditionVariableState(
      ssaNode.conditionVariableState,
      this,
      _current,
    );
  }

  TrivialVariableReference _variableReference(
    int variableKey,
    SharedTypeView unpromotedType,
  ) {
    PromotionModel info = _current.promotionInfo!.get(this, variableKey)!;
    return new TrivialVariableReference(
      promotionKey: variableKey,
      model: _current,
      type: info.promotedTypes.lastOrNull ?? unpromotedType,
      isThisOrSuper: false,
      ssaNode: info.ssaNode ?? new SsaNode(),
    );
  }

  /// Common logic for handling writes to variables, whether they occur as part
  /// of an ordinary assignment or a pattern assignment.
  ///
  /// If [isPostfixIncDec] is `true`, the [node] is a postfix expression and we
  /// won't store information about [variable].
  ExpressionInfo? _write(
    Node node,
    Variable variable,
    SharedTypeView writtenType,
    ExpressionInfo? expressionInfo, {
    bool isPostfixIncDec = false,
    required int offset,
  }) {
    SharedTypeView unpromotedType = operations.variableType(variable);
    int variableKey = promotionKeyStore.keyForVariable(variable);
    SsaNode newSsaNode = new SsaNode(
      conditionVariableState:
          expressionInfo != null && expressionInfo.isNonTrivial
          ? expressionInfo
          : null,
    );
    _setCurrent(
      _current.write(
        this,
        new DemoteViaExplicitWrite<Variable, Node>(variable, node),
        variableKey,
        writtenType,
        newSsaNode,
        unpromotedType: unpromotedType,
      ),
      offset: offset,
    );

    // Update the type of the variable for looking up the write expression.
    TrivialVariableReference? reference;
    if (typeAnalyzerOptions.inferenceUpdate4Enabled && !isPostfixIncDec) {
      reference = _variableReference(variableKey, unpromotedType);
    }
    return reference;
  }
}

/// Base class for objects representing constructs in the Dart programming
/// language for which flow analysis information needs to be tracked.
abstract class _FlowContext {
  _FlowContext() {
    assert(() {
      // Check that `_debugType` has been overridden in a way that reflects the
      // class name.  Note that this assumes the behavior of `runtimeType` in
      // the VM, but that's ok, because this code is only active when asserts
      // are enabled, and we only run unit tests on the VM.
      String expectedDebugType = runtimeType.toString();
      int lessThanIndex = expectedDebugType.indexOf('<');
      if (lessThanIndex > 0) {
        expectedDebugType = expectedDebugType.substring(0, lessThanIndex);
      }
      assert(
        _debugType == expectedDebugType,
        'Expected a debug type of $expectedDebugType, got $_debugType',
      );
      return true;
    }());
  }

  /// Returns a freshly allocated map whose keys are the names of fields in the
  /// class, and whose values are the values of those fields.
  ///
  /// This is used by [toString] to print out information for debugging.
  Map<String, Object?> get _debugFields => {};

  /// Returns a string representation of the class name.  This is used by
  /// [toString] to print out information for debugging.
  String get _debugType;

  @override
  String toString() {
    List<String> fields = [
      for (MapEntry<String, Object?> entry in _debugFields.entries)
        if (entry.value != null) '${entry.key}: ${entry.value}',
    ];
    return '$_debugType(${fields.join(', ')})';
  }
}

/// [_FlowContext] representing a function expression.
class _FunctionExpressionContext extends _SimpleContext {
  /// The [_AnonymousBlockContext] for the immediately enclosing block-bodied
  /// anonymous method, or `null` if there is no enclosing block-bodied
  /// anonymous method.
  final _AnonymousBlockContext? _previousAnonymousBlockContext;

  _FunctionExpressionContext(
    super.previous,
    this._previousAnonymousBlockContext,
  );

  @override
  Map<String, Object?> get _debugFields =>
      super._debugFields
        ..['previousAnonymousBlockContext'] = _previousAnonymousBlockContext;

  @override
  String get _debugType => '_FunctionExpressionContext';
}

/// Specialization of [_EqualityCheckResult] used as the return value for
/// [_FlowAnalysisImpl._equalityCheck] when it is determined that the two
/// operands are guaranteed to be equal to one another, so the code path that
/// results from a not-equal result should be marked as unreachable.  (This
/// happens if both operands have type `Null`).
class _GuaranteedEqual extends _EqualityCheckResult {
  const _GuaranteedEqual() : super._();
}

/// Specialization of [_EqualityCheckResult] used as the return value for
/// [_FlowAnalysisImpl._equalityCheck] when it is determined that the two
/// operands are guaranteed to be not equal to one another, so the code path
/// that results from an equal result should be marked as unreachable.  (This
/// happens if one operands has type `Null` and the other has a non-nullable
/// type, and [TypeAnalyzerOptions.soundFlowAnalysisEnabled] is `true`).
class _GuaranteedNotEqual extends _EqualityCheckResult {
  const _GuaranteedNotEqual() : super._();
}

/// [_FlowContext] representing an `if` statement.
class _IfContext extends _BranchContext {
  /// Flow model associated with the state of program execution after the `if`
  /// statement executes, in the circumstance where the "then" branch is taken.
  FlowModel? _afterThen;

  _IfContext(super._branchModel);

  @override
  Map<String, Object?> get _debugFields =>
      super._debugFields..['afterThen'] = _afterThen;

  @override
  String get _debugType => '_IfContext';
}

/// [_FlowContext] representing an "if-null" (`??`) expression.
class _IfNullExpressionContext extends _FlowContext {
  /// The state if the operation short-cuts (i.e. if the expression before the
  /// `??` was non-`null`).
  final FlowModel _shortcutState;

  _IfNullExpressionContext(this._shortcutState);

  @override
  Map<String, Object?> get _debugFields =>
      super._debugFields..['shortcutState'] = _shortcutState;

  @override
  String get _debugType => '_IfNullExpressionContext';
}

/// Specialization of [_EqualityCheckResult] used as the return value for
/// [_FlowAnalysisImpl._equalityCheck] when no particular conclusion can be
/// drawn about the outcome of the outcome of the equality check.  In other
/// words, regardless of whether the equality check matches or not, the
/// resulting code path is reachable and no promotions can be done.
class _NoEqualityInformation extends _EqualityCheckResult {
  const _NoEqualityInformation() : super._();
}

/// [_FlowContext] representing a null aware access (`?.`).
class _NullAwareAccessContext extends _SimpleContext {
  _NullAwareAccessContext(super.previous);

  @override
  String get _debugType => '_NullAwareAccessContext';
}

/// [_FlowContext] representing a null-aware map entry (`{?a: ?b}`).
///
/// This context should only be created for a null-aware map entry that has a
/// null-aware key.
class _NullAwareMapEntryContext extends _FlowContext {
  /// The state if the operation short-cuts (i.e. if the key expression was
  /// `null`.
  final FlowModel _shortcutState;

  _NullAwareMapEntryContext(this._shortcutState);

  @override
  Map<String, Object?> get _debugFields =>
      super._debugFields..['shortcutState'] = _shortcutState;

  @override
  String get _debugType => '_NullAwareMapEntryContext';
}

/// Specialization of [ExpressionInfo] for the case where the expression is a
/// `null` literal.
class _NullInfo extends ExpressionInfo {
  _NullInfo({required super.type, required super.model}) : super.trivial();

  @override
  bool get isNull => true;

  @override
  String toString() => '_NullInfo(type: $_type)';
}

/// [_FlowContext] representing a logical-or pattern.
class _OrPatternContext extends _PatternContext {
  /// The value of [_FlowAnalysisImpl._unmatched] prior to entering the
  /// logical-or pattern.
  final FlowModel _previousUnmatched;

  /// If the left hand side of the logical-or pattern has already been
  /// traversed, the value of [_FlowAnalysisImpl._current] after traversing it.
  /// This represents the flow state under the assumption that the left hand
  /// side matched.
  FlowModel? _lhsMatched;

  _OrPatternContext(super._matchedValueInfo, this._previousUnmatched);

  @override
  Map<String, Object?> get _debugFields => super._debugFields
    ..['previousUnmatched'] = _previousUnmatched
    ..['lhsMatched'] = _lhsMatched;

  @override
  String get _debugType => '_OrPatternContext';
}

/// [_FlowContext] representing a pattern.
class _PatternContext extends _FlowContext {
  /// [ExpressionInfo] for the value being matched.
  final _Reference _matchedValueInfo;

  _PatternContext(this._matchedValueInfo);

  @override
  Map<String, Object?> get _debugFields =>
      super._debugFields..['matchedValueInfo'] = _matchedValueInfo;

  @override
  String get _debugType => '_PatternContext';

  /// Creates a reference to the matched value having type [matchedType].
  TrivialVariableReference createReference(
    SharedTypeView matchedType,
    FlowModel current,
  ) => new TrivialVariableReference(
    promotionKey: _matchedValueInfo.promotionKey,
    model: current,
    type: matchedType,
    isThisOrSuper: false,
    ssaNode: new SsaNode(),
  );
}

/// [_FlowContext] representing a subpattern of an object pattern, which is
/// being matched against a property of the object pattern's target.
class _PropertyPatternContext extends _PatternContext {
  /// The value of [_FlowAnalysisImpl._scrutineeReference] that was in effect
  /// prior to visiting the subpattern.
  final _Reference? _previousScrutinee;

  _PropertyPatternContext(super._matchedValueInfo, this._previousScrutinee);

  @override
  Map<String, Object?> get _debugFields =>
      super._debugFields..['previousScrutinee'] = _previousScrutinee;

  @override
  String get _debugType => '_PropertyPatternContext';
}

/// Specialization of [ExpressionInfo] for the case where the expression is a
/// reference to a property.
class _PropertyReference extends _Reference {
  /// The name of the property.
  final String propertyName;

  /// The field or property being accessed.  This matches a `propertyMember`
  /// value that was passed to [FlowAnalysis.propertyGet].
  final Object? propertyMember;

  _PropertyReference({
    required super.type,
    required super.model,
    required this.propertyName,
    required this.propertyMember,
    required super.promotionKey,
    required super.ssaNode,
  }) : super.trivial(isThisOrSuper: false);

  @override
  String toString() =>
      '_PropertyReference('
      'type: $_type, propertyName: $propertyName, '
      'propertyMember: $propertyMember, promotionKey: $promotionKey)';
}

/// Data structure representing a unique value returned by the invocation of a
/// property getter during execution of the code being analyzed.
class _PropertySsaNode extends SsaNode {
  /// The promotion key associated with this value. This allows for field
  /// promotion.
  final int promotionKey;

  /// If this property is not promotable, then a fresh SSA node is assigned at
  /// the time of each access; when that occurs, this field points to the
  /// previous SSA node associated with the same property; otherwise it is
  /// `null`. This is used by the "why not promoted" logic to figure out what
  /// promotions *would* have occurred if the property had been promotable.
  final _PropertySsaNode? previousSsaNode;

  _PropertySsaNode(this.promotionKey, {this.previousSsaNode});
}

/// Interface used by the classes derived from [PropertyTarget] to access the
/// internals of [_FlowAnalysisImpl].
abstract class _PropertyTargetHelper<Expression extends Object> {
  /// Stack of information about the targets of any cascade expressions that are
  /// currently being visited.
  List<_Reference> get _cascadeTargetStack;

  /// SSA node representing the implicit pseudo-variable `super`. Although
  /// `super` and `this` represent the same object, flow analysis considers them
  /// distinct so that if the class being compiled both inherits *and* overrides
  /// a field `_f`, type promotions for `this._f` and `super._f` will be tracked
  /// separately.
  SsaNode get _superSsaNode;

  /// SSA node representing the implicit variable `this`.
  SsaNode get _thisSsaNode;
}

/// Specialization of [ExpressionInfo] for the case where the expression is a
/// reference to a variable, property, `this`, or the pseudo-expression `super`.
class _Reference extends ExpressionInfo {
  /// The integer key representing the thing referred to by this expression in
  /// [FlowModel.promotionInfo].
  final int promotionKey;

  /// Whether the thing referred to by this expression is `this` (or the
  /// pseudo-expression `super`).
  final bool isThisOrSuper;

  /// The SSA node representing the value of this expression.
  final SsaNode ssaNode;

  _Reference({
    required super.type,
    required super.ifTrue,
    required super.ifFalse,
    required this.promotionKey,
    required this.isThisOrSuper,
    required this.ssaNode,
  });

  _Reference.trivial({
    required super.type,
    required super.model,
    required this.promotionKey,
    required this.isThisOrSuper,
    required this.ssaNode,
  }) : super.trivial();

  @override
  String toString() =>
      '_Reference(type: $_type, '
      'ifTrue: $ifTrue, ifFalse: $ifFalse, promotionKey: $promotionKey, '
      'isThisOrSuper: $isThisOrSuper, ssaNode: $ssaNode)';
}

/// [_FlowContext] representing a construct that can contain one or more
/// patterns, and thus has a scrutinee (for example a `switch` statement).
class _ScrutineeContext extends _FlowContext {
  final _Reference? previousScrutineeReference;

  _ScrutineeContext({required this.previousScrutineeReference});

  @override
  Map<String, Object?> get _debugFields =>
      super._debugFields
        ..['previousScrutineeReference'] = previousScrutineeReference;

  @override
  String get _debugType => '_ScrutineeContext';
}

/// [_FlowContext] representing a language construct for which flow analysis
/// must store a flow model state to be retrieved later, such as a `try`
/// statement, function expression, or "if-null" (`??`) expression.
abstract class _SimpleContext extends _FlowContext {
  /// The stored state.  For a `try` statement, this is the state from the
  /// beginning of the `try` block.  For a function expression, this is the
  /// state at the point the function expression was created.
  final FlowModel _previous;

  _SimpleContext(this._previous);

  @override
  Map<String, Object?> get _debugFields =>
      super._debugFields..['previous'] = _previous;
}

/// [_FlowContext] representing a language construct that can be targeted by
/// `break` or `continue` statements, and for which flow analysis must store a
/// flow model state to be retrieved later.  Examples include "for each" and
/// `switch` statements.
class _SimpleStatementContext extends _BranchTargetContext {
  /// The stored state.  For a "for each" statement, this is the state after
  /// evaluation of the iterable.  For a `switch` statement, this is the state
  /// after evaluation of the switch expression.
  final FlowModel _previous;

  _SimpleStatementContext(super.checkpoint, this._previous);

  @override
  Map<String, Object?> get _debugFields =>
      super._debugFields..['previous'] = _previous;

  @override
  String get _debugType => '_SimpleStatementContext';
}

class _SwitchAlternativesContext<Variable extends Object> extends _FlowContext {
  /// The enclosing [_SwitchContext].
  final _SwitchContext _switchContext;

  /// Data structure accumulating information about the relationship among
  /// variables defined by patterns in the various alternatives.
  final PatternVariableInfo<Variable> _patternVariableInfo =
      new PatternVariableInfo();

  FlowModel? _combinedModel;

  _SwitchAlternativesContext(this._switchContext);

  @override
  Map<String, Object?> get _debugFields =>
      super._debugFields..['combinedModel'] = _combinedModel;

  @override
  String get _debugType => '_SwitchAlternativesContext';
}

/// [_FlowContext] representing a switch statement or switch expression.
class _SwitchContext extends _SimpleStatementContext {
  /// [_Reference] for the value being matched.
  final _Reference _matchedValueInfo;

  /// Flow state for the code path where no patterns have matched yet.  If we
  /// think of a switch as syntactic sugar for a chain of if-else statements,
  /// this is the flow state on entry to the next `if`.
  FlowModel _unmatched;

  _SwitchContext(super.checkpoint, super._previous, this._matchedValueInfo)
    : _unmatched = _previous;

  @override
  Map<String, Object?> get _debugFields => super._debugFields
    ..['matchedValueInfo'] = _matchedValueInfo
    ..['unmatched'] = _unmatched;

  @override
  String get _debugType => '_SwitchContext';
}

/// [_FlowContext] representing the top level of a pattern syntax tree.
class _TopPatternContext extends _PatternContext {
  final FlowModel? _previousUnmatched;

  _TopPatternContext(super.matchedValueInfo, this._previousUnmatched);

  @override
  Map<String, Object?> get _debugFields =>
      super._debugFields..['previousUnmatched'] = _previousUnmatched;

  @override
  String get _debugType => '_TopPatternContext';
}

/// [_FlowContext] representing a try statement.
class _TryContext extends _SimpleContext {
  /// If the statement is a "try/catch" statement, the flow model representing
  /// program state at the top of any `catch` block.
  FlowModel? _beforeCatch;

  /// If the statement is a "try/catch" statement, the accumulated flow model
  /// representing program state after the `try` block or one of the `catch`
  /// blocks has finished executing.  If the statement is a "try/finally"
  /// statement, the flow model representing program state after the `try` block
  /// has finished executing.
  FlowModel? _afterBodyAndCatches;

  _TryContext(super.previous);

  @override
  Map<String, Object?> get _debugFields => super._debugFields
    ..['beforeCatch'] = _beforeCatch
    ..['afterBodyAndCatches'] = '_afterBodyAndCatches';

  @override
  String get _debugType => '_TryContext';
}

class _TryFinallyContext extends _FlowContext {
  /// The flow model representing program state at the top of the `try` block.
  FlowModel _beforeTry;

  /// The flow model representing program state at the bottom of the `try`
  /// block.
  FlowModel? _afterTry;

  /// The flow model representing program state at the top of the `finally`
  /// block.
  FlowModel? _beforeFinally;

  _TryFinallyContext(this._beforeTry);

  @override
  Map<String, Object?> get _debugFields => super._debugFields
    ..['beforeTry'] = _beforeTry
    ..['afterTry'] = _afterTry
    ..['beforeFinally'] = _beforeFinally;

  @override
  String get _debugType => '_TryFinallyContext';
}

/// [_FlowContext] representing a `while` loop (or a C-style `for` loop, which
/// is functionally similar).
class _WhileContext extends _BranchTargetContext {
  /// Flow model if the condition evaluates to `false`.
  final FlowModel _conditionFalse;

  _WhileContext(super.checkpoint, this._conditionFalse);

  @override
  Map<String, Object?> get _debugFields =>
      super._debugFields..['conditionFalse'] = _conditionFalse;

  @override
  String get _debugType => '_WhileContext';
}
