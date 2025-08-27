// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file implements the AST of a Dart-like language suitable for testing
/// flow analysis.  Callers may use the top level methods in this file to create
/// AST nodes and then feed them to [Harness.run] to run them through flow
/// analysis testing.
library;

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart'
    show
        CascadePropertyTarget,
        ExpressionInfo,
        ExpressionPropertyTarget,
        FlowAnalysis,
        PropertyTarget,
        SuperPropertyTarget,
        ThisPropertyTarget;
import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis_operations.dart';
import 'package:_fe_analyzer_shared/src/type_inference/assigned_variables.dart';
import 'package:_fe_analyzer_shared/src/type_inference/null_shorting.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analysis_result.dart'
    as shared;
import 'package:_fe_analyzer_shared/src/type_inference/type_analysis_result.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart'
    as shared;
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart'
    hide MapPatternEntry, RecordPatternField;
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer_operations.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_constraint.dart';
import 'package:_fe_analyzer_shared/src/type_inference/variable_bindings.dart';
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:test/test.dart';

import 'mini_ir.dart';
import 'mini_type_constraint_gatherer.dart';
import 'mini_types.dart';

final RegExp _locationRegExp = RegExp(
  '(file:)?[a-zA-Z0-9_./]+.dart:[0-9]+:[0-9]+',
);

SwitchHeadDefault get default_ =>
    SwitchHeadDefault._(location: computeLocation());

ConstExpression get nullLiteral =>
    new NullLiteral._(location: computeLocation());

Expression get this_ => new This._(location: computeLocation());

Statement assert_(ProtoExpression condition, [ProtoExpression? message]) {
  var location = computeLocation();
  return new Assert._(
    condition.asExpression(location: location),
    message?.asExpression(location: location),
    location: location,
  );
}

Statement block(List<ProtoStatement> statements) =>
    new Block._(statements, location: computeLocation());

Expression booleanLiteral(bool value) =>
    BooleanLiteral._(value, location: computeLocation());

Statement break_([Label? target]) =>
    new Break(target, location: computeLocation());

/// Creates a pseudo-expression whose function is to verify that flow analysis
/// considers [variable]'s assigned state to be [expectedAssignedState].
Expression checkAssigned(Var variable, bool expectedAssignedState) =>
    new CheckAssigned._(
      variable,
      expectedAssignedState,
      location: computeLocation(),
    );

/// Creates a pseudo-expression whose function is to verify that flow analysis
/// considers [promotable] to be un-promoted.
Expression checkNotPromoted(Promotable promotable) =>
    new CheckPromoted._(promotable, null, location: computeLocation());

/// Creates a pseudo-expression whose function is to verify that flow analysis
/// considers [promotable]'s assigned state to be promoted to [expectedTypeStr].
Expression checkPromoted(Promotable promotable, String? expectedTypeStr) =>
    new CheckPromoted._(
      promotable,
      expectedTypeStr,
      location: computeLocation(),
    );

Expression checkPromotionChain(
  Promotable promotable,
  List<String> expectedPromotionChain,
) => new CheckPromotionChain._(
  promotable,
  expectedPromotionChain,
  location: computeLocation(),
);

/// Creates a pseudo-expression whose function is to verify that flow analysis
/// considers the current location's reachability state to be
/// [expectedReachable].
Expression checkReachable(bool expectedReachable) =>
    new CheckReachable(expectedReachable, location: computeLocation());

/// Creates a pseudo-expression whose function is to verify that flow analysis
/// considers [variable]'s unassigned state to be [expectedUnassignedState].
Expression checkUnassigned(Var variable, bool expectedUnassignedState) =>
    new CheckUnassigned._(
      variable,
      expectedUnassignedState,
      location: computeLocation(),
    );

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
          stackLine.contains('flow_analysis_test.dart') ||
          stackLine.contains('type_constraint_gatherer_test.dart'),
      'Unexpected file: $stackLine',
    );
  }

  var match = _locationRegExp.firstMatch(stackLine);
  if (match == null) {
    throw AssertionError(
      '_locationRegExp failed to match $stackLine in $callStack',
    );
  }
  return match.group(0)!;
}

Statement continue_([Label? target]) =>
    new Continue._(target, location: computeLocation());

Statement declare(
  Var variable, {
  bool isLate = false,
  bool isFinal = false,
  String? type,
  ProtoExpression? initializer,
  String? expectInferredType,
}) {
  var location = computeLocation();
  return new VariableDeclaration._(
    variable: variable,
    isLate: isLate,
    isFinal: isFinal,
    declaredType: type == null ? null : Type(type),
    initializer: initializer?.asExpression(location: location),
    expectInferredType: expectInferredType,
    location: location,
  );
}

Statement do_(List<ProtoStatement> body, ProtoExpression condition) {
  var location = computeLocation();
  return Do._(
    Block._(body, location: location),
    condition.asExpression(location: location),
    location: location,
  );
}

Expression dotShorthandHead(String name) =>
    new DotShorthandHead._(name, location: computeLocation());

/// Creates a pseudo-expression having type [typeStr] that otherwise has no
/// effect on flow analysis.
ConstExpression expr(String typeStr) =>
    new PlaceholderExpression._(new Type(typeStr), location: computeLocation());

/// Creates a conventional `for` statement.  Optional boolean [forCollection]
/// indicates that this `for` statement is actually a collection element, so
/// `null` should be passed to [FlowAnalysis.for_bodyBegin].
Statement for_(
  ProtoStatement? initializer,
  ProtoExpression? condition,
  ProtoExpression? updater,
  List<ProtoStatement> body, {
  bool forCollection = false,
}) {
  var location = computeLocation();
  return new For._(
    initializer?.asStatement(location: location),
    condition?.asExpression(location: location),
    updater?.asExpression(location: location),
    Block._(body, location: location),
    forCollection,
    location: location,
  );
}

/// Creates a "for each" statement where the identifier being assigned to by the
/// iteration is not a local variable.
///
/// This models code like:
///     var x; // Top level variable
///     f(Iterable iterable) {
///       for (x in iterable) { ... }
///     }
Statement forEachWithNonVariable(
  ProtoExpression iterable,
  List<ProtoStatement> body,
) {
  var location = computeLocation();
  return new ForEach._(
    null,
    iterable.asExpression(location: location),
    Block._(body, location: location),
    false,
    location: location,
  );
}

/// Creates a "for each" statement where the identifier being assigned to by the
/// iteration is a variable that is being declared by the "for each" statement.
///
/// This models code like:
///     f(Iterable iterable) {
///       for (var x in iterable) { ... }
///     }
Statement forEachWithVariableDecl(
  Var variable,
  ProtoExpression iterable,
  List<ProtoStatement> body,
) {
  var location = computeLocation();
  return new ForEach._(
    variable,
    iterable.asExpression(location: location),
    block(body),
    true,
    location: location,
  );
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
  Var variable,
  ProtoExpression iterable,
  List<ProtoStatement> body,
) {
  var location = computeLocation();
  return new ForEach._(
    variable,
    iterable.asExpression(location: location),
    Block._(body, location: location),
    false,
    location: location,
  );
}

Statement if_(
  ProtoExpression condition,
  List<ProtoStatement> ifTrue, [
  List<ProtoStatement>? ifFalse,
]) {
  var location = computeLocation();
  return new If._(
    condition.asExpression(location: location),
    Block._(ifTrue, location: location),
    ifFalse == null ? null : Block._(ifFalse, location: location),
    location: location,
  );
}

Statement ifCase(
  ProtoExpression expression,
  PossiblyGuardedPattern pattern,
  List<ProtoStatement> ifTrue, [
  List<ProtoStatement>? ifFalse,
]) {
  var location = computeLocation();
  var guardedPattern = pattern._asGuardedPattern;
  return IfCase(
    expression.asExpression(location: location),
    guardedPattern.pattern,
    guardedPattern.guard,
    Block._(ifTrue, location: location),
    ifFalse != null ? Block._(ifFalse, location: location) : null,
    location: location,
  );
}

CollectionElement ifCaseElement(
  ProtoExpression expression,
  PossiblyGuardedPattern pattern,
  ProtoCollectionElement ifTrue, [
  ProtoCollectionElement? ifFalse,
]) {
  var location = computeLocation();
  var guardedPattern = pattern._asGuardedPattern;
  return new IfCaseElement(
    expression.asExpression(location: location),
    guardedPattern.pattern,
    guardedPattern.guard,
    ifTrue.asCollectionElement(location: location),
    ifFalse?.asCollectionElement(location: location),
    location: location,
  );
}

CollectionElement ifElement(
  ProtoExpression condition,
  ProtoCollectionElement ifTrue, [
  ProtoCollectionElement? ifFalse,
]) {
  var location = computeLocation();
  return new IfElement._(
    condition.asExpression(location: location),
    ifTrue.asCollectionElement(location: location),
    ifFalse?.asCollectionElement(location: location),
    location: location,
  );
}

ConstExpression intLiteral(int value, {bool? expectConversionToDouble}) =>
    new IntLiteral(
      value,
      expectConversionToDouble: expectConversionToDouble,
      location: computeLocation(),
    );

/// Creates a list literal containing the given [elements].
///
/// [elementType] is the explicit type argument of the list literal.
/// TODO(paulberry): support list literals with an inferred type argument.
Expression listLiteral(
  List<ProtoCollectionElement> elements, {
  required String elementType,
}) {
  var location = computeLocation();
  return ListLiteral._(
    [
      for (var element in elements)
        element.asCollectionElement(location: location),
    ],
    Type(elementType),
    location: location,
  );
}

Pattern listPattern(List<ListPatternElement> elements, {String? elementType}) =>
    ListPattern._(
      elementType == null ? null : Type(elementType),
      elements,
      location: computeLocation(),
    );

Expression localFunction(List<ProtoStatement> body) {
  var location = computeLocation();
  return LocalFunction._(Block._(body, location: location), location: location);
}

/// Creates a map entry containing the given [key] and [value] subexpressions.
CollectionElement mapEntry(
  ProtoExpression key,
  ProtoExpression value, {
  bool isKeyNullAware = false,
}) {
  var location = computeLocation();
  return MapEntry._(
    key.asExpression(location: location),
    value.asExpression(location: location),
    isKeyNullAware: isKeyNullAware,
    location: location,
  );
}

/// Creates a map literal containing the given [elements].
///
/// [keyType] and [valueType] are the explicit type arguments of the map
/// literal. TODO(paulberry): support map literals with inferred type arguments.
Expression mapLiteral(
  List<ProtoCollectionElement> elements, {
  required String keyType,
  required String valueType,
}) {
  var location = computeLocation();
  return MapLiteral._(
    [
      for (var element in elements)
        element.asCollectionElement(location: location),
    ],
    Type(keyType),
    Type(valueType),
    location: location,
  );
}

Pattern mapPattern(
  List<MapPatternElement> elements, {
  String? keyType,
  String? valueType,
}) {
  var location = computeLocation();
  return MapPattern._(
    keyType == null && valueType == null
        ? null
        : (keyType: Type(keyType!), valueType: Type(valueType!)),
    elements,
    location: location,
  );
}

MapPatternElement mapPatternEntry(ProtoExpression key, Pattern value) {
  var location = computeLocation();
  return MapPatternEntry._(
    key.asExpression(location: location),
    value,
    location: location,
  );
}

Pattern mapPatternWithTypeArguments({
  required String keyType,
  required String valueType,
  required List<MapPatternElement> elements,
}) {
  var location = computeLocation();
  return MapPattern._(
    (keyType: Type(keyType), valueType: Type(valueType)),
    elements,
    location: location,
  );
}

Pattern objectPattern({
  required String requiredType,
  required List<RecordPatternField> fields,
}) {
  var parsedType = Type(requiredType);
  if (parsedType is! PrimaryType || parsedType.isQuestionType) {
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
  ProtoExpression expression,
  List<ProtoStatement> body, {
  bool hasAwait = false,
}) {
  var location = computeLocation();
  return new PatternForIn(
    pattern,
    expression.asExpression(location: location),
    Block._(body, location: location),
    hasAwait: hasAwait,
    location: location,
  );
}

/// Creates a "pattern-for-in" element.
///
/// This models code like:
///     void f(Iterable<(int, String)> iterable) {
///       [for (var (a, b) in iterable) '$a $b']
///     }
CollectionElement patternForInElement(
  Pattern pattern,
  ProtoExpression expression,
  ProtoCollectionElement body, {
  bool hasAwait = false,
}) {
  var location = computeLocation();
  return new PatternForInElement(
    pattern,
    expression.asExpression(location: location),
    body.asCollectionElement(location: location),
    hasAwait: hasAwait,
    location: location,
  );
}

Statement patternVariableDeclaration(
  Pattern pattern,
  ProtoExpression initializer, {
  bool isFinal = false,
}) {
  var location = computeLocation();
  return new PatternVariableDeclaration._(
    pattern,
    initializer.asExpression(location: location),
    isFinal: isFinal,
    location: location,
  );
}

Pattern recordPattern(List<RecordPatternField> fields) =>
    RecordPattern._(fields, location: computeLocation());

Pattern relationalPattern(
  String operator,
  ProtoExpression operand, {
  String? errorId,
}) {
  var location = computeLocation();
  var result = RelationalPattern._(
    operator,
    operand.asExpression(location: location),
    location: location,
  );
  if (errorId != null) {
    result.errorId = errorId;
  }
  return result;
}

/// Creates a "rest" pattern with optional [subPattern], for use in a list
/// pattern.
///
/// Although using a rest pattern inside a map pattern is an error, it's allowed
/// syntactically (since this leads to better error recovery). To facilitate
/// testing of the error recovery logic, the returned type ([RestPattern]) may
/// be used were a [MapPatternElement] is expected.
RestPattern restPattern([Pattern? subPattern]) =>
    RestPattern._(subPattern, location: computeLocation());

Statement return_() => new Return._(location: computeLocation());

/// Models a call to a generic Dart function that takes two arguments and
/// returns the second argument; in other words, a function defined this way:
///
///     T second(dynamic x, T y) => y;
///
/// This can be useful in situations where a test needs to verify certain
/// properties, or establish certain preconditions, before the analysis reaches
/// a certain subexpression.
Expression second(ProtoExpression first, ProtoExpression second) {
  var location = computeLocation();
  return Second._(
    first.asExpression(location: location),
    second.asExpression(location: location),
    location: location,
  );
}

PromotableLValue superProperty(String name) => new ThisOrSuperProperty._(
  name,
  location: computeLocation(),
  isSuperAccess: true,
);

Statement switch_(
  ProtoExpression expression,
  List<SwitchStatementMember> cases, {
  bool? isLegacyExhaustive,
  bool? expectHasDefault,
  bool? expectIsExhaustive,
  bool? expectLastCaseTerminates,
  bool? expectRequiresExhaustivenessValidation,
  String? expectScrutineeType,
}) {
  var location = computeLocation();
  return new SwitchStatement(
    expression.asExpression(location: location),
    cases,
    isLegacyExhaustive,
    location: location,
    expectHasDefault: expectHasDefault,
    expectIsExhaustive: expectIsExhaustive,
    expectLastCaseTerminates: expectLastCaseTerminates,
    expectRequiresExhaustivenessValidation:
        expectRequiresExhaustivenessValidation,
    expectScrutineeType: expectScrutineeType,
  );
}

Expression switchExpr(ProtoExpression expression, List<ExpressionCase> cases) {
  var location = computeLocation();
  return new SwitchExpression._(
    expression.asExpression(location: location),
    cases,
    location: location,
  );
}

SwitchStatementMember switchStatementMember(
  List<ProtoSwitchHead> cases,
  List<ProtoStatement> body, {
  bool hasLabels = false,
}) {
  var location = computeLocation();
  return SwitchStatementMember._(
    [for (var case_ in cases) case_.asSwitchHead],
    Block._(body, location: location),
    hasLabels: hasLabels,
    location: computeLocation(),
  );
}

PromotableLValue thisProperty(String name) => new ThisOrSuperProperty._(
  name,
  location: computeLocation(),
  isSuperAccess: false,
);

Expression throw_(ProtoExpression operand) {
  var location = computeLocation();
  return new Throw._(
    operand.asExpression(location: location),
    location: location,
  );
}

TryBuilder try_(List<ProtoStatement> body) {
  var location = computeLocation();
  return new TryStatementImpl(
    Block._(body, location: location),
    [],
    null,
    location: location,
  );
}

Statement while_(ProtoExpression condition, List<ProtoStatement> body) {
  var location = computeLocation();
  return new While._(
    condition.asExpression(location: location),
    Block._(body, location: location),
    location: location,
  );
}

Pattern wildcard({String? type, String? expectInferredType}) {
  return WildcardPattern._(
    declaredType: type == null ? null : Type(type),
    expectInferredType: expectInferredType,
    location: computeLocation(),
  );
}

typedef SharedMatchContext =
    shared.MatchContext<Node, Expression, Pattern, SharedTypeView, Var>;

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
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
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
      'assert',
      [Kind.expression, Kind.expression],
      Kind.statement,
      location: location,
    );
  }
}

class Block extends Statement {
  final List<Statement> statements;

  Block._(List<ProtoStatement> statements, {required super.location})
    : statements = [
        for (var s in statements) s.asStatement(location: location),
      ];

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
      'block',
      List.filled(statements.length, Kind.statement),
      Kind.statement,
      location: location,
    );
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
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
    var type = h.typeAnalyzer.analyzeBoolLiteral(this, value);
    h.irBuilder.atom('$value', Kind.expression, location: location);
    return new ExpressionTypeAnalysisResult(type: SharedTypeView(type));
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
    h.typeAnalyzer.analyzeBreakStatement(
      target == null
          ? h.typeAnalyzer._currentBreakTarget
          : target._getBinding(),
    );
    h.irBuilder.apply('break', [], Kind.statement, location: location);
  }
}

/// Representation of a cascade expression in the pseudo-Dart language used for
/// flow analysis testing.
class Cascade extends Expression {
  /// The expression appearing before the first `..` (or `?..`).
  final Expression target;

  /// List of the cascade sections. Each cascade section is an ordinary
  /// expression, built around a [Property] or [InvokeMethod] expression whose
  /// target is a [CascadePlaceholder]. See [CascadePlaceholder] for more
  /// information.
  final List<Expression> sections;

  /// Indicates whether the cascade is null-aware (i.e. its first section is
  /// preceded by `?..` instead of `..`).
  final bool isNullAware;

  Cascade._(
    this.target,
    this.sections, {
    required this.isNullAware,
    required super.location,
  });

  @override
  void preVisit(PreVisitor visitor) {
    target.preVisit(visitor);
    for (var section in sections) {
      section.preVisit(visitor);
    }
  }

  @override
  String toString() {
    return [target, if (isNullAware) '?', ...sections].join('');
  }

  @override
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
    // Form the IR for evaluating the LHS
    var targetType = h.typeAnalyzer.analyzeExpression(target, schema);
    var previousCascadeTargetIR = h.typeAnalyzer._currentCascadeTargetIR;
    var previousCascadeType = h.typeAnalyzer._currentCascadeTargetType;
    // Create a let-variable that will be initialized to the value of the LHS
    var targetTmp = h.typeAnalyzer._currentCascadeTargetIR = h.irBuilder
        .allocateTmp(location: location);
    h.typeAnalyzer._currentCascadeTargetType = h.flow
        .cascadeExpression_afterTarget(
          target,
          targetType,
          isNullAware: isNullAware,
        );
    if (isNullAware) {
      h.flow.nullAwareAccess_rightBegin(target, targetType);
      // Push `targetTmp == null` and `targetTmp` on the IR builder stack,
      // because they'll be needed later to form the conditional expression that
      // does the null-aware guarding.
      h.irBuilder.readTmp(targetTmp, location: location);
      h.irBuilder.atom('null', Kind.expression, location: location);
      h.irBuilder.apply(
        '==',
        [Kind.expression, Kind.expression],
        Kind.expression,
        location: location,
      );
      h.irBuilder.readTmp(targetTmp, location: location);
    }
    // Form the IR for evaluating each section
    List<MiniIRTmp> sectionTmps = [];
    for (var section in sections) {
      h.typeAnalyzer.analyzeExpression(section, h.operations.unknownType);
      // Create a let-variable that will be initialized to the value of the
      // section (which will be discarded)
      sectionTmps.add(h.irBuilder.allocateTmp(location: location));
    }
    // For the final IR, `let targetTmp = target in let section1Tmp = section1
    // in section2Tmp = section2 ... in targetTmp`, or, for null-aware cascades,
    // `let targetTmp = target in targetTmp == null ? targetTmp : let
    // section1Tmp = section1 in section2Tmp = section2 ... in targetTmp`.
    h.irBuilder.readTmp(targetTmp, location: location);
    for (int i = sectionTmps.length; i-- > 0;) {
      h.irBuilder.let(sectionTmps[i], location: location);
    }
    if (isNullAware) {
      h.irBuilder.apply(
        'if',
        [Kind.expression, Kind.expression, Kind.expression],
        Kind.expression,
        location: location,
      );
      h.flow.nullAwareAccess_end();
    }
    h.irBuilder.let(targetTmp, location: location);
    h.flow.cascadeExpression_end(this);
    h.typeAnalyzer._currentCascadeTargetIR = previousCascadeTargetIR;
    h.typeAnalyzer._currentCascadeTargetType = previousCascadeType;
    return ExpressionTypeAnalysisResult(type: targetType);
  }
}

/// Representation of the implicit reference to a cascade target in a cascade
/// section, in the pseudo-Dart language used for flow analysis testing.
///
/// For example, in the cascade expression `x..f()`, the cascade section `..f()`
/// is represented as an [InvokeMethod] expression whose `target` is a
/// [CascadePlaceholder].
class CascadePlaceholder extends Expression {
  CascadePlaceholder._({required super.location});

  @override
  void preVisit(PreVisitor visitor) {}

  @override
  String toString() {
    // We use an empty string as the string representation of a cascade
    // placeholder. This ensures that in a cascade expression like `x..f()`, the
    // cascade section will have the string representation `..f()`.
    return '.';
  }

  @override
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
    h.irBuilder.readTmp(
      h.typeAnalyzer._currentCascadeTargetIR!,
      location: location,
    );
    return ExpressionTypeAnalysisResult(
      type: h.typeAnalyzer._currentCascadeTargetType!,
    );
  }
}

class CastPattern extends Pattern {
  final Pattern inner;

  final Type type;

  CastPattern(this.inner, this.type, {required super.location}) : super._();

  @override
  SharedTypeSchemaView computeSchema(Harness h) =>
      h.typeAnalyzer.analyzeCastPatternSchema();

  @override
  void preVisit(
    PreVisitor visitor,
    VariableBinder<Node, Var> variableBinder, {
    required bool isInAssignment,
  }) {
    inner.preVisit(visitor, variableBinder, isInAssignment: isInAssignment);
  }

  @override
  PatternResult visit(Harness h, SharedMatchContext context) {
    var analysisResult = h.typeAnalyzer.analyzeCastPattern(
      context: context,
      pattern: this,
      innerPattern: inner,
      requiredType: SharedTypeView(type),
    );
    var matchedType = analysisResult.matchedValueType.unwrapTypeView<Type>();
    h.irBuilder.atom(type.type, Kind.type, location: location);
    h.irBuilder.atom(matchedType.type, Kind.type, location: location);
    h.irBuilder.apply(
      'castPattern',
      [Kind.pattern, Kind.type, Kind.type],
      Kind.pattern,
      names: ['matchedType'],
      location: location,
    );
    return analysisResult;
  }

  @override
  String _debugString({required bool needsKeywordOrType}) =>
      '${inner._debugString(needsKeywordOrType: needsKeywordOrType)} as '
      '${type.type}';
}

/// Representation of a single catch clause in a try/catch statement.  Use
/// [TryBuilder.catch_] to create instances of this class.
class CatchClause {
  final Statement body;
  final Type? exceptionType;
  final Var? exception;
  final Var? stackTrace;

  CatchClause._(
    this.body,
    this.exceptionType,
    this.exception,
    this.stackTrace,
  ) {
    if (exception == null && stackTrace != null) {
      fail(
        'If a stack trace variable is provided, an exception variable must be '
        'provided too',
      );
    }
    if (exception == null && exceptionType == null) {
      fail(
        'If no exception variable is provided, an exception type must be '
        'provided',
      );
    }
  }

  @override
  String toString() {
    return [
      if (exceptionType case var exceptionType?) 'on $exceptionType',
      if (exception case Var(name: var exceptionName))
        switch (stackTrace) {
          Var(name: var stackTraceName) =>
            'catch ($exceptionName, $stackTraceName)',
          _ => 'catch ($exceptionName)',
        },
      body,
    ].join(' ');
  }

  void _preVisit(PreVisitor visitor) {
    if (exception case var exception?) {
      visitor._assignedVariables.declare(exception);
    }
    if (stackTrace case var stackTrace?) {
      visitor._assignedVariables.declare(stackTrace);
    }
    body.preVisit(visitor);
  }
}

class CheckAssigned extends Expression {
  final Var variable;
  final bool expectedAssignedState;

  CheckAssigned._(
    this.variable,
    this.expectedAssignedState, {
    required super.location,
  });

  @override
  void preVisit(PreVisitor visitor) {}

  @override
  String toString() {
    var verb = expectedAssignedState ? 'is' : 'is not';
    return 'check $variable $verb definitely assigned;';
  }

  @override
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
    expect(
      h.flow.isAssigned(variable),
      expectedAssignedState,
      reason: 'at $location',
    );
    h.irBuilder.atom('null', Kind.expression, location: location);
    return ExpressionTypeAnalysisResult(
      type: SharedTypeView(h.typeAnalyzer.nullType),
    );
  }
}

class CheckPromoted extends Expression {
  final Promotable promotable;
  final String? expectedTypeStr;

  CheckPromoted._(
    this.promotable,
    this.expectedTypeStr, {
    required super.location,
  });

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
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
    var promotedType = promotable._getPromotedType(h);
    expect(promotedType?.type, expectedTypeStr, reason: 'at $location');
    return ExpressionTypeAnalysisResult(
      type: SharedTypeView(NullType.instance),
    );
  }
}

class CheckPromotionChain extends Expression {
  final Promotable promotable;
  final List<String> expectedPromotionChain;

  CheckPromotionChain._(
    this.promotable,
    this.expectedPromotionChain, {
    required super.location,
  });

  @override
  void preVisit(PreVisitor visitor) {
    promotable.preVisit(visitor);
  }

  @override
  String toString() =>
      'check $promotable has promotion chain $expectedPromotionChain';

  @override
  shared.ExpressionTypeAnalysisResult visit(
    Harness h,
    SharedTypeSchemaView schema,
  ) {
    var promotionChain = promotable._getPromotionChain(h);
    expect(
      [for (var t in promotionChain) t.type],
      expectedPromotionChain,
      reason: 'at $location',
    );
    return ExpressionTypeAnalysisResult(
      type: SharedTypeView(NullType.instance),
    );
  }
}

class CheckReachable extends Expression {
  final bool expectedReachable;

  CheckReachable(this.expectedReachable, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {}

  @override
  String toString() => 'check reachable';

  @override
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
    expect(h.flow.isReachable, expectedReachable, reason: 'at $location');
    h.irBuilder.atom('null', Kind.expression, location: location);
    return new ExpressionTypeAnalysisResult(
      type: SharedTypeView(NullType.instance),
    );
  }
}

class CheckUnassigned extends Expression {
  final Var variable;
  final bool expectedUnassignedState;

  CheckUnassigned._(
    this.variable,
    this.expectedUnassignedState, {
    required super.location,
  });

  @override
  void preVisit(PreVisitor visitor) {}

  @override
  String toString() {
    var verb = expectedUnassignedState ? 'is' : 'is not';
    return 'check $variable $verb definitely unassigned;';
  }

  @override
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
    expect(
      h.flow.isUnassigned(variable),
      expectedUnassignedState,
      reason: 'at $location',
    );
    h.irBuilder.atom('null', Kind.expression, location: location);
    return ExpressionTypeAnalysisResult(
      type: SharedTypeView(h.typeAnalyzer.nullType),
    );
  }
}

/// Representation of a collection element in the pseudo-Dart language used for
/// type analysis testing.
abstract class CollectionElement extends Node
    with ProtoCollectionElement<CollectionElement> {
  /// If non-null, the expected IR that should be produced when this collection
  /// element is analyzed.
  String? _expectedIR;

  CollectionElement({required super.location}) : super._();

  @override
  CollectionElement asCollectionElement({required String location}) => this;

  @override
  CollectionElement checkIR(String expectedIR) {
    _expectedIR = expectedIR;
    return this;
  }

  void preVisit(PreVisitor visitor);

  void visit(Harness h, CollectionElementContext context);
}

abstract class CollectionElementContext {}

class CollectionElementContextMapEntry extends CollectionElementContext {
  final Type keyType;
  final Type valueType;

  CollectionElementContextMapEntry._(this.keyType, this.valueType);
}

class CollectionElementContextType extends CollectionElementContext {
  final SharedTypeSchemaView elementTypeSchema;

  CollectionElementContextType._(this.elementTypeSchema);
}

class Conditional extends Expression {
  final Expression condition;
  final Expression ifTrue;
  final Expression ifFalse;

  Conditional._(
    this.condition,
    this.ifTrue,
    this.ifFalse, {
    required super.location,
  });

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
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
    var result = h.typeAnalyzer.analyzeConditionalExpression(
      this,
      condition,
      ifTrue,
      ifFalse,
    );
    h.irBuilder.apply(
      'if',
      [Kind.expression, Kind.expression, Kind.expression],
      Kind.expression,
      location: location,
    );
    return result;
  }
}

class ConstantPattern extends Pattern {
  final Expression constant;

  ConstantPattern(this.constant, {required super.location}) : super._();

  @override
  SharedTypeSchemaView computeSchema(Harness h) =>
      h.typeAnalyzer.analyzeConstantPatternSchema();

  @override
  void preVisit(
    PreVisitor visitor,
    VariableBinder<Node, Var> variableBinder, {
    required bool isInAssignment,
  }) {
    constant.preVisit(visitor);
  }

  @override
  PatternResult visit(Harness h, SharedMatchContext context) {
    var analysisResult = h.typeAnalyzer.analyzeConstantPattern(
      context,
      this,
      constant,
    );
    var matchedType = analysisResult.matchedValueType.unwrapTypeView<Type>();
    h.irBuilder.atom(matchedType.type, Kind.type, location: location);
    h.irBuilder.apply(
      'const',
      [Kind.expression, Kind.type],
      Kind.pattern,
      names: ['matchedType'],
      location: location,
    );
    return analysisResult;
  }

  @override
  _debugString({required bool needsKeywordOrType}) => constant.toString();
}

/// Common interface shared by constructs that represent constant expressions,
/// in the pseudo-Dart language used for flow analysis testing.
abstract class ConstExpression extends Expression {
  ConstExpression._({required super.location});

  /// Converts this expression into a constant pattern.
  Pattern get pattern => ConstantPattern(this, location: computeLocation());
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
    h.typeAnalyzer.analyzeContinueStatement(
      target == null
          ? h.typeAnalyzer._currentContinueTarget
          : target._getBinding(),
    );
    h.irBuilder.apply('continue', [], Kind.statement, location: location);
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
    h.irBuilder.apply(
      'do',
      [Kind.statement, Kind.expression],
      Kind.statement,
      location: location,
    );
  }
}

// Represents the entire dot shorthand expression.
// e.g. `.current.errorZone`
class DotShorthand extends Expression {
  final Expression expr;

  DotShorthand._(this.expr, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    expr.preVisit(visitor);
  }

  @override
  String toString() => '$expr';

  @override
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
    return h.typeAnalyzer.analyzeDotShorthandExpression(expr, schema);
  }
}

// Represents the head of a dot shorthand.
// e.g. `.zero`
class DotShorthandHead extends Expression {
  final String name;

  DotShorthandHead._(this.name, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {}

  @override
  String toString() => '.$name';

  @override
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
    return h.typeAnalyzer.analyzeDotShorthandHeadExpression(this, name, schema);
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
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
    var operatorName = isInverted ? '!=' : '==';
    var result = h.typeAnalyzer.analyzeBinaryExpression(
      this,
      lhs,
      operatorName,
      rhs,
    );
    h.irBuilder.apply(
      operatorName,
      [Kind.expression, Kind.expression],
      Kind.expression,
      location: location,
    );
    return result;
  }
}

/// Representation of an expression in the pseudo-Dart language used for flow
/// analysis testing.  Methods in this class may be used to create more complex
/// expressions based on this one.
abstract class Expression extends Node
    with
        ProtoStatement<Expression>,
        ProtoCollectionElement<Expression>,
        ProtoExpression {
  /// If non-null, the expected IR that should be produced when this expression
  /// is analyzed.
  String? _expectedIR;

  /// If non-null, the expected schema that should be used to analyze this
  /// expression.
  String? _expectedSchema;

  /// If non-null, the expected type that should be produced when this
  /// expression is analyzed.
  String? _expectedType;

  Expression({required super.location}) : super._();

  @override
  Expression asExpression({required String location}) => this;

  void preVisit(PreVisitor visitor);

  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema);
}

/// Representation of a single case clause in a switch expression.  Use
/// [PossiblyGuardedPattern.thenExpr] or [SwitchHead.thenExpr] to create
/// instances of this class.
class ExpressionCase extends Node {
  final GuardedPattern? guardedPattern;
  final Expression expression;

  ExpressionCase._(
    this.guardedPattern,
    this.expression, {
    required super.location,
  }) : super._();

  @override
  String toString() => [
    guardedPattern == null ? 'default' : 'case $guardedPattern',
    ': $expression',
  ].join('');

  void _preVisit(PreVisitor visitor) {
    final guardedPattern = this.guardedPattern;
    if (guardedPattern != null) {
      var variableBinder = _VariableBinder(visitor);
      variableBinder.casePatternStart();
      guardedPattern.pattern.preVisit(
        visitor,
        variableBinder,
        isInAssignment: false,
      );
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
    SharedTypeSchemaView typeSchema = context is CollectionElementContextType
        ? context.elementTypeSchema
        : h.operations.unknownType;
    h.typeAnalyzer.analyzeExpression(expression, typeSchema);
    h.irBuilder.apply(
      'celt',
      [Kind.expression],
      Kind.collectionElement,
      location: location,
    );
  }
}

class ExpressionInTypeSchema extends Statement {
  final Expression expr;

  final SharedTypeSchemaView typeSchema;

  ExpressionInTypeSchema._(
    this.expr,
    this.typeSchema, {
    required super.location,
  });

  @override
  void preVisit(PreVisitor visitor) {
    expr.preVisit(visitor);
  }

  @override
  String toString() => '$expr (in type schema $typeSchema);';

  @override
  void visit(Harness h) {
    h.typeAnalyzer.analyzeExpression(expr, typeSchema);
    h.irBuilder.apply(
      'stmt',
      [Kind.expression],
      Kind.statement,
      location: location,
    );
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
    h.irBuilder.apply(
      'stmt',
      [Kind.expression],
      Kind.statement,
      location: location,
    );
  }
}

class For extends Statement {
  final Statement? initializer;
  final Expression? condition;
  final Expression? updater;
  final Statement body;
  final bool forCollection;

  For._(
    this.initializer,
    this.condition,
    this.updater,
    this.body,
    this.forCollection, {
    required super.location,
  });

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
      h.typeAnalyzer.analyzeExpression(condition!, h.operations.unknownType);
    } else {
      h.typeAnalyzer.handleNoCondition(this);
    }
    h.flow.for_bodyBegin(forCollection ? null : this, condition);
    h.typeAnalyzer._visitLoopBody(this, body);
    h.flow.for_updaterBegin();
    if (updater != null) {
      h.typeAnalyzer.analyzeExpression(updater!, h.operations.unknownType);
    } else {
      h.typeAnalyzer.handleNoCondition(this);
    }
    h.flow.for_end();
    h.irBuilder.apply(
      'for',
      [Kind.statement, Kind.expression, Kind.statement, Kind.expression],
      Kind.statement,
      location: location,
    );
  }
}

class ForEach extends Statement {
  final Var? variable;
  final Expression iterable;
  final Statement body;
  final bool declaresVariable;

  ForEach._(
    this.variable,
    this.iterable,
    this.body,
    this.declaresVariable, {
    required super.location,
  });

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
      h.typeAnalyzer
          .analyzeExpression(iterable, h.operations.unknownType)
          .unwrapTypeView<Type>(),
    );
    h.flow.forEach_bodyBegin(this);
    var variable = this.variable;
    if (variable != null && !declaresVariable) {
      h.flow.write(this, variable, SharedTypeView(iteratedType), null);
    }
    h.typeAnalyzer._visitLoopBody(this, body);
    h.flow.forEach_end();
    h.irBuilder.apply(
      'forEach',
      [Kind.expression, Kind.statement],
      Kind.statement,
      location: location,
    );
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
    'int.<': Type('bool Function(num)'),
    'int.<=': Type('bool Function(num)'),
    'int.>': Type('bool Function(num)'),
    'int.>=': Type('bool Function(num)'),
    'int.abs': Type('int Function()'),
    'int.isEven': Type('bool'),
    'num.sign': Type('num'),
    'Object.toString': Type('String Function()'),
  };

  final MiniAstOperations operations = MiniAstOperations();

  bool _started = false;

  late final FlowAnalysis<Node, Statement, Expression, Var, SharedTypeView>
  flow;

  bool? _inferenceUpdate3Enabled;

  bool? _inferenceUpdate4Enabled;

  bool? _soundFlowAnalysisEnabled;

  bool? _patternsEnabled;

  Type? _thisType;

  late final Map<String, _PropertyElement?> _members = {
    for (var entry in _coreMemberTypes.entries)
      entry.key: _PropertyElement(
        entry.value,
        entry.key.split('.').last,
        isPromotable: false,
        whyNotPromotable: null,
      ),
  };

  late final typeAnalyzer = _MiniAstTypeAnalyzer(
    this,
    computeTypeAnalyzerOptions(),
  );

  /// Indicates whether initializers of implicitly typed variables should be
  /// accounted for by SSA analysis.  (In an ideal world, they always would be,
  /// but due to https://github.com/dart-lang/language/issues/1785, they weren't
  /// always, and we need to be able to replicate the old behavior when
  /// analyzing old language versions).
  bool _respectImplicitlyTypedVarInitializers = true;

  bool _fieldPromotionEnabled = true;

  bool get inferenceUpdate3Enabled => _inferenceUpdate3Enabled ?? true;

  bool get inferenceUpdate4Enabled => _inferenceUpdate4Enabled ?? true;

  MiniIRBuilder get irBuilder => typeAnalyzer._irBuilder;

  bool get patternsEnabled => _patternsEnabled ?? true;

  bool get soundFlowAnalysisEnabled => _soundFlowAnalysisEnabled ?? true;

  set thisType(String type) {
    assert(!_started);
    _thisType = Type(type);
  }

  /// Updates the harness with a new result for
  /// [MiniAstOperations.downwardInfer].
  void addDownwardInfer({
    required String name,
    required String context,
    required String result,
  }) {
    operations.addDownwardInfer(name: name, context: context, result: result);
  }

  /// Updates the harness so that when an
  /// [TypeAnalyzerOperations.isAlwaysExhaustiveType] query is invoked on type
  /// [type], [isExhaustive] will be returned.
  void addExhaustiveness(String type, bool isExhaustive) {
    operations.addExhaustiveness(type, isExhaustive);
  }

  /// Updates the harness so that when an extension type erasure query is
  /// invoked on type [type], [representation] will be returned.
  void addExtensionTypeErasure(String type, String representation) {
    operations.addExtensionTypeErasure(type, representation);
  }

  void addLub(String type1, String type2, String resultType) {
    operations.addLub(type1, type2, resultType);
  }

  /// Updates the harness so that when member [memberName] is looked up on type
  /// [targetType], a member is found having the given [type].
  ///
  /// If [type] is `null`, then an attempt to look up [memberName] on type
  /// [targetType] should result in `null` (no such member) rather than a test
  /// failure.
  void addMember(
    String targetType,
    String memberName,
    String? type, {
    bool promotable = false,
    PropertyNonPromotabilityReason? whyNotPromotable,
  }) {
    if (promotable) {
      assert(whyNotPromotable == null);
    }
    var query = '$targetType.$memberName';
    if (type == null) {
      if (promotable) {
        fail(
          "It doesn't make sense to specify `promotable: true` "
          "when the type is `null`",
        );
      }
      _members[query] = null;
      return;
    }
    _members[query] = _PropertyElement(
      Type(type),
      memberName,
      isPromotable: promotable,
      whyNotPromotable: whyNotPromotable,
    );
  }

  void addPromotionException(String from, String to, String result) {
    operations.addPromotionException(from, to, result);
  }

  void addSuperInterfaces(
    String className,
    List<Type> Function(List<Type>) template,
  ) {
    operations.addSuperInterfaces(className, template);
  }

  shared.TypeAnalyzerOptions computeTypeAnalyzerOptions() =>
      TypeAnalyzerOptions(
        patternsEnabled: patternsEnabled,
        inferenceUpdate3Enabled: inferenceUpdate3Enabled,
        respectImplicitlyTypedVarInitializers:
            _respectImplicitlyTypedVarInitializers,
        fieldPromotionEnabled: _fieldPromotionEnabled,
        inferenceUpdate4Enabled: inferenceUpdate4Enabled,
        soundFlowAnalysisEnabled: soundFlowAnalysisEnabled,
      );

  void disableFieldPromotion() {
    assert(!_started);
    _fieldPromotionEnabled = false;
  }

  void disableInferenceUpdate3() {
    assert(!_started);
    _inferenceUpdate3Enabled = false;
  }

  void disableInferenceUpdate4() {
    assert(!_started);
    _inferenceUpdate4Enabled = false;
  }

  void disablePatterns() {
    assert(!_started);
    _patternsEnabled = false;
  }

  void disableRespectImplicitlyTypedVarInitializers() {
    assert(!_started);
    _respectImplicitlyTypedVarInitializers = false;
  }

  void disableSoundFlowAnalysis() {
    assert(!_started);
    _soundFlowAnalysisEnabled = false;
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
    // If an explicit map entry was found for this member, return the associated
    // value (even if it is `null`; `null` means the test has been explicitly
    // configured so that the member lookup is supposed to find nothing).
    if (member != null || _members.containsKey(query)) return member;
    switch (memberName) {
      case 'toString':
        // Assume that all types implement `Object.toString`.
        return _members['Object.$memberName']!;
      default:
        // It's legal to look up any member on the type `dynamic`.
        if (type is DynamicType) {
          return null;
        }
        // But an attempt to look up an unknown member on any other type
        // results in a test failure. This is to catch mistakes in unit tests;
        // if the unit test is deliberately trying to exercise a member lookup
        // that should find nothing, please use `addMember` to store an
        // explicit `null` value in the `_members` map.
        fail('Unknown member query: $query');
    }
  }

  /// See [TypeAnalyzer.resolveRelationalPatternOperator].
  RelationalOperatorResolution? resolveRelationalPatternOperator(
    Type matchedValueType,
    String operator,
  ) {
    if (operator == '==' || operator == '!=') {
      return RelationalOperatorResolution(
        kind: operator == '=='
            ? RelationalOperatorKind.equals
            : RelationalOperatorKind.notEquals,
        parameterType: SharedTypeView(Type('Object')),
        returnType: SharedTypeView(Type('bool')),
      );
    }
    var member = getMember(matchedValueType, operator);
    if (member == null) return null;
    var memberType = member._type;
    if (memberType is! FunctionType || memberType.isQuestionType) {
      fail(
        '$matchedValueType.operator$operator has type $memberType; '
        'must be a function type',
      );
    }
    if (memberType.positionalParameters.isEmpty) {
      fail(
        '$matchedValueType.operator$operator has type $memberType; '
        'must accept a parameter',
      );
    }
    return RelationalOperatorResolution(
      kind: RelationalOperatorKind.other,
      parameterType: SharedTypeView(memberType.positionalParameters[0]),
      returnType: SharedTypeView(memberType.returnType),
    );
  }

  /// Runs the given [statements] through flow analysis, checking any assertions
  /// they contain.
  void run(
    List<ProtoStatement> statements, {
    bool errorRecoveryOK = false,
    Set<String> expectedErrors = const {},
  }) {
    try {
      _started = true;
      var visitor = PreVisitor(typeAnalyzer.errors);
      var b = Block._(statements, location: computeLocation());
      b.preVisit(visitor);
      flow = FlowAnalysis<Node, Statement, Expression, Var, SharedTypeView>(
        operations,
        visitor._assignedVariables,
        typeAnalyzerOptions: computeTypeAnalyzerOptions(),
      );
      typeAnalyzer.dispatchStatement(b);
      typeAnalyzer.finish();
      expect(typeAnalyzer.errors._accumulatedErrors, expectedErrors);
      var assertInErrorRecoveryStack =
          typeAnalyzer.errors._assertInErrorRecoveryStack;
      if (!errorRecoveryOK && assertInErrorRecoveryStack != null) {
        fail(
          'assertInErrorRecovery called but no errors reported: '
          '$assertInErrorRecoveryStack',
        );
      }
      if (Node._nodesWithUnusedErrorIds.isNotEmpty) {
        var ids = [
          for (var node in Node._nodesWithUnusedErrorIds) node._errorId,
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
      'if',
      [Kind.expression, Kind.statement, Kind.statement],
      Kind.statement,
      location: location,
    );
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

  IfCase(
    this.expression,
    this.pattern,
    this.guard,
    super.ifTrue,
    super.ifFalse, {
    required super.location,
  }) : super._();

  @override
  String get _conditionPartString => '$expression case $pattern';

  @override
  void preVisit(PreVisitor visitor) {
    expression.preVisit(visitor);
    var variableBinder = _VariableBinder(visitor);
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
      this,
      expression,
      pattern,
      guard,
      ifTrue,
      ifFalse,
      _candidateVariables,
    );
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
    this.expression,
    this.pattern,
    this.guard,
    super.ifTrue,
    super.ifFalse, {
    required super.location,
  }) : super._();

  @override
  String get _conditionPartString => '$expression case $pattern';

  @override
  void preVisit(PreVisitor visitor) {
    expression.preVisit(visitor);
    var variableBinder = _VariableBinder(visitor);
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

  IfElement._(
    this.condition,
    super.ifTrue,
    super.ifFalse, {
    required super.location,
  }) : super._();

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
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
    var result = h.typeAnalyzer.analyzeIfNullExpression(this, lhs, rhs);
    h.irBuilder.apply(
      'ifNull',
      [Kind.expression, Kind.expression],
      Kind.expression,
      location: location,
    );
    return result;
  }
}

class IntLiteral extends ConstExpression {
  final int value;

  /// `true` or `false` if we should assert that int->double conversion either
  /// does, or does not, happen.  `null` if no assertion should be done.
  final bool? expectConversionToDouble;

  IntLiteral(
    this.value, {
    this.expectConversionToDouble,
    required super.location,
  }) : super._();

  @override
  void preVisit(PreVisitor visitor) {}

  @override
  String toString() => '$value';

  @override
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
    var result = h.typeAnalyzer.analyzeIntLiteral(schema);
    if (expectConversionToDouble != null) {
      expect(result.convertedToDouble, expectConversionToDouble);
    }
    h.irBuilder.atom(
      result.convertedToDouble ? '${value.toDouble()}f' : '$value',
      Kind.expression,
      location: location,
    );
    return result;
  }
}

/// Representation of a method invocation in the pseudo-Dart language used for
/// flow analysis testing.
class InvokeMethod extends Expression {
  // The expression appering before the `.`.
  final Expression target;

  // The name of the method being invoked.
  final String methodName;

  // The arguments being passed to the invocation.
  final List<Expression> arguments;

  final bool isNullAware;

  InvokeMethod._(
    this.target,
    this.methodName,
    this.arguments, {
    required this.isNullAware,
    required super.location,
  });

  @override
  void preVisit(PreVisitor visitor) {
    target.preVisit(visitor);
    for (var argument in arguments) {
      argument.preVisit(visitor);
    }
  }

  @override
  String toString() {
    var q = isNullAware ? '?' : '';
    return '$target$q.$methodName'
        '(${[for (var arg in arguments) arg].join(', ')})';
  }

  @override
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
    return h.typeAnalyzer.analyzeMethodInvocation(
      this,
      target is CascadePlaceholder ? null : target,
      methodName,
      arguments,
      isNullAware: isNullAware,
    );
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
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
    return h.typeAnalyzer.analyzeTypeTest(
      this,
      target,
      type,
      isInverted: isInverted,
    );
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

/// Representation of a list literal in the pseudo-Dart language used for flow
/// analysis testing.
class ListLiteral extends Expression {
  final List<CollectionElement> elements;
  final Type elementType;

  ListLiteral._(this.elements, this.elementType, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    for (var element in elements) {
      element.preVisit(visitor);
    }
  }

  @override
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
    for (var element in elements) {
      h.typeAnalyzer.dispatchCollectionElement(
        element,
        CollectionElementContextType._(SharedTypeSchemaView(elementType)),
      );
    }
    h.irBuilder.apply(
      'list',
      [for (var _ in elements) Kind.collectionElement],
      Kind.expression,
      location: location,
    );
    return ExpressionTypeAnalysisResult(
      type: h.operations.listType(SharedTypeView(elementType)),
    );
  }
}

abstract class ListOrMapPatternElement implements Node {
  ListOrMapPatternElement._();

  void preVisit(
    PreVisitor visitor,
    VariableBinder<Node, Var> variableBinder, {
    required bool isInAssignment,
  });

  String _debugString({required bool needsKeywordOrType});
}

class ListPattern extends Pattern {
  final Type? elementType;

  final List<ListPatternElement> elements;

  ListPattern._(this.elementType, this.elements, {required super.location})
    : super._();

  @override
  SharedTypeSchemaView computeSchema(Harness h) =>
      h.typeAnalyzer.analyzeListPatternSchema(
        elementType: elementType?.wrapSharedTypeView(),
        elements: elements,
      );

  @override
  void preVisit(
    PreVisitor visitor,
    VariableBinder<Node, Var> variableBinder, {
    required bool isInAssignment,
  }) {
    for (var element in elements) {
      element.preVisit(visitor, variableBinder, isInAssignment: isInAssignment);
    }
  }

  @override
  PatternResult visit(Harness h, SharedMatchContext context) {
    var listPatternResult = h.typeAnalyzer.analyzeListPattern(
      context,
      this,
      elementType: elementType?.wrapSharedTypeView(),
      elements: elements,
    );
    var matchedType = listPatternResult.matchedValueType.unwrapTypeView<Type>();
    var requiredType = listPatternResult.requiredType.unwrapTypeView<Type>();
    h.irBuilder.atom(matchedType.type, Kind.type, location: location);
    h.irBuilder.atom(requiredType.type, Kind.type, location: location);
    h.irBuilder.apply(
      'listPattern',
      [...List.filled(elements.length, Kind.pattern), Kind.type, Kind.type],
      Kind.pattern,
      names: ['matchedType', 'requiredType'],
      location: location,
    );
    return listPatternResult;
  }

  @override
  String _debugString({required bool needsKeywordOrType}) {
    var elements = [
      for (var element in this.elements)
        element._debugString(needsKeywordOrType: needsKeywordOrType),
    ];
    return '[${elements.join(', ')}]';
  }
}

abstract class ListPatternElement implements ListOrMapPatternElement {}

class LocalFunction extends Expression {
  final Statement body;
  final Type type;

  LocalFunction._(this.body, {String? type, required super.location})
    : type = Type(type ?? 'void Function()');

  @override
  void preVisit(PreVisitor visitor) {
    visitor._assignedVariables.beginNode();
    body.preVisit(visitor);
    visitor._assignedVariables.endNode(
      this,
      isClosureOrLateVariableInitializer: true,
    );
  }

  @override
  String toString() => '() $body';

  @override
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
    h.flow.functionExpression_begin(this);
    h.typeAnalyzer.dispatchStatement(body);
    h.flow.functionExpression_end();
    h.irBuilder.apply(
      'localFunction',
      [Kind.statement],
      Kind.expression,
      location: location,
    );
    return ExpressionTypeAnalysisResult(type: SharedTypeView(type));
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
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
    var operatorName = isAnd ? '&&' : '||';
    var result = h.typeAnalyzer.analyzeBinaryExpression(
      this,
      lhs,
      operatorName,
      rhs,
    );
    h.irBuilder.apply(
      operatorName,
      [Kind.expression, Kind.expression],
      Kind.expression,
      location: location,
    );
    return result;
  }
}

class LogicalAndPattern extends Pattern {
  final Pattern lhs;

  final Pattern rhs;

  LogicalAndPattern._(this.lhs, this.rhs, {required super.location})
    : super._();

  @override
  SharedTypeSchemaView computeSchema(Harness h) =>
      h.typeAnalyzer.analyzeLogicalAndPatternSchema(lhs, rhs);

  @override
  void preVisit(
    PreVisitor visitor,
    VariableBinder<Node, Var> variableBinder, {
    required bool isInAssignment,
  }) {
    lhs.preVisit(visitor, variableBinder, isInAssignment: isInAssignment);
    rhs.preVisit(visitor, variableBinder, isInAssignment: isInAssignment);
  }

  @override
  PatternResult visit(Harness h, SharedMatchContext context) {
    var analysisResult = h.typeAnalyzer.analyzeLogicalAndPattern(
      context,
      this,
      lhs,
      rhs,
    );
    var matchedType = analysisResult.matchedValueType.unwrapTypeView<Type>();
    h.irBuilder.atom(matchedType.type, Kind.type, location: location);
    h.irBuilder.apply(
      'logicalAndPattern',
      [Kind.pattern, Kind.pattern, Kind.type],
      Kind.pattern,
      names: ['matchedType'],
      location: location,
    );
    return analysisResult;
  }

  @override
  _debugString({required bool needsKeywordOrType}) => [
    lhs._debugString(needsKeywordOrType: false),
    '&&',
    rhs._debugString(needsKeywordOrType: false),
  ].join(' ');
}

class LogicalOrPattern extends Pattern {
  final Pattern lhs;

  final Pattern rhs;

  LogicalOrPattern(this.lhs, this.rhs, {required super.location}) : super._();

  @override
  SharedTypeSchemaView computeSchema(Harness h) =>
      h.typeAnalyzer.analyzeLogicalOrPatternSchema(lhs, rhs);

  @override
  void preVisit(
    PreVisitor visitor,
    VariableBinder<Node, Var> variableBinder, {
    required bool isInAssignment,
  }) {
    variableBinder.logicalOrPatternStart();
    lhs.preVisit(visitor, variableBinder, isInAssignment: isInAssignment);
    variableBinder.logicalOrPatternFinishLeft();
    rhs.preVisit(visitor, variableBinder, isInAssignment: isInAssignment);
    variableBinder.logicalOrPatternFinish(this);
  }

  @override
  PatternResult visit(Harness h, SharedMatchContext context) {
    var analysisResult = h.typeAnalyzer.analyzeLogicalOrPattern(
      context,
      this,
      lhs,
      rhs,
    );
    var matchedType = analysisResult.matchedValueType.unwrapTypeView<Type>();
    h.irBuilder.atom(matchedType.type, Kind.type, location: location);
    h.irBuilder.apply(
      'logicalOrPattern',
      [Kind.pattern, Kind.pattern, Kind.type],
      Kind.pattern,
      names: ['matchedType'],
      location: location,
    );
    return analysisResult;
  }

  @override
  _debugString({required bool needsKeywordOrType}) => [
    lhs._debugString(needsKeywordOrType: false),
    '||',
    rhs._debugString(needsKeywordOrType: false),
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
  Expression write(ProtoExpression? value) {
    var location = computeLocation();
    return new Write(
      this,
      value?.asExpression(location: location),
      location: location,
    );
  }

  void _visitPostIncDec(
    Harness h,
    Expression postIncDecExpression,
    Type writtenType,
  );

  void _visitWrite(
    Harness h,
    Expression assignmentExpression,
    Type writtenType,
    Expression? rhs,
  );
}

/// Representation of a map entry in the pseudo-Dart language used for flow
/// analysis testing.
class MapEntry extends CollectionElement {
  final Expression key;
  final Expression value;
  final bool isKeyNullAware;

  MapEntry._(
    this.key,
    this.value, {
    required this.isKeyNullAware,
    required super.location,
  });

  @override
  void preVisit(PreVisitor visitor) {
    key.preVisit(visitor);
    value.preVisit(visitor);
  }

  @override
  String toString() => '${isKeyNullAware ? '?' : ''}$key: $value';

  @override
  void visit(Harness h, CollectionElementContext context) {
    SharedTypeSchemaView keySchema;
    SharedTypeSchemaView valueSchema;
    switch (context) {
      case CollectionElementContextMapEntry(:var keyType, :var valueType):
        keySchema = SharedTypeSchemaView(keyType);
        valueSchema = SharedTypeSchemaView(valueType);
      default:
        keySchema = valueSchema = h.operations.unknownType;
    }
    var keyType = h.typeAnalyzer.analyzeExpression(key, keySchema);
    h.flow.nullAwareMapEntry_valueBegin(
      key,
      keyType,
      isKeyNullAware: isKeyNullAware,
    );
    h.typeAnalyzer.analyzeExpression(value, valueSchema);
    h.flow.nullAwareMapEntry_end(isKeyNullAware: isKeyNullAware);
    h.irBuilder.apply(
      'mapEntry',
      [Kind.expression, Kind.expression],
      Kind.collectionElement,
      location: location,
    );
  }
}

/// Representation of a list literal in the pseudo-Dart language used for flow
/// analysis testing.
class MapLiteral extends Expression {
  final List<CollectionElement> elements;
  final Type keyType;
  final Type valueType;

  MapLiteral._(
    this.elements,
    this.keyType,
    this.valueType, {
    required super.location,
  });

  @override
  void preVisit(PreVisitor visitor) {
    for (var element in elements) {
      element.preVisit(visitor);
    }
  }

  @override
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
    var context = CollectionElementContextMapEntry._(keyType, valueType);
    for (var element in elements) {
      h.typeAnalyzer.dispatchCollectionElement(element, context);
    }
    h.irBuilder.apply(
      'map',
      [for (var _ in elements) Kind.collectionElement],
      Kind.expression,
      location: location,
    );
    return ExpressionTypeAnalysisResult(
      type: h.operations.mapType(
        keyType: SharedTypeView(keyType),
        valueType: SharedTypeView(valueType),
      ),
    );
  }
}

class MapPattern extends Pattern {
  final ({Type keyType, Type valueType})? typeArguments;

  final List<MapPatternElement> elements;

  MapPattern._(this.typeArguments, this.elements, {required super.location})
    : super._();

  @override
  SharedTypeSchemaView computeSchema(Harness h) =>
      h.typeAnalyzer.analyzeMapPatternSchema(
        typeArguments: typeArguments?.wrapSharedTypeMapEntryView(),
        elements: elements,
      );

  @override
  void preVisit(
    PreVisitor visitor,
    VariableBinder<Node, Var> variableBinder, {
    required bool isInAssignment,
  }) {
    for (var element in elements) {
      element.preVisit(visitor, variableBinder, isInAssignment: isInAssignment);
    }
  }

  @override
  PatternResult visit(Harness h, SharedMatchContext context) {
    var mapPatternResult = h.typeAnalyzer.analyzeMapPattern(
      context,
      this,
      typeArguments: typeArguments?.wrapSharedTypeMapEntryView(),
      elements: elements,
    );
    var matchedType = mapPatternResult.matchedValueType.unwrapTypeView<Type>();
    var requiredType = mapPatternResult.requiredType.unwrapTypeView<Type>();
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
    return mapPatternResult;
  }

  @override
  String _debugString({required bool needsKeywordOrType}) {
    var elements = [
      for (var element in this.elements)
        element._debugString(needsKeywordOrType: needsKeywordOrType),
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
  void preVisit(
    PreVisitor visitor,
    VariableBinder<Node, Var> variableBinder, {
    required bool isInAssignment,
  }) {
    value.preVisit(visitor, variableBinder, isInAssignment: isInAssignment);
  }

  @override
  String _debugString({required bool needsKeywordOrType}) {
    return '$key: $value';
  }
}

class MiniAstOperations
    with TypeAnalyzerOperationsMixin<Var, Type, String, Node>
    implements TypeAnalyzerOperations<Var, Type, String, Node> {
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
    'num?': false,
    'Object': false,
    'Object?': false,
    'String': false,
    'String?': false,
  };

  static final Map<String, Type> _coreGlbs = {
    '_, int': Type('int'),
    '(int,), _': Type('(int,)'),
    '(num,), _': Type('(num,)'),
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
    'Null, bool': Type('bool?'),
    'Null, dynamic': Type('dynamic'),
    'Null, int': Type('int?'),
    'Null, Object': Type('Object?'),
    'Null, String': Type('String?'),
    'int, _': Type('int'),
    'List<_>, _': Type('List<_>'),
    'Null, _': Type('Null'),
  };

  static final Map<String, Type> _coreDownwardInferenceResults = {
    'bool <: bool': Type('bool'),
    'dynamic <: int': Type('dynamic'),
    'dynamic <: Null': Type('dynamic'),
    'error <: int': Type('error'),
    'error <: num': Type('error'),
    'int <: dynamic': Type('int'),
    'int <: int': Type('int'),
    'int <: Null': Type('int'),
    'int <: num': Type('int'),
    'int <: Object': Type('int'),
    'int <: Object?': Type('int'),
    'List <: Iterable<int>': Type('List<int>'),
    'Never <: int': Type('Never'),
    'Null <: int': Type('Null'),
    'Null <: Null': Type('Null'),
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

  @override
  late final SharedTypeView objectQuestionType = SharedTypeView(
    Type('Object?'),
  );

  @override
  late final SharedTypeView objectType = SharedTypeView(Type('Object'));

  @override
  late final SharedTypeSchemaView unknownType = SharedTypeSchemaView(Type('_'));

  @override
  late final SharedTypeView intType = SharedTypeView(Type('int'));

  @override
  late final SharedTypeView doubleType = SharedTypeView(Type('double'));

  final Map<String, bool> _exhaustiveness = Map.of(_coreExhaustiveness);

  final Map<String, Type> _extensionTypeErasure = {};

  final Map<String, Type> _glbs = Map.of(_coreGlbs);

  final Map<String, Type> _lubs = Map.of(_coreLubs);

  final Map<String, Type> _downwardInferenceResults = Map.of(
    _coreDownwardInferenceResults,
  );

  Map<String, Map<String, String>> _promotionExceptions = {};

  Map<String, Type> _normalizeResults = Map.of(_coreNormalizeResults);

  final TypeSystem _typeSystem = TypeSystem();

  final _variance = <String, List<Variance>>{};

  @override
  final SharedTypeView boolType = SharedTypeView(Type('bool'));

  @override
  SharedTypeView get dynamicType => SharedTypeView(DynamicType.instance);

  @override
  SharedTypeView get errorType => SharedTypeView(InvalidType.instance);

  @override
  SharedTypeView get neverType => SharedTypeView(NeverType.instance);

  @override
  SharedTypeView get nullType => SharedTypeView(NullType.instance);

  /// Updates the harness with a new result for [downwardInfer].
  void addDownwardInfer({
    required String name,
    required String context,
    required String result,
  }) {
    var query = '$name <: $context';
    _downwardInferenceResults[query] = Type(result);
  }

  /// Updates the harness so that when an [isAlwaysExhaustiveType] query is
  /// invoked on type [type], [isExhaustive] will be returned.
  void addExhaustiveness(String type, bool isExhaustive) {
    _exhaustiveness[type] = isExhaustive;
  }

  /// Updates the harness so that when an extension type erasure query is
  /// invoked on type [type], [representation] will be returned.
  void addExtensionTypeErasure(String type, String representation) {
    _extensionTypeErasure[type] = Type(representation);
  }

  void addLub(String type1, String type2, String resultType) {
    _lubs['$type1, $type2'] = Type(resultType);
  }

  void addPromotionException(String from, String to, String result) {
    (_promotionExceptions[from] ??= {})[to] = result;
  }

  void addSuperInterfaces(
    String className,
    List<Type> Function(List<Type>) template,
  ) {
    _typeSystem.addSuperInterfaces(className, template);
  }

  void addVariance(String typeName, List<Variance> varianceByArgument) {
    _variance[typeName] = varianceByArgument;
  }

  @override
  TypeClassification classifyType(SharedTypeView type) {
    if (isSubtypeOfInternal(type.unwrapTypeView<Type>(), Type('Object'))) {
      return TypeClassification.nonNullable;
    } else if (isSubtypeOfInternal(
      type.unwrapTypeView<Type>(),
      NullType.instance,
    )) {
      return TypeClassification.nullOrEquivalent;
    } else {
      return TypeClassification.potentiallyNullable;
    }
  }

  @override
  TypeConstraintGenerator<Var, Type, String, Node>
  createTypeConstraintGenerator({
    required TypeConstraintGenerationDataForTesting?
    typeConstraintGenerationDataForTesting,
    required List<SharedTypeParameterView> typeParametersToInfer,
    required TypeAnalyzerOperations<Var, Type, String, Node>
    typeAnalyzerOperations,
    required bool inferenceUsingBoundsIsEnabled,
  }) {
    return TypeConstraintGatherer({
      for (var typeParameter in typeParametersToInfer)
        typeParameter
            .unwrapTypeParameterViewAsTypeParameterStructure<TypeParameter>()
            .name,
    });
  }

  /// Returns the downward inference result of a type with the given [name],
  /// in the [context]. For example infer `List<int>` from `Iterable<int>`.
  Type downwardInfer(String name, Type context) {
    var query = '$name <: $context';
    return _downwardInferenceResults[query] ??
        fail('Unknown downward inference query: $query');
  }

  @override
  SharedTypeView extensionTypeErasure(SharedTypeView type) {
    var query = '${type.unwrapTypeView()}';
    return SharedTypeView(
      _extensionTypeErasure[query] ?? type.unwrapTypeView(),
    );
  }

  @override
  SharedTypeView factor(SharedTypeView from, SharedTypeView what) {
    return SharedTypeView(
      _typeSystem.factor(
        from.unwrapTypeView<Type>(),
        what.unwrapTypeView<Type>(),
      ),
    );
  }

  @override
  Type futureTypeInternal(Type argumentType) {
    return PrimaryType(TypeRegistry.future, args: [argumentType]);
  }

  @override
  TypeDeclarationKind? getTypeDeclarationKindInternal(Type type) {
    if (isInterfaceTypeInternal(type)) {
      return TypeDeclarationKind.interfaceDeclaration;
    } else if (isExtensionTypeInternal(type)) {
      return TypeDeclarationKind.extensionTypeDeclaration;
    } else {
      return null;
    }
  }

  @override
  Variance getTypeParameterVariance(
    String typeDeclaration,
    int parameterIndex,
  ) {
    return _variance[typeDeclaration]?[parameterIndex] ?? Variance.covariant;
  }

  @override
  Type glbInternal(Type type1, Type type2) {
    if (type1.type == type2.type) return type1;
    var typeNames = [type1.type, type2.type];
    typeNames.sort();
    var query = typeNames.join(', ');
    return _glbs[query] ?? fail('Unknown glb query: $query');
  }

  @override
  SharedTypeView greatestClosureOfSchema(
    SharedTypeSchemaView schema, {
    SharedTypeView? topType,
  }) {
    return SharedTypeView(
      schema.unwrapTypeSchemaView<Type>().closureWithRespectToUnknown(
            covariant: true,
          ) ??
          schema.unwrapTypeSchemaView(),
    );
  }

  @override
  Type greatestClosureOfTypeInternal(
    Type type,
    List<SharedTypeParameter> typeParametersToEliminate,
  ) {
    // TODO(paulberry): Implement greatest closure of types in mini ast.
    throw UnimplementedError();
  }

  @override
  bool isAlwaysExhaustiveType(SharedTypeView type) {
    var query = type.unwrapTypeView<Type>().type;
    return _exhaustiveness[query] ??
        fail('Unknown exhaustiveness query: $query');
  }

  @override
  bool isAssignableTo(SharedTypeView fromType, SharedTypeView toType) {
    if (fromType is DynamicType) return true;
    if (fromType is InvalidType) return true;
    return isSubtypeOfInternal(
      fromType.unwrapTypeView<Type>(),
      toType.unwrapTypeView<Type>(),
    );
  }

  @override
  bool isBottomType(SharedTypeView type) {
    Type unwrappedType = type.unwrapTypeView();
    return unwrappedType is NeverType && !unwrappedType.isQuestionType;
  }

  @override
  bool isBoundOmitted(SharedTypeParameter typeParameter) {
    // TODO(paulberry): Implement isBoundOmitted in mini ast.
    throw UnimplementedError();
  }

  @override
  bool isDartCoreFunctionInternal(Type type) {
    return type is PrimaryType &&
        !type.isQuestionType &&
        type.name == 'Function' &&
        type.args.isEmpty;
  }

  @override
  bool isDartCoreRecordInternal(Type type) {
    return type is PrimaryType &&
        !type.isQuestionType &&
        type.name == 'Record' &&
        type.args.isEmpty;
  }

  @override
  bool isExtensionTypeInternal(Type type) {
    // TODO(cstefantsova): Add the support for extension types in the mini ast
    // testing framework.
    return false;
  }

  @override
  bool isFinal(Var variable) {
    return variable.isFinal;
  }

  @override
  bool isInterfaceTypeInternal(Type type) {
    return type is PrimaryType && type.isInterfaceType;
  }

  @override
  bool isInvalidType(SharedTypeView type) {
    return type is InvalidType;
  }

  @override
  bool isKnownType(SharedTypeSchemaView typeSchema) {
    var unwrapped = typeSchema.unwrapTypeSchemaView<Type>();
    switch (unwrapped) {
      case FutureOrType(:var typeArgument):
        return isKnownType(SharedTypeSchemaView(typeArgument));
      case PrimaryType(:var args):
        for (var arg in args) {
          if (!isKnownType(SharedTypeSchemaView(arg))) {
            return false;
          }
        }
        return true;
      case FunctionType(
        :var returnType,
        :var typeParametersShared,
        :var positionalParameters,
        :var namedParameters,
      ):
        if (!isKnownType(SharedTypeSchemaView(returnType))) {
          return false;
        }
        for (var typeParameter in typeParametersShared) {
          if (!isKnownType(SharedTypeSchemaView(typeParameter.bound))) {
            return false;
          }
        }
        for (var positionalParameter in positionalParameters) {
          if (!isKnownType(SharedTypeSchemaView(positionalParameter))) {
            return false;
          }
        }
        for (var namedParameter in namedParameters) {
          if (!isKnownType(SharedTypeSchemaView(namedParameter.type))) {
            return false;
          }
        }
        return true;
      case RecordType(:var positionalTypes, :var namedTypes):
        for (var positionalType in positionalTypes) {
          if (!isKnownType(SharedTypeSchemaView(positionalType))) {
            return false;
          }
        }
        for (var namedType in namedTypes) {
          if (!isKnownType(SharedTypeSchemaView(namedType.type))) {
            return false;
          }
        }
        return true;
      case UnknownType():
        return false;
      default:
        return true;
    }
  }

  @override
  bool isNonNullableInternal(Type type) {
    Type unwrappedType = type;
    if (unwrappedType is DynamicType ||
        unwrappedType is SharedUnknownType ||
        unwrappedType is VoidType ||
        unwrappedType is NullType ||
        unwrappedType is InvalidType) {
      return false;
    } else if (unwrappedType case TypeParameterType(
      :var promotion,
      :var typeParameter,
      isQuestionType: false,
    )) {
      if (promotion != null) {
        return isNonNullableInternal(promotion);
      } else {
        return isNonNullableInternal(typeParameter.bound);
      }
    } else if (type.isQuestionType) {
      return false;
    } else if (matchFutureOrInternal(unwrappedType) case Type typeArgument?) {
      return isNonNullableInternal(typeArgument);
    }
    return true;
  }

  @override
  bool isNullableInternal(Type type) {
    Type unwrappedType = type;
    if (unwrappedType is DynamicType ||
        unwrappedType is SharedUnknownType ||
        unwrappedType is VoidType ||
        unwrappedType is NullType) {
      return true;
    } else if (type.isQuestionType) {
      return false;
    } else if (matchFutureOrInternal(unwrappedType) case Type typeArgument?) {
      return isNullableInternal(typeArgument);
    }
    // TODO(cstefantsova): Update to a fast-pass implementation when the
    // mini-ast testing framework supports looking up superinterfaces of
    // extension types or looking up bounds of type parameters.
    return _typeSystem.isSubtype(NullType.instance, unwrappedType);
  }

  @override
  bool isObject(SharedTypeView type) {
    Type unwrappedType = type.unwrapTypeView();
    return unwrappedType is PrimaryType &&
        !unwrappedType.isQuestionType &&
        unwrappedType.name == 'Object' &&
        unwrappedType.args.isEmpty;
  }

  @override
  bool isPropertyPromotable(covariant _PropertyElement property) =>
      property.isPromotable;

  @override
  bool isSubtypeOfInternal(Type leftType, Type rightType) {
    return _typeSystem.isSubtype(leftType, rightType);
  }

  @override
  bool isTypeParameterType(SharedTypeView type) {
    Type unwrappedType = type.unwrapTypeView();
    return unwrappedType is TypeParameterType && !unwrappedType.isQuestionType;
  }

  @override
  bool isTypeSchemaSatisfied({
    required SharedTypeSchemaView typeSchema,
    required SharedTypeView type,
  }) {
    return isSubtypeOfInternal(
      type.unwrapTypeView<Type>(),
      typeSchema.unwrapTypeSchemaView<Type>(),
    );
  }

  @override
  bool isVariableFinal(Var node) {
    return node.isFinal;
  }

  @override
  SharedTypeSchemaView iterableTypeSchema(
    SharedTypeSchemaView elementTypeSchema,
  ) {
    return SharedTypeSchemaView(
      PrimaryType(
        TypeRegistry.iterable,
        args: [elementTypeSchema.unwrapTypeSchemaView<Type>()],
      ),
    );
  }

  @override
  SharedTypeView leastClosureOfSchema(SharedTypeSchemaView schema) {
    // TODO(paulberry): Implement leastClosureOfSchema in mini ast.
    throw UnimplementedError();
  }

  @override
  Type leastClosureOfTypeInternal(
    Type type,
    List<SharedTypeParameter> typeParametersToEliminate,
  ) {
    // TODO(paulberry): Implement greatest closure of types in mini ast.
    throw UnimplementedError();
  }

  @override
  Type listTypeInternal(Type elementType) {
    return PrimaryType(TypeRegistry.list, args: [elementType]);
  }

  @override
  Type lubInternal(Type type1, Type type2) {
    if (type1 == type2) {
      return type1;
    } else if (promoteToNonNull(SharedTypeView(type1)) ==
        SharedTypeView(type2)) {
      return type1;
    } else if (promoteToNonNull(SharedTypeView(type2)) ==
        SharedTypeView(type1)) {
      return type2;
    } else if (type1 is NullType &&
        promoteToNonNull(SharedTypeView(type2)) != SharedTypeView(type2)) {
      // type2 is already nullable
      return type2;
    } else if (type2 is NullType &&
        promoteToNonNull(SharedTypeView(type1)) != SharedTypeView(type1)) {
      // type1 is already nullable
      return type1;
    } else if (type1 is NeverType && !type1.isQuestionType) {
      return type2;
    } else if (type2 is NeverType && !type2.isQuestionType) {
      return type1;
    } else {
      var typeNames = [type1.type, type2.type];
      typeNames.sort();
      var query = typeNames.join(', ');
      return _lubs[query] ?? fail('Unknown lub query: $query');
    }
  }

  @override
  Type makeNullableInternal(Type type) => lubInternal(type, NullType.instance);

  @override
  Type mapTypeInternal({required Type keyType, required Type valueType}) {
    return PrimaryType(TypeRegistry.map, args: [keyType, valueType]);
  }

  @override
  Type? matchFutureOrInternal(Type type) {
    if (type is FutureOrType) {
      return type.typeArgument;
    }
    return null;
  }

  @override
  TypeParameter? matchInferableParameterInternal(Type type) {
    if (type case TypeParameterType(
      :var typeParameter,
      isQuestionType: false,
    )) {
      return typeParameter;
    } else {
      return null;
    }
  }

  @override
  Type? matchIterableTypeInternal(Type type) {
    if (type is PrimaryType && !type.isQuestionType && type.args.length == 1) {
      if (type.name == 'Iterable' || type.name == 'List') {
        return type.args[0];
      }
    }
    return null;
  }

  @override
  SharedTypeView? matchListType(SharedTypeView type) {
    Type unwrappedType = type.unwrapTypeView();
    if (unwrappedType is PrimaryType &&
        !unwrappedType.isQuestionType &&
        unwrappedType.name == 'List' &&
        unwrappedType.args.length == 1) {
      return SharedTypeView(unwrappedType.args[0]);
    }
    return null;
  }

  @override
  ({SharedTypeView keyType, SharedTypeView valueType})? matchMapType(
    SharedTypeView type,
  ) {
    Type unwrappedType = type.unwrapTypeView();
    if (unwrappedType is PrimaryType &&
        !unwrappedType.isQuestionType &&
        unwrappedType.name == 'Map' &&
        unwrappedType.args.length == 2) {
      return (
        keyType: SharedTypeView(unwrappedType.args[0]),
        valueType: SharedTypeView(unwrappedType.args[1]),
      );
    }
    return null;
  }

  @override
  SharedTypeView? matchStreamType(SharedTypeView type) {
    Type unwrappedType = type.unwrapTypeView();
    if (unwrappedType is PrimaryType &&
        !unwrappedType.isQuestionType &&
        unwrappedType.args.length == 1) {
      if (unwrappedType.name == 'Stream') {
        return SharedTypeView(unwrappedType.args[0]);
      }
    }
    return null;
  }

  @override
  TypeDeclarationMatchResult<Type, String>? matchTypeDeclarationTypeInternal(
    Type type,
  ) {
    if (type is! PrimaryType) return null;
    TypeDeclarationKind typeDeclarationKind;
    if (type.isInterfaceType) {
      typeDeclarationKind = TypeDeclarationKind.interfaceDeclaration;
    } else if (isExtensionTypeInternal(type)) {
      typeDeclarationKind = TypeDeclarationKind.extensionTypeDeclaration;
    } else {
      return null;
    }
    return new TypeDeclarationMatchResult(
      typeDeclarationKind: typeDeclarationKind,
      typeDeclaration: type.name,
      typeDeclarationType: type,
      typeArguments: type.args,
    );
  }

  @override
  Type? matchTypeParameterBoundInternal(Type type) {
    if (type case TypeParameterType(
      :var promotion,
      :var typeParameter,
      isQuestionType: false,
    )) {
      return promotion ?? typeParameter.bound;
    } else {
      return null;
    }
  }

  @override
  SharedTypeView normalize(SharedTypeView type) {
    var query = '${type.unwrapTypeView()}';
    return SharedTypeView(
      _normalizeResults[query] ?? fail('Unknown query: $query'),
    );
  }

  @override
  SharedTypeView promoteToNonNull(SharedTypeView type) {
    Type unwrappedType = type.unwrapTypeView();
    if (unwrappedType.isQuestionType) {
      return SharedTypeView(unwrappedType.asQuestionType(false));
    } else if (unwrappedType is NullType) {
      return SharedTypeView(NeverType.instance);
    } else {
      return type;
    }
  }

  @override
  RecordType recordTypeInternal({
    required List<SharedType> positional,
    required covariant List<(String, SharedType)> named,
  }) {
    return RecordType(
      positionalTypes: positional.cast<Type>(),
      namedTypes: [
        for (var (name, type) in named)
          NamedType(name: name, type: type as Type),
      ]..sort((a, b) => a.name.compareTo(b.name)),
    );
  }

  @override
  SharedTypeSchemaView streamTypeSchema(
    SharedTypeSchemaView elementTypeSchema,
  ) {
    return SharedTypeSchemaView(
      PrimaryType(
        TypeRegistry.stream,
        args: [elementTypeSchema.unwrapTypeSchemaView<Type>()],
      ),
    );
  }

  @override
  SharedType substituteTypeFromIterables(
    SharedType typeToSubstitute,
    List<SharedTypeParameter> typeParameters,
    List<SharedType> types,
  ) {
    // TODO(paulberry): Implement substituteTypeFromIterables.
    throw UnimplementedError();
  }

  @override
  SharedTypeView? tryPromoteToType(SharedTypeView to, SharedTypeView from) {
    var exception =
        (_promotionExceptions[from.unwrapTypeView<Type>().type] ?? {})[to
            .unwrapTypeView<Type>()
            .type];
    if (exception != null) {
      return SharedTypeView(Type(exception));
    }
    if (isSubtypeOfInternal(
      to.unwrapTypeView<Type>(),
      from.unwrapTypeView<Type>(),
    )) {
      return to;
    } else {
      return null;
    }
  }

  @override
  SharedTypeSchemaView typeToSchema(SharedTypeView type) =>
      SharedTypeSchemaView(type.unwrapTypeView());

  @override
  SharedTypeView variableType(Var variable) {
    return SharedTypeView(variable.type);
  }

  @override
  PropertyNonPromotabilityReason? whyPropertyIsNotPromotable(
    covariant _PropertyElement property,
  ) => property.whyNotPromotable;
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

  factory Node.placeholder() => Node._(location: computeLocation());

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
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
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
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
    return h.typeAnalyzer.analyzeLogicalNot(this, operand);
  }
}

class NullCheckOrAssertPattern extends Pattern {
  final Pattern inner;

  final bool isAssert;

  NullCheckOrAssertPattern._(
    this.inner,
    this.isAssert, {
    required super.location,
  }) : super._();

  @override
  SharedTypeSchemaView computeSchema(Harness h) => h.typeAnalyzer
      .analyzeNullCheckOrAssertPatternSchema(inner, isAssert: isAssert);

  @override
  void preVisit(
    PreVisitor visitor,
    VariableBinder<Node, Var> variableBinder, {
    required bool isInAssignment,
  }) {
    inner.preVisit(visitor, variableBinder, isInAssignment: isInAssignment);
  }

  @override
  PatternResult visit(Harness h, SharedMatchContext context) {
    var analysisResult = h.typeAnalyzer.analyzeNullCheckOrAssertPattern(
      context,
      this,
      inner,
      isAssert: isAssert,
    );
    var matchedType = analysisResult.matchedValueType.unwrapTypeView<Type>();
    h.irBuilder.atom(matchedType.type, Kind.type, location: location);
    h.irBuilder.apply(
      isAssert ? 'nullAssertPattern' : 'nullCheckPattern',
      [Kind.pattern, Kind.type],
      Kind.pattern,
      names: ['matchedType'],
      location: location,
    );
    return analysisResult;
  }

  @override
  String _debugString({required bool needsKeywordOrType}) =>
      '${inner._debugString(needsKeywordOrType: needsKeywordOrType)}?';
}

class NullLiteral extends ConstExpression {
  NullLiteral._({required super.location}) : super._();

  @override
  void preVisit(PreVisitor visitor) {}

  @override
  String toString() => 'null';

  @override
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
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
  SharedTypeSchemaView computeSchema(Harness h) {
    return h.typeAnalyzer.analyzeObjectPatternSchema(
      SharedTypeView(requiredType),
    );
  }

  @override
  void preVisit(
    PreVisitor visitor,
    VariableBinder<Node, Var> variableBinder, {
    required bool isInAssignment,
  }) {
    for (var field in fields) {
      field.pattern.preVisit(
        visitor,
        variableBinder,
        isInAssignment: isInAssignment,
      );
    }
  }

  @override
  PatternResult visit(Harness h, SharedMatchContext context) {
    var objectPatternResult = h.typeAnalyzer.analyzeObjectPattern(
      context,
      this,
      fields: fields,
    );
    var matchedType = objectPatternResult.matchedValueType
        .unwrapTypeView<Type>();
    var requiredType = objectPatternResult.requiredType.unwrapTypeView<Type>();
    h.irBuilder.atom(matchedType.type, Kind.type, location: location);
    h.irBuilder.atom(requiredType.type, Kind.type, location: location);
    h.irBuilder.apply(
      'objectPattern',
      [...List.filled(fields.length, Kind.pattern), Kind.type, Kind.type],
      Kind.pattern,
      names: ['matchedType', 'requiredType'],
      location: location,
    );
    return objectPatternResult;
  }

  @override
  String _debugString({required bool needsKeywordOrType}) {
    var fieldStrings = [
      for (var field in fields)
        field.pattern._debugString(needsKeywordOrType: needsKeywordOrType),
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
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
    return h.typeAnalyzer.analyzeParenthesizedExpression(this, expr, schema);
  }
}

class ParenthesizedPattern extends Pattern {
  final Pattern inner;

  ParenthesizedPattern._(this.inner, {required super.location}) : super._();

  @override
  SharedTypeSchemaView computeSchema(Harness h) => inner.computeSchema(h);

  @override
  void preVisit(
    PreVisitor visitor,
    VariableBinder<Node, Var> variableBinder, {
    required bool isInAssignment,
  }) => inner.preVisit(visitor, variableBinder, isInAssignment: isInAssignment);

  @override
  PatternResult visit(Harness h, SharedMatchContext context) {
    return inner.visit(h, context);
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
    return GuardedPattern._(pattern: this, guard: null, location: location);
  }

  Pattern and(Pattern other) =>
      LogicalAndPattern._(this, other, location: computeLocation());

  Pattern as_(String type) =>
      new CastPattern(this, Type(type), location: computeLocation());

  /// Creates a pattern assignment expression assigning [rhs] to this pattern.
  Expression assign(ProtoExpression rhs) {
    var location = computeLocation();
    return PatternAssignment._(
      this,
      rhs.asExpression(location: location),
      location: location,
    );
  }

  SharedTypeSchemaView computeSchema(Harness h);

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

  PatternResult visit(Harness h, SharedMatchContext context);

  GuardedPattern when(ProtoExpression? guard) {
    return GuardedPattern._(
      pattern: this,
      guard: guard?.asExpression(location: location),
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
    var variableBinder = _VariableBinder(visitor);
    variableBinder.casePatternStart();
    lhs.preVisit(visitor, variableBinder, isInAssignment: true);
    variableBinder.casePatternFinish();
    variableBinder.finish();
    rhs.preVisit(visitor);
  }

  @override
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
    var result = h.typeAnalyzer.analyzePatternAssignment(this, lhs, rhs);
    h.irBuilder.apply(
      'patternAssignment',
      [Kind.expression, Kind.pattern],
      Kind.expression,
      location: location,
    );
    return result;
  }
}

class PatternForIn extends Statement {
  final bool hasAwait;
  final Pattern pattern;
  final Expression expression;
  final Statement body;

  PatternForIn(
    this.pattern,
    this.expression,
    this.body, {
    required this.hasAwait,
    required super.location,
  });

  @override
  void preVisit(PreVisitor visitor) {
    expression.preVisit(visitor);

    var variableBinder = _VariableBinder(visitor);
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
      },
    );
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

  PatternForInElement(
    this.pattern,
    this.expression,
    this.body, {
    required this.hasAwait,
    required super.location,
  });

  @override
  void preVisit(PreVisitor visitor) {
    expression.preVisit(visitor);

    var variableBinder = _VariableBinder(visitor);
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
      },
    );
    h.irBuilder.apply(
      'forEach',
      [Kind.expression, Kind.pattern, Kind.collectionElement],
      Kind.collectionElement,
      location: location,
    );
  }
}

class PatternVariableDeclaration extends Statement {
  final bool isFinal;
  final Pattern pattern;
  final Expression initializer;

  PatternVariableDeclaration._(
    this.pattern,
    this.initializer, {
    required this.isFinal,
    required super.location,
  });

  @override
  void preVisit(PreVisitor visitor) {
    var variableBinder = _VariableBinder(visitor);
    variableBinder.casePatternStart();
    pattern.preVisit(visitor, variableBinder, isInAssignment: false);
    variableBinder.casePatternFinish();
    variableBinder.finish();
    initializer.preVisit(visitor);
  }

  @override
  String toString() {
    var parts = <String>[
      if (isFinal) 'final',
      pattern._debugString(needsKeywordOrType: !isFinal),
      '= $initializer',
    ];
    return '${parts.join(' ')};';
  }

  @override
  void visit(Harness h) {
    h.typeAnalyzer.analyzePatternVariableDeclaration(
      this,
      pattern,
      initializer,
      isFinal: isFinal,
    );
    h.irBuilder.apply(
      ['match', if (isFinal) 'final'].join('_'),
      [Kind.expression, Kind.pattern],
      Kind.statement,
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

  PatternVariableJoin(
    super.name, {
    required this.expectedComponents,
    super.identity,
  }) : super(location: computeLocation()) {
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
    var componentsStr = expectedComponents
        .map((v) => v.stringToCheckVariables)
        .join(', ');
    return '$declarationStr = [$componentsStr]';
  }

  /// Called by [VariableBinder.joinPatternVariables].
  void _handleJoin({
    required List<Var> components,
    required JoinedPatternVariableInconsistency inconsistency,
    required PreVisitor visitor,
  }) {
    expect(isJoined, false);
    expect(
      components.map((c) => c.identity),
      expectedComponents.map((c) => c.identity),
      reason: 'at $location',
    );
    expect(components, expectedComponents, reason: 'at $location');
    this.inconsistency = inconsistency;
    this.isJoined = true;
    visitor._assignedVariables.declare(this);
  }
}

class PlaceholderExpression extends ConstExpression {
  final Type type;

  PlaceholderExpression._(this.type, {required super.location}) : super._();

  @override
  void preVisit(PreVisitor visitor) {}

  @override
  String toString() => '(expr with type $type)';

  @override
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
    h.irBuilder.atom(type.type, Kind.type, location: location);
    h.irBuilder.apply('expr', [Kind.type], Kind.expression, location: location);
    return new ExpressionTypeAnalysisResult(type: SharedTypeView(type));
  }
}

/// Mixin containing logic shared by [Pattern] and [GuardedPattern].  Both of
/// these types can be used in a case where a pattern with an optional guard is
/// expected.
mixin PossiblyGuardedPattern on Node implements ProtoSwitchHead {
  @override
  SwitchHead get asSwitchHead =>
      SwitchHeadCase._(_asGuardedPattern, location: location);

  /// Converts `this` to a [GuardedPattern], including a `null` guard if
  /// necessary.
  GuardedPattern get _asGuardedPattern;

  SwitchStatementMember then(List<ProtoStatement> body) {
    return SwitchStatementMember._(
      [SwitchHeadCase._(_asGuardedPattern, location: location)],
      Block._(body, location: location),
      hasLabels: false,
      location: location,
    );
  }

  ExpressionCase thenExpr(ProtoExpression body) {
    var location = computeLocation();
    return ExpressionCase._(
      _asGuardedPattern,
      body.asExpression(location: location),
      location: location,
    );
  }
}

/// Representation of a postfix increment or decrement operation.
class PostIncDec extends Expression {
  final LValue lhs;

  PostIncDec(this.lhs, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    lhs.preVisit(visitor, disposition: _LValueDisposition.readWrite);
  }

  @override
  String toString() => '$lhs++';

  @override
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
    Type type = h.typeAnalyzer
        .analyzeExpression(lhs, h.operations.unknownType)
        .unwrapTypeView();
    lhs._visitPostIncDec(h, this, type);
    return new ExpressionTypeAnalysisResult(type: SharedTypeView(type));
  }
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

  /// Queries the current promotion status of `this`.  Return value is a list of
  /// types, in order from least promoted type to most promoted type, or an
  ///  empty list if `this` is not promoted.
  List<Type> _getPromotionChain(Harness h);
}

/// Base class for l-values that, at a given point in flow analysis, might or
/// might not be promoted.
abstract class PromotableLValue extends LValue implements Promotable {
  PromotableLValue._({required super.location}) : super._();
}

class Property extends PromotableLValue {
  final Expression target;

  final String propertyName;

  final bool isNullAware;

  Property._(
    this.target,
    this.propertyName, {
    required super.location,
    required this.isNullAware,
  }) : super._();

  @override
  void preVisit(
    PreVisitor visitor, {
    _LValueDisposition disposition = _LValueDisposition.read,
  }) {
    target.preVisit(visitor);
  }

  @override
  String toString() {
    var q = isNullAware ? '?' : '';
    return '$target$q.$propertyName';
  }

  @override
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
    return h.typeAnalyzer.analyzePropertyGet(
      this,
      target is CascadePlaceholder ? null : target,
      propertyName,
      isNullAware: isNullAware,
    );
  }

  _PropertyElement? _computeMember(Harness h) {
    if (isNullAware) {
      fail(
        "at $location: it doesn't make sense to compute the promoted type of "
        'a null-aware property.',
      );
    }
    var receiverType = h.typeAnalyzer
        .analyzeExpression(target, h.operations.unknownType)
        .unwrapTypeView<Type>();
    var member = h.typeAnalyzer._lookupMember(receiverType, propertyName);
    return member;
  }

  @override
  Type? _getPromotedType(Harness h) {
    _PropertyElement? member = _computeMember(h);
    return h.flow
        .promotedPropertyType(
          ExpressionPropertyTarget(target),
          propertyName,
          member,
          SharedTypeView(member!._type),
        )
        ?.unwrapTypeView();
  }

  @override
  List<Type> _getPromotionChain(Harness h) {
    _PropertyElement? member = _computeMember(h);
    return h.flow
        .propertyPromotionChainForTesting(
          ExpressionPropertyTarget(target),
          propertyName,
          member,
        )
        .map((t) => t.unwrapTypeView<Type>())
        .toList();
  }

  @override
  void _visitPostIncDec(
    Harness h,
    Expression postIncDecExpression,
    Type writtenType,
  ) {
    assert(!isNullAware); // TODO(paulberry): implement null-aware support
    // No flow analysis impact
  }

  @override
  void _visitWrite(
    Harness h,
    Expression assignmentExpression,
    Type writtenType,
    Expression? rhs,
  ) {
    assert(!isNullAware); // TODO(paulberry): implement null-aware support
    // No flow analysis impact
  }
}

/// Common functionality shared by constructs that can be used where a
/// collection element is expected, in in the pseudo-Dart language used for flow
/// analysis testing.
///
/// The reason this mixin is distinct from the [CollectionElement] class is
/// because both [Expression]s and other [CollectionElement]s (`if` and `for`
/// elements) can be used where a collection element is expected (because an
/// expression inside a collection simply becomes an
/// [ExpressionCollectionElement]).
mixin ProtoCollectionElement<Self extends ProtoCollectionElement<dynamic>> {
  /// Converts `this` to a [CollectionElement]. If it's already a
  /// [CollectionElement], it is returned unchanged. If it's an [Expression],
  /// it's converted into a collection element.
  ///
  /// In general, tests shouldn't need to call this method directly; instead
  /// they should simply be able to use either an [Expression] or some other
  /// [CollectionElement] in a context where a [CollectionElement] is expected,
  /// and the test infrastructure will call this getter as needed.
  CollectionElement asCollectionElement({required String location});

  /// Wraps `this` in such a way that, when the test is run, it will verify that
  /// the IR produced matches [expectedIR].
  Self checkIR(String expectedIR);
}

/// Common functionality shared by constructs that can be used where an
/// expression is expected, in in the pseudo-Dart language used for flow
/// analysis testing.
///
/// The reason this mixin is distinct from the [Expression] class is because
/// both [Expression]s and [Var]s can be used where a statement is expected
/// (because a [Var] in an expression context simply becomes a read of the
/// variable).
mixin ProtoExpression
    implements ProtoStatement<Expression>, ProtoCollectionElement<Expression> {
  /// If `this` is an expression `x`, creates a dot shorthand wrapper around
  /// `x`.
  Expression get dotShorthand {
    var location = computeLocation();
    return new DotShorthand._(
      asExpression(location: location),
      location: location,
    );
  }

  /// If `this` is an expression `x`, creates the expression `x!`.
  Expression get nonNullAssert {
    var location = computeLocation();
    return new NonNullAssert._(
      asExpression(location: location),
      location: location,
    );
  }

  /// If `this` is an expression `x`, creates the expression `!x`.
  Expression get not {
    var location = computeLocation();
    return new Not._(asExpression(location: location), location: location);
  }

  /// If `this` is an expression `x`, creates the expression `(x)`.
  Expression get parenthesized {
    var location = computeLocation();
    return new ParenthesizedExpression._(
      asExpression(location: location),
      location: location,
    );
  }

  /// If `this` is an expression `x`, creates the expression `x && other`.
  Expression and(ProtoExpression other) {
    var location = computeLocation();
    return new Logical._(
      asExpression(location: location),
      other.asExpression(location: location),
      isAnd: true,
      location: location,
    );
  }

  /// If `this` is an expression `x`, creates the expression `x as typeStr`.
  Expression as_(String typeStr) {
    var location = computeLocation();
    return new As._(
      asExpression(location: location),
      Type(typeStr),
      location: location,
    );
  }

  @override
  CollectionElement asCollectionElement({required String location}) =>
      ExpressionCollectionElement(
        asExpression(location: location),
        location: location,
      );

  /// Converts `this` to an [Expression]. If it's already an [Expression], it is
  /// returned unchanged. If it's something else (e.g. a [Var]), it's converted
  /// into an [Expression].
  ///
  /// In general, tests shouldn't need to call this method directly; instead
  /// they should simply be able to use either anything implementing the
  /// [ProtoExpression] interface in a context where an [Expression] is
  /// expected, and the test infrastructure will call this getter as needed.
  Expression asExpression({required String location});

  @override
  Statement asStatement({required String location}) =>
      new ExpressionStatement._(
        asExpression(location: location),
        location: location,
      );

  /// If `this` is an expression `x`, creates a cascade expression with `x` as
  /// the target, and [sections] as the cascade sections. [isNullAware]
  /// indicates whether this is a null-aware cascade.
  ///
  /// Since each cascade section needs to implicitly refer to the target of the
  /// cascade, the caller should pass in a closure for each cascade section; the
  /// closures will be immediately invoked, passing in a [CascadePlaceholder]
  /// pseudo-expression representing the implicit reference to the cascade
  /// target.
  Expression cascade(
    List<ProtoExpression Function(CascadePlaceholder)> sections, {
    bool isNullAware = false,
  }) {
    var location = computeLocation();
    return Cascade._(
      asExpression(location: location),
      [
        for (var section in sections)
          section(
            CascadePlaceholder._(location: location),
          ).asExpression(location: location),
      ],
      isNullAware: isNullAware,
      location: location,
    );
  }

  /// Wraps `this` in such a way that, when the test is run, it will verify that
  /// the IR produced matches [expectedIR].
  @override
  Expression checkIR(String expectedIR) {
    var location = computeLocation();
    return asExpression(location: location).._expectedIR = expectedIR;
  }

  /// Wraps `this` in such a way that, when the test is run, it will verify that
  /// the context provided when analyzing the expression matches
  /// [expectedSchema].
  Expression checkSchema(String expectedSchema) {
    var location = computeLocation();
    return asExpression(location: location).._expectedSchema = expectedSchema;
  }

  /// Creates an [Expression] that, when analyzed, will behave the same as
  /// `this`, but after visiting it, will verify that the type of the expression
  /// was [expectedType].
  Expression checkType(String expectedType) {
    var location = computeLocation();
    return asExpression(location: location).._expectedType = expectedType;
  }

  /// If `this` is an expression `x`, creates the expression
  /// `x ? ifTrue : ifFalse`.
  Expression conditional(ProtoExpression ifTrue, ProtoExpression ifFalse) {
    var location = computeLocation();
    return new Conditional._(
      asExpression(location: location),
      ifTrue.asExpression(location: location),
      ifFalse.asExpression(location: location),
      location: location,
    );
  }

  /// If `this` is an expression `x`, creates the expression `x == other`.
  Expression eq(ProtoExpression other) {
    var location = computeLocation();
    return new Equal._(
      asExpression(location: location),
      other.asExpression(location: location),
      false,
      location: location,
    );
  }

  /// If `this` is an expression `x`, creates the expression `x ?? other`.
  Expression ifNull(ProtoExpression other) {
    var location = computeLocation();
    return new IfNull._(
      asExpression(location: location),
      other.asExpression(location: location),
      location: location,
    );
  }

  /// Creates a [Statement] that, when analyzed, will analyze `this`, supplying
  /// a type schema of [typeSchema].
  Statement inTypeSchema(String typeSchema) {
    var location = computeLocation();
    return ExpressionInTypeSchema._(
      asExpression(location: location),
      SharedTypeSchemaView(Type(typeSchema)),
      location: location,
    );
  }

  /// If `this` is an expression `x`, creates a method invocation with `x` as
  /// the target, [name] as the method name, and [arguments] as the method
  /// arguments. Named arguments are not supported.
  Expression invokeMethod(
    String name,
    List<ProtoExpression> arguments, {
    bool isNullAware = false,
  }) {
    var location = computeLocation();
    return new InvokeMethod._(
      asExpression(location: location),
      name,
      [
        for (var argument in arguments)
          argument.asExpression(location: location),
      ],
      isNullAware: isNullAware,
      location: location,
    );
  }

  /// If `this` is an expression `x`, creates the expression `x is typeStr`.
  ///
  /// With [isInverted] set to `true`, creates the expression `x is! typeStr`.
  Expression is_(String typeStr, {bool isInverted = false}) {
    var location = computeLocation();
    return new Is._(
      asExpression(location: location),
      Type(typeStr),
      isInverted,
      location: location,
    );
  }

  /// If `this` is an expression `x`, creates the expression `x is! typeStr`.
  Expression isNot(String typeStr) {
    var location = computeLocation();
    return Is._(
      asExpression(location: location),
      Type(typeStr),
      true,
      location: location,
    );
  }

  /// If `this` is an expression `x`, creates the expression `x != other`.
  Expression notEq(ProtoExpression other) {
    var location = computeLocation();
    return Equal._(
      asExpression(location: location),
      other.asExpression(location: location),
      true,
      location: location,
    );
  }

  /// If `this` is an expression `x`, creates the expression `x || other`.
  Expression or(ProtoExpression other) {
    var location = computeLocation();
    return new Logical._(
      asExpression(location: location),
      other.asExpression(location: location),
      isAnd: false,
      location: location,
    );
  }

  /// If `this` is an expression `x`, creates the L-value `x.name`.
  PromotableLValue property(String name, {bool isNullAware = false}) {
    var location = computeLocation();
    return new Property._(
      asExpression(location: location),
      name,
      location: location,
      isNullAware: isNullAware,
    );
  }

  /// If `this` is an expression `x`, creates a pseudo-expression that models
  /// evaluation of `x` followed by execution of [stmt].  This can be used to
  /// test that flow analysis is in the correct state after an expression is
  /// visited.
  Expression thenStmt(ProtoStatement stmt) {
    var location = computeLocation();
    return new WrappedExpression._(
      null,
      asExpression(location: location),
      stmt.asStatement(location: location),
      location: location,
    );
  }
}

/// Common functionality shared by constructs that can be used where a statement
/// is expected, in in the pseudo-Dart language used for flow analysis testing.
///
/// The reason this mixin is distinct from the [Statement] class is because both
/// [Expression]s and [Statement]s can be used where a statement is expected
/// (because an [Expression] in a statement context simply becomes an expression
/// statement).
mixin ProtoStatement<Self extends ProtoStatement<dynamic>> {
  /// Converts `this` to a [Statement]. If it's already a [Statement], it is
  /// returned unchanged. If it's an [Expression], it's converted into an
  /// expression statement.
  ///
  /// In general, tests shouldn't need to call this method directly; instead
  /// they should simply be able to use either a [Statement] or an [Expression]
  /// in a context where a statement is expected, and the test infrastructure
  /// will call this getter as needed.
  Statement asStatement({required String location});

  /// Wraps `this` in such a way that, when the test is run, it will verify that
  /// the IR produced matches [expectedIR].
  Self checkIR(String expectedIR);
}

/// Common interface shared by constructs that can be used where a switch head
/// (pattern with optional guard, or `default`) is expected, in the pseudo-Dart
/// language used for flow analysis testing.
abstract class ProtoSwitchHead {
  /// Converts `this` to a [SwitchHead]. If it's already a [SwitchHead], it is
  /// returned unchanged. If it's a [PossiblyGuardedPattern], it's converted
  /// into a [SwitchHeadCase]
  ///
  /// In general, tests shouldn't need to call this getter directly; instead
  /// they should simply be able to use a [Pattern], [GuardedPattern], or
  /// [default_] in a context where a switch head is expected, and the test
  /// infrastructure will call this getter as needed.
  SwitchHead get asSwitchHead;
}

class RecordPattern extends Pattern {
  final List<RecordPatternField> fields;

  RecordPattern._(this.fields, {required super.location}) : super._();

  @override
  SharedTypeSchemaView computeSchema(Harness h) {
    return h.typeAnalyzer.analyzeRecordPatternSchema(fields: fields);
  }

  @override
  void preVisit(
    PreVisitor visitor,
    VariableBinder<Node, Var> variableBinder, {
    required bool isInAssignment,
  }) {
    for (var field in fields) {
      field.pattern.preVisit(
        visitor,
        variableBinder,
        isInAssignment: isInAssignment,
      );
    }
  }

  @override
  PatternResult visit(Harness h, SharedMatchContext context) {
    var recordPatternResult = h.typeAnalyzer.analyzeRecordPattern(
      context,
      this,
      fields: fields,
    );
    var matchedType = recordPatternResult.matchedValueType
        .unwrapTypeView<Type>();
    var requiredType = recordPatternResult.requiredType.unwrapTypeView<Type>();
    h.irBuilder.atom(matchedType.type, Kind.type, location: location);
    h.irBuilder.atom(requiredType.type, Kind.type, location: location);
    h.irBuilder.apply(
      'recordPattern',
      [...List.filled(fields.length, Kind.pattern), Kind.type, Kind.type],
      Kind.pattern,
      names: ['matchedType', 'requiredType'],
      location: location,
    );
    return recordPatternResult;
  }

  @override
  String _debugString({required bool needsKeywordOrType}) {
    var fieldStrings = [
      for (var field in fields)
        field.pattern._debugString(needsKeywordOrType: needsKeywordOrType),
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
  SharedTypeSchemaView computeSchema(Harness h) =>
      h.typeAnalyzer.analyzeRelationalPatternSchema();

  @override
  void preVisit(
    PreVisitor visitor,
    VariableBinder<Node, Var> variableBinder, {
    required bool isInAssignment,
  }) {
    operand.preVisit(visitor);
  }

  @override
  PatternResult visit(Harness h, SharedMatchContext context) {
    var analysisResult = h.typeAnalyzer.analyzeRelationalPattern(
      context,
      this,
      operand,
    );
    var matchedType = analysisResult.matchedValueType.unwrapTypeView<Type>();
    h.irBuilder.atom(matchedType.type, Kind.type, location: location);
    h.irBuilder.apply(
      operator,
      [Kind.expression, Kind.type],
      Kind.pattern,
      names: ['matchedType'],
      location: location,
    );
    return analysisResult;
  }

  @override
  _debugString({required bool needsKeywordOrType}) => '$operator $operand';
}

class RestPattern extends Node
    implements ListPatternElement, MapPatternElement {
  final Pattern? subPattern;

  RestPattern._(this.subPattern, {required super.location}) : super._();

  @override
  void preVisit(
    PreVisitor visitor,
    VariableBinder<Node, Var> variableBinder, {
    required bool isInAssignment,
  }) {
    subPattern?.preVisit(
      visitor,
      variableBinder,
      isInAssignment: isInAssignment,
    );
  }

  @override
  String _debugString({required bool needsKeywordOrType}) {
    var subPattern = this.subPattern;
    if (subPattern == null) {
      return '...';
    } else {
      return '...${subPattern._debugString(needsKeywordOrType: false)}';
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

/// Representation of an invocation of a function `Second`, defined as follows:
///
///     T second(dynamic x, T y) => y;
class Second extends Expression {
  final Expression first;
  final Expression second;

  Second._(this.first, this.second, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    first.preVisit(visitor);
    second.preVisit(visitor);
  }

  @override
  String toString() => 'second($first, $second)';

  @override
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
    h.typeAnalyzer.analyzeExpression(first, h.operations.unknownType);
    var type = h.typeAnalyzer.analyzeExpression(second, schema);
    h.irBuilder.apply(
      'second',
      [Kind.expression, Kind.expression],
      Kind.expression,
      location: location,
    );
    return ExpressionTypeAnalysisResult(type: type);
  }
}

/// Representation of a statement in the pseudo-Dart language used for flow
/// analysis testing.
abstract class Statement extends Node with ProtoStatement<Statement> {
  /// If non-null, the expected IR that should be produced when this statement
  /// is analyzed.
  String? _expectedIR;

  Statement({required super.location}) : super._();

  @override
  Statement asStatement({required String location}) => this;

  @override
  Statement checkIR(String expectedIR) {
    var location = computeLocation();
    return asStatement(location: location).._expectedIR = expectedIR;
  }

  void preVisit(PreVisitor visitor);

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
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
    var result = h.typeAnalyzer.analyzeSwitchExpression(
      this,
      scrutinee,
      cases.length,
      schema,
    );
    h.irBuilder.apply(
      'switchExpr',
      [Kind.expression, ...List.filled(cases.length, Kind.expressionCase)],
      Kind.expression,
      location: location,
    );
    return result;
  }
}

abstract class SwitchHead extends Node implements ProtoSwitchHead {
  SwitchHead._({required super.location}) : super._();

  @override
  SwitchHead get asSwitchHead => this;

  SwitchStatementMember then(List<ProtoStatement> body) {
    return SwitchStatementMember._(
      [this],
      Block._(body, location: location),
      hasLabels: false,
      location: location,
    );
  }

  ExpressionCase thenExpr(ProtoExpression body) {
    var location = computeLocation();
    return ExpressionCase._(
      null,
      body.asExpression(location: location),
      location: location,
    );
  }
}

class SwitchHeadCase extends SwitchHead {
  final GuardedPattern guardedPattern;

  SwitchHeadCase._(this.guardedPattern, {required super.location}) : super._();
}

class SwitchHeadDefault extends SwitchHead {
  SwitchHeadDefault._({required super.location}) : super._();
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

  SwitchStatement(
    this.scrutinee,
    this.cases,
    this.isLegacyExhaustive, {
    required super.location,
    required this.expectHasDefault,
    required this.expectIsExhaustive,
    required this.expectLastCaseTerminates,
    required this.expectRequiresExhaustivenessValidation,
    required this.expectScrutineeType,
  });

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
    var analysisResult = h.typeAnalyzer.analyzeSwitchStatement(
      this,
      scrutinee,
      cases.length,
    );
    expect(analysisResult.hasDefault, expectHasDefault ?? anything);
    expect(analysisResult.isExhaustive, expectIsExhaustive ?? anything);
    expect(
      analysisResult.lastCaseTerminates,
      expectLastCaseTerminates ?? anything,
    );
    expect(
      analysisResult.requiresExhaustivenessValidation,
      expectRequiresExhaustivenessValidation ?? anything,
    );
    expect(
      analysisResult.scrutineeType.unwrapTypeView<Type>().type,
      expectScrutineeType ?? anything,
    );
    h.irBuilder.apply(
      'switch',
      [Kind.expression, ...List.filled(cases.length, Kind.statementCase)],
      Kind.statement,
      location: location,
    );
    h.typeAnalyzer._currentBreakTarget = previousBreakTarget;
    h.typeAnalyzer._currentContinueTarget = previousContinueTarget;
  }
}

/// Representation of a single case clause in a switch statement.  Use
/// [PossiblyGuardedPattern.then] or [SwitchHead.then] to create instances of
/// this class.
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
    var variableBinder = _VariableBinder(visitor);
    variableBinder.switchStatementSharedCaseScopeStart(this);
    for (SwitchHead element in elements) {
      if (element is SwitchHeadCase) {
        variableBinder.casePatternStart();
        element.guardedPattern.pattern.preVisit(
          visitor,
          variableBinder,
          isInAssignment: false,
        );
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
    _candidateVariables = variableBinder.switchStatementSharedCaseScopeFinish(
      this,
    );
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
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
    var result = h.typeAnalyzer.analyzeThis(this);
    h.irBuilder.atom('this', Kind.expression, location: location);
    return result;
  }
}

class ThisOrSuperProperty extends PromotableLValue {
  final String propertyName;
  final bool isSuperAccess;

  ThisOrSuperProperty._(
    this.propertyName, {
    required super.location,
    required this.isSuperAccess,
  }) : super._();

  @override
  void preVisit(
    PreVisitor visitor, {
    _LValueDisposition disposition = _LValueDisposition.read,
  }) {}

  @override
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
    var result = h.typeAnalyzer.analyzeThisOrSuperPropertyGet(
      this,
      propertyName,
      isSuperAccess: isSuperAccess,
    );
    var thisOrSuper = isSuperAccess ? 'super' : 'this';
    h.irBuilder.atom(
      '$thisOrSuper.$propertyName',
      Kind.expression,
      location: location,
    );
    return result;
  }

  _PropertyElement? _computeMember(Harness h) {
    var thisOrSuper = isSuperAccess ? 'super' : 'this';
    h.irBuilder.atom(
      '$thisOrSuper.$propertyName',
      Kind.expression,
      location: location,
    );
    var member = h.typeAnalyzer._lookupMember(h._thisType!, propertyName);
    return member;
  }

  @override
  Type? _getPromotedType(Harness h) {
    _PropertyElement? member = _computeMember(h);
    return h.flow
        .promotedPropertyType(
          isSuperAccess
              ? SuperPropertyTarget.singleton
              : ThisPropertyTarget.singleton,
          propertyName,
          member,
          SharedTypeView(member!._type),
        )
        ?.unwrapTypeView();
  }

  @override
  List<Type> _getPromotionChain(Harness h) {
    _PropertyElement? member = _computeMember(h);
    return h.flow
        .propertyPromotionChainForTesting(
          isSuperAccess
              ? SuperPropertyTarget.singleton
              : ThisPropertyTarget.singleton,
          propertyName,
          member,
        )
        .map((t) => t.unwrapTypeView<Type>())
        .toList();
  }

  @override
  void _visitPostIncDec(
    Harness h,
    Expression postIncDecExpression,
    Type writtenType,
  ) {
    // No flow analysis impact
  }

  @override
  void _visitWrite(
    Harness h,
    Expression assignmentExpression,
    Type writtenType,
    Expression? rhs,
  ) {
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
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
    return h.typeAnalyzer.analyzeThrow(this, operand);
  }
}

abstract class TryBuilder {
  TryStatement catch_({
    String? type,
    Var? exception,
    Var? stackTrace,
    required List<ProtoStatement> body,
  });

  Statement finally_(List<ProtoStatement> statements);
}

abstract class TryStatement extends Statement implements TryBuilder {
  TryStatement._({required super.location});
}

class TryStatementImpl extends TryStatement {
  final Statement body;
  final List<CatchClause> catches;
  final Statement? finallyStatement;

  TryStatementImpl(
    this.body,
    this.catches,
    this.finallyStatement, {
    required super.location,
  }) : super._();

  @override
  TryStatement catch_({
    String? type,
    Var? exception,
    Var? stackTrace,
    required List<ProtoStatement> body,
  }) {
    assert(finallyStatement == null, 'catch after finally');
    return TryStatementImpl(
      this.body,
      [
        ...catches,
        CatchClause._(
          Block._(body, location: computeLocation()),
          type == null ? null : Type(type),
          exception,
          stackTrace,
        ),
      ],
      null,
      location: location,
    );
  }

  @override
  Statement finally_(List<ProtoStatement> statements) {
    assert(finallyStatement == null, 'multiple finally clauses');
    return TryStatementImpl(
      body,
      catches,
      Block._(statements, location: computeLocation()),
      location: location,
    );
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
        Kind.statement,
      ],
      Kind.statement,
      location: location,
    );
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
class Var extends Node
    with
        ProtoStatement<Expression>,
        ProtoCollectionElement<Expression>,
        ProtoExpression
    implements Promotable {
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

  @override
  LValue asExpression({required String location}) =>
      new VariableReference._(this, null, location: location);

  Pattern pattern({String? type, String? expectInferredType}) =>
      new VariablePattern._(
        type == null ? null : Type(type),
        this,
        expectInferredType,
        location: computeLocation(),
      );

  /// Creates an expression representing a postfix increment or decrement
  /// operation applied to this variable.
  Expression postIncDec() {
    var location = computeLocation();
    return new PostIncDec(
      new VariableReference._(this, null, location: location),
      location: location,
    );
  }

  @override
  void preVisit(PreVisitor visitor) {}

  /// Creates an expression representing a read of this variable, which as a
  /// side effect will call the given callback with the returned promoted type.
  Expression readAndCheckPromotedType(void Function(Type?) callback) =>
      new VariableReference._(this, callback, location: computeLocation());

  @override
  String toString() => 'var $name';

  /// Creates an expression representing a write to this variable.
  Expression write(ProtoExpression? value) {
    var location = computeLocation();
    return new Write(
      new VariableReference._(this, null, location: location),
      value?.asExpression(location: location),
      location: location,
    );
  }

  @override
  Type? _getPromotedType(Harness h) {
    h.irBuilder.atom(name, Kind.expression, location: location);
    return h.flow.promotedType(this)?.unwrapTypeView();
  }

  @override
  List<Type> _getPromotionChain(Harness h) {
    h.irBuilder.atom(name, Kind.expression, location: location);
    return h.flow
        .variablePromotionChainForTesting(this)
        .map((t) => t.unwrapTypeView<Type>())
        .toList();
  }
}

class VariableDeclaration extends Statement {
  final Var variable;
  final bool isLate;
  final bool isFinal;
  final Type? declaredType;
  final Expression? initializer;
  final String? expectInferredType;

  VariableDeclaration._({
    required super.location,
    required this.variable,
    required this.isLate,
    required this.isFinal,
    required this.declaredType,
    required this.initializer,
    required this.expectInferredType,
  });

  @override
  void preVisit(PreVisitor visitor) {
    visitor._assignedVariables.declare(variable);
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
      if (declaredType != null) declaredType!.type else if (!isFinal) 'var',
      variable.name,
      if (expectInferredType != null) '(expected type $expectInferredType)',
      if (initializer != null) '= $initializer',
    ];
    return '${parts.join(' ')};';
  }

  @override
  void visit(Harness h) {
    String irName;
    List<Kind> argKinds;
    List<String> names = const [];
    var initializer = this.initializer;
    h.irBuilder.atom(variable.name, Kind.variable, location: location);
    Type staticType;
    if (initializer == null) {
      // Use the shared logic for analyzing uninitialized variable
      // declarations.
      staticType = h.typeAnalyzer
          .analyzeUninitializedVariableDeclaration(
            this,
            variable,
            declaredType?.wrapSharedTypeView(),
            isFinal: isFinal,
          )
          .unwrapTypeView();
      h.irBuilder.atom(staticType.type, Kind.type, location: location);
      irName = 'declare';
      argKinds = [Kind.variable, Kind.type];
      names = ['staticType'];
    } else {
      // There's no shared logic for analyzing initialized variable
      // declarations, so analyze the declaration directly.
      if (isLate) h.flow.lateInitializer_begin(this);
      var initializerType = h.typeAnalyzer
          .analyzeExpression(
            initializer,
            declaredType?.wrapSharedTypeSchemaView() ??
                h.operations.unknownType,
          )
          .unwrapTypeView<Type>();
      if (isLate) h.flow.lateInitializer_end();
      staticType = variable.type =
          declaredType ??
          h.typeAnalyzer
              .variableTypeFromInitializerType(
                initializerType.wrapSharedTypeView(),
              )
              .unwrapTypeView();
      h.flow.declare(variable, SharedTypeView(staticType), initialized: true);
      h.flow.initialize(
        variable,
        SharedTypeView(initializerType),
        initializer,
        isFinal: isFinal,
        isLate: isLate,
        isImplicitlyTyped: declaredType == null,
      );
      h.irBuilder.atom(initializerType.type, Kind.type, location: location);
      h.irBuilder.atom(staticType.type, Kind.type, location: location);
      irName = 'declare';
      argKinds = [Kind.variable, Kind.expression, Kind.type, Kind.type];
      names = ['initializerType', 'staticType'];
    }
    // Finally, double check the inferred variable type, if necessary for the
    // test.
    var expectInferredType = this.expectInferredType;
    if (expectInferredType != null) {
      expect(staticType.type, expectInferredType, reason: 'at $location');
    }
    h.irBuilder.apply(
      [irName, if (isLate) 'late', if (isFinal) 'final'].join('_'),
      argKinds,
      Kind.statement,
      location: location,
      names: names,
    );
  }
}

class VariablePattern extends Pattern {
  final Type? declaredType;

  final Var variable;

  final String? expectInferredType;

  late bool isAssignedVariable;

  VariablePattern._(
    this.declaredType,
    this.variable,
    this.expectInferredType, {
    required super.location,
  }) : super._();

  @override
  SharedTypeSchemaView computeSchema(Harness h) {
    if (isAssignedVariable) {
      return h.typeAnalyzer.analyzeAssignedVariablePatternSchema(variable);
    } else {
      return h.typeAnalyzer.analyzeDeclaredVariablePatternSchema(
        declaredType?.wrapSharedTypeView(),
      );
    }
  }

  @override
  void preVisit(
    PreVisitor visitor,
    VariableBinder<Node, Var> variableBinder, {
    required bool isInAssignment,
  }) {
    var variable = this.variable;
    isAssignedVariable = isInAssignment;
    if (!isAssignedVariable && variableBinder.add(variable.name, variable)) {
      visitor._assignedVariables.declare(variable);
    }
    if (isAssignedVariable) {
      assert(
        declaredType == null,
        "Variables in pattern assignments can't have declared types",
      );
    }
  }

  @override
  PatternResult visit(Harness h, SharedMatchContext context) {
    if (isAssignedVariable) {
      var analysisResult = h.typeAnalyzer.analyzeAssignedVariablePattern(
        context,
        this,
        variable,
      );
      h.typeAnalyzer.handleAssignedVariablePattern(this);
      return analysisResult;
    } else {
      var declaredVariablePatternResult = h.typeAnalyzer
          .analyzeDeclaredVariablePattern(
            context,
            this,
            variable,
            variable.name,
            declaredType?.wrapSharedTypeView(),
          );
      var matchedType = declaredVariablePatternResult.matchedValueType
          .unwrapTypeView<Type>();
      var staticType = declaredVariablePatternResult.staticType
          .unwrapTypeView<Type>();
      h.typeAnalyzer.handleDeclaredVariablePattern(
        this,
        matchedType: matchedType,
        staticType: staticType,
      );
      return declaredVariablePatternResult;
    }
  }

  @override
  _debugString({required bool needsKeywordOrType}) => [
    if (declaredType != null)
      declaredType!.type
    else if (needsKeywordOrType)
      'var',
    variable.name,
    if (expectInferredType != null) '(expected type $expectInferredType)',
  ].join(' ');
}

class VariableReference extends LValue {
  final Var variable;

  final void Function(Type?)? callback;

  VariableReference._(this.variable, this.callback, {required super.location})
    : super._();

  @override
  void preVisit(
    PreVisitor visitor, {
    _LValueDisposition disposition = _LValueDisposition.read,
  }) {
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
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
    var result = h.typeAnalyzer.analyzeVariableGet(this, variable, callback);
    h.irBuilder.atom(variable.name, Kind.expression, location: location);
    return result;
  }

  @override
  void _visitPostIncDec(
    Harness h,
    Expression postIncDecExpression,
    Type writtenType,
  ) {
    h.flow.postIncDec(
      postIncDecExpression,
      variable,
      SharedTypeView(writtenType),
    );
  }

  @override
  void _visitWrite(
    Harness h,
    Expression assignmentExpression,
    Type writtenType,
    Expression? rhs,
  ) {
    h.flow.write(
      assignmentExpression,
      variable,
      SharedTypeView(writtenType),
      rhs,
    );
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
      'while',
      [Kind.expression, Kind.statement],
      Kind.statement,
      location: location,
    );
  }
}

class WildcardPattern extends Pattern {
  final Type? declaredType;

  final String? expectInferredType;

  WildcardPattern._({
    required this.declaredType,
    required this.expectInferredType,
    required super.location,
  }) : super._();

  @override
  SharedTypeSchemaView computeSchema(Harness h) {
    return h.typeAnalyzer.analyzeWildcardPatternSchema(
      declaredType: declaredType?.wrapSharedTypeView(),
    );
  }

  @override
  void preVisit(
    PreVisitor visitor,
    VariableBinder<Node, Var> variableBinder, {
    required bool isInAssignment,
  }) {}

  @override
  PatternResult visit(Harness h, SharedMatchContext context) {
    var analysisResult = h.typeAnalyzer.analyzeWildcardPattern(
      context: context,
      node: this,
      declaredType: declaredType?.wrapSharedTypeView(),
    );
    var matchedType = analysisResult.matchedValueType.unwrapTypeView<Type>();
    h.irBuilder.atom(matchedType.type, Kind.type, location: location);
    h.irBuilder.apply(
      'wildcardPattern',
      [Kind.type],
      Kind.pattern,
      names: ['matchedType'],
      location: location,
    );
    var expectInferredType = this.expectInferredType;
    if (expectInferredType != null) {
      expect(matchedType.type, expectInferredType, reason: 'at $location');
    }
    return analysisResult;
  }

  @override
  _debugString({required bool needsKeywordOrType}) => [
    if (declaredType != null) declaredType!.type,
    '_',
    if (expectInferredType != null) '(expected type $expectInferredType)',
  ].join(' ');
}

class WrappedExpression extends Expression {
  final Statement? before;
  final Expression expr;
  final Statement? after;

  WrappedExpression._(
    this.before,
    this.expr,
    this.after, {
    required super.location,
  });

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
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
    late MiniIRTmp beforeTmp;
    if (before != null) {
      h.typeAnalyzer.dispatchStatement(before!);
      h.irBuilder.apply(
        'expr',
        [Kind.statement],
        Kind.expression,
        location: location,
      );
      beforeTmp = h.irBuilder.allocateTmp(location: location);
    }
    var type = h.typeAnalyzer.analyzeExpression(expr, h.operations.unknownType);
    if (after != null) {
      var exprTmp = h.irBuilder.allocateTmp(location: location);
      h.typeAnalyzer.dispatchStatement(after!);
      h.irBuilder.apply(
        'expr',
        [Kind.statement],
        Kind.expression,
        location: location,
      );
      var afterTmp = h.irBuilder.allocateTmp(location: location);
      h.irBuilder.readTmp(exprTmp, location: location);
      h.irBuilder.let(afterTmp, location: location);
      h.irBuilder.let(exprTmp, location: location);
    }
    h.flow.forwardExpression(this, expr);
    if (before != null) {
      h.irBuilder.let(beforeTmp, location: location);
    }
    return new ExpressionTypeAnalysisResult(type: type);
  }
}

class Write extends Expression {
  final LValue lhs;
  final Expression? rhs;

  Write(this.lhs, this.rhs, {required super.location});

  @override
  void preVisit(PreVisitor visitor) {
    lhs.preVisit(
      visitor,
      disposition: rhs == null
          ? _LValueDisposition.readWrite
          : _LValueDisposition.write,
    );
    rhs?.preVisit(visitor);
  }

  @override
  String toString() => '$lhs = $rhs';

  @override
  ExpressionTypeAnalysisResult visit(Harness h, SharedTypeSchemaView schema) {
    var rhs = this.rhs;
    Type type;
    if (rhs == null) {
      // We are simulating an increment/decrement operation.
      // TODO(paulberry): Make a separate node type for this.
      type = h.typeAnalyzer
          .analyzeExpression(lhs, h.operations.unknownType)
          .unwrapTypeView();
    } else {
      type = h.typeAnalyzer
          .analyzeExpression(rhs, h.operations.unknownType)
          .unwrapTypeView();
    }
    lhs._visitWrite(h, this, type, rhs);
    // TODO(paulberry): null shorting
    return new ExpressionTypeAnalysisResult(type: SharedTypeView(type));
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
        TypeAnalyzerErrors<
          Node,
          Statement,
          Expression,
          Var,
          SharedTypeView,
          Pattern,
          void
        >,
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
  void caseExpressionTypeMismatch({
    required Expression scrutinee,
    required Expression caseExpression,
    required SharedTypeView scrutineeType,
    required SharedTypeView caseExpressionType,
  }) {
    _recordError('caseExpressionTypeMismatch', {
      'scrutinee': scrutinee,
      'caseExpression': caseExpression,
      'scrutineeType': scrutineeType,
      'caseExpressionType': caseExpressionType,
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
  void emptyMapPattern({required Pattern pattern}) {
    _recordError('emptyMapPattern', {'pattern': pattern});
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
    required SharedTypeView matchedType,
  }) {
    _recordError('matchedTypeIsStrictlyNonNullable', {
      'pattern': pattern,
      'matchedType': matchedType,
    });
  }

  @override
  void matchedTypeIsSubtypeOfRequired({
    required Pattern pattern,
    required SharedTypeView matchedType,
    required SharedTypeView requiredType,
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
    required SharedTypeView expressionType,
  }) {
    _recordError('patternForInExpressionIsNotIterable', {
      'node': node,
      'expression': expression,
      'expressionType': expressionType,
    });
  }

  @override
  void patternTypeMismatchInIrrefutableContext({
    required Node pattern,
    required Node context,
    required SharedTypeView matchedType,
    required SharedTypeView requiredType,
  }) {
    _recordError('patternTypeMismatchInIrrefutableContext', {
      'pattern': pattern,
      'context': context,
      'matchedType': matchedType,
      'requiredType': requiredType,
    });
  }

  @override
  void refutablePatternInIrrefutableContext({
    required Node pattern,
    required Node context,
  }) {
    _recordError('refutablePatternInIrrefutableContext', {
      'pattern': pattern,
      'context': context,
    });
  }

  @override
  void relationalPatternOperandTypeNotAssignable({
    required Pattern pattern,
    required SharedTypeView operandType,
    required SharedTypeView parameterType,
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
    required SharedTypeView returnType,
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
  void switchCaseCompletesNormally({
    required covariant SwitchStatement node,
    required int caseIndex,
  }) {
    _recordError('switchCaseCompletesNormally', {
      'node': node,
      'caseIndex': caseIndex,
    });
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

    String argumentsStr = namedArguments.entries
        .map((entry) {
          return '${entry.key}: ${argumentStr(entry.value)}';
        })
        .join(', ');

    var errorText = '$name($argumentsStr)';

    _assertInErrorRecoveryStack = null;
    if (!_accumulatedErrors.add(errorText)) {
      fail('Same error reported twice: $errorText');
    }
  }
}

class _MiniAstTypeAnalyzer
    with
        TypeAnalyzer<
          Node,
          Statement,
          Expression,
          Var,
          Pattern,
          void,
          Type,
          String
        >,
        NullShortingMixin<MiniIRTmp, Expression, Var, SharedTypeView> {
  final Harness _harness;

  @override
  final _MiniAstErrors errors = _MiniAstErrors();

  Statement? _currentBreakTarget;

  Statement? _currentContinueTarget;

  final _irBuilder = MiniIRBuilder();

  @override
  final TypeAnalyzerOptions typeAnalyzerOptions;

  /// The temporary variable used in the IR to represent the target of the
  /// innermost enclosing cascade expression, or `null` if no cascade expression
  /// is currently being visited.
  MiniIRTmp? _currentCascadeTargetIR;

  /// The type of the target of the innermost enclosing cascade expression
  /// (promoted to non-nullable, if it's a null-aware cascade), or `null` if no
  /// cascade expression is currently being visited.
  SharedTypeView? _currentCascadeTargetType;

  _MiniAstTypeAnalyzer(this._harness, this.typeAnalyzerOptions);

  @override
  FlowAnalysis<Node, Statement, Expression, Var, SharedTypeView> get flow =>
      _harness.flow;

  Type get nullType => NullType.instance;

  @override
  MiniAstOperations get operations => _harness.operations;

  Type get thisType => _harness._thisType!;

  void analyzeAssertStatement(
    Statement node,
    Expression condition,
    Expression? message,
  ) {
    flow.assert_begin();
    analyzeExpression(condition, operations.unknownType);
    flow.assert_afterCondition(condition);
    if (message != null) {
      analyzeExpression(message, operations.unknownType);
    } else {
      handleNoMessage(node);
    }
    flow.assert_end();
  }

  ExpressionTypeAnalysisResult analyzeBinaryExpression(
    Expression node,
    Expression lhs,
    String operatorName,
    Expression rhs,
  ) {
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
    var leftType = analyzeExpression(lhs, operations.unknownType);
    ExpressionInfo<SharedTypeView>? leftInfo;
    if (isEquals) {
      leftInfo = flow.equalityOperand_end(lhs);
    } else if (isLogical) {
      flow.logicalBinaryOp_rightBegin(lhs, node, isAnd: isAnd);
    }
    var rightType = analyzeExpression(rhs, operations.unknownType);
    if (isEquals) {
      flow.equalityOperation_end(
        node,
        leftInfo,
        leftType,
        flow.equalityOperand_end(rhs),
        rightType,
        notEqual: isNot,
      );
    } else if (isLogical) {
      flow.logicalBinaryOp_end(node, rhs, isAnd: isAnd);
    }
    return new ExpressionTypeAnalysisResult(type: operations.boolType);
  }

  void analyzeBlock(Iterable<Statement> statements) {
    for (var statement in statements) {
      dispatchStatement(statement);
    }
  }

  Type analyzeBoolLiteral(Expression node, bool value) {
    flow.booleanLiteral(node, value);
    return operations.boolType.unwrapTypeView();
  }

  void analyzeBreakStatement(Statement? target) {
    flow.handleBreak(target);
  }

  ExpressionTypeAnalysisResult analyzeConditionalExpression(
    Expression node,
    Expression condition,
    Expression ifTrue,
    Expression ifFalse,
  ) {
    flow.conditional_conditionBegin();
    analyzeExpression(condition, operations.unknownType);
    flow.conditional_thenBegin(condition, node);
    var ifTrueType = analyzeExpression(ifTrue, operations.unknownType);
    flow.conditional_elseBegin(ifTrue, ifTrueType);
    var ifFalseType = analyzeExpression(ifFalse, operations.unknownType);
    var lubType = operations.lub(ifTrueType, ifFalseType);
    flow.conditional_end(node, lubType, ifFalse, ifFalseType);
    return new ExpressionTypeAnalysisResult(type: lubType);
  }

  void analyzeContinueStatement(Statement? target) {
    flow.handleContinue(target);
  }

  void analyzeDoLoop(Statement node, Statement body, Expression condition) {
    flow.doStatement_bodyBegin(node);
    _visitLoopBody(node, body);
    flow.doStatement_conditionBegin();
    analyzeExpression(condition, operations.unknownType);
    flow.doStatement_end(condition);
  }

  ExpressionTypeAnalysisResult analyzeDotShorthandExpression(
    Expression expression,
    SharedTypeSchemaView schema,
  ) {
    var type = analyzeDotShorthand(expression, schema);
    return new ExpressionTypeAnalysisResult(type: type);
  }

  ExpressionTypeAnalysisResult analyzeDotShorthandHeadExpression(
    Expression node,
    String name,
    SharedTypeSchemaView schema,
  ) {
    _irBuilder.atom(name, Kind.expression, location: node.location);
    return new ExpressionTypeAnalysisResult(
      type: SharedTypeView(getDotShorthandContext().unwrapTypeSchemaView()),
    );
  }

  void analyzeExpressionStatement(Expression expression) {
    analyzeExpression(expression, operations.unknownType);
  }

  ExpressionTypeAnalysisResult analyzeIfNullExpression(
    Expression node,
    Expression lhs,
    Expression rhs,
  ) {
    var leftType = analyzeExpression(lhs, operations.unknownType);
    flow.ifNullExpression_rightBegin(lhs, leftType);
    var rightType = analyzeExpression(rhs, operations.unknownType);
    flow.ifNullExpression_end();
    return new ExpressionTypeAnalysisResult(
      type: operations.lub(
        flow.operations.promoteToNonNull(leftType),
        rightType,
      ),
    );
  }

  void analyzeLabeledStatement(Statement node, Statement body) {
    flow.labeledStatement_begin(node);
    dispatchStatement(body);
    flow.labeledStatement_end();
  }

  ExpressionTypeAnalysisResult analyzeLogicalNot(
    Expression node,
    Expression expression,
  ) {
    analyzeExpression(expression, operations.unknownType);
    flow.logicalNot_end(node, expression);
    return new ExpressionTypeAnalysisResult(type: operations.boolType);
  }

  /// Invokes the appropriate flow analysis methods, and creates the IR
  /// representation, for a method invocation. [node] is the full method
  /// invocation expression, [target] is the expression before the `.` (or
  /// `null` in case of a cascaded method invocation), [methodName] is the name
  /// of the method being invoked, and [arguments] is the list of argument
  /// expressions.
  ///
  /// Named arguments are not supported.
  ExpressionTypeAnalysisResult analyzeMethodInvocation(
    Expression node,
    Expression? target,
    String methodName,
    List<Expression> arguments, {
    required bool isNullAware,
  }) {
    // Analyze the target, generate its IR, and look up the method's type.
    var methodType = _handlePropertyTargetAndMemberLookup(
      null,
      target,
      methodName,
      location: node.location,
      isNullAware: isNullAware,
    );
    var returnType = operations.dynamicType.unwrapTypeView();
    if (methodType is FunctionType) {
      returnType = methodType.returnType;
      if (methodType.namedParameters.isNotEmpty) {
        throw UnimplementedError('Named parameters are not supported yet');
      } else if (methodType.requiredPositionalParameterCount !=
          methodType.positionalParameters.length) {
        throw UnimplementedError(
          'Optional positional parameters are not supported yet',
        );
      }
    }
    // Recursively analyze each argument.
    var inputKinds = [Kind.expression];
    for (var i = 0; i < arguments.length; i++) {
      inputKinds.add(Kind.expression);
      analyzeExpression(
        arguments[i],
        methodType is FunctionType && !methodType.isQuestionType
            ? operations.typeToSchema(
                SharedTypeView(methodType.positionalParameters[i]),
              )
            : operations.unknownType,
      );
    }
    // Form the IR for the member invocation.
    _harness.irBuilder.apply(
      methodName,
      inputKinds,
      Kind.expression,
      location: node.location,
    );
    return new ExpressionTypeAnalysisResult(type: SharedTypeView(returnType));
  }

  ExpressionTypeAnalysisResult analyzeNonNullAssert(
    Expression node,
    Expression expression,
  ) {
    var type = analyzeExpression(
      expression,
      operations.unknownType,
      continueNullShorting: true,
    );
    flow.nonNullAssert_end(expression);
    return new ExpressionTypeAnalysisResult(
      type: flow.operations.promoteToNonNull(type),
    );
  }

  ExpressionTypeAnalysisResult analyzeNullLiteral(Expression node) {
    flow.nullLiteral(node, SharedTypeView(nullType));
    return new ExpressionTypeAnalysisResult(type: SharedTypeView(nullType));
  }

  ExpressionTypeAnalysisResult analyzeParenthesizedExpression(
    Expression node,
    Expression expression,
    SharedTypeSchemaView schema,
  ) {
    var type = analyzeExpression(expression, schema);
    flow.parenthesizedExpression(node, expression);
    return new ExpressionTypeAnalysisResult(type: type);
  }

  /// Invokes the appropriate flow analysis methods, and creates the IR
  /// representation, for a property get. [node] is the full property get
  /// expression, [target] is the expression before the `.` (or `null` in the
  /// case of a cascaded property get), and [propertyName] is the name of the
  /// property being accessed.
  ///
  /// Null-aware property accesses are not supported.
  ExpressionTypeAnalysisResult analyzePropertyGet(
    Expression node,
    Expression? target,
    String propertyName, {
    required bool isNullAware,
  }) {
    // Analyze the target, generate its IR, and look up the property's type.
    var propertyType = _handlePropertyTargetAndMemberLookup(
      node,
      target,
      propertyName,
      location: node.location,
      isNullAware: isNullAware,
    );
    // Build the property get IR.
    _harness.irBuilder.propertyGet(propertyName, location: node.location);
    // TODO(paulberry): handle null shorting
    return new ExpressionTypeAnalysisResult(type: SharedTypeView(propertyType));
  }

  void analyzeReturnStatement() {
    flow.handleExit();
  }

  ExpressionTypeAnalysisResult analyzeThis(Expression node) {
    var thisType = this.thisType;
    flow.thisOrSuper(node, SharedTypeView(thisType), isSuper: false);
    return new ExpressionTypeAnalysisResult(type: SharedTypeView(thisType));
  }

  ExpressionTypeAnalysisResult analyzeThisOrSuperPropertyGet(
    Expression node,
    String propertyName, {
    required bool isSuperAccess,
  }) {
    var member = _lookupMember(thisType, propertyName);
    var memberType = member?._type ?? operations.dynamicType.unwrapTypeView();
    var promotedType = flow
        .propertyGet(
          node,
          isSuperAccess
              ? SuperPropertyTarget.singleton
              : ThisPropertyTarget.singleton,
          propertyName,
          member,
          SharedTypeView(memberType),
        )
        ?.unwrapTypeView();
    return new ExpressionTypeAnalysisResult(
      type: SharedTypeView(promotedType ?? memberType),
    );
  }

  ExpressionTypeAnalysisResult analyzeThrow(
    Expression node,
    Expression expression,
  ) {
    analyzeExpression(expression, operations.unknownType);
    flow.handleExit();
    return new ExpressionTypeAnalysisResult(type: operations.neverType);
  }

  void analyzeTryStatement(
    Statement node,
    Statement body,
    Iterable<CatchClause> catchClauses,
    Statement? finallyBlock,
  ) {
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
        catch_.exception?._type = catch_.exceptionType ?? Type('dynamic');
        catch_.stackTrace?._type = Type('StackTrace');
        flow.tryCatchStatement_catchBegin(catch_.exception, catch_.stackTrace);
        dispatchStatement(catch_.body);
        flow.tryCatchStatement_catchEnd();
      }
      flow.tryCatchStatement_end();
    }
    if (finallyBlock != null) {
      flow.tryFinallyStatement_finallyBegin(
        catchClauses.isNotEmpty ? node : body,
      );
      dispatchStatement(finallyBlock);
      flow.tryFinallyStatement_end();
    } else {
      handleNoStatement(node);
    }
  }

  ExpressionTypeAnalysisResult analyzeTypeCast(
    Expression node,
    Expression expression,
    Type type,
  ) {
    var subExpressionType = analyzeExpression(
      expression,
      operations.unknownType,
    );
    flow.asExpression_end(
      expression,
      subExpressionType: subExpressionType,
      castType: SharedTypeView(type),
    );
    return new ExpressionTypeAnalysisResult(type: SharedTypeView(type));
  }

  ExpressionTypeAnalysisResult analyzeTypeTest(
    Expression node,
    Expression expression,
    Type type, {
    bool isInverted = false,
  }) {
    var subExpressionType = analyzeExpression(
      expression,
      operations.unknownType,
    );
    flow.isExpression_end(
      node,
      expression,
      isInverted,
      subExpressionType: subExpressionType,
      checkedType: SharedTypeView(type),
    );
    return new ExpressionTypeAnalysisResult(type: operations.boolType);
  }

  ExpressionTypeAnalysisResult analyzeVariableGet(
    Expression node,
    Var variable,
    void Function(Type?)? callback,
  ) {
    var promotedType = flow.variableRead(node, variable);
    callback?.call(promotedType?.unwrapTypeView());
    return new ExpressionTypeAnalysisResult(
      type: promotedType ?? SharedTypeView(variable.type),
    );
  }

  void analyzeWhileLoop(Statement node, Expression condition, Statement body) {
    flow.whileStatement_conditionBegin(node);
    analyzeExpression(condition, operations.unknownType);
    flow.whileStatement_bodyBegin(node, condition);
    _visitLoopBody(node, body);
    flow.whileStatement_end();
  }

  SharedTypeView createNullAwareGuard(
    Expression target,
    SharedTypeView targetType,
  ) {
    var tmp = _harness.irBuilder.allocateTmp(location: target.location);
    startNullShorting(tmp, target, targetType);
    _harness.irBuilder.readTmp(tmp, location: target.location);
    return operations.promoteToNonNull(targetType);
  }

  @override
  void dispatchCollectionElement(
    covariant CollectionElement element,
    covariant CollectionElementContext context,
  ) {
    _irBuilder.guard(element, () => element.visit(_harness, context));
    if (element._expectedIR case var expectedIR?) {
      _irBuilder.check(
        expectedIR,
        Kind.collectionElement,
        location: element.location,
      );
    }
  }

  @override
  ExpressionTypeAnalysisResult dispatchExpression(
    Expression expression,
    SharedTypeSchemaView schema,
  ) {
    if (expression._expectedSchema case var expectedSchema?) {
      expect(schema.unwrapTypeSchemaView<Type>().type, expectedSchema);
    }
    var result = _irBuilder.guard(
      expression,
      () => expression.visit(_harness, schema),
    );
    if (expression._expectedType case var expectedType?) {
      expect(
        result.type.unwrapTypeView<Type>().type,
        expectedType,
        reason: 'at ${expression.location}',
      );
    }
    if (expression._expectedIR case var expectedIR?) {
      _irBuilder.check(
        expectedIR,
        Kind.expression,
        location: expression.location,
      );
    }
    return result;
  }

  @override
  PatternResult dispatchPattern(
    SharedMatchContext context,
    covariant Pattern node,
  ) {
    return node.visit(_harness, context);
  }

  @override
  SharedTypeSchemaView dispatchPatternSchema(covariant Pattern node) {
    return node.computeSchema(_harness);
  }

  @override
  void dispatchStatement(Statement statement) {
    _irBuilder.guard(statement, () => statement.visit(_harness));
    if (statement._expectedIR case var expectedIR?) {
      _irBuilder.check(
        expectedIR,
        Kind.statement,
        location: statement.location,
      );
    }
  }

  @override
  SharedTypeView downwardInferObjectPatternRequiredType({
    required SharedTypeView matchedType,
    required covariant ObjectPattern pattern,
  }) {
    var requiredType = pattern.requiredType;
    if (requiredType.args.isNotEmpty) {
      return SharedTypeView(requiredType);
    } else {
      return SharedTypeView(
        operations.downwardInfer(
          requiredType.name,
          matchedType.unwrapTypeView(),
        ),
      );
    }
  }

  void finish() {
    flow.finish();
  }

  @override
  void finishExpressionCase(Expression node, int caseIndex) {
    _irBuilder.apply(
      'case',
      [Kind.caseHead, Kind.expression],
      Kind.expressionCase,
      location: node.location,
    );
  }

  @override
  void finishJoinedPatternVariable(
    covariant PatternVariableJoin variable, {
    required JoinedPatternVariableLocation location,
    required JoinedPatternVariableInconsistency inconsistency,
    required bool isFinal,
    required SharedTypeView type,
  }) {
    variable.isFinal = isFinal;
    variable.type = type.unwrapTypeView();
    variable.inconsistency = variable.inconsistency.maxWith(inconsistency);
  }

  @override
  shared.MapPatternEntry<Expression, Pattern>? getMapPatternEntry(
    Node element,
  ) {
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
    return element is RestPattern ? element.subPattern : null;
  }

  @override
  SwitchExpressionMemberInfo<Node, Expression, Var>
  getSwitchExpressionMemberInfo(covariant SwitchExpression node, int index) {
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
  getSwitchStatementMemberInfo(covariant SwitchStatement node, int caseIndex) {
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
            CaseHeadOrDefaultInfo(pattern: null, variables: {}, guard: null),
      ],
      body: case_.body.statements,
      variables: case_._candidateVariables,
      hasLabels: case_.hasLabels,
    );
  }

  @override
  void handle_ifCaseStatement_afterPattern({required covariant IfCase node}) {
    _irVariables(node, node._candidateVariables.values);
  }

  void handleAssignedVariablePattern(covariant VariablePattern node) {
    _irBuilder.atom(node.variable.name, Kind.variable, location: node.location);
    _irBuilder.apply(
      'assignedVarPattern',
      [Kind.variable],
      Kind.pattern,
      location: node.location,
    );
    assert(
      node.expectInferredType == null,
      "assigned variable patterns don't get an inferred type",
    );
  }

  @override
  void handleCase_afterCaseHeads(
    covariant SwitchStatement node,
    int caseIndex,
    Iterable<Var> variables,
  ) {
    var case_ = node.cases[caseIndex];
    _irVariables(node, variables);
    _irBuilder.apply(
      'heads',
      [...List.filled(case_.elements.length, Kind.caseHead), Kind.variables],
      Kind.caseHeads,
      location: node.location,
    );
  }

  @override
  void handleCaseHead(
    Node node, {
    required int caseIndex,
    required int subIndex,
  }) {
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
      'head',
      [Kind.pattern, Kind.expression, Kind.variables],
      Kind.caseHead,
      location: node.location,
    );
  }

  void handleDeclaredVariablePattern(
    covariant VariablePattern node, {
    required Type matchedType,
    required Type staticType,
  }) {
    _irBuilder.atom(node.variable.name, Kind.variable, location: node.location);
    _irBuilder.atom(matchedType.type, Kind.type, location: node.location);
    _irBuilder.atom(staticType.type, Kind.type, location: node.location);
    _irBuilder.apply(
      'varPattern',
      [Kind.variable, Kind.type, Kind.type],
      Kind.pattern,
      names: ['matchedType', 'staticType'],
      location: node.location,
    );
    var expectInferredType = node.expectInferredType;
    if (expectInferredType != null) {
      expect(
        staticType.type,
        expectInferredType,
        reason: 'at ${node.location}',
      );
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
    covariant RestPattern restElement,
  ) {
    if (restElement.subPattern != null) {
      _irBuilder.apply(
        '...',
        [Kind.pattern],
        Kind.pattern,
        location: restElement.location,
      );
    } else {
      _irBuilder.atom('...', Kind.pattern, location: restElement.location);
    }
  }

  @override
  void handleMapPatternEntry(
    Pattern container,
    Node entryElement,
    SharedTypeView keyType,
  ) {
    _irBuilder.apply(
      'mapPatternEntry',
      [Kind.expression, Kind.pattern],
      Kind.mapPatternElement,
      location: entryElement.location,
    );
  }

  @override
  void handleMapPatternRestElement(
    Pattern container,
    covariant RestPattern restElement,
  ) {
    if (restElement.subPattern != null) {
      _irBuilder.apply(
        '...',
        [Kind.pattern],
        Kind.mapPatternElement,
        location: restElement.location,
      );
    } else {
      _irBuilder.atom(
        '...',
        Kind.mapPatternElement,
        location: restElement.location,
      );
    }
  }

  @override
  void handleMergedStatementCase(
    covariant SwitchStatement node, {
    required int caseIndex,
    required bool isTerminating,
  }) {
    var numStatements = node.cases[caseIndex].body.statements.length;
    if (!isTerminating) {
      _irBuilder.apply(
        'synthetic-break',
        [],
        Kind.statement,
        location: node.location,
      );
      numStatements++;
    }
    _irBuilder.apply(
      'block',
      List.filled(numStatements, Kind.statement),
      Kind.statement,
      location: node.location,
    );
    _irBuilder.apply(
      'case',
      [Kind.caseHeads, Kind.statement],
      Kind.statementCase,
      location: node.location,
    );
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
  void handleNullShortingStep(MiniIRTmp guard, SharedTypeView inferredType) {
    _irBuilder.ifNotNull(guard, location: guard.location);
  }

  @override
  void handleSwitchBeforeAlternative(
    Node node, {
    required int caseIndex,
    required int subIndex,
  }) {}

  @override
  void handleSwitchScrutinee(SharedTypeView type) {}

  @override
  bool isDotShorthand(Node node) {
    return node is DotShorthand;
  }

  @override
  bool isLegacySwitchExhaustive(
    covariant SwitchStatement node,
    SharedTypeView expressionType,
  ) {
    return node.isLegacyExhaustive!;
  }

  @override
  bool isRestPatternElement(Node element) {
    return element is RestPattern;
  }

  @override
  bool isVariablePattern(Node pattern) => pattern is VariablePattern;

  _PropertyElement? lookupInterfaceMember(
    Type receiverType,
    String memberName,
  ) {
    return _harness.getMember(receiverType, memberName);
  }

  @override
  (_PropertyElement?, SharedTypeView) resolveObjectPatternPropertyGet({
    required Pattern objectPattern,
    required SharedTypeView receiverType,
    required shared.RecordPatternField<Node, Pattern> field,
  }) {
    var propertyMember = _harness.getMember(
      receiverType.unwrapTypeView(),
      field.name!,
    );
    return (
      propertyMember,
      SharedTypeView(
        propertyMember?._type ?? operations.dynamicType.unwrapTypeView(),
      ),
    );
  }

  @override
  RelationalOperatorResolution? resolveRelationalPatternOperator(
    covariant RelationalPattern node,
    SharedTypeView matchedValueType,
  ) {
    return _harness.resolveRelationalPatternOperator(
      matchedValueType.unwrapTypeView(),
      node.operator,
    );
  }

  @override
  void setVariableType(Var variable, SharedTypeView type) {
    variable.type = type.unwrapTypeView();
  }

  @override
  String toString() => _irBuilder.toString();

  @override
  SharedTypeView variableTypeFromInitializerType(SharedTypeView type) {
    // Variables whose initializer has type `Null` receive the inferred type
    // `dynamic`.
    if (_harness.operations.classifyType(type) ==
        TypeClassification.nullOrEquivalent) {
      type = operations.dynamicType;
    }
    // Variables whose initializer type includes a promoted type variable
    // receive the nearest supertype that could be expressed in Dart source code
    // (e.g. `T&int` is demoted to `T`).
    // TODO(paulberry): add language tests to verify that the behavior of
    // `type.recursivelyDemote` matches what the analyzer and CFE do.
    return SharedTypeView(
      type.unwrapTypeView<Type>().recursivelyDemote(covariant: true) ??
          type.unwrapTypeView(),
    );
  }

  /// Analyzes the target of a property get or method invocation, looks up the
  /// member being accessed, and returns its type. [propertyGetNode] is the
  /// source representation of the property get itself (or `null` if this is a
  /// method invocation), [target] is the source representation of the target
  /// (or `null` if this is a cascaded access), and [propertyName] is the name
  /// of the property being accessed. [location] is the source location (used
  /// for reporting test failures).
  ///
  /// Returns the type of the member, or a representation of the type `dynamic`
  /// if the member couldn't be found.
  Type _handlePropertyTargetAndMemberLookup(
    Expression? propertyGetNode,
    Expression? target,
    String propertyName, {
    required String location,
    required bool isNullAware,
  }) {
    // Analyze the target, and generate its IR.
    PropertyTarget<Expression> propertyTarget;
    SharedTypeView targetType;
    if (target == null) {
      if (isNullAware) {
        fail(
          "at $location: cascaded accesses shouldn't be marked as null-aware "
          '(the cascade itself should be marked as null-aware instead).',
        );
      }
      // This is a cascaded access so the IR we need to generate is an implicit
      // read of the temporary variable holding the cascade target.
      propertyTarget = CascadePropertyTarget.singleton;
      _harness.irBuilder.readTmp(_currentCascadeTargetIR!, location: location);
      targetType = _currentCascadeTargetType!;
    } else {
      propertyTarget = ExpressionPropertyTarget(target);
      targetType = analyzeExpression(
        target,
        operations.unknownType,
        continueNullShorting: true,
      );
      if (isNullAware) targetType = createNullAwareGuard(target, targetType);
    }
    // Look up the type of the member, applying type promotion if necessary.
    var member = _lookupMember(targetType.unwrapTypeView(), propertyName);
    var memberType =
        member?._type ?? operations.dynamicType.unwrapTypeView<Type>();
    return flow
            .propertyGet(
              propertyGetNode,
              propertyTarget,
              propertyName,
              member,
              SharedTypeView(memberType),
            )
            ?.unwrapTypeView() ??
        memberType;
  }

  void _irVariables(Node node, Iterable<Var> variables) {
    var variableList = variables.toList();
    for (var variable in variableList) {
      _irBuilder.atom(
        variable.stringToCheckVariables,
        Kind.variable,
        location: variable.location,
      );
    }
    _irBuilder.apply(
      'variables',
      List.filled(variableList.length, Kind.variable),
      Kind.variables,
      location: node.location,
    );
  }

  _PropertyElement? _lookupMember(Type receiverType, String memberName) {
    return lookupInterfaceMember(receiverType, memberName);
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

  /// The name of the property (used by toString)
  final String _name;

  /// Whether the property is promotable.
  final bool isPromotable;

  /// The reason the property is not promotable, if applicable and relevant to
  /// the test.
  ///
  /// If the propery is promotable ([isPromotable] is `true`), this value is
  /// always `null`.
  ///
  /// Otherwise the value *may* be a reason for the property not being
  /// promotable, but it may also still be `null` if the reason is not relevant
  /// to the test.
  final PropertyNonPromotabilityReason? whyNotPromotable;

  _PropertyElement(
    this._type,
    this._name, {
    required this.isPromotable,
    required this.whyNotPromotable,
  }) {
    if (isPromotable) {
      assert(whyNotPromotable == null);
    }
  }

  @override
  String toString() => '$_type.$_name';
}

class _VariableBinder extends VariableBinder<Node, Var> {
  final PreVisitor visitor;

  _VariableBinder(this.visitor) : super(errors: visitor.errors);

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
      visitor: visitor,
    );
    return joinedVariable;
  }
}
