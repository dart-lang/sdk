// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file implements the AST of a Dart-like language suitable for testing
/// flow analysis.  Callers may use the top level methods in this file to create
/// AST nodes and then feed them to [Harness.run] to run them through flow
/// analysis testing.
import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:test/test.dart';

const Expression nullLiteral = const _NullLiteral();

Statement assert_(Expression condition, [Expression? message]) =>
    new _Assert(condition, message);

Statement block(List<Statement> statements) => new _Block(statements);

Expression booleanLiteral(bool value) => _BooleanLiteral(value);

/// Wrapper allowing creation of a statement that can be used as the target of
/// `break` or `continue` statements.  [callback] will be invoked to create the
/// statement, and it will be passed a [BranchTargetPlaceholder] that can be
/// passed to [break_] or [continue_].
Statement branchTarget(Statement Function(BranchTargetPlaceholder) callback) {
  var branchTargetPlaceholder = BranchTargetPlaceholder._();
  var stmt = callback(branchTargetPlaceholder);
  branchTargetPlaceholder._target = stmt;
  return stmt;
}

Statement break_(BranchTargetPlaceholder branchTargetPlaceholder) =>
    new _Break(branchTargetPlaceholder);

SwitchCase case_(List<Statement> body, {bool hasLabel = false}) =>
    SwitchCase._(hasLabel, body);

CatchClause catch_(
        {Var? exception, Var? stackTrace, required List<Statement> body}) =>
    CatchClause._(body, exception, stackTrace);

/// Creates a pseudo-statement whose function is to verify that flow analysis
/// considers [variable]'s assigned state to be [expectedAssignedState].
Statement checkAssigned(Var variable, bool expectedAssignedState) =>
    new _CheckAssigned(variable, expectedAssignedState);

/// Creates a pseudo-statement whose function is to verify that flow analysis
/// considers [variable] to be un-promoted.
Statement checkNotPromoted(Var variable) => new _CheckPromoted(variable, null);

/// Creates a pseudo-statement whose function is to verify that flow analysis
/// considers [variable]'s assigned state to be promoted to [expectedTypeStr].
Statement checkPromoted(Var variable, String? expectedTypeStr) =>
    new _CheckPromoted(variable, expectedTypeStr);

/// Creates a pseudo-statement whose function is to verify that flow analysis
/// considers the current location's reachability state to be
/// [expectedReachable].
Statement checkReachable(bool expectedReachable) =>
    new _CheckReachable(expectedReachable);

/// Creates a pseudo-statement whose function is to verify that flow analysis
/// considers [variable]'s unassigned state to be [expectedUnassignedState].
Statement checkUnassigned(Var variable, bool expectedUnassignedState) =>
    new _CheckUnassigned(variable, expectedUnassignedState);

Statement continue_(BranchTargetPlaceholder branchTargetPlaceholder) =>
    new _Continue(branchTargetPlaceholder);

Statement declare(Var variable,
        {required bool initialized,
        bool isFinal = false,
        bool isLate = false}) =>
    new _Declare(variable, initialized ? expr(variable.type.type) : null,
        isFinal, isLate);

Statement declareInitialized(Var variable, Expression initializer,
        {bool isFinal = false, bool isLate = false}) =>
    new _Declare(variable, initializer, isFinal, isLate);

Statement do_(List<Statement> body, Expression condition) =>
    _Do(body, condition);

/// Creates a pseudo-expression having type [typeStr] that otherwise has no
/// effect on flow analysis.
Expression expr(String typeStr) =>
    new _PlaceholderExpression(new Type(typeStr));

/// Creates a conventional `for` statement.  Optional boolean [forCollection]
/// indicates that this `for` statement is actually a collection element, so
/// `null` should be passed to [for_bodyBegin].
Statement for_(Statement? initializer, Expression? condition,
        Expression? updater, List<Statement> body,
        {bool forCollection = false}) =>
    new _For(initializer, condition, updater, body, forCollection);

/// Creates a "for each" statement where the identifier being assigned to by the
/// iteration is not a local variable.
///
/// This models code like:
///     var x; // Top level variable
///     f(Iterable iterable) {
///       for (x in iterable) { ... }
///     }
Statement forEachWithNonVariable(Expression iterable, List<Statement> body) =>
    new _ForEach(null, iterable, body, false);

/// Creates a "for each" statement where the identifier being assigned to by the
/// iteration is a variable that is being declared by the "for each" statement.
///
/// This models code like:
///     f(Iterable iterable) {
///       for (var x in iterable) { ... }
///     }
Statement forEachWithVariableDecl(
    Var variable, Expression iterable, List<Statement> body) {
  // ignore: unnecessary_null_comparison
  assert(variable != null);
  return new _ForEach(variable, iterable, body, true);
}

/// Creates a "for each" statement where the identifier being assigned to by the
/// iteration is a local variable that is declared elsewhere in the function.
///
/// This models code like:
///     f(Iterable iterable) {
///       var x;
///       for (x in iterable) { ... }
///     }
Statement forEachWithVariableSet(
    Var variable, Expression iterable, List<Statement> body) {
  // ignore: unnecessary_null_comparison
  assert(variable != null);
  return new _ForEach(variable, iterable, body, false);
}

/// Creates a [Statement] that, when analyzed, will cause [callback] to be
/// passed an [SsaNodeHarness] allowing the test to examine the values of
/// variables' SSA nodes.
Statement getSsaNodes(void Function(SsaNodeHarness) callback) =>
    new _GetSsaNodes(callback);

Statement if_(Expression condition, List<Statement> ifTrue,
        [List<Statement>? ifFalse]) =>
    new _If(condition, ifTrue, ifFalse);

Statement labeled(Statement body) => new _LabeledStatement(body);

Statement localFunction(List<Statement> body) => _LocalFunction(body);

Statement return_() => new _Return();

Statement switch_(Expression expression, List<SwitchCase> cases,
        {required bool isExhaustive}) =>
    new _Switch(expression, cases, isExhaustive);

Expression throw_(Expression operand) => new _Throw(operand);

Statement tryCatch(List<Statement> body, List<CatchClause> catches) =>
    new _TryCatch(body, catches);

Statement tryFinally(List<Statement> body, List<Statement> finally_) =>
    new _TryFinally(body, finally_);

Statement while_(Expression condition, List<Statement> body) =>
    new _While(condition, body);

/// Placeholder used by [branchTarget] to tie `break` and `continue` statements
/// to their branch targets.
class BranchTargetPlaceholder {
  late Statement _target;

  BranchTargetPlaceholder._();
}

/// Representation of a single catch clause in a try/catch statement.  Use
/// [catch_] to create instances of this class.
class CatchClause implements _Visitable<void> {
  final List<Statement> _body;
  final Var? _exception;
  final Var? _stackTrace;

  CatchClause._(this._body, this._exception, this._stackTrace);

  String toString() {
    String initialPart;
    if (_stackTrace != null) {
      initialPart = 'catch (${_exception!.name}, ${_stackTrace!.name})';
    } else if (_exception != null) {
      initialPart = 'catch (${_exception!.name})';
    } else {
      initialPart = 'on ...';
    }
    return '$initialPart ${block(_body)}';
  }

  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    _body._preVisit(assignedVariables);
  }

  void _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    flow.tryCatchStatement_catchBegin(_exception, _stackTrace);
    _body._visit(h, flow);
    flow.tryCatchStatement_catchEnd();
  }
}

/// Representation of an expression in the pseudo-Dart language used for flow
/// analysis testing.  Methods in this class may be used to create more complex
/// expressions based on this one.
abstract class Expression implements _Visitable<Type> {
  const Expression();

  /// If `this` is an expression `x`, creates the expression `x!`.
  Expression get nonNullAssert => new _NonNullAssert(this);

  /// If `this` is an expression `x`, creates the expression `!x`.
  Expression get not => new _Not(this);

  /// If `this` is an expression `x`, creates the expression `(x)`.
  Expression get parenthesized => new _ParenthesizedExpression(this);

  /// If `this` is an expression `x`, creates the statement `x;`.
  Statement get stmt => new _ExpressionStatement(this);

  /// If `this` is an expression `x`, creates the expression `x && other`.
  Expression and(Expression other) => new _Logical(this, other, isAnd: true);

  /// If `this` is an expression `x`, creates the expression `x as typeStr`.
  Expression as_(String typeStr) => new _As(this, Type(typeStr));

  /// If `this` is an expression `x`, creates the expression
  /// `x ? ifTrue : ifFalse`.
  Expression conditional(Expression ifTrue, Expression ifFalse) =>
      new _Conditional(this, ifTrue, ifFalse);

  /// If `this` is an expression `x`, creates the expression `x == other`.
  Expression eq(Expression other) => new _Equal(this, other, false);

  /// Creates an [Expression] that, when analyzed, will behave the same as
  /// `this`, but after visiting it, will cause [callback] to be passed the
  /// [ExpressionInfo] associated with it.  If the expression has no flow
  /// analysis information associated with it, `null` will be passed to
  /// [callback].
  Expression getExpressionInfo(
          void Function(ExpressionInfo<Var, Type>?) callback) =>
      new _GetExpressionInfo(this, callback);

  /// If `this` is an expression `x`, creates the expression `x ?? other`.
  Expression ifNull(Expression other) => new _IfNull(this, other);

  /// If `this` is an expression `x`, creates the expression `x is typeStr`.
  ///
  /// With [isInverted] set to `true`, creates the expression `x is! typeStr`.
  Expression is_(String typeStr, {bool isInverted = false}) =>
      new _Is(this, Type(typeStr), isInverted);

  /// If `this` is an expression `x`, creates the expression `x is! typeStr`.
  Expression isNot(String typeStr) => _Is(this, Type(typeStr), true);

  /// If `this` is an expression `x`, creates the expression `x != other`.
  Expression notEq(Expression other) => _Equal(this, other, true);

  /// If `this` is an expression `x`, creates the expression `x?.other`.
  ///
  /// Note that in the real Dart language, the RHS of a null aware access isn't
  /// strictly speaking an expression.  However for flow analysis it suffices to
  /// model it as an expression.
  Expression nullAwareAccess(Expression other, {bool isCascaded = false}) =>
      _NullAwareAccess(this, other, isCascaded);

  /// If `this` is an expression `x`, creates the expression `x || other`.
  Expression or(Expression other) => new _Logical(this, other, isAnd: false);

  /// If `this` is an expression `x`, creates a pseudo-expression that models
  /// evaluation of `x` followed by execution of [stmt].  This can be used to
  /// test that flow analysis is in the correct state after an expression is
  /// visited.
  Expression thenStmt(Statement stmt) =>
      new _WrappedExpression(null, this, stmt);
}

/// Test harness for creating flow analysis tests.  This class implements all
/// the [TypeOperations] needed by flow analysis, as well as other methods
/// needed for testing.
class Harness extends TypeOperations<Var, Type> {
  static const Map<String, bool> _coreSubtypes = const {
    'bool <: int': false,
    'bool <: Object': true,
    'double <: Object': true,
    'double <: num': true,
    'double <: num?': true,
    'double <: int': false,
    'double <: int?': false,
    'int <: double': false,
    'int <: int?': true,
    'int <: Iterable': false,
    'int <: List': false,
    'int <: Null': false,
    'int <: num': true,
    'int <: num?': true,
    'int <: num*': true,
    'int <: Never?': false,
    'int <: Object': true,
    'int <: Object?': true,
    'int <: String': false,
    'int? <: int': false,
    'int? <: Null': false,
    'int? <: num': false,
    'int? <: num?': true,
    'int? <: Object': false,
    'int? <: Object?': true,
    'Null <: int': false,
    'Null <: Object': false,
    'num <: int': false,
    'num <: Iterable': false,
    'num <: List': false,
    'num <: num?': true,
    'num <: num*': true,
    'num <: Object': true,
    'num <: Object?': true,
    'num? <: int?': false,
    'num? <: num': false,
    'num? <: num*': true,
    'num? <: Object': false,
    'num? <: Object?': true,
    'num* <: num': true,
    'num* <: num?': true,
    'num* <: Object': true,
    'num* <: Object?': true,
    'Iterable <: int': false,
    'Iterable <: num': false,
    'Iterable <: Object': true,
    'Iterable <: Object?': true,
    'List <: int': false,
    'List <: Iterable': true,
    'List <: Object': true,
    'Never <: int': true,
    'Never <: int?': true,
    'Never <: Null': true,
    'Never? <: int': false,
    'Never? <: int?': true,
    'Never? <: num?': true,
    'Never? <: Object?': true,
    'Null <: int?': true,
    'Object <: int': false,
    'Object <: int?': false,
    'Object <: List': false,
    'Object <: num': false,
    'Object <: num?': false,
    'Object <: Object?': true,
    'Object <: String': false,
    'Object? <: Object': false,
    'Object? <: int': false,
    'Object? <: int?': false,
    'String <: int': false,
    'String <: int?': false,
    'String <: num?': false,
    'String <: Object': true,
    'String <: Object?': true,
  };

  static final Map<String, Type> _coreFactors = {
    'Object? - int': Type('Object?'),
    'Object? - int?': Type('Object'),
    'Object? - num?': Type('Object'),
    'Object? - Object?': Type('Never?'),
    'Object? - String': Type('Object?'),
    'Object - bool': Type('Object'),
    'Object - int': Type('Object'),
    'Object - String': Type('Object'),
    'int - Object': Type('Never'),
    'int - String': Type('int'),
    'int - int': Type('Never'),
    'int - int?': Type('Never'),
    'int? - int': Type('Never?'),
    'int? - int?': Type('Never'),
    'int? - String': Type('int?'),
    'Null - int': Type('Null'),
    'num - int': Type('num'),
    'num? - num': Type('Never?'),
    'num? - int': Type('num?'),
    'num? - int?': Type('num'),
    'num? - Object': Type('Never?'),
    'num? - String': Type('num?'),
    'Object - int?': Type('Object'),
    'Object - num': Type('Object'),
    'Object - num?': Type('Object'),
    'Object - num*': Type('Object'),
    'Object - Iterable': Type('Object'),
    'Object? - Object': Type('Never?'),
    'Object? - Iterable': Type('Object?'),
    'Object? - num': Type('Object?'),
    'Iterable - List': Type('Iterable'),
    'num* - Object': Type('Never'),
  };

  final bool allowLocalBooleanVarsToPromote;

  final Map<String, bool> _subtypes = Map.of(_coreSubtypes);

  final Map<String, Type> _factorResults = Map.of(_coreFactors);

  Node? _currentSwitch;

  Harness({this.allowLocalBooleanVarsToPromote = false});

  /// Updates the harness so that when a [factor] query is invoked on types
  /// [from] and [what], [result] will be returned.
  void addFactor(Type from, Type what, Type result) {
    var query = '$from - $what';
    _factorResults[query] = result;
  }

  /// Updates the harness so that when an [isSubtypeOf] query is invoked on
  /// types [leftType] and [rightType], [isSubtype] will be returned.
  void addSubtype(Type leftType, Type rightType, bool isSubtype) {
    var query = '$leftType <: $rightType';
    _subtypes[query] = isSubtype;
  }

  @override
  TypeClassification classifyType(Type type) {
    if (isSubtypeOf(type, Type('Object'))) {
      return TypeClassification.nonNullable;
    } else if (isSubtypeOf(type, Type('Null'))) {
      return TypeClassification.nullOrEquivalent;
    } else {
      return TypeClassification.potentiallyNullable;
    }
  }

  @override
  Type factor(Type from, Type what) {
    var query = '$from - $what';
    return _factorResults[query] ?? fail('Unknown factor query: $query');
  }

  @override
  bool isNever(Type type) {
    return type.type == 'Never';
  }

  @override
  bool isSameType(Type type1, Type type2) {
    return type1.type == type2.type;
  }

  @override
  bool isSubtypeOf(Type leftType, Type rightType) {
    if (leftType.type == rightType.type) return true;
    var query = '$leftType <: $rightType';
    return _subtypes[query] ?? fail('Unknown subtype query: $query');
  }

  @override
  Type promoteToNonNull(Type type) {
    if (type.type.endsWith('?')) {
      return Type(type.type.substring(0, type.type.length - 1));
    } else if (type.type == 'Null') {
      return Type('Never');
    } else {
      return type;
    }
  }

  /// Runs the given [statements] through flow analysis, checking any assertions
  /// they contain.
  void run(List<Statement> statements) {
    var assignedVariables = AssignedVariables<Node, Var>();
    statements._preVisit(assignedVariables);
    var flow = FlowAnalysis<Node, Statement, Expression, Var, Type>(
        this, assignedVariables,
        allowLocalBooleanVarsToPromote: allowLocalBooleanVarsToPromote);
    statements._visit(this, flow);
    flow.finish();
  }

  @override
  Type? tryPromoteToType(Type to, Type from) {
    if (isSubtypeOf(to, from)) {
      return to;
    } else {
      return null;
    }
  }

  @override
  Type variableType(Var variable) {
    return variable.type;
  }

  Type _getIteratedType(Type iterableType) {
    var typeStr = iterableType.type;
    if (typeStr.startsWith('List<') && typeStr.endsWith('>')) {
      return Type(typeStr.substring(5, typeStr.length - 1));
    } else {
      throw UnimplementedError('TODO(paulberry): getIteratedType($typeStr)');
    }
  }

  Type _lub(Type type1, Type type2) {
    if (isSameType(type1, type2)) {
      return type1;
    } else if (isSameType(promoteToNonNull(type1), type2)) {
      return type1;
    } else if (isSameType(promoteToNonNull(type2), type1)) {
      return type2;
    } else if (type1.type == 'Null' &&
        !isSameType(promoteToNonNull(type2), type2)) {
      // type2 is already nullable
      return type2;
    } else if (type2.type == 'Null' &&
        !isSameType(promoteToNonNull(type1), type1)) {
      // type1 is already nullable
      return type1;
    } else if (type1.type == 'Never') {
      return type2;
    } else if (type2.type == 'Never') {
      return type1;
    } else {
      throw UnimplementedError(
          'TODO(paulberry): least upper bound of $type1 and $type2');
    }
  }
}

/// Representation of an expression or statement in the pseudo-Dart language
/// used for flow analysis testing.
class Node {
  Node._();
}

/// Helper class allowing tests to examine the values of variables' SSA nodes.
class SsaNodeHarness {
  final FlowAnalysis<Node, Statement, Expression, Var, Type> _flow;

  SsaNodeHarness(this._flow);

  /// Gets the SSA node associated with [variable] at the current point in
  /// control flow, or `null` if the variable has been write captured.
  SsaNode<Var, Type>? operator [](Var variable) =>
      _flow.ssaNodeForTesting(variable);
}

/// Representation of a statement in the pseudo-Dart language used for flow
/// analysis testing.
abstract class Statement extends Node implements _Visitable<void> {
  Statement._() : super._();

  /// If `this` is a statement `x`, creates a pseudo-expression that models
  /// execution of `x` followed by evaluation of [expr].  This can be used to
  /// test that flow analysis is in the correct state before an expression is
  /// visited.
  Expression thenExpr(Expression expr) => _WrappedExpression(this, expr, null);
}

/// Representation of a single case clause in a switch statement.  Use [case_]
/// to create instances of this class.
class SwitchCase implements _Visitable<void> {
  final bool _hasLabel;
  final List<Statement> _body;

  SwitchCase._(this._hasLabel, this._body);

  String toString() =>
      [if (_hasLabel) '<label>:', 'case <value>:', ..._body].join(' ');

  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    _body._preVisit(assignedVariables);
  }

  void _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    flow.switchStatement_beginCase(_hasLabel, h._currentSwitch!);
    _body._visit(h, flow);
  }
}

/// Representation of a type in the pseudo-Dart language used for flow analysis
/// testing.  This is essentially a thin wrapper around a string representation
/// of the type.
class Type {
  final String type;

  Type(this.type);

  @override
  bool operator ==(Object other) {
    // The flow analysis engine should not compare types using operator==.  It
    // should compare them using TypeOperations.
    fail('Unexpected use of operator== on types');
  }

  @override
  String toString() => type;
}

/// Representation of a local variable in the pseudo-Dart language used for flow
/// analysis testing.
class Var {
  final String name;
  final Type type;

  Var(this.name, String typeStr) : type = Type(typeStr);

  /// Creates an expression representing a read of this variable.
  Expression get read => new _VariableRead(this);

  @override
  String toString() => '$type $name';

  /// Creates an expression representing a write to this variable.
  Expression write(Expression? value) => new _Write(this, value);
}

class _As extends Expression {
  final Expression target;
  final Type type;

  _As(this.target, this.type);

  @override
  String toString() => '$target as $type';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    target._preVisit(assignedVariables);
  }

  @override
  Type _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    target._visit(h, flow);
    flow.asExpression_end(target, type);
    return type;
  }
}

class _Assert extends Statement {
  final Expression condition;
  final Expression? message;

  _Assert(this.condition, this.message) : super._();

  @override
  String toString() =>
      'assert($condition${message == null ? '' : ', $message'});';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    condition._preVisit(assignedVariables);
    message?._preVisit(assignedVariables);
  }

  @override
  void _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    flow.assert_begin();
    flow.assert_afterCondition(condition.._visit(h, flow));
    message?._visit(h, flow);
    flow.assert_end();
  }
}

class _Block extends Statement {
  final List<Statement> statements;

  _Block(this.statements) : super._();

  @override
  String toString() =>
      statements.isEmpty ? '{}' : '{ ${statements.join(' ')} }';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    statements._preVisit(assignedVariables);
  }

  @override
  void _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    statements._visit(h, flow);
  }
}

class _BooleanLiteral extends Expression {
  final bool value;

  _BooleanLiteral(this.value);

  @override
  String toString() => '$value';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {}

  @override
  Type _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    flow.booleanLiteral(this, value);
    return Type('bool');
  }
}

class _Break extends Statement {
  final BranchTargetPlaceholder branchTargetPlaceholder;

  _Break(this.branchTargetPlaceholder) : super._();

  @override
  String toString() => 'break;';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {}

  @override
  void _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    // ignore: unnecessary_null_comparison
    assert(branchTargetPlaceholder._target != null);
    flow.handleBreak(branchTargetPlaceholder._target);
  }
}

class _CheckAssigned extends Statement {
  final Var variable;
  final bool expectedAssignedState;

  _CheckAssigned(this.variable, this.expectedAssignedState) : super._();

  @override
  String toString() {
    var verb = expectedAssignedState ? 'is' : 'is not';
    return 'check $variable $verb definitely assigned;';
  }

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {}

  @override
  void _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    expect(flow.isAssigned(variable), expectedAssignedState);
  }
}

class _CheckPromoted extends Statement {
  final Var variable;
  final String? expectedTypeStr;

  _CheckPromoted(this.variable, this.expectedTypeStr) : super._();

  @override
  String toString() {
    var predicate = expectedTypeStr == null
        ? 'not promoted'
        : 'promoted to $expectedTypeStr';
    return 'check $variable $predicate;';
  }

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {}

  @override
  void _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    var promotedType = flow.promotedType(variable);
    if (expectedTypeStr == null) {
      expect(promotedType, isNull);
    } else {
      expect(promotedType?.type, expectedTypeStr);
    }
  }
}

class _CheckReachable extends Statement {
  final bool expectedReachable;

  _CheckReachable(this.expectedReachable) : super._();

  @override
  String toString() => 'check reachable;';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {}

  @override
  void _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    expect(flow.isReachable, expectedReachable);
  }
}

class _CheckUnassigned extends Statement {
  final Var variable;
  final bool expectedUnassignedState;

  _CheckUnassigned(this.variable, this.expectedUnassignedState) : super._();

  @override
  String toString() {
    var verb = expectedUnassignedState ? 'is' : 'is not';
    return 'check $variable $verb definitely unassigned;';
  }

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {}

  @override
  void _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    expect(flow.isUnassigned(variable), expectedUnassignedState);
  }
}

class _Conditional extends Expression {
  final Expression condition;
  final Expression ifTrue;
  final Expression ifFalse;

  _Conditional(this.condition, this.ifTrue, this.ifFalse);

  @override
  String toString() => '$condition ? $ifTrue : $ifFalse';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    condition._preVisit(assignedVariables);
    ifTrue._preVisit(assignedVariables);
    ifFalse._preVisit(assignedVariables);
  }

  @override
  Type _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    flow.conditional_conditionBegin();
    flow.conditional_thenBegin(condition.._visit(h, flow));
    var ifTrueType = ifTrue._visit(h, flow);
    flow.conditional_elseBegin(ifTrue);
    var ifFalseType = ifFalse._visit(h, flow);
    flow.conditional_end(this, ifFalse);
    return h._lub(ifTrueType, ifFalseType);
  }
}

class _Continue extends Statement {
  final BranchTargetPlaceholder branchTargetPlaceholder;

  _Continue(this.branchTargetPlaceholder) : super._();

  @override
  String toString() => 'continue;';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {}

  @override
  void _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    // ignore: unnecessary_null_comparison
    assert(branchTargetPlaceholder._target != null);
    flow.handleContinue(branchTargetPlaceholder._target);
  }
}

class _Declare extends Statement {
  final Var variable;
  final Expression? initializer;
  final bool isFinal;
  final bool isLate;

  _Declare(this.variable, this.initializer, this.isFinal, this.isLate)
      : super._();

  @override
  String toString() {
    var latePart = isLate ? 'late ' : '';
    var finalPart = isFinal ? 'final ' : '';
    var initializerPart = initializer != null ? ' = $initializer' : '';
    return '$latePart$finalPart$variable${initializerPart};';
  }

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    initializer?._preVisit(assignedVariables);
  }

  @override
  void _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    var initializer = this.initializer;
    if (initializer == null) {
      flow.declare(variable, false);
    } else {
      var initializerType = initializer._visit(h, flow);
      flow.declare(variable, true);
      flow.initialize(variable, initializerType, initializer,
          isFinal: isFinal, isLate: isLate);
    }
  }
}

class _Do extends Statement {
  final List<Statement> body;
  final Expression condition;

  _Do(this.body, this.condition) : super._();

  @override
  String toString() => 'do ${block(body)} while ($condition);';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    assignedVariables.beginNode();
    body._preVisit(assignedVariables);
    condition._preVisit(assignedVariables);
    assignedVariables.endNode(this);
  }

  @override
  void _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    flow.doStatement_bodyBegin(this);
    body._visit(h, flow);
    flow.doStatement_conditionBegin();
    condition._visit(h, flow);
    flow.doStatement_end(condition);
  }
}

class _Equal extends Expression {
  final Expression lhs;
  final Expression rhs;
  final bool isInverted;

  _Equal(this.lhs, this.rhs, this.isInverted);

  @override
  String toString() => '$lhs ${isInverted ? '!=' : '=='} $rhs';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    lhs._preVisit(assignedVariables);
    rhs._preVisit(assignedVariables);
  }

  @override
  Type _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    var lhsType = lhs._visit(h, flow);
    flow.equalityOp_rightBegin(lhs, lhsType);
    var rhsType = rhs._visit(h, flow);
    flow.equalityOp_end(this, rhs, rhsType, notEqual: isInverted);
    return Type('bool');
  }
}

class _ExpressionStatement extends Statement {
  final Expression expr;

  _ExpressionStatement(this.expr) : super._();

  @override
  String toString() => '$expr;';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    expr._preVisit(assignedVariables);
  }

  @override
  void _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    expr._visit(h, flow);
  }
}

class _For extends Statement {
  final Statement? initializer;
  final Expression? condition;
  final Expression? updater;
  final List<Statement> body;
  final bool forCollection;

  _For(this.initializer, this.condition, this.updater, this.body,
      this.forCollection)
      : super._();

  @override
  String toString() {
    var buffer = StringBuffer('for (');
    if (initializer == null) {
      buffer.write(';');
    } else {
      buffer.write(initializer);
    }
    if (condition == null) {
      buffer.write(';');
    } else {
      buffer.write(' $condition;');
    }
    if (updater != null) {
      buffer.write(' $updater');
    }
    buffer.write(') ${block(body)}');
    return buffer.toString();
  }

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    initializer?._preVisit(assignedVariables);
    assignedVariables.beginNode();
    condition?._preVisit(assignedVariables);
    body._preVisit(assignedVariables);
    updater?._preVisit(assignedVariables);
    assignedVariables.endNode(this);
  }

  @override
  void _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    initializer?._visit(h, flow);
    flow.for_conditionBegin(this);
    condition?._visit(h, flow);
    flow.for_bodyBegin(forCollection ? null : this, condition);
    body._visit(h, flow);
    flow.for_updaterBegin();
    updater?._visit(h, flow);
    flow.for_end();
  }
}

class _ForEach extends Statement {
  final Var? variable;
  final Expression iterable;
  final List<Statement> body;
  final bool declaresVariable;

  _ForEach(this.variable, this.iterable, this.body, this.declaresVariable)
      : super._();

  @override
  String toString() {
    String declarationPart;
    if (variable == null) {
      declarationPart = '<identifier>';
    } else if (declaresVariable) {
      declarationPart = variable.toString();
    } else {
      declarationPart = variable!.name;
    }
    return 'for ($declarationPart in $iterable) ${block(body)}';
  }

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    iterable._preVisit(assignedVariables);
    if (variable != null) {
      if (declaresVariable) {
        assignedVariables.declare(variable!);
      } else {
        assignedVariables.write(variable!);
      }
    }
    assignedVariables.beginNode();
    body._preVisit(assignedVariables);
    assignedVariables.endNode(this);
  }

  @override
  void _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    var iteratedType = h._getIteratedType(iterable._visit(h, flow));
    flow.forEach_bodyBegin(this, variable, iteratedType);
    body._visit(h, flow);
    flow.forEach_end();
  }
}

class _GetExpressionInfo extends Expression {
  final Expression target;

  final void Function(ExpressionInfo<Var, Type>?) callback;

  _GetExpressionInfo(this.target, this.callback);

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    target._preVisit(assignedVariables);
  }

  @override
  Type _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    var type = target._visit(h, flow);
    flow.forwardExpression(this, target);
    callback(flow.expressionInfoForTesting(this));
    return type;
  }
}

class _GetSsaNodes extends Statement {
  final void Function(SsaNodeHarness) callback;

  _GetSsaNodes(this.callback) : super._();

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {}

  @override
  void _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    callback(SsaNodeHarness(flow));
  }
}

class _If extends Statement {
  final Expression condition;
  final List<Statement> ifTrue;
  final List<Statement>? ifFalse;

  _If(this.condition, this.ifTrue, this.ifFalse) : super._();

  @override
  String toString() =>
      'if ($condition) ${block(ifTrue)}' +
      (ifFalse == null ? '' : 'else ${block(ifFalse!)}');

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    condition._preVisit(assignedVariables);
    ifTrue._preVisit(assignedVariables);
    ifFalse?._preVisit(assignedVariables);
  }

  @override
  void _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    flow.ifStatement_conditionBegin();
    flow.ifStatement_thenBegin(condition.._visit(h, flow));
    ifTrue._visit(h, flow);
    if (ifFalse == null) {
      flow.ifStatement_end(false);
    } else {
      flow.ifStatement_elseBegin();
      ifFalse!._visit(h, flow);
      flow.ifStatement_end(true);
    }
  }
}

class _IfNull extends Expression {
  final Expression lhs;
  final Expression rhs;

  _IfNull(this.lhs, this.rhs);

  @override
  String toString() => '$lhs ?? $rhs';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    lhs._preVisit(assignedVariables);
    rhs._preVisit(assignedVariables);
  }

  @override
  Type _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    var lhsType = lhs._visit(h, flow);
    flow.ifNullExpression_rightBegin(lhs, lhsType);
    var rhsType = rhs._visit(h, flow);
    flow.ifNullExpression_end();
    return h._lub(h.promoteToNonNull(lhsType), rhsType);
  }
}

class _Is extends Expression {
  final Expression target;
  final Type type;
  final bool isInverted;

  _Is(this.target, this.type, this.isInverted);

  @override
  String toString() => '$target is${isInverted ? '!' : ''} $type';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    target._preVisit(assignedVariables);
  }

  @override
  Type _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    flow.isExpression_end(this, target.._visit(h, flow), isInverted, type);
    return Type('bool');
  }
}

class _LabeledStatement extends Statement {
  final Statement body;

  _LabeledStatement(this.body) : super._();

  @override
  String toString() => 'labeled: $body';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    body._preVisit(assignedVariables);
  }

  @override
  void _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    flow.labeledStatement_begin(this);
    body._visit(h, flow);
    flow.labeledStatement_end();
  }
}

class _LocalFunction extends Statement {
  final List<Statement> body;

  _LocalFunction(this.body) : super._();

  @override
  String toString() => '() ${block(body)}';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    assignedVariables.beginNode();
    body._preVisit(assignedVariables);
    assignedVariables.endNode(this, isClosureOrLateVariableInitializer: true);
  }

  @override
  void _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    flow.functionExpression_begin(this);
    body._visit(h, flow);
    flow.functionExpression_end();
  }
}

class _Logical extends Expression {
  final Expression lhs;
  final Expression rhs;
  final bool isAnd;

  _Logical(this.lhs, this.rhs, {required this.isAnd});

  @override
  String toString() => '$lhs ${isAnd ? '&&' : '||'} $rhs';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    lhs._preVisit(assignedVariables);
    rhs._preVisit(assignedVariables);
  }

  @override
  Type _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    flow.logicalBinaryOp_begin();
    flow.logicalBinaryOp_rightBegin(lhs.._visit(h, flow), isAnd: isAnd);
    flow.logicalBinaryOp_end(this, rhs.._visit(h, flow), isAnd: isAnd);
    return Type('bool');
  }
}

class _NonNullAssert extends Expression {
  final Expression operand;

  _NonNullAssert(this.operand);

  @override
  String toString() => '$operand!';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    operand._preVisit(assignedVariables);
  }

  @override
  Type _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    var type = operand._visit(h, flow);
    flow.nonNullAssert_end(operand);
    return h.promoteToNonNull(type);
  }
}

class _Not extends Expression {
  final Expression operand;

  _Not(this.operand);

  @override
  String toString() => '!$operand';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    operand._preVisit(assignedVariables);
  }

  @override
  Type _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    flow.logicalNot_end(this, operand.._visit(h, flow));
    return Type('bool');
  }
}

class _NullAwareAccess extends Expression {
  final Expression lhs;
  final Expression rhs;
  final bool isCascaded;

  _NullAwareAccess(this.lhs, this.rhs, this.isCascaded);

  @override
  String toString() => '$lhs?.${isCascaded ? '.' : ''}($rhs)';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    lhs._preVisit(assignedVariables);
    rhs._preVisit(assignedVariables);
  }

  @override
  Type _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    var lhsType = lhs._visit(h, flow);
    flow.nullAwareAccess_rightBegin(isCascaded ? null : lhs, lhsType);
    var rhsType = rhs._visit(h, flow);
    flow.nullAwareAccess_end();
    return h._lub(rhsType, Type('Null'));
  }
}

class _NullLiteral extends Expression {
  const _NullLiteral();

  @override
  String toString() => 'null';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {}

  @override
  Type _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    flow.nullLiteral(this);
    return Type('Null');
  }
}

class _ParenthesizedExpression extends Expression {
  final Expression expr;

  _ParenthesizedExpression(this.expr);

  @override
  String toString() => '($expr)';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    expr._preVisit(assignedVariables);
  }

  @override
  Type _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    var type = expr._visit(h, flow);
    flow.parenthesizedExpression(this, expr);
    return type;
  }
}

class _PlaceholderExpression extends Expression {
  final Type type;

  _PlaceholderExpression(this.type);

  @override
  String toString() => '(expr with type $type)';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {}

  @override
  Type _visit(Harness h,
          FlowAnalysis<Node, Statement, Expression, Var, Type> flow) =>
      type;
}

class _Return extends Statement {
  _Return() : super._();

  @override
  String toString() => 'return;';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {}

  @override
  void _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    flow.handleExit();
  }
}

class _Switch extends Statement {
  final Expression expression;
  final List<SwitchCase> cases;
  final bool isExhaustive;

  _Switch(this.expression, this.cases, this.isExhaustive) : super._();

  @override
  String toString() {
    var exhaustiveness = isExhaustive ? 'exhaustive' : 'non-exhaustive';
    String body;
    if (cases.isEmpty) {
      body = '{}';
    } else {
      var contents = cases.join(' ');
      body = '{ $contents }';
    }
    return 'switch<$exhaustiveness> ($expression) $body';
  }

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    expression._preVisit(assignedVariables);
    assignedVariables.beginNode();
    cases._preVisit(assignedVariables);
    assignedVariables.endNode(this);
  }

  @override
  void _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    expression._visit(h, flow);
    flow.switchStatement_expressionEnd(this);
    var oldSwitch = h._currentSwitch;
    h._currentSwitch = this;
    cases._visit(h, flow);
    h._currentSwitch = oldSwitch;
    flow.switchStatement_end(isExhaustive);
  }
}

class _Throw extends Expression {
  final Expression operand;

  _Throw(this.operand);

  @override
  String toString() => 'throw ...';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    operand._preVisit(assignedVariables);
  }

  @override
  Type _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    operand._visit(h, flow);
    flow.handleExit();
    return Type('Never');
  }
}

class _TryCatch extends Statement {
  final List<Statement> body;
  final List<CatchClause> catches;

  _TryCatch(this.body, this.catches) : super._();

  @override
  String toString() => 'try ${block(body)} ${catches.join(' ')}';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    assignedVariables.beginNode();
    body._preVisit(assignedVariables);
    assignedVariables.endNode(this);
    catches._preVisit(assignedVariables);
  }

  @override
  void _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    flow.tryCatchStatement_bodyBegin();
    body._visit(h, flow);
    flow.tryCatchStatement_bodyEnd(this);
    catches._visit(h, flow);
    flow.tryCatchStatement_end();
  }
}

class _TryFinally extends Statement {
  final List<Statement> body;
  final List<Statement> finally_;
  final Node _bodyNode = Node._();
  final Node _finallyNode = Node._();

  _TryFinally(this.body, this.finally_) : super._();

  @override
  String toString() => 'try ${block(body)} finally ${block(finally_)}';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    assignedVariables.beginNode();
    body._preVisit(assignedVariables);
    assignedVariables.endNode(_bodyNode);
    assignedVariables.beginNode();
    finally_._preVisit(assignedVariables);
    assignedVariables.endNode(_finallyNode);
  }

  @override
  void _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    flow.tryFinallyStatement_bodyBegin();
    body._visit(h, flow);
    flow.tryFinallyStatement_finallyBegin(_bodyNode);
    finally_._visit(h, flow);
    flow.tryFinallyStatement_end(_finallyNode);
  }
}

class _VariableRead extends Expression {
  final Var variable;

  _VariableRead(this.variable);

  @override
  String toString() => variable.name;

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {}

  @override
  Type _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    return flow.variableRead(this, variable) ?? variable.type;
  }
}

abstract class _Visitable<T> {
  void _preVisit(AssignedVariables<Node, Var> assignedVariables);

  T _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow);
}

class _While extends Statement {
  final Expression condition;
  final List<Statement> body;

  _While(this.condition, this.body) : super._();

  @override
  String toString() => 'while ($condition) ${block(body)}';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    assignedVariables.beginNode();
    condition._preVisit(assignedVariables);
    body._preVisit(assignedVariables);
    assignedVariables.endNode(this);
  }

  @override
  void _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    flow.whileStatement_conditionBegin(this);
    condition._visit(h, flow);
    flow.whileStatement_bodyBegin(this, condition);
    body._visit(h, flow);
    flow.whileStatement_end();
  }
}

class _WrappedExpression extends Expression {
  final Statement? before;
  final Expression expr;
  final Statement? after;

  _WrappedExpression(this.before, this.expr, this.after);

  @override
  String toString() {
    var s = StringBuffer('(');
    if (before != null) {
      s.write('($before) ');
    }
    s.write(expr);
    if (after != null) {
      s.write(' ($after)');
    }
    s.write(')');
    return s.toString();
  }

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    before?._preVisit(assignedVariables);
    expr._preVisit(assignedVariables);
    after?._preVisit(assignedVariables);
  }

  @override
  Type _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    before?._visit(h, flow);
    var type = expr._visit(h, flow);
    after?._visit(h, flow);
    flow.forwardExpression(this, expr);
    return type;
  }
}

class _Write extends Expression {
  final Var variable;
  final Expression? rhs;

  _Write(this.variable, this.rhs);

  @override
  String toString() => '${variable.name} = $rhs';

  @override
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    assignedVariables.write(variable);
    rhs?._preVisit(assignedVariables);
  }

  @override
  Type _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    var rhs = this.rhs;
    var type = rhs == null ? variable.type : rhs._visit(h, flow);
    flow.write(variable, type, rhs);
    return type;
  }
}

extension on List<_Visitable<void>> {
  void _preVisit(AssignedVariables<Node, Var> assignedVariables) {
    for (var element in this) {
      element._preVisit(assignedVariables);
    }
  }

  void _visit(
      Harness h, FlowAnalysis<Node, Statement, Expression, Var, Type> flow) {
    for (var element in this) {
      element._visit(h, flow);
    }
  }
}
