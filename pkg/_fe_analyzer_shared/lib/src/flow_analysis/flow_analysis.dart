// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

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
class AssignedVariables<Node, Variable> {
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
  /// local function, or closure which might need to be queried later.
  ///
  /// [isClosure] should be true if the node is a local function or closure.
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
  /// local function, or closure which might need to be queried later.
  ///
  /// [isClosure] should be true if the node is a local function or closure.
  ///
  /// In contrast to [endNode], this method doesn't store the data gathered for
  /// the node for later use; instead it returns it to the caller.  At a later
  /// time, the caller should pass the returned data to [storeNodeInfo].
  ///
  /// See [beginNode] for more details.
  AssignedVariablesNodeInfo<Variable> deferNode({bool isClosure: false}) {
    AssignedVariablesNodeInfo<Variable> info = _stack.removeLast();
    info._written.removeAll(info._declared);
    info._captured.removeAll(info._declared);
    AssignedVariablesNodeInfo<Variable> last = _stack.last;
    last._written.addAll(info._written);
    last._captured.addAll(info._captured);
    if (isClosure) {
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
  /// local function, or closure which might need to be queried later.
  ///
  /// [isClosure] should be true if the node is a local function or closure.
  ///
  /// This is equivalent to a call to [deferNode] followed immediately by a call
  /// to [storeInfo].
  ///
  /// See [beginNode] for more details.
  void endNode(Node node, {bool isClosure: false}) {
    storeInfo(node, deferNode(isClosure: isClosure));
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

  /// Call this method to register that the node [from] for which information
  /// has been stored is replaced by the node [to].
  // TODO(johnniwinther): Remove this when unified collections are encoded as
  // general elements in the front-end.
  void reassignInfo(Node from, Node to) {
    assert(!_info.containsKey(to), "Node $to already has info: ${_info[to]}");
    AssignedVariablesNodeInfo<Variable> info = _info.remove(from);
    assert(
        info != null,
        'No information for $from (${from.hashCode}) in '
        '{${_info.keys.map((k) => '$k (${k.hashCode})').join(',')}}');

    _info[to] = info;
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
class AssignedVariablesForTesting<Node, Variable>
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
class AssignedVariablesNodeInfo<Variable> {
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
class ExpressionInfo<Variable, Type> {
  /// The state after the expression evaluates, if we don't care what it
  /// evaluates to.
  final FlowModel<Variable, Type> after;

  /// The state after the expression evaluates, if it evaluates to `true`.
  final FlowModel<Variable, Type> ifTrue;

  /// The state after the expression evaluates, if it evaluates to `false`.
  final FlowModel<Variable, Type> ifFalse;

  ExpressionInfo(this.after, this.ifTrue, this.ifFalse);

  @override
  String toString() =>
      'ExpressionInfo(after: $after, _ifTrue: $ifTrue, ifFalse: $ifFalse)';

  /// Compute a new [ExpressionInfo] based on this one, but with the roles of
  /// [ifTrue] and [ifFalse] reversed.
  static ExpressionInfo<Variable, Type> invert<Variable, Type>(
          ExpressionInfo<Variable, Type> info) =>
      new ExpressionInfo<Variable, Type>(info.after, info.ifFalse, info.ifTrue);
}

/// Implementation of flow analysis to be shared between the analyzer and the
/// front end.
///
/// The client should create one instance of this class for every method, field,
/// or top level variable to be analyzed, and call the appropriate methods
/// while visiting the code for type inference.
abstract class FlowAnalysis<Node, Statement extends Node, Expression, Variable,
    Type> {
  factory FlowAnalysis(TypeOperations<Variable, Type> typeOperations,
      AssignedVariables<Node, Variable> assignedVariables) {
    return new _FlowAnalysisImpl(typeOperations, assignedVariables);
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
      {bool notEqual = false});

  /// Call this method just after visiting the left hand side of a binary `==`
  /// or `!=` expression.
  void equalityOp_rightBegin(Expression leftOperand);

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
  void for_bodyBegin(Statement node, Expression condition);

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
  void forEach_bodyBegin(Node node, Variable loopVariable, Type writtenType);

  /// Call this method just before visiting the body of a "for-in" statement or
  /// collection element.  See [forEach_bodyBegin] for details.
  void forEach_end();

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
  void ifNullExpression_rightBegin(Expression leftHandSide);

  /// Call this method after visiting the "then" part of an if statement, and
  /// before visiting the "else" part.
  void ifStatement_elseBegin();

  /// Call this method after visiting an if statement.
  void ifStatement_end(bool hasElse);

  /// Call this method after visiting the condition part of an if statement.
  /// [condition] should be the if statement's condition.
  ///
  /// The order of visiting an if statement with no "else" part should be:
  /// - Visit the condition
  /// - Call [ifStatement_thenBegin]
  /// - Visit the "then" statement
  /// - Call [ifStatement_end], passing `false` for `hasElse`.
  ///
  /// The order of visiting an if statement with an "else" part should be:
  /// - Visit the condition
  /// - Call [ifStatement_thenBegin]
  /// - Visit the "then" statement
  /// - Call [ifStatement_elseBegin]
  /// - Visit the "else" statement
  /// - Call [ifStatement_end], passing `true` for `hasElse`.
  void ifStatement_thenBegin(Expression condition);

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
  void labeledStatement_begin(Node node);

  /// Call this method after visiting a labeled statement.
  void labeledStatement_end();

  /// Call this method after visiting the RHS of a logical binary operation
  /// ("||" or "&&").
  /// [wholeExpression] should be the whole logical binary expression.
  /// [rightOperand] should be the RHS.  [isAnd] should indicate whether the
  /// logical operator is "&&" or "||".
  void logicalBinaryOp_end(Expression wholeExpression, Expression rightOperand,
      {@required bool isAnd});

  /// Call this method after visiting the LHS of a logical binary operation
  /// ("||" or "&&").
  /// [rightOperand] should be the LHS.  [isAnd] should indicate whether the
  /// logical operator is "&&" or "||".
  void logicalBinaryOp_rightBegin(Expression leftOperand,
      {@required bool isAnd});

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
  /// Note that [nullAwareAccess_end] should be called after the conclusion
  /// of any null-shorting that is caused by the `?.`.  So, for example, if the
  /// code being analyzed is `x?.y?.z(x)`, [nullAwareAccess_rightBegin] should
  /// be called once upon reaching each `?.`, but [nullAwareAccess_end] should
  /// not be called until after processing the method call to `z(x)`.
  void nullAwareAccess_rightBegin(Expression target);

  /// Call this method when encountering an expression that is a `null` literal.
  void nullLiteral(Expression expression);

  /// Call this method just after visiting a parenthesized expression.
  ///
  /// This is only necessary if the implementation uses a different [Expression]
  /// object to represent a parenthesized expression and its contents.
  void parenthesizedExpression(
      Expression outerExpression, Expression innerExpression);

  /// Retrieves the type that the [variable] is promoted to, if the [variable]
  /// is currently promoted.  Otherwise returns `null`.
  ///
  /// For testing only.  Please use [variableRead] instead.
  @visibleForTesting
  Type promotedType(Variable variable);

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
      Variable exceptionVariable, Variable stackTraceVariable);

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
  Type variableRead(Expression expression, Variable variable);

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
  void write(Variable variable, Type writtenType);
}

/// Alternate implementation of [FlowAnalysis] that prints out inputs and output
/// at the API boundary, for assistance in debugging.
class FlowAnalysisDebug<Node, Statement extends Node, Expression, Variable,
    Type> implements FlowAnalysis<Node, Statement, Expression, Variable, Type> {
  _FlowAnalysisImpl<Node, Statement, Expression, Variable, Type> _wrapped;

  bool _exceptionOccurred = false;

  factory FlowAnalysisDebug(TypeOperations<Variable, Type> typeOperations,
      AssignedVariables<Node, Variable> assignedVariables) {
    print('FlowAnalysisDebug()');
    return new FlowAnalysisDebug._(
        new _FlowAnalysisImpl(typeOperations, assignedVariables));
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
      {bool notEqual = false}) {
    _wrap(
        'equalityOp_end($wholeExpression, $rightOperand, notEqual: $notEqual)',
        () => _wrapped.equalityOp_end(wholeExpression, rightOperand,
            notEqual: notEqual));
  }

  @override
  void equalityOp_rightBegin(Expression leftOperand) {
    _wrap('equalityOp_rightBegin($leftOperand)',
        () => _wrapped.equalityOp_rightBegin(leftOperand));
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
  void for_bodyBegin(Statement node, Expression condition) {
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
  void forEach_bodyBegin(Node node, Variable loopVariable, Type writtenType) {
    return _wrap('forEach_bodyBegin($node, $loopVariable, $writtenType)',
        () => _wrapped.forEach_bodyBegin(node, loopVariable, writtenType));
  }

  @override
  void forEach_end() {
    return _wrap('forEach_end()', () => _wrapped.forEach_end());
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
  void ifNullExpression_rightBegin(Expression leftHandSide) {
    return _wrap('ifNullExpression_rightBegin($leftHandSide)',
        () => _wrapped.ifNullExpression_rightBegin(leftHandSide));
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
    return _wrap('isUnassigned($variable)', () => _wrapped.isAssigned(variable),
        isQuery: true);
  }

  @override
  void labeledStatement_begin(Node node) {
    return _wrap('labeledStatement_begin($node)',
        () => _wrapped.labeledStatement_begin(node));
  }

  @override
  void labeledStatement_end() {
    return _wrap(
        'labeledStatement_end()', () => _wrapped.labeledStatement_end());
  }

  @override
  void logicalBinaryOp_end(Expression wholeExpression, Expression rightOperand,
      {@required bool isAnd}) {
    _wrap(
        'logicalBinaryOp_end($wholeExpression, $rightOperand, isAnd: $isAnd)',
        () => _wrapped.logicalBinaryOp_end(wholeExpression, rightOperand,
            isAnd: isAnd));
  }

  @override
  void logicalBinaryOp_rightBegin(Expression leftOperand,
      {@required bool isAnd}) {
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
  void nullAwareAccess_rightBegin(Expression target) {
    _wrap('nullAwareAccess_rightBegin($target)',
        () => _wrapped.nullAwareAccess_rightBegin(target));
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
  Type promotedType(Variable variable) {
    return _wrap(
        'promotedType($variable)', () => _wrapped.promotedType(variable),
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
      Variable exceptionVariable, Variable stackTraceVariable) {
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
  Type variableRead(Expression expression, Variable variable) {
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
  void write(Variable variable, Type writtenType) {
    _wrap('write($variable, $writtenType)',
        () => _wrapped.write(variable, writtenType));
  }

  T _wrap<T>(String description, T callback(),
      {bool isQuery: false, bool isPure}) {
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
class FlowModel<Variable, Type> {
  /// Indicates whether this point in the control flow is reachable.
  final bool reachable;

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

  /// Variable model for variables that have never been seen before.
  final VariableModel<Variable, Type> _freshVariableInfo;

  /// The empty map, used to [join] variables.
  final Map<Variable, VariableModel<Variable, Type>> _emptyVariableMap = {};

  /// Creates a state object with the given [reachable] status.  All variables
  /// are assumed to be unpromoted and already assigned, so joining another
  /// state with this one will have no effect on it.
  FlowModel(bool reachable)
      : this._(
          reachable,
          const {},
        );

  FlowModel._(this.reachable, this.variableInfo)
      : _freshVariableInfo = new VariableModel.fresh() {
    assert(() {
      for (VariableModel<Variable, Type> value in variableInfo.values) {
        assert(value != null);
      }
      return true;
    }());
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
    Map<Variable, VariableModel<Variable, Type>> newVariableInfo;

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
      VariableModel<Variable, Type> info = variableInfo[variable];
      if (info == null) {
        (newVariableInfo ??=
            new Map<Variable, VariableModel<Variable, Type>>.from(
                variableInfo))[variable] = new VariableModel<Variable, Type>(
            null, const [], false, false, true);
      } else if (!info.writeCaptured) {
        (newVariableInfo ??=
            new Map<Variable, VariableModel<Variable, Type>>.from(
                variableInfo))[variable] = info.writeCapture();
      }
    }

    FlowModel<Variable, Type> result = newVariableInfo == null
        ? this
        : new FlowModel<Variable, Type>._(reachable, newVariableInfo);

    return result;
  }

  /// Register a declaration of the [variable].
  /// Should also be called for function parameters.
  ///
  /// A local variable is [initialized] if its declaration has an initializer.
  /// A function parameter is always initialized, so [initialized] is `true`.
  FlowModel<Variable, Type> declare(Variable variable, bool initialized) {
    VariableModel<Variable, Type> newInfoForVar = _freshVariableInfo;
    if (initialized) {
      newInfoForVar = newInfoForVar.initialize();
    }

    return _updateVariableInfo(variable, newInfoForVar);
  }

  /// Gets the info for the given [variable], creating it if it doesn't exist.
  VariableModel<Variable, Type> infoFor(Variable variable) =>
      variableInfo[variable] ?? _freshVariableInfo;

  /// Updates the state to indicate that variables that are not definitely
  /// unassigned in the [other], are also not definitely unassigned in the
  /// result.
  FlowModel<Variable, Type> joinUnassigned(FlowModel<Variable, Type> other) {
    Map<Variable, VariableModel<Variable, Type>> newVariableInfo;

    void markNotUnassigned(Variable variable) {
      VariableModel<Variable, Type> info = variableInfo[variable];
      if (info == null) return;

      VariableModel<Variable, Type> newInfo = info.markNotUnassigned();
      if (identical(newInfo, info)) return;

      (newVariableInfo ??=
          new Map<Variable, VariableModel<Variable, Type>>.from(
              variableInfo))[variable] = newInfo;
    }

    for (Variable variable in other.variableInfo.keys) {
      VariableModel<Variable, Type> otherInfo = other.variableInfo[variable];
      if (!otherInfo.unassigned) {
        markNotUnassigned(variable);
      }
    }

    if (newVariableInfo == null) return this;

    return new FlowModel<Variable, Type>._(reachable, newVariableInfo);
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
    bool newReachable = reachable && other.reachable;

    Map<Variable, VariableModel<Variable, Type>> newVariableInfo =
        <Variable, VariableModel<Variable, Type>>{};
    bool variableInfoMatchesThis = true;
    bool variableInfoMatchesOther = true;
    for (MapEntry<Variable, VariableModel<Variable, Type>> entry
        in variableInfo.entries) {
      Variable variable = entry.key;
      VariableModel<Variable, Type> thisModel = entry.value;
      VariableModel<Variable, Type> otherModel = other.variableInfo[variable];
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

  /// Updates the state to indicate whether the control flow path is
  /// [reachable].
  FlowModel<Variable, Type> setReachable(bool reachable) {
    if (this.reachable == reachable) return this;

    return new FlowModel<Variable, Type>._(reachable, variableInfo);
  }

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
      return new ExpressionInfo<Variable, Type>(this, this, this);
    }

    Type previousType = info.promotedTypes?.last;
    previousType ??= typeOperations.variableType(variable);

    Type newType = typeOperations.promoteToNonNull(previousType);
    if (typeOperations.isSameType(newType, previousType)) {
      return new ExpressionInfo<Variable, Type>(this, this, this);
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

    Type previousType = info.promotedTypes?.last;
    previousType ??= typeOperations.variableType(variable);

    Type newType = typeOperations.tryPromoteToType(type, previousType);
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
      return new ExpressionInfo<Variable, Type>(this, this, this);
    }

    Type previousType = info.promotedTypes?.last;
    previousType ??= typeOperations.variableType(variable);

    FlowModel<Variable, Type> modelIfSuccessful = this;
    Type typeIfSuccess = typeOperations.tryPromoteToType(type, previousType);
    if (typeIfSuccess != null &&
        !typeOperations.isSameType(typeIfSuccess, previousType)) {
      assert(typeOperations.isSubtypeOf(typeIfSuccess, previousType),
          "Expected $typeIfSuccess to be a subtype of $previousType.");
      modelIfSuccessful =
          _finishTypeTest(typeOperations, variable, info, type, typeIfSuccess);
    }

    Type factoredType = typeOperations.factor(previousType, type);
    Type typeIfFailed = typeOperations.isSameType(factoredType, previousType)
        ? null
        : factoredType;
    FlowModel<Variable, Type> modelIfFailed =
        _finishTypeTest(typeOperations, variable, info, type, typeIfFailed);

    return new ExpressionInfo<Variable, Type>(
        this, modelIfSuccessful, modelIfFailed);
  }

  /// Updates the state to indicate that an assignment was made to the given
  /// [variable].  The variable is marked as definitely assigned, and any
  /// previous type promotion is removed.
  FlowModel<Variable, Type> write(Variable variable, Type writtenType,
      TypeOperations<Variable, Type> typeOperations) {
    VariableModel<Variable, Type> infoForVar = variableInfo[variable];
    if (infoForVar == null) return this;

    VariableModel<Variable, Type> newInfoForVar =
        infoForVar.write(variable, writtenType, typeOperations);
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
    Type testedType,
    Type promotedType,
  ) {
    List<Type> newTested = info.tested;
    if (testedType != null) {
      newTested = VariableModel._addTypeToUniqueList(
          info.tested, testedType, typeOperations);
    }

    List<Type> newPromotedTypes = info.promotedTypes;
    if (promotedType != null) {
      newPromotedTypes =
          VariableModel._addToPromotedTypes(info.promotedTypes, promotedType);
    }

    return identical(newTested, info.tested) &&
            identical(newPromotedTypes, info.promotedTypes)
        ? this
        : _updateVariableInfo(
            variable,
            new VariableModel<Variable, Type>(newPromotedTypes, newTested,
                info.assigned, info.unassigned, info.writeCaptured));
  }

  /// Returns a new [FlowModel] where the information for [variable] is replaced
  /// with [model].
  FlowModel<Variable, Type> _updateVariableInfo(
      Variable variable, VariableModel<Variable, Type> model) {
    Map<Variable, VariableModel<Variable, Type>> newVariableInfo =
        new Map<Variable, VariableModel<Variable, Type>>.from(variableInfo);
    newVariableInfo[variable] = model;
    return new FlowModel<Variable, Type>._(reachable, newVariableInfo);
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
  static FlowModel<Variable, Type> join<Variable, Type>(
    TypeOperations<Variable, Type> typeOperations,
    FlowModel<Variable, Type> first,
    FlowModel<Variable, Type> second,
    Map<Variable, VariableModel<Variable, Type>> emptyVariableMap,
  ) {
    if (first == null) return second;
    if (second == null) return first;

    if (first.reachable && !second.reachable) return first;
    if (!first.reachable && second.reachable) return second;

    bool newReachable = first.reachable || second.reachable;
    Map<Variable, VariableModel<Variable, Type>> newVariableInfo =
        FlowModel.joinVariableInfo(typeOperations, first.variableInfo,
            second.variableInfo, emptyVariableMap);

    return FlowModel._identicalOrNew(
        first, second, newReachable, newVariableInfo);
  }

  /// Joins two "variable info" maps.  See [join] for details.
  @visibleForTesting
  static Map<Variable, VariableModel<Variable, Type>>
      joinVariableInfo<Variable, Type>(
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
      VariableModel<Variable, Type> secondModel = second[variable];
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

  /// Creates a new [FlowModel] object, unless it is equivalent to either
  /// [first] or [second], in which case one of those objects is re-used.
  static FlowModel<Variable, Type> _identicalOrNew<Variable, Type>(
      FlowModel<Variable, Type> first,
      FlowModel<Variable, Type> second,
      bool newReachable,
      Map<Variable, VariableModel<Variable, Type>> newVariableInfo) {
    if (first.reachable == newReachable &&
        identical(first.variableInfo, newVariableInfo)) {
      return first;
    }
    if (second.reachable == newReachable &&
        identical(second.variableInfo, newVariableInfo)) {
      return second;
    }

    return new FlowModel<Variable, Type>._(newReachable, newVariableInfo);
  }

  /// Determines whether the given "variableInfo" maps are equivalent.
  ///
  /// The equivalence check is shallow; if two variables' models are not
  /// identical, we return `false`.
  static bool _variableInfosEqual<Variable, Type>(
      Map<Variable, VariableModel<Variable, Type>> p1,
      Map<Variable, VariableModel<Variable, Type>> p2) {
    if (p1.length != p2.length) return false;
    if (!p1.keys.toSet().containsAll(p2.keys)) return false;
    for (MapEntry<Variable, VariableModel<Variable, Type>> entry
        in p1.entries) {
      VariableModel<Variable, Type> p1Value = entry.value;
      VariableModel<Variable, Type> p2Value = p2[entry.key];
      if (!identical(p1Value, p2Value)) {
        return false;
      }
    }
    return true;
  }
}

/// Operations on types, abstracted from concrete type interfaces.
abstract class TypeOperations<Variable, Type> {
  /// Returns the "remainder" of [from] when [what] has been removed from
  /// consideration by an instance check.
  Type factor(Type from, Type what);

  /// Whether the possible promotion from [from] to [to] should be forced, given
  /// the current [promotedTypes], and [newPromotedTypes] resulting from
  /// possible demotion.
  ///
  /// It is not expected that any implementation would override this except for
  /// the migration engine.
  bool forcePromotion(Type to, Type from, List<Type> promotedTypes,
          List<Type> newPromotedTypes) =>
      false;

  /// Return `true` if the [variable] is a local variable (not a formal
  /// parameter), and it has no declared type (no explicit type, and not
  /// initializer).
  bool isLocalVariableWithoutDeclaredType(Variable variable);

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
  List<Type> refinePromotedTypes(
          List<Type> chain1, List<Type> chain2, List<Type> promotedTypes) =>
      promotedTypes;

  /// Tries to promote to the first type from the second type, and returns the
  /// promoted type if it succeeds, otherwise null.
  Type tryPromoteToType(Type to, Type from);

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
class VariableModel<Variable, Type> {
  /// Sequence of types that the variable has been promoted to, where each
  /// element of the sequence is a subtype of the previous.  Null if the
  /// variable hasn't been promoted.
  final List<Type> promotedTypes;

  /// List of types that the variable has been tested against in all code paths
  /// leading to the given point in the source code.
  final List<Type> tested;

  /// Indicates whether the variable has definitely been assigned.
  final bool assigned;

  /// Indicates whether the variable is unassigned.
  final bool unassigned;

  /// Indicates whether the variable has been write captured.
  final bool writeCaptured;

  VariableModel(this.promotedTypes, this.tested, this.assigned, this.unassigned,
      this.writeCaptured) {
    assert(!(assigned && unassigned),
        "Can't be both definitely assigned and unassigned");
    assert(promotedTypes == null || promotedTypes.isNotEmpty);
    assert(!writeCaptured || promotedTypes == null,
        "Write-captured variables can't be promoted");
    assert(!(writeCaptured && unassigned),
        "Write-captured variables can't be definitely unassigned");
    assert(tested != null);
  }

  /// Creates a [VariableModel] representing a variable that's never been seen
  /// before.
  VariableModel.fresh()
      : promotedTypes = null,
        tested = const [],
        assigned = false,
        unassigned = true,
        writeCaptured = false;

  /// Returns a new [VariableModel] in which any promotions present have been
  /// dropped, and the variable has been marked as "not unassigned".
  VariableModel<Variable, Type> discardPromotionsAndMarkNotUnassigned() {
    if (promotedTypes == null && !unassigned) {
      return this;
    }
    return new VariableModel<Variable, Type>(
        null, tested, assigned, false, writeCaptured);
  }

  /// Returns a new [VariableModel] reflecting the fact that the variable was
  /// just initialized.
  VariableModel<Variable, Type> initialize() {
    if (promotedTypes == null && tested.isEmpty && assigned && !unassigned) {
      return this;
    }
    return new VariableModel<Variable, Type>(
        null, const [], true, false, writeCaptured);
  }

  /// Returns a new [VariableModel] reflecting the fact that the variable is
  /// not definitely unassigned.
  VariableModel<Variable, Type> markNotUnassigned() {
    if (!unassigned) return this;

    return new VariableModel<Variable, Type>(
        promotedTypes, tested, assigned, false, writeCaptured);
  }

  /// Returns an updated model reflect a control path that is known to have
  /// previously passed through some [other] state.  See [FlowModel.restrict]
  /// for details.
  VariableModel<Variable, Type> restrict(
      TypeOperations<Variable, Type> typeOperations,
      VariableModel<Variable, Type> otherModel,
      bool unsafe) {
    List<Type> thisPromotedTypes = promotedTypes;
    List<Type> otherPromotedTypes = otherModel.promotedTypes;
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
    List<Type> newPromotedTypes;
    if (newWriteCaptured) {
      // Write-captured variables can't be promoted
      newPromotedTypes = null;
    } else if (unsafe) {
      // There was an assignment to the variable in the "this" path, so none of
      // the promotions from the "other" path can be used.
      newPromotedTypes = thisPromotedTypes;
    } else if (otherPromotedTypes == null) {
      // The other promotion chain contributes nothing so we just use this
      // promotion chain directly.
      newPromotedTypes = thisPromotedTypes;
    } else if (thisPromotedTypes == null) {
      // This promotion chain contributes nothing so we just use the other
      // promotion chain directly.
      newPromotedTypes = otherPromotedTypes;
    } else {
      // Start with otherPromotedTypes and apply each of the promotions in
      // thisPromotedTypes (discarding any that don't follow the ordering
      // invariant)
      newPromotedTypes = otherPromotedTypes;
      Type otherPromotedType = otherPromotedTypes.last;
      for (int i = 0; i < thisPromotedTypes.length; i++) {
        Type nextType = thisPromotedTypes[i];
        if (typeOperations.isSubtypeOf(nextType, otherPromotedType) &&
            !typeOperations.isSameType(nextType, otherPromotedType)) {
          newPromotedTypes = otherPromotedTypes.toList()
            ..addAll(thisPromotedTypes.skip(i));
          break;
        }
      }
    }
    return _identicalOrNew(this, otherModel, newPromotedTypes, tested,
        newAssigned, newUnassigned, newWriteCaptured);
  }

  @override
  String toString() {
    List<String> parts = [];
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
  VariableModel<Variable, Type> write(Variable variable, Type writtenType,
      TypeOperations<Variable, Type> typeOperations) {
    if (writeCaptured) {
      return new VariableModel<Variable, Type>(
          promotedTypes, tested, true, false, writeCaptured);
    }

    if (_isPromotableViaInitialization(typeOperations, variable)) {
      return new VariableModel<Variable, Type>(
          [writtenType], tested, true, false, writeCaptured);
    }

    List<Type> newPromotedTypes = _demoteViaAssignment(
      writtenType,
      typeOperations,
    );

    Type declaredType = typeOperations.variableType(variable);
    newPromotedTypes = _tryPromoteToTypeOfInterest(
        typeOperations, declaredType, newPromotedTypes, writtenType);
    if (identical(promotedTypes, newPromotedTypes) && assigned) return this;

    List<Type> newTested;
    if (newPromotedTypes == null && promotedTypes != null) {
      newTested = const [];
    } else {
      newTested = tested;
    }

    return new VariableModel<Variable, Type>(
        newPromotedTypes, newTested, true, false, writeCaptured);
  }

  /// Returns a new [VariableModel] reflecting the fact that the variable has
  /// been write-captured.
  VariableModel<Variable, Type> writeCapture() {
    return new VariableModel<Variable, Type>(
        null, const [], assigned, false, true);
  }

  List<Type> _demoteViaAssignment(
    Type writtenType,
    TypeOperations<Variable, Type> typeOperations,
  ) {
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

  /// We say that a variable `x` is promotable via initialization given
  /// variable model `VM` if `x` is a local variable (not a formal parameter)
  /// and:
  /// * VM = VariableModel(declared, promoted, tested,
  ///                      assigned, unassigned, captured)
  /// * and `captured` is false
  /// * and `promoted` is empty
  /// * and `x` is declared with no explicit type and no initializer
  /// * and `assigned` is false and `unassigned` is true
  bool _isPromotableViaInitialization<Variable>(
    TypeOperations<Variable, Type> typeOperations,
    Variable variable,
  ) {
    return !writeCaptured &&
        !assigned &&
        unassigned &&
        promotedTypes == null &&
        typeOperations.isLocalVariableWithoutDeclaredType(variable);
  }

  /// Determines whether a variable with the given [promotedTypes] should be
  /// promoted to [writtenType] based on types of interest.  If it should,
  /// returns an updated promotion chain; otherwise returns [promotedTypes]
  /// unchanged.
  ///
  /// Note that since promotion chains are considered immutable, if promotion
  /// is required, a new promotion chain will be created and returned.
  List<Type> _tryPromoteToTypeOfInterest(
      TypeOperations<Variable, Type> typeOperations,
      Type declaredType,
      List<Type> promotedTypes,
      Type writtenType) {
    assert(!writeCaptured);

    if (typeOperations.forcePromotion(
        writtenType, declaredType, this.promotedTypes, promotedTypes)) {
      return _addToPromotedTypes(promotedTypes, writtenType);
    }

    // Figure out if we have any promotion candidates (types that are a
    // supertype of writtenType and a proper subtype of the currently-promoted
    // type).  If at any point we find an exact match, we take it immediately.
    Type currentlyPromotedType = promotedTypes?.last;

    List<Type> result;
    List<Type> candidates = null;

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
      if (!_typeListContains(typeOperations, candidates, type)) {
        candidates.add(type);
        return;
      }
    }

    // The declared type is always a type of interest, but we never promote
    // to the declared type. So, try NonNull of it.
    Type declaredTypeNonNull = typeOperations.promoteToNonNull(declaredType);
    if (!typeOperations.isSameType(declaredTypeNonNull, declaredType)) {
      handleTypeOfInterest(declaredTypeNonNull);
      if (result != null) {
        return result;
      }
    }

    for (int i = 0; i < tested.length; i++) {
      Type type = tested[i];

      handleTypeOfInterest(type);
      if (result != null) {
        return result;
      }

      Type typeNonNull = typeOperations.promoteToNonNull(type);
      if (!typeOperations.isSameType(typeNonNull, type)) {
        handleTypeOfInterest(typeNonNull);
        if (result != null) {
          return result;
        }
      }
    }

    if (candidates != null) {
      // Figure out if we have a unique promotion candidate that's a subtype
      // of all the others.
      Type promoted;
      outer:
      for (int i = 0; i < candidates.length; i++) {
        for (int j = 0; j < candidates.length; j++) {
          if (j == i) continue;
          if (!typeOperations.isSubtypeOf(candidates[i], candidates[j])) {
            // Not a subtype of all the others.
            continue outer;
          }
        }
        if (promoted != null) {
          // Not unique.  Do not promote.
          return promotedTypes;
        } else {
          promoted = candidates[i];
        }
      }
      if (promoted != null) {
        return _addToPromotedTypes(promotedTypes, promoted);
      }
    }
    // No suitable promotion found.
    return promotedTypes;
  }

  /// Joins two variable models.  See [FlowModel.join] for details.
  static VariableModel<Variable, Type> join<Variable, Type>(
      TypeOperations<Variable, Type> typeOperations,
      VariableModel<Variable, Type> first,
      VariableModel<Variable, Type> second) {
    List<Type> newPromotedTypes = joinPromotedTypes(
        first.promotedTypes, second.promotedTypes, typeOperations);
    newPromotedTypes = typeOperations.refinePromotedTypes(
        first.promotedTypes, second.promotedTypes, newPromotedTypes);
    bool newAssigned = first.assigned && second.assigned;
    bool newUnassigned = first.unassigned && second.unassigned;
    bool newWriteCaptured = first.writeCaptured || second.writeCaptured;
    List<Type> newTested = newWriteCaptured
        ? const []
        : joinTested(first.tested, second.tested, typeOperations);
    return _identicalOrNew(first, second, newPromotedTypes, newTested,
        newAssigned, newUnassigned, newWriteCaptured);
  }

  /// Performs the portion of the "join" algorithm that applies to promotion
  /// chains.  Briefly, we intersect given chains.  The chains are totally
  /// ordered subsets of a global partial order.  Their intersection is a
  /// subset of each, and as such is also totally ordered.
  static List<Type> joinPromotedTypes<Variable, Type>(List<Type> chain1,
      List<Type> chain2, TypeOperations<Variable, Type> typeOperations) {
    if (chain1 == null) return chain1;
    if (chain2 == null) return chain2;

    int index1 = 0;
    int index2 = 0;
    bool skipped1 = false;
    bool skipped2 = false;
    List<Type> result;
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
  static List<Type> joinTested<Variable, Type>(List<Type> types1,
      List<Type> types2, TypeOperations<Variable, Type> typeOperations) {
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

  static List<Type> _addToPromotedTypes<Type>(
          List<Type> promotedTypes, Type promoted) =>
      promotedTypes == null
          ? [promoted]
          : (promotedTypes.toList()..add(promoted));

  static List<Type> _addTypeToUniqueList<Variable, Type>(List<Type> types,
      Type newType, TypeOperations<Variable, Type> typeOperations) {
    if (_typeListContains(typeOperations, types, newType)) return types;
    return new List<Type>.from(types)..add(newType);
  }

  /// Creates a new [VariableModel] object, unless it is equivalent to either
  /// [first] or [second], in which case one of those objects is re-used.
  static VariableModel<Variable, Type> _identicalOrNew<Variable, Type>(
      VariableModel<Variable, Type> first,
      VariableModel<Variable, Type> second,
      List<Type> newPromotedTypes,
      List<Type> newTested,
      bool newAssigned,
      bool newUnassigned,
      bool newWriteCaptured) {
    if (identical(first.promotedTypes, newPromotedTypes) &&
        identical(first.tested, newTested) &&
        first.assigned == newAssigned &&
        first.unassigned == newUnassigned &&
        first.writeCaptured == newWriteCaptured) {
      return first;
    } else if (identical(second.promotedTypes, newPromotedTypes) &&
        identical(second.tested, newTested) &&
        second.assigned == newAssigned &&
        second.unassigned == newUnassigned &&
        second.writeCaptured == newWriteCaptured) {
      return second;
    } else {
      return new VariableModel<Variable, Type>(newPromotedTypes, newTested,
          newAssigned, newUnassigned, newWriteCaptured);
    }
  }

  static bool _typeListContains<Variable, Type>(
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
class _AssertContext<Variable, Type> extends _SimpleContext<Variable, Type> {
  /// Flow models associated with the condition being asserted.
  ExpressionInfo<Variable, Type> _conditionInfo;

  _AssertContext(FlowModel<Variable, Type> previous) : super(previous);

  @override
  String toString() =>
      '_AssertContext(previous: $_previous, conditionInfo: $_conditionInfo)';
}

/// [_FlowContext] representing a language construct that branches on a boolean
/// condition, such as an `if` statement, conditional expression, or a logical
/// binary operator.
class _BranchContext<Variable, Type> extends _FlowContext {
  /// Flow models associated with the condition being branched on.
  final ExpressionInfo<Variable, Type> _conditionInfo;

  _BranchContext(this._conditionInfo);

  @override
  String toString() => '_BranchContext(conditionInfo: $_conditionInfo)';
}

/// [_FlowContext] representing a language construct that can be targeted by
/// `break` or `continue` statements, such as a loop or switch statement.
class _BranchTargetContext<Variable, Type> extends _FlowContext {
  /// Accumulated flow model for all `break` statements seen so far, or `null`
  /// if no `break` statements have been seen yet.
  FlowModel<Variable, Type> _breakModel;

  /// Accumulated flow model for all `continue` statements seen so far, or
  /// `null` if no `continue` statements have been seen yet.
  FlowModel<Variable, Type> _continueModel;

  @override
  String toString() => '_BranchTargetContext(breakModel: $_breakModel, '
      'continueModel: $_continueModel)';
}

/// [_FlowContext] representing a conditional expression.
class _ConditionalContext<Variable, Type>
    extends _BranchContext<Variable, Type> {
  /// Flow models associated with the value of the conditional expression in the
  /// circumstance where the "then" branch is taken.
  ExpressionInfo<Variable, Type> _thenInfo;

  _ConditionalContext(ExpressionInfo<Variable, Type> conditionInfo)
      : super(conditionInfo);

  @override
  String toString() => '_ConditionalContext(conditionInfo: $_conditionInfo, '
      'thenInfo: $_thenInfo)';
}

class _FlowAnalysisImpl<Node, Statement extends Node, Expression, Variable,
    Type> implements FlowAnalysis<Node, Statement, Expression, Variable, Type> {
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

  FlowModel<Variable, Type> _current;

  /// The most recently visited expression for which an [ExpressionInfo] object
  /// exists, or `null` if no expression has been visited that has a
  /// corresponding [ExpressionInfo] object.
  Expression _expressionWithInfo;

  /// If [_expressionWithInfo] is not `null`, the [ExpressionInfo] object
  /// corresponding to it.  Otherwise `null`.
  ExpressionInfo<Variable, Type> _expressionInfo;

  int _functionNestingLevel = 0;

  final AssignedVariables<Node, Variable> _assignedVariables;

  _FlowAnalysisImpl(this.typeOperations, this._assignedVariables) {
    _current = new FlowModel<Variable, Type>(true);
  }

  @override
  bool get isReachable => _current.reachable;

  @override
  void asExpression_end(Expression subExpression, Type type) {
    ExpressionInfo<Variable, Type> subExpressionInfo =
        _getExpressionInfo(subExpression);
    Variable variable;
    if (subExpressionInfo is _VariableReadInfo<Variable, Type>) {
      variable = subExpressionInfo._variable;
    } else {
      return;
    }
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
    _stack.add(new _AssertContext<Variable, Type>(_current));
  }

  @override
  void assert_end() {
    _AssertContext<Variable, Type> context =
        _stack.removeLast() as _AssertContext<Variable, Type>;
    _current = _join(context._previous, context._conditionInfo.ifTrue);
  }

  @override
  void booleanLiteral(Expression expression, bool value) {
    FlowModel<Variable, Type> unreachable = _current.setReachable(false);
    _storeExpressionInfo(
        expression,
        value
            ? new ExpressionInfo(_current, _current, unreachable)
            : new ExpressionInfo(_current, unreachable, _current));
  }

  @override
  void conditional_elseBegin(Expression thenExpression) {
    _ConditionalContext<Variable, Type> context =
        _stack.last as _ConditionalContext<Variable, Type>;
    context._thenInfo = _expressionEnd(thenExpression);
    _current = context._conditionInfo.ifFalse;
  }

  @override
  void conditional_end(
      Expression conditionalExpression, Expression elseExpression) {
    _ConditionalContext<Variable, Type> context =
        _stack.removeLast() as _ConditionalContext<Variable, Type>;
    ExpressionInfo<Variable, Type> thenInfo = context._thenInfo;
    ExpressionInfo<Variable, Type> elseInfo = _expressionEnd(elseExpression);
    _storeExpressionInfo(
        conditionalExpression,
        new ExpressionInfo(
            _join(thenInfo.after, elseInfo.after),
            _join(thenInfo.ifTrue, elseInfo.ifTrue),
            _join(thenInfo.ifFalse, elseInfo.ifFalse)));
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
        new _BranchTargetContext<Variable, Type>();
    _stack.add(context);
    _current = _current.conservativeJoin(info._written, info._captured);
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
    _current = _join(_expressionEnd(condition).ifFalse, context._breakModel);
  }

  @override
  void equalityOp_end(Expression wholeExpression, Expression rightOperand,
      {bool notEqual = false}) {
    _BranchContext<Variable, Type> context =
        _stack.removeLast() as _BranchContext<Variable, Type>;
    ExpressionInfo<Variable, Type> lhsInfo = context._conditionInfo;
    ExpressionInfo<Variable, Type> rhsInfo = _getExpressionInfo(rightOperand);
    Variable variable;
    if (lhsInfo is _NullInfo<Variable, Type> &&
        rhsInfo is _VariableReadInfo<Variable, Type>) {
      variable = rhsInfo._variable;
    } else if (rhsInfo is _NullInfo<Variable, Type> &&
        lhsInfo is _VariableReadInfo<Variable, Type>) {
      variable = lhsInfo._variable;
    } else {
      return;
    }
    ExpressionInfo<Variable, Type> expressionInfo =
        _current.tryMarkNonNullable(typeOperations, variable);
    _storeExpressionInfo(wholeExpression,
        notEqual ? expressionInfo : ExpressionInfo.invert(expressionInfo));
  }

  @override
  void equalityOp_rightBegin(Expression leftOperand) {
    _stack.add(
        new _BranchContext<Variable, Type>(_getExpressionInfo(leftOperand)));
  }

  @override
  void finish() {
    assert(_stack.isEmpty);
  }

  @override
  void for_bodyBegin(Statement node, Expression condition) {
    ExpressionInfo<Variable, Type> conditionInfo = condition == null
        ? new ExpressionInfo(_current, _current, _current.setReachable(false))
        : _expressionEnd(condition);
    _WhileContext<Variable, Type> context =
        new _WhileContext<Variable, Type>(conditionInfo);
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
    _current = _current.conservativeJoin(info._written, info._captured);
  }

  @override
  void for_end() {
    _WhileContext<Variable, Type> context =
        _stack.removeLast() as _WhileContext<Variable, Type>;
    // Tail of the stack: falseCondition, break
    FlowModel<Variable, Type> breakState = context._breakModel;
    FlowModel<Variable, Type> falseCondition = context._conditionInfo.ifFalse;

    _current = _join(falseCondition, breakState);
  }

  @override
  void for_updaterBegin() {
    _WhileContext<Variable, Type> context =
        _stack.last as _WhileContext<Variable, Type>;
    _current = _join(_current, context._continueModel);
  }

  @override
  void forEach_bodyBegin(Node node, Variable loopVariable, Type writtenType) {
    AssignedVariablesNodeInfo<Variable> info =
        _assignedVariables._getInfoForNode(node);
    _SimpleStatementContext<Variable, Type> context =
        new _SimpleStatementContext<Variable, Type>(_current);
    _stack.add(context);
    _current = _current.conservativeJoin(info._written, info._captured);
    if (loopVariable != null) {
      _current = _current.write(loopVariable, writtenType, typeOperations);
    }
  }

  @override
  void forEach_end() {
    _SimpleStatementContext<Variable, Type> context =
        _stack.removeLast() as _SimpleStatementContext<Variable, Type>;
    _current = _join(_current, context._previous);
  }

  @override
  void functionExpression_begin(Node node) {
    AssignedVariablesNodeInfo<Variable> info =
        _assignedVariables._getInfoForNode(node);
    ++_functionNestingLevel;
    _current = _current.conservativeJoin(const [], info._written);
    _stack.add(new _SimpleContext(_current));
    _current = _current.conservativeJoin(_assignedVariables._anywhere._written,
        _assignedVariables._anywhere._captured);
  }

  @override
  void functionExpression_end() {
    --_functionNestingLevel;
    assert(_functionNestingLevel >= 0);
    FlowModel<Variable, Type> afterBody = _current;
    _SimpleContext<Variable, Type> context =
        _stack.removeLast() as _SimpleContext<Variable, Type>;
    _current = context._previous;
    _current = _current.joinUnassigned(afterBody);
  }

  @override
  void handleBreak(Statement target) {
    _BranchTargetContext<Variable, Type> context = _statementToContext[target];
    if (context != null) {
      context._breakModel = _join(context._breakModel, _current);
    }
    _current = _current.setReachable(false);
  }

  @override
  void handleContinue(Statement target) {
    _BranchTargetContext<Variable, Type> context = _statementToContext[target];
    if (context != null) {
      context._continueModel = _join(context._continueModel, _current);
    }
    _current = _current.setReachable(false);
  }

  @override
  void handleExit() {
    _current = _current.setReachable(false);
  }

  @override
  void ifNullExpression_end() {
    _SimpleContext<Variable, Type> context =
        _stack.removeLast() as _SimpleContext<Variable, Type>;
    _current = _join(_current, context._previous);
  }

  @override
  void ifNullExpression_rightBegin(Expression leftHandSide) {
    ExpressionInfo<Variable, Type> lhsInfo = _getExpressionInfo(leftHandSide);
    FlowModel<Variable, Type> promoted;
    if (lhsInfo is _VariableReadInfo<Variable, Type>) {
      ExpressionInfo<Variable, Type> promotionInfo =
          _current.tryMarkNonNullable(typeOperations, lhsInfo._variable);
      _current = promotionInfo.ifFalse;
      promoted = promotionInfo.ifTrue;
    } else {
      promoted = _current;
    }
    _stack.add(new _SimpleContext<Variable, Type>(promoted));
  }

  @override
  void ifStatement_elseBegin() {
    _IfContext<Variable, Type> context =
        _stack.last as _IfContext<Variable, Type>;
    context._afterThen = _current;
    _current = context._conditionInfo.ifFalse;
  }

  @override
  void ifStatement_end(bool hasElse) {
    _IfContext<Variable, Type> context =
        _stack.removeLast() as _IfContext<Variable, Type>;
    FlowModel<Variable, Type> afterThen;
    FlowModel<Variable, Type> afterElse;
    if (hasElse) {
      afterThen = context._afterThen;
      afterElse = _current;
    } else {
      afterThen = _current; // no `else`, so `then` is still current
      afterElse = context._conditionInfo.ifFalse;
    }
    _current = _join(afterThen, afterElse);
  }

  @override
  void ifStatement_thenBegin(Expression condition) {
    ExpressionInfo<Variable, Type> conditionInfo = _expressionEnd(condition);
    _stack.add(new _IfContext(conditionInfo));
    _current = conditionInfo.ifTrue;
  }

  @override
  bool isAssigned(Variable variable) {
    return _current.infoFor(variable).assigned;
  }

  @override
  void isExpression_end(Expression isExpression, Expression subExpression,
      bool isNot, Type type) {
    ExpressionInfo<Variable, Type> subExpressionInfo =
        _getExpressionInfo(subExpression);
    Variable variable;
    if (subExpressionInfo is _VariableReadInfo<Variable, Type>) {
      variable = subExpressionInfo._variable;
    } else {
      return;
    }
    ExpressionInfo<Variable, Type> expressionInfo =
        _current.tryPromoteForTypeCheck(typeOperations, variable, type);
    _storeExpressionInfo(isExpression,
        isNot ? ExpressionInfo.invert(expressionInfo) : expressionInfo);
  }

  @override
  bool isUnassigned(Variable variable) {
    return _current.infoFor(variable).unassigned;
  }

  @override
  void labeledStatement_begin(Node node) {
    _BranchTargetContext<Variable, Type> context =
        new _BranchTargetContext<Variable, Type>();
    _stack.add(context);
    _statementToContext[node] = context;
  }

  @override
  void labeledStatement_end() {
    _BranchTargetContext<Variable, Type> context =
        _stack.removeLast() as _BranchTargetContext<Variable, Type>;
    _current = _join(_current, context._breakModel);
  }

  @override
  void logicalBinaryOp_end(Expression wholeExpression, Expression rightOperand,
      {@required bool isAnd}) {
    _BranchContext<Variable, Type> context =
        _stack.removeLast() as _BranchContext<Variable, Type>;
    ExpressionInfo<Variable, Type> rhsInfo = _expressionEnd(rightOperand);

    FlowModel<Variable, Type> trueResult;
    FlowModel<Variable, Type> falseResult;
    if (isAnd) {
      trueResult = rhsInfo.ifTrue;
      falseResult = _join(context._conditionInfo.ifFalse, rhsInfo.ifFalse);
    } else {
      trueResult = _join(context._conditionInfo.ifTrue, rhsInfo.ifTrue);
      falseResult = rhsInfo.ifFalse;
    }
    _storeExpressionInfo(
        wholeExpression,
        new ExpressionInfo(
            _join(trueResult, falseResult), trueResult, falseResult));
  }

  @override
  void logicalBinaryOp_rightBegin(Expression leftOperand,
      {@required bool isAnd}) {
    ExpressionInfo<Variable, Type> conditionInfo = _expressionEnd(leftOperand);
    _stack.add(new _BranchContext<Variable, Type>(conditionInfo));
    _current = isAnd ? conditionInfo.ifTrue : conditionInfo.ifFalse;
  }

  @override
  void logicalNot_end(Expression notExpression, Expression operand) {
    ExpressionInfo<Variable, Type> conditionInfo = _expressionEnd(operand);
    _storeExpressionInfo(notExpression, ExpressionInfo.invert(conditionInfo));
  }

  @override
  void nonNullAssert_end(Expression operand) {
    ExpressionInfo<Variable, Type> operandInfo = _getExpressionInfo(operand);
    if (operandInfo is _VariableReadInfo<Variable, Type>) {
      _current = _current
          .tryMarkNonNullable(typeOperations, operandInfo._variable)
          .ifTrue;
    }
  }

  @override
  void nullAwareAccess_end() {
    _SimpleContext<Variable, Type> context =
        _stack.removeLast() as _SimpleContext<Variable, Type>;
    _current = _join(_current, context._previous);
  }

  @override
  void nullAwareAccess_rightBegin(Expression target) {
    _stack.add(new _SimpleContext<Variable, Type>(_current));
    if (target != null) {
      ExpressionInfo<Variable, Type> targetInfo = _getExpressionInfo(target);
      if (targetInfo is _VariableReadInfo<Variable, Type>) {
        _current = _current
            .tryMarkNonNullable(typeOperations, targetInfo._variable)
            .ifTrue;
      }
    }
  }

  @override
  void nullLiteral(Expression expression) {
    _storeExpressionInfo(expression, new _NullInfo(_current));
  }

  @override
  void parenthesizedExpression(
      Expression outerExpression, Expression innerExpression) {
    if (identical(_expressionWithInfo, innerExpression)) {
      _expressionWithInfo = outerExpression;
    }
  }

  @override
  Type promotedType(Variable variable) {
    return _current.infoFor(variable).promotedTypes?.last;
  }

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
    FlowModel<Variable, Type> breakState = context._breakModel;

    // It is allowed to "fall off" the end of a switch statement, so join the
    // current state to any breaks that were found previously.
    breakState = _join(breakState, _current);

    // And, if there is an implicit fall-through default, join it to any breaks.
    if (!isExhaustive) breakState = _join(breakState, context._previous);

    _current = breakState;
  }

  @override
  void switchStatement_expressionEnd(Statement switchStatement) {
    _SimpleStatementContext<Variable, Type> context =
        new _SimpleStatementContext<Variable, Type>(_current);
    _stack.add(context);
    _statementToContext[switchStatement] = context;
  }

  @override
  void tryCatchStatement_bodyBegin() {
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
      Variable exceptionVariable, Variable stackTraceVariable) {
    _TryContext<Variable, Type> context =
        _stack.last as _TryContext<Variable, Type>;
    _current = context._beforeCatch;
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
    _current = context._afterBodyAndCatches;
  }

  @override
  void tryFinallyStatement_bodyBegin() {
    _stack.add(new _TryContext<Variable, Type>(_current));
  }

  @override
  void tryFinallyStatement_end(Node finallyBlock) {
    AssignedVariablesNodeInfo<Variable> info =
        _assignedVariables._getInfoForNode(finallyBlock);
    _TryContext<Variable, Type> context =
        _stack.removeLast() as _TryContext<Variable, Type>;
    _current = _current.restrict(
        typeOperations, context._afterBodyAndCatches, info._written);
  }

  @override
  void tryFinallyStatement_finallyBegin(Node body) {
    AssignedVariablesNodeInfo<Variable> info =
        _assignedVariables._getInfoForNode(body);
    _TryContext<Variable, Type> context =
        _stack.last as _TryContext<Variable, Type>;
    context._afterBodyAndCatches = _current;
    _current = _join(_current,
        context._previous.conservativeJoin(info._written, info._captured));
  }

  @override
  Type variableRead(Expression expression, Variable variable) {
    _storeExpressionInfo(expression, new _VariableReadInfo(_current, variable));
    return _current.infoFor(variable).promotedTypes?.last;
  }

  @override
  void whileStatement_bodyBegin(
      Statement whileStatement, Expression condition) {
    ExpressionInfo<Variable, Type> conditionInfo = _expressionEnd(condition);
    _WhileContext<Variable, Type> context =
        new _WhileContext<Variable, Type>(conditionInfo);
    _stack.add(context);
    _statementToContext[whileStatement] = context;
    _current = conditionInfo.ifTrue;
  }

  @override
  void whileStatement_conditionBegin(Node node) {
    AssignedVariablesNodeInfo<Variable> info =
        _assignedVariables._getInfoForNode(node);
    _current = _current.conservativeJoin(info._written, info._captured);
  }

  @override
  void whileStatement_end() {
    _WhileContext<Variable, Type> context =
        _stack.removeLast() as _WhileContext<Variable, Type>;
    _current = _join(context._conditionInfo.ifFalse, context._breakModel);
  }

  @override
  void write(Variable variable, Type writtenType) {
    assert(
        _assignedVariables._anywhere._written.contains(variable),
        "Variable is written to, but was not included in "
        "_variablesWrittenAnywhere: $variable");
    _current = _current.write(variable, writtenType, typeOperations);
  }

  void _dumpState() {
    print('  current: $_current');
    print('  expressionWithInfo: $_expressionWithInfo');
    print('  expressionInfo: $_expressionInfo');
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
      _getExpressionInfo(expression) ??
      new ExpressionInfo(_current, _current, _current);

  /// Gets the [ExpressionInfo] associated with the [expression] (which should
  /// be the last expression that was traversed).  If there is no
  /// [ExpressionInfo] associated with the [expression], then `null` is
  /// returned.
  ExpressionInfo<Variable, Type> _getExpressionInfo(Expression expression) {
    if (identical(expression, _expressionWithInfo)) {
      ExpressionInfo<Variable, Type> expressionInfo = _expressionInfo;
      _expressionInfo = null;
      return expressionInfo;
    } else {
      return null;
    }
  }

  FlowModel<Variable, Type> _join(
          FlowModel<Variable, Type> first, FlowModel<Variable, Type> second) =>
      FlowModel.join(typeOperations, first, second, _current._emptyVariableMap);

  /// Associates [expression], which should be the most recently visited
  /// expression, with the given [expressionInfo] object, and updates the
  /// current flow model state to correspond to it.
  void _storeExpressionInfo(
      Expression expression, ExpressionInfo<Variable, Type> expressionInfo) {
    _expressionWithInfo = expression;
    _expressionInfo = expressionInfo;
    _current = expressionInfo.after;
  }
}

/// Base class for objects representing constructs in the Dart programming
/// language for which flow analysis information needs to be tracked.
abstract class _FlowContext {}

/// [_FlowContext] representing an `if` statement.
class _IfContext<Variable, Type> extends _BranchContext<Variable, Type> {
  /// Flow model associated with the state of program execution after the `if`
  /// statement executes, in the circumstance where the "then" branch is taken.
  FlowModel<Variable, Type> _afterThen;

  _IfContext(ExpressionInfo<Variable, Type> conditionInfo)
      : super(conditionInfo);

  @override
  String toString() =>
      '_IfContext(conditionInfo: $_conditionInfo, afterThen: $_afterThen)';
}

/// [ExpressionInfo] representing a `null` literal.
class _NullInfo<Variable, Type> implements ExpressionInfo<Variable, Type> {
  @override
  final FlowModel<Variable, Type> after;

  _NullInfo(this.after);

  @override
  FlowModel<Variable, Type> get ifFalse => after;

  @override
  FlowModel<Variable, Type> get ifTrue => after;
}

/// [_FlowContext] representing a language construct for which flow analysis
/// must store a flow model state to be retrieved later, such as a `try`
/// statement, function expression, or "if-null" (`??`) expression.
class _SimpleContext<Variable, Type> extends _FlowContext {
  /// The stored state.  For a `try` statement, this is the state from the
  /// beginning of the `try` block.  For a function expression, this is the
  /// state at the point the function expression was created.  For an "if-null"
  /// expression, this is the state after execution of the expression before the
  /// `??`.
  final FlowModel<Variable, Type> _previous;

  _SimpleContext(this._previous);

  @override
  String toString() => '_SimpleContext(previous: $_previous)';
}

/// [_FlowContext] representing a language construct that can be targeted by
/// `break` or `continue` statements, and for which flow analysis must store a
/// flow model state to be retrieved later.  Examples include "for each" and
/// `switch` statements.
class _SimpleStatementContext<Variable, Type>
    extends _BranchTargetContext<Variable, Type> {
  /// The stored state.  For a "for each" statement, this is the state after
  /// evaluation of the iterable.  For a `switch` statement, this is the state
  /// after evaluation of the switch expression.
  final FlowModel<Variable, Type> _previous;

  _SimpleStatementContext(this._previous);

  @override
  String toString() => '_SimpleStatementContext(breakModel: $_breakModel, '
      'continueModel: $_continueModel, previous: $_previous)';
}

/// [_FlowContext] representing a try statement.
class _TryContext<Variable, Type> extends _SimpleContext<Variable, Type> {
  /// If the statement is a "try/catch" statement, the flow model representing
  /// program state at the top of any `catch` block.
  FlowModel<Variable, Type> _beforeCatch;

  /// If the statement is a "try/catch" statement, the accumulated flow model
  /// representing program state after the `try` block or one of the `catch`
  /// blocks has finished executing.  If the statement is a "try/finally"
  /// statement, the flow model representing program state after the `try` block
  /// has finished executing.
  FlowModel<Variable, Type> _afterBodyAndCatches;

  _TryContext(FlowModel<Variable, Type> previous) : super(previous);

  @override
  String toString() =>
      '_TryContext(previous: $_previous, beforeCatch: $_beforeCatch, '
      'afterBodyAndCatches: $_afterBodyAndCatches)';
}

/// [ExpressionInfo] representing an expression that reads the value of a
/// variable.
class _VariableReadInfo<Variable, Type>
    implements ExpressionInfo<Variable, Type> {
  @override
  final FlowModel<Variable, Type> after;

  /// The variable that is being read.
  final Variable _variable;

  _VariableReadInfo(this.after, this._variable);

  @override
  FlowModel<Variable, Type> get ifFalse => after;

  @override
  FlowModel<Variable, Type> get ifTrue => after;

  @override
  String toString() => '_VariableReadInfo(after: $after, variable: $_variable)';
}

/// [_FlowContext] representing a `while` loop (or a C-style `for` loop, which
/// is functionally similar).
class _WhileContext<Variable, Type>
    extends _BranchTargetContext<Variable, Type> {
  /// Flow models associated with the loop condition.
  final ExpressionInfo<Variable, Type> _conditionInfo;

  _WhileContext(this._conditionInfo);

  @override
  String toString() => '_WhileContext(breakModel: $_breakModel, '
      'continueModel: $_continueModel, conditionInfo: $_conditionInfo)';
}
