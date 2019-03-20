// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:meta/meta.dart';

/// Object that tracks "assigned" status for local variables in a function body.
///
/// The client should create a new instance of tracker for a function body.
///
/// Each declared local variable must be added using [add].  If the variable
/// is assigned at the declaration, it is not actually tracked.
///
/// For each read of a local variable [read] should be invoked, and for each
/// write - [write].  If there is a  "read" of a variable before it is
/// definitely written, the variable is added to output [readBeforeWritten].
///
/// For each AST node that affects definite assignment the client must invoke
/// corresponding `beginX` and `endX` methods.  They will combine assignment
/// facts registered in parts of AST. These invocations are expected to be
/// performed as a part of the resolution pass over the AST.
///
/// In the examples below, Dart code is listed on the left, and the set of
/// calls that need to be made to [DefiniteAssignmentTracker] are listed on
/// the right.
///
///
/// --------------------------------------------------
/// Assignments.
///
/// When the LHS is a local variable, and the assignment is pure, i.e. uses
/// operators `=` and `??=`, only the RHS is executed, and then the
/// variable on the LHS is marked as definitely assigned.
///
/// ```dart
/// int V1;      // add(V1)
/// int V2;      // add(V2)
/// V1 = 0;      // write(V1)
/// V2 = V2;     // read(V2) => readBeforeWritten; write(V2)
/// V1;          // read(V1) => OK
/// V2;          // read(V2) => readBeforeWritten (already)
/// ```
///
/// In compound assignments to a local variable, or assignments where the LHS
/// is not a simple identifier, the LHS is executed first, and then the RHS.
///
/// ```dart
/// int V1;                 // add(V1)
/// List<int> V2;           // add(V2)
/// V1 += 1;                // read(V1) => readBeforeWritten; write(V1)
/// V2[0] = (V2 = [0])[0];  // read(V2) => readBeforeWritten; write(V2)
/// V1;                     // read(V1) => readBeforeWritten (already)
/// V2;                     // read(V2) => readBeforeWritten (already)
/// ```
///
///
/// --------------------------------------------------
/// Logical expression.
///
/// In logical expressions `a && b` or `a || b` only `a` is always executed,
/// in the enclosing branch.  The expression `b` might not be executed, so its
/// results are on the exit from the logical expression.
///
/// ```dart
/// int V1;      // add(V1)
/// int V2;      // add(V2)
/// (
///   V1 = 1     // write(V1)
/// ) > 0
/// &&           // beginBinaryExpressionLogicalRight()
/// (
///   V2 = V1    // read(V1) => OK; write(V2)
/// ) > 0
/// ;            // endBinaryExpressionLogicalRight()
/// V1;          // read(V1) => OK
/// V2;          // read(V2) => readBeforeWritten
/// ```
///
///
/// --------------------------------------------------
/// assert(C, M)
///
/// The `assert` statement is not guaranteed to execute, so assignments in the
/// condition and the message are discarded.  But assignments in the condition
/// are visible in the message.
///
/// ```dart
/// bool V;    // add(V)
/// assert(    // beginAssertStatement()
///   V        // read(V) => readBeforeWritten
/// );         // endAssertExpression()
/// V          // read(V) => readBeforeWritten
/// ```
///
/// ```dart
/// bool V;      // add(V)
/// assert(      // beginAssertExpression()
///   V = true,  // write(V)
///   "$V",      // read(V) => OK
/// );           // endAssertExpression()
/// V            // read(V) => readBeforeWritten
/// ```
///
///
/// --------------------------------------------------
/// if (E) {} else {}
///
/// The variable must be assigned in the `then` branch, and the `else` branch.
///
/// The condition `E` contributes into the current branch.
///
/// ```dart
/// int V1;     // add(V1)
/// int V2;     // add(V2)
/// int V3;     // add(V3)
/// if (E)
/// {           // beginIfStatementThen()
///   V1 = 0;   // write(V1)
///   V2 = 0;   // write(V2)
///   V1;       // read(V1) => OK
///   V2;       // read(V2) => OK
/// } else {    // beginIfStatementElse()
///   V1 = 0;   // write(V1)
///   V3 = 0;   // write(V3)
///   V1;       // read(V1) => OK
///   V3;       // read(V3) => OK
/// }           // endIfStatement(hasElse: true)
/// V1;         // read(V1) => OK
/// V2;         // read(V2) => readBeforeWritten
/// V3;         // read(V3) => readBeforeWritten
/// ```
///
///
/// --------------------------------------------------
/// while (E) {}
///
/// If `E` is not the `true` literal, which is covered below, then the body of
/// the loop might be not executed at all.  So, the fork is discarded.
///
/// The condition `E` contributes into the current branch.
///
/// ```dart
/// int V;      // add(V)
/// while (     // beginWhileStatement(labels: [])
///   E
/// ) {         // beginWhileStatementBody(isTrue: false)
///   V = 0;    // write(V)
///   V;        // read(V) => OK
/// }           // endWhileStatement()
/// V;          // read(V) => readBeforeWritten
/// ```
///
///
/// --------------------------------------------------
/// while (true) { ...break... }
///
/// Statements `break` and `continue` in loops make the rest of the enclosing
/// (or labelled) loop ineligible for marking variables definitely assigned
/// outside of the loop. However it is still OK to mark variables assigned and
/// use their values in the rest of the loop.
///
/// ```dart
/// int V;
/// while (             // beginWhileStatement(labels: [])
///   true
/// ) {                 // beginWhileStatementBody(isTrue: true)
///   if (condition) {  // beginIfStatement(hasElse: false)
///     break;          // handleBreak(while);
///   }                 // endIfStatement()
///   V = 0;            // write(V)
///   V;                // read(V) => OK
/// }                   // endWhileStatement()
/// V;                  // read(V) => readBeforeWritten
/// ```
///
/// Nested loops:
///
/// ```dart
/// int V1, V2;
/// L1: while (         // beginWhileStatement(node)
///   true
/// ) {                 // beginWhileStatementBody(isTrue: true)
///   while (           // beginWhileStatement(labels: [])
///     true
///   ) {               // beginWhileStatementBody()
///     if (C1) {       // beginIfStatement(hasElse: true)
///       V1 = 0;       // write(V1)
///     } else {        // beginIfStatementElse()
///       if (C2) {     // beginIfStatement(hasElse: false)
///         break L1;   // handleBreak(L1: while)
///       }             // endIfStatement()
///       V1 = 0;       // write(V1)
///     }               // endIfStatement()
///     V1;             // read(V1) => OK
///   }                 // endWhileStatement()
///   V1;               // read(V1) => OK
///   while (           // beginWhileStatement(node)
///     true
///   ) {               // beginWhileStatementBody(isTrue: true)
///     V2 = 0;         // write(V2)
///     break;          // handleBreak(while)
///   }                 // endWhileStatement()
///   V1;               // read(V1) => OK
///   V2;               // read(V2) => OK
/// }                   // endWhileStatement()
/// V1;                 // read(V1) => readBeforeWritten
/// V2;                 // read(V2) => readBeforeWritten
/// ```
///
///
/// --------------------------------------------------
/// do {} while (E)
///
/// The body and the condition always execute, all assignments contribute to
/// the current branch.  The body is tracked in its own branch, so that if
/// it has an interruption (`break` or `continue`), we can discard the branch
/// after or before the condition.
///
/// ```dart
/// int V1;                  // add(V1)
/// int V2;                  // add(V2)
/// do {                     // beginDoWhileStatement(node)
///   V1 = 0;                // write(V1)
///   V1;                    // read(V1) => OK
/// } while                  // beginDoWhileStatementCondition()
///   ((V2 = 0) >= 0)        // write(V2)
/// ;                        // endDoWhileStatement()
/// V1;                      // read(V1) => OK
/// V2;                      // read(V2) => OK
/// ```
///
///
/// --------------------------------------------------
/// do { ...break... } while (E)
///
/// The `break` statement prevents execution of the rest of the body, and
/// the condition.  So, the branch ends after the condition.
///
/// ```dart
/// int V1;                  // add(V1)
/// int V2;                  // add(V2)
/// int V3;                  // add(V3)
/// do {                     // beginDoWhileStatement(node)
///   V1 = 0;                // write(V1)
///   V1;                    // read(V1) => OK
///   if (C1) break;         // handleBreak(do)
///   V2 = 0;                // write(V2)
///   V2;                    // read(V2) => OK
/// } while                  // beginDoWhileStatementCondition()
///   ((V3 = 0) >= 0)        // write(V3)
/// ;                        // endDoWhileStatement()
/// V1;                      // read(V1) => OK
/// V2;                      // read(V2) => readBeforeWritten
/// V3;                      // read(V3) => readBeforeWritten
/// ```
///
///
/// --------------------------------------------------
/// do { ...continue... } while (E)
///
/// The `continue` statement prevents execution of the rest of the body, but
/// the condition is always executed.  So, the branch ends before the condition,
/// and the condition contributes to the enclosing branch.
///
/// ```dart
/// int V1;                  // add(V1)
/// int V2;                  // add(V2)
/// int V3;                  // add(V3)
/// do {                     // beginDoWhileStatement(node)
///   V1 = 0;                // write(V1)
///   V1;                    // read(V1) => OK
///   if (C1) continue;      // handleContinue(do)
///   V2 = 0;                // write(V2)
///   V2;                    // read(V2) => OK
/// } while                  // beginDoWhileStatementCondition()
///   ((V3 = 0) >= 0)        // write(V3)
/// ;                        // endDoWhileStatement()
/// V1;                      // read(V1) => OK
/// V2;                      // read(V2) => readBeforeWritten
/// V3;                      // read(V3) => OK
/// ```
///
///
/// --------------------------------------------------
/// Try / catch.
///
/// The variable must be assigned in the `try` branch and every `catch` branch.
///
/// Note, that an improvement is possible, when some first statements in the
/// `try` branch can be shown to not throw (e.g. `V = 0;`). We could consider
/// these statements as definitely executed, so producing definite assignments.
///
/// ```dart
/// int V;        // add(V)
/// try {         // beginTryStatement()
///   V = f();    // write(V)
/// }             // endTryStatementBody()
/// catch (_) {   // beginTryStatementCatchClause()
///   V = 0;      // write(V)
/// }             // endTryStatementCatchClause(); endTryStatementCatchClauses()
/// V;            // read(V) => OK
/// ```
///
///
/// --------------------------------------------------
/// Try / finally.
///
/// The `finally` clause is always executed, so it is tracked in the branch
/// that contains the `try` statement.
///
/// Without `catch` clauses the `try` clause is always executed to the end,
/// so also can be tracked in the branch that contains the `try` statement.
///
/// ```dart
/// int V1;     // add(V1)
/// int V2;     // add(V2)
/// try {       // beginTryStatement()
///   V1 = 0;   // write(V1)
/// }           // endTryStatementBody(); endTryStatementCatchClauses();
/// finally {
///   V2 = 0;   // write(V2)
/// }
/// V1;         // read(V1) => OK
/// V2;         // read(V2) => OK
/// ```
///
///
/// --------------------------------------------------
/// Try / catch / finally.
///
/// The `finally` clause is always executed, so it is tracked in the branch
/// that contains the `try` statement.
///
/// The `try` and `catch` branches are tracked as without `finally`.
///
///
/// --------------------------------------------------
/// switch (E) { case E1: ... default: }
///
/// The variable must be assigned in every `case` branch and must have the
/// `default` branch.  If the `default` branch is missing, then the `switch`
/// does not definitely cover all possible values of `E`, so the variable is
/// not definitely assigned.
///
/// The expression `E` contributes into the current branch.
///
/// ```dart
/// int V;      // add(V)
/// switch      // beginSwitchStatement()
/// (E) {       // endSwitchStatementExpression()
///   case 1:   // beginSwitchStatementMember()
///     V = 0;  // write(V)
///     break;  // handleBreak(switch)
///   default:  // beginSwitchStatementMember()
///     V = 0;  // write(V); handleBreak(switch)
/// }           // endSwitchStatement(hasDefault: true)
/// V;          // read(V) => OK
/// ```
///
/// The presence of a `continue L` statement in switch / case is analyzed in an
/// approximate way; if a given variable is not written to in all case bodies,
/// it is considered "not definitely assigned", even though a full basic block
/// analysis would show that it is definitely assigned.
///
/// ```dart
/// int V;           // add(V)
/// switch           // beginSwitchStatement()
/// (E) {            // endSwitchStatementExpression()
///   L: case 1:     // beginSwitchStatementMember()
///     V = 0;       // write(V)
///     break;       // handleBreak(switch)
///   case 2:        // beginSwitchStatementMember()
///     continue L;  // handleContinue(switch)
///   default:       // beginSwitchStatementMember()
///     V = 0;       // write(V); handleBreak(switch)
/// }                // endSwitchStatement(hasDefault: true)
/// V;               // read(V) => readBeforeWritten
/// ```
///
///
/// --------------------------------------------------
/// For each.
///
/// The iterable might be empty, so the body might be not executed, so writes
/// in the body are discarded.  But writes in the iterable expressions are
/// always executed.
///
/// ```dart
/// int V1;     // add(V1)
/// int V2;     // add(V2)
/// for (var _ in (V1 = [0, 1, 2]))  // beginForEachStatement(node)
/// {                                // beginForEachStatementBody()
///   V2 = 0;                        // write(V1)
/// }                                // endForEachStatement();
/// V1;         // read(V1) => OK
/// V2;         // read(V2) => readBeforeWritten
/// ```
///
///
/// --------------------------------------------------
/// For statement.
///
/// Very similar to `while` statement.  The initializer and condition parts
/// are always executed, so contribute to definite assignments.  The body and
/// updaters might be not executed, so writes in them are discarded.  The
/// updaters are executed after the body, so writes in the body are visible in
/// the updaters, correspondingly AST portions should be visited, and
/// [beginForEachStatementBody] should be before [beginForStatementUpdaters],
/// and followed with [endForStatement].
///
/// ```dart
/// int V1;     // 1. add(V1)
/// int V2;     // 2. add(V2)
/// int V3;     // 3. add(V3)
/// int V4;     // 4. add(V4)
/// for (                //  5. beginForStatement(node)
///   var _ = (V1 = 0);  //  6. write(V1)
///   (V2 = 0) >= 0;     //  7. write(V2)
///   V3 = 0             // 10. beginForStatementUpdaters(); write(V3)
/// ) {                  //  8. beginForStatementBody()
///   V4 = 0;            //  9. write(V4)
/// }                    // 11. endForStatement()
/// V1;         // 12. read(V1) => OK
/// V2;         // 13. read(V2) => OK
/// V3;         // 14. read(V3) => readBeforeWritten
/// V4;         // 15. read(V4) => readBeforeWritten
/// ```
///
///
/// --------------------------------------------------
/// Function expressions - local functions and closures.
///
/// A function expression, e.g. a closure passed as an argument of an
/// invocation, might be invoked synchronously, asynchronously, or never.
/// So, all local variables that are read in the function expression must be
/// definitely assigned, but any writes should be discarded on exit from the
/// function expression.
///
/// ```dart
/// int V1;     // add(V1)
/// int V2;     // add(V2)
/// int V3;     // add(V2)
/// V1 = 0;     // write(V1)
/// void f() {  // beginFunctionExpression()
///   V1;       // read(V1) => OK
///   V2;       // read(V2) => readBeforeWritten
///   V3 = 0;   // write(V1)
/// }           // endFunctionExpression();
/// V2 = 0;     // write(V2)
/// f();
/// V1;         // read(V1) => OK
/// V2;         // read(V2) => OK
/// V3;         // read(V3) => readBeforeWritten
/// ```
///
///
/// --------------------------------------------------
/// Definite exit.
///
/// If a definite exit is reached, e.g. a `return` or a `throw` statement,
/// then all the variables are vacuously definitely assigned.
///
/// ```dart
/// int V;      // add(V)
/// if (E) {
/// {           // beginIfStatementThen()
///   V = 0;    // write(V)
/// } else {    // beginIfStatementElse()
///   return;   // handleExit()
/// }           // endIfStatement(hasElse: true)
/// V;          // read(V) => OK
/// ```
class DefiniteAssignmentTracker {
  /// The output list of variables that were read before they were written.
  final List<LocalVariableElement> readBeforeWritten = [];

  /// The stack of sets of variables that are not definitely assigned.
  final List<_ElementSet> _stack = [];

  /// The mapping from labeled [Statement]s to the index in the [_stack]
  /// where the first related element is located.  The number of elements
  /// is statement specific.
  final Map<Statement, int> _statementToStackIndex = {};

  /// The current set of variables that are not definitely assigned.
  _ElementSet _current = _ElementSet.empty;

  @visibleForTesting
  bool get isRootBranch {
    return _stack.isEmpty;
  }

  /// Add a new [variable], which might be already [assigned].
  void add(LocalVariableElement variable, {bool assigned: false}) {
    if (!assigned) {
      _current = _current.add(variable);
    }
  }

  void beginAssertStatement() {
    _stack.add(_current);
  }

  void beginBinaryExpressionLogicalRight() {
    _stack.add(_current);
  }

  void beginConditionalExpressionElse() {
    var afterCondition = _stack.last;
    _stack.last = _current; // after then
    _current = afterCondition;
  }

  void beginConditionalExpressionThen() {
    _stack.add(_current); // after condition
  }

  void beginDoWhileStatement(DoStatement statement) {
    _statementToStackIndex[statement] = _stack.length;
    _stack.add(_ElementSet.empty); // break set
    _stack.add(_ElementSet.empty); // continue set
  }

  void beginDoWhileStatementCondition() {
    var continueSet = _stack.removeLast();
    // If there was a `continue`, use it.
    // If there was not any, use the current.
    _current = _current.union(continueSet);
  }

  void beginForStatement2(ForStatement statement) {
    // Not strongly necessary, because we discard everything anyway.
    // Just for consistency, so that `break` is handled without `null`.
    _statementToStackIndex[statement] = _stack.length;
  }

  void beginForStatement2Body() {
    _stack.add(_current); // break set
    _stack.add(_ElementSet.empty); // continue set
  }

  void beginForStatementUpdaters() {
    var continueSet = _stack.last;
    _current = _current.union(continueSet);
  }

  void beginFunctionExpression() {
    _stack.add(_current);
  }

  void beginIfStatementElse() {
    var enclosing = _stack.last;
    _stack.last = _current;
    _current = enclosing;
  }

  void beginIfStatementThen() {
    _stack.add(_current);
  }

  void beginSwitchStatement(SwitchStatement statement) {
    _statementToStackIndex[statement] = _stack.length;
    _stack.add(_ElementSet.empty); // break set
    _stack.add(_ElementSet.empty); // continue set (placeholder)
  }

  void beginSwitchStatementMember() {
    _current = _stack.last; // before cases
  }

  void beginTryStatement() {
    _stack.add(_current); // before body, for catches
  }

  void beginTryStatementCatchClause() {
    _current = _stack[_stack.length - 2]; // before body
  }

  void beginWhileStatement(WhileStatement statement) {
    _statementToStackIndex[statement] = _stack.length;
  }

  void beginWhileStatementBody(bool isTrue) {
    _stack.add(isTrue ? _ElementSet.empty : _current); // break set
    _stack.add(_ElementSet.empty); // continue set
  }

  void endAssertStatement() {
    _current = _stack.removeLast();
  }

  void endBinaryExpressionLogicalRight() {
    _current = _stack.removeLast();
  }

  void endConditionalExpression() {
    var thenSet = _stack.removeLast();
    var elseSet = _current;
    _current = thenSet.union(elseSet);
  }

  void endDoWhileStatement() {
    var breakSet = _stack.removeLast();
    // If there was a `break`, use it.
    // If there was not any, use the current.
    _current = _current.union(breakSet);
  }

  void endForStatement2() {
    _stack.removeLast(); // continue set
    _current = _stack.removeLast(); // break set, before body
  }

  void endFunctionExpression() {
    _current = _stack.removeLast();
  }

  void endIfStatement(bool hasElse) {
    if (hasElse) {
      var thenSet = _stack.removeLast();
      var elseSet = _current;
      _current = thenSet.union(elseSet);
    } else {
      var afterCondition = _stack.removeLast();
      _current = afterCondition;
    }
  }

  void endSwitchStatement(bool hasDefault) {
    var beforeCasesSet = _stack.removeLast();
    _stack.removeLast(); // continue set
    var breakSet = _stack.removeLast();
    if (hasDefault) {
      _current = breakSet;
    } else {
      _current = beforeCasesSet;
    }
  }

  void endSwitchStatementExpression() {
    _stack.add(_current); // before cases
  }

  void endTryStatementBody() {
    _stack.add(_current); // union of body and catches
  }

  void endTryStatementCatchClause() {
    _stack.last = _stack.last.union(_current); // union of body and catches
  }

  void endTryStatementCatchClauses() {
    _current = _stack.removeLast(); // union of body and catches
    _stack.removeLast(); // before body
  }

  void endWhileStatement() {
    _stack.removeLast(); // continue set
    _current = _stack.removeLast(); // break set
  }

  /// Handle a `break` statement with the given [target].
  void handleBreak(AstNode target) {
    var breakSetIndex = _statementToStackIndex[target];
    if (breakSetIndex != null) {
      _stack[breakSetIndex] = _stack[breakSetIndex].union(_current);
    }
    _current = _ElementSet.empty;
  }

  /// Handle a `continue` statement with the given [target].
  void handleContinue(AstNode target) {
    var breakSetIndex = _statementToStackIndex[target];
    if (breakSetIndex != null) {
      var continueSetIndex = breakSetIndex + 1;
      _stack[continueSetIndex] = _stack[continueSetIndex].union(_current);
    }
    _current = _ElementSet.empty;
  }

  /// Register the fact that the current branch definitely exists, e.g. returns
  /// from the body, throws an exception, etc.  So, all variables in the branch
  /// are vacuously definitely assigned.
  void handleExit() {
    _current = _ElementSet.empty;
  }

  /// Register read of the given [variable] in the current branch.
  void read(LocalVariableElement variable) {
    if (_current.contains(variable)) {
      // Add to the list of violating variables, if not there yet.
      for (var i = 0; i < readBeforeWritten.length; ++i) {
        var violatingVariable = readBeforeWritten[i];
        if (identical(violatingVariable, variable)) {
          return;
        }
      }
      readBeforeWritten.add(variable);
    }
  }

  /// Register write of the given [variable] in the current branch.
  void write(LocalVariableElement variable) {
    _current = _current.remove(variable);
  }
}

/// List based immutable set of elements.
class _ElementSet {
  static final empty = _ElementSet._(
    List<LocalVariableElement>(0),
  );

  final List<LocalVariableElement> elements;

  _ElementSet._(this.elements);

  _ElementSet add(LocalVariableElement addedElement) {
    if (contains(addedElement)) {
      return this;
    }

    var length = elements.length;
    var newElements = List<LocalVariableElement>(length + 1);
    for (var i = 0; i < length; ++i) {
      newElements[i] = elements[i];
    }
    newElements[length] = addedElement;
    return _ElementSet._(newElements);
  }

  bool contains(LocalVariableElement element) {
    var length = elements.length;
    for (var i = 0; i < length; ++i) {
      if (identical(elements[i], element)) {
        return true;
      }
    }
    return false;
  }

  _ElementSet remove(LocalVariableElement removedElement) {
    if (!contains(removedElement)) {
      return this;
    }

    var length = elements.length;
    if (length == 1) {
      return empty;
    }

    var newElements = List<LocalVariableElement>(length - 1);
    var newIndex = 0;
    for (var i = 0; i < length; ++i) {
      var element = elements[i];
      if (!identical(element, removedElement)) {
        newElements[newIndex++] = element;
      }
    }

    return _ElementSet._(newElements);
  }

  _ElementSet union(_ElementSet other) {
    if (other == null || other.elements.isEmpty) {
      return this;
    }

    var result = this;
    var otherElements = other.elements;
    for (var i = 0; i < otherElements.length; ++i) {
      var otherElement = otherElements[i];
      result = result.add(otherElement);
    }
    return result;
  }
}
