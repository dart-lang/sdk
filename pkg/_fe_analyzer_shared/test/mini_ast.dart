// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file implements the AST of a Dart-like language suitable for testing
/// flow analysis.  Callers may use the top level methods in this file to create
/// AST nodes and then feed them to [Harness.run] to run them through flow
/// analysis testing.
import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart'
    show
        ExpressionInfo,
        ExpressionPropertyTarget,
        FlowAnalysis,
        Operations,
        SuperPropertyTarget,
        ThisPropertyTarget;
import 'package:_fe_analyzer_shared/src/type_inference/assigned_variables.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analysis_result.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analysis_result.dart'
    as shared;
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart'
    hide MapPatternEntry, NamedType, RecordPatternField, RecordType;
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart'
    as shared;
import 'package:_fe_analyzer_shared/src/type_inference/type_operations.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_operations.dart'
    as shared;
import 'package:_fe_analyzer_shared/src/type_inference/variable_bindings.dart';
import 'package:test/test.dart';

import 'mini_ir.dart';
import 'mini_types.dart';

final RegExp _locationRegExp =
    RegExp('(file:)?[a-zA-Z0-9_./]+.dart:[0-9]+:[0-9]+');

SwitchHeadDefault get default_ =>
    SwitchHeadDefault(location: computeLocation());

Expression get nullLiteral => new NullLiteral._(location: computeLocation());

Expression get this_ => new This._(location: computeLocation());

Statement assert_(Expression condition, [Expression? message]) =>
    new Assert._(condition, message, location: computeLocation());

Statement block(List<Statement> statements) =>
    new Block._(statements, location: computeLocation());

Expression booleanLiteral(bool value) =>
    BooleanLiteral._(value, location: computeLocation());

Statement break_([Label? target]) =>
    new Break(target, location: computeLocation());

/// Creates a pseudo-statement whose function is to verify that flow analysis
/// considers [variable]'s assigned state to be [expectedAssignedState].
Statement checkAssigned(Var variable, bool expectedAssignedState) =>
    new CheckAssigned._(variable, expectedAssignedState,
        location: computeLocation());

/// Creates a pseudo-statement whose function is to verify that flow analysis
/// considers [promotable] to be un-promoted.
Statement checkNotPromoted(Promotable promotable) =>
    new CheckPromoted._(promotable, null, location: computeLocation());

/// Creates a pseudo-statement whose function is to verify that flow analysis
/// considers [promotable]'s assigned state to be promoted to [expectedTypeStr].
Statement checkPromoted(Promotable promotable, String? expectedTypeStr) =>
    new CheckPromoted._(promotable, expectedTypeStr,
        location: computeLocation());

/// Creates a pseudo-statement whose function is to verify that flow analysis
/// considers the current location's reachability state to be
/// [expectedReachable].
Statement checkReachable(bool expectedReachable) =>
    new CheckReachable(expectedReachable, location: computeLocation());

/// Creates a pseudo-statement whose function is to verify that flow analysis
/// considers [variable]'s unassigned state to be [expectedUnassignedState].
Statement checkUnassigned(Var variable, bool expectedUnassignedState) =>
    new CheckUnassigned._(variable, expectedUnassignedState,
        location: computeLocation());

/// Computes a "location" string using `StackTrace.current` to find the source
/// location of the caller's caller.
///
/// Note: this is highly dependent on the behavior of VM stack traces.  This
/// won't work in code compiled with dart2js for example.  That's fine, though,
/// since we only run these tests under the VM.
String computeLocation() {
  var callStack = StackTrace.current.toString().split('\n');
  assert(callStack[0].contains('mini_ast.dart'));
  assert(callStack[1].contains('mini_ast.dart'));

  String stackLine;
  if (callStack[3].contains('joinPatternVariables')) {
    stackLine = callStack[3];
  } else {
    stackLine = callStack[2];
    assert(
        stackLine.contains('type_inference_test.dart') ||
            stackLine.contains('flow_analysis_test.dart'),
        'Unexpected file: $stackLine');
  }

  var match = _locationRegExp.firstMatch(stackLine);
  if (match == null) {
    throw AssertionError(
        '_locationRegExp failed to match $stackLine in $callStack');
  }
  return match.group(0)!;
}

Statement continue_([Label? target]) =>
    new Continue._(target, location: computeLocation());

Statement declare(Var variable,
    {bool isLate = false,
    bool isFinal = false,
    String? type,
    Expression? initializer,
    String? expectInferredType}) {
  var location = computeLocation();
  return new Declare._(
      new VariablePattern._(
          type == null ? null : Type(type), variable, expectInferredType,
          location: location),
      initializer,
      isLate: isLate,
      isFinal: isFinal,
      location: location);
}

Statement do_(List<Statement> body, Expression condition) {
  var location = computeLocation();
  return Do._(Block._(body, location: location), condition, location: location);
}

/// Creates a pseudo-expression having type [typeStr] that otherwise has no
/// effect on flow analysis.
Expression expr(String typeStr) =>
    new PlaceholderExpression._(new Type(typeStr), location: computeLocation());

/// Creates a conventional `for` statement.  Optional boolean [forCollection]
/// indicates that this `for` statement is actually a collection element, so
/// `null` should be passed to [for_bodyBegin].
Statement for_(Statement? initializer, Expression? condition,
    Expression? updater, List<Statement> body,
    {bool forCollection = false}) {
  var location = computeLocation();
  return new For._(initializer, condition, updater,
      Block._(body, location: location), forCollection,
      location: location);
}

/// Creates a "for each" statement where the identifier being assigned to by the
/// iteration is not a local variable.
///
/// This models code like:
///     var x; // Top level variable
///     f(Iterable iterable) {
///       for (x in iterable) { ... }
///     }
Statement forEachWithNonVariable(Expression iterable, List<Statement> body) {
  var location = computeLocation();
  return new ForEach._(null, iterable, Block._(body, location: location), false,
      location: location);
}

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
  return new ForEach._(variable, iterable, block(body), true,
      location: computeLocation());
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
  var location = computeLocation();
  return new ForEach._(
      variable, iterable, Block._(body, location: location), false,
      location: location);
}

Statement if_(Expression condition, List<Statement> ifTrue,
    [List<Statement>? ifFalse]) {
  var location = computeLocation();
  return new If._(condition, Block._(ifTrue, location: location),
      ifFalse == null ? null : Block._(ifFalse, location: location),
      location: location);
}

Statement ifCase(Expression expression, PossiblyGuardedPattern pattern,
    List<Statement> ifTrue,
    [List<Statement>? ifFalse]) {
  var location = computeLocation();
  var guardedPattern = pattern._asGuardedPattern;
  return IfCase(
    expression,
    guardedPattern.pattern,
    guardedPattern.guard,
    Block._(ifTrue, location: location),
    ifFalse != null ? Block._(ifFalse, location: location) : null,
    location: location,
  );
}

CollectionElement ifCaseElement(
  Expression expression,
  PossiblyGuardedPattern pattern,
  CollectionElement ifTrue, [
  CollectionElement? ifFalse,
]) {
  var location = computeLocation();
  var guardedPattern = pattern._asGuardedPattern;
  return new IfCaseElement(
    expression,
    guardedPattern.pattern,
    guardedPattern.guard,
    ifTrue,
    ifFalse,
    location: location,
  );
}

CollectionElement ifElement(Expression condition, CollectionElement ifTrue,
    [CollectionElement? ifFalse]) {
  var location = computeLocation();
  return new IfElement._(condition, ifTrue, ifFalse, location: location);
}

Expression intLiteral(int value, {bool? expectConversionToDouble}) =>
    new IntLiteral(value,
        expectConversionToDouble: expectConversionToDouble,
        location: computeLocation());

Pattern listPattern(List<ListPatternElement> elements, {String? elementType}) =>
    ListPattern._(elementType == null ? null : Type(elementType), elements,
        location: computeLocation());

ListPatternElement listPatternRestElement([Pattern? pattern]) =>
    RestPatternElement._(pattern, location: computeLocation());

Statement localFunction(List<Statement> body) {
  var location = computeLocation();
  return LocalFunction._(Block._(body, location: location), location: location);
}

Pattern mapPattern(List<MapPatternElement> elements,
    {String? keyType, String? valueType}) {
  var location = computeLocation();
  return MapPattern._(
      keyType == null && valueType == null
          ? null
          : MapPatternTypeArguments(
              keyType: Type(keyType!), valueType: Type(valueType!)),
      elements,
      location: location);
}

MapPatternElement mapPatternEntry(Expression key, Pattern value) {
  return MapPatternEntry._(key, value, location: computeLocation());
}

MapPatternElement mapPatternRestElement([Pattern? pattern]) =>
    RestPatternElement._(pattern, location: computeLocation());

Pattern mapPatternWithTypeArguments({
  required String keyType,
  required String valueType,
  required List<MapPatternElement> elements,
}) {
  var location = computeLocation();
  return MapPattern._(
    shared.MapPatternTypeArguments<Type>(
      keyType: Type(keyType),
      valueType: Type(valueType),
    ),
    elements,
    location: location,
  );
}

Statement match(Pattern pattern, Expression initializer,
        {bool isLate = false, bool isFinal = false}) =>
    new Declare._(pattern, initializer,
        isLate: isLate, isFinal: isFinal, location: computeLocation());

Pattern objectPattern({
  required String requiredType,
  required List<RecordPatternField> fields,
}) {
  var parsedType = Type(requiredType);
  if (parsedType is! PrimaryType) {
    fail('Expected a primary type, got $parsedType');
  }
  return ObjectPattern._(
    requiredType: parsedType,
    fields: fields,
    location: computeLocation(),
  );
}

/// Creates a "pattern-for-in" statement.
///
/// This models code like:
///     void f(Iterable<(int, String)> iterable) {
///       for (var (a, b) in iterable) { ... }
///     }
Statement patternForIn(
  Pattern pattern,
  Expression expression,
  List<Statement> body, {
  bool hasAwait = false,
}) {
  var location = computeLocation();
  return new PatternForIn(
      pattern, expression, Block._(body, location: location),
      hasAwait: hasAwait, location: location);
}

/// Creates a "pattern-for-in" element.
///
/// This models code like:
///     void f(Iterable<(int, String)> iterable) {
///       [for (var (a, b) in iterable) '$a $b']
///     }
CollectionElement patternForInElement(
  Pattern pattern,
  Expression expression,
  CollectionElement body, {
  bool hasAwait = false,
}) {
  var location = computeLocation();
  return new PatternForInElement(pattern, expression, body,
      hasAwait: hasAwait, location: location);
}

Pattern recordPattern(List<RecordPatternField> fields) =>
    RecordPattern._(fields, location: computeLocation());

Pattern relationalPattern(String operator, Expression operand,
    {String? errorId}) {
  var result =
      RelationalPattern._(operator, operand, location: computeLocation());
  if (errorId != null) {
    result.errorId = errorId;
  }
  return result;
}

Statement return_() => new Return._(location: computeLocation());

PromotableLValue superProperty(String name) => new ThisOrSuperProperty._(name,
    location: computeLocation(), isSuperAccess: true);

Statement switch_(Expression expression, List<SwitchStatementMember> cases,
        {bool? isLegacyExhaustive,
        bool? expectHasDefault,
        bool? expectIsExhaustive,
        bool? expectLastCaseTerminates,
        bool? expectRequiresExhaustivenessValidation,
        String? expectScrutineeType}) =>
    new SwitchStatement(expression, cases, isLegacyExhaustive,
        location: computeLocation(),
        expectHasDefault: expectHasDefault,
        expectIsExhaustive: expectIsExhaustive,
        expectLastCaseTerminates: expectLastCaseTerminates,
        expectRequiresExhaustivenessValidation:
            expectRequiresExhaustivenessValidation,
        expectScrutineeType: expectScrutineeType);

Expression switchExpr(Expression expression, List<ExpressionCase> cases) =>
    new SwitchExpression._(expression, cases, location: computeLocation());

SwitchStatementMember switchStatementMember(
  List<SwitchHead> cases,
  List<Statement> body, {
  bool hasLabels = false,
}) {
  var location = computeLocation();
  return SwitchStatementMember._(
    cases,
    Block._(body, location: location),
    hasLabels: hasLabels,
    location: computeLocation(),
  );
}

PromotableLValue thisProperty(String name) => new ThisOrSuperProperty._(name,
    location: computeLocation(), isSuperAccess: false);

Expression throw_(Expression operand) =>
    new Throw._(operand, location: computeLocation());

TryBuilder try_(List<Statement> body) {
  var location = computeLocation();
  return new TryStatementImpl(Block._(body, location: location), [], null,
      location: location);
}

Statement while_(Expression condition, List<Statement> body) {
  var location = computeLocation();
  return new While._(condition, Block._(body, location: location),
      location: location);
}

Pattern wildcard({String? type, String? expectInferredType}) {
  return WildcardPattern._(
    declaredType: type == null ? null : Type(type),
    expectInferredType: expectInferredType,
    location: computeLocation(),
  );
}

typedef SharedMatchContext
    = shared.MatchContext<Node, Expression, Pattern, Type, Var>;

typedef SharedRecordPatternField = shared.RecordPatternField<Node, Pattern>;

class As extends Expression {
  final Expression target;
  final Type type;

  As._(this.target, this.type, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    target.preVisit(visitor);
  }

  @override
  String toString() => '$target as $type';

  @override
  ExpressionTypeAnalysisResult<Type> visit(Harness h, Type context) {
    return h.typeAnalyzer.analyzeTypeCast(this, target, type);
  }
}

class Assert extends Statement {
  final Expression condition;
  final Expression? message;

  Assert._(this.condition, this.message, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    condition.preVisit(visitor);
    message?.preVisit(visitor);
  }

  @override
  String toString() =>
      'assert($condition${message == null ? '' : ', $message'});';

  @override
  void visit(Harness h) {
    h.typeAnalyzer.analyzeAssertStatement(this, condition, message);
    h.irBuilder.apply(
        'assert', [Kind.expression, Kind.expression], Kind.statement,
        location: location);
  }
}

class Block extends Statement {
  final List<Statement> statements;

  Block._(this.statements, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    for (var statement in statements) {
      statement.preVisit(visitor);
    }
  }

  @override
  String toString() =>
      statements.isEmpty ? '{}' : '{ ${statements.join(' ')} }';

  @override
  void visit(Harness h) {
    h.typeAnalyzer.analyzeBlock(statements);
    h.irBuilder.apply(
        'block', List.filled(statements.length, Kind.statement), Kind.statement,
        location: location);
  }
}

class BooleanLiteral extends Expression {
  final bool value;

  BooleanLiteral._(this.value, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {}

  @override
  String toString() => '$value';

  @override
  ExpressionTypeAnalysisResult<Type> visit(Harness h, Type context) {
    var type = h.typeAnalyzer.analyzeBoolLiteral(this, value);
    h.irBuilder.atom('$value', Kind.expression, location: location);
    return new SimpleTypeAnalysisResult<Type>(type: type);
  }
}

/// Normal implementation of [Label].
class BoundLabel extends Label {
  final String name;

  Statement? _binding;

  BoundLabel._(this.name) : super._(location: computeLocation());

  @override
  Statement thenStmt(Statement statement) {
    if (statement is! LabeledStatement) {
      statement = LabeledStatement._(statement, location: computeLocation());
    }
    statement.labels.insert(0, this);
    _binding = statement;
    return statement;
  }

  @override
  String toString() => name;

  @override
  Statement? _getBinding() {
    var binding = _binding;
    if (binding == null) {
      fail("Unbound label $name");
    }
    return binding;
  }
}

class Break extends Statement {
  final Label? target;

  Break(this.target, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {}

  @override
  String toString() => 'break;';

  @override
  void visit(Harness h) {
    var target = this.target;
    h.typeAnalyzer.analyzeBreakStatement(target == null
        ? h.typeAnalyzer._currentBreakTarget
        : target._getBinding());
    h.irBuilder.apply('break', [], Kind.statement, location: location);
  }
}

class CastPattern extends Pattern {
  final Pattern inner;

  final Type type;

  CastPattern(this.inner, this.type, {required super.location}) : super._();

  @override
  Type computeSchema(Harness h) => h.typeAnalyzer.analyzeCastPatternSchema();

  @override
  void preVisit(PreVisitor visitor, VariableBinder<Node, Var> variableBinder,
      {required bool isInAssignment}) {
    inner.preVisit(visitor, variableBinder, isInAssignment: isInAssignment);
  }

  @override
  void visit(Harness h, SharedMatchContext context) {
    var matchedType = h.typeAnalyzer.flow.getMatchedValueType();
    h.typeAnalyzer.analyzeCastPattern(
      context: context,
      pattern: this,
      innerPattern: inner,
      requiredType: type,
    );
    h.irBuilder.atom(type.type, Kind.type, location: location);
    h.irBuilder.atom(matchedType.type, Kind.type, location: location);
    h.irBuilder.apply(
        'castPattern', [Kind.pattern, Kind.type, Kind.type], Kind.pattern,
        names: ['matchedType'], location: location);
  }

  @override
  String _debugString({required bool needsKeywordOrType}) =>
      '${inner._debugString(needsKeywordOrType: needsKeywordOrType)} as '
      '${type.type}';
}

/// Representation of a single catch clause in a try/catch statement.  Use
/// [catch_] to create instances of this class.
class CatchClause {
  final Statement body;
  final Var? exception;
  final Var? stackTrace;

  CatchClause._(this.body, this.exception, this.stackTrace);

  @override
  String toString() {
    String initialPart;
    if (stackTrace != null) {
      initialPart = 'catch (${exception!.name}, ${stackTrace!.name})';
    } else if (exception != null) {
      initialPart = 'catch (${exception!.name})';
    } else {
      initialPart = 'on ...';
    }
    return '$initialPart $body';
  }

  void _preVisit(PreVisitor visitor) {
    body.preVisit(visitor);
  }
}

class CheckAssigned extends Statement {
  final Var variable;
  final bool expectedAssignedState;

  CheckAssigned._(this.variable, this.expectedAssignedState,
      {required super.location});

  @override
  void preVisit(PreVisitor visitor) {}

  @override
  String toString() {
    var verb = expectedAssignedState ? 'is' : 'is not';
    return 'check $variable $verb definitely assigned;';
  }

  @override
  void visit(Harness h) {
    expect(h.flow.isAssigned(variable), expectedAssignedState,
        reason: 'at $location');
    h.irBuilder.atom('null', Kind.statement, location: location);
  }
}

class CheckCollectionElementIr extends CollectionElement {
  final CollectionElement inner;

  final String expectedIr;

  CheckCollectionElementIr._(this.inner, this.expectedIr,
      {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    inner.preVisit(visitor);
  }

  @override
  String toString() => '$inner (should produce IR $expectedIr)';

  @override
  void visit(Harness h, CollectionElementContext context) {
    h.typeAnalyzer.dispatchCollectionElement(inner, context);
    h.irBuilder.check(expectedIr, Kind.collectionElement, location: location);
  }
}

class CheckExpressionContext extends Expression {
  final Expression inner;

  final String expectedContext;

  CheckExpressionContext._(this.inner, this.expectedContext,
      {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    inner.preVisit(visitor);
  }

  @override
  String toString() => '$inner (should be in context $expectedContext)';

  @override
  ExpressionTypeAnalysisResult<Type> visit(Harness h, Type context) {
    expect(context.type, expectedContext);
    var result =
        h.typeAnalyzer.analyzeParenthesizedExpression(this, inner, context);
    return result;
  }
}

class CheckExpressionIr extends Expression {
  final Expression inner;

  final String expectedIr;

  CheckExpressionIr._(this.inner, this.expectedIr, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    inner.preVisit(visitor);
  }

  @override
  String toString() => '$inner (should produce IR $expectedIr)';

  @override
  ExpressionTypeAnalysisResult<Type> visit(Harness h, Type context) {
    var result =
        h.typeAnalyzer.analyzeParenthesizedExpression(this, inner, context);
    h.irBuilder.check(expectedIr, Kind.expression, location: location);
    return result;
  }
}

class CheckExpressionType extends Expression {
  final Expression target;
  final String expectedType;

  CheckExpressionType(this.target, this.expectedType,
      {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    target.preVisit(visitor);
  }

  @override
  String toString() => '$target (expected type: $expectedType)';

  @override
  ExpressionTypeAnalysisResult<Type> visit(Harness h, Type context) {
    var result =
        h.typeAnalyzer.analyzeParenthesizedExpression(this, target, context);
    expect(result.type.type, expectedType, reason: 'at $location');
    return result;
  }
}

class CheckPromoted extends Statement {
  final Promotable promotable;
  final String? expectedTypeStr;

  CheckPromoted._(this.promotable, this.expectedTypeStr,
      {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    promotable.preVisit(visitor);
  }

  @override
  String toString() {
    var predicate = expectedTypeStr == null
        ? 'not promoted'
        : 'promoted to $expectedTypeStr';
    return 'check $promotable $predicate;';
  }

  @override
  void visit(Harness h) {
    var promotedType = promotable._getPromotedType(h);
    expect(promotedType?.type, expectedTypeStr, reason: 'at $location');
    h.irBuilder
        .apply('stmt', [Kind.expression], Kind.statement, location: location);
  }
}

class CheckReachable extends Statement {
  final bool expectedReachable;

  CheckReachable(this.expectedReachable, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {}

  @override
  String toString() => 'check reachable;';

  @override
  void visit(Harness h) {
    expect(h.flow.isReachable, expectedReachable, reason: 'at $location');
    h.irBuilder.atom('null', Kind.statement, location: location);
  }
}

class CheckStatementIr extends Statement {
  final Statement inner;

  final String expectedIr;

  CheckStatementIr._(this.inner, this.expectedIr, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    inner.preVisit(visitor);
  }

  @override
  String toString() => '$inner (should produce IR $expectedIr)';

  @override
  void visit(Harness h) {
    h.typeAnalyzer.dispatchStatement(inner);
    h.irBuilder.check(expectedIr, Kind.statement, location: location);
  }
}

class CheckUnassigned extends Statement {
  final Var variable;
  final bool expectedUnassignedState;

  CheckUnassigned._(this.variable, this.expectedUnassignedState,
      {required super.location});

  @override
  void preVisit(PreVisitor visitor) {}

  @override
  String toString() {
    var verb = expectedUnassignedState ? 'is' : 'is not';
    return 'check $variable $verb definitely unassigned;';
  }

  @override
  void visit(Harness h) {
    expect(h.flow.isUnassigned(variable), expectedUnassignedState,
        reason: 'at $location');
    h.irBuilder.atom('null', Kind.statement, location: location);
  }
}

/// Representation of a collection element in the pseudo-Dart language used for
/// type analysis testing.
abstract class CollectionElement extends Node {
  CollectionElement({required super.location}) : super._();

  /// Wraps `this` in such a way that, when the test is run, it will verify that
  /// the IR produced matches [expectedIr].
  CollectionElement checkIr(String expectedIr) =>
      CheckCollectionElementIr._(this, expectedIr, location: computeLocation());

  /// Creates a [Statement] that, when analyzed, will analyze `this`, supplying
  /// [type] as the context (for `List` and `Set` literals).
  Statement inContextElementType(String type) =>
      CollectionElementInContext(this, CollectionElementContextType(type),
          location: computeLocation());

  /// Creates a [Statement] that, when analyzed, will analyze `this`, supplying
  /// [keyType] and [valueType] as the context (for `Map` literals).
  Statement inContextMapEntry(String keyType, String valueType) =>
      CollectionElementInContext(
          this, CollectionElementContextMapEntry._(keyType, valueType),
          location: computeLocation());

  void preVisit(PreVisitor visitor);

  void visit(Harness h, CollectionElementContext context);
}

abstract class CollectionElementContext {}

class CollectionElementContextMapEntry extends CollectionElementContext {
  final Type keyType;
  final Type valueType;

  CollectionElementContextMapEntry._(String keyType, String valueType)
      : keyType = Type(keyType),
        valueType = Type(valueType);
}

class CollectionElementContextType extends CollectionElementContext {
  final Type elementType;

  CollectionElementContextType(String type) : elementType = Type(type);
}

/// TODO(scheglov) This is a weird statement. We need `ListLiteral`, etc.
class CollectionElementInContext extends Statement {
  final CollectionElement element;

  final CollectionElementContext context;

  CollectionElementInContext(this.element, this.context,
      {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    element.preVisit(visitor);
  }

  @override
  String toString() => '$element (in context $context);';

  @override
  void visit(Harness h) {
    h.typeAnalyzer.dispatchCollectionElement(element, context);
    h.irBuilder.apply('stmt', [Kind.collectionElement], Kind.statement,
        location: location);
  }
}

class Conditional extends Expression {
  final Expression condition;
  final Expression ifTrue;
  final Expression ifFalse;

  Conditional._(this.condition, this.ifTrue, this.ifFalse,
      {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    condition.preVisit(visitor);
    visitor._assignedVariables.beginNode();
    ifTrue.preVisit(visitor);
    visitor._assignedVariables.endNode(this);
    ifFalse.preVisit(visitor);
  }

  @override
  String toString() => '$condition ? $ifTrue : $ifFalse';

  @override
  ExpressionTypeAnalysisResult<Type> visit(Harness h, Type context) {
    var result = h.typeAnalyzer
        .analyzeConditionalExpression(this, condition, ifTrue, ifFalse);
    h.irBuilder.apply('if', [Kind.expression, Kind.expression, Kind.expression],
        Kind.expression,
        location: location);
    return result;
  }
}

class ConstantPattern extends Pattern {
  final Expression constant;

  ConstantPattern(this.constant, {required super.location}) : super._();

  @override
  Type computeSchema(Harness h) =>
      h.typeAnalyzer.analyzeConstantPatternSchema();

  @override
  void preVisit(PreVisitor visitor, VariableBinder<Node, Var> variableBinder,
      {required bool isInAssignment}) {
    constant.preVisit(visitor);
  }

  @override
  void visit(Harness h, SharedMatchContext context) {
    var matchedType = h.typeAnalyzer.flow.getMatchedValueType();
    h.typeAnalyzer.analyzeConstantPattern(context, this, constant);
    h.irBuilder.atom(matchedType.type, Kind.type, location: location);
    h.irBuilder.apply('const', [Kind.expression, Kind.type], Kind.pattern,
        names: ['matchedType'], location: location);
  }

  @override
  _debugString({required bool needsKeywordOrType}) => constant.toString();
}

class Continue extends Statement {
  final Label? target;

  Continue._(this.target, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {}

  @override
  String toString() => 'continue;';

  @override
  void visit(Harness h) {
    var target = this.target;
    h.typeAnalyzer.analyzeContinueStatement(target == null
        ? h.typeAnalyzer._currentContinueTarget
        : target._getBinding());
    h.irBuilder.apply('continue', [], Kind.statement, location: location);
  }
}

class Declare extends Statement {
  final bool isLate;
  final bool isFinal;
  final Pattern pattern;
  final Expression? initializer;

  Declare._(this.pattern, this.initializer,
      {required this.isLate, required this.isFinal, required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    var variableBinder = _VariableBinder(errors: visitor.errors);
    variableBinder.casePatternStart();
    pattern.preVisit(visitor, variableBinder, isInAssignment: false);
    variableBinder.casePatternFinish();
    variableBinder.finish();
    if (isLate) {
      visitor._assignedVariables.beginNode();
    }
    initializer?.preVisit(visitor);
    if (isLate) {
      visitor._assignedVariables.endNode(this);
    }
  }

  @override
  String toString() {
    var parts = <String>[
      if (isLate) 'late',
      if (isFinal) 'final',
      pattern._debugString(needsKeywordOrType: !isFinal),
      if (initializer != null) '= $initializer'
    ];
    return '${parts.join(' ')};';
  }

  @override
  void visit(Harness h) {
    String irName;
    List<Kind> argKinds;
    List<String> names = const [];
    var initializer = this.initializer;
    if (isLate) {
      // Late declarations are not allowed using patterns, so interpret the
      // declaration as an old-fashioned variable declaration.
      var pattern = this.pattern as VariablePattern;
      var variable = pattern.variable;
      h.irBuilder.atom(variable.name, Kind.variable, location: location);
      var declaredType = pattern.declaredType;
      Type staticType;
      if (initializer == null) {
        // Use the shared logic for analyzing uninitialized variable
        // declarations.
        staticType = h.typeAnalyzer.analyzeUninitializedVariableDeclaration(
            this, pattern.variable, pattern.declaredType,
            isFinal: isFinal);
        irName = 'declare';
        argKinds = [Kind.variable];
      } else {
        // There's no shared logic for analyzing initialized late variable
        // declarations, so analyze the declaration directly.
        h.flow.lateInitializer_begin(this);
        var initializerType =
            h.typeAnalyzer.analyzeExpression(initializer, declaredType);
        h.flow.lateInitializer_end();
        staticType = variable.type = declaredType ?? initializerType;
        h.flow.declare(variable, staticType, initialized: true);
        h.flow.initialize(variable, initializerType, initializer,
            isFinal: isFinal,
            isLate: true,
            isImplicitlyTyped: declaredType == null);
        h.irBuilder.atom(initializerType.type, Kind.type, location: location);
        h.irBuilder.atom(staticType.type, Kind.type, location: location);
        irName = 'declare';
        argKinds = [Kind.variable, Kind.expression, Kind.type, Kind.type];
        names = (['initializerType', 'staticType']);
      }
      // Finally, double check the inferred variable type, if necessary for the
      // test.
      var expectInferredType = pattern.expectInferredType;
      if (expectInferredType != null) {
        expect(staticType, expectInferredType);
      }
    } else if (initializer == null) {
      var pattern = this.pattern as VariablePattern;
      var staticType = h.typeAnalyzer.analyzeUninitializedVariableDeclaration(
          this, pattern.variable, pattern.declaredType,
          isFinal: isFinal);
      h.typeAnalyzer.handleDeclaredVariablePattern(pattern,
          matchedType: staticType, staticType: staticType);
      irName = 'declare';
      argKinds = [Kind.pattern];
    } else {
      h.typeAnalyzer.analyzePatternVariableDeclaration(
          this, pattern, initializer,
          isFinal: isFinal);
      irName = 'match';
      argKinds = [Kind.expression, Kind.pattern];
    }
    h.irBuilder.apply(
        [irName, if (isLate) 'late', if (isFinal) 'final'].join('_'),
        argKinds,
        Kind.statement,
        location: location,
        names: names);
  }
}

class Do extends Statement {
  final Statement body;
  final Expression condition;

  Do._(this.body, this.condition, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    visitor._assignedVariables.beginNode();
    body.preVisit(visitor);
    condition.preVisit(visitor);
    visitor._assignedVariables.endNode(this);
  }

  @override
  String toString() => 'do $body while ($condition);';

  @override
  void visit(Harness h) {
    h.typeAnalyzer.analyzeDoLoop(this, body, condition);
    h.irBuilder.apply('do', [Kind.statement, Kind.expression], Kind.statement,
        location: location);
  }
}

class Equal extends Expression {
  final Expression lhs;
  final Expression rhs;
  final bool isInverted;

  Equal._(this.lhs, this.rhs, this.isInverted, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    lhs.preVisit(visitor);
    rhs.preVisit(visitor);
  }

  @override
  String toString() => '$lhs ${isInverted ? '!=' : '=='} $rhs';

  @override
  ExpressionTypeAnalysisResult<Type> visit(Harness h, Type context) {
    var operatorName = isInverted ? '!=' : '==';
    var result =
        h.typeAnalyzer.analyzeBinaryExpression(this, lhs, operatorName, rhs);
    h.irBuilder.apply(
        operatorName, [Kind.expression, Kind.expression], Kind.expression,
        location: location);
    return result;
  }
}

/// Representation of an expression in the pseudo-Dart language used for flow
/// analysis testing.  Methods in this class may be used to create more complex
/// expressions based on this one.
abstract class Expression extends Node {
  Expression({required super.location}) : super._();

  /// Creates a [CollectionElement] that, when analyzed, will analyze `this`.
  CollectionElement get asCollectionElement =>
      ExpressionCollectionElement(this, location: computeLocation());

  /// If `this` is an expression `x`, creates the expression `x!`.
  Expression get nonNullAssert =>
      new NonNullAssert._(this, location: computeLocation());

  /// If `this` is an expression `x`, creates the expression `!x`.
  Expression get not => new Not._(this, location: computeLocation());

  /// If `this` is an expression `x`, creates the expression `(x)`.
  Expression get parenthesized =>
      new ParenthesizedExpression._(this, location: computeLocation());

  Pattern get pattern => ConstantPattern(this, location: computeLocation());

  /// If `this` is an expression `x`, creates the statement `x;`.
  Statement get stmt =>
      new ExpressionStatement._(this, location: computeLocation());

  /// If `this` is an expression `x`, creates the expression `x && other`.
  Expression and(Expression other) =>
      new Logical._(this, other, isAnd: true, location: computeLocation());

  /// If `this` is an expression `x`, creates the expression `x as typeStr`.
  Expression as_(String typeStr) =>
      new As._(this, Type(typeStr), location: computeLocation());

  /// Wraps `this` in such a way that, when the test is run, it will verify that
  /// the context provided when analyzing the expression matches
  /// [expectedContext].
  Expression checkContext(String expectedContext) =>
      CheckExpressionContext._(this, expectedContext,
          location: computeLocation());

  /// Wraps `this` in such a way that, when the test is run, it will verify that
  /// the IR produced matches [expectedIr].
  Expression checkIr(String expectedIr) =>
      CheckExpressionIr._(this, expectedIr, location: computeLocation());

  /// Creates an [Expression] that, when analyzed, will behave the same as
  /// `this`, but after visiting it, will verify that the type of the expression
  /// was [expectedType].
  Expression checkType(String expectedType) =>
      new CheckExpressionType(this, expectedType, location: computeLocation());

  /// If `this` is an expression `x`, creates the expression
  /// `x ? ifTrue : ifFalse`.
  Expression conditional(Expression ifTrue, Expression ifFalse) =>
      new Conditional._(this, ifTrue, ifFalse, location: computeLocation());

  /// If `this` is an expression `x`, creates the expression `x == other`.
  Expression eq(Expression other) =>
      new Equal._(this, other, false, location: computeLocation());

  /// If `this` is an expression `x`, creates the expression `x ?? other`.
  Expression ifNull(Expression other) =>
      new IfNull._(this, other, location: computeLocation());

  /// Creates a [Statement] that, when analyzed, will analyze `this`, supplying
  /// a context type of [context].
  Statement inContext(String context) =>
      ExpressionInContext._(this, Type(context), location: computeLocation());

  /// If `this` is an expression `x`, creates the expression `x is typeStr`.
  ///
  /// With [isInverted] set to `true`, creates the expression `x is! typeStr`.
  Expression is_(String typeStr, {bool isInverted = false}) =>
      new Is._(this, Type(typeStr), isInverted, location: computeLocation());

  /// If `this` is an expression `x`, creates the expression `x is! typeStr`.
  Expression isNot(String typeStr) =>
      Is._(this, Type(typeStr), true, location: computeLocation());

  /// If `this` is an expression `x`, creates the expression `x != other`.
  Expression notEq(Expression other) =>
      Equal._(this, other, true, location: computeLocation());

  /// If `this` is an expression `x`, creates the expression `x?.other`.
  ///
  /// Note that in the real Dart language, the RHS of a null aware access isn't
  /// strictly speaking an expression.  However for flow analysis it suffices to
  /// model it as an expression.
  Expression nullAwareAccess(Expression other, {bool isCascaded = false}) =>
      NullAwareAccess._(this, other, isCascaded, location: computeLocation());

  /// If `this` is an expression `x`, creates the expression `x || other`.
  Expression or(Expression other) =>
      new Logical._(this, other, isAnd: false, location: computeLocation());

  void preVisit(PreVisitor visitor);

  /// If `this` is an expression `x`, creates the L-value `x.name`.
  PromotableLValue property(String name) =>
      new Property._(this, name, location: computeLocation());

  /// If `this` is an expression `x`, creates a pseudo-expression that models
  /// evaluation of `x` followed by execution of [stmt].  This can be used to
  /// test that flow analysis is in the correct state after an expression is
  /// visited.
  Expression thenStmt(Statement stmt) =>
      new WrappedExpression._(null, this, stmt, location: computeLocation());

  ExpressionTypeAnalysisResult<Type> visit(Harness h, Type context);
}

/// Representation of a single case clause in a switch expression.  Use
/// [caseExpr] to create instances of this class.
class ExpressionCase extends Node {
  final GuardedPattern? guardedPattern;
  final Expression expression;

  ExpressionCase._(this.guardedPattern, this.expression,
      {required super.location})
      : super._();

  @override
  String toString() => [
        guardedPattern == null ? 'default' : 'case $guardedPattern',
        ': $expression'
      ].join('');

  void _preVisit(PreVisitor visitor) {
    final guardedPattern = this.guardedPattern;
    if (guardedPattern != null) {
      var variableBinder = _VariableBinder(errors: visitor.errors);
      variableBinder.casePatternStart();
      guardedPattern.pattern
          .preVisit(visitor, variableBinder, isInAssignment: false);
      guardedPattern.variables = variableBinder.casePatternFinish();
      variableBinder.finish();
    }
    expression.preVisit(visitor);
  }
}

class ExpressionCollectionElement extends CollectionElement {
  final Expression expression;

  ExpressionCollectionElement(this.expression, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    expression.preVisit(visitor);
  }

  @override
  String toString() => '$expression;';

  @override
  void visit(Harness h, CollectionElementContext context) {
    Type contextType = context is CollectionElementContextType
        ? context.elementType
        : h.typeAnalyzer.unknownType;
    h.typeAnalyzer.dispatchExpression(expression, contextType);
    h.irBuilder.apply('celt', [Kind.expression], Kind.collectionElement,
        location: location);
  }
}

class ExpressionInContext extends Statement {
  final Expression expr;

  final Type context;

  ExpressionInContext._(this.expr, this.context, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    expr.preVisit(visitor);
  }

  @override
  String toString() => '$expr (in context $context);';

  @override
  void visit(Harness h) {
    h.typeAnalyzer.analyzeExpression(expr, context);
    h.irBuilder
        .apply('stmt', [Kind.expression], Kind.statement, location: location);
  }
}

class ExpressionStatement extends Statement {
  final Expression expr;

  ExpressionStatement._(this.expr, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    expr.preVisit(visitor);
  }

  @override
  String toString() => '$expr;';

  @override
  void visit(Harness h) {
    h.typeAnalyzer.analyzeExpressionStatement(expr);
    h.irBuilder
        .apply('stmt', [Kind.expression], Kind.statement, location: location);
  }
}

class For extends Statement {
  final Statement? initializer;
  final Expression? condition;
  final Expression? updater;
  final Statement body;
  final bool forCollection;

  For._(this.initializer, this.condition, this.updater, this.body,
      this.forCollection,
      {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    initializer?.preVisit(visitor);
    visitor._assignedVariables.beginNode();
    condition?.preVisit(visitor);
    body.preVisit(visitor);
    updater?.preVisit(visitor);
    visitor._assignedVariables.endNode(this);
  }

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
    buffer.write(') $body');
    return buffer.toString();
  }

  @override
  void visit(Harness h) {
    if (initializer != null) {
      h.typeAnalyzer.dispatchStatement(initializer!);
    } else {
      h.typeAnalyzer.handleNoInitializer(this);
    }
    h.flow.for_conditionBegin(this);
    if (condition != null) {
      h.typeAnalyzer.analyzeExpression(condition!, h.typeAnalyzer.unknownType);
    } else {
      h.typeAnalyzer.handleNoCondition(this);
    }
    h.flow.for_bodyBegin(forCollection ? null : this, condition);
    h.typeAnalyzer._visitLoopBody(this, body);
    h.flow.for_updaterBegin();
    if (updater != null) {
      h.typeAnalyzer.analyzeExpression(updater!, h.typeAnalyzer.unknownType);
    } else {
      h.typeAnalyzer.handleNoCondition(this);
    }
    h.flow.for_end();
    h.irBuilder.apply(
        'for',
        [Kind.statement, Kind.expression, Kind.statement, Kind.expression],
        Kind.statement,
        location: location);
  }
}

class ForEach extends Statement {
  final Var? variable;
  final Expression iterable;
  final Statement body;
  final bool declaresVariable;

  ForEach._(this.variable, this.iterable, this.body, this.declaresVariable,
      {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    iterable.preVisit(visitor);
    if (variable != null) {
      if (declaresVariable) {
        visitor._assignedVariables.declare(variable!);
      } else {
        visitor._assignedVariables.write(variable!);
      }
    }
    visitor._assignedVariables.beginNode();
    body.preVisit(visitor);
    visitor._assignedVariables.endNode(this);
  }

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
    return 'for ($declarationPart in $iterable) $body';
  }

  @override
  void visit(Harness h) {
    var iteratedType = h._getIteratedType(
        h.typeAnalyzer.analyzeExpression(iterable, h.typeAnalyzer.unknownType));
    h.flow.forEach_bodyBegin(this);
    var variable = this.variable;
    if (variable != null && !declaresVariable) {
      h.flow.write(this, variable, iteratedType, null);
    }
    h.typeAnalyzer._visitLoopBody(this, body);
    h.flow.forEach_end();
    h.irBuilder.apply(
        'forEach', [Kind.expression, Kind.statement], Kind.statement,
        location: location);
  }
}

class GuardedPattern extends Node with PossiblyGuardedPattern {
  final Pattern pattern;
  late final Map<String, Var> variables;
  final Expression? guard;

  GuardedPattern._({
    required this.pattern,
    required this.guard,
    required super.location,
  }) : super._();

  @override
  GuardedPattern get _asGuardedPattern => this;
}

class Harness {
  static Map<String, Type> _coreMemberTypes = {
    'int.>': Type('bool Function(num)'),
    'int.>=': Type('bool Function(num)'),
    'num.sign': Type('num'),
  };

  final MiniAstOperations _operations = MiniAstOperations();

  bool _started = false;

  late final FlowAnalysis<Node, Statement, Expression, Var, Type> flow;

  bool? _patternsEnabled;

  Type? _thisType;

  late final Map<String, _PropertyElement?> _members = {
    for (var entry in _coreMemberTypes.entries)
      entry.key: _PropertyElement(entry.value)
  };

  late final typeAnalyzer = _MiniAstTypeAnalyzer(
      this,
      TypeAnalyzerOptions(
          nullSafetyEnabled: !_operations.legacy,
          patternsEnabled: patternsEnabled));

  /// Indicates whether initializers of implicitly typed variables should be
  /// accounted for by SSA analysis.  (In an ideal world, they always would be,
  /// but due to https://github.com/dart-lang/language/issues/1785, they weren't
  /// always, and we need to be able to replicate the old behavior when
  /// analyzing old language versions).
  bool _respectImplicitlyTypedVarInitializers = true;

  MiniIrBuilder get irBuilder => typeAnalyzer._irBuilder;

  set legacy(bool value) {
    assert(!_started);
    _operations.legacy = value;
  }

  bool get patternsEnabled => _patternsEnabled ?? !_operations.legacy;

  set patternsEnabled(bool value) {
    assert(!_started);
    _patternsEnabled = value;
  }

  set respectImplicitlyTypedVarInitializers(bool value) {
    assert(!_started);
    _respectImplicitlyTypedVarInitializers = value;
  }

  set thisType(String type) {
    assert(!_started);
    _thisType = Type(type);
  }

  /// Updates the harness with a new result for [downwardInfer].
  void addDownwardInfer({
    required String name,
    required String context,
    required String result,
  }) {
    _operations.addDownwardInfer(
      name: name,
      context: context,
      result: result,
    );
  }

  /// Updates the harness so that when an [isAlwaysExhaustiveType] query is
  /// invoked on type [type], [isExhaustive] will be returned.
  void addExhaustiveness(String type, bool isExhaustive) {
    _operations.addExhaustiveness(type, isExhaustive);
  }

  /// Updates the harness so that when member [memberName] is looked up on type
  /// [targetType], a member is found having the given [type].
  ///
  /// If [type] is `null`, then an attempt to look up [memberName] on type
  /// [targetType] should result in `null` (no such member) rather than a test
  /// failure.
  void addMember(String targetType, String memberName, String? type,
      {bool promotable = false}) {
    var query = '$targetType.$memberName';
    if (type == null) {
      if (promotable) {
        fail("It doesn't make sense to specify `promotable: true` "
            "when the type is `null`");
      }
      _members[query] = null;
      return;
    }
    var member = _PropertyElement(Type(type));
    _members[query] = member;
    if (promotable) {
      _operations.promotableFields.add(member);
    }
  }

  void addPromotionException(String from, String to, String result) {
    _operations.addPromotionException(from, to, result);
  }

  void addSuperInterfaces(
      String className, List<Type> Function(List<Type>) template) {
    _operations.addSuperInterfaces(className, template);
  }

  void addTypeVariable(String name, {String? bound}) {
    _operations.addTypeVariable(name, bound: bound);
  }

  /// Attempts to look up a member named [memberName] in the given [type].  If
  /// a member is found, returns its [_PropertyElement] object; otherwise `null`
  /// is returned.
  ///
  /// If test hasn't been configured in such a way that the result of the query
  /// is known, the test fails.
  _PropertyElement? getMember(Type type, String memberName) {
    var query = '$type.$memberName';
    var member = _members[query];
    if (member == null && !_members.containsKey(query)) {
      fail('Unknown member query: $query');
    }
    return member;
  }

  /// See [TypeAnalyzer.resolveRelationalPatternOperator].
  RelationalOperatorResolution<Type>? resolveRelationalPatternOperator(
      Type matchedValueType, String operator) {
    if (operator == '==' || operator == '!=') {
      return RelationalOperatorResolution(
          kind: operator == '=='
              ? RelationalOperatorKind.equals
              : RelationalOperatorKind.notEquals,
          parameterType: Type('Object'),
          returnType: Type('bool'));
    }
    var member = getMember(matchedValueType, operator);
    if (member == null) return null;
    var memberType = member._type;
    if (memberType is! FunctionType) {
      fail('$matchedValueType.operator$operator has type $memberType; '
          'must be a function type');
    }
    if (memberType.positionalParameters.isEmpty) {
      fail('$matchedValueType.operator$operator has type $memberType; '
          'must accept a parameter');
    }
    return RelationalOperatorResolution(
        kind: RelationalOperatorKind.other,
        parameterType: memberType.positionalParameters[0],
        returnType: memberType.returnType);
  }

  /// Runs the given [statements] through flow analysis, checking any assertions
  /// they contain.
  void run(List<Statement> statements,
      {bool errorRecoveryOk = false, Set<String> expectedErrors = const {}}) {
    try {
      _started = true;
      if (_operations.legacy && patternsEnabled) {
        fail('Patterns cannot be enabled in legacy mode');
      }
      var visitor = PreVisitor(typeAnalyzer.errors);
      var b = Block._(statements, location: computeLocation());
      b.preVisit(visitor);
      flow = _operations.legacy
          ? FlowAnalysis<Node, Statement, Expression, Var, Type>.legacy(
              _operations, visitor._assignedVariables)
          : FlowAnalysis<Node, Statement, Expression, Var, Type>(
              _operations, visitor._assignedVariables,
              respectImplicitlyTypedVarInitializers:
                  _respectImplicitlyTypedVarInitializers);
      typeAnalyzer.dispatchStatement(b);
      typeAnalyzer.finish();
      expect(typeAnalyzer.errors._accumulatedErrors, expectedErrors);
      var assertInErrorRecoveryStack =
          typeAnalyzer.errors._assertInErrorRecoveryStack;
      if (!errorRecoveryOk && assertInErrorRecoveryStack != null) {
        fail('assertInErrorRecovery called but no errors reported: '
            '$assertInErrorRecoveryStack');
      }
      if (Node._nodesWithUnusedErrorIds.isNotEmpty) {
        var ids = [
          for (var node in Node._nodesWithUnusedErrorIds) node._errorId
        ].join(', ');
        fail('Unused error ids: $ids');
      }
    } finally {
      Node._nodesWithUnusedErrorIds.clear();
    }
  }

  Type _getIteratedType(Type iterableType) {
    var typeStr = iterableType.type;
    if (typeStr.startsWith('List<') && typeStr.endsWith('>')) {
      return Type(typeStr.substring(5, typeStr.length - 1));
    } else {
      throw UnimplementedError('TODO(paulberry): getIteratedType($typeStr)');
    }
  }
}

class If extends IfBase {
  final Expression condition;

  If._(this.condition, super.ifTrue, super.ifFalse, {required super.location})
      : super._();

  @override
  String get _conditionPartString => condition.toString();

  @override
  void preVisit(PreVisitor visitor) {
    condition.preVisit(visitor);
    super.preVisit(visitor);
  }

  @override
  void visit(Harness h) {
    h.typeAnalyzer.analyzeIfStatement(this, condition, ifTrue, ifFalse);
    h.irBuilder.apply(
        'if', [Kind.expression, Kind.statement, Kind.statement], Kind.statement,
        location: location);
  }
}

abstract class IfBase extends Statement {
  final Statement ifTrue;
  final Statement? ifFalse;

  IfBase._(this.ifTrue, this.ifFalse, {required super.location});

  String get _conditionPartString;

  @override
  void preVisit(PreVisitor visitor) {
    visitor._assignedVariables.beginNode();
    ifTrue.preVisit(visitor);
    visitor._assignedVariables.endNode(this);
    ifFalse?.preVisit(visitor);
  }

  @override
  String toString() =>
      'if ($_conditionPartString) $ifTrue' +
      (ifFalse == null ? '' : 'else $ifFalse');
}

class IfCase extends IfBase {
  final Expression expression;
  final Pattern pattern;
  final Expression? guard;

  /// These variables are set during pre-visit, and some of them are joins of
  /// pattern variable declarations. We don't know their types until we do
  /// type analysis. So, some of these variables might become unavailable.
  late final Map<String, Var> _candidateVariables;

  IfCase(this.expression, this.pattern, this.guard, super.ifTrue, super.ifFalse,
      {required super.location})
      : super._();

  @override
  String get _conditionPartString => '$expression case $pattern';

  @override
  void preVisit(PreVisitor visitor) {
    expression.preVisit(visitor);
    var variableBinder = _VariableBinder(errors: visitor.errors);
    variableBinder.casePatternStart();
    pattern.preVisit(visitor, variableBinder, isInAssignment: false);
    _candidateVariables = variableBinder.casePatternFinish();
    variableBinder.finish();
    guard?.preVisit(visitor);
    super.preVisit(visitor);
  }

  @override
  void visit(Harness h) {
    h.typeAnalyzer.analyzeIfCaseStatement(
        this, expression, pattern, guard, ifTrue, ifFalse, _candidateVariables);
    h.irBuilder.apply(
      'ifCase',
      [
        Kind.expression,
        Kind.pattern,
        Kind.variables,
        Kind.expression,
        Kind.statement,
        Kind.statement,
      ],
      Kind.statement,
      location: location,
    );
  }
}

class IfCaseElement extends IfElementBase {
  final Expression expression;
  final Pattern pattern;
  final Expression? guard;
  late final Map<String, Var> _variables;

  IfCaseElement(
      this.expression, this.pattern, this.guard, super.ifTrue, super.ifFalse,
      {required super.location})
      : super._();

  @override
  String get _conditionPartString => '$expression case $pattern';

  @override
  void preVisit(PreVisitor visitor) {
    expression.preVisit(visitor);
    var variableBinder = _VariableBinder(errors: visitor.errors);
    variableBinder.casePatternStart();
    pattern.preVisit(visitor, variableBinder, isInAssignment: false);
    _variables = variableBinder.casePatternFinish();
    variableBinder.finish();
    guard?.preVisit(visitor);
    super.preVisit(visitor);
  }

  @override
  void visit(Harness h, Object context) {
    h.typeAnalyzer.analyzeIfCaseElement(
      node: this,
      expression: expression,
      pattern: pattern,
      variables: _variables,
      guard: guard,
      ifTrue: ifTrue,
      ifFalse: ifFalse,
      context: context,
    );
    h.irBuilder.apply(
      'if',
      [
        Kind.expression,
        Kind.pattern,
        Kind.expression,
        Kind.collectionElement,
        Kind.collectionElement,
      ],
      Kind.collectionElement,
      names: ['expression', 'pattern', 'guard', 'ifTrue', 'ifFalse'],
      location: location,
    );
  }
}

class IfElement extends IfElementBase {
  final Expression condition;

  IfElement._(this.condition, super.ifTrue, super.ifFalse,
      {required super.location})
      : super._();

  @override
  String get _conditionPartString => condition.toString();

  @override
  void preVisit(PreVisitor visitor) {
    condition.preVisit(visitor);
    super.preVisit(visitor);
  }

  @override
  void visit(Harness h, Object context) {
    h.typeAnalyzer.analyzeIfElement(
      node: this,
      condition: condition,
      ifTrue: ifTrue,
      ifFalse: ifFalse,
      context: context,
    );
    h.irBuilder.apply(
      'if',
      [Kind.expression, Kind.collectionElement, Kind.collectionElement],
      Kind.collectionElement,
      location: location,
    );
  }
}

abstract class IfElementBase extends CollectionElement {
  final CollectionElement ifTrue;
  final CollectionElement? ifFalse;

  IfElementBase._(this.ifTrue, this.ifFalse, {required super.location});

  String get _conditionPartString;

  @override
  void preVisit(PreVisitor visitor) {
    visitor._assignedVariables.beginNode();
    ifTrue.preVisit(visitor);
    visitor._assignedVariables.endNode(this);
    ifFalse?.preVisit(visitor);
  }

  @override
  String toString() =>
      'if ($_conditionPartString) $ifTrue' +
      (ifFalse == null ? '' : 'else $ifFalse');
}

class IfNull extends Expression {
  final Expression lhs;
  final Expression rhs;

  IfNull._(this.lhs, this.rhs, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    lhs.preVisit(visitor);
    rhs.preVisit(visitor);
  }

  @override
  String toString() => '$lhs ?? $rhs';

  @override
  ExpressionTypeAnalysisResult<Type> visit(Harness h, Type context) {
    var result = h.typeAnalyzer.analyzeIfNullExpression(this, lhs, rhs);
    h.irBuilder.apply(
        'ifNull', [Kind.expression, Kind.expression], Kind.expression,
        location: location);
    return result;
  }
}

class IntLiteral extends Expression {
  final int value;

  /// `true` or `false` if we should assert that int->double conversion either
  /// does, or does not, happen.  `null` if no assertion should be done.
  final bool? expectConversionToDouble;

  IntLiteral(this.value,
      {this.expectConversionToDouble, required super.location});

  @override
  void preVisit(PreVisitor visitor) {}

  @override
  String toString() => '$value';

  @override
  ExpressionTypeAnalysisResult<Type> visit(Harness h, Type context) {
    var result = h.typeAnalyzer.analyzeIntLiteral(context);
    if (expectConversionToDouble != null) {
      expect(result.convertedToDouble, expectConversionToDouble);
    }
    h.irBuilder.atom(
        result.convertedToDouble ? '${value.toDouble()}f' : '$value',
        Kind.expression,
        location: location);
    return result;
  }
}

class Is extends Expression {
  final Expression target;
  final Type type;
  final bool isInverted;

  Is._(this.target, this.type, this.isInverted, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    target.preVisit(visitor);
  }

  @override
  String toString() => '$target is${isInverted ? '!' : ''} $type';

  @override
  ExpressionTypeAnalysisResult<Type> visit(Harness h, Type context) {
    return h.typeAnalyzer
        .analyzeTypeTest(this, target, type, isInverted: isInverted);
  }
}

abstract class Label extends Node {
  factory Label(String name) = BoundLabel._;

  factory Label.unbound() = UnboundLabel._;

  Label._({required super.location}) : super._();

  Statement thenStmt(Statement statement);

  /// Returns the statement this label has been bound to, or `null` for labels
  /// constructed with [Label.unbound].
  Statement? _getBinding();
}

class LabeledStatement extends Statement {
  final List<Label> labels = [];

  final Statement body;

  LabeledStatement._(this.body, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    body.preVisit(visitor);
  }

  @override
  String toString() => [...labels, body].join(': ');

  @override
  void visit(Harness h) {
    h.typeAnalyzer.analyzeLabeledStatement(this, body);
  }
}

abstract class ListOrMapPatternElement implements Node {
  ListOrMapPatternElement._();

  void preVisit(PreVisitor visitor, VariableBinder<Node, Var> variableBinder,
      {required bool isInAssignment});

  String _debugString({required bool needsKeywordOrType});
}

class ListPattern extends Pattern {
  final Type? elementType;

  final List<ListPatternElement> elements;

  ListPattern._(this.elementType, this.elements, {required super.location})
      : super._();

  @override
  Type computeSchema(Harness h) => h.typeAnalyzer
      .analyzeListPatternSchema(elementType: elementType, elements: elements);

  @override
  void preVisit(PreVisitor visitor, VariableBinder<Node, Var> variableBinder,
      {required bool isInAssignment}) {
    for (var element in elements) {
      element.preVisit(visitor, variableBinder, isInAssignment: isInAssignment);
    }
  }

  @override
  void visit(Harness h, SharedMatchContext context) {
    var matchedType = h.typeAnalyzer.flow.getMatchedValueType();
    var listPatternResult = h.typeAnalyzer.analyzeListPattern(context, this,
        elementType: elementType, elements: elements);
    var requiredType = listPatternResult.requiredType;
    h.irBuilder.atom(matchedType.type, Kind.type, location: location);
    h.irBuilder.atom(requiredType.type, Kind.type, location: location);
    h.irBuilder.apply(
        'listPattern',
        [...List.filled(elements.length, Kind.pattern), Kind.type, Kind.type],
        Kind.pattern,
        names: ['matchedType', 'requiredType'],
        location: location);
  }

  @override
  String _debugString({required bool needsKeywordOrType}) {
    var elements = [
      for (var element in this.elements)
        element._debugString(needsKeywordOrType: needsKeywordOrType)
    ];
    return '[${elements.join(', ')}]';
  }
}

abstract class ListPatternElement implements ListOrMapPatternElement {}

class LocalFunction extends Statement {
  final Statement body;

  LocalFunction._(this.body, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    visitor._assignedVariables.beginNode();
    body.preVisit(visitor);
    visitor._assignedVariables
        .endNode(this, isClosureOrLateVariableInitializer: true);
  }

  @override
  String toString() => '() $body';

  @override
  void visit(Harness h) {
    h.flow.functionExpression_begin(this);
    h.typeAnalyzer.dispatchStatement(body);
    h.flow.functionExpression_end();
  }
}

class Logical extends Expression {
  final Expression lhs;
  final Expression rhs;
  final bool isAnd;

  Logical._(this.lhs, this.rhs, {required this.isAnd, required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    lhs.preVisit(visitor);
    visitor._assignedVariables.beginNode();
    rhs.preVisit(visitor);
    visitor._assignedVariables.endNode(this);
  }

  @override
  String toString() => '$lhs ${isAnd ? '&&' : '||'} $rhs';

  @override
  ExpressionTypeAnalysisResult<Type> visit(Harness h, Type context) {
    var operatorName = isAnd ? '&&' : '||';
    var result =
        h.typeAnalyzer.analyzeBinaryExpression(this, lhs, operatorName, rhs);
    h.irBuilder.apply(
        operatorName, [Kind.expression, Kind.expression], Kind.expression,
        location: location);
    return result;
  }
}

class LogicalAndPattern extends Pattern {
  final Pattern lhs;

  final Pattern rhs;

  LogicalAndPattern._(this.lhs, this.rhs, {required super.location})
      : super._();

  @override
  Type computeSchema(Harness h) =>
      h.typeAnalyzer.analyzeLogicalAndPatternSchema(lhs, rhs);

  @override
  void preVisit(PreVisitor visitor, VariableBinder<Node, Var> variableBinder,
      {required bool isInAssignment}) {
    lhs.preVisit(visitor, variableBinder, isInAssignment: isInAssignment);
    rhs.preVisit(visitor, variableBinder, isInAssignment: isInAssignment);
  }

  @override
  void visit(Harness h, SharedMatchContext context) {
    var matchedType = h.typeAnalyzer.flow.getMatchedValueType();
    h.typeAnalyzer.analyzeLogicalAndPattern(context, this, lhs, rhs);
    h.irBuilder.atom(matchedType.type, Kind.type, location: location);
    h.irBuilder.apply('logicalAndPattern',
        [Kind.pattern, Kind.pattern, Kind.type], Kind.pattern,
        names: ['matchedType'], location: location);
  }

  @override
  _debugString({required bool needsKeywordOrType}) => [
        lhs._debugString(needsKeywordOrType: false),
        '&&',
        rhs._debugString(needsKeywordOrType: false)
      ].join(' ');
}

class LogicalOrPattern extends Pattern {
  final Pattern lhs;

  final Pattern rhs;

  LogicalOrPattern(this.lhs, this.rhs, {required super.location}) : super._();

  @override
  Type computeSchema(Harness h) =>
      h.typeAnalyzer.analyzeLogicalOrPatternSchema(lhs, rhs);

  @override
  void preVisit(PreVisitor visitor, VariableBinder<Node, Var> variableBinder,
      {required bool isInAssignment}) {
    variableBinder.logicalOrPatternStart();
    lhs.preVisit(visitor, variableBinder, isInAssignment: isInAssignment);
    variableBinder.logicalOrPatternFinishLeft();
    rhs.preVisit(visitor, variableBinder, isInAssignment: isInAssignment);
    variableBinder.logicalOrPatternFinish(this);
  }

  @override
  void visit(Harness h, SharedMatchContext context) {
    var matchedType = h.typeAnalyzer.flow.getMatchedValueType();
    h.typeAnalyzer.analyzeLogicalOrPattern(context, this, lhs, rhs);
    h.irBuilder.atom(matchedType.type, Kind.type, location: location);
    h.irBuilder.apply('logicalOrPattern',
        [Kind.pattern, Kind.pattern, Kind.type], Kind.pattern,
        names: ['matchedType'], location: location);
  }

  @override
  _debugString({required bool needsKeywordOrType}) => [
        lhs._debugString(needsKeywordOrType: false),
        '||',
        rhs._debugString(needsKeywordOrType: false)
      ].join(' ');
}

/// Representation of an expression that can appear on the left hand side of an
/// assignment (or as the target of `++` or `--`).  Methods in this class may be
/// used to create more complex expressions based on this one.
abstract class LValue extends Expression {
  LValue._({required super.location});

  @override
  void preVisit(PreVisitor visitor, {_LValueDisposition disposition});

  /// Creates an expression representing a write to this L-value.
  Expression write(Expression? value) =>
      new Write(this, value, location: computeLocation());

  void _visitWrite(Harness h, Expression assignmentExpression, Type writtenType,
      Expression? rhs);
}

class MapPattern extends Pattern {
  final shared.MapPatternTypeArguments<Type>? typeArguments;

  final List<MapPatternElement> elements;

  MapPattern._(this.typeArguments, this.elements, {required super.location})
      : super._();

  @override
  Type computeSchema(Harness h) => h.typeAnalyzer.analyzeMapPatternSchema(
      typeArguments: typeArguments, elements: elements);

  @override
  void preVisit(PreVisitor visitor, VariableBinder<Node, Var> variableBinder,
      {required bool isInAssignment}) {
    for (var element in elements) {
      element.preVisit(visitor, variableBinder, isInAssignment: isInAssignment);
    }
  }

  @override
  void visit(Harness h, SharedMatchContext context) {
    var matchedType = h.typeAnalyzer.flow.getMatchedValueType();
    var mapPatternResult = h.typeAnalyzer.analyzeMapPattern(context, this,
        typeArguments: typeArguments, elements: elements);
    var requiredType = mapPatternResult.requiredType;
    h.irBuilder.atom(matchedType.type, Kind.type, location: location);
    h.irBuilder.atom(requiredType.type, Kind.type, location: location);
    h.irBuilder.apply(
      'mapPattern',
      [
        ...List.filled(elements.length, Kind.mapPatternElement),
        Kind.type,
        Kind.type,
      ],
      Kind.pattern,
      names: ['matchedType', 'requiredType'],
      location: location,
    );
  }

  @override
  String _debugString({required bool needsKeywordOrType}) {
    var elements = [
      for (var element in this.elements)
        element._debugString(needsKeywordOrType: needsKeywordOrType)
    ];
    return '[${elements.join(', ')}]';
  }
}

abstract class MapPatternElement implements ListOrMapPatternElement {}

class MapPatternEntry extends Node implements MapPatternElement {
  final Expression key;
  final Pattern value;

  MapPatternEntry._(this.key, this.value, {required super.location})
      : super._();

  @override
  void preVisit(PreVisitor visitor, VariableBinder<Node, Var> variableBinder,
      {required bool isInAssignment}) {
    value.preVisit(visitor, variableBinder, isInAssignment: isInAssignment);
  }

  @override
  String _debugString({required bool needsKeywordOrType}) {
    return '$key: $value';
  }
}

class MiniAstOperations
    with TypeOperations<Type>
    implements Operations<Var, Type> {
  static const Map<String, bool> _coreExhaustiveness = const {
    '()': true,
    '(int, int?)': false,
    'bool': true,
    'dynamic': false,
    'int': false,
    'int?': false,
    'List<int>': false,
    'Never': false,
    'num': false,
    'Object': false,
    'Object?': false,
    'String': false,
    'String?': false,
  };

  static final Map<String, Type> _coreGlbs = {
    '?, int': Type('int'),
    '(int,), ?': Type('(int,)'),
    '(num,), ?': Type('(num,)'),
    'Object?, double': Type('double'),
    'Object?, int': Type('int'),
    'double, int': Type('Never'),
    'double?, int?': Type('Null'),
    'int?, num': Type('int'),
    'Null, int': Type('Never'),
  };

  static final Map<String, Type> _coreLubs = {
    'double, int': Type('num'),
    'double?, int?': Type('num?'),
    'int, num': Type('num'),
    'Never, int': Type('int'),
    'Null, int': Type('int?'),
    '?, int': Type('int'),
    '?, List<?>': Type('List<?>'),
    '?, Null': Type('Null'),
  };

  static final Map<String, Type> _coreDownwardInferenceResults = {
    'bool <: bool': Type('bool'),
    'dynamic <: int': Type('dynamic'),
    'error <: int': Type('error'),
    'error <: num': Type('error'),
    'int <: dynamic': Type('int'),
    'int <: num': Type('int'),
    'int <: Object?': Type('int'),
    'List <: Iterable<int>': Type('List<int>'),
    'Never <: int': Type('Never'),
    'num <: int': Type('num'),
    'num <: Object': Type('num'),
    'Object <: num': Type('Object'),
    'String <: num': Type('String'),
  };

  static final Map<String, Type> _coreNormalizeResults = {
    'Object': Type('Object'),
    'FutureOr<Object>': Type('Object'),
    'double': Type('double'),
    'int': Type('int'),
    'int?': Type('int?'),
    'num': Type('num'),
    'String?': Type('String?'),
    'List<int>': Type('List<int>'),
  };

  static final Map<String, bool> _coreAreStructurallyEqualResults = {
    'Object == FutureOr<Object>': false,
    'double == num': false,
    'int == Object': false,
    'int == num': false,
    'num == int': false,
    'List<int> == int': false,
  };

  bool? _legacy;

  final Map<String, bool> _exhaustiveness = Map.of(_coreExhaustiveness);

  final Map<String, Type> _glbs = Map.of(_coreGlbs);

  final Map<String, Type> _lubs = Map.of(_coreLubs);

  final Map<String, Type> _downwardInferenceResults =
      Map.of(_coreDownwardInferenceResults);

  Map<String, Map<String, String>> _promotionExceptions = {};

  Map<String, Type> _normalizeResults = Map.of(_coreNormalizeResults);

  Map<String, bool> _areStructurallyEqualResults =
      Map.of(_coreAreStructurallyEqualResults);

  final Set<_PropertyElement> promotableFields = {};

  final TypeSystem _typeSystem = TypeSystem();

  @override
  final Type boolType = Type('bool');

  bool get legacy => _legacy ?? false;

  set legacy(bool value) {
    _legacy = value;
  }

  /// Updates the harness with a new result for [downwardInfer].
  void addDownwardInfer({
    required String name,
    required String context,
    required String result,
  }) {
    var query = '$name <: $context';
    _downwardInferenceResults[query] = Type(result);
  }

  /// Updates the harness so that when an [isExhaustiveType] query is invoked on
  /// type [type], [isExhaustive] will be returned.
  void addExhaustiveness(String type, bool isExhaustive) {
    _exhaustiveness[type] = isExhaustive;
  }

  void addPromotionException(String from, String to, String result) {
    (_promotionExceptions[from] ??= {})[to] = result;
  }

  void addSuperInterfaces(
      String className, List<Type> Function(List<Type>) template) {
    _typeSystem.addSuperInterfaces(className, template);
  }

  void addTypeVariable(String name, {String? bound}) {
    _typeSystem.addTypeVariable(name, bound: bound);
  }

  @override
  bool areStructurallyEqual(Type type1, Type type2) {
    if ('$type1' == '$type2') {
      return true;
    }
    var query = '$type1 == $type2';
    return _areStructurallyEqualResults[query] ?? fail('Unknown query: $query');
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

  /// Returns the downward inference result of a type with the given [name],
  /// in the [context]. For example infer `List<int>` from `Iterable<int>`.
  Type downwardInfer(String name, Type context) {
    var query = '$name <: $context';
    return _downwardInferenceResults[query] ??
        fail('Unknown downward inference query: $query');
  }

  @override
  Type factor(Type from, Type what) {
    return _typeSystem.factor(from, what);
  }

  @override
  Type glb(Type type1, Type type2) {
    if (type1.type == type2.type) return type1;
    var typeNames = [type1.type, type2.type];
    typeNames.sort();
    var query = typeNames.join(', ');
    return _glbs[query] ?? fail('Unknown glb query: $query');
  }

  /// Queries whether [type] is an "always exhaustive" type (as defined in the
  /// patterns spec).  Exhaustive types are types for which the switch statement
  /// is required to be exhaustive when patterns support is enabled.
  bool isAlwaysExhaustiveType(Type type) {
    var query = type.type;
    return _exhaustiveness[query] ??
        fail('Unknown exhaustiveness query: $query');
  }

  @override
  bool isAssignableTo(Type fromType, Type toType) {
    if (legacy && isSubtypeOf(toType, fromType)) return true;
    if (fromType.type == 'dynamic') return true;
    if (fromType.type == 'error') return true;
    return isSubtypeOf(fromType, toType);
  }

  @override
  bool isDynamic(Type type) =>
      type is PrimaryType && type.name == 'dynamic' && type.args.isEmpty;

  @override
  bool isError(Type type) =>
      type is PrimaryType && type.name == 'error' && type.args.isEmpty;

  @override
  bool isNever(Type type) {
    return type.type == 'Never';
  }

  @override
  bool isPropertyPromotable(Object property) =>
      promotableFields.contains(property);

  @override
  bool isSameType(Type type1, Type type2) {
    return type1.type == type2.type;
  }

  @override
  bool isSubtypeOf(Type leftType, Type rightType) {
    return _typeSystem.isSubtype(leftType, rightType);
  }

  @override
  bool isTypeParameterType(Type type) => type is PromotedTypeVariableType;

  @override
  Type lub(Type type1, Type type2) {
    if (type1.type == type2.type) return type1;
    var typeNames = [type1.type, type2.type];
    typeNames.sort();
    var query = typeNames.join(', ');
    return _lubs[query] ?? fail('Unknown lub query: $query');
  }

  @override
  Type makeNullable(Type type) => lub(type, Type('Null'));

  @override
  Type? matchIterableType(Type type) {
    if (type is PrimaryType && type.args.length == 1) {
      if (type.name == 'Iterable' || type.name == 'List') {
        return type.args[0];
      }
    }
    return null;
  }

  @override
  Type? matchListType(Type type) {
    if (type is PrimaryType && type.name == 'List' && type.args.length == 1) {
      return type.args[0];
    }
    return null;
  }

  @override
  shared.MapPatternTypeArguments<Type>? matchMapType(Type type) {
    if (type is PrimaryType && type.name == 'Map' && type.args.length == 2) {
      return shared.MapPatternTypeArguments<Type>(
        keyType: type.args[0],
        valueType: type.args[1],
      );
    }
    return null;
  }

  @override
  Type? matchStreamType(Type type) {
    if (type is PrimaryType && type.args.length == 1) {
      if (type.name == 'Stream') {
        return type.args[0];
      }
    }
    return null;
  }

  @override
  Type normalize(Type type) {
    var query = '$type';
    return _normalizeResults[query] ?? fail('Unknown query: $query');
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

  @override
  Type? tryPromoteToType(Type to, Type from) {
    var exception = (_promotionExceptions[from.type] ?? {})[to.type];
    if (exception != null) {
      return Type(exception);
    }
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
  static int _nextId = 0;

  /// Tracks all [Node] object that have had an [errorId] assigned, but haven't
  /// had [errorId] queried.  This is used to detect unused error IDs so that we
  /// can keep the test cases clean.
  static final Set<Node> _nodesWithUnusedErrorIds = {};

  final int id;

  final String location;

  String? _errorId;

  Node._({required this.location}) : id = _nextId++;

  String get errorId {
    _nodesWithUnusedErrorIds.remove(this);
    String? errorId = _errorId;
    if (errorId == null) {
      fail('No error ID assigned for $runtimeType $this at $location');
    } else {
      return errorId;
    }
  }

  set errorId(String value) {
    _errorId = value;
    _nodesWithUnusedErrorIds.add(this);
  }

  @override
  String toString() => 'Node#$id';
}

class NonNullAssert extends Expression {
  final Expression operand;

  NonNullAssert._(this.operand, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    operand.preVisit(visitor);
  }

  @override
  String toString() => '$operand!';

  @override
  ExpressionTypeAnalysisResult<Type> visit(Harness h, Type context) {
    return h.typeAnalyzer.analyzeNonNullAssert(this, operand);
  }
}

class Not extends Expression {
  final Expression operand;

  Not._(this.operand, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    operand.preVisit(visitor);
  }

  @override
  String toString() => '!$operand';

  @override
  ExpressionTypeAnalysisResult<Type> visit(Harness h, Type context) {
    return h.typeAnalyzer.analyzeLogicalNot(this, operand);
  }
}

class NullAwareAccess extends Expression {
  static String _fakeMethodName = 'm';

  final Expression lhs;
  final Expression rhs;
  final bool isCascaded;

  NullAwareAccess._(this.lhs, this.rhs, this.isCascaded,
      {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    lhs.preVisit(visitor);
    rhs.preVisit(visitor);
  }

  @override
  String toString() => '$lhs?.${isCascaded ? '.' : ''}($rhs)';

  @override
  ExpressionTypeAnalysisResult<Type> visit(Harness h, Type context) {
    var lhsType =
        h.typeAnalyzer.analyzeExpression(lhs, h.typeAnalyzer.unknownType);
    h.flow.nullAwareAccess_rightBegin(isCascaded ? null : lhs, lhsType);
    var rhsType =
        h.typeAnalyzer.analyzeExpression(rhs, h.typeAnalyzer.unknownType);
    h.flow.nullAwareAccess_end();
    var type = h._operations._lub(rhsType, Type('Null'));
    h.irBuilder.apply(
        _fakeMethodName, [Kind.expression, Kind.expression], Kind.expression,
        location: location);
    return new SimpleTypeAnalysisResult<Type>(type: type);
  }
}

class NullCheckOrAssertPattern extends Pattern {
  final Pattern inner;

  final bool isAssert;

  NullCheckOrAssertPattern._(this.inner, this.isAssert,
      {required super.location})
      : super._();

  @override
  Type computeSchema(Harness h) => h.typeAnalyzer
      .analyzeNullCheckOrAssertPatternSchema(inner, isAssert: isAssert);

  @override
  void preVisit(PreVisitor visitor, VariableBinder<Node, Var> variableBinder,
      {required bool isInAssignment}) {
    inner.preVisit(visitor, variableBinder, isInAssignment: isInAssignment);
  }

  @override
  void visit(Harness h, SharedMatchContext context) {
    var matchedType = h.typeAnalyzer.flow.getMatchedValueType();
    h.typeAnalyzer.analyzeNullCheckOrAssertPattern(context, this, inner,
        isAssert: isAssert);
    h.irBuilder.atom(matchedType.type, Kind.type, location: location);
    h.irBuilder.apply(isAssert ? 'nullAssertPattern' : 'nullCheckPattern',
        [Kind.pattern, Kind.type], Kind.pattern,
        names: ['matchedType'], location: location);
  }

  @override
  String _debugString({required bool needsKeywordOrType}) =>
      '${inner._debugString(needsKeywordOrType: needsKeywordOrType)}?';
}

class NullLiteral extends Expression {
  NullLiteral._({required super.location});

  @override
  void preVisit(PreVisitor visitor) {}

  @override
  String toString() => 'null';

  @override
  ExpressionTypeAnalysisResult<Type> visit(Harness h, Type context) {
    var result = h.typeAnalyzer.analyzeNullLiteral(this);
    h.irBuilder.atom('null', Kind.expression, location: location);
    return result;
  }
}

class ObjectPattern extends Pattern {
  final PrimaryType requiredType;
  final List<RecordPatternField> fields;

  ObjectPattern._({
    required this.requiredType,
    required this.fields,
    required super.location,
  }) : super._();

  @override
  Type computeSchema(Harness h) {
    return h.typeAnalyzer.analyzeObjectPatternSchema(requiredType);
  }

  @override
  void preVisit(PreVisitor visitor, VariableBinder<Node, Var> variableBinder,
      {required bool isInAssignment}) {
    for (var field in fields) {
      field.pattern
          .preVisit(visitor, variableBinder, isInAssignment: isInAssignment);
    }
  }

  @override
  void visit(Harness h, SharedMatchContext context) {
    var matchedType = h.typeAnalyzer.flow.getMatchedValueType();
    var objectPatternResult =
        h.typeAnalyzer.analyzeObjectPattern(context, this, fields: fields);
    var requiredType = objectPatternResult.requiredType;
    h.irBuilder.atom(matchedType.type, Kind.type, location: location);
    h.irBuilder.atom(requiredType.type, Kind.type, location: location);
    h.irBuilder.apply(
      'objectPattern',
      [...List.filled(fields.length, Kind.pattern), Kind.type, Kind.type],
      Kind.pattern,
      names: ['matchedType', 'requiredType'],
      location: location,
    );
  }

  @override
  String _debugString({required bool needsKeywordOrType}) {
    var fieldStrings = [
      for (var field in fields)
        field.pattern._debugString(needsKeywordOrType: needsKeywordOrType)
    ];
    final requiredType = this.requiredType;
    return '$requiredType(${fieldStrings.join(', ')})';
  }
}

class ParenthesizedExpression extends Expression {
  final Expression expr;

  ParenthesizedExpression._(this.expr, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    expr.preVisit(visitor);
  }

  @override
  String toString() => '($expr)';

  @override
  ExpressionTypeAnalysisResult<Type> visit(Harness h, Type context) {
    return h.typeAnalyzer.analyzeParenthesizedExpression(this, expr, context);
  }
}

class ParenthesizedPattern extends Pattern {
  final Pattern inner;

  ParenthesizedPattern._(this.inner, {required super.location}) : super._();

  @override
  Type computeSchema(Harness h) => inner.computeSchema(h);

  @override
  void preVisit(PreVisitor visitor, VariableBinder<Node, Var> variableBinder,
          {required bool isInAssignment}) =>
      inner.preVisit(visitor, variableBinder, isInAssignment: isInAssignment);

  @override
  void visit(Harness h, SharedMatchContext context) {
    inner.visit(h, context);
  }

  @override
  String _debugString({required bool needsKeywordOrType}) =>
      '(${inner._debugString(needsKeywordOrType: false)})';
}

abstract class Pattern extends Node
    with PossiblyGuardedPattern
    implements ListPatternElement {
  Pattern._({required super.location}) : super._();

  Pattern get nullAssert =>
      NullCheckOrAssertPattern._(this, true, location: computeLocation());

  Pattern get nullCheck =>
      NullCheckOrAssertPattern._(this, false, location: computeLocation());

  Pattern get parenthesized =>
      ParenthesizedPattern._(this, location: computeLocation());

  @override
  GuardedPattern get _asGuardedPattern {
    return GuardedPattern._(
      pattern: this,
      guard: null,
      location: location,
    );
  }

  Pattern and(Pattern other) =>
      LogicalAndPattern._(this, other, location: computeLocation());

  Pattern as_(String type) =>
      new CastPattern(this, Type(type), location: computeLocation());

  /// Creates a pattern assignment expression assigning [rhs] to this pattern.
  Expression assign(Expression rhs) =>
      PatternAssignment._(this, rhs, location: computeLocation());

  Type computeSchema(Harness h);

  Pattern or(Pattern other) =>
      LogicalOrPattern(this, other, location: computeLocation());

  RecordPatternField recordField([String? name]) {
    return RecordPatternField(
      name: name,
      pattern: this,
      location: computeLocation(),
    );
  }

  @override
  String toString() => _debugString(needsKeywordOrType: true);

  void visit(Harness h, SharedMatchContext context);

  GuardedPattern when(Expression? guard) {
    return GuardedPattern._(
      pattern: this,
      guard: guard,
      location: location,
    );
  }
}

class PatternAssignment extends Expression {
  final Pattern lhs;
  final Expression rhs;

  PatternAssignment._(this.lhs, this.rhs, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    var variableBinder = _VariableBinder(errors: visitor.errors);
    variableBinder.casePatternStart();
    lhs.preVisit(visitor, variableBinder, isInAssignment: true);
    variableBinder.casePatternFinish();
    variableBinder.finish();
    rhs.preVisit(visitor);
  }

  @override
  ExpressionTypeAnalysisResult<Type> visit(Harness h, Type context) {
    var result = h.typeAnalyzer.analyzePatternAssignment(this, lhs, rhs);
    h.irBuilder.apply(
        'patternAssignment', [Kind.expression, Kind.pattern], Kind.expression,
        location: location);
    return result;
  }
}

class PatternForIn extends Statement {
  final bool hasAwait;
  final Pattern pattern;
  final Expression expression;
  final Statement body;

  PatternForIn(this.pattern, this.expression, this.body,
      {required this.hasAwait, required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    expression.preVisit(visitor);

    var variableBinder = _VariableBinder(errors: visitor.errors);
    variableBinder.casePatternStart();
    pattern.preVisit(visitor, variableBinder, isInAssignment: false);
    variableBinder.casePatternFinish();
    variableBinder.finish();

    visitor._assignedVariables.beginNode();
    body.preVisit(visitor);
    visitor._assignedVariables.endNode(this);
  }

  @override
  String toString() {
    return 'for ($pattern in $expression) $body';
  }

  @override
  void visit(Harness h) {
    h.typeAnalyzer.analyzePatternForIn(
        node: this,
        hasAwait: hasAwait,
        pattern: pattern,
        expression: expression,
        dispatchBody: () {
          h.typeAnalyzer.dispatchStatement(body);
        });
    h.irBuilder.apply(
      'forEach',
      [Kind.expression, Kind.pattern, Kind.statement],
      Kind.statement,
      location: location,
    );
  }
}

class PatternForInElement extends CollectionElement {
  final bool hasAwait;
  final Pattern pattern;
  final Expression expression;
  final CollectionElement body;

  PatternForInElement(this.pattern, this.expression, this.body,
      {required this.hasAwait, required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    expression.preVisit(visitor);

    var variableBinder = _VariableBinder(errors: visitor.errors);
    variableBinder.casePatternStart();
    pattern.preVisit(visitor, variableBinder, isInAssignment: false);
    variableBinder.casePatternFinish();
    variableBinder.finish();

    visitor._assignedVariables.beginNode();
    body.preVisit(visitor);
    visitor._assignedVariables.endNode(this);
  }

  @override
  void visit(Harness h, covariant CollectionElementContext context) {
    h.typeAnalyzer.analyzePatternForIn(
        node: this,
        hasAwait: hasAwait,
        pattern: pattern,
        expression: expression,
        dispatchBody: () {
          h.typeAnalyzer.dispatchCollectionElement(body, context);
        });
    h.irBuilder.apply(
      'forEach',
      [Kind.expression, Kind.pattern, Kind.collectionElement],
      Kind.collectionElement,
      location: location,
    );
  }
}

/// A variable modelling an implicit join of variables declared inside
/// logical-or patterns or switch cases sharing a body.
///
/// The analyzer and CFE make such variables automatically when needed, but in
/// the flow analysis and type inference unit tests, we create them manually so
/// that we can refer to them in later code.
class PatternVariableJoin extends Var {
  /// The component variables joined together by this variable.  When the test
  /// is run, an assertion will verify that these components match those passed
  /// to [VariableBinder.joinPatternVariables].
  final List<Var> expectedComponents;

  /// Indicates whether this variable has been found to be inconsistent; a value
  /// of `true` either means that the variable is consistent or that analysis
  /// has not yet completed.
  @override
  JoinedPatternVariableInconsistency inconsistency =
      JoinedPatternVariableInconsistency.none;

  /// Indicates whether [VariableBinder.joinPatternVariables] has been called
  /// for this variable join yet.
  bool isJoined = false;

  PatternVariableJoin(super.name,
      {required this.expectedComponents, super.identity})
      : super(location: computeLocation()) {
    for (var component in expectedComponents) {
      assert(component._joinedVar == null);
      component._joinedVar = this;
    }
  }

  @override
  String get stringToCheckVariables {
    return toString();
  }

  @override
  String toString() {
    var declarationStr = <String>[
      if (_type != null) ...[
        if (inconsistency != JoinedPatternVariableInconsistency.none)
          'notConsistent:${inconsistency.name}',
        if (isFinal) 'final',
        type.type,
      ],
      name,
    ].join(' ');
    var componentsStr =
        expectedComponents.map((v) => v.stringToCheckVariables).join(', ');
    return '$declarationStr = [$componentsStr]';
  }

  /// Called by [VariableBinder.joinPatternVariables].
  void _handleJoin({
    required List<Var> components,
    required JoinedPatternVariableInconsistency inconsistency,
  }) {
    expect(isJoined, false);
    expect(components.map((c) => c.identity),
        expectedComponents.map((c) => c.identity),
        reason: 'at $location');
    expect(components, expectedComponents, reason: 'at $location');
    this.inconsistency = inconsistency;
    this.isJoined = true;
  }
}

class PlaceholderExpression extends Expression {
  final Type type;

  PlaceholderExpression._(this.type, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {}

  @override
  String toString() => '(expr with type $type)';

  @override
  ExpressionTypeAnalysisResult<Type> visit(Harness h, Type context) {
    h.irBuilder.atom(type.type, Kind.type, location: location);
    h.irBuilder.apply('expr', [Kind.type], Kind.expression, location: location);
    return new SimpleTypeAnalysisResult<Type>(type: type);
  }
}

/// Mixin containing logic shared by [Pattern] and [GuardedPattern].  Both of
/// these types can be used in a case where a pattern with an optional guard is
/// expected.
mixin PossiblyGuardedPattern on Node {
  SwitchHead get switchCase {
    return SwitchHeadCase._(
      _asGuardedPattern,
      location: location,
    );
  }

  /// Converts `this` to a [GuardedPattern], including a `null` guard if
  /// necessary.
  GuardedPattern get _asGuardedPattern;

  SwitchStatementMember then(List<Statement> body) {
    return SwitchStatementMember._(
      [
        SwitchHeadCase._(_asGuardedPattern, location: location),
      ],
      Block._(body, location: location),
      hasLabels: false,
      location: location,
    );
  }

  ExpressionCase thenExpr(Expression body) =>
      ExpressionCase._(_asGuardedPattern, body, location: computeLocation());
}

/// Data structure holding information needed during the "pre-visit" phase of
/// type analysis.
class PreVisitor {
  final AssignedVariables<Node, Var> _assignedVariables =
      AssignedVariables<Node, Var>();

  final VariableBinderErrors<Node, Var>? errors;

  PreVisitor(this.errors);
}

/// Base class for language constructs that, at a given point in flow analysis,
/// might or might not be promoted.
abstract class Promotable {
  /// Makes the appropriate calls to [AssignedVariables] and [VariableBinder]
  /// for this syntactic construct.
  void preVisit(PreVisitor visitor);

  /// Queries the current promotion status of `this`.  Return value is either a
  /// type (if `this` is promoted), or `null` (if it isn't).
  Type? _getPromotedType(Harness h);
}

/// Base class for l-values that, at a given point in flow analysis, might or
/// might not be promoted.
abstract class PromotableLValue extends LValue implements Promotable {
  PromotableLValue._({required super.location}) : super._();
}

class Property extends PromotableLValue {
  final Expression target;

  final String propertyName;

  Property._(this.target, this.propertyName, {required super.location})
      : super._();

  @override
  void preVisit(PreVisitor visitor,
      {_LValueDisposition disposition = _LValueDisposition.read}) {
    target.preVisit(visitor);
  }

  @override
  String toString() => '$target.$propertyName';

  @override
  ExpressionTypeAnalysisResult<Type> visit(Harness h, Type context) {
    return h.typeAnalyzer.analyzePropertyGet(this, target, propertyName);
  }

  @override
  Type? _getPromotedType(Harness h) {
    var receiverType =
        h.typeAnalyzer.analyzeExpression(target, h.typeAnalyzer.unknownType);
    var member = h.typeAnalyzer._lookupMember(this, receiverType, propertyName);
    return h.flow.promotedPropertyType(
        ExpressionPropertyTarget(target), propertyName, member, member!._type);
  }

  @override
  void _visitWrite(Harness h, Expression assignmentExpression, Type writtenType,
      Expression? rhs) {
    // No flow analysis impact
  }
}

class RecordPattern extends Pattern {
  final List<RecordPatternField> fields;

  RecordPattern._(this.fields, {required super.location}) : super._();

  @override
  Type computeSchema(Harness h) {
    return h.typeAnalyzer.analyzeRecordPatternSchema(
      fields: fields,
    );
  }

  @override
  void preVisit(PreVisitor visitor, VariableBinder<Node, Var> variableBinder,
      {required bool isInAssignment}) {
    for (var field in fields) {
      field.pattern
          .preVisit(visitor, variableBinder, isInAssignment: isInAssignment);
    }
  }

  @override
  void visit(Harness h, SharedMatchContext context) {
    var matchedType = h.typeAnalyzer.flow.getMatchedValueType();
    var recordPatternResult =
        h.typeAnalyzer.analyzeRecordPattern(context, this, fields: fields);
    var requiredType = recordPatternResult.requiredType;
    h.irBuilder.atom(matchedType.type, Kind.type, location: location);
    h.irBuilder.atom(requiredType.type, Kind.type, location: location);
    h.irBuilder.apply(
      'recordPattern',
      [...List.filled(fields.length, Kind.pattern), Kind.type, Kind.type],
      Kind.pattern,
      names: ['matchedType', 'requiredType'],
      location: location,
    );
  }

  @override
  String _debugString({required bool needsKeywordOrType}) {
    var fieldStrings = [
      for (var field in fields)
        field.pattern._debugString(needsKeywordOrType: needsKeywordOrType)
    ];
    return '(${fieldStrings.join(', ')})';
  }
}

/// A field in object and record patterns.
class RecordPatternField extends Node
    implements shared.RecordPatternField<Node, Pattern> {
  @override
  final String? name;
  @override
  final Pattern pattern;

  RecordPatternField({
    required this.name,
    required this.pattern,
    required super.location,
  }) : super._();

  @override
  Node get node => this;
}

class RelationalPattern extends Pattern {
  final String operator;
  final Expression operand;

  RelationalPattern._(this.operator, this.operand, {required super.location})
      : super._();

  @override
  Type computeSchema(Harness h) =>
      h.typeAnalyzer.analyzeRelationalPatternSchema();

  @override
  void preVisit(PreVisitor visitor, VariableBinder<Node, Var> variableBinder,
      {required bool isInAssignment}) {
    operand.preVisit(visitor);
  }

  @override
  void visit(Harness h, SharedMatchContext context) {
    var matchedType = h.typeAnalyzer.flow.getMatchedValueType();
    h.typeAnalyzer.analyzeRelationalPattern(context, this, operand);
    h.irBuilder.atom(matchedType.type, Kind.type, location: location);
    h.irBuilder.apply(operator, [Kind.expression, Kind.type], Kind.pattern,
        names: ['matchedType'], location: location);
  }

  @override
  _debugString({required bool needsKeywordOrType}) => '$operator $operand';
}

class RestPatternElement extends Node
    implements ListPatternElement, MapPatternElement {
  final Pattern? pattern;

  RestPatternElement._(this.pattern, {required super.location}) : super._();

  @override
  void preVisit(PreVisitor visitor, VariableBinder<Node, Var> variableBinder,
      {required bool isInAssignment}) {
    pattern?.preVisit(visitor, variableBinder, isInAssignment: isInAssignment);
  }

  @override
  String _debugString({required bool needsKeywordOrType}) {
    var pattern = this.pattern;
    if (pattern == null) {
      return '...';
    } else {
      return '...${pattern._debugString(needsKeywordOrType: false)}';
    }
  }
}

class Return extends Statement {
  Return._({required super.location});

  @override
  void preVisit(PreVisitor visitor) {}

  @override
  String toString() => 'return;';

  @override
  void visit(Harness h) {
    h.typeAnalyzer.analyzeReturnStatement();
    h.irBuilder.apply('return', [], Kind.statement, location: location);
  }
}

/// Representation of a statement in the pseudo-Dart language used for flow
/// analysis testing.
abstract class Statement extends Node {
  Statement({required super.location}) : super._();

  /// Wraps `this` in such a way that, when the test is run, it will verify that
  /// the IR produced matches [expectedIr].
  Statement checkIr(String expectedIr) =>
      CheckStatementIr._(this, expectedIr, location: computeLocation());

  void preVisit(PreVisitor visitor);

  /// If `this` is a statement `x`, creates a pseudo-expression that models
  /// execution of `x` followed by evaluation of [expr].  This can be used to
  /// test that flow analysis is in the correct state before an expression is
  /// visited.
  Expression thenExpr(Expression expr) =>
      WrappedExpression._(this, expr, null, location: computeLocation());

  void visit(Harness h);
}

class SwitchExpression extends Expression {
  final Expression scrutinee;

  final List<ExpressionCase> cases;

  SwitchExpression._(this.scrutinee, this.cases, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    scrutinee.preVisit(visitor);
    for (var case_ in cases) {
      case_._preVisit(visitor);
    }
  }

  @override
  String toString() {
    String body;
    if (cases.isEmpty) {
      body = '{}';
    } else {
      var contents = cases.join(' ');
      body = '{ $contents }';
    }
    return 'switch ($scrutinee) $body';
  }

  @override
  ExpressionTypeAnalysisResult<Type> visit(Harness h, Type context) {
    var result = h.typeAnalyzer
        .analyzeSwitchExpression(this, scrutinee, cases.length, context);
    h.irBuilder.apply(
        'switchExpr',
        [Kind.expression, ...List.filled(cases.length, Kind.expressionCase)],
        Kind.expression,
        location: location);
    return result;
  }
}

abstract class SwitchHead extends Node {
  SwitchHead._({required super.location}) : super._();

  SwitchStatementMember then(List<Statement> body) {
    return SwitchStatementMember._(
      [this],
      Block._(body, location: location),
      hasLabels: false,
      location: location,
    );
  }

  ExpressionCase thenExpr(Expression body) =>
      ExpressionCase._(null, body, location: computeLocation());
}

class SwitchHeadCase extends SwitchHead {
  final GuardedPattern guardedPattern;

  SwitchHeadCase._(this.guardedPattern, {required super.location}) : super._();
}

class SwitchHeadDefault extends SwitchHead {
  SwitchHeadDefault({required super.location}) : super._();
}

class SwitchStatement extends Statement {
  final Expression scrutinee;

  final List<SwitchStatementMember> cases;

  final bool? isLegacyExhaustive;

  final bool? expectHasDefault;

  final bool? expectIsExhaustive;

  final bool? expectLastCaseTerminates;

  final bool? expectRequiresExhaustivenessValidation;

  final String? expectScrutineeType;

  SwitchStatement(this.scrutinee, this.cases, this.isLegacyExhaustive,
      {required super.location,
      required this.expectHasDefault,
      required this.expectIsExhaustive,
      required this.expectLastCaseTerminates,
      required this.expectRequiresExhaustivenessValidation,
      required this.expectScrutineeType});

  @override
  void preVisit(PreVisitor visitor) {
    scrutinee.preVisit(visitor);
    visitor._assignedVariables.beginNode();
    for (var case_ in cases) {
      case_._preVisit(visitor);
    }
    visitor._assignedVariables.endNode(this);
  }

  @override
  String toString() {
    var isLegacyExhaustive = this.isLegacyExhaustive;
    var exhaustiveness = isLegacyExhaustive == null
        ? ''
        : isLegacyExhaustive
            ? '<exhaustive>'
            : '<non-exhaustive>';
    String body;
    if (cases.isEmpty) {
      body = '{}';
    } else {
      var contents = cases.join(' ');
      body = '{ $contents }';
    }
    return 'switch$exhaustiveness ($scrutinee) $body';
  }

  @override
  void visit(Harness h) {
    bool needsLegacyExhaustive = !h.patternsEnabled;
    if (!needsLegacyExhaustive && isLegacyExhaustive != null) {
      fail('isLegacyExhaustive should not be specified at $location');
    } else if (needsLegacyExhaustive && isLegacyExhaustive == null) {
      fail('isLegacyExhaustive should be specified at $location');
    }
    var previousBreakTarget = h.typeAnalyzer._currentBreakTarget;
    h.typeAnalyzer._currentBreakTarget = this;
    var previousContinueTarget = h.typeAnalyzer._currentContinueTarget;
    h.typeAnalyzer._currentContinueTarget = this;
    var analysisResult =
        h.typeAnalyzer.analyzeSwitchStatement(this, scrutinee, cases.length);
    expect(analysisResult.hasDefault, expectHasDefault ?? anything);
    expect(analysisResult.isExhaustive, expectIsExhaustive ?? anything);
    expect(analysisResult.lastCaseTerminates,
        expectLastCaseTerminates ?? anything);
    expect(analysisResult.requiresExhaustivenessValidation,
        expectRequiresExhaustivenessValidation ?? anything);
    expect(analysisResult.scrutineeType.type, expectScrutineeType ?? anything);
    h.irBuilder.apply(
      'switch',
      [
        Kind.expression,
        ...List.filled(cases.length, Kind.statementCase),
      ],
      Kind.statement,
      location: location,
    );
    h.typeAnalyzer._currentBreakTarget = previousBreakTarget;
    h.typeAnalyzer._currentContinueTarget = previousContinueTarget;
  }
}

/// Representation of a single case clause in a switch statement.  Use [case_]
/// to create instances of this class.
class SwitchStatementMember extends Node {
  final bool hasLabels;
  final List<SwitchHead> elements;
  final Block body;

  /// These variables are set during pre-visit, and some of them are joins of
  /// pattern variable declarations. We don't know their types until we do
  /// type analysis. So, some of these variables might become unavailable.
  late final Map<String, Var> _candidateVariables;

  SwitchStatementMember._(
    this.elements,
    this.body, {
    required super.location,
    required this.hasLabels,
  }) : super._();

  void _preVisit(PreVisitor visitor) {
    var variableBinder = _VariableBinder(errors: visitor.errors);
    variableBinder.switchStatementSharedCaseScopeStart(this);
    for (SwitchHead element in elements) {
      if (element is SwitchHeadCase) {
        variableBinder.casePatternStart();
        element.guardedPattern.pattern
            .preVisit(visitor, variableBinder, isInAssignment: false);
        element.guardedPattern.guard?.preVisit(visitor);
        element.guardedPattern.variables = variableBinder.casePatternFinish(
          sharedCaseScopeKey: this,
        );
      } else {
        variableBinder.switchStatementSharedCaseScopeEmpty(this);
      }
    }
    if (hasLabels) {
      variableBinder.switchStatementSharedCaseScopeEmpty(this);
    }
    _candidateVariables =
        variableBinder.switchStatementSharedCaseScopeFinish(this);
    body.preVisit(visitor);
  }
}

class This extends Expression {
  This._({required super.location});

  @override
  void preVisit(PreVisitor visitor) {}

  @override
  String toString() => 'this';

  @override
  ExpressionTypeAnalysisResult<Type> visit(Harness h, Type context) {
    var result = h.typeAnalyzer.analyzeThis(this);
    h.irBuilder.atom('this', Kind.expression, location: location);
    return result;
  }
}

class ThisOrSuperProperty extends PromotableLValue {
  final String propertyName;
  final bool isSuperAccess;

  ThisOrSuperProperty._(this.propertyName,
      {required super.location, required this.isSuperAccess})
      : super._();

  @override
  void preVisit(PreVisitor visitor,
      {_LValueDisposition disposition = _LValueDisposition.read}) {}

  @override
  ExpressionTypeAnalysisResult<Type> visit(Harness h, Type context) {
    var result = h.typeAnalyzer.analyzeThisOrSuperPropertyGet(
        this, propertyName,
        isSuperAccess: isSuperAccess);
    var thisOrSuper = isSuperAccess ? 'super' : 'this';
    h.irBuilder.atom('$thisOrSuper.$propertyName', Kind.expression,
        location: location);
    return result;
  }

  @override
  Type? _getPromotedType(Harness h) {
    var thisOrSuper = isSuperAccess ? 'super' : 'this';
    h.irBuilder.atom('$thisOrSuper.$propertyName', Kind.expression,
        location: location);
    var member = h.typeAnalyzer._lookupMember(this, h._thisType!, propertyName);
    return h.flow.promotedPropertyType(
        isSuperAccess
            ? SuperPropertyTarget.singleton
            : ThisPropertyTarget.singleton,
        propertyName,
        member,
        member!._type);
  }

  @override
  void _visitWrite(Harness h, Expression assignmentExpression, Type writtenType,
      Expression? rhs) {
    // No flow analysis impact
  }
}

class Throw extends Expression {
  final Expression operand;

  Throw._(this.operand, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    operand.preVisit(visitor);
  }

  @override
  String toString() => 'throw ...';

  @override
  ExpressionTypeAnalysisResult<Type> visit(Harness h, Type context) {
    return h.typeAnalyzer.analyzeThrow(this, operand);
  }
}

abstract class TryBuilder {
  TryStatement catch_(
      {Var? exception, Var? stackTrace, required List<Statement> body});

  Statement finally_(List<Statement> statements);
}

abstract class TryStatement extends Statement implements TryBuilder {
  TryStatement._({required super.location});
}

class TryStatementImpl extends TryStatement {
  final Statement body;
  final List<CatchClause> catches;
  final Statement? finallyStatement;

  TryStatementImpl(this.body, this.catches, this.finallyStatement,
      {required super.location})
      : super._();

  @override
  TryStatement catch_(
      {Var? exception, Var? stackTrace, required List<Statement> body}) {
    assert(finallyStatement == null, 'catch after finally');
    return TryStatementImpl(
        this.body,
        [
          ...catches,
          CatchClause._(
              Block._(body, location: computeLocation()), exception, stackTrace)
        ],
        null,
        location: location);
  }

  @override
  Statement finally_(List<Statement> statements) {
    assert(finallyStatement == null, 'multiple finally clauses');
    return TryStatementImpl(
        body, catches, Block._(statements, location: computeLocation()),
        location: location);
  }

  @override
  void preVisit(PreVisitor visitor) {
    if (finallyStatement != null) {
      visitor._assignedVariables.beginNode();
    }
    if (catches.isNotEmpty) {
      visitor._assignedVariables.beginNode();
    }
    body.preVisit(visitor);
    visitor._assignedVariables.endNode(body);
    for (var catch_ in catches) {
      catch_._preVisit(visitor);
    }
    if (finallyStatement != null) {
      if (catches.isNotEmpty) {
        visitor._assignedVariables.endNode(this);
      }
      finallyStatement!.preVisit(visitor);
    }
  }

  @override
  void visit(Harness h) {
    h.typeAnalyzer.analyzeTryStatement(this, body, catches, finallyStatement);
    h.irBuilder.apply(
        'try',
        [
          Kind.statement,
          ...List.filled(catches.length, Kind.statement),
          Kind.statement
        ],
        Kind.statement,
        location: location);
  }
}

/// Variant of [Label] that causes `null` to be passed to `handleBreak` or
/// `handleContinue`.
class UnboundLabel extends Label {
  UnboundLabel._() : super._(location: computeLocation());

  @override
  Statement thenStmt(Statement statement) {
    fail("Unbound labels can't be bound");
  }

  @override
  String toString() => '<UNBOUND LABEL>';

  @override
  Statement? _getBinding() => null;
}

/// Representation of a local variable in the pseudo-Dart language used for flow
/// analysis testing.
class Var extends Node implements Promotable {
  final String name;
  bool isFinal;

  /// The type of the variable, or `null` if it is not yet known.
  Type? _type;

  /// Identifier for this variable in IR.  This allows distinct variables with
  /// the same name to be distinguished.
  final String identity;

  /// The [PatternVariableJoin] that this variable is a component of, if any.
  PatternVariableJoin? _joinedVar;

  Var(this.name, {this.isFinal = false, String? identity, String? location})
      : identity = identity ?? name,
        super._(location: location ?? computeLocation());

  /// Creates an L-value representing a reference to this variable.
  LValue get expr =>
      new VariableReference._(this, null, location: computeLocation());

  JoinedPatternVariableInconsistency get inconsistency {
    return JoinedPatternVariableInconsistency.none;
  }

  /// The string that should be used to check variables in a set.
  String get stringToCheckVariables => identity;

  /// Gets the type if known; otherwise throws an exception.
  Type get type {
    if (_type == null) {
      throw 'Type not yet known';
    } else {
      return _type!;
    }
  }

  set type(Type value) {
    if (_type != null) {
      throw 'Type already set';
    }
    _type = value;
  }

  Pattern pattern({String? type, String? expectInferredType}) =>
      new VariablePattern._(
          type == null ? null : Type(type), this, expectInferredType,
          location: computeLocation());

  @override
  void preVisit(PreVisitor visitor) {}

  /// Creates an expression representing a read of this variable, which as a
  /// side effect will call the given callback with the returned promoted type.
  Expression readAndCheckPromotedType(void Function(Type?) callback) =>
      new VariableReference._(this, callback, location: computeLocation());

  @override
  String toString() => 'var $name';

  /// Creates an expression representing a write to this variable.
  Expression write(Expression? value) {
    var location = computeLocation();
    return new Write(
        new VariableReference._(this, null, location: location), value,
        location: location);
  }

  @override
  Type? _getPromotedType(Harness h) {
    h.irBuilder.atom(name, Kind.expression, location: location);
    return h.flow.promotedType(this);
  }
}

class VariablePattern extends Pattern {
  final Type? declaredType;

  final Var variable;

  final String? expectInferredType;

  late bool isAssignedVariable;

  VariablePattern._(this.declaredType, this.variable, this.expectInferredType,
      {required super.location})
      : super._();

  @override
  Type computeSchema(Harness h) {
    if (isAssignedVariable) {
      return h.typeAnalyzer.analyzeAssignedVariablePatternSchema(variable);
    } else {
      return h.typeAnalyzer.analyzeDeclaredVariablePatternSchema(declaredType);
    }
  }

  @override
  void preVisit(PreVisitor visitor, VariableBinder<Node, Var> variableBinder,
      {required bool isInAssignment}) {
    var variable = this.variable;
    isAssignedVariable = isInAssignment;
    if (!isAssignedVariable && variableBinder.add(variable.name, variable)) {
      visitor._assignedVariables.declare(variable);
    }
    if (isAssignedVariable) {
      assert(declaredType == null,
          "Variables in pattern assignments can't have declared types");
    }
  }

  @override
  void visit(Harness h, SharedMatchContext context) {
    if (isAssignedVariable) {
      h.typeAnalyzer.analyzeAssignedVariablePattern(context, this, variable);
      h.typeAnalyzer.handleAssignedVariablePattern(this);
    } else {
      var matchedType = h.typeAnalyzer.flow.getMatchedValueType();
      var declaredVariablePatternResult = h.typeAnalyzer
          .analyzeDeclaredVariablePattern(
              context, this, variable, variable.name, declaredType);
      var staticType = declaredVariablePatternResult.staticType;
      h.typeAnalyzer.handleDeclaredVariablePattern(this,
          matchedType: matchedType, staticType: staticType);
    }
  }

  @override
  _debugString({required bool needsKeywordOrType}) => [
        if (declaredType != null)
          declaredType!.type
        else if (needsKeywordOrType)
          'var',
        variable.name,
        if (expectInferredType != null) '(expected type $expectInferredType)'
      ].join(' ');
}

class VariableReference extends LValue {
  final Var variable;

  final void Function(Type?)? callback;

  VariableReference._(this.variable, this.callback, {required super.location})
      : super._();

  @override
  void preVisit(PreVisitor visitor,
      {_LValueDisposition disposition = _LValueDisposition.read}) {
    if (disposition != _LValueDisposition.write) {
      visitor._assignedVariables.read(variable);
    }
    if (disposition != _LValueDisposition.read) {
      visitor._assignedVariables.write(variable);
    }
  }

  @override
  String toString() => variable.name;

  @override
  ExpressionTypeAnalysisResult<Type> visit(Harness h, Type context) {
    var result = h.typeAnalyzer.analyzeVariableGet(this, variable, callback);
    h.irBuilder.atom(variable.name, Kind.expression, location: location);
    return result;
  }

  @override
  void _visitWrite(Harness h, Expression assignmentExpression, Type writtenType,
      Expression? rhs) {
    h.flow.write(assignmentExpression, variable, writtenType, rhs);
  }
}

class While extends Statement {
  final Expression condition;
  final Statement body;

  While._(this.condition, this.body, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    visitor._assignedVariables.beginNode();
    condition.preVisit(visitor);
    body.preVisit(visitor);
    visitor._assignedVariables.endNode(this);
  }

  @override
  String toString() => 'while ($condition) $body';

  @override
  void visit(Harness h) {
    h.typeAnalyzer.analyzeWhileLoop(this, condition, body);
    h.irBuilder.apply(
        'while', [Kind.expression, Kind.statement], Kind.statement,
        location: location);
  }
}

class WildcardPattern extends Pattern {
  final Type? declaredType;

  final String? expectInferredType;

  WildcardPattern._(
      {required this.declaredType,
      required this.expectInferredType,
      required super.location})
      : super._();

  @override
  Type computeSchema(Harness h) {
    return h.typeAnalyzer.analyzeWildcardPatternSchema(
      declaredType: declaredType,
    );
  }

  @override
  void preVisit(PreVisitor visitor, VariableBinder<Node, Var> variableBinder,
      {required bool isInAssignment}) {}

  @override
  void visit(Harness h, SharedMatchContext context) {
    var matchedType = h.typeAnalyzer.flow.getMatchedValueType();
    h.typeAnalyzer.analyzeWildcardPattern(
      context: context,
      node: this,
      declaredType: declaredType,
    );
    h.irBuilder.atom(matchedType.type, Kind.type, location: location);
    h.irBuilder.apply('wildcardPattern', [Kind.type], Kind.pattern,
        names: ['matchedType'], location: location);
    var expectInferredType = this.expectInferredType;
    if (expectInferredType != null) {
      expect(matchedType.type, expectInferredType, reason: 'at $location');
    }
  }

  @override
  _debugString({required bool needsKeywordOrType}) => [
        if (declaredType != null) declaredType!.type,
        '_',
        if (expectInferredType != null) '(expected type $expectInferredType)'
      ].join(' ');
}

class WrappedExpression extends Expression {
  final Statement? before;
  final Expression expr;
  final Statement? after;

  WrappedExpression._(this.before, this.expr, this.after,
      {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    before?.preVisit(visitor);
    expr.preVisit(visitor);
    after?.preVisit(visitor);
  }

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
  ExpressionTypeAnalysisResult<Type> visit(Harness h, Type context) {
    late MiniIrTmp beforeTmp;
    if (before != null) {
      h.typeAnalyzer.dispatchStatement(before!);
      h.irBuilder
          .apply('expr', [Kind.statement], Kind.expression, location: location);
      beforeTmp = h.irBuilder.allocateTmp();
    }
    var type =
        h.typeAnalyzer.analyzeExpression(expr, h.typeAnalyzer.unknownType);
    if (after != null) {
      var exprTmp = h.irBuilder.allocateTmp();
      h.typeAnalyzer.dispatchStatement(after!);
      h.irBuilder
          .apply('expr', [Kind.statement], Kind.expression, location: location);
      var afterTmp = h.irBuilder.allocateTmp();
      h.irBuilder.readTmp(exprTmp, location: location);
      h.irBuilder.let(afterTmp, location: location);
      h.irBuilder.let(exprTmp, location: location);
    }
    h.flow.forwardExpression(this, expr);
    if (before != null) {
      h.irBuilder.let(beforeTmp, location: location);
    }
    return new SimpleTypeAnalysisResult<Type>(type: type);
  }
}

class Write extends Expression {
  final LValue lhs;
  final Expression? rhs;

  Write(this.lhs, this.rhs, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    lhs.preVisit(visitor,
        disposition: rhs == null
            ? _LValueDisposition.readWrite
            : _LValueDisposition.write);
    rhs?.preVisit(visitor);
  }

  @override
  String toString() => '$lhs = $rhs';

  @override
  ExpressionTypeAnalysisResult<Type> visit(Harness h, Type context) {
    var rhs = this.rhs;
    Type type;
    if (rhs == null) {
      // We are simulating an increment/decrement operation.
      // TODO(paulberry): Make a separate node type for this.
      type = h.typeAnalyzer.analyzeExpression(lhs, h.typeAnalyzer.unknownType);
    } else {
      type = h.typeAnalyzer.analyzeExpression(rhs, h.typeAnalyzer.unknownType);
    }
    lhs._visitWrite(h, this, type, rhs);
    // TODO(paulberry): null shorting
    return new SimpleTypeAnalysisResult<Type>(type: type);
  }
}

/// Enum representing the different ways an [LValue] might be used.
enum _LValueDisposition {
  /// The [LValue] is being read from only, not written to.  This happens if it
  /// appears in a place where an ordinary expression is expected.
  read,

  /// The [LValue] is being written to only, not read from.  This happens if it
  /// appears on the left hand side of `=`.
  write,

  /// The [LValue] is being both read from and written to.  This happens if it
  /// appears on the left and side of `op=` (where `op` is some operator), or as
  /// the target of `++` or `--`.
  readWrite,
}

class _MiniAstErrors
    implements
        TypeAnalyzerErrors<Node, Statement, Expression, Var, Type, Pattern,
            void>,
        VariableBinderErrors<Node, Var> {
  final Set<String> _accumulatedErrors = {};

  /// If [assertInErrorRecovery] is called prior to any errors being reported,
  /// the stack trace is captured and stored in this variable, so that if no
  /// errors are reported by the end of running the test, we can use it to
  /// highlight the point of failure.
  StackTrace? _assertInErrorRecoveryStack;

  @override
  void assertInErrorRecovery() {
    if (_accumulatedErrors.isEmpty) {
      _assertInErrorRecoveryStack ??= StackTrace.current;
    }
  }

  @override
  void caseExpressionTypeMismatch(
      {required Expression scrutinee,
      required Expression caseExpression,
      required Type scrutineeType,
      required Type caseExpressionType,
      required bool nullSafetyEnabled}) {
    _recordError('caseExpressionTypeMismatch', {
      'scrutinee': scrutinee,
      'caseExpression': caseExpression,
      'scrutineeType': scrutineeType,
      'caseExpressionType': caseExpressionType,
      'nullSafetyEnabled': nullSafetyEnabled,
    });
  }

  @override
  void duplicateAssignmentPatternVariable({
    required Var variable,
    required Pattern original,
    required Pattern duplicate,
  }) {
    _recordError('duplicateAssignmentPatternVariable', {
      'variable': variable,
      'original': original,
      'duplicate': duplicate,
    });
  }

  @override
  void duplicateRecordPatternField({
    required Pattern objectOrRecordPattern,
    required String name,
    required covariant RecordPatternField original,
    required covariant RecordPatternField duplicate,
  }) {
    _recordError('duplicateRecordPatternField', {
      'objectOrRecordPattern': objectOrRecordPattern,
      'name': name,
      'original': original,
      'duplicate': duplicate,
    });
  }

  @override
  void duplicateRestPattern({
    required Pattern mapOrListPattern,
    required Node original,
    required Node duplicate,
  }) {
    _recordError('duplicateRestPattern', {
      'mapOrListPattern': mapOrListPattern,
      'original': original,
      'duplicate': duplicate,
    });
  }

  @override
  void duplicateVariablePattern({
    required String name,
    required Var original,
    required Var duplicate,
  }) {
    _recordError('duplicateVariablePattern', {
      'name': name,
      'original': original,
      'duplicate': duplicate,
    });
  }

  @override
  void emptyMapPattern({
    required Pattern pattern,
  }) {
    _recordError('emptyMapPattern', {
      'pattern': pattern,
    });
  }

  @override
  void inconsistentJoinedPatternVariable({
    required covariant PatternVariableJoin variable,
    required Var component,
  }) {
    _recordError('inconsistentJoinedPatternVariable', {
      'variable': '$variable',
      'component': component,
    });
  }

  @override
  void logicalOrPatternBranchMissingVariable({
    required Node node,
    required bool hasInLeft,
    required String name,
    required Var variable,
  }) {
    _recordError('logicalOrPatternBranchMissingVariable', {
      'node': node,
      'hasInLeft': hasInLeft,
      'name': name,
      'variable': variable,
    });
  }

  @override
  void matchedTypeIsStrictlyNonNullable({
    required Pattern pattern,
    required Type matchedType,
  }) {
    _recordError('matchedTypeIsStrictlyNonNullable', {
      'pattern': pattern,
      'matchedType': matchedType,
    });
  }

  @override
  void matchedTypeIsSubtypeOfRequired({
    required Pattern pattern,
    required Type matchedType,
    required Type requiredType,
  }) {
    _recordError('matchedTypeIsSubtypeOfRequired', {
      'pattern': pattern,
      'matchedType': matchedType,
      'requiredType': requiredType,
    });
  }

  @override
  void nonBooleanCondition({required Expression node}) {
    _recordError('nonBooleanCondition', {'node': node});
  }

  @override
  void patternForInExpressionIsNotIterable({
    required Node node,
    required Expression expression,
    required Type expressionType,
  }) {
    _recordError('patternForInExpressionIsNotIterable', {
      'node': node,
      'expression': expression,
      'expressionType': expressionType,
    });
  }

  @override
  void patternTypeMismatchInIrrefutableContext(
      {required Node pattern,
      required Node context,
      required Type matchedType,
      required Type requiredType}) {
    _recordError('patternTypeMismatchInIrrefutableContext', {
      'pattern': pattern,
      'context': context,
      'matchedType': matchedType,
      'requiredType': requiredType,
    });
  }

  @override
  void refutablePatternInIrrefutableContext(
      {required Node pattern, required Node context}) {
    _recordError('refutablePatternInIrrefutableContext',
        {'pattern': pattern, 'context': context});
  }

  @override
  void relationalPatternOperandTypeNotAssignable({
    required Pattern pattern,
    required Type operandType,
    required Type parameterType,
  }) {
    _recordError('relationalPatternOperandTypeNotAssignable', {
      'pattern': pattern,
      'operandType': operandType,
      'parameterType': parameterType,
    });
  }

  @override
  void relationalPatternOperatorReturnTypeNotAssignableToBool({
    required Pattern pattern,
    required Type returnType,
  }) {
    _recordError('relationalPatternOperatorReturnTypeNotAssignableToBool', {
      'pattern': pattern,
      'returnType': returnType,
    });
  }

  @override
  void restPatternInMap({required Pattern node, required Node element}) {
    _recordError('restPatternInMap', {'node': node, 'element': element});
  }

  @override
  void switchCaseCompletesNormally(
      {required covariant SwitchStatement node, required int caseIndex}) {
    _recordError(
        'switchCaseCompletesNormally', {'node': node, 'caseIndex': caseIndex});
  }

  @override
  void unnecessaryWildcardPattern({
    required Pattern pattern,
    required UnnecessaryWildcardKind kind,
  }) {
    _recordError('unnecessaryWildcardPattern', {
      'pattern': pattern,
      'kind': kind,
    });
  }

  void _recordError(String name, Map<String, Object?> namedArguments) {
    String argumentStr(Object? argument) {
      if (argument is bool) {
        return '$argument';
      } else if (argument is int) {
        return '$argument';
      } else if (argument is Enum) {
        return argument.name;
      } else if (argument is Node) {
        return argument.errorId;
      } else if (argument is Type) {
        return argument.type;
      } else {
        return argument as String;
      }
    }

    String argumentsStr = namedArguments.entries.map((entry) {
      return '${entry.key}: ${argumentStr(entry.value)}';
    }).join(', ');

    var errorText = '$name($argumentsStr)';

    _assertInErrorRecoveryStack = null;
    if (!_accumulatedErrors.add(errorText)) {
      fail('Same error reported twice: $errorText');
    }
  }
}

class _MiniAstTypeAnalyzer
    with TypeAnalyzer<Node, Statement, Expression, Var, Type, Pattern, void> {
  final Harness _harness;

  @override
  final _MiniAstErrors errors = _MiniAstErrors();

  Statement? _currentBreakTarget;

  Statement? _currentContinueTarget;

  final _irBuilder = MiniIrBuilder();

  @override
  late final Type boolType = Type('bool');

  @override
  late final Type doubleType = Type('double');

  @override
  late final Type dynamicType = Type('dynamic');

  @override
  late final Type intType = Type('int');

  @override
  late final Type neverType = Type('Never');

  late final Type nullType = Type('Null');

  @override
  late final Type objectQuestionType = Type('Object?');

  @override
  late final Type unknownType = Type('?');

  @override
  final TypeAnalyzerOptions options;

  _MiniAstTypeAnalyzer(this._harness, this.options);

  @override
  Type get errorType => Type('error');

  @override
  FlowAnalysis<Node, Statement, Expression, Var, Type> get flow =>
      _harness.flow;

  @override
  MiniAstOperations get operations => _harness._operations;

  Type get thisType => _harness._thisType!;

  void analyzeAssertStatement(
      Statement node, Expression condition, Expression? message) {
    flow.assert_begin();
    analyzeExpression(condition, unknownType);
    flow.assert_afterCondition(condition);
    if (message != null) {
      analyzeExpression(message, unknownType);
    } else {
      handleNoMessage(node);
    }
    flow.assert_end();
  }

  SimpleTypeAnalysisResult<Type> analyzeBinaryExpression(
      Expression node, Expression lhs, String operatorName, Expression rhs) {
    bool isEquals = false;
    bool isNot = false;
    bool isLogical = false;
    bool isAnd = false;
    switch (operatorName) {
      case '==':
        isEquals = true;
        break;
      case '!=':
        isEquals = true;
        isNot = true;
        operatorName = '==';
        break;
      case '&&':
        isLogical = true;
        isAnd = true;
        break;
      case '||':
        isLogical = true;
        break;
    }
    if (operatorName == '==') {
      isEquals = true;
    } else if (operatorName == '!=') {
      isEquals = true;
      isNot = true;
      operatorName = '==';
    }
    if (isLogical) {
      flow.logicalBinaryOp_begin();
    }
    var leftType = analyzeExpression(lhs, unknownType);
    ExpressionInfo<Type>? leftInfo;
    if (isEquals) {
      leftInfo = flow.equalityOperand_end(lhs, leftType);
    } else if (isLogical) {
      flow.logicalBinaryOp_rightBegin(lhs, node, isAnd: isAnd);
    }
    var rightType = analyzeExpression(rhs, unknownType);
    if (isEquals) {
      flow.equalityOperation_end(
          node, leftInfo, flow.equalityOperand_end(rhs, rightType),
          notEqual: isNot);
    } else if (isLogical) {
      flow.logicalBinaryOp_end(node, rhs, isAnd: isAnd);
    }
    return new SimpleTypeAnalysisResult<Type>(type: boolType);
  }

  void analyzeBlock(Iterable<Statement> statements) {
    for (var statement in statements) {
      dispatchStatement(statement);
    }
  }

  Type analyzeBoolLiteral(Expression node, bool value) {
    flow.booleanLiteral(node, value);
    return boolType;
  }

  void analyzeBreakStatement(Statement? target) {
    flow.handleBreak(target);
  }

  SimpleTypeAnalysisResult<Type> analyzeConditionalExpression(Expression node,
      Expression condition, Expression ifTrue, Expression ifFalse) {
    flow.conditional_conditionBegin();
    analyzeExpression(condition, unknownType);
    flow.conditional_thenBegin(condition, node);
    var ifTrueType = analyzeExpression(ifTrue, unknownType);
    flow.conditional_elseBegin(ifTrue, ifTrueType);
    var ifFalseType = analyzeExpression(ifFalse, unknownType);
    var lubType = leastUpperBound(ifTrueType, ifFalseType);
    flow.conditional_end(node, lubType, ifFalse, ifFalseType);
    return new SimpleTypeAnalysisResult<Type>(type: lubType);
  }

  void analyzeContinueStatement(Statement? target) {
    flow.handleContinue(target);
  }

  void analyzeDoLoop(Statement node, Statement body, Expression condition) {
    flow.doStatement_bodyBegin(node);
    _visitLoopBody(node, body);
    flow.doStatement_conditionBegin();
    analyzeExpression(condition, unknownType);
    flow.doStatement_end(condition);
  }

  void analyzeExpressionStatement(Expression expression) {
    analyzeExpression(expression, unknownType);
  }

  SimpleTypeAnalysisResult<Type> analyzeIfNullExpression(
      Expression node, Expression lhs, Expression rhs) {
    var leftType = analyzeExpression(lhs, unknownType);
    flow.ifNullExpression_rightBegin(lhs, leftType);
    var rightType = analyzeExpression(rhs, unknownType);
    flow.ifNullExpression_end();
    return new SimpleTypeAnalysisResult<Type>(
        type: leastUpperBound(
            flow.operations.promoteToNonNull(leftType), rightType));
  }

  void analyzeLabeledStatement(Statement node, Statement body) {
    flow.labeledStatement_begin(node);
    dispatchStatement(body);
    flow.labeledStatement_end();
  }

  SimpleTypeAnalysisResult<Type> analyzeLogicalNot(
      Expression node, Expression expression) {
    analyzeExpression(expression, unknownType);
    flow.logicalNot_end(node, expression);
    return new SimpleTypeAnalysisResult<Type>(type: boolType);
  }

  SimpleTypeAnalysisResult<Type> analyzeNonNullAssert(
      Expression node, Expression expression) {
    var type = analyzeExpression(expression, unknownType);
    flow.nonNullAssert_end(expression);
    return new SimpleTypeAnalysisResult<Type>(
        type: flow.operations.promoteToNonNull(type));
  }

  SimpleTypeAnalysisResult<Type> analyzeNullLiteral(Expression node) {
    flow.nullLiteral(node, nullType);
    return new SimpleTypeAnalysisResult<Type>(type: nullType);
  }

  SimpleTypeAnalysisResult<Type> analyzeParenthesizedExpression(
      Expression node, Expression expression, Type context) {
    var type = analyzeExpression(expression, context);
    flow.parenthesizedExpression(node, expression);
    return new SimpleTypeAnalysisResult<Type>(type: type);
  }

  ExpressionTypeAnalysisResult<Type> analyzePropertyGet(
      Expression node, Expression receiver, String propertyName) {
    var receiverType = analyzeExpression(receiver, unknownType);
    var member = _lookupMember(node, receiverType, propertyName);
    var memberType = member?._type ?? dynamicType;
    var promotedType = flow.propertyGet(node,
        ExpressionPropertyTarget(receiver), propertyName, member, memberType);
    // TODO(paulberry): handle null shorting
    return new SimpleTypeAnalysisResult<Type>(type: promotedType ?? memberType);
  }

  void analyzeReturnStatement() {
    flow.handleExit();
  }

  SimpleTypeAnalysisResult<Type> analyzeThis(Expression node) {
    var thisType = this.thisType;
    flow.thisOrSuper(node, thisType, isSuper: false);
    return new SimpleTypeAnalysisResult<Type>(type: thisType);
  }

  SimpleTypeAnalysisResult<Type> analyzeThisOrSuperPropertyGet(
      Expression node, String propertyName,
      {required bool isSuperAccess}) {
    var member = _lookupMember(node, thisType, propertyName);
    var memberType = member?._type ?? dynamicType;
    var promotedType = flow.propertyGet(
        node,
        isSuperAccess
            ? SuperPropertyTarget.singleton
            : ThisPropertyTarget.singleton,
        propertyName,
        member,
        memberType);
    return new SimpleTypeAnalysisResult<Type>(type: promotedType ?? memberType);
  }

  SimpleTypeAnalysisResult<Type> analyzeThrow(
      Expression node, Expression expression) {
    analyzeExpression(expression, unknownType);
    flow.handleExit();
    return new SimpleTypeAnalysisResult<Type>(type: neverType);
  }

  void analyzeTryStatement(Statement node, Statement body,
      Iterable<CatchClause> catchClauses, Statement? finallyBlock) {
    if (finallyBlock != null) {
      flow.tryFinallyStatement_bodyBegin();
    }
    if (catchClauses.isNotEmpty) {
      flow.tryCatchStatement_bodyBegin();
    }
    dispatchStatement(body);
    if (catchClauses.isNotEmpty) {
      flow.tryCatchStatement_bodyEnd(body);
      for (var catch_ in catchClauses) {
        flow.tryCatchStatement_catchBegin(catch_.exception, catch_.stackTrace);
        dispatchStatement(catch_.body);
        flow.tryCatchStatement_catchEnd();
      }
      flow.tryCatchStatement_end();
    }
    if (finallyBlock != null) {
      flow.tryFinallyStatement_finallyBegin(
          catchClauses.isNotEmpty ? node : body);
      dispatchStatement(finallyBlock);
      flow.tryFinallyStatement_end();
    } else {
      handleNoStatement(node);
    }
  }

  SimpleTypeAnalysisResult<Type> analyzeTypeCast(
      Expression node, Expression expression, Type type) {
    analyzeExpression(expression, unknownType);
    flow.asExpression_end(expression, type);
    return new SimpleTypeAnalysisResult<Type>(type: type);
  }

  SimpleTypeAnalysisResult<Type> analyzeTypeTest(
      Expression node, Expression expression, Type type,
      {bool isInverted = false}) {
    analyzeExpression(expression, unknownType);
    flow.isExpression_end(node, expression, isInverted, type);
    return new SimpleTypeAnalysisResult<Type>(type: boolType);
  }

  SimpleTypeAnalysisResult<Type> analyzeVariableGet(
      Expression node, Var variable, void Function(Type?)? callback) {
    var promotedType = flow.variableRead(node, variable);
    callback?.call(promotedType);
    return new SimpleTypeAnalysisResult<Type>(
        type: promotedType ?? variable.type);
  }

  void analyzeWhileLoop(Statement node, Expression condition, Statement body) {
    flow.whileStatement_conditionBegin(node);
    analyzeExpression(condition, unknownType);
    flow.whileStatement_bodyBegin(node, condition);
    _visitLoopBody(node, body);
    flow.whileStatement_end();
  }

  @override
  shared.RecordType<Type>? asRecordType(Type type) {
    if (type is RecordType) {
      return shared.RecordType<Type>(
        positional: type.positional,
        named: type.named.entries.map((entry) {
          return shared.NamedType(
            entry.key,
            entry.value,
          );
        }).toList(),
      );
    }
    return null;
  }

  @override
  void dispatchCollectionElement(
    covariant CollectionElement element,
    covariant CollectionElementContext context,
  ) {
    _irBuilder.guard(element, () => element.visit(_harness, context));
  }

  @override
  ExpressionTypeAnalysisResult<Type> dispatchExpression(
          Expression expression, Type context) =>
      _irBuilder.guard(expression, () => expression.visit(_harness, context));

  @override
  void dispatchPattern(SharedMatchContext context, covariant Pattern node) {
    return node.visit(_harness, context);
  }

  @override
  Type dispatchPatternSchema(covariant Pattern node) {
    return node.computeSchema(_harness);
  }

  @override
  void dispatchStatement(Statement statement) =>
      _irBuilder.guard(statement, () => statement.visit(_harness));

  @override
  Type downwardInferObjectPatternRequiredType({
    required Type matchedType,
    required covariant ObjectPattern pattern,
  }) {
    var requiredType = pattern.requiredType;
    if (requiredType.args.isNotEmpty) {
      return requiredType;
    } else {
      return operations.downwardInfer(requiredType.name, matchedType);
    }
  }

  void finish() {
    flow.finish();
  }

  @override
  void finishExpressionCase(Expression node, int caseIndex) {
    _irBuilder.apply(
        'case', [Kind.caseHead, Kind.expression], Kind.expressionCase,
        location: node.location);
  }

  @override
  void finishJoinedPatternVariable(
    covariant PatternVariableJoin variable, {
    required JoinedPatternVariableLocation location,
    required JoinedPatternVariableInconsistency inconsistency,
    required bool isFinal,
    required Type type,
  }) {
    variable.isFinal = isFinal;
    variable.type = type;
    variable.inconsistency = variable.inconsistency.maxWith(inconsistency);
  }

  @override
  shared.MapPatternEntry<Expression, Pattern>? getMapPatternEntry(
      Node element) {
    if (element is MapPatternEntry) {
      return shared.MapPatternEntry<Expression, Pattern>(
        key: element.key,
        value: element.value,
      );
    }
    return null;
  }

  @override
  Pattern? getRestPatternElementPattern(Node element) {
    return element is RestPatternElement ? element.pattern : null;
  }

  @override
  SwitchExpressionMemberInfo<Node, Expression, Var>
      getSwitchExpressionMemberInfo(
          covariant SwitchExpression node, int index) {
    var case_ = node.cases[index];
    return SwitchExpressionMemberInfo(
      head: CaseHeadOrDefaultInfo(
        pattern: case_.guardedPattern?.pattern,
        variables: case_.guardedPattern?.variables ?? {},
        guard: case_.guardedPattern?.guard,
      ),
      expression: case_.expression,
    );
  }

  @override
  SwitchStatementMemberInfo<Node, Statement, Expression, Var>
      getSwitchStatementMemberInfo(
          covariant SwitchStatement node, int caseIndex) {
    SwitchStatementMember case_ = node.cases[caseIndex];
    return SwitchStatementMemberInfo(
      heads: [
        for (var element in case_.elements)
          if (element is SwitchHeadCase)
            CaseHeadOrDefaultInfo(
              pattern: element.guardedPattern.pattern,
              variables: element.guardedPattern.variables,
              guard: element.guardedPattern.guard,
            )
          else
            CaseHeadOrDefaultInfo(
              pattern: null,
              variables: {},
              guard: null,
            )
      ],
      body: case_.body.statements,
      variables: case_._candidateVariables,
      hasLabels: case_.hasLabels,
    );
  }

  @override
  Type getVariableType(Var variable) {
    return variable.type;
  }

  @override
  void handle_ifCaseStatement_afterPattern({required covariant IfCase node}) {
    _irVariables(node, node._candidateVariables.values);
  }

  void handleAssignedVariablePattern(covariant VariablePattern node) {
    _irBuilder.atom(node.variable.name, Kind.variable, location: node.location);
    _irBuilder.apply('assignedVarPattern', [Kind.variable], Kind.pattern,
        location: node.location);
    assert(node.expectInferredType == null,
        "assigned variable patterns don't get an inferred type");
  }

  @override
  void handleCase_afterCaseHeads(
      covariant SwitchStatement node, int caseIndex, Iterable<Var> variables) {
    var case_ = node.cases[caseIndex];
    _irVariables(node, variables);
    _irBuilder.apply(
      'heads',
      [
        ...List.filled(case_.elements.length, Kind.caseHead),
        Kind.variables,
      ],
      Kind.caseHeads,
      location: node.location,
    );
  }

  @override
  void handleCaseHead(Node node,
      {required int caseIndex, required int subIndex}) {
    Iterable<Var> variables = [];
    if (node is SwitchExpression) {
      var guardedPattern = node.cases[caseIndex].guardedPattern;
      if (guardedPattern != null) {
        variables = guardedPattern.variables.values;
      }
    } else if (node is SwitchStatement) {
      var head = node.cases[caseIndex].elements[subIndex];
      if (head is SwitchHeadCase) {
        variables = head.guardedPattern.variables.values;
      }
    } else {
      throw UnimplementedError('(${node.runtimeType}) $node');
    }
    _irVariables(node, variables);

    _irBuilder.apply(
        'head', [Kind.pattern, Kind.expression, Kind.variables], Kind.caseHead,
        location: node.location);
  }

  void handleDeclaredVariablePattern(covariant VariablePattern node,
      {required Type matchedType, required Type staticType}) {
    _irBuilder.atom(node.variable.name, Kind.variable, location: node.location);
    _irBuilder.atom(matchedType.type, Kind.type, location: node.location);
    _irBuilder.atom(staticType.type, Kind.type, location: node.location);
    _irBuilder.apply(
        'varPattern', [Kind.variable, Kind.type, Kind.type], Kind.pattern,
        names: ['matchedType', 'staticType'], location: node.location);
    var expectInferredType = node.expectInferredType;
    if (expectInferredType != null) {
      expect(staticType.type, expectInferredType);
    }
  }

  @override
  void handleDefault(
    Node node, {
    required int caseIndex,
    required int subIndex,
  }) {
    _irBuilder.atom('default', Kind.caseHead, location: node.location);
  }

  @override
  void handleListPatternRestElement(
    Pattern container,
    covariant RestPatternElement restElement,
  ) {
    if (restElement.pattern != null) {
      _irBuilder.apply('...', [Kind.pattern], Kind.pattern,
          location: restElement.location);
    } else {
      _irBuilder.atom('...', Kind.pattern, location: restElement.location);
    }
  }

  @override
  void handleMapPatternEntry(
      Pattern container, Node entryElement, Type keyType) {
    _irBuilder.apply('mapPatternEntry', [Kind.expression, Kind.pattern],
        Kind.mapPatternElement,
        location: entryElement.location);
  }

  @override
  void handleMapPatternRestElement(
    Pattern container,
    covariant RestPatternElement restElement,
  ) {
    if (restElement.pattern != null) {
      _irBuilder.apply('...', [Kind.pattern], Kind.mapPatternElement,
          location: restElement.location);
    } else {
      _irBuilder.atom('...', Kind.mapPatternElement,
          location: restElement.location);
    }
  }

  @override
  void handleMergedStatementCase(covariant SwitchStatement node,
      {required int caseIndex, required bool isTerminating}) {
    var numStatements = node.cases[caseIndex].body.statements.length;
    if (!isTerminating) {
      _irBuilder.apply('synthetic-break', [], Kind.statement,
          location: node.location);
      numStatements++;
    }
    _irBuilder.apply(
        'block', List.filled(numStatements, Kind.statement), Kind.statement,
        location: node.location);
    _irBuilder.apply(
        'case', [Kind.caseHeads, Kind.statement], Kind.statementCase,
        location: node.location);
  }

  @override
  void handleNoCollectionElement(Node node) {
    _irBuilder.atom('noop', Kind.collectionElement, location: node.location);
  }

  void handleNoCondition(Node node) {
    _irBuilder.atom('true', Kind.expression, location: node.location);
  }

  @override
  void handleNoGuard(Node node, int caseIndex) {
    _irBuilder.atom('true', Kind.expression, location: node.location);
  }

  void handleNoInitializer(Node node) {
    _irBuilder.atom('uninitialized', Kind.statement, location: node.location);
  }

  void handleNoMessage(Node node) {
    _irBuilder.atom('failure', Kind.expression, location: node.location);
  }

  @override
  void handleNoStatement(Node node) {
    _irBuilder.atom('noop', Kind.statement, location: node.location);
  }

  @override
  void handleSwitchBeforeAlternative(
    Node node, {
    required int caseIndex,
    required int subIndex,
  }) {}

  @override
  void handleSwitchScrutinee(Type type) {}

  @override
  bool isAlwaysExhaustiveType(Type type) =>
      operations.isAlwaysExhaustiveType(type);

  @override
  bool isLegacySwitchExhaustive(
      covariant SwitchStatement node, Type expressionType) {
    return node.isLegacyExhaustive!;
  }

  @override
  bool isRestPatternElement(Node element) {
    return element is RestPatternElement;
  }

  @override
  bool isVariableFinal(Var node) {
    return node.isFinal;
  }

  @override
  bool isVariablePattern(Node pattern) => pattern is VariablePattern;

  @override
  Type iterableType(Type elementType) {
    return PrimaryType('Iterable', args: [elementType]);
  }

  Type leastUpperBound(Type t1, Type t2) => _harness._operations._lub(t1, t2);

  @override
  Type listType(Type elementType) => PrimaryType('List', args: [elementType]);

  _PropertyElement? lookupInterfaceMember(
      Node node, Type receiverType, String memberName) {
    return _harness.getMember(receiverType, memberName);
  }

  @override
  Type mapType({
    required Type keyType,
    required Type valueType,
  }) {
    return PrimaryType('Map', args: [keyType, valueType]);
  }

  @override
  RecordType recordType(
      {required List<Type> positional,
      required List<shared.NamedType<Type>> named}) {
    return RecordType(
      positional: positional,
      named: {for (var e in named) e.name: e.type},
    );
  }

  @override
  Type resolveObjectPatternPropertyGet({
    required Pattern objectPattern,
    required Type receiverType,
    required shared.RecordPatternField<Node, Pattern> field,
  }) {
    return _harness.getMember(receiverType, field.name!)?._type ?? dynamicType;
  }

  @override
  RelationalOperatorResolution<Type>? resolveRelationalPatternOperator(
      covariant RelationalPattern node, Type matchedValueType) {
    return _harness.resolveRelationalPatternOperator(
        matchedValueType, node.operator);
  }

  @override
  void setVariableType(Var variable, Type type) {
    variable.type = type;
  }

  @override
  Type streamType(Type elementType) {
    return PrimaryType('Stream', args: [elementType]);
  }

  @override
  String toString() => _irBuilder.toString();

  @override
  Type variableTypeFromInitializerType(Type type) {
    // Variables whose initializer has type `Null` receive the inferred type
    // `dynamic`.
    if (_harness._operations.classifyType(type) ==
        TypeClassification.nullOrEquivalent) {
      type = dynamicType;
    }
    // Variables whose initializer type includes a promoted type variable
    // receive the nearest supertype that could be expressed in Dart source code
    // (e.g. `T&int` is demoted to `T`).
    // TODO(paulberry): add language tests to verify that the behavior of
    // `type.recursivelyDemote` matches what the analyzer and CFE do.
    return type.recursivelyDemote(covariant: true) ?? type;
  }

  void _irVariables(Node node, Iterable<Var> variables) {
    var variableList = variables.toList();
    for (var variable in variableList) {
      _irBuilder.atom(variable.stringToCheckVariables, Kind.variable,
          location: variable.location);
    }
    _irBuilder.apply(
      'variables',
      List.filled(variableList.length, Kind.variable),
      Kind.variables,
      location: node.location,
    );
  }

  _PropertyElement? _lookupMember(
      Expression node, Type receiverType, String memberName) {
    return lookupInterfaceMember(node, receiverType, memberName);
  }

  void _visitLoopBody(Statement loop, Statement body) {
    var previousBreakTarget = _currentBreakTarget;
    var previousContinueTarget = _currentContinueTarget;
    _currentBreakTarget = loop;
    _currentContinueTarget = loop;
    dispatchStatement(body);
    _currentBreakTarget = previousBreakTarget;
    _currentContinueTarget = previousContinueTarget;
  }
}

/// Mini-ast representation of a class property.  Instances of this class are
/// used to represent class members in the flow analysis `promotableFields` set.
class _PropertyElement {
  /// The type of the property.
  final Type _type;

  _PropertyElement(this._type);
}

class _VariableBinder extends VariableBinder<Node, Var> {
  _VariableBinder({
    required super.errors,
  });

  @override
  Var joinPatternVariables({
    required Object? key,
    required List<Var> components,
    required JoinedPatternVariableInconsistency inconsistency,
  }) {
    var joinedVariable = components[0]._joinedVar;
    if (joinedVariable == null) {
      fail('No joined variable for ${components[0].location}');
    }
    joinedVariable._handleJoin(
      components: components,
      inconsistency: inconsistency,
    );
    return joinedVariable;
  }
}
