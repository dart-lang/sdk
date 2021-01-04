// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

/// Set this boolean to `true` to permanently enable the feature of allowing
/// local boolean variables to influence promotion (see
/// https://github.com/dart-lang/language/issues/1274).  While this boolean is
/// `false`, the feature remains experimental and can be activated via an
/// optional boolean parameter to the [FlowAnalysis] constructor.
///
/// Changing this value to `true` will cause some dead code warnings to appear
/// for code that only exists to support the old behavior.
const bool allowLocalBooleanVarsToPromoteByDefault = false;

/// [AssignedVariables] is a helper class capable of computing the set of
/// variables that are potentially written to, and potentially captured by
/// closures, at various locations inside the code being analyzed.  This class
/// should be used prior to running flow analysis, to compute the sets of
/// variables to pass in to flow analysis.
///
/// This class is intended to be used in two phases.  In the first phase, the
/// client should traverse the source code recursively, making calls to
/// [beginNode] and [endNode] to indicate the constructs in which writes should
/// be tracked, and calls to [write] to indicate when a write is encountered.
/// The order of visiting is not important provided that nesting is respected.
/// This phase is called the "pre-traversal" because it should happen prior to
/// flow analysis.
///
/// Then, in the second phase, the client may make queries using
/// [capturedAnywhere], [writtenInNode], and [capturedInNode].
///
/// We use the term "node" to refer generally to a loop statement, switch
/// statement, try statement, loop collection element, local function, or
/// closure.
class AssignedVariables<Node extends Object, Variable extends Object> {
  /// Mapping from a node to the info for that node.
  final Map<Node, AssignedVariablesNodeInfo<Variable>> _info =
      new Map<Node, AssignedVariablesNodeInfo<Variable>>.identity();

  /// Info for the variables written or captured anywhere in the code being
  /// analyzed.
  final AssignedVariablesNodeInfo<Variable> _anywhere =
      new AssignedVariablesNodeInfo<Variable>();

  /// Stack of info for nodes that have been entered but not yet left.
  final List<AssignedVariablesNodeInfo<Variable>> _stack = [
    new AssignedVariablesNodeInfo<Variable>()
  ];

  /// When assertions are enabled, the set of info objects that have been
  /// retrieved by [deferNode] but not yet sent to [storeNode].
  final Set<AssignedVariablesNodeInfo<Variable>> _deferredInfos =
      new Set<AssignedVariablesNodeInfo<Variable>>.identity();

  /// This method should be called during pre-traversal, to mark the start of a
  /// loop statement, switch statement, try statement, loop collection element,
  /// local function, closure, or late variable initializer which might need to
  /// be queried later.
  ///
  /// The span between the call to [beginNode] and [endNode] should cover any
  /// statements and expressions that might be crossed by a backwards jump.  So
  /// for instance, in a "for" loop, the condition, updaters, and body should be
  /// covered, but the initializers should not.  Similarly, in a switch
  /// statement, the body of the switch statement should be covered, but the
  /// switch expression should not.
  void beginNode() {
    _stack.add(new AssignedVariablesNodeInfo<Variable>());
  }

  /// This method should be called during pre-traversal, to indicate that the
  /// declaration of a variable has been found.
  ///
  /// It is not required for the declaration to be seen prior to its use (this
  /// is to allow for error recovery in the analyzer).
  void declare(Variable variable) {
    _stack.last._declared.add(variable);
  }

  /// This method may be called during pre-traversal, to mark the end of a
  /// loop statement, switch statement, try statement, loop collection element,
  /// local function, closure, or late variable initializer which might need to
  /// be queried later.
  ///
  /// [isClosureOrLateVariableInitializer] should be true if the node is a local
  /// function or closure, or a late variable initializer.
  ///
  /// In contrast to [endNode], this method doesn't store the data gathered for
  /// the node for later use; instead it returns it to the caller.  At a later
  /// time, the caller should pass the returned data to [storeNodeInfo].
  ///
  /// See [beginNode] for more details.
  AssignedVariablesNodeInfo<Variable> deferNode(
      {bool isClosureOrLateVariableInitializer: false}) {
    AssignedVariablesNodeInfo<Variable> info = _stack.removeLast();
    info._written.removeAll(info._declared);
    info._captured.removeAll(info._declared);
    AssignedVariablesNodeInfo<Variable> last = _stack.last;
    last._written.addAll(info._written);
    last._captured.addAll(info._captured);
    if (isClosureOrLateVariableInitializer) {
      last._captured.addAll(info._written);
      _anywhere._captured.addAll(info._written);
    }
    // If we have already deferred this info, something has gone horribly wrong.
    assert(_deferredInfos.add(info));
    return info;
  }

  /// This method may be called during pre-traversal, to discard the effects of
  /// the most recent unmatched call to [beginNode].
  ///
  /// This is necessary because try/catch/finally needs to be desugared into
  /// a try/catch nested inside a try/finally, however the pre-traversal phase
  /// of the front end happens during parsing, so when a `try` is encountered,
  /// it is not known whether it will need to be desugared into two nested
  /// `try`s.  To cope with this, the front end may call [beginNode] twice upon
  /// seeing the two `try`s, and later if it turns out that no desugaring was
  /// needed, use [discardNode] to discard the effects of one of the [beginNode]
  /// calls.
  void discardNode() {
    AssignedVariablesNodeInfo<Variable> discarded = _stack.removeLast();
    AssignedVariablesNodeInfo<Variable> last = _stack.last;
    last._declared.addAll(discarded._declared);
    last._written.addAll(discarded._written);
    last._captured.addAll(discarded._captured);
  }

  /// This method should be called during pre-traversal, to mark the end of a
  /// loop statement, switch statement, try statement, loop collection element,
  /// local function, closure, or late variable initializer which might need to
  /// be queried later.
  ///
  /// [isClosureOrLateVariableInitializer] should be true if the node is a local
  /// function or closure, or a late variable initializer.
  ///
  /// This is equivalent to a call to [deferNode] followed immediately by a call
  /// to [storeInfo].
  ///
  /// See [beginNode] for more details.
  void endNode(Node node, {bool isClosureOrLateVariableInitializer: false}) {
    storeInfo(
        node,
        deferNode(
            isClosureOrLateVariableInitializer:
                isClosureOrLateVariableInitializer));
  }

  /// Call this after visiting the code to be analyzed, to check invariants.
  void finish() {
    assert(() {
      assert(
          _deferredInfos.isEmpty, "Deferred infos not stored: $_deferredInfos");
      assert(_stack.length == 1, "Unexpected stack: $_stack");
      AssignedVariablesNodeInfo<Variable> last = _stack.last;
      Set<Variable> undeclaredWrites = last._written.difference(last._declared);
      assert(undeclaredWrites.isEmpty,
          'Variables written to but not declared: $undeclaredWrites');
      Set<Variable> undeclaredCaptures =
          last._captured.difference(last._declared);
      assert(undeclaredCaptures.isEmpty,
          'Variables captured but not declared: $undeclaredCaptures');
      return true;
    }());
  }

  /// Call this method between calls to [beginNode] and [endNode]/[deferNode],
  /// if it is necessary to temporarily process some code outside the current
  /// node.  Returns a data structure that should be passed to [pushNode].
  ///
  /// This is used by the front end when building for-elements in lists, maps,
  /// and sets; their initializers are partially built after building their
  /// loop conditions but before completely building their bodies.
  AssignedVariablesNodeInfo<Variable> popNode() {
    return _stack.removeLast();
  }

  /// Call this method to un-do the effect of [popNode].
  void pushNode(AssignedVariablesNodeInfo<Variable> node) {
    _stack.add(node);
  }

  /// Call this method to register that the node [from] for which information
  /// has been stored is replaced by the node [to].
  // TODO(johnniwinther): Remove this when unified collections are encoded as
  // general elements in the front-end.
  void reassignInfo(Node from, Node to) {
    assert(!_info.containsKey(to), "Node $to already has info: ${_info[to]}");
    AssignedVariablesNodeInfo<Variable>? info = _info.remove(from);
    assert(
        info != null,
        'No information for $from (${from.hashCode}) in '
        '{${_info.keys.map((k) => '$k (${k.hashCode})').join(',')}}');

    _info[to] = info!;
  }

  /// This method may be called at any time between a call to [deferNode] and
  /// the call to [finish], to store assigned variable info for the node.
  void storeInfo(Node node, AssignedVariablesNodeInfo<Variable> info) {
    // Caller should not try to store the same piece of info more than once.
    assert(_deferredInfos.remove(info));
    _info[node] = info;
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('AssignedVariables(');
    _printOn(sb);
    sb.write(')');
    return sb.toString();
  }

  /// This method should be called during pre-traversal, to mark a write to a
  /// variable.
  void write(Variable variable) {
    _stack.last._written.add(variable);
    _anywhere._written.add(variable);
  }

  /// Queries the information stored for the given [node].
  AssignedVariablesNodeInfo<Variable> _getInfoForNode(Node node) {
    return _info[node] ??
        (throw new StateError('No information for $node (${node.hashCode}) in '
            '{${_info.keys.map((k) => '$k (${k.hashCode})').join(',')}}'));
  }

  void _printOn(StringBuffer sb) {
    sb.write('_info=$_info,');
    sb.write('_stack=$_stack,');
    sb.write('_anywhere=$_anywhere');
  }
}

/// Extension of [AssignedVariables] intended for use in tests.  This class
/// exposes the results of the analysis so that they can be tested directly.
/// Not intended to be used by clients of flow analysis.
class AssignedVariablesForTesting<Node extends Object, Variable extends Object>
    extends AssignedVariables<Node, Variable> {
  Set<Variable> get capturedAnywhere => _anywhere._captured;

  Set<Variable> get declaredAtTopLevel => _stack.first._declared;

  Set<Variable> get writtenAnywhere => _anywhere._written;

  Set<Variable> capturedInNode(Node node) => _getInfoForNode(node)._captured;

  Set<Variable> declaredInNode(Node node) => _getInfoForNode(node)._declared;

  bool isTracked(Node node) => _info.containsKey(node);

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('AssignedVariablesForTesting(');
    _printOn(sb);
    sb.write(')');
    return sb.toString();
  }

  Set<Variable> writtenInNode(Node node) => _getInfoForNode(node)._written;
}

/// Information tracked by [AssignedVariables] for a single node.
class AssignedVariablesNodeInfo<Variable extends Object> {
  /// The set of local variables that are potentially written in the node.
  final Set<Variable> _written = new Set<Variable>.identity();

  /// The set of local variables for which a potential write is captured by a
  /// local function or closure inside the node.
  final Set<Variable> _captured = new Set<Variable>.identity();

  /// The set of local variables that are declared in the node.
  final Set<Variable> _declared = new Set<Variable>.identity();

  String toString() =>
      'AssignedVariablesNodeInfo(_written=$_written, _captured=$_captured, '
      '_declared=$_declared)';
}

/// A collection of flow models representing the possible outcomes of evaluating
/// an expression that are relevant to flow analysis.
class ExpressionInfo<Variable extends Object, Type extends Object> {
  /// The state after the expression evaluates, if we don't care what it
  /// evaluates to.
  final FlowModel<Variable, Type> after;

  /// The state after the expression evaluates, if it evaluates to `true`.
  final FlowModel<Variable, Type> ifTrue;

  /// The state after the expression evaluates, if it evaluates to `false`.
  final FlowModel<Variable, Type> ifFalse;

  ExpressionInfo(this.after, this.ifTrue, this.ifFalse);

  /// Computes a new [ExpressionInfo] based on this one, but with the roles of
  /// [ifTrue] and [ifFalse] reversed.
  ExpressionInfo<Variable, Type> invert() =>
      new ExpressionInfo<Variable, Type>(after, ifFalse, ifTrue);

  ExpressionInfo<Variable, Type>? rebaseForward(
          TypeOperations<Variable, Type> typeOperations,
          FlowModel<Variable, Type> base) =>
      new ExpressionInfo(base, ifTrue.rebaseForward(typeOperations, base),
          ifFalse.rebaseForward(typeOperations, base));

  @override
  String toString() =>
      'ExpressionInfo(after: $after, _ifTrue: $ifTrue, ifFalse: $ifFalse)';
}

/// Implementation of flow analysis to be shared between the analyzer and the
/// front end.
///
/// The client should create one instance of this class for every method, field,
/// or top level variable to be analyzed, and call the appropriate methods
/// while visiting the code for type inference.
abstract class FlowAnalysis<Node extends Object, Statement extends Node,
    Expression extends Object, Variable extends Object, Type extends Object> {
  factory FlowAnalysis(TypeOperations<Variable, Type> typeOperations,
      AssignedVariables<Node, Variable> assignedVariables,
      {bool allowLocalBooleanVarsToPromote = false}) {
    return new _FlowAnalysisImpl(typeOperations, assignedVariables,
        allowLocalBooleanVarsToPromote: allowLocalBooleanVarsToPromote);
  }

  /// Return `true` if the current state is reachable.
  bool get isReachable;

  /// Call this method after visiting an "as" expression.
  ///
  /// [subExpression] should be the expression to which the "as" check was
  /// applied.  [type] should be the type being checked.
  void asExpression_end(Expression subExpression, Type type);

  /// Call this method after visiting the condition part of an assert statement
  /// (or assert initializer).
  ///
  /// [condition] should be the assert statement's condition.
  ///
  /// See [assert_begin] for more information.
  void assert_afterCondition(Expression condition);

  /// Call this method before visiting the condition part of an assert statement
  /// (or assert initializer).
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
  void assert_begin();

  /// Call this method after visiting an assert statement (or assert
  /// initializer).
  ///
  /// See [assert_begin] for more information.
  void assert_end();

  /// Call this method when visiting a boolean literal expression.
  void booleanLiteral(Expression expression, bool value);

  /// Call this method just before visiting a conditional expression ("?:").
  void conditional_conditionBegin();

  /// Call this method upon reaching the ":" part of a conditional expression
  /// ("?:").  [thenExpression] should be the expression preceding the ":".
  void conditional_elseBegin(Expression thenExpression);

  /// Call this method when finishing the visit of a conditional expression
  /// ("?:").  [elseExpression] should be the expression preceding the ":", and
  /// [conditionalExpression] should be the whole conditional expression.
  void conditional_end(
      Expression conditionalExpression, Expression elseExpression);

  /// Call this method upon reaching the "?" part of a conditional expression
  /// ("?:").  [condition] should be the expression preceding the "?".
  void conditional_thenBegin(Expression condition);

  /// Register a declaration of the [variable] in the current state.
  /// Should also be called for function parameters.
  ///
  /// A local variable is [initialized] if its declaration has an initializer.
  /// A function parameter is always initialized, so [initialized] is `true`.
  void declare(Variable variable, bool initialized);

  /// Call this method before visiting the body of a "do-while" statement.
  /// [doStatement] should be the same node that was passed to
  /// [AssignedVariables.endNode] for the do-while statement.
  void doStatement_bodyBegin(Statement doStatement);

  /// Call this method after visiting the body of a "do-while" statement, and
  /// before visiting its condition.
  void doStatement_conditionBegin();

  /// Call this method after visiting the condition of a "do-while" statement.
  /// [condition] should be the condition of the loop.
  void doStatement_end(Expression condition);

  /// Call this method just after visiting a binary `==` or `!=` expression.
  void equalityOp_end(Expression wholeExpression, Expression rightOperand,
      Type rightOperandType,
      {bool notEqual = false});

  /// Call this method just after visiting the left hand side of a binary `==`
  /// or `!=` expression.
  void equalityOp_rightBegin(Expression leftOperand, Type leftOperandType);

  /// Retrieves the [ExpressionInfo] associated with [target], if known.  Will
  /// return `null` if (a) no info is associated with [target], or (b) another
  /// expression with info has been visited more recently than [target].  For
  /// testing only.
  ExpressionInfo<Variable, Type>? expressionInfoForTesting(Expression target);

  /// This method should be called at the conclusion of flow analysis for a top
  /// level function or method.  Performs assertion checks.
  void finish();

  /// Call this method just before visiting the body of a conventional "for"
  /// statement or collection element.  See [for_conditionBegin] for details.
  ///
  /// If a "for" statement is being entered, [node] is an opaque representation
  /// of the loop, for use as the target of future calls to [handleBreak] or
  /// [handleContinue].  If a "for" collection element is being entered, [node]
  /// should be `null`.
  ///
  /// [condition] is an opaque representation of the loop condition; it is
  /// matched against expressions passed to previous calls to determine whether
  /// the loop condition should cause any promotions to occur.  If [condition]
  /// is null, the condition is understood to be empty (equivalent to a
  /// condition of `true`).
  void for_bodyBegin(Statement? node, Expression? condition);

  /// Call this method just before visiting the condition of a conventional
  /// "for" statement or collection element.
  ///
  /// Note that a conventional "for" statement is a statement of the form
  /// `for (initializers; condition; updaters) body`.  Statements of the form
  /// `for (variable in iterable) body` should use [forEach_bodyBegin].  Similar
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
  void for_conditionBegin(Node node);

  /// Call this method just after visiting the updaters of a conventional "for"
  /// statement or collection element.  See [for_conditionBegin] for details.
  void for_end();

  /// Call this method just before visiting the updaters of a conventional "for"
  /// statement or collection element.  See [for_conditionBegin] for details.
  void for_updaterBegin();

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
  /// [AssignedVariables.endNode] for the for statement.  [loopVariable] should
  /// be the variable assigned to by the loop (if it is promotable, otherwise
  /// null).  [writtenType] should be the type written to that variable (i.e.
  /// if the loop iterates over `List<Foo>`, it should be `Foo`).
  void forEach_bodyBegin(Node node, Variable? loopVariable, Type writtenType);

  /// Call this method just before visiting the body of a "for-in" statement or
  /// collection element.  See [forEach_bodyBegin] for details.
  void forEach_end();

  /// Call this method to forward information on [oldExpression] to
  /// [newExpression].
  ///
  /// This can be used to preserve promotions through a replacement from
  /// [oldExpression] to [newExpression]. For instance when rewriting
  ///
  ///    method(int i) {
  ///      if (i is int) { ... } else { ... }
  ///    }
  ///
  ///  to
  ///
  ///    method(int i) {
  ///      if (i is int || throw ...) { ... } else { ... }
  ///    }
  ///
  ///  the promotion `i is int` can be forwarded to `i is int || throw ...` and
  ///  there preserved in the surrounding if statement.
  void forwardExpression(Expression newExpression, Expression oldExpression);

  /// Call this method just before visiting the body of a function expression or
  /// local function.
  ///
  /// [node] should be the same node that was passed to
  /// [AssignedVariables.endNode] for the function expression.
  void functionExpression_begin(Node node);

  /// Call this method just after visiting the body of a function expression or
  /// local function.
  void functionExpression_end();

  /// Call this method when visiting a break statement.  [target] should be the
  /// statement targeted by the break.
  void handleBreak(Statement target);

  /// Call this method when visiting a continue statement.  [target] should be
  /// the statement targeted by the continue.
  void handleContinue(Statement target);

  /// Register the fact that the current state definitely exists, e.g. returns
  /// from the body, throws an exception, etc.
  ///
  /// Should also be called if a subexpression's type is Never.
  void handleExit();

  /// Call this method after visiting the RHS of an if-null expression ("??")
  /// or if-null assignment ("??=").
  ///
  /// Note: for an if-null assignment, the call to [write] should occur before
  /// the call to [ifNullExpression_end] (since the write only occurs if the
  /// read resulted in a null value).
  void ifNullExpression_end();

  /// Call this method after visiting the LHS of an if-null expression ("??")
  /// or if-null assignment ("??=").
  void ifNullExpression_rightBegin(
      Expression leftHandSide, Type leftHandSideType);

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
  void ifStatement_conditionBegin();

  /// Call this method after visiting the "then" part of an if statement, and
  /// before visiting the "else" part.
  void ifStatement_elseBegin();

  /// Call this method after visiting an if statement.
  void ifStatement_end(bool hasElse);

  /// Call this method after visiting the condition part of an if statement.
  /// [condition] should be the if statement's condition.
  void ifStatement_thenBegin(Expression condition);

  /// Call this method after visiting the initializer of a variable declaration.
  void initialize(
      Variable variable, Type initializerType, Expression initializerExpression,
      {required bool isFinal, required bool isLate});

  /// Return whether the [variable] is definitely assigned in the current state.
  bool isAssigned(Variable variable);

  /// Call this method after visiting the LHS of an "is" expression.
  ///
  /// [isExpression] should be the complete expression.  [subExpression] should
  /// be the expression to which the "is" check was applied.  [isNot] should be
  /// a boolean indicating whether this is an "is" or an "is!" expression.
  /// [type] should be the type being checked.
  void isExpression_end(
      Expression isExpression, Expression subExpression, bool isNot, Type type);

  /// Return whether the [variable] is definitely unassigned in the current
  /// state.
  bool isUnassigned(Variable variable);

  /// Call this method before visiting a labeled statement.
  /// Call [labeledStatement_end] after visiting the statement.
  void labeledStatement_begin(Statement node);

  /// Call this method after visiting a labeled statement.
  void labeledStatement_end();

  /// Call this method just before visiting the initializer of a late variable.
  void lateInitializer_begin(Node node);

  /// Call this method just after visiting the initializer of a late variable.
  void lateInitializer_end();

  /// Call this method before visiting the LHS of a logical binary operation
  /// ("||" or "&&").
  void logicalBinaryOp_begin();

  /// Call this method after visiting the RHS of a logical binary operation
  /// ("||" or "&&").
  /// [wholeExpression] should be the whole logical binary expression.
  /// [rightOperand] should be the RHS.  [isAnd] should indicate whether the
  /// logical operator is "&&" or "||".
  void logicalBinaryOp_end(Expression wholeExpression, Expression rightOperand,
      {required bool isAnd});

  /// Call this method after visiting the LHS of a logical binary operation
  /// ("||" or "&&").
  /// [rightOperand] should be the LHS.  [isAnd] should indicate whether the
  /// logical operator is "&&" or "||".
  void logicalBinaryOp_rightBegin(Expression leftOperand,
      {required bool isAnd});

  /// Call this method after visiting a logical not ("!") expression.
  /// [notExpression] should be the complete expression.  [operand] should be
  /// the subexpression whose logical value is being negated.
  void logicalNot_end(Expression notExpression, Expression operand);

  /// Call this method just after visiting a non-null assertion (`x!`)
  /// expression.
  void nonNullAssert_end(Expression operand);

  /// Call this method after visiting an expression using `?.`.
  void nullAwareAccess_end();

  /// Call this method after visiting a null-aware operator such as `?.`,
  /// `?..`, `?.[`, or `?..[`.
  ///
  /// [target] should be the expression just before the null-aware operator, or
  /// `null` if the null-aware access starts a cascade section.
  ///
  /// [targetType] should be the type of the expression just before the
  /// null-aware operator, and should be non-null even if the null-aware access
  /// starts a cascade section.
  ///
  /// Note that [nullAwareAccess_end] should be called after the conclusion
  /// of any null-shorting that is caused by the `?.`.  So, for example, if the
  /// code being analyzed is `x?.y?.z(x)`, [nullAwareAccess_rightBegin] should
  /// be called once upon reaching each `?.`, but [nullAwareAccess_end] should
  /// not be called until after processing the method call to `z(x)`.
  void nullAwareAccess_rightBegin(Expression? target, Type targetType);

  /// Call this method when encountering an expression that is a `null` literal.
  void nullLiteral(Expression expression);

  /// Call this method just after visiting a parenthesized expression.
  ///
  /// This is only necessary if the implementation uses a different [Expression]
  /// object to represent a parenthesized expression and its contents.
  void parenthesizedExpression(
      Expression outerExpression, Expression innerExpression);

  /// Attempt to promote [variable] to [type].  The client may use this to
  /// ensure that a variable declaration of the form `var x = expr;` promotes
  /// `x` to type `X&T` in the circumstance where the type of `expr` is `X&T`.
  void promote(Variable variable, Type type);

  /// Retrieves the type that the [variable] is promoted to, if the [variable]
  /// is currently promoted.  Otherwise returns `null`.
  Type? promotedType(Variable variable);

  /// Retrieves the SSA node associated with [variable], or `null` if [variable]
  /// is not associated with an SSA node because it is write captured.  For
  /// testing only.
  @visibleForTesting
  SsaNode<Variable, Type>? ssaNodeForTesting(Variable variable);

  /// Call this method just before visiting one of the cases in the body of a
  /// switch statement.  See [switchStatement_expressionEnd] for details.
  ///
  /// [hasLabel] indicates whether the case has any labels.
  ///
  /// [node] should be the same node that was passed to
  /// [AssignedVariables.endNode] for the switch statement.
  void switchStatement_beginCase(bool hasLabel, Node node);

  /// Call this method just after visiting the body of a switch statement.  See
  /// [switchStatement_expressionEnd] for details.
  ///
  /// [isExhaustive] indicates whether the switch statement had a "default"
  /// case, or is based on an enumeration and all the enumeration constants
  /// were listed in cases.
  void switchStatement_end(bool isExhaustive);

  /// Call this method just after visiting the expression part of a switch
  /// statement.
  ///
  /// The order of visiting a switch statement should be:
  /// - Visit the switch expression.
  /// - Call [switchStatement_expressionEnd].
  /// - For each switch case (including the default case, if any):
  ///   - Call [switchStatement_beginCase].
  ///   - Visit the case.
  /// - Call [switchStatement_end].
  void switchStatement_expressionEnd(Statement switchStatement);

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
  void tryCatchStatement_bodyBegin();

  /// Call this method just after visiting the body of a "try/catch" statement.
  /// See [tryCatchStatement_bodyBegin] for details.
  ///
  /// [body] should be the same node that was passed to
  /// [AssignedVariables.endNode] for the "try" part of the try/catch statement.
  void tryCatchStatement_bodyEnd(Node body);

  /// Call this method just before visiting a catch clause of a "try/catch"
  /// statement.  See [tryCatchStatement_bodyBegin] for details.
  ///
  /// [exceptionVariable] should be the exception variable declared by the catch
  /// clause, or `null` if there is no exception variable.  Similar for
  /// [stackTraceVariable].
  void tryCatchStatement_catchBegin(
      Variable? exceptionVariable, Variable? stackTraceVariable);

  /// Call this method just after visiting a catch clause of a "try/catch"
  /// statement.  See [tryCatchStatement_bodyBegin] for details.
  void tryCatchStatement_catchEnd();

  /// Call this method just after visiting a "try/catch" statement.  See
  /// [tryCatchStatement_bodyBegin] for details.
  void tryCatchStatement_end();

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
  /// See [tryFinallyStatement_bodyBegin] for details.
  ///
  /// [finallyBlock] should be the same node that was passed to
  /// [AssignedVariables.endNode] for the "finally" part of the try/finally
  /// statement.
  void tryFinallyStatement_end(Node finallyBlock);

  /// Call this method just before visiting the finally block of a "try/finally"
  /// statement.  See [tryFinallyStatement_bodyBegin] for details.
  ///
  /// [body] should be the same node that was passed to
  /// [AssignedVariables.endNode] for the "try" part of the try/finally
  /// statement.
  void tryFinallyStatement_finallyBegin(Node body);

  /// Call this method when encountering an expression that reads the value of
  /// a variable.
  ///
  /// If the variable's type is currently promoted, the promoted type is
  /// returned.  Otherwise `null` is returned.
  Type? variableRead(Expression expression, Variable variable);

  /// Call this method after visiting the condition part of a "while" statement.
  /// [whileStatement] should be the full while statement.  [condition] should
  /// be the condition part of the while statement.
  void whileStatement_bodyBegin(Statement whileStatement, Expression condition);

  /// Call this method before visiting the condition part of a "while"
  /// statement.
  ///
  /// [node] should be the same node that was passed to
  /// [AssignedVariables.endNode] for the while statement.
  void whileStatement_conditionBegin(Node node);

  /// Call this method after visiting a "while" statement.
  void whileStatement_end();

  /// Register write of the given [variable] in the current state.
  /// [writtenType] should be the type of the value that was written.
  /// [writtenExpression] should be the expression that was written, or `null`
  /// if the expression that was written is not directly represented in the
  /// source code (this happens, for example, with compound assignments and with
  /// for-each loops).
  ///
  /// This should also be used for the implicit write to a non-final variable in
  /// its initializer, to ensure that the type is promoted to non-nullable if
  /// necessary; in this case, [viaInitializer] should be `true`.
  void write(
      Variable variable, Type writtenType, Expression? writtenExpression);
}

/// Alternate implementation of [FlowAnalysis] that prints out inputs and output
/// at the API boundary, for assistance in debugging.
class FlowAnalysisDebug<Node extends Object, Statement extends Node,
        Expression extends Object, Variable extends Object, Type extends Object>
    implements FlowAnalysis<Node, Statement, Expression, Variable, Type> {
  _FlowAnalysisImpl<Node, Statement, Expression, Variable, Type> _wrapped;

  bool _exceptionOccurred = false;

  factory FlowAnalysisDebug(TypeOperations<Variable, Type> typeOperations,
      AssignedVariables<Node, Variable> assignedVariables,
      {bool allowLocalBooleanVarsToPromote = false}) {
    print('FlowAnalysisDebug()');
    return new FlowAnalysisDebug._(new _FlowAnalysisImpl(
        typeOperations, assignedVariables,
        allowLocalBooleanVarsToPromote: allowLocalBooleanVarsToPromote));
  }

  FlowAnalysisDebug._(this._wrapped);

  @override
  bool get isReachable =>
      _wrap('isReachable', () => _wrapped.isReachable, isQuery: true);

  @override
  void asExpression_end(Expression subExpression, Type type) {
    _wrap('asExpression_end($subExpression, $type)',
        () => _wrapped.asExpression_end(subExpression, type));
  }

  @override
  void assert_afterCondition(Expression condition) {
    _wrap('assert_afterCondition($condition)',
        () => _wrapped.assert_afterCondition(condition));
  }

  @override
  void assert_begin() {
    _wrap('assert_begin()', () => _wrapped.assert_begin());
  }

  @override
  void assert_end() {
    _wrap('assert_end()', () => _wrapped.assert_end());
  }

  @override
  void booleanLiteral(Expression expression, bool value) {
    _wrap('booleanLiteral($expression, $value)',
        () => _wrapped.booleanLiteral(expression, value));
  }

  @override
  void conditional_conditionBegin() {
    _wrap('conditional_conditionBegin()',
        () => _wrapped.conditional_conditionBegin());
  }

  @override
  void conditional_elseBegin(Expression thenExpression) {
    _wrap('conditional_elseBegin($thenExpression',
        () => _wrapped.conditional_elseBegin(thenExpression));
  }

  @override
  void conditional_end(
      Expression conditionalExpression, Expression elseExpression) {
    _wrap('conditional_end($conditionalExpression, $elseExpression',
        () => _wrapped.conditional_end(conditionalExpression, elseExpression));
  }

  @override
  void conditional_thenBegin(Expression condition) {
    _wrap('conditional_thenBegin($condition)',
        () => _wrapped.conditional_thenBegin(condition));
  }

  @override
  void declare(Variable variable, bool initialized) {
    _wrap('declare($variable, $initialized)',
        () => _wrapped.declare(variable, initialized));
  }

  @override
  void doStatement_bodyBegin(Statement doStatement) {
    return _wrap('doStatement_bodyBegin($doStatement)',
        () => _wrapped.doStatement_bodyBegin(doStatement));
  }

  @override
  void doStatement_conditionBegin() {
    return _wrap('doStatement_conditionBegin()',
        () => _wrapped.doStatement_conditionBegin());
  }

  @override
  void doStatement_end(Expression condition) {
    return _wrap('doStatement_end($condition)',
        () => _wrapped.doStatement_end(condition));
  }

  @override
  void equalityOp_end(Expression wholeExpression, Expression rightOperand,
      Type rightOperandType,
      {bool notEqual = false}) {
    _wrap(
        'equalityOp_end($wholeExpression, $rightOperand, $rightOperandType, '
        'notEqual: $notEqual)',
        () => _wrapped.equalityOp_end(
            wholeExpression, rightOperand, rightOperandType,
            notEqual: notEqual));
  }

  @override
  void equalityOp_rightBegin(Expression leftOperand, Type leftOperandType) {
    _wrap('equalityOp_rightBegin($leftOperand, $leftOperandType)',
        () => _wrapped.equalityOp_rightBegin(leftOperand, leftOperandType));
  }

  @override
  ExpressionInfo<Variable, Type>? expressionInfoForTesting(Expression target) {
    return _wrap('expressionInfoForTesting($target)',
        () => _wrapped.expressionInfoForTesting(target),
        isQuery: true);
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
  void for_bodyBegin(Statement? node, Expression? condition) {
    _wrap('for_bodyBegin($node, $condition)',
        () => _wrapped.for_bodyBegin(node, condition));
  }

  @override
  void for_conditionBegin(Node node) {
    _wrap('for_conditionBegin($node)', () => _wrapped.for_conditionBegin(node));
  }

  @override
  void for_end() {
    _wrap('for_end()', () => _wrapped.for_end());
  }

  @override
  void for_updaterBegin() {
    _wrap('for_updaterBegin()', () => _wrapped.for_updaterBegin());
  }

  @override
  void forEach_bodyBegin(Node node, Variable? loopVariable, Type writtenType) {
    return _wrap('forEach_bodyBegin($node, $loopVariable, $writtenType)',
        () => _wrapped.forEach_bodyBegin(node, loopVariable, writtenType));
  }

  @override
  void forEach_end() {
    return _wrap('forEach_end()', () => _wrapped.forEach_end());
  }

  @override
  void forwardExpression(Expression newExpression, Expression oldExpression) {
    return _wrap('forwardExpression($newExpression, $oldExpression)',
        () => _wrapped.forwardExpression(newExpression, oldExpression));
  }

  @override
  void functionExpression_begin(Node node) {
    _wrap('functionExpression_begin($node)',
        () => _wrapped.functionExpression_begin(node));
  }

  @override
  void functionExpression_end() {
    _wrap('functionExpression_end()', () => _wrapped.functionExpression_end());
  }

  @override
  void handleBreak(Statement target) {
    _wrap('handleBreak($target)', () => _wrapped.handleBreak(target));
  }

  @override
  void handleContinue(Statement target) {
    _wrap('handleContinue($target)', () => _wrapped.handleContinue(target));
  }

  @override
  void handleExit() {
    _wrap('handleExit()', () => _wrapped.handleExit());
  }

  @override
  void ifNullExpression_end() {
    return _wrap(
        'ifNullExpression_end()', () => _wrapped.ifNullExpression_end());
  }

  @override
  void ifNullExpression_rightBegin(
      Expression leftHandSide, Type leftHandSideType) {
    _wrap(
        'ifNullExpression_rightBegin($leftHandSide, $leftHandSideType)',
        () => _wrapped.ifNullExpression_rightBegin(
            leftHandSide, leftHandSideType));
  }

  @override
  void ifStatement_conditionBegin() {
    return _wrap('ifStatement_conditionBegin()',
        () => _wrapped.ifStatement_conditionBegin());
  }

  @override
  void ifStatement_elseBegin() {
    return _wrap(
        'ifStatement_elseBegin()', () => _wrapped.ifStatement_elseBegin());
  }

  @override
  void ifStatement_end(bool hasElse) {
    _wrap('ifStatement_end($hasElse)', () => _wrapped.ifStatement_end(hasElse));
  }

  @override
  void ifStatement_thenBegin(Expression condition) {
    _wrap('ifStatement_thenBegin($condition)',
        () => _wrapped.ifStatement_thenBegin(condition));
  }

  @override
  void initialize(
      Variable variable, Type initializerType, Expression initializerExpression,
      {required bool isFinal, required bool isLate}) {
    _wrap(
        'initialize($variable, $initializerType, $initializerExpression, '
        'isFinal: $isFinal, isLate: $isLate)',
        () => _wrapped.initialize(
            variable, initializerType, initializerExpression,
            isFinal: isFinal, isLate: isLate));
  }

  @override
  bool isAssigned(Variable variable) {
    return _wrap('isAssigned($variable)', () => _wrapped.isAssigned(variable),
        isQuery: true);
  }

  @override
  void isExpression_end(Expression isExpression, Expression subExpression,
      bool isNot, Type type) {
    _wrap(
        'isExpression_end($isExpression, $subExpression, $isNot, $type)',
        () => _wrapped.isExpression_end(
            isExpression, subExpression, isNot, type));
  }

  @override
  bool isUnassigned(Variable variable) {
    return _wrap(
        'isUnassigned($variable)', () => _wrapped.isUnassigned(variable),
        isQuery: true);
  }

  @override
  void labeledStatement_begin(Statement node) {
    return _wrap('labeledStatement_begin($node)',
        () => _wrapped.labeledStatement_begin(node));
  }

  @override
  void labeledStatement_end() {
    return _wrap(
        'labeledStatement_end()', () => _wrapped.labeledStatement_end());
  }

  @override
  void lateInitializer_begin(Node node) {
    _wrap('lateInitializer_begin($node)',
        () => _wrapped.lateInitializer_begin(node));
  }

  @override
  void lateInitializer_end() {
    _wrap('lateInitializer_end()', () => _wrapped.lateInitializer_end());
  }

  @override
  void logicalBinaryOp_begin() {
    _wrap('logicalBinaryOp_begin()', () => _wrapped.logicalBinaryOp_begin());
  }

  @override
  void logicalBinaryOp_end(Expression wholeExpression, Expression rightOperand,
      {required bool isAnd}) {
    _wrap(
        'logicalBinaryOp_end($wholeExpression, $rightOperand, isAnd: $isAnd)',
        () => _wrapped.logicalBinaryOp_end(wholeExpression, rightOperand,
            isAnd: isAnd));
  }

  @override
  void logicalBinaryOp_rightBegin(Expression leftOperand,
      {required bool isAnd}) {
    _wrap('logicalBinaryOp_rightBegin($leftOperand, isAnd: $isAnd)',
        () => _wrapped.logicalBinaryOp_rightBegin(leftOperand, isAnd: isAnd));
  }

  @override
  void logicalNot_end(Expression notExpression, Expression operand) {
    return _wrap('logicalNot_end($notExpression, $operand)',
        () => _wrapped.logicalNot_end(notExpression, operand));
  }

  @override
  void nonNullAssert_end(Expression operand) {
    return _wrap('nonNullAssert_end($operand)',
        () => _wrapped.nonNullAssert_end(operand));
  }

  @override
  void nullAwareAccess_end() {
    _wrap('nullAwareAccess_end()', () => _wrapped.nullAwareAccess_end());
  }

  @override
  void nullAwareAccess_rightBegin(Expression? target, Type targetType) {
    _wrap('nullAwareAccess_rightBegin($target, $targetType)',
        () => _wrapped.nullAwareAccess_rightBegin(target, targetType));
  }

  @override
  void nullLiteral(Expression expression) {
    _wrap('nullLiteral($expression)', () => _wrapped.nullLiteral(expression));
  }

  @override
  void parenthesizedExpression(
      Expression outerExpression, Expression innerExpression) {
    _wrap(
        'parenthesizedExpression($outerExpression, $innerExpression)',
        () =>
            _wrapped.parenthesizedExpression(outerExpression, innerExpression));
  }

  @override
  void promote(Variable variable, Type type) {
    _wrap('promote($variable, $type', () => _wrapped.promote(variable, type));
  }

  @override
  Type? promotedType(Variable variable) {
    return _wrap(
        'promotedType($variable)', () => _wrapped.promotedType(variable),
        isQuery: true);
  }

  @override
  SsaNode<Variable, Type>? ssaNodeForTesting(Variable variable) {
    return _wrap('ssaNodeForTesting($variable)',
        () => _wrapped.ssaNodeForTesting(variable),
        isQuery: true);
  }

  @override
  void switchStatement_beginCase(bool hasLabel, Node node) {
    _wrap('switchStatement_beginCase($hasLabel, $node)',
        () => _wrapped.switchStatement_beginCase(hasLabel, node));
  }

  @override
  void switchStatement_end(bool isExhaustive) {
    _wrap('switchStatement_end($isExhaustive)',
        () => _wrapped.switchStatement_end(isExhaustive));
  }

  @override
  void switchStatement_expressionEnd(Statement switchStatement) {
    _wrap('switchStatement_expressionEnd($switchStatement)',
        () => _wrapped.switchStatement_expressionEnd(switchStatement));
  }

  @override
  void tryCatchStatement_bodyBegin() {
    return _wrap('tryCatchStatement_bodyBegin()',
        () => _wrapped.tryCatchStatement_bodyBegin());
  }

  @override
  void tryCatchStatement_bodyEnd(Node body) {
    return _wrap('tryCatchStatement_bodyEnd($body)',
        () => _wrapped.tryCatchStatement_bodyEnd(body));
  }

  @override
  void tryCatchStatement_catchBegin(
      Variable? exceptionVariable, Variable? stackTraceVariable) {
    return _wrap(
        'tryCatchStatement_catchBegin($exceptionVariable, $stackTraceVariable)',
        () => _wrapped.tryCatchStatement_catchBegin(
            exceptionVariable, stackTraceVariable));
  }

  @override
  void tryCatchStatement_catchEnd() {
    return _wrap('tryCatchStatement_catchEnd()',
        () => _wrapped.tryCatchStatement_catchEnd());
  }

  @override
  void tryCatchStatement_end() {
    return _wrap(
        'tryCatchStatement_end()', () => _wrapped.tryCatchStatement_end());
  }

  @override
  void tryFinallyStatement_bodyBegin() {
    return _wrap('tryFinallyStatement_bodyBegin()',
        () => _wrapped.tryFinallyStatement_bodyBegin());
  }

  @override
  void tryFinallyStatement_end(Node finallyBlock) {
    return _wrap('tryFinallyStatement_end($finallyBlock)',
        () => _wrapped.tryFinallyStatement_end(finallyBlock));
  }

  @override
  void tryFinallyStatement_finallyBegin(Node body) {
    return _wrap('tryFinallyStatement_finallyBegin($body)',
        () => _wrapped.tryFinallyStatement_finallyBegin(body));
  }

  @override
  Type? variableRead(Expression expression, Variable variable) {
    return _wrap('variableRead($expression, $variable)',
        () => _wrapped.variableRead(expression, variable),
        isQuery: true, isPure: false);
  }

  @override
  void whileStatement_bodyBegin(
      Statement whileStatement, Expression condition) {
    return _wrap('whileStatement_bodyBegin($whileStatement, $condition)',
        () => _wrapped.whileStatement_bodyBegin(whileStatement, condition));
  }

  @override
  void whileStatement_conditionBegin(Node node) {
    return _wrap('whileStatement_conditionBegin($node)',
        () => _wrapped.whileStatement_conditionBegin(node));
  }

  @override
  void whileStatement_end() {
    return _wrap('whileStatement_end()', () => _wrapped.whileStatement_end());
  }

  @override
  void write(
      Variable variable, Type writtenType, Expression? writtenExpression) {
    _wrap('write($variable, $writtenType, $writtenExpression)',
        () => _wrapped.write(variable, writtenType, writtenExpression));
  }

  T _wrap<T>(String description, T callback(),
      {bool isQuery: false, bool? isPure}) {
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
      print('  => $result');
    }
    return result;
  }
}

/// An instance of the [FlowModel] class represents the information gathered by
/// flow analysis at a single point in the control flow of the function or
/// method being analyzed.
///
/// Instances of this class are immutable, so the methods below that "update"
/// the state actually leave `this` unchanged and return a new state object.
@visibleForTesting
class FlowModel<Variable extends Object, Type extends Object> {
  final Reachability reachable;

  /// For each variable being tracked by flow analysis, the variable's model.
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
  final Map<Variable, VariableModel<Variable, Type> /*!*/ > variableInfo;

  /// The empty map, used to [join] variables.
  final Map<Variable, VariableModel<Variable, Type>> _emptyVariableMap = {};

  /// Creates a state object with the given [reachable] status.  All variables
  /// are assumed to be unpromoted and already assigned, so joining another
  /// state with this one will have no effect on it.
  FlowModel(Reachability reachable)
      : this.withInfo(
          reachable,
          const {},
        );

  @visibleForTesting
  FlowModel.withInfo(this.reachable, this.variableInfo) {
    // ignore:unnecessary_null_comparison
    assert(reachable != null);
    assert(() {
      for (VariableModel<Variable, Type> value in variableInfo.values) {
        // ignore:unnecessary_null_comparison
        assert(value != null);
      }
      return true;
    }());
  }

  /// Computes the effect of executing a try/finally's `try` and `finally`
  /// blocks in sequence.  `this` is the flow analysis state from the end of the
  /// `try` block; [beforeFinally] and [afterFinally] are the flow analysis
  /// states from the top and bottom of the `finally` block, respectively.
  ///
  /// Initially the `finally` block is analyzed under the conservative
  /// assumption that the `try` block might have been interrupted at any point
  /// by an exception occurring, therefore no variable assignments or promotions
  /// that occurred in the `try` block can be relied upon.  As a result, when we
  /// get to the end of processing the `finally` block, the only promotions and
  /// variable assignments accounted for by flow analysis are the ones performed
  /// within the `finally` block itself.  However, when we analyze code that
  /// follows the `finally` block, we know that the `try` block did *not* throw
  /// an exception, so we want to reinstate the results of any promotions and
  /// assignments that occurred during the `try` block, to the extent that they
  /// weren't invalidated by later assignments in the `finally` block.
  FlowModel<Variable, Type> attachFinally(
      TypeOperations<Variable, Type> typeOperations,
      FlowModel<Variable, Type> beforeFinally,
      FlowModel<Variable, Type> afterFinally) {
    // Code that follows the `try/finally` is reachable iff the end of the `try`
    // block is reachable _and_ the end of the `finally` block is reachable.
    Reachability newReachable = afterFinally.reachable.rebaseForward(reachable);

    // Consider each variable that is common to all three models.
    Map<Variable, VariableModel<Variable, Type>> newVariableInfo =
        <Variable, VariableModel<Variable, Type>>{};
    bool variableInfoMatchesThis = true;
    bool variableInfoMatchesAfterFinally = true;
    for (MapEntry<Variable, VariableModel<Variable, Type>> entry
        in variableInfo.entries) {
      Variable variable = entry.key;
      VariableModel<Variable, Type> thisModel = entry.value;
      VariableModel<Variable, Type>? beforeFinallyModel =
          beforeFinally.variableInfo[variable];
      VariableModel<Variable, Type>? afterFinallyModel =
          afterFinally.variableInfo[variable];
      if (beforeFinallyModel == null || afterFinallyModel == null) {
        // The variable is in `this` model but not in one of the `finally`
        // models.  This happens when the variable is declared inside the `try`
        // block.  We can just drop the variable because it won't be in scope
        // after the try/finally statement.
        variableInfoMatchesThis = false;
        continue;
      }
      // We can just use the "write captured" state from the `finally` block,
      // because any write captures in the `try` block are conservatively
      // considered to take effect in the `finally` block too.
      List<Type>? newPromotedTypes;
      SsaNode<Variable, Type>? newSsaNode;
      if (beforeFinallyModel.ssaNode == afterFinallyModel.ssaNode) {
        // The finally clause doesn't write to the variable, so we want to keep
        // all promotions that were done to it in both the try and finally
        // blocks.
        newPromotedTypes = VariableModel.rebasePromotedTypes(typeOperations,
            thisModel.promotedTypes, afterFinallyModel.promotedTypes);
        // And we can safely restore the SSA node from the end of the try block.
        newSsaNode = thisModel.ssaNode;
      } else {
        // A write to the variable occurred in the finally block, so promotions
        // from the try block aren't necessarily valid.
        newPromotedTypes = afterFinallyModel.promotedTypes;
        // And we can't safely restore the SSA node from the end of the try
        // block; we need to keep the one from the end of the finally block.
        newSsaNode = afterFinallyModel.ssaNode;
      }
      // The `finally` block inherited all tests from the `try` block so we can
      // just inherit tests from it.
      List<Type> newTested = afterFinallyModel.tested;
      // The variable is definitely assigned if it was definitely assigned in
      // either the `try` or the `finally` block.
      bool newAssigned = thisModel.assigned || afterFinallyModel.assigned;
      // The `finally` block inherited the "unassigned" state from the `try`
      // block so we can just inherit from it.
      bool newUnassigned = afterFinallyModel.unassigned;
      VariableModel<Variable, Type> newModel = VariableModel._identicalOrNew(
          thisModel,
          afterFinallyModel,
          newPromotedTypes,
          newTested,
          newAssigned,
          newUnassigned,
          newSsaNode);
      newVariableInfo[variable] = newModel;
      if (!identical(newModel, thisModel)) variableInfoMatchesThis = false;
      if (!identical(newModel, afterFinallyModel)) {
        variableInfoMatchesAfterFinally = false;
      }
    }
    // newVariableInfo is now correct.  However, if there are any variables
    // present in `afterFinally` that aren't present in `this`, we may
    // erroneously think that `newVariableInfo` matches `afterFinally`.  If so,
    // correct that.
    if (variableInfoMatchesAfterFinally) {
      for (Variable variable in afterFinally.variableInfo.keys) {
        if (!variableInfo.containsKey(variable)) {
          variableInfoMatchesAfterFinally = false;
          break;
        }
      }
    }
    assert(variableInfoMatchesThis ==
        _variableInfosEqual(newVariableInfo, variableInfo));
    assert(variableInfoMatchesAfterFinally ==
        _variableInfosEqual(newVariableInfo, afterFinally.variableInfo));
    if (variableInfoMatchesThis) {
      newVariableInfo = variableInfo;
    } else if (variableInfoMatchesAfterFinally) {
      newVariableInfo = afterFinally.variableInfo;
    }

    return _identicalOrNew(this, afterFinally, newReachable, newVariableInfo);
  }

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
  FlowModel<Variable, Type> conservativeJoin(
      Iterable<Variable> writtenVariables,
      Iterable<Variable> capturedVariables) {
    Map<Variable, VariableModel<Variable, Type>>? newVariableInfo;

    for (Variable variable in writtenVariables) {
      VariableModel<Variable, Type> info = infoFor(variable);
      VariableModel<Variable, Type> newInfo =
          info.discardPromotionsAndMarkNotUnassigned();
      if (!identical(info, newInfo)) {
        (newVariableInfo ??=
            new Map<Variable, VariableModel<Variable, Type>>.from(
                variableInfo))[variable] = newInfo;
      }
    }

    for (Variable variable in capturedVariables) {
      VariableModel<Variable, Type>? info = variableInfo[variable];
      if (info == null) {
        (newVariableInfo ??=
            new Map<Variable, VariableModel<Variable, Type>>.from(
                variableInfo))[variable] = new VariableModel<Variable, Type>(
            promotedTypes: null,
            tested: const [],
            assigned: false,
            unassigned: false,
            ssaNode: null);
      } else if (!info.writeCaptured) {
        (newVariableInfo ??=
            new Map<Variable, VariableModel<Variable, Type>>.from(
                variableInfo))[variable] = info.writeCapture();
      }
    }

    FlowModel<Variable, Type> result = newVariableInfo == null
        ? this
        : new FlowModel<Variable, Type>.withInfo(reachable, newVariableInfo);

    return result;
  }

  /// Register a declaration of the [variable].
  /// Should also be called for function parameters.
  ///
  /// A local variable is [initialized] if its declaration has an initializer.
  /// A function parameter is always initialized, so [initialized] is `true`.
  FlowModel<Variable, Type> declare(Variable variable, bool initialized) {
    VariableModel<Variable, Type> newInfoForVar =
        new VariableModel.fresh(assigned: initialized);

    return _updateVariableInfo(variable, newInfoForVar);
  }

  /// Gets the info for the given [variable], creating it if it doesn't exist.
  VariableModel<Variable, Type> infoFor(Variable variable) =>
      variableInfo[variable] ?? new VariableModel.fresh();

  /// Builds a [FlowModel] based on `this`, but extending the `tested` set to
  /// include types from [other].  This is used at the bottom of certain kinds
  /// of loops, to ensure that types tested within the body of the loop are
  /// consistently treated as "of interest" in code that follows the loop,
  /// regardless of the type of loop.
  @visibleForTesting
  FlowModel<Variable, Type> inheritTested(
      TypeOperations<Variable, Type> typeOperations,
      FlowModel<Variable, Type> other) {
    Map<Variable, VariableModel<Variable, Type>> newVariableInfo =
        <Variable, VariableModel<Variable, Type>>{};
    Map<Variable, VariableModel<Variable, Type>> otherVariableInfo =
        other.variableInfo;
    bool changed = false;
    for (MapEntry<Variable, VariableModel<Variable, Type>> entry
        in variableInfo.entries) {
      Variable variable = entry.key;
      VariableModel<Variable, Type> variableModel = entry.value;
      VariableModel<Variable, Type>? otherVariableModel =
          otherVariableInfo[variable];
      VariableModel<Variable, Type> newVariableModel =
          otherVariableModel == null
              ? variableModel
              : VariableModel.inheritTested(
                  typeOperations, variableModel, otherVariableModel.tested);
      newVariableInfo[variable] = newVariableModel;
      if (!identical(newVariableModel, variableModel)) changed = true;
    }
    if (changed) {
      return new FlowModel<Variable, Type>.withInfo(reachable, newVariableInfo);
    } else {
      return this;
    }
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
  FlowModel<Variable, Type> rebaseForward(
      TypeOperations<Variable, Type> typeOperations,
      FlowModel<Variable, Type> base) {
    // The rebased model is reachable iff both `this` and the new base are
    // reachable.
    Reachability newReachable = reachable.rebaseForward(base.reachable);

    // Consider each variable in the new base model.
    Map<Variable, VariableModel<Variable, Type>> newVariableInfo =
        <Variable, VariableModel<Variable, Type>>{};
    bool variableInfoMatchesThis = true;
    bool variableInfoMatchesBase = true;
    for (MapEntry<Variable, VariableModel<Variable, Type>> entry
        in base.variableInfo.entries) {
      Variable variable = entry.key;
      VariableModel<Variable, Type> baseModel = entry.value;
      VariableModel<Variable, Type>? thisModel = variableInfo[variable];
      if (thisModel == null) {
        // The variable has newly came into scope since `thisModel`, so the
        // information in `baseModel` is up to date.
        newVariableInfo[variable] = baseModel;
        variableInfoMatchesThis = false;
        continue;
      }
      // If the variable was write captured in either `this` or the new base,
      // it's captured now.
      bool newWriteCaptured =
          thisModel.writeCaptured || baseModel.writeCaptured;
      List<Type>? newPromotedTypes;
      if (newWriteCaptured) {
        // Write captured variables can't be promoted.
        newPromotedTypes = null;
      } else if (baseModel.ssaNode != thisModel.ssaNode) {
        // The variable may have been written to since `thisModel`, so we can't
        // use any of the promotions from `thisModel`.
        newPromotedTypes = baseModel.promotedTypes;
      } else {
        // The variable hasn't been written to since `thisModel`, so we can keep
        // all of the promotions from `thisModel`, provided that we retain the
        // usual "promotion chain" invariant (each promoted type is a subtype of
        // the previous).
        newPromotedTypes = VariableModel.rebasePromotedTypes(
            typeOperations, thisModel.promotedTypes, baseModel.promotedTypes);
      }
      // Tests are kept regardless of whether they are in `this` model or the
      // new base model.
      List<Type> newTested = VariableModel.joinTested(
          thisModel.tested, baseModel.tested, typeOperations);
      // The variable is definitely assigned if it was definitely assigned
      // either in `this` model or the new base model.
      bool newAssigned = thisModel.assigned || baseModel.assigned;
      // The variable is definitely unassigned if it was definitely unassigned
      // in both `this` model and the new base model.
      bool newUnassigned = thisModel.unassigned && baseModel.unassigned;
      VariableModel<Variable, Type> newModel = VariableModel._identicalOrNew(
          thisModel,
          baseModel,
          newPromotedTypes,
          newTested,
          newAssigned,
          newUnassigned,
          newWriteCaptured ? null : baseModel.ssaNode);
      newVariableInfo[variable] = newModel;
      if (!identical(newModel, thisModel)) variableInfoMatchesThis = false;
      if (!identical(newModel, baseModel)) variableInfoMatchesBase = false;
    }
    // newVariableInfo is now correct.  However, if there are any variables
    // present in `this` that aren't present in `base`, we may erroneously think
    // that `newVariableInfo` matches `this`.  If so, correct that.
    if (variableInfoMatchesThis) {
      for (Variable variable in variableInfo.keys) {
        if (!base.variableInfo.containsKey(variable)) {
          variableInfoMatchesThis = false;
          break;
        }
      }
    }
    assert(variableInfoMatchesThis ==
        _variableInfosEqual(newVariableInfo, variableInfo));
    assert(variableInfoMatchesBase ==
        _variableInfosEqual(newVariableInfo, base.variableInfo));
    if (variableInfoMatchesThis) {
      newVariableInfo = variableInfo;
    } else if (variableInfoMatchesBase) {
      newVariableInfo = base.variableInfo;
    }

    return _identicalOrNew(this, base, newReachable, newVariableInfo);
  }

  /// Updates the state to reflect a control path that is known to have
  /// previously passed through some [other] state.
  ///
  /// Approximately, this method forms the union of the definite assignments and
  /// promotions in `this` state and the [other] state.  More precisely:
  ///
  /// The control flow path is considered reachable if both this state and the
  /// other state are reachable.  Variables are considered definitely assigned
  /// if they were definitely assigned in either this state or the other state.
  /// Variable type promotions are taken from this state, unless the promotion
  /// in the other state is more specific, and the variable is "safe".  A
  /// variable is considered safe if there is no chance that it was assigned
  /// more recently than the "other" state.
  ///
  /// This is used after a `try/finally` statement to combine the promotions and
  /// definite assignments that occurred in the `try` and `finally` blocks
  /// (where `this` is the state from the `finally` block and `other` is the
  /// state from the `try` block).  Variables that are assigned in the `finally`
  /// block are considered "unsafe" because the assignment might have cancelled
  /// the effect of any promotion that occurred inside the `try` block.
  FlowModel<Variable, Type> restrict(
      TypeOperations<Variable, Type> typeOperations,
      FlowModel<Variable, Type> other,
      Set<Variable> unsafe) {
    if (allowLocalBooleanVarsToPromoteByDefault) {
      // TODO(paulberry): when we hardcode
      // allowLocalBooleanVarsToPromoteByDefault to `true`, we should remove
      // this method entirely.
      throw new StateError('This method should not be called anymore');
    }
    Reachability newReachable =
        Reachability.restrict(reachable, other.reachable);

    Map<Variable, VariableModel<Variable, Type>> newVariableInfo =
        <Variable, VariableModel<Variable, Type>>{};
    bool variableInfoMatchesThis = true;
    bool variableInfoMatchesOther = true;
    for (MapEntry<Variable, VariableModel<Variable, Type>> entry
        in variableInfo.entries) {
      Variable variable = entry.key;
      VariableModel<Variable, Type> thisModel = entry.value;
      VariableModel<Variable, Type>? otherModel = other.variableInfo[variable];
      if (otherModel == null) {
        variableInfoMatchesThis = false;
        continue;
      }
      VariableModel<Variable, Type> restricted = thisModel.restrict(
          typeOperations, otherModel, unsafe.contains(variable));
      newVariableInfo[variable] = restricted;
      if (!identical(restricted, thisModel)) variableInfoMatchesThis = false;
      if (!identical(restricted, otherModel)) variableInfoMatchesOther = false;
    }
    if (variableInfoMatchesOther) {
      for (Variable variable in other.variableInfo.keys) {
        if (!variableInfo.containsKey(variable)) {
          variableInfoMatchesOther = false;
          break;
        }
      }
    }
    assert(variableInfoMatchesThis ==
        _variableInfosEqual(newVariableInfo, variableInfo));
    assert(variableInfoMatchesOther ==
        _variableInfosEqual(newVariableInfo, other.variableInfo));
    if (variableInfoMatchesThis) {
      newVariableInfo = variableInfo;
    } else if (variableInfoMatchesOther) {
      newVariableInfo = other.variableInfo;
    }

    return _identicalOrNew(this, other, newReachable, newVariableInfo);
  }

  /// Updates the state to indicate that the control flow path is unreachable.
  FlowModel<Variable, Type> setUnreachable() {
    if (!reachable.locallyReachable) return this;

    return new FlowModel<Variable, Type>.withInfo(
        reachable.setUnreachable(), variableInfo);
  }

  /// Returns a [FlowModel] indicating the result of creating a control flow
  /// split.  See [Reachability.split] for more information.
  FlowModel<Variable, Type> split() =>
      new FlowModel<Variable, Type>.withInfo(reachable.split(), variableInfo);

  @override
  String toString() => '($reachable, $variableInfo)';

  /// Returns an [ExpressionInfo] indicating the result of checking whether the
  /// given [variable] is non-null.
  ///
  /// Note that the state is only changed if the previous type of [variable] was
  /// potentially nullable.
  ExpressionInfo<Variable, Type> tryMarkNonNullable(
      TypeOperations<Variable, Type> typeOperations, Variable variable) {
    VariableModel<Variable, Type> info = infoFor(variable);
    if (info.writeCaptured) {
      return new _TrivialExpressionInfo<Variable, Type>(this);
    }

    Type? previousType = info.promotedTypes?.last;
    previousType ??= typeOperations.variableType(variable);

    Type newType = typeOperations.promoteToNonNull(previousType);
    if (typeOperations.isSameType(newType, previousType)) {
      return new _TrivialExpressionInfo<Variable, Type>(this);
    }
    assert(typeOperations.isSubtypeOf(newType, previousType));

    FlowModel<Variable, Type> modelIfSuccessful =
        _finishTypeTest(typeOperations, variable, info, null, newType);

    FlowModel<Variable, Type> modelIfFailed = this;

    return new ExpressionInfo<Variable, Type>(
        this, modelIfSuccessful, modelIfFailed);
  }

  /// Returns an [ExpressionInfo] indicating the result of casting the given
  /// [variable] to the given [type], as a consequence of an `as` expression.
  ///
  /// Note that the state is only changed if [type] is a subtype of the
  /// variable's previous (possibly promoted) type.
  ///
  /// TODO(paulberry): if the type is non-nullable, should this method mark the
  /// variable as definitely assigned?  Does it matter?
  FlowModel<Variable, Type> tryPromoteForTypeCast(
      TypeOperations<Variable, Type> typeOperations,
      Variable variable,
      Type type) {
    VariableModel<Variable, Type> info = infoFor(variable);
    if (info.writeCaptured) {
      return this;
    }

    Type? previousType = info.promotedTypes?.last;
    previousType ??= typeOperations.variableType(variable);

    Type? newType = typeOperations.tryPromoteToType(type, previousType);
    if (newType == null || typeOperations.isSameType(newType, previousType)) {
      return this;
    }

    assert(typeOperations.isSubtypeOf(newType, previousType),
        "Expected $newType to be a subtype of $previousType.");
    return _finishTypeTest(typeOperations, variable, info, type, newType);
  }

  /// Returns an [ExpressionInfo] indicating the result of checking whether the
  /// given [variable] satisfies the given [type], e.g. as a consequence of an
  /// `is` expression as the condition of an `if` statement.
  ///
  /// Note that the "ifTrue" state is only changed if [type] is a subtype of
  /// the variable's previous (possibly promoted) type.
  ///
  /// TODO(paulberry): if the type is non-nullable, should this method mark the
  /// variable as definitely assigned?  Does it matter?
  ExpressionInfo<Variable, Type> tryPromoteForTypeCheck(
      TypeOperations<Variable, Type> typeOperations,
      Variable variable,
      Type type) {
    VariableModel<Variable, Type> info = infoFor(variable);
    if (info.writeCaptured) {
      return new _TrivialExpressionInfo<Variable, Type>(this);
    }

    Type? previousType = info.promotedTypes?.last;
    previousType ??= typeOperations.variableType(variable);

    FlowModel<Variable, Type> modelIfSuccessful = this;
    Type? typeIfSuccess = typeOperations.tryPromoteToType(type, previousType);
    if (typeIfSuccess != null &&
        !typeOperations.isSameType(typeIfSuccess, previousType)) {
      assert(typeOperations.isSubtypeOf(typeIfSuccess, previousType),
          "Expected $typeIfSuccess to be a subtype of $previousType.");
      modelIfSuccessful =
          _finishTypeTest(typeOperations, variable, info, type, typeIfSuccess);
    }

    Type factoredType = typeOperations.factor(previousType, type);
    Type? typeIfFailed;
    if (typeOperations.isNever(factoredType)) {
      // Promoting to `Never` would mark the code as unreachable.  But it might
      // be reachable due to mixed mode unsoundness.  So don't promote.
      typeIfFailed = null;
    } else if (typeOperations.isSameType(factoredType, previousType)) {
      // No change to the type, so don't promote.
      typeIfFailed = null;
    } else {
      typeIfFailed = factoredType;
    }
    FlowModel<Variable, Type> modelIfFailed =
        _finishTypeTest(typeOperations, variable, info, type, typeIfFailed);

    return new ExpressionInfo<Variable, Type>(
        this, modelIfSuccessful, modelIfFailed);
  }

  /// Returns a [FlowModel] indicating the result of removing a control flow
  /// split.  See [Reachability.unsplit] for more information.
  FlowModel<Variable, Type> unsplit() =>
      new FlowModel<Variable, Type>.withInfo(reachable.unsplit(), variableInfo);

  /// Removes control flow splits until a [FlowModel] is obtained whose
  /// reachability has the given [parent].
  FlowModel<Variable, Type> unsplitTo(Reachability parent) {
    if (identical(this.reachable.parent, parent)) return this;
    Reachability reachable = this.reachable.unsplit();
    while (!identical(reachable.parent, parent)) {
      reachable = reachable.unsplit();
    }
    return new FlowModel<Variable, Type>.withInfo(reachable, variableInfo);
  }

  /// Updates the state to indicate that an assignment was made to the given
  /// [variable].  The variable is marked as definitely assigned, and any
  /// previous type promotion is removed.
  FlowModel<Variable, Type> write(
      Variable variable,
      Type writtenType,
      SsaNode<Variable, Type> newSsaNode,
      TypeOperations<Variable, Type> typeOperations) {
    VariableModel<Variable, Type>? infoForVar = variableInfo[variable];
    if (infoForVar == null) return this;

    VariableModel<Variable, Type> newInfoForVar =
        infoForVar.write(variable, writtenType, typeOperations, newSsaNode);
    if (identical(newInfoForVar, infoForVar)) return this;

    return _updateVariableInfo(variable, newInfoForVar);
  }

  /// Common algorithm for [tryMarkNonNullable], [tryPromoteForTypeCast],
  /// and [tryPromoteForTypeCheck].  Builds a [FlowModel] object describing the
  /// effect of updating the [variable] by adding the [testedType] to the
  /// list of tested types (if not `null`, and not there already), adding the
  /// [promotedType] to the chain of promoted types.
  ///
  /// Preconditions:
  /// - [info] should be the result of calling `infoFor(variable)`
  /// - [promotedType] should be a subtype of the currently-promoted type (i.e.
  ///   no redundant or side-promotions)
  /// - The variable should not be write-captured.
  FlowModel<Variable, Type> _finishTypeTest(
    TypeOperations<Variable, Type> typeOperations,
    Variable variable,
    VariableModel<Variable, Type> info,
    Type? testedType,
    Type? promotedType,
  ) {
    List<Type> newTested = info.tested;
    if (testedType != null) {
      newTested = VariableModel._addTypeToUniqueList(
          info.tested, testedType, typeOperations);
    }

    List<Type>? newPromotedTypes = info.promotedTypes;
    Reachability newReachable = reachable;
    if (promotedType != null) {
      newPromotedTypes =
          VariableModel._addToPromotedTypes(info.promotedTypes, promotedType);
      if (typeOperations.isNever(promotedType)) {
        newReachable = reachable.setUnreachable();
      }
    }

    return identical(newTested, info.tested) &&
            identical(newPromotedTypes, info.promotedTypes) &&
            newReachable == reachable
        ? this
        : _updateVariableInfo(
            variable,
            new VariableModel<Variable, Type>(
                promotedTypes: newPromotedTypes,
                tested: newTested,
                assigned: info.assigned,
                unassigned: info.unassigned,
                ssaNode: info.ssaNode),
            reachable: newReachable);
  }

  /// Returns a new [FlowModel] where the information for [variable] is replaced
  /// with [model].
  FlowModel<Variable, Type> _updateVariableInfo(
      Variable variable, VariableModel<Variable, Type> model,
      {Reachability? reachable}) {
    reachable ??= this.reachable;
    Map<Variable, VariableModel<Variable, Type>> newVariableInfo =
        new Map<Variable, VariableModel<Variable, Type>>.from(variableInfo);
    newVariableInfo[variable] = model;
    return new FlowModel<Variable, Type>.withInfo(reachable, newVariableInfo);
  }

  /// Forms a new state to reflect a control flow path that might have come from
  /// either `this` or the [other] state.
  ///
  /// The control flow path is considered reachable if either of the input
  /// states is reachable.  Variables are considered definitely assigned if they
  /// were definitely assigned in both of the input states.  Variable promotions
  /// are kept only if they are common to both input states; if a variable is
  /// promoted to one type in one state and a subtype in the other state, the
  /// less specific type promotion is kept.
  static FlowModel<Variable, Type>
      join<Variable extends Object, Type extends Object>(
    TypeOperations<Variable, Type> typeOperations,
    FlowModel<Variable, Type>? first,
    FlowModel<Variable, Type>? second,
    Map<Variable, VariableModel<Variable, Type>> emptyVariableMap,
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

    Reachability newReachable =
        Reachability.join(first.reachable, second.reachable);
    Map<Variable, VariableModel<Variable, Type>> newVariableInfo =
        FlowModel.joinVariableInfo(typeOperations, first.variableInfo,
            second.variableInfo, emptyVariableMap);

    return FlowModel._identicalOrNew(
        first, second, newReachable, newVariableInfo);
  }

  /// Joins two "variable info" maps.  See [join] for details.
  @visibleForTesting
  static Map<Variable, VariableModel<Variable, Type>>
      joinVariableInfo<Variable extends Object, Type extends Object>(
    TypeOperations<Variable, Type> typeOperations,
    Map<Variable, VariableModel<Variable, Type>> first,
    Map<Variable, VariableModel<Variable, Type>> second,
    Map<Variable, VariableModel<Variable, Type>> emptyMap,
  ) {
    if (identical(first, second)) return first;
    if (first.isEmpty || second.isEmpty) {
      return emptyMap;
    }

    Map<Variable, VariableModel<Variable, Type>> result =
        <Variable, VariableModel<Variable, Type>>{};
    bool alwaysFirst = true;
    bool alwaysSecond = true;
    for (MapEntry<Variable, VariableModel<Variable, Type>> entry
        in first.entries) {
      Variable variable = entry.key;
      VariableModel<Variable, Type>? secondModel = second[variable];
      if (secondModel == null) {
        alwaysFirst = false;
      } else {
        VariableModel<Variable, Type> joined =
            VariableModel.join<Variable, Type>(
                typeOperations, entry.value, secondModel);
        result[variable] = joined;
        if (!identical(joined, entry.value)) alwaysFirst = false;
        if (!identical(joined, secondModel)) alwaysSecond = false;
      }
    }

    if (alwaysFirst) return first;
    if (alwaysSecond && result.length == second.length) return second;
    if (result.isEmpty) return emptyMap;
    return result;
  }

  /// Models the result of joining the flow models [first] and [second] at the
  /// merge of two control flow paths.
  static FlowModel<Variable, Type>
      merge<Variable extends Object, Type extends Object>(
    TypeOperations<Variable, Type> typeOperations,
    FlowModel<Variable, Type>? first,
    FlowModel<Variable, Type>? second,
    Map<Variable, VariableModel<Variable, Type>> emptyVariableMap,
  ) {
    if (first == null) return second!.unsplit();
    if (second == null) return first.unsplit();

    assert(identical(first.reachable.parent, second.reachable.parent));
    if (first.reachable.locallyReachable &&
        !second.reachable.locallyReachable) {
      return first.unsplit();
    }
    if (!first.reachable.locallyReachable &&
        second.reachable.locallyReachable) {
      return second.unsplit();
    }

    Reachability newReachable =
        Reachability.join(first.reachable, second.reachable).unsplit();
    Map<Variable, VariableModel<Variable, Type>> newVariableInfo =
        FlowModel.joinVariableInfo(typeOperations, first.variableInfo,
            second.variableInfo, emptyVariableMap);

    return FlowModel._identicalOrNew(
        first, second, newReachable, newVariableInfo);
  }

  /// Creates a new [FlowModel] object, unless it is equivalent to either
  /// [first] or [second], in which case one of those objects is re-used.
  static FlowModel<Variable, Type>
      _identicalOrNew<Variable extends Object, Type extends Object>(
          FlowModel<Variable, Type> first,
          FlowModel<Variable, Type> second,
          Reachability newReachable,
          Map<Variable, VariableModel<Variable, Type>> newVariableInfo) {
    if (first.reachable == newReachable &&
        identical(first.variableInfo, newVariableInfo)) {
      return first;
    }
    if (second.reachable == newReachable &&
        identical(second.variableInfo, newVariableInfo)) {
      return second;
    }

    return new FlowModel<Variable, Type>.withInfo(
        newReachable, newVariableInfo);
  }

  /// Determines whether the given "variableInfo" maps are equivalent.
  ///
  /// The equivalence check is shallow; if two variables' models are not
  /// identical, we return `false`.
  static bool _variableInfosEqual<Variable extends Object, Type extends Object>(
      Map<Variable, VariableModel<Variable, Type>> p1,
      Map<Variable, VariableModel<Variable, Type>> p2) {
    if (p1.length != p2.length) return false;
    if (!p1.keys.toSet().containsAll(p2.keys)) return false;
    for (MapEntry<Variable, VariableModel<Variable, Type>> entry
        in p1.entries) {
      VariableModel<Variable, Type> p1Value = entry.value;
      VariableModel<Variable, Type>? p2Value = p2[entry.key];
      if (!identical(p1Value, p2Value)) {
        return false;
      }
    }
    return true;
  }
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
    assert(overallReachable ==
        (locallyReachable && (parent?.overallReachable ?? true)));
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
    for (Reachability? self = this;
        self != null && !identical(self, ancestor);
        self = self.parent) {
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

  /// Combines two reachabilities (both of which must be based on the same
  /// checkpoint), where the code is considered reachable from the checkpoint
  /// iff either argument is reachable from the checkpoint.
  ///
  /// This is used as part of the "join" operation.
  static Reachability join(Reachability r1, Reachability r2) {
    assert(identical(r1.parent, r2.parent));
    if (r2.locallyReachable) {
      return r2;
    } else {
      return r1;
    }
  }

  /// Combines two reachabilities (both of which must be based on the same
  /// checkpoint), where the code is considered reachable from the checkpoint
  /// iff both arguments are reachable from the checkpoint.
  ///
  /// This is used as part of the "restrict" operation.
  static Reachability restrict(Reachability r1, Reachability r2) {
    assert(identical(r1.parent, r2.parent));
    if (r2.locallyReachable) {
      return r1;
    } else {
      return r2;
    }
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
@visibleForTesting
class SsaNode<Variable extends Object, Type extends Object> {
  /// Expando mapping SSA nodes to debug ids.  Only used by `toString`.
  static final Expando<int> _debugIds = new Expando<int>();

  static int _nextDebugId = 0;

  /// Flow analysis information was associated with the expression that
  /// produced the value represented by this SSA node, if it was non-trivial.
  /// This can be used at a later time to perform promotions if the value is
  /// used in a control flow construct.
  ///
  /// We don't bother storing flow analysis information if it's trivial (see
  /// [_TrivialExpressionInfo]) because such information does not lead to
  /// promotions.
  @visibleForTesting
  final ExpressionInfo<Variable, Type>? expressionInfo;

  SsaNode(this.expressionInfo);

  @override
  String toString() {
    SsaNode self = this; // Work around #44475
    int id = _debugIds[self] ??= _nextDebugId++;
    return 'ssa$id';
  }
}

/// Enum representing the different classifications of types that can be
/// returned by [TypeOperations.classifyType].
enum TypeClassification {
  /// The type is `Null` or an equivalent type (e.g. `Never?`)
  nullOrEquivalent,

  /// The type is a potentially nullable type, but not equivalent to `Null`
  /// (e.g. `int?`, or a type variable whose bound is potentially nullable)
  potentiallyNullable,

  /// The type is a non-nullable type.
  nonNullable,
}

/// Operations on types, abstracted from concrete type interfaces.
abstract class TypeOperations<Variable extends Object, Type extends Object> {
  /// Classifies the given type into one of the three categories defined by
  /// the [TypeClassification] enum.
  TypeClassification classifyType(Type type);

  /// Returns the "remainder" of [from] when [what] has been removed from
  /// consideration by an instance check.
  Type factor(Type from, Type what);

  /// Whether the possible promotion from [from] to [to] should be forced, given
  /// the current [promotedTypes], and [newPromotedTypes] resulting from
  /// possible demotion.
  ///
  /// It is not expected that any implementation would override this except for
  /// the migration engine.
  bool forcePromotion(Type to, Type from, List<Type>? promotedTypes,
          List<Type>? newPromotedTypes) =>
      false;

  /// Determines whether the given [type] is equivalent to the `Never` type.
  ///
  /// A type is equivalent to `Never` if it:
  /// (a) is the `Never` type itself.
  /// (b) is a type variable that extends `Never`, OR
  /// (c) is a type variable that has been promoted to `Never`
  bool isNever(Type type);

  /// Returns `true` if [type1] and [type2] are the same type.
  bool isSameType(Type type1, Type type2);

  /// Return `true` if the [leftType] is a subtype of the [rightType].
  bool isSubtypeOf(Type leftType, Type rightType);

  /// Returns the non-null promoted version of [type].
  ///
  /// Note that some types don't have a non-nullable version (e.g.
  /// `FutureOr<int?>`), so [type] may be returned even if it is nullable.
  Type /*!*/ promoteToNonNull(Type type);

  /// Performs refinements on the [promotedTypes] chain which resulted in
  /// intersecting [chain1] and [chain2].
  ///
  /// It is not expected that any implementation would override this except for
  /// the migration engine.
  List<Type>? refinePromotedTypes(
          List<Type>? chain1, List<Type>? chain2, List<Type>? promotedTypes) =>
      promotedTypes;

  /// Tries to promote to the first type from the second type, and returns the
  /// promoted type if it succeeds, otherwise null.
  Type? tryPromoteToType(Type to, Type from);

  /// Return the static type of the given [variable].
  Type variableType(Variable variable);
}

/// An instance of the [VariableModel] class represents the information gathered
/// by flow analysis for a single variable at a single point in the control flow
/// of the function or method being analyzed.
///
/// Instances of this class are immutable, so the methods below that "update"
/// the state actually leave `this` unchanged and return a new state object.
@visibleForTesting
class VariableModel<Variable extends Object, Type extends Object> {
  /// Sequence of types that the variable has been promoted to, where each
  /// element of the sequence is a subtype of the previous.  Null if the
  /// variable hasn't been promoted.
  final List<Type>? promotedTypes;

  /// List of types that the variable has been tested against in all code paths
  /// leading to the given point in the source code.
  final List<Type> tested;

  /// Indicates whether the variable has definitely been assigned.
  final bool assigned;

  /// Indicates whether the variable is unassigned.
  final bool unassigned;

  /// SSA node associated with this variable.  Every time the variable's value
  /// potentially changes (either through an explicit write or a join with a
  /// control flow path that contains a write), this field is updated to point
  /// to a fresh node.  Thus, it can be used to detect whether a variable's
  /// value has changed since a time in the past.
  ///
  /// `null` if the variable has been write captured.
  final SsaNode<Variable, Type>? ssaNode;

  VariableModel(
      {required this.promotedTypes,
      required this.tested,
      required this.assigned,
      required this.unassigned,
      required this.ssaNode}) {
    assert(!(assigned && unassigned),
        "Can't be both definitely assigned and unassigned");
    assert(promotedTypes == null || promotedTypes!.isNotEmpty);
    assert(!writeCaptured || promotedTypes == null,
        "Write-captured variables can't be promoted");
    assert(!(writeCaptured && unassigned),
        "Write-captured variables can't be definitely unassigned");
    // ignore:unnecessary_null_comparison
    assert(tested != null);
  }

  /// Creates a [VariableModel] representing a variable that's never been seen
  /// before.
  VariableModel.fresh({this.assigned = false})
      : promotedTypes = null,
        tested = const [],
        unassigned = !assigned,
        ssaNode = new SsaNode<Variable, Type>(null);

  /// Indicates whether the variable has been write captured.
  bool get writeCaptured => ssaNode == null;

  /// Returns a new [VariableModel] in which any promotions present have been
  /// dropped, and the variable has been marked as "not unassigned".
  ///
  /// Used by [conservativeJoin] to update the state of variables at the top of
  /// loops whose bodies write to them.
  VariableModel<Variable, Type> discardPromotionsAndMarkNotUnassigned() {
    return new VariableModel<Variable, Type>(
        promotedTypes: null,
        tested: tested,
        assigned: assigned,
        unassigned: false,
        ssaNode: writeCaptured ? null : new SsaNode<Variable, Type>(null));
  }

  /// Returns an updated model reflect a control path that is known to have
  /// previously passed through some [other] state.  See [FlowModel.restrict]
  /// for details.
  VariableModel<Variable, Type> restrict(
      TypeOperations<Variable, Type> typeOperations,
      VariableModel<Variable, Type> otherModel,
      bool unsafe) {
    if (allowLocalBooleanVarsToPromoteByDefault) {
      // TODO(paulberry): when we hardcode
      // allowLocalBooleanVarsToPromoteByDefault to `true`, we should remove
      // this method entirely.
      throw new StateError('This method should not be called anymore');
    }
    List<Type>? thisPromotedTypes = promotedTypes;
    List<Type>? otherPromotedTypes = otherModel.promotedTypes;
    bool newAssigned = assigned || otherModel.assigned;
    // The variable can only be unassigned in this state if it was also
    // unassigned in the other state or if the other state didn't complete
    // normally. For the latter case the resulting state is unreachable but to
    // avoid creating a variable model that is both assigned and unassigned we
    // take the intersection below.
    //
    // This situation can occur in try-finally like:
    //
    //   method() {
    //     var local;
    //     try {
    //       local = 0;
    //       return; // assigned
    //     } finally {
    //       local; // unassigned
    //     }
    //     local; // unreachable state
    //   }
    //
    bool newUnassigned = unassigned && otherModel.unassigned;
    bool newWriteCaptured = writeCaptured || otherModel.writeCaptured;
    List<Type>? newPromotedTypes;
    if (newWriteCaptured) {
      // Write-captured variables can't be promoted
      newPromotedTypes = null;
    } else if (unsafe) {
      // There was an assignment to the variable in the "this" path, so none of
      // the promotions from the "other" path can be used.
      newPromotedTypes = thisPromotedTypes;
    } else {
      newPromotedTypes = rebasePromotedTypes(
          typeOperations, thisPromotedTypes, otherPromotedTypes);
    }
    return _identicalOrNew(this, otherModel, newPromotedTypes, tested,
        newAssigned, newUnassigned, newWriteCaptured ? null : ssaNode);
  }

  @override
  String toString() {
    List<String> parts = [ssaNode.toString()];
    if (promotedTypes != null) {
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
    return 'VariableModel(${parts.join(', ')})';
  }

  /// Returns a new [VariableModel] reflecting the fact that the variable was
  /// just written to.
  VariableModel<Variable, Type> write(
      Variable variable,
      Type writtenType,
      TypeOperations<Variable, Type> typeOperations,
      SsaNode<Variable, Type> newSsaNode) {
    if (writeCaptured) {
      return new VariableModel<Variable, Type>(
          promotedTypes: promotedTypes,
          tested: tested,
          assigned: true,
          unassigned: false,
          ssaNode: null);
    }

    List<Type>? newPromotedTypes = _demoteViaAssignment(
      writtenType,
      typeOperations,
    );

    Type declaredType = typeOperations.variableType(variable);
    newPromotedTypes = _tryPromoteToTypeOfInterest(
        typeOperations, declaredType, newPromotedTypes, writtenType);
    if (identical(promotedTypes, newPromotedTypes) && assigned) {
      return new VariableModel<Variable, Type>(
          promotedTypes: promotedTypes,
          tested: tested,
          assigned: assigned,
          unassigned: unassigned,
          ssaNode: newSsaNode);
    }

    List<Type> newTested;
    if (newPromotedTypes == null && promotedTypes != null) {
      newTested = const [];
    } else {
      newTested = tested;
    }

    return new VariableModel<Variable, Type>(
        promotedTypes: newPromotedTypes,
        tested: newTested,
        assigned: true,
        unassigned: false,
        ssaNode: newSsaNode);
  }

  /// Returns a new [VariableModel] reflecting the fact that the variable has
  /// been write-captured.
  VariableModel<Variable, Type> writeCapture() {
    return new VariableModel<Variable, Type>(
        promotedTypes: null,
        tested: const [],
        assigned: assigned,
        unassigned: false,
        ssaNode: null);
  }

  List<Type>? _demoteViaAssignment(
    Type writtenType,
    TypeOperations<Variable, Type> typeOperations,
  ) {
    List<Type>? promotedTypes = this.promotedTypes;
    if (promotedTypes == null) {
      return null;
    }

    int numElementsToKeep = promotedTypes.length;
    for (;; numElementsToKeep--) {
      if (numElementsToKeep == 0) {
        return null;
      }
      Type promoted = promotedTypes[numElementsToKeep - 1];
      if (typeOperations.isSubtypeOf(writtenType, promoted)) {
        if (numElementsToKeep == promotedTypes.length) {
          return promotedTypes;
        }
        return promotedTypes.sublist(0, numElementsToKeep);
      }
    }
  }

  /// Determines whether a variable with the given [promotedTypes] should be
  /// promoted to [writtenType] based on types of interest.  If it should,
  /// returns an updated promotion chain; otherwise returns [promotedTypes]
  /// unchanged.
  ///
  /// Note that since promotion chains are considered immutable, if promotion
  /// is required, a new promotion chain will be created and returned.
  List<Type>? _tryPromoteToTypeOfInterest(
      TypeOperations<Variable, Type> typeOperations,
      Type declaredType,
      List<Type>? promotedTypes,
      Type writtenType) {
    assert(!writeCaptured);

    if (typeOperations.forcePromotion(
        writtenType, declaredType, this.promotedTypes, promotedTypes)) {
      return _addToPromotedTypes(promotedTypes, writtenType);
    }

    // Figure out if we have any promotion candidates (types that are a
    // supertype of writtenType and a proper subtype of the currently-promoted
    // type).  If at any point we find an exact match, we take it immediately.
    Type? currentlyPromotedType = promotedTypes?.last;

    List<Type>? result;
    List<Type>? candidates = null;

    void handleTypeOfInterest(Type type) {
      // The written type must be a subtype of the type.
      if (!typeOperations.isSubtypeOf(writtenType, type)) {
        return;
      }

      // Must be more specific that the currently promoted type.
      if (currentlyPromotedType != null) {
        if (typeOperations.isSameType(type, currentlyPromotedType)) {
          return;
        }
        if (!typeOperations.isSubtypeOf(type, currentlyPromotedType)) {
          return;
        }
      }

      // This is precisely the type we want to promote to; take it.
      if (typeOperations.isSameType(type, writtenType)) {
        result = _addToPromotedTypes(promotedTypes, writtenType);
      }

      if (candidates == null) {
        candidates = [type];
        return;
      }

      // Add only unique candidates.
      if (!_typeListContains(typeOperations, candidates!, type)) {
        candidates!.add(type);
        return;
      }
    }

    // The declared type is always a type of interest, but we never promote
    // to the declared type. So, try NonNull of it.
    Type declaredTypeNonNull = typeOperations.promoteToNonNull(declaredType);
    if (!typeOperations.isSameType(declaredTypeNonNull, declaredType)) {
      handleTypeOfInterest(declaredTypeNonNull);
      if (result != null) {
        return result!;
      }
    }

    for (int i = 0; i < tested.length; i++) {
      Type type = tested[i];

      handleTypeOfInterest(type);
      if (result != null) {
        return result!;
      }

      Type typeNonNull = typeOperations.promoteToNonNull(type);
      if (!typeOperations.isSameType(typeNonNull, type)) {
        handleTypeOfInterest(typeNonNull);
        if (result != null) {
          return result!;
        }
      }
    }

    List<Type>? candidates2 = candidates;
    if (candidates2 != null) {
      // Figure out if we have a unique promotion candidate that's a subtype
      // of all the others.
      Type? promoted;
      outer:
      for (int i = 0; i < candidates2.length; i++) {
        for (int j = 0; j < candidates2.length; j++) {
          if (j == i) continue;
          if (!typeOperations.isSubtypeOf(candidates2[i], candidates2[j])) {
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

  /// Builds a [VariableModel] based on [model], but extending the [tested] set
  /// to include types from [tested].  This is used at the bottom of certain
  /// kinds of loops, to ensure that types tested within the body of the loop
  /// are consistently treated as "of interest" in code that follows the loop,
  /// regardless of the type of loop.
  @visibleForTesting
  static VariableModel<Variable, Type>
      inheritTested<Variable extends Object, Type extends Object>(
          TypeOperations<Variable, Type> typeOperations,
          VariableModel<Variable, Type> model,
          List<Type> tested) {
    List<Type> newTested = joinTested(tested, model.tested, typeOperations);
    if (identical(newTested, model.tested)) return model;
    return new VariableModel<Variable, Type>(
        promotedTypes: model.promotedTypes,
        tested: newTested,
        assigned: model.assigned,
        unassigned: model.unassigned,
        ssaNode: model.ssaNode);
  }

  /// Joins two variable models.  See [FlowModel.join] for details.
  static VariableModel<Variable, Type>
      join<Variable extends Object, Type extends Object>(
          TypeOperations<Variable, Type> typeOperations,
          VariableModel<Variable, Type> first,
          VariableModel<Variable, Type> second) {
    List<Type>? newPromotedTypes = joinPromotedTypes(
        first.promotedTypes, second.promotedTypes, typeOperations);
    newPromotedTypes = typeOperations.refinePromotedTypes(
        first.promotedTypes, second.promotedTypes, newPromotedTypes);
    bool newAssigned = first.assigned && second.assigned;
    bool newUnassigned = first.unassigned && second.unassigned;
    bool newWriteCaptured = first.writeCaptured || second.writeCaptured;
    List<Type> newTested = newWriteCaptured
        ? const []
        : joinTested(first.tested, second.tested, typeOperations);
    SsaNode<Variable, Type>? newSsaNode = newWriteCaptured
        ? null
        : first.ssaNode == second.ssaNode
            ? first.ssaNode
            : new SsaNode<Variable, Type>(null);
    return _identicalOrNew(first, second, newPromotedTypes, newTested,
        newAssigned, newUnassigned, newWriteCaptured ? null : newSsaNode);
  }

  /// Performs the portion of the "join" algorithm that applies to promotion
  /// chains.  Briefly, we intersect given chains.  The chains are totally
  /// ordered subsets of a global partial order.  Their intersection is a
  /// subset of each, and as such is also totally ordered.
  static List<Type>?
      joinPromotedTypes<Variable extends Object, Type extends Object>(
          List<Type>? chain1,
          List<Type>? chain2,
          TypeOperations<Variable, Type> typeOperations) {
    if (chain1 == null) return chain1;
    if (chain2 == null) return chain2;

    int index1 = 0;
    int index2 = 0;
    bool skipped1 = false;
    bool skipped2 = false;
    List<Type>? result;
    while (index1 < chain1.length && index2 < chain2.length) {
      Type type1 = chain1[index1];
      Type type2 = chain2[index2];
      if (typeOperations.isSameType(type1, type2)) {
        result ??= <Type>[];
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
    return result;
  }

  /// Performs the portion of the "join" algorithm that applies to promotion
  /// chains.  Essentially this performs a set union, with the following
  /// caveats:
  /// - The "sets" are represented as lists (since they are expected to be very
  ///   small in real-world cases)
  /// - The sense of equality for the union operation is determined by
  ///   [TypeOperations.isSameType].
  /// - The types of interests lists are considered immutable.
  static List<Type> joinTested<Variable extends Object, Type extends Object>(
      List<Type> types1,
      List<Type> types2,
      TypeOperations<Variable, Type> typeOperations) {
    // Ensure that types1 is the shorter list.
    if (types1.length > types2.length) {
      List<Type> tmp = types1;
      types1 = types2;
      types2 = tmp;
    }
    // Determine the length of the common prefix the two lists share.
    int shared = 0;
    for (; shared < types1.length; shared++) {
      if (!typeOperations.isSameType(types1[shared], types2[shared])) break;
    }
    // Use types2 as a starting point and add any entries from types1 that are
    // not present in it.
    for (int i = shared; i < types1.length; i++) {
      Type typeToAdd = types1[i];
      if (_typeListContains(typeOperations, types2, typeToAdd)) continue;
      List<Type> result = types2.toList()..add(typeToAdd);
      for (i++; i < types1.length; i++) {
        typeToAdd = types1[i];
        if (_typeListContains(typeOperations, types2, typeToAdd)) continue;
        result.add(typeToAdd);
      }
      return result;
    }
    // No types needed to be added.
    return types2;
  }

  /// Forms a promotion chain by starting with [basePromotedTypes] and applying
  /// promotions from [thisPromotedTypes] to it, to the extent possible without
  /// violating the usual ordering invariant (each promoted type must be a
  /// subtype of the previous).
  ///
  /// In degenerate cases, the returned chain will be identical to
  /// [thisPromotedTypes] or [basePromotedTypes] (to make it easier for the
  /// caller to detect when data structures may be re-used).
  static List<Type>? rebasePromotedTypes<Type extends Object>(
      TypeOperations<Object, Type> typeOperations,
      List<Type>? thisPromotedTypes,
      List<Type>? basePromotedTypes) {
    if (basePromotedTypes == null) {
      // The base promotion chain contributes nothing so we just use this
      // promotion chain directly.
      return thisPromotedTypes;
    } else if (thisPromotedTypes == null) {
      // This promotion chain contributes nothing so we just use the base
      // promotion chain directly.
      return basePromotedTypes;
    } else {
      // Start with basePromotedTypes and apply each of the promotions in
      // thisPromotedTypes (discarding any that don't follow the ordering
      // invariant)
      List<Type> newPromotedTypes = basePromotedTypes;
      Type otherPromotedType = basePromotedTypes.last;
      for (int i = 0; i < thisPromotedTypes.length; i++) {
        Type nextType = thisPromotedTypes[i];
        if (typeOperations.isSubtypeOf(nextType, otherPromotedType) &&
            !typeOperations.isSameType(nextType, otherPromotedType)) {
          newPromotedTypes = basePromotedTypes.toList()
            ..addAll(thisPromotedTypes.skip(i));
          break;
        }
      }
      return newPromotedTypes;
    }
  }

  static List<Type> _addToPromotedTypes<Type extends Object>(
          List<Type>? promotedTypes, Type promoted) =>
      promotedTypes == null
          ? [promoted]
          : (promotedTypes.toList()..add(promoted));

  static List<Type>
      _addTypeToUniqueList<Variable extends Object, Type extends Object>(
          List<Type> types,
          Type newType,
          TypeOperations<Variable, Type> typeOperations) {
    if (_typeListContains(typeOperations, types, newType)) return types;
    return new List<Type>.from(types)..add(newType);
  }

  /// Creates a new [VariableModel] object, unless it is equivalent to either
  /// [first] or [second], in which case one of those objects is re-used.
  static VariableModel<Variable, Type>
      _identicalOrNew<Variable extends Object, Type extends Object>(
          VariableModel<Variable, Type> first,
          VariableModel<Variable, Type> second,
          List<Type>? newPromotedTypes,
          List<Type> newTested,
          bool newAssigned,
          bool newUnassigned,
          SsaNode<Variable, Type>? newSsaNode) {
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
      return new VariableModel<Variable, Type>(
          promotedTypes: newPromotedTypes,
          tested: newTested,
          assigned: newAssigned,
          unassigned: newUnassigned,
          ssaNode: newSsaNode);
    }
  }

  static bool _typeListContains<Variable extends Object, Type extends Object>(
      TypeOperations<Variable, Type> typeOperations,
      List<Type> list,
      Type searchType) {
    for (Type type in list) {
      if (typeOperations.isSameType(type, searchType)) return true;
    }
    return false;
  }
}

/// [_FlowContext] representing an assert statement or assert initializer.
class _AssertContext<Variable extends Object, Type extends Object>
    extends _SimpleContext<Variable, Type> {
  /// Flow models associated with the condition being asserted.
  ExpressionInfo<Variable, Type>? _conditionInfo;

  _AssertContext(FlowModel<Variable, Type> previous) : super(previous);

  @override
  String toString() =>
      '_AssertContext(previous: $_previous, conditionInfo: $_conditionInfo)';
}

/// [_FlowContext] representing a language construct that branches on a boolean
/// condition, such as an `if` statement, conditional expression, or a logical
/// binary operator.
class _BranchContext<Variable extends Object, Type extends Object>
    extends _FlowContext {
  /// Flow models associated with the condition being branched on.
  final ExpressionInfo<Variable, Type>? _conditionInfo;

  _BranchContext(this._conditionInfo);

  @override
  String toString() => '_BranchContext(conditionInfo: $_conditionInfo)';
}

/// [_FlowContext] representing a language construct that can be targeted by
/// `break` or `continue` statements, such as a loop or switch statement.
class _BranchTargetContext<Variable extends Object, Type extends Object>
    extends _FlowContext {
  /// Accumulated flow model for all `break` statements seen so far, or `null`
  /// if no `break` statements have been seen yet.
  FlowModel<Variable, Type>? _breakModel;

  /// Accumulated flow model for all `continue` statements seen so far, or
  /// `null` if no `continue` statements have been seen yet.
  FlowModel<Variable, Type>? _continueModel;

  /// The reachability checkpoint associated with this loop or switch statement.
  /// When analyzing deeply nested `break` and `continue` statements, their flow
  /// models need to be unsplit to this point before joining them to the control
  /// flow paths for the loop or switch.
  final Reachability _checkpoint;

  _BranchTargetContext(this._checkpoint);

  @override
  String toString() => '_BranchTargetContext(breakModel: $_breakModel, '
      'continueModel: $_continueModel, checkpoint: $_checkpoint)';
}

/// [_FlowContext] representing a conditional expression.
class _ConditionalContext<Variable extends Object, Type extends Object>
    extends _BranchContext<Variable, Type> {
  /// Flow models associated with the value of the conditional expression in the
  /// circumstance where the "then" branch is taken.
  ExpressionInfo<Variable, Type>? _thenInfo;

  _ConditionalContext(ExpressionInfo<Variable, Type> conditionInfo)
      : super(conditionInfo);

  @override
  String toString() => '_ConditionalContext(conditionInfo: $_conditionInfo, '
      'thenInfo: $_thenInfo)';
}

/// [_FlowContext] representing an equality comparison using `==` or `!=`.
class _EqualityOpContext<Variable extends Object, Type extends Object>
    extends _BranchContext<Variable, Type> {
  /// The type of the expression on the LHS of `==` or `!=`.
  final Type _leftOperandType;

  /// If the LHS of `==` or `!=` is a variable reference, the variable.
  /// Otherwise `null`.
  final Variable? _leftOperandVariable;

  _EqualityOpContext(ExpressionInfo<Variable, Type>? conditionInfo,
      this._leftOperandType, this._leftOperandVariable)
      : super(conditionInfo);

  @override
  String toString() =>
      '_EqualityOpContext(conditionInfo: $_conditionInfo, lhsType: '
      '$_leftOperandType)';
}

class _FlowAnalysisImpl<Node extends Object, Statement extends Node,
        Expression extends Object, Variable extends Object, Type extends Object>
    implements FlowAnalysis<Node, Statement, Expression, Variable, Type> {
  /// The [TypeOperations], used to access types, and check subtyping.
  final TypeOperations<Variable, Type> typeOperations;

  /// Stack of [_FlowContext] objects representing the statements and
  /// expressions that are currently being visited.
  final List<_FlowContext> _stack = [];

  /// The mapping from [Statement]s that can act as targets for `break` and
  /// `continue` statements (i.e. loops and switch statements) to the to their
  /// context information.
  final Map<Statement, _BranchTargetContext<Variable, Type>>
      _statementToContext = {};

  late FlowModel<Variable, Type> _current;

  /// The most recently visited expression for which an [ExpressionInfo] object
  /// exists, or `null` if no expression has been visited that has a
  /// corresponding [ExpressionInfo] object.
  Expression? _expressionWithInfo;

  /// If [_expressionWithInfo] is not `null`, the [ExpressionInfo] object
  /// corresponding to it.  Otherwise `null`.
  ExpressionInfo<Variable, Type>? _expressionInfo;

  /// The most recently visited expression which was a variable reference, or
  /// `null` if no expression has been visited that was a variable reference.
  Expression? _expressionWithVariable;

  /// If [_expressionVariable] is not `null`, the variable corresponding to it.
  /// Otherwise `null`.
  Variable? _expressionVariable;

  int _functionNestingLevel = 0;

  final AssignedVariables<Node, Variable> _assignedVariables;

  /// Set this boolean to `true` to temporarily enable the feature of allowing
  /// local boolean variables to influence promotion, for this flow analysis
  /// session (see https://github.com/dart-lang/language/issues/1274).  Once the
  /// top level const [allowLocalBooleanVarsToPromoteByDefault] is changed to
  /// `true`, this field will always be `true`, so it can be safely removed.
  final bool allowLocalBooleanVarsToPromote;

  _FlowAnalysisImpl(this.typeOperations, this._assignedVariables,
      {bool allowLocalBooleanVarsToPromote = false})
      : allowLocalBooleanVarsToPromote =
            allowLocalBooleanVarsToPromoteByDefault ||
                allowLocalBooleanVarsToPromote {
    _current = new FlowModel<Variable, Type>(Reachability.initial);
  }

  @override
  bool get isReachable => _current.reachable.overallReachable;

  @override
  void asExpression_end(Expression subExpression, Type type) {
    Variable? variable = _getExpressionVariable(subExpression);
    if (variable == null) return;
    _current = _current.tryPromoteForTypeCast(typeOperations, variable, type);
  }

  @override
  void assert_afterCondition(Expression condition) {
    _AssertContext<Variable, Type> context =
        _stack.last as _AssertContext<Variable, Type>;
    ExpressionInfo<Variable, Type> conditionInfo = _expressionEnd(condition);
    context._conditionInfo = conditionInfo;
    _current = conditionInfo.ifFalse;
  }

  @override
  void assert_begin() {
    _current = _current.split();
    _stack.add(new _AssertContext<Variable, Type>(_current));
  }

  @override
  void assert_end() {
    _AssertContext<Variable, Type> context =
        _stack.removeLast() as _AssertContext<Variable, Type>;
    _current = _merge(context._previous, context._conditionInfo!.ifTrue);
  }

  @override
  void booleanLiteral(Expression expression, bool value) {
    FlowModel<Variable, Type> unreachable = _current.setUnreachable();
    _storeExpressionInfo(
        expression,
        value
            ? new ExpressionInfo(_current, _current, unreachable)
            : new ExpressionInfo(_current, unreachable, _current));
  }

  @override
  void conditional_conditionBegin() {
    _current = _current.split();
  }

  @override
  void conditional_elseBegin(Expression thenExpression) {
    _ConditionalContext<Variable, Type> context =
        _stack.last as _ConditionalContext<Variable, Type>;
    context._thenInfo = _expressionEnd(thenExpression);
    _current = context._conditionInfo!.ifFalse;
  }

  @override
  void conditional_end(
      Expression conditionalExpression, Expression elseExpression) {
    _ConditionalContext<Variable, Type> context =
        _stack.removeLast() as _ConditionalContext<Variable, Type>;
    ExpressionInfo<Variable, Type> thenInfo = context._thenInfo!;
    ExpressionInfo<Variable, Type> elseInfo = _expressionEnd(elseExpression);
    _storeExpressionInfo(
        conditionalExpression,
        new ExpressionInfo(
            _merge(thenInfo.after, elseInfo.after),
            _merge(thenInfo.ifTrue, elseInfo.ifTrue),
            _merge(thenInfo.ifFalse, elseInfo.ifFalse)));
  }

  @override
  void conditional_thenBegin(Expression condition) {
    ExpressionInfo<Variable, Type> conditionInfo = _expressionEnd(condition);
    _stack.add(new _ConditionalContext(conditionInfo));
    _current = conditionInfo.ifTrue;
  }

  @override
  void declare(Variable variable, bool initialized) {
    _current = _current.declare(variable, initialized);
  }

  @override
  void doStatement_bodyBegin(Statement doStatement) {
    AssignedVariablesNodeInfo<Variable> info =
        _assignedVariables._getInfoForNode(doStatement);
    _BranchTargetContext<Variable, Type> context =
        new _BranchTargetContext<Variable, Type>(_current.reachable);
    _stack.add(context);
    _current = _current.conservativeJoin(info._written, info._captured).split();
    _statementToContext[doStatement] = context;
  }

  @override
  void doStatement_conditionBegin() {
    _BranchTargetContext<Variable, Type> context =
        _stack.last as _BranchTargetContext<Variable, Type>;
    _current = _join(_current, context._continueModel);
  }

  @override
  void doStatement_end(Expression condition) {
    _BranchTargetContext<Variable, Type> context =
        _stack.removeLast() as _BranchTargetContext<Variable, Type>;
    _current = _merge(_expressionEnd(condition).ifFalse, context._breakModel);
  }

  @override
  void equalityOp_end(Expression wholeExpression, Expression rightOperand,
      Type rightOperandType,
      {bool notEqual = false}) {
    _EqualityOpContext<Variable, Type> context =
        _stack.removeLast() as _EqualityOpContext<Variable, Type>;
    ExpressionInfo<Variable, Type>? lhsInfo = context._conditionInfo;
    Variable? lhsVariable = context._leftOperandVariable;
    Type leftOperandType = context._leftOperandType;
    ExpressionInfo<Variable, Type>? rhsInfo = _getExpressionInfo(rightOperand);
    Variable? rhsVariable = _getExpressionVariable(rightOperand);
    TypeClassification leftOperandTypeClassification =
        typeOperations.classifyType(leftOperandType);
    TypeClassification rightOperandTypeClassification =
        typeOperations.classifyType(rightOperandType);
    if (leftOperandTypeClassification == TypeClassification.nullOrEquivalent &&
        rightOperandTypeClassification == TypeClassification.nullOrEquivalent) {
      booleanLiteral(wholeExpression, !notEqual);
    } else if ((leftOperandTypeClassification ==
                TypeClassification.nullOrEquivalent &&
            rightOperandTypeClassification == TypeClassification.nonNullable) ||
        (rightOperandTypeClassification ==
                TypeClassification.nullOrEquivalent &&
            leftOperandTypeClassification == TypeClassification.nonNullable)) {
      // In strong mode the test is guaranteed to produce a "not equal" result,
      // but weak mode it might produce an "equal" result.  We don't want flow
      // analysis behavior to depend on mode, so we conservatively assume that
      // either result is possible.
    } else if (lhsInfo is _NullInfo<Variable, Type> && rhsVariable != null) {
      ExpressionInfo<Variable, Type> equalityInfo =
          _current.tryMarkNonNullable(typeOperations, rhsVariable);
      _storeExpressionInfo(
          wholeExpression, notEqual ? equalityInfo : equalityInfo.invert());
    } else if (rhsInfo is _NullInfo<Variable, Type> && lhsVariable != null) {
      ExpressionInfo<Variable, Type> equalityInfo =
          _current.tryMarkNonNullable(typeOperations, lhsVariable);
      _storeExpressionInfo(
          wholeExpression, notEqual ? equalityInfo : equalityInfo.invert());
    }
  }

  @override
  void equalityOp_rightBegin(Expression leftOperand, Type leftOperandType) {
    _stack.add(new _EqualityOpContext<Variable, Type>(
        _getExpressionInfo(leftOperand),
        leftOperandType,
        _getExpressionVariable(leftOperand)));
  }

  @override
  ExpressionInfo<Variable, Type>? expressionInfoForTesting(Expression target) =>
      identical(target, _expressionWithInfo) ? _expressionInfo : null;

  @override
  void finish() {
    assert(_stack.isEmpty);
    assert(_current.reachable.parent == null);
  }

  @override
  void for_bodyBegin(Statement? node, Expression? condition) {
    ExpressionInfo<Variable, Type> conditionInfo = condition == null
        ? new ExpressionInfo(_current, _current, _current.setUnreachable())
        : _expressionEnd(condition);
    _WhileContext<Variable, Type> context = new _WhileContext<Variable, Type>(
        _current.reachable.parent!, conditionInfo);
    _stack.add(context);
    if (node != null) {
      _statementToContext[node] = context;
    }
    _current = conditionInfo.ifTrue;
  }

  @override
  void for_conditionBegin(Node node) {
    AssignedVariablesNodeInfo<Variable> info =
        _assignedVariables._getInfoForNode(node);
    _current = _current.conservativeJoin(info._written, info._captured).split();
  }

  @override
  void for_end() {
    _WhileContext<Variable, Type> context =
        _stack.removeLast() as _WhileContext<Variable, Type>;
    // Tail of the stack: falseCondition, break
    FlowModel<Variable, Type>? breakState = context._breakModel;
    FlowModel<Variable, Type> falseCondition = context._conditionInfo.ifFalse;

    _current = _merge(falseCondition, breakState)
        .inheritTested(typeOperations, _current);
  }

  @override
  void for_updaterBegin() {
    _WhileContext<Variable, Type> context =
        _stack.last as _WhileContext<Variable, Type>;
    _current = _join(_current, context._continueModel);
  }

  @override
  void forEach_bodyBegin(Node node, Variable? loopVariable, Type writtenType) {
    AssignedVariablesNodeInfo<Variable> info =
        _assignedVariables._getInfoForNode(node);
    _current = _current.conservativeJoin(info._written, info._captured).split();
    _SimpleStatementContext<Variable, Type> context =
        new _SimpleStatementContext<Variable, Type>(
            _current.reachable.parent!, _current);
    _stack.add(context);
    if (loopVariable != null) {
      _current = _current.write(loopVariable, writtenType,
          new SsaNode<Variable, Type>(null), typeOperations);
    }
  }

  @override
  void forEach_end() {
    _SimpleStatementContext<Variable, Type> context =
        _stack.removeLast() as _SimpleStatementContext<Variable, Type>;
    _current = _merge(_current, context._previous);
  }

  @override
  void forwardExpression(Expression newExpression, Expression oldExpression) {
    if (identical(_expressionWithInfo, oldExpression)) {
      _expressionWithInfo = newExpression;
    }
    if (identical(_expressionWithVariable, oldExpression)) {
      _expressionWithVariable = newExpression;
    }
  }

  @override
  void functionExpression_begin(Node node) {
    AssignedVariablesNodeInfo<Variable> info =
        _assignedVariables._getInfoForNode(node);
    ++_functionNestingLevel;
    _current = _current.conservativeJoin(const [], info._written);
    _stack.add(new _FunctionExpressionContext(_current));
    _current = _current.conservativeJoin(_assignedVariables._anywhere._written,
        _assignedVariables._anywhere._captured);
  }

  @override
  void functionExpression_end() {
    --_functionNestingLevel;
    assert(_functionNestingLevel >= 0);
    _SimpleContext<Variable, Type> context =
        _stack.removeLast() as _FunctionExpressionContext<Variable, Type>;
    _current = context._previous;
  }

  @override
  void handleBreak(Statement target) {
    _BranchTargetContext<Variable, Type>? context = _statementToContext[target];
    if (context != null) {
      context._breakModel =
          _join(context._breakModel, _current.unsplitTo(context._checkpoint));
    }
    _current = _current.setUnreachable();
  }

  @override
  void handleContinue(Statement target) {
    _BranchTargetContext<Variable, Type>? context = _statementToContext[target];
    if (context != null) {
      context._continueModel = _join(
          context._continueModel, _current.unsplitTo(context._checkpoint));
    }
    _current = _current.setUnreachable();
  }

  @override
  void handleExit() {
    _current = _current.setUnreachable();
  }

  @override
  void ifNullExpression_end() {
    _IfNullExpressionContext<Variable, Type> context =
        _stack.removeLast() as _IfNullExpressionContext<Variable, Type>;
    _current = _merge(_current, context._previous);
  }

  @override
  void ifNullExpression_rightBegin(
      Expression leftHandSide, Type leftHandSideType) {
    Variable? lhsVariable = _getExpressionVariable(leftHandSide);
    FlowModel<Variable, Type> promoted;
    _current = _current.split();
    if (lhsVariable != null) {
      ExpressionInfo<Variable, Type> promotionInfo =
          _current.tryMarkNonNullable(typeOperations, lhsVariable);
      _current = promotionInfo.ifFalse;
      promoted = promotionInfo.ifTrue;
    } else {
      promoted = _current;
    }
    _stack.add(new _IfNullExpressionContext<Variable, Type>(promoted));
  }

  @override
  void ifStatement_conditionBegin() {
    _current = _current.split();
  }

  @override
  void ifStatement_elseBegin() {
    _IfContext<Variable, Type> context =
        _stack.last as _IfContext<Variable, Type>;
    context._afterThen = _current;
    _current = context._conditionInfo!.ifFalse;
  }

  @override
  void ifStatement_end(bool hasElse) {
    _IfContext<Variable, Type> context =
        _stack.removeLast() as _IfContext<Variable, Type>;
    FlowModel<Variable, Type> afterThen;
    FlowModel<Variable, Type> afterElse;
    if (hasElse) {
      afterThen = context._afterThen!;
      afterElse = _current;
    } else {
      afterThen = _current; // no `else`, so `then` is still current
      afterElse = context._conditionInfo!.ifFalse;
    }
    _current = _merge(afterThen, afterElse);
  }

  @override
  void ifStatement_thenBegin(Expression condition) {
    ExpressionInfo<Variable, Type> conditionInfo = _expressionEnd(condition);
    _stack.add(new _IfContext(conditionInfo));
    _current = conditionInfo.ifTrue;
  }

  @override
  void initialize(
      Variable variable, Type initializerType, Expression initializerExpression,
      {required bool isFinal, required bool isLate}) {
    ExpressionInfo<Variable, Type>? expressionInfo =
        _getExpressionInfo(initializerExpression);
    SsaNode<Variable, Type> newSsaNode = new SsaNode<Variable, Type>(isLate
        ? null
        : expressionInfo is _TrivialExpressionInfo
            ? null
            : expressionInfo);
    if (isFinal) {
      // We don't promote final variables on initialization, so pretend the
      // written type is the variable's declared type.
      initializerType = typeOperations.variableType(variable);
    }
    _current =
        _current.write(variable, initializerType, newSsaNode, typeOperations);
  }

  @override
  bool isAssigned(Variable variable) {
    return _current.infoFor(variable).assigned;
  }

  @override
  void isExpression_end(Expression isExpression, Expression subExpression,
      bool isNot, Type type) {
    Variable? subExpressionVariable = _getExpressionVariable(subExpression);
    if (subExpressionVariable != null) {
      ExpressionInfo<Variable, Type> expressionInfo = _current
          .tryPromoteForTypeCheck(typeOperations, subExpressionVariable, type);
      _storeExpressionInfo(
          isExpression, isNot ? expressionInfo.invert() : expressionInfo);
    }
  }

  @override
  bool isUnassigned(Variable variable) {
    return _current.infoFor(variable).unassigned;
  }

  @override
  void labeledStatement_begin(Statement node) {
    _current = _current.split();
    _BranchTargetContext<Variable, Type> context =
        new _BranchTargetContext<Variable, Type>(_current.reachable.parent!);
    _stack.add(context);
    _statementToContext[node] = context;
  }

  @override
  void labeledStatement_end() {
    _BranchTargetContext<Variable, Type> context =
        _stack.removeLast() as _BranchTargetContext<Variable, Type>;
    _current = _merge(_current, context._breakModel);
  }

  @override
  void lateInitializer_begin(Node node) {
    // Late initializers are treated the same as function expressions.
    // Essentially we act as though `late x = expr;` is syntactic sugar for
    // `late x = LAZY_MAGIC(() => expr);` (where `LAZY_MAGIC` creates a lazy
    // evaluation thunk that gets replaced by the result of `expr` once it is
    // evaluated).
    functionExpression_begin(node);
  }

  @override
  void lateInitializer_end() {
    // Late initializers are treated the same as function expressions.
    // Essentially we act as though `late x = expr;` is syntactic sugar for
    // `late x = LAZY_MAGIC(() => expr);` (where `LAZY_MAGIC` creates a lazy
    // evaluation thunk that gets replaced by the result of `expr` once it is
    // evaluated).
    functionExpression_end();
  }

  @override
  void logicalBinaryOp_begin() {
    _current = _current.split();
  }

  @override
  void logicalBinaryOp_end(Expression wholeExpression, Expression rightOperand,
      {required bool isAnd}) {
    _BranchContext<Variable, Type> context =
        _stack.removeLast() as _BranchContext<Variable, Type>;
    ExpressionInfo<Variable, Type> rhsInfo = _expressionEnd(rightOperand);

    FlowModel<Variable, Type> trueResult;
    FlowModel<Variable, Type> falseResult;
    if (isAnd) {
      trueResult = rhsInfo.ifTrue;
      falseResult = _join(context._conditionInfo!.ifFalse, rhsInfo.ifFalse);
    } else {
      trueResult = _join(context._conditionInfo!.ifTrue, rhsInfo.ifTrue);
      falseResult = rhsInfo.ifFalse;
    }
    _storeExpressionInfo(
        wholeExpression,
        new ExpressionInfo(_merge(trueResult, falseResult),
            trueResult.unsplit(), falseResult.unsplit()));
  }

  @override
  void logicalBinaryOp_rightBegin(Expression leftOperand,
      {required bool isAnd}) {
    ExpressionInfo<Variable, Type> conditionInfo = _expressionEnd(leftOperand);
    _stack.add(new _BranchContext<Variable, Type>(conditionInfo));
    _current = isAnd ? conditionInfo.ifTrue : conditionInfo.ifFalse;
  }

  @override
  void logicalNot_end(Expression notExpression, Expression operand) {
    ExpressionInfo<Variable, Type> conditionInfo = _expressionEnd(operand);
    _storeExpressionInfo(notExpression, conditionInfo.invert());
  }

  @override
  void nonNullAssert_end(Expression operand) {
    Variable? operandVariable = _getExpressionVariable(operand);
    if (operandVariable != null) {
      _current =
          _current.tryMarkNonNullable(typeOperations, operandVariable).ifTrue;
    }
  }

  @override
  void nullAwareAccess_end() {
    _NullAwareAccessContext<Variable, Type> context =
        _stack.removeLast() as _NullAwareAccessContext<Variable, Type>;
    _current = _merge(_current, context._previous);
  }

  @override
  void nullAwareAccess_rightBegin(Expression? target, Type targetType) {
    // ignore:unnecessary_null_comparison
    assert(targetType != null);
    _current = _current.split();
    _stack.add(new _NullAwareAccessContext<Variable, Type>(_current));
    Variable? targetVariable = _getExpressionVariable(target);
    if (targetVariable != null) {
      _current =
          _current.tryMarkNonNullable(typeOperations, targetVariable).ifTrue;
    }
  }

  @override
  void nullLiteral(Expression expression) {
    _storeExpressionInfo(expression, new _NullInfo(_current));
  }

  @override
  void parenthesizedExpression(
      Expression outerExpression, Expression innerExpression) {
    forwardExpression(outerExpression, innerExpression);
  }

  @override
  void promote(Variable variable, Type type) {
    _current =
        _current.tryPromoteForTypeCheck(typeOperations, variable, type).ifTrue;
  }

  @override
  Type? promotedType(Variable variable) {
    return _current.infoFor(variable).promotedTypes?.last;
  }

  @override
  SsaNode<Variable, Type>? ssaNodeForTesting(Variable variable) =>
      _current.variableInfo[variable]?.ssaNode;

  @override
  void switchStatement_beginCase(bool hasLabel, Node node) {
    AssignedVariablesNodeInfo<Variable> info =
        _assignedVariables._getInfoForNode(node);
    _SimpleStatementContext<Variable, Type> context =
        _stack.last as _SimpleStatementContext<Variable, Type>;
    if (hasLabel) {
      _current =
          context._previous.conservativeJoin(info._written, info._captured);
    } else {
      _current = context._previous;
    }
  }

  @override
  void switchStatement_end(bool isExhaustive) {
    _SimpleStatementContext<Variable, Type> context =
        _stack.removeLast() as _SimpleStatementContext<Variable, Type>;
    FlowModel<Variable, Type>? breakState = context._breakModel;

    // It is allowed to "fall off" the end of a switch statement, so join the
    // current state to any breaks that were found previously.
    breakState = _join(breakState, _current);

    // And, if there is an implicit fall-through default, join it to any breaks.
    if (!isExhaustive) breakState = _join(breakState, context._previous);

    _current = breakState.unsplit();
  }

  @override
  void switchStatement_expressionEnd(Statement switchStatement) {
    _current = _current.split();
    _SimpleStatementContext<Variable, Type> context =
        new _SimpleStatementContext<Variable, Type>(
            _current.reachable.parent!, _current);
    _stack.add(context);
    _statementToContext[switchStatement] = context;
  }

  @override
  void tryCatchStatement_bodyBegin() {
    _current = _current.split();
    _stack.add(new _TryContext<Variable, Type>(_current));
  }

  @override
  void tryCatchStatement_bodyEnd(Node body) {
    FlowModel<Variable, Type> afterBody = _current;

    _TryContext<Variable, Type> context =
        _stack.last as _TryContext<Variable, Type>;
    FlowModel<Variable, Type> beforeBody = context._previous;

    AssignedVariablesNodeInfo<Variable> info =
        _assignedVariables._getInfoForNode(body);
    FlowModel<Variable, Type> beforeCatch =
        beforeBody.conservativeJoin(info._written, info._captured);

    context._beforeCatch = beforeCatch;
    context._afterBodyAndCatches = afterBody;
  }

  @override
  void tryCatchStatement_catchBegin(
      Variable? exceptionVariable, Variable? stackTraceVariable) {
    _TryContext<Variable, Type> context =
        _stack.last as _TryContext<Variable, Type>;
    _current = context._beforeCatch!;
    if (exceptionVariable != null) {
      _current = _current.declare(exceptionVariable, true);
    }
    if (stackTraceVariable != null) {
      _current = _current.declare(stackTraceVariable, true);
    }
  }

  @override
  void tryCatchStatement_catchEnd() {
    _TryContext<Variable, Type> context =
        _stack.last as _TryContext<Variable, Type>;
    context._afterBodyAndCatches =
        _join(context._afterBodyAndCatches, _current);
  }

  @override
  void tryCatchStatement_end() {
    _TryContext<Variable, Type> context =
        _stack.removeLast() as _TryContext<Variable, Type>;
    _current = context._afterBodyAndCatches!.unsplit();
  }

  @override
  void tryFinallyStatement_bodyBegin() {
    _stack.add(new _TryFinallyContext<Variable, Type>(_current));
  }

  @override
  void tryFinallyStatement_end(Node finallyBlock) {
    AssignedVariablesNodeInfo<Variable> info =
        _assignedVariables._getInfoForNode(finallyBlock);
    _TryFinallyContext<Variable, Type> context =
        _stack.removeLast() as _TryFinallyContext<Variable, Type>;
    if (allowLocalBooleanVarsToPromote) {
      _current = context._afterBodyAndCatches!
          .attachFinally(typeOperations, context._beforeFinally, _current);
    } else {
      _current = _current.restrict(
          typeOperations, context._afterBodyAndCatches!, info._written);
    }
  }

  @override
  void tryFinallyStatement_finallyBegin(Node body) {
    AssignedVariablesNodeInfo<Variable> info =
        _assignedVariables._getInfoForNode(body);
    _TryFinallyContext<Variable, Type> context =
        _stack.last as _TryFinallyContext<Variable, Type>;
    context._afterBodyAndCatches = _current;
    _current = _join(_current,
        context._previous.conservativeJoin(info._written, info._captured));
    context._beforeFinally = _current;
  }

  @override
  Type? variableRead(Expression expression, Variable variable) {
    _storeExpressionVariable(expression, variable);
    VariableModel<Variable, Type> variableModel = _current.infoFor(variable);
    if (allowLocalBooleanVarsToPromote) {
      ExpressionInfo<Variable, Type>? expressionInfo = variableModel
          .ssaNode?.expressionInfo
          ?.rebaseForward(typeOperations, _current);
      if (expressionInfo != null) {
        _storeExpressionInfo(expression, expressionInfo);
      }
    }
    return variableModel.promotedTypes?.last;
  }

  @override
  void whileStatement_bodyBegin(
      Statement whileStatement, Expression condition) {
    ExpressionInfo<Variable, Type> conditionInfo = _expressionEnd(condition);
    _WhileContext<Variable, Type> context = new _WhileContext<Variable, Type>(
        _current.reachable.parent!, conditionInfo);
    _stack.add(context);
    _statementToContext[whileStatement] = context;
    _current = conditionInfo.ifTrue;
  }

  @override
  void whileStatement_conditionBegin(Node node) {
    _current = _current.split();
    AssignedVariablesNodeInfo<Variable> info =
        _assignedVariables._getInfoForNode(node);
    _current = _current.conservativeJoin(info._written, info._captured);
  }

  @override
  void whileStatement_end() {
    _WhileContext<Variable, Type> context =
        _stack.removeLast() as _WhileContext<Variable, Type>;
    _current = _merge(context._conditionInfo.ifFalse, context._breakModel)
        .inheritTested(typeOperations, _current);
  }

  @override
  void write(
      Variable variable, Type writtenType, Expression? writtenExpression) {
    ExpressionInfo<Variable, Type>? expressionInfo = writtenExpression == null
        ? null
        : _getExpressionInfo(writtenExpression);
    SsaNode<Variable, Type> newSsaNode = new SsaNode<Variable, Type>(
        expressionInfo is _TrivialExpressionInfo ? null : expressionInfo);
    _current =
        _current.write(variable, writtenType, newSsaNode, typeOperations);
  }

  void _dumpState() {
    print('  current: $_current');
    print('  expressionWithInfo: $_expressionWithInfo');
    print('  expressionInfo: $_expressionInfo');
    print('  expressionWithVariable: $_expressionWithVariable');
    print('  expressionVariable: $_expressionVariable');
    print('  stack:');
    for (_FlowContext stackEntry in _stack.reversed) {
      print('    $stackEntry');
    }
  }

  /// Gets the [ExpressionInfo] associated with the [expression] (which should
  /// be the last expression that was traversed).  If there is no
  /// [ExpressionInfo] associated with the [expression], then a fresh
  /// [ExpressionInfo] is created recording the current flow analysis state.
  ExpressionInfo<Variable, Type> _expressionEnd(Expression expression) =>
      _getExpressionInfo(expression) ?? new _TrivialExpressionInfo(_current);

  /// Gets the [ExpressionInfo] associated with the [expression] (which should
  /// be the last expression that was traversed).  If there is no
  /// [ExpressionInfo] associated with the [expression], then `null` is
  /// returned.
  ExpressionInfo<Variable, Type>? _getExpressionInfo(Expression expression) {
    if (identical(expression, _expressionWithInfo)) {
      ExpressionInfo<Variable, Type>? expressionInfo = _expressionInfo;
      _expressionInfo = null;
      return expressionInfo;
    } else {
      return null;
    }
  }

  /// Gets the [Variable] associated with the [expression] (which should be the
  /// last expression that was traversed).  If there is no [Variable] associated
  /// with the [expression], then `null` is returned.
  Variable? _getExpressionVariable(Expression? expression) {
    if (identical(expression, _expressionWithVariable)) {
      Variable? expressionVariable = _expressionVariable;
      _expressionVariable = null;
      return expressionVariable;
    } else {
      return null;
    }
  }

  FlowModel<Variable, Type> _join(FlowModel<Variable, Type>? first,
          FlowModel<Variable, Type>? second) =>
      FlowModel.join(typeOperations, first, second, _current._emptyVariableMap);

  FlowModel<Variable, Type> _merge(
          FlowModel<Variable, Type> first, FlowModel<Variable, Type>? second) =>
      FlowModel.merge(
          typeOperations, first, second, _current._emptyVariableMap);

  /// Associates [expression], which should be the most recently visited
  /// expression, with the given [expressionInfo] object, and updates the
  /// current flow model state to correspond to it.
  void _storeExpressionInfo(
      Expression expression, ExpressionInfo<Variable, Type> expressionInfo) {
    _expressionWithInfo = expression;
    _expressionInfo = expressionInfo;
    _current = expressionInfo.after;
  }

  /// Associates [expression], which should be the most recently visited
  /// expression, with the given [Variable] object.
  void _storeExpressionVariable(
      Expression expression, Variable expressionVariable) {
    _expressionWithVariable = expression;
    _expressionVariable = expressionVariable;
  }
}

/// Base class for objects representing constructs in the Dart programming
/// language for which flow analysis information needs to be tracked.
abstract class _FlowContext {}

/// [_FlowContext] representing a function expression.
class _FunctionExpressionContext<Variable extends Object, Type extends Object>
    extends _SimpleContext<Variable, Type> {
  _FunctionExpressionContext(FlowModel<Variable, Type> previous)
      : super(previous);

  @override
  String toString() => '_FunctionExpressionContext(previous: $_previous)';
}

/// [_FlowContext] representing an `if` statement.
class _IfContext<Variable extends Object, Type extends Object>
    extends _BranchContext<Variable, Type> {
  /// Flow model associated with the state of program execution after the `if`
  /// statement executes, in the circumstance where the "then" branch is taken.
  FlowModel<Variable, Type>? _afterThen;

  _IfContext(ExpressionInfo<Variable, Type> conditionInfo)
      : super(conditionInfo);

  @override
  String toString() =>
      '_IfContext(conditionInfo: $_conditionInfo, afterThen: $_afterThen)';
}

/// [_FlowContext] representing an "if-null" (`??`) expression.
class _IfNullExpressionContext<Variable extends Object, Type extends Object>
    extends _SimpleContext<Variable, Type> {
  _IfNullExpressionContext(FlowModel<Variable, Type> previous)
      : super(previous);

  @override
  String toString() => '_IfNullExpressionContext(previous: $_previous)';
}

/// [_FlowContext] representing a null aware access (`?.`).
class _NullAwareAccessContext<Variable extends Object, Type extends Object>
    extends _SimpleContext<Variable, Type> {
  _NullAwareAccessContext(FlowModel<Variable, Type> previous) : super(previous);

  @override
  String toString() => '_NullAwareAccessContext(previous: $_previous)';
}

/// [ExpressionInfo] representing a `null` literal.
class _NullInfo<Variable extends Object, Type extends Object>
    implements ExpressionInfo<Variable, Type> {
  @override
  final FlowModel<Variable, Type> after;

  _NullInfo(this.after);

  @override
  FlowModel<Variable, Type> get ifFalse => after;

  @override
  FlowModel<Variable, Type> get ifTrue => after;

  @override
  ExpressionInfo<Variable, Type> invert() {
    // This should only happen if `!null` is encountered.  That should never
    // happen for a properly typed program, but we need to handle it so we can
    // give reasonable errors for an improperly typed program.
    return this;
  }

  @override
  ExpressionInfo<Variable, Type>? rebaseForward(
          TypeOperations<Variable, Type> typeOperations,
          FlowModel<Variable, Type> base) =>
      null;
}

/// [_FlowContext] representing a language construct for which flow analysis
/// must store a flow model state to be retrieved later, such as a `try`
/// statement, function expression, or "if-null" (`??`) expression.
abstract class _SimpleContext<Variable extends Object, Type extends Object>
    extends _FlowContext {
  /// The stored state.  For a `try` statement, this is the state from the
  /// beginning of the `try` block.  For a function expression, this is the
  /// state at the point the function expression was created.  For an "if-null"
  /// expression, this is the state after execution of the expression before the
  /// `??`.
  final FlowModel<Variable, Type> _previous;

  _SimpleContext(this._previous);
}

/// [_FlowContext] representing a language construct that can be targeted by
/// `break` or `continue` statements, and for which flow analysis must store a
/// flow model state to be retrieved later.  Examples include "for each" and
/// `switch` statements.
class _SimpleStatementContext<Variable extends Object, Type extends Object>
    extends _BranchTargetContext<Variable, Type> {
  /// The stored state.  For a "for each" statement, this is the state after
  /// evaluation of the iterable.  For a `switch` statement, this is the state
  /// after evaluation of the switch expression.
  final FlowModel<Variable, Type> _previous;

  _SimpleStatementContext(Reachability checkpoint, this._previous)
      : super(checkpoint);

  @override
  String toString() => '_SimpleStatementContext(breakModel: $_breakModel, '
      'continueModel: $_continueModel, previous: $_previous, '
      'checkpoint: $_checkpoint)';
}

/// Specialization of [ExpressionInfo] for the case where the information we
/// have about the expression is trivial (meaning we know by construction that
/// the expression's [after], [ifTrue], and [ifFalse] models are all the same).
class _TrivialExpressionInfo<Variable extends Object, Type extends Object>
    implements ExpressionInfo<Variable, Type> {
  @override
  final FlowModel<Variable, Type> after;

  _TrivialExpressionInfo(this.after);

  @override
  FlowModel<Variable, Type> get ifFalse => after;

  @override
  FlowModel<Variable, Type> get ifTrue => after;

  @override
  ExpressionInfo<Variable, Type> invert() => this;

  @override
  ExpressionInfo<Variable, Type> rebaseForward(
          TypeOperations<Variable, Type> typeOperations,
          FlowModel<Variable, Type> base) =>
      new _TrivialExpressionInfo(base);
}

/// [_FlowContext] representing a try statement.
class _TryContext<Variable extends Object, Type extends Object>
    extends _SimpleContext<Variable, Type> {
  /// If the statement is a "try/catch" statement, the flow model representing
  /// program state at the top of any `catch` block.
  FlowModel<Variable, Type>? _beforeCatch;

  /// If the statement is a "try/catch" statement, the accumulated flow model
  /// representing program state after the `try` block or one of the `catch`
  /// blocks has finished executing.  If the statement is a "try/finally"
  /// statement, the flow model representing program state after the `try` block
  /// has finished executing.
  FlowModel<Variable, Type>? _afterBodyAndCatches;

  _TryContext(FlowModel<Variable, Type> previous) : super(previous);

  @override
  String toString() =>
      '_TryContext(previous: $_previous, beforeCatch: $_beforeCatch, '
      'afterBodyAndCatches: $_afterBodyAndCatches)';
}

class _TryFinallyContext<Variable extends Object, Type extends Object>
    extends _TryContext<Variable, Type> {
  /// The flow model representing program state at the top of the `finally`
  /// block.
  late FlowModel<Variable, Type> _beforeFinally;

  _TryFinallyContext(FlowModel<Variable, Type> previous) : super(previous);
}

/// [_FlowContext] representing a `while` loop (or a C-style `for` loop, which
/// is functionally similar).
class _WhileContext<Variable extends Object, Type extends Object>
    extends _BranchTargetContext<Variable, Type> {
  /// Flow models associated with the loop condition.
  final ExpressionInfo<Variable, Type> _conditionInfo;

  _WhileContext(Reachability checkpoint, this._conditionInfo)
      : super(checkpoint);

  @override
  String toString() => '_WhileContext(breakModel: $_breakModel, '
      'continueModel: $_continueModel, conditionInfo: $_conditionInfo, '
      'checkpoint: $_checkpoint)';
}
