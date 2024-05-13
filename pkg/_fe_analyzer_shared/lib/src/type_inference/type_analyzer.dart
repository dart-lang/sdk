// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../flow_analysis/flow_analysis.dart';
import '../types/shared_type.dart';
import 'type_analysis_result.dart';
import 'type_analyzer_operations.dart';

/// Information supplied by the client to [TypeAnalyzer.analyzeSwitchExpression]
/// or [TypeAnalyzer.analyzeSwitchStatement] about a single case head or
/// `default` clause.
///
/// The client is free to `implement` or `extend` this class.
class CaseHeadOrDefaultInfo<Node extends Object, Expression extends Node,
    Variable extends Object> {
  /// For a `case` clause, the case pattern.  For a `default` clause, `null`.
  final Node? pattern;

  /// The pattern variables declared in [pattern]. Some of them are joins of
  /// individual pattern variable declarations. We don't know their types
  /// until we do type analysis. So, some of these variables might become
  /// not consistent.
  final Map<String, Variable> variables;

  /// For a `case` clause that has a guard clause, the expression following
  /// `when`.  Otherwise `null`.
  final Expression? guard;

  CaseHeadOrDefaultInfo({
    required this.pattern,
    required this.variables,
    this.guard,
  });
}

/// The kind of inconsistency identified for a variable.
enum JoinedPatternVariableInconsistency {
  /// No inconsistency.
  none(0),

  /// Only one branch of a logical-or pattern has the variable.
  logicalOr(4),

  /// Not every case of a shared case scope has the variable.
  sharedCaseAbsent(3),

  /// The shared case scope has a label or `default` case.
  sharedCaseHasLabel(2),

  /// The finality or type of the variable components is not the same.
  /// This is reported for both logical-or and shared cases.
  differentFinalityOrType(1);

  final int _severity;

  const JoinedPatternVariableInconsistency(this._severity);

  /// Returns the most serious inconsistency for `this` or [other].
  JoinedPatternVariableInconsistency maxWith(
    JoinedPatternVariableInconsistency other,
  ) {
    return _severity > other._severity ? this : other;
  }

  /// Returns the most serious inconsistency for `this` or [others].
  JoinedPatternVariableInconsistency maxWithAll(
    Iterable<JoinedPatternVariableInconsistency> others,
  ) {
    JoinedPatternVariableInconsistency result = this;
    for (JoinedPatternVariableInconsistency other in others) {
      result = result.maxWith(other);
    }
    return result;
  }
}

/// The location where the join of a pattern variable happens.
enum JoinedPatternVariableLocation {
  /// A single pattern, from `logical-or` patterns.
  singlePattern,

  /// A shared `case` scope, when multiple `case`s share the same body.
  sharedCaseScope,
}

class MapPatternEntry<Expression extends Object, Pattern extends Object> {
  final Expression key;
  final Pattern value;

  MapPatternEntry({
    required this.key,
    required this.value,
  });
}

/// Information supplied by the client to [TypeAnalyzer.analyzeObjectPattern],
/// [TypeAnalyzer.analyzeRecordPattern], or
/// [TypeAnalyzer.analyzeRecordPatternSchema] about a single field in a record
/// or object pattern.
///
/// The client is free to `implement` or `extend` this class.
class RecordPatternField<Node extends Object, Pattern extends Object> {
  /// The client specific node from which this object was created.  It can be
  /// used for error reporting.
  final Node node;

  /// If not `null` then the field is named, otherwise it is positional.
  final String? name;
  final Pattern pattern;

  RecordPatternField({
    required this.node,
    required this.name,
    required this.pattern,
  });
}

/// Kinds of relational pattern operators that shared analysis needs to
/// distinguish.
enum RelationalOperatorKind {
  /// The operator `==`
  equals,

  /// The operator `!=`
  notEquals,

  /// Any relational pattern operator other than `==` or `!=`
  other,
}

/// Information about a relational operator.
class RelationalOperatorResolution<Type extends SharedType> {
  final RelationalOperatorKind kind;
  final Type parameterType;
  final Type returnType;

  RelationalOperatorResolution({
    required this.kind,
    required this.parameterType,
    required this.returnType,
  });
}

/// Information supplied by the client to [TypeAnalyzer.analyzeSwitchExpression]
/// about an individual `case` or `default` clause.
///
/// The client is free to `implement` or `extend` this class.
class SwitchExpressionMemberInfo<Node extends Object, Expression extends Node,
    Variable extends Object> {
  /// The [CaseOrDefaultHead] associated with this clause.
  final CaseHeadOrDefaultInfo<Node, Expression, Variable> head;

  /// The body of the `case` or `default` clause.
  final Expression expression;

  SwitchExpressionMemberInfo({required this.head, required this.expression});
}

/// Information supplied by the client to [TypeAnalyzer.analyzeSwitchStatement]
/// about an individual `case` or `default` clause.
///
/// The client is free to `implement` or `extend` this class.
class SwitchStatementMemberInfo<Node extends Object, Statement extends Node,
    Expression extends Node, Variable extends Object> {
  /// The list of case heads for this case.
  ///
  /// The reason this is a list rather than a single head is because the front
  /// end merges together cases that share a body at parse time.
  final List<CaseHeadOrDefaultInfo<Node, Expression, Variable>> heads;

  /// Is `true` if the group of `case` and `default` clauses has a label.
  final bool hasLabels;

  /// The statements following this `case` or `default` clause.  If this list is
  /// empty, and this is not the last `case` or `default` clause, this clause
  /// will be considered to share a body with the `case` or `default` clause
  /// that follows.
  final List<Statement> body;

  /// The merged set of pattern variables from [heads]. If there is more than
  /// one element in [heads], these variables are joins of individual pattern
  /// variable declarations. Some of these variables might be already not
  /// consistent, because they are present not in every head. We don't know
  /// their types until we do type analysis. So, some of these variables
  /// might become not consistent.
  final Map<String, Variable> variables;

  SwitchStatementMemberInfo(
      {required this.heads,
      required this.body,
      required this.variables,
      required this.hasLabels});
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
mixin TypeAnalyzer<
    Node extends Object,
    Statement extends Node,
    Expression extends Node,
    Variable extends Object,
    Type extends SharedType,
    Pattern extends Node,
    Error,
    TypeSchema extends Object,
    InferableParameter extends Object,
    TypeDeclarationType extends Object,
    TypeDeclaration extends Object> {
  TypeAnalyzerErrors<Node, Statement, Expression, Variable, Type, Pattern,
      Error> get errors;

  /// Returns the client's [FlowAnalysis] object.
  FlowAnalysis<Node, Statement, Expression, Variable, Type> get flow;

  /// The [TypeAnalyzerOperations], used to access types, check subtyping, and
  /// query variable types.
  TypeAnalyzerOperations<Variable, Type, TypeSchema, InferableParameter,
      TypeDeclarationType, TypeDeclaration> get operations;

  /// Options affecting the behavior of [TypeAnalyzer].
  TypeAnalyzerOptions get options;

  /// Analyzes a non-wildcard variable pattern appearing in an assignment
  /// context.  [node] is the pattern itself, and [variable] is the variable
  /// being referenced.
  ///
  /// Returns an [AssignedVariablePatternResult] with information about reported
  /// errors.
  ///
  /// See [dispatchPattern] for the meaning of [context].
  ///
  /// For wildcard patterns in an assignment context,
  /// [analyzeDeclaredVariablePattern] should be used instead.
  ///
  /// Stack effect: none.
  AssignedVariablePatternResult<Type, Error> analyzeAssignedVariablePattern(
      MatchContext<Node, Expression, Pattern, Type, Variable> context,
      Pattern node,
      Variable variable) {
    Type matchedValueType = flow.getMatchedValueType();
    Error? duplicateAssignmentPatternVariableError;
    Map<Variable, Pattern>? assignedVariables = context.assignedVariables;
    if (assignedVariables != null) {
      Pattern? original = assignedVariables[variable];
      if (original == null) {
        assignedVariables[variable] = node;
      } else {
        duplicateAssignmentPatternVariableError =
            errors.duplicateAssignmentPatternVariable(
          variable: variable,
          original: original,
          duplicate: node,
        );
      }
    }

    Type variableDeclaredType = operations.variableType(variable);
    Node? irrefutableContext = context.irrefutableContext;
    assert(irrefutableContext != null,
        'Assigned variables must only appear in irrefutable pattern contexts');
    Error? patternTypeMismatchInIrrefutableContextError;
    if (irrefutableContext != null &&
        matchedValueType is! SharedDynamicType &&
        matchedValueType is! SharedInvalidType &&
        !operations.isSubtypeOf(matchedValueType, variableDeclaredType)) {
      patternTypeMismatchInIrrefutableContextError =
          errors.patternTypeMismatchInIrrefutableContext(
              pattern: node,
              context: irrefutableContext,
              matchedType: matchedValueType,
              requiredType: variableDeclaredType);
    }
    flow.promoteForPattern(
        matchedType: matchedValueType, knownType: variableDeclaredType);
    flow.assignedVariablePattern(node, variable, matchedValueType);
    return new AssignedVariablePatternResult(
        duplicateAssignmentPatternVariableError:
            duplicateAssignmentPatternVariableError,
        patternTypeMismatchInIrrefutableContextError:
            patternTypeMismatchInIrrefutableContextError,
        matchedValueType: matchedValueType);
  }

  /// Computes the type schema for a variable pattern appearing in an assignment
  /// context.  [variable] is the variable being referenced.
  TypeSchema analyzeAssignedVariablePatternSchema(Variable variable) =>
      operations.typeToSchema(
          flow.promotedType(variable) ?? operations.variableType(variable));

  /// Analyzes a cast pattern.  [innerPattern] is the sub-pattern] and
  /// [requiredType] is the type to cast to.
  ///
  /// See [dispatchPattern] for the meaning of [context].
  ///
  /// Stack effect: pushes (Pattern innerPattern).
  PatternResult<Type> analyzeCastPattern({
    required MatchContext<Node, Expression, Pattern, Type, Variable> context,
    required Pattern pattern,
    required Pattern innerPattern,
    required Type requiredType,
  }) {
    Type matchedValueType = flow.getMatchedValueType();
    flow.promoteForPattern(
        matchedType: matchedValueType,
        knownType: requiredType,
        matchFailsIfWrongType: false);
    if (operations.isSubtypeOf(matchedValueType, requiredType) &&
        requiredType is! SharedInvalidType) {
      errors.matchedTypeIsSubtypeOfRequired(
        pattern: pattern,
        matchedType: matchedValueType,
        requiredType: requiredType,
      );
    }
    // Note: although technically the inner pattern match of a cast-pattern
    // operates on the same value as the cast pattern does, we analyze it as
    // though it's a different value; this ensures that (a) the matched value
    // type when matching the inner pattern is precisely the cast type, and (b)
    // promotions triggered by the inner pattern have no effect outside the
    // cast.
    flow.pushSubpattern(requiredType);
    dispatchPattern(context.withUnnecessaryWildcardKind(null), innerPattern);
    // Stack: (Pattern)
    flow.popSubpattern();
    return new PatternResult(matchedValueType: matchedValueType);
  }

  /// Computes the type schema for a cast pattern.
  ///
  /// Stack effect: none.
  TypeSchema analyzeCastPatternSchema() => operations.unknownType;

  /// Analyzes a constant pattern.  [node] is the pattern itself, and
  /// [expression] is the constant expression.  Depending on the client's
  /// representation, [node] and [expression] might or might not be identical.
  ///
  /// See [dispatchPattern] for the meaning of [context].
  ///
  /// Returns a [ConstantPatternResult] with the static type of [expression]
  /// and information about reported errors.
  ///
  /// Stack effect: pushes (Expression).
  ConstantPatternResult<Type, Error> analyzeConstantPattern(
      MatchContext<Node, Expression, Pattern, Type, Variable> context,
      Node node,
      Expression expression) {
    Type matchedValueType = flow.getMatchedValueType();
    // Stack: ()
    Node? irrefutableContext = context.irrefutableContext;
    Error? refutablePatternInIrrefutableContextError;
    if (irrefutableContext != null) {
      refutablePatternInIrrefutableContextError =
          errors.refutablePatternInIrrefutableContext(
              pattern: node, context: irrefutableContext);
    }
    Type expressionType = analyzeExpression(
        expression, operations.typeToSchema(matchedValueType));
    flow.constantPattern_end(expression, expressionType,
        patternsEnabled: options.patternsEnabled,
        matchedValueType: matchedValueType);
    // Stack: (Expression)
    Error? caseExpressionTypeMismatchError;
    if (!options.patternsEnabled) {
      Expression? switchScrutinee = context.switchScrutinee;
      if (switchScrutinee != null) {
        bool nullSafetyEnabled = options.nullSafetyEnabled;
        bool matches = nullSafetyEnabled
            ? operations.isSubtypeOf(expressionType, matchedValueType)
            : operations.isAssignableTo(expressionType, matchedValueType);
        if (!matches) {
          caseExpressionTypeMismatchError = errors.caseExpressionTypeMismatch(
              caseExpression: expression,
              scrutinee: switchScrutinee,
              caseExpressionType: expressionType,
              scrutineeType: matchedValueType,
              nullSafetyEnabled: nullSafetyEnabled);
        }
      }
    }
    return new ConstantPatternResult(
        expressionType: expressionType,
        refutablePatternInIrrefutableContextError:
            refutablePatternInIrrefutableContextError,
        caseExpressionTypeMismatchError: caseExpressionTypeMismatchError,
        matchedValueType: matchedValueType);
  }

  /// Computes the type schema for a constant pattern.
  ///
  /// Stack effect: none.
  TypeSchema analyzeConstantPatternSchema() {
    // Constant patterns are only allowed in refutable contexts, and refutable
    // contexts don't propagate a type schema into the scrutinee.  So this
    // code path is only reachable if the user's code contains errors.
    errors.assertInErrorRecovery();
    return operations.unknownType;
  }

  /// Analyzes a variable pattern in a non-assignment context.  [node] is the
  /// pattern itself, [variable] is the variable, [declaredType] is the
  /// explicitly declared type (if present).  [variableName] is the name of the
  /// variable; this is used to match up corresponding variables in the
  /// different branches of logical-or patterns, as well as different switch
  /// cases that share a body.
  ///
  /// See [dispatchPattern] for the meaning of [context].
  ///
  /// Returns a [DeclaredVariablePatternResult] with the static type of the
  /// variable (possibly inferred) and information about reported errors.
  ///
  /// Stack effect: none.
  DeclaredVariablePatternResult<Type, Error> analyzeDeclaredVariablePattern(
    MatchContext<Node, Expression, Pattern, Type, Variable> context,
    Pattern node,
    Variable variable,
    String variableName,
    Type? declaredType,
  ) {
    Type matchedValueType = flow.getMatchedValueType();
    Type staticType =
        declaredType ?? variableTypeFromInitializerType(matchedValueType);
    Node? irrefutableContext = context.irrefutableContext;
    Error? patternTypeMismatchInIrrefutableContextError;
    if (irrefutableContext != null &&
        matchedValueType is! SharedDynamicType &&
        matchedValueType is! SharedInvalidType &&
        !operations.isSubtypeOf(matchedValueType, staticType)) {
      patternTypeMismatchInIrrefutableContextError =
          errors.patternTypeMismatchInIrrefutableContext(
              pattern: node,
              context: irrefutableContext,
              matchedType: matchedValueType,
              requiredType: staticType);
    }
    flow.promoteForPattern(
        matchedType: matchedValueType, knownType: staticType);
    // The promotion may have made the matched type even more specific than
    // either `matchedType` or `staticType`, so fetch it again and use that
    // in the call to `declaredVariablePattern` below.
    Type promotedValueType = flow.getMatchedValueType();
    bool isImplicitlyTyped = declaredType == null;
    // TODO(paulberry): are we handling _isFinal correctly?
    int promotionKey = context.patternVariablePromotionKeys[variableName] =
        flow.declaredVariablePattern(
            matchedType: promotedValueType,
            staticType: staticType,
            isFinal: context.isFinal || operations.isVariableFinal(variable),
            isLate: false,
            isImplicitlyTyped: isImplicitlyTyped);
    setVariableType(variable, staticType);
    (context.componentVariables[variableName] ??= []).add(variable);
    flow.assignMatchedPatternVariable(variable, promotionKey);
    return new DeclaredVariablePatternResult(
        staticType: staticType,
        patternTypeMismatchInIrrefutableContextError:
            patternTypeMismatchInIrrefutableContextError,
        matchedValueType: matchedValueType);
  }

  /// Computes the type schema for a variable pattern in a non-assignment
  /// context (or a wildcard pattern).  [declaredType] is the explicitly
  /// declared type (if present).
  ///
  /// Stack effect: none.
  TypeSchema analyzeDeclaredVariablePatternSchema(Type? declaredType) {
    return declaredType == null
        ? operations.unknownType
        : operations.typeToSchema(declaredType);
  }

  /// Analyzes an expression.  [node] is the expression to analyze, and
  /// [schema] is the type schema which should be used for type inference.
  ///
  /// Stack effect: pushes (Expression).
  Type analyzeExpression(Expression node, TypeSchema schema) {
    // Stack: ()
    if (operations.typeSchemaIsDynamic(schema)) {
      schema = operations.unknownType;
    }
    ExpressionTypeAnalysisResult<Type> result =
        dispatchExpression(node, schema);
    // Stack: (Expression)
    if (operations.isNever(result.provisionalType)) {
      flow.handleExit();
    }
    return result.resolveShorting();
  }

  /// Analyzes a collection element of the form
  /// `if (expression case pattern) ifTrue` or
  /// `if (expression case pattern) ifTrue else ifFalse`.
  ///
  /// [node] should be the AST node for the entire element, [expression] for
  /// the expression, [pattern] for the pattern to match, [ifTrue] for the
  /// "then" branch, and [ifFalse] for the "else" branch (if present).
  ///
  /// [variables] should be a map from variable name to the variable the client
  /// wishes to use to represent that variable.  This is used to join together
  /// variables that appear in different branches of logical-or patterns.
  ///
  /// Returns a [IfCaseStatementResult] with the static type of [expression] and
  /// information about reported errors.
  ///
  /// Stack effect: pushes (Expression scrutinee, Pattern, Expression guard,
  /// CollectionElement ifTrue, CollectionElement ifFalse).  If there is no
  /// `else` clause, the representation for `ifFalse` will be pushed by
  /// [handleNoCollectionElement].  If there is no guard, the representation
  /// for `guard` will be pushed by [handleNoGuard].
  IfCaseStatementResult<Type, Error> analyzeIfCaseElement({
    required Node node,
    required Expression expression,
    required Pattern pattern,
    required Map<String, Variable> variables,
    required Expression? guard,
    required Node ifTrue,
    required Node? ifFalse,
    required Object? context,
  }) {
    // Stack: ()
    flow.ifCaseStatement_begin();
    Type initializerType =
        analyzeExpression(expression, operations.unknownType);
    flow.ifCaseStatement_afterExpression(expression, initializerType);
    // Stack: (Expression)
    Map<String, List<Variable>> componentVariables = {};
    Map<String, int> patternVariablePromotionKeys = {};
    // TODO(paulberry): rework handling of isFinal
    dispatchPattern(
      new MatchContext<Node, Expression, Pattern, Type, Variable>(
        isFinal: false,
        componentVariables: componentVariables,
        patternVariablePromotionKeys: patternVariablePromotionKeys,
      ),
      pattern,
    );
    // Stack: (Expression, Pattern)
    _finishJoinedPatternVariables(
        variables, componentVariables, patternVariablePromotionKeys,
        location: JoinedPatternVariableLocation.singlePattern);
    Error? nonBooleanGuardError;
    Type? guardType;
    if (guard != null) {
      guardType = analyzeExpression(
          guard, operations.typeToSchema(operations.boolType));
      nonBooleanGuardError = _checkGuardType(guard, guardType);
    } else {
      handleNoGuard(node, 0);
    }
    // Stack: (Expression, Pattern, Guard)
    flow.ifCaseStatement_thenBegin(guard);
    _analyzeIfElementCommon(node, ifTrue, ifFalse, context);
    return new IfCaseStatementResult(
        matchedExpressionType: initializerType,
        nonBooleanGuardError: nonBooleanGuardError,
        guardType: guardType);
  }

  /// Analyzes a statement of the form `if (expression case pattern) ifTrue` or
  /// `if (expression case pattern) ifTrue else ifFalse`.
  ///
  /// [node] should be the AST node for the entire statement, [expression] for
  /// the expression, [pattern] for the pattern to match, [ifTrue] for the
  /// "then" branch, and [ifFalse] for the "else" branch (if present).
  ///
  /// Returns a [IfCaseStatementResult] with the static type of [expression] and
  /// information about reported errors.
  ///
  /// Stack effect: pushes (Expression scrutinee, Pattern, Expression guard,
  /// Statement ifTrue, Statement ifFalse).  If there is no `else` clause, the
  /// representation for `ifFalse` will be pushed by [handleNoStatement].  If
  /// there is no guard, the representation for `guard` will be pushed by
  /// [handleNoGuard].
  IfCaseStatementResult<Type, Error> analyzeIfCaseStatement(
    Statement node,
    Expression expression,
    Pattern pattern,
    Expression? guard,
    Statement ifTrue,
    Statement? ifFalse,
    Map<String, Variable> variables,
  ) {
    // Stack: ()
    flow.ifCaseStatement_begin();
    Type initializerType =
        analyzeExpression(expression, operations.unknownType);
    flow.ifCaseStatement_afterExpression(expression, initializerType);
    // Stack: (Expression)
    Map<String, List<Variable>> componentVariables = {};
    Map<String, int> patternVariablePromotionKeys = {};
    // TODO(paulberry): rework handling of isFinal
    dispatchPattern(
      new MatchContext<Node, Expression, Pattern, Type, Variable>(
        isFinal: false,
        componentVariables: componentVariables,
        patternVariablePromotionKeys: patternVariablePromotionKeys,
      ),
      pattern,
    );

    _finishJoinedPatternVariables(
      variables,
      componentVariables,
      patternVariablePromotionKeys,
      location: JoinedPatternVariableLocation.singlePattern,
    );

    handle_ifCaseStatement_afterPattern(node: node);
    // Stack: (Expression, Pattern)
    Error? nonBooleanGuardError;
    Type? guardType;
    if (guard != null) {
      guardType = analyzeExpression(
          guard, operations.typeToSchema(operations.boolType));
      nonBooleanGuardError = _checkGuardType(guard, guardType);
    } else {
      handleNoGuard(node, 0);
    }
    // Stack: (Expression, Pattern, Guard)
    flow.ifCaseStatement_thenBegin(guard);
    _analyzeIfCommon(node, ifTrue, ifFalse);
    return new IfCaseStatementResult(
        matchedExpressionType: initializerType,
        nonBooleanGuardError: nonBooleanGuardError,
        guardType: guardType);
  }

  /// Analyzes a collection element of the form `if (condition) ifTrue` or
  /// `if (condition) ifTrue else ifFalse`.
  ///
  /// [node] should be the AST node for the entire element, [condition] for
  /// the condition expression, [ifTrue] for the "then" branch, and [ifFalse]
  /// for the "else" branch (if present).
  ///
  /// Stack effect: pushes (Expression condition, CollectionElement ifTrue,
  /// CollectionElement ifFalse).  Note that if there is no `else` clause, the
  /// representation for `ifFalse` will be pushed by
  /// [handleNoCollectionElement].
  void analyzeIfElement({
    required Node node,
    required Expression condition,
    required Node ifTrue,
    required Node? ifFalse,
    required Object? context,
  }) {
    // Stack: ()
    flow.ifStatement_conditionBegin();
    analyzeExpression(condition, operations.typeToSchema(operations.boolType));
    handle_ifElement_conditionEnd(node);
    // Stack: (Expression condition)
    flow.ifStatement_thenBegin(condition, node);
    _analyzeIfElementCommon(node, ifTrue, ifFalse, context);
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
    flow.ifStatement_conditionBegin();
    analyzeExpression(condition, operations.typeToSchema(operations.boolType));
    handle_ifStatement_conditionEnd(node);
    // Stack: (Expression condition)
    flow.ifStatement_thenBegin(condition, node);
    _analyzeIfCommon(node, ifTrue, ifFalse);
  }

  /// Analyzes an integer literal, given the type schema [schema].
  ///
  /// Stack effect: none.
  IntTypeAnalysisResult<Type> analyzeIntLiteral(TypeSchema schema) {
    bool convertToDouble = !operations.isTypeSchemaSatisfied(
            type: operations.intType, typeSchema: schema) &&
        operations.isTypeSchemaSatisfied(
            type: operations.doubleType, typeSchema: schema);
    Type type = convertToDouble ? operations.doubleType : operations.intType;
    return new IntTypeAnalysisResult<Type>(
        type: type, convertedToDouble: convertToDouble);
  }

  /// Analyzes a list pattern.  [node] is the pattern itself, [elementType] is
  /// the list element type (if explicitly supplied), and [elements] is the
  /// list of subpatterns.
  ///
  /// Returns a [ListPatternResult] with the required type and information about
  /// reported errors.
  ///
  /// See [dispatchPattern] for the meaning of [context].
  ///
  /// Stack effect: pushes (n * Pattern) where n = elements.length.
  ListPatternResult<Type, Error> analyzeListPattern(
      MatchContext<Node, Expression, Pattern, Type, Variable> context,
      Pattern node,
      {Type? elementType,
      required List<Node> elements}) {
    Type matchedValueType = flow.getMatchedValueType();
    Type valueType;
    if (elementType != null) {
      valueType = elementType;
    } else {
      Type? listElementType = operations.matchListType(matchedValueType);
      if (listElementType != null) {
        valueType = listElementType;
      } else if (matchedValueType is SharedDynamicType) {
        valueType = operations.dynamicType;
      } else if (matchedValueType is SharedInvalidType) {
        valueType = operations.errorType;
      } else {
        valueType = operations.objectQuestionType;
      }
    }
    Type requiredType = operations.listType(valueType);
    flow.promoteForPattern(
        matchedType: matchedValueType,
        knownType: requiredType,
        matchMayFailEvenIfCorrectType:
            !(elements.length == 1 && isRestPatternElement(elements[0])));
    // Stack: ()
    Node? previousRestPattern;
    Map<int, Error>? duplicateRestPatternErrors;
    for (int i = 0; i < elements.length; i++) {
      Node element = elements[i];
      if (isRestPatternElement(element)) {
        if (previousRestPattern != null) {
          (duplicateRestPatternErrors ??= {})[i] = errors.duplicateRestPattern(
            mapOrListPattern: node,
            original: previousRestPattern,
            duplicate: element,
          );
        }
        previousRestPattern = element;
        Pattern? subPattern = getRestPatternElementPattern(element);
        if (subPattern != null) {
          Type subPatternMatchedType = requiredType;
          flow.pushSubpattern(subPatternMatchedType);
          dispatchPattern(
              context.withUnnecessaryWildcardKind(null), subPattern);
          flow.popSubpattern();
        }
        handleListPatternRestElement(node, element);
      } else {
        flow.pushSubpattern(valueType);
        dispatchPattern(context.withUnnecessaryWildcardKind(null), element);
        flow.popSubpattern();
      }
    }
    // Stack: (n * Pattern) where n = elements.length
    Node? irrefutableContext = context.irrefutableContext;
    Error? patternTypeMismatchInIrrefutableContextError;
    if (irrefutableContext != null &&
        !operations.isAssignableTo(matchedValueType, requiredType)) {
      patternTypeMismatchInIrrefutableContextError =
          errors.patternTypeMismatchInIrrefutableContext(
              pattern: node,
              context: irrefutableContext,
              matchedType: matchedValueType,
              requiredType: requiredType);
    }
    return new ListPatternResult(
        requiredType: requiredType,
        duplicateRestPatternErrors: duplicateRestPatternErrors,
        patternTypeMismatchInIrrefutableContextError:
            patternTypeMismatchInIrrefutableContextError,
        matchedValueType: matchedValueType);
  }

  /// Computes the type schema for a list pattern.  [elementType] is the list
  /// element type (if explicitly supplied), and [elements] is the list of
  /// subpatterns.
  ///
  /// Stack effect: none.
  TypeSchema analyzeListPatternSchema({
    required Type? elementType,
    required List<Node> elements,
  }) {
    if (elementType != null) {
      return operations.listTypeSchema(operations.typeToSchema(elementType));
    }

    if (elements.isEmpty) {
      return operations.listTypeSchema(operations.unknownType);
    }

    TypeSchema? currentGLB;
    for (Node element in elements) {
      TypeSchema? typeToAdd;
      if (isRestPatternElement(element)) {
        Pattern? subPattern = getRestPatternElementPattern(element);
        if (subPattern != null) {
          TypeSchema subPatternType = dispatchPatternSchema(subPattern);
          typeToAdd = operations.matchIterableTypeSchema(subPatternType);
        }
      } else {
        typeToAdd = dispatchPatternSchema(element);
      }
      if (typeToAdd != null) {
        if (currentGLB == null) {
          currentGLB = typeToAdd;
        } else {
          currentGLB = operations.typeSchemaGlb(currentGLB, typeToAdd);
        }
      }
    }
    currentGLB ??= operations.unknownType;
    return operations.listTypeSchema(currentGLB);
  }

  /// Analyzes a logical-and pattern.  [node] is the pattern itself, and [lhs]
  /// and [rhs] are the left and right sides of the `&&` operator.
  ///
  /// See [dispatchPattern] for the meaning of [context].
  ///
  /// Stack effect: pushes (Pattern left, Pattern right)
  PatternResult<Type> analyzeLogicalAndPattern(
      MatchContext<Node, Expression, Pattern, Type, Variable> context,
      Pattern node,
      Node lhs,
      Node rhs) {
    Type matchedValueType = flow.getMatchedValueType();
    // Stack: ()
    dispatchPattern(
      context.withUnnecessaryWildcardKind(
        UnnecessaryWildcardKind.logicalAndPatternOperand,
      ),
      lhs,
    );
    // Stack: (Pattern left)
    dispatchPattern(
      context.withUnnecessaryWildcardKind(
        UnnecessaryWildcardKind.logicalAndPatternOperand,
      ),
      rhs,
    );
    // Stack: (Pattern left, Pattern right)
    return new PatternResult(matchedValueType: matchedValueType);
  }

  /// Computes the type schema for a logical-and pattern.  [lhs] and [rhs] are
  /// the left and right sides of the `&&` operator.
  ///
  /// Stack effect: none.
  TypeSchema analyzeLogicalAndPatternSchema(Node lhs, Node rhs) {
    return operations.typeSchemaGlb(
        dispatchPatternSchema(lhs), dispatchPatternSchema(rhs));
  }

  /// Analyzes a logical-or pattern.  [node] is the pattern itself, and [lhs]
  /// and [rhs] are the left and right sides of the `||` operator.
  ///
  /// Returns a [LogicalOrPatternResult] with information about reported errors.
  ///
  /// See [dispatchPattern] for the meaning of [context].
  ///
  /// Stack effect: pushes (Pattern left, Pattern right)
  LogicalOrPatternResult<Type, Error> analyzeLogicalOrPattern(
      MatchContext<Node, Expression, Pattern, Type, Variable> context,
      Pattern node,
      Node lhs,
      Node rhs) {
    Type matchedValueType = flow.getMatchedValueType();
    Node? irrefutableContext = context.irrefutableContext;
    Error? refutablePatternInIrrefutableContextError;
    if (irrefutableContext != null) {
      refutablePatternInIrrefutableContextError =
          errors.refutablePatternInIrrefutableContext(
              pattern: node, context: irrefutableContext);
      // Avoid cascading errors
      context = context.makeRefutable();
    }
    // Stack: ()
    flow.logicalOrPattern_begin();
    Map<String, int> leftPromotionKeys = {};
    dispatchPattern(
      context
          .withPromotionKeys(leftPromotionKeys)
          .withUnnecessaryWildcardKind(null),
      lhs,
    );
    // Stack: (Pattern left)
    // We'll use the promotion keys allocated during processing of the LHS as
    // the merged keys.
    for (MapEntry<String, int> entry in leftPromotionKeys.entries) {
      String variableName = entry.key;
      int promotionKey = entry.value;
      assert(!context.patternVariablePromotionKeys.containsKey(variableName));
      context.patternVariablePromotionKeys[variableName] = promotionKey;
    }
    flow.logicalOrPattern_afterLhs();
    handle_logicalOrPattern_afterLhs(node);
    Map<String, int> rightPromotionKeys = {};
    dispatchPattern(
      context
          .withPromotionKeys(rightPromotionKeys)
          .withUnnecessaryWildcardKind(null),
      rhs,
    );
    // Stack: (Pattern left, Pattern right)
    for (MapEntry<String, int> entry in rightPromotionKeys.entries) {
      String variableName = entry.key;
      int rightPromotionKey = entry.value;
      int? mergedPromotionKey = leftPromotionKeys[variableName];
      if (mergedPromotionKey == null) {
        // No matching variable on the LHS.  This is an error condition (which
        // has already been reported by VariableBinder).  For error recovery,
        // we still need to add the variable to
        // context.patternVariablePromotionKeys so that later analysis still
        // accounts for the presence of this variable.  So we just use the
        // promotion key from the RHS as the merged key.
        mergedPromotionKey = rightPromotionKey;
        assert(!context.patternVariablePromotionKeys.containsKey(variableName));
        context.patternVariablePromotionKeys[variableName] = mergedPromotionKey;
      } else {
        // Copy the promotion data over to the merged key.
        flow.copyPromotionData(
            sourceKey: rightPromotionKey, destinationKey: mergedPromotionKey);
      }
    }
    // Since the promotion data is now all stored in the merged keys in both
    // flow control branches, the normal join process will combine promotions
    // accordingly.
    flow.logicalOrPattern_end();
    return new LogicalOrPatternResult(
        refutablePatternInIrrefutableContextError:
            refutablePatternInIrrefutableContextError,
        matchedValueType: matchedValueType);
  }

  /// Computes the type schema for a logical-or pattern.  [lhs] and [rhs] are
  /// the left and right sides of the `|` or `&` operator.
  ///
  /// Stack effect: none.
  TypeSchema analyzeLogicalOrPatternSchema(Node lhs, Node rhs) {
    // Logical-or patterns are only allowed in refutable contexts, and
    // refutable contexts don't propagate a type schema into the scrutinee.
    // So this code path is only reachable if the user's code contains errors.
    errors.assertInErrorRecovery();
    return operations.unknownType;
  }

  /// Analyzes a map pattern.  [node] is the pattern itself, [typeArguments]
  /// contain explicit type arguments (if specified), and [elements] is the
  /// list of subpatterns.
  ///
  /// Returns a [MapPatternResult] with the required type and information about
  /// reported errors.
  ///
  /// See [dispatchPattern] for the meaning of [context].
  ///
  /// Stack effect: pushes (n * MapPatternElement) where n = elements.length.
  MapPatternResult<Type, Error> analyzeMapPattern(
    MatchContext<Node, Expression, Pattern, Type, Variable> context,
    Pattern node, {
    required ({Type keyType, Type valueType})? typeArguments,
    required List<Node> elements,
  }) {
    Type matchedValueType = flow.getMatchedValueType();
    Type keyType;
    Type valueType;
    TypeSchema keySchema;
    if (typeArguments != null) {
      keyType = typeArguments.keyType;
      valueType = typeArguments.valueType;
      keySchema = operations.typeToSchema(keyType);
    } else {
      typeArguments = operations.matchMapType(matchedValueType);
      if (typeArguments != null) {
        keyType = typeArguments.keyType;
        valueType = typeArguments.valueType;
        keySchema = operations.typeToSchema(keyType);
      } else if (matchedValueType is SharedDynamicType) {
        keyType = operations.dynamicType;
        valueType = operations.dynamicType;
        keySchema = operations.unknownType;
      } else if (matchedValueType is SharedInvalidType) {
        keyType = operations.errorType;
        valueType = operations.errorType;
        keySchema = operations.unknownType;
      } else {
        keyType = operations.objectQuestionType;
        valueType = operations.objectQuestionType;
        keySchema = operations.unknownType;
      }
    }
    Type requiredType = operations.mapType(
      keyType: keyType,
      valueType: valueType,
    );
    flow.promoteForPattern(
        matchedType: matchedValueType,
        knownType: requiredType,
        matchMayFailEvenIfCorrectType: true);
    // Stack: ()

    Map<int, Error>? restPatternErrors;
    for (int i = 0; i < elements.length; i++) {
      Node element = elements[i];
      if (isRestPatternElement(element)) {
        (restPatternErrors ??= {})[i] =
            errors.restPatternInMap(node: node, element: element);
      }
    }

    for (int i = 0; i < elements.length; i++) {
      Node element = elements[i];
      MapPatternEntry<Expression, Pattern>? entry = getMapPatternEntry(element);
      if (entry != null) {
        Type keyType = analyzeExpression(entry.key, keySchema);
        flow.pushSubpattern(valueType);
        dispatchPattern(
          context.withUnnecessaryWildcardKind(null),
          entry.value,
        );
        handleMapPatternEntry(node, element, keyType);
        flow.popSubpattern();
      } else {
        assert(isRestPatternElement(element));
        Pattern? subPattern = getRestPatternElementPattern(element);
        if (subPattern != null) {
          flow.pushSubpattern(operations.dynamicType);
          dispatchPattern(
            context.withUnnecessaryWildcardKind(null),
            subPattern,
          );
          flow.popSubpattern();
        }
        handleMapPatternRestElement(node, element);
      }
    }
    // Stack: (n * MapPatternElement) where n = elements.length
    Node? irrefutableContext = context.irrefutableContext;
    Error? patternTypeMismatchInIrrefutableContextError;
    if (irrefutableContext != null &&
        !operations.isAssignableTo(matchedValueType, requiredType)) {
      patternTypeMismatchInIrrefutableContextError =
          errors.patternTypeMismatchInIrrefutableContext(
        pattern: node,
        context: irrefutableContext,
        matchedType: matchedValueType,
        requiredType: requiredType,
      );
    }
    Error? emptyMapPatternError;
    if (elements.isEmpty) {
      emptyMapPatternError = errors.emptyMapPattern(pattern: node);
    }
    return new MapPatternResult(
        requiredType: requiredType,
        patternTypeMismatchInIrrefutableContextError:
            patternTypeMismatchInIrrefutableContextError,
        emptyMapPatternError: emptyMapPatternError,
        restPatternErrors: restPatternErrors,
        matchedValueType: matchedValueType);
  }

  /// Computes the type schema for a map pattern.  [typeArguments] contain
  /// explicit type arguments (if specified), and [elements] is the list of
  /// subpatterns.
  ///
  /// Stack effect: none.
  TypeSchema analyzeMapPatternSchema({
    required ({Type keyType, Type valueType})? typeArguments,
    required List<Node> elements,
  }) {
    if (typeArguments != null) {
      return operations.typeToSchema(operations.mapType(
        keyType: typeArguments.keyType,
        valueType: typeArguments.valueType,
      ));
    }

    TypeSchema? valueType;
    for (Node element in elements) {
      MapPatternEntry<Expression, Pattern>? entry = getMapPatternEntry(element);
      if (entry != null) {
        TypeSchema entryValueType = dispatchPatternSchema(entry.value);
        if (valueType == null) {
          valueType = entryValueType;
        } else {
          valueType = operations.typeSchemaGlb(valueType, entryValueType);
        }
      }
    }
    return operations.mapTypeSchema(
      keyTypeSchema: operations.unknownType,
      valueTypeSchema: valueType ?? operations.unknownType,
    );
  }

  /// Analyzes a null-check or null-assert pattern.  [node] is the pattern
  /// itself, [innerPattern] is the sub-pattern, and [isAssert] indicates
  /// whether this is a null-check or a null-assert pattern.
  ///
  /// Returns a [NullCheckOrAssertPatternResult] with information about
  /// reported errors.
  ///
  /// See [dispatchPattern] for the meaning of [context].
  ///
  /// Stack effect: pushes (Pattern innerPattern).
  NullCheckOrAssertPatternResult<Type, Error> analyzeNullCheckOrAssertPattern(
      MatchContext<Node, Expression, Pattern, Type, Variable> context,
      Pattern node,
      Pattern innerPattern,
      {required bool isAssert}) {
    Type matchedValueType = flow.getMatchedValueType();
    // Stack: ()
    Error? refutablePatternInIrrefutableContextError;
    Error? matchedTypeIsStrictlyNonNullableError;
    Node? irrefutableContext = context.irrefutableContext;
    bool matchedTypeIsStrictlyNonNullable = flow.nullCheckOrAssertPattern_begin(
        isAssert: isAssert, matchedValueType: matchedValueType);
    if (irrefutableContext != null && !isAssert) {
      refutablePatternInIrrefutableContextError =
          errors.refutablePatternInIrrefutableContext(
              pattern: node, context: irrefutableContext);
      // Avoid cascading errors
      context = context.makeRefutable();
    } else if (matchedTypeIsStrictlyNonNullable) {
      matchedTypeIsStrictlyNonNullableError =
          errors.matchedTypeIsStrictlyNonNullable(
        pattern: node,
        matchedType: matchedValueType,
      );
    }
    dispatchPattern(
      context.withUnnecessaryWildcardKind(null),
      innerPattern,
    );
    // Stack: (Pattern)
    flow.nullCheckOrAssertPattern_end();

    return new NullCheckOrAssertPatternResult(
        refutablePatternInIrrefutableContextError:
            refutablePatternInIrrefutableContextError,
        matchedTypeIsStrictlyNonNullableError:
            matchedTypeIsStrictlyNonNullableError,
        matchedValueType: matchedValueType);
  }

  /// Computes the type schema for a null-check or null-assert pattern.
  /// [innerPattern] is the sub-pattern and [isAssert] indicates whether this is
  /// a null-check or a null-assert pattern.
  ///
  /// Stack effect: none.
  TypeSchema analyzeNullCheckOrAssertPatternSchema(Pattern innerPattern,
      {required bool isAssert}) {
    if (isAssert) {
      return operations
          .makeTypeSchemaNullable(dispatchPatternSchema(innerPattern));
    } else {
      // Null-check patterns are only allowed in refutable contexts, and
      // refutable contexts don't propagate a type schema into the scrutinee.
      // So this code path is only reachable if the user's code contains errors.
      errors.assertInErrorRecovery();
      return operations.unknownType;
    }
  }

  /// Analyzes an object pattern.  [node] is the pattern itself, and [fields]
  /// is the list of subpatterns.  The [requiredType] must be not `null` in
  /// irrefutable contexts, but can be `null` in refutable contexts, then
  /// [downwardInferObjectPatternRequiredType] is invoked to infer the type.
  ///
  /// Returns a [ObjectPatternResult] with the required type and information
  /// about reported errors.
  ///
  /// See [dispatchPattern] for the meaning of [context].
  ///
  /// Stack effect: pushes (n * Pattern) where n = fields.length.
  ObjectPatternResult<Type, Error> analyzeObjectPattern(
    MatchContext<Node, Expression, Pattern, Type, Variable> context,
    Pattern node, {
    required List<RecordPatternField<Node, Pattern>> fields,
  }) {
    Type matchedValueType = flow.getMatchedValueType();
    Map<int, Error>? duplicateRecordPatternFieldErrors =
        _reportDuplicateRecordPatternFields(node, fields);

    Type requiredType = downwardInferObjectPatternRequiredType(
      matchedType: matchedValueType,
      pattern: node,
    );
    flow.promoteForPattern(
        matchedType: matchedValueType, knownType: requiredType);

    // If the required type is `dynamic` or `Never`, then every getter is
    // treated as having the same type.
    (Object?, Type)? overridePropertyGetType;
    if (requiredType is SharedDynamicType ||
        requiredType is SharedInvalidType ||
        operations.isNever(requiredType)) {
      overridePropertyGetType = (null, requiredType);
    }

    Node? irrefutableContext = context.irrefutableContext;
    Error? patternTypeMismatchInIrrefutableContextError;
    if (irrefutableContext != null &&
        !operations.isAssignableTo(matchedValueType, requiredType)) {
      patternTypeMismatchInIrrefutableContextError =
          errors.patternTypeMismatchInIrrefutableContext(
        pattern: node,
        context: irrefutableContext,
        matchedType: matchedValueType,
        requiredType: requiredType,
      );
    }

    // Stack: ()
    for (RecordPatternField<Node, Pattern> field in fields) {
      var (Object? propertyMember, Type unpromotedPropertyType) =
          overridePropertyGetType ??
              resolveObjectPatternPropertyGet(
                objectPattern: node,
                receiverType: requiredType,
                field: field,
              );
      // Note: an object pattern field must always have a property name, but in
      // error recovery circumstances, one may be absent; when this happens, use
      // the empty string as a the property name to prevent a crash.
      String propertyName = field.name ?? '';
      Type promotedPropertyType = flow.pushPropertySubpattern(
              propertyName, propertyMember, unpromotedPropertyType) ??
          unpromotedPropertyType;
      if (operations.isNever(promotedPropertyType)) {
        flow.handleExit();
      }
      dispatchPattern(
        context.withUnnecessaryWildcardKind(null),
        field.pattern,
      );
      flow.popPropertySubpattern();
    }
    // Stack: (n * Pattern) where n = fields.length

    return new ObjectPatternResult(
        requiredType: requiredType,
        duplicateRecordPatternFieldErrors: duplicateRecordPatternFieldErrors,
        patternTypeMismatchInIrrefutableContextError:
            patternTypeMismatchInIrrefutableContextError,
        matchedValueType: matchedValueType);
  }

  /// Computes the type schema for an object pattern.  [type] is the type
  /// specified with the object name, and with the type arguments applied.
  ///
  /// Stack effect: none.
  TypeSchema analyzeObjectPatternSchema(Type type) {
    return operations.typeToSchema(type);
  }

  /// Analyzes a patternAssignment expression of the form `pattern = rhs`.
  ///
  /// [node] should be the AST node for the entire expression, [pattern] for
  /// the pattern, and [rhs] for the right hand side.
  ///
  /// Stack effect: pushes (Expression, Pattern).
  PatternAssignmentAnalysisResult<Type, TypeSchema> analyzePatternAssignment(
      Expression node, Pattern pattern, Expression rhs) {
    // Stack: ()
    TypeSchema patternSchema = dispatchPatternSchema(pattern);
    Type rhsType = analyzeExpression(rhs, patternSchema);
    // Stack: (Expression)
    flow.patternAssignment_afterRhs(rhs, rhsType);
    Map<String, List<Variable>> componentVariables = {};
    Map<String, int> patternVariablePromotionKeys = {};
    dispatchPattern(
      new MatchContext<Node, Expression, Pattern, Type, Variable>(
        isFinal: false,
        irrefutableContext: node,
        assignedVariables: <Variable, Pattern>{},
        componentVariables: componentVariables,
        patternVariablePromotionKeys: patternVariablePromotionKeys,
      ),
      pattern,
    );
    if (componentVariables.isNotEmpty) {
      // Declared pattern variables should never appear in a pattern assignment
      // so this should never happen.
      errors.assertInErrorRecovery();
    }
    flow.patternAssignment_end();
    // Stack: (Expression, Pattern)
    return new PatternAssignmentAnalysisResult<Type, TypeSchema>(
      patternSchema: patternSchema,
      type: rhsType,
    );
  }

  /// Analyzes a `pattern-for-in` statement or element.
  ///
  /// Statement:
  /// `for (<keyword> <pattern> in <expression>) <statement>`
  ///
  /// Element:
  /// `for (<keyword> <pattern> in <expression>) <body>`
  ///
  /// Stack effect: pushes (Expression, Pattern).
  ///
  /// Returns a [PatternForInResult] containing information on reported errors.
  ///
  /// Note, however, that the caller is responsible for reporting an error if
  /// the static type of [expression] is potentially nullable.
  PatternForInResult<Type, Error> analyzePatternForIn({
    required Node node,
    required bool hasAwait,
    required Pattern pattern,
    required Expression expression,
    required void Function() dispatchBody,
  }) {
    // Stack: ()
    TypeSchema patternTypeSchema = dispatchPatternSchema(pattern);
    TypeSchema expressionTypeSchema = hasAwait
        ? operations.streamTypeSchema(patternTypeSchema)
        : operations.iterableTypeSchema(patternTypeSchema);
    Type expressionType = analyzeExpression(expression, expressionTypeSchema);
    // Stack: (Expression)

    Error? patternForInExpressionIsNotIterableError;
    Type? elementType = hasAwait
        ? operations.matchStreamType(expressionType)
        : operations.matchIterableType(expressionType);
    if (elementType == null) {
      if (expressionType is SharedDynamicType) {
        elementType = operations.dynamicType;
      } else if (expressionType is SharedInvalidType) {
        elementType = operations.errorType;
      } else {
        patternForInExpressionIsNotIterableError =
            errors.patternForInExpressionIsNotIterable(
          node: node,
          expression: expression,
          expressionType: expressionType,
        );
        elementType = operations.errorType;
      }
    }
    flow.patternForIn_afterExpression(elementType);

    Map<String, List<Variable>> componentVariables = {};
    Map<String, int> patternVariablePromotionKeys = {};
    dispatchPattern(
      new MatchContext<Node, Expression, Pattern, Type, Variable>(
        isFinal: false,
        irrefutableContext: node,
        componentVariables: componentVariables,
        patternVariablePromotionKeys: patternVariablePromotionKeys,
      ),
      pattern,
    );
    // Stack: (Expression, Pattern)

    flow.forEach_bodyBegin(node);
    dispatchBody();
    flow.forEach_end();
    flow.patternForIn_end();

    return new PatternForInResult(
        elementType: elementType,
        expressionType: expressionType,
        patternForInExpressionIsNotIterableError:
            patternForInExpressionIsNotIterableError);
  }

  /// Analyzes a patternVariableDeclaration node of the form
  /// `var pattern = initializer` or `final pattern = initializer`.
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
  /// Returns a [PatternVariableDeclarationAnalysisResult] holding the static
  /// type of the initializer and the type schema of the [pattern].
  ///
  /// Stack effect: pushes (Expression, Pattern).
  PatternVariableDeclarationAnalysisResult<Type, TypeSchema>
      analyzePatternVariableDeclaration(
          Node node, Pattern pattern, Expression initializer,
          {required bool isFinal}) {
    // Stack: ()
    TypeSchema patternSchema = dispatchPatternSchema(pattern);
    Type initializerType = analyzeExpression(initializer, patternSchema);
    // Stack: (Expression)
    flow.patternVariableDeclaration_afterInitializer(
        initializer, initializerType);
    Map<String, List<Variable>> componentVariables = {};
    Map<String, int> patternVariablePromotionKeys = {};
    dispatchPattern(
      new MatchContext<Node, Expression, Pattern, Type, Variable>(
        isFinal: isFinal,
        irrefutableContext: node,
        componentVariables: componentVariables,
        patternVariablePromotionKeys: patternVariablePromotionKeys,
      ),
      pattern,
    );
    _finishJoinedPatternVariables(
        {}, componentVariables, patternVariablePromotionKeys,
        location: JoinedPatternVariableLocation.singlePattern);
    flow.patternVariableDeclaration_end();
    // Stack: (Expression, Pattern)
    return new PatternVariableDeclarationAnalysisResult(
        initializerType: initializerType, patternSchema: patternSchema);
  }

  /// Analyzes a record pattern.  [node] is the pattern itself, and [fields]
  /// is the list of subpatterns.
  ///
  /// Returns a [RecordPatternResult] with the required type and information
  /// about reported errors.
  ///
  /// See [dispatchPattern] for the meaning of [context].
  ///
  /// Stack effect: pushes (n * Pattern) where n = fields.length.
  RecordPatternResult<Type, Error> analyzeRecordPattern(
    MatchContext<Node, Expression, Pattern, Type, Variable> context,
    Pattern node, {
    required List<RecordPatternField<Node, Pattern>> fields,
  }) {
    Type matchedValueType = flow.getMatchedValueType();
    List<Type> demonstratedPositionalTypes = [];
    List<(String, Type)> demonstratedNamedTypes = [];
    void dispatchField(
      RecordPatternField<Node, Pattern> field,
      Type matchedType,
    ) {
      flow.pushSubpattern(matchedType);
      dispatchPattern(
        context.withUnnecessaryWildcardKind(null),
        field.pattern,
      );
      Type demonstratedType = flow.getMatchedValueType();
      String? name = field.name;
      if (name == null) {
        demonstratedPositionalTypes.add(demonstratedType);
      } else {
        demonstratedNamedTypes.add((name, demonstratedType));
      }
      flow.popSubpattern();
    }

    void dispatchFields(Type matchedType) {
      for (int i = 0; i < fields.length; i++) {
        dispatchField(fields[i], matchedType);
      }
    }

    Map<int, Error>? duplicateRecordPatternFieldErrors =
        _reportDuplicateRecordPatternFields(node, fields);

    // Build the required type.
    int requiredTypePositionalCount = 0;
    List<(String, Type)> requiredTypeNamedTypes = [];
    for (RecordPatternField<Node, Pattern> field in fields) {
      String? name = field.name;
      if (name == null) {
        requiredTypePositionalCount++;
      } else {
        requiredTypeNamedTypes.add(
          (name, operations.objectQuestionType),
        );
      }
    }
    Type requiredType = operations.recordType(
      positional: new List.filled(
        requiredTypePositionalCount,
        operations.objectQuestionType,
      ),
      named: requiredTypeNamedTypes,
    );
    flow.promoteForPattern(
        matchedType: matchedValueType, knownType: requiredType);

    // Stack: ()
    if (matchedValueType is SharedRecordType<Type>) {
      List<Type>? fieldTypes = _matchRecordTypeShape(fields, matchedValueType);
      if (fieldTypes != null) {
        assert(fieldTypes.length == fields.length);
        for (int i = 0; i < fields.length; i++) {
          dispatchField(fields[i], fieldTypes[i]);
        }
      } else {
        dispatchFields(operations.objectQuestionType);
      }
    } else if (matchedValueType is SharedDynamicType) {
      dispatchFields(operations.dynamicType);
    } else if (matchedValueType is SharedInvalidType) {
      dispatchFields(operations.errorType);
    } else {
      dispatchFields(operations.objectQuestionType);
    }
    // Stack: (n * Pattern) where n = fields.length

    Node? irrefutableContext = context.irrefutableContext;
    Error? patternTypeMismatchInIrrefutableContextError;
    if (irrefutableContext != null &&
        !operations.isAssignableTo(matchedValueType, requiredType)) {
      patternTypeMismatchInIrrefutableContextError =
          errors.patternTypeMismatchInIrrefutableContext(
        pattern: node,
        context: irrefutableContext,
        matchedType: matchedValueType,
        requiredType: requiredType,
      );
    }

    Type demonstratedType = operations.recordType(
        positional: demonstratedPositionalTypes, named: demonstratedNamedTypes);
    flow.promoteForPattern(
        matchedType: matchedValueType,
        knownType: demonstratedType,
        matchFailsIfWrongType: false);
    return new RecordPatternResult(
        requiredType: requiredType,
        duplicateRecordPatternFieldErrors: duplicateRecordPatternFieldErrors,
        patternTypeMismatchInIrrefutableContextError:
            patternTypeMismatchInIrrefutableContextError,
        matchedValueType: matchedValueType);
  }

  /// Computes the type schema for a record pattern.
  ///
  /// Stack effect: none.
  TypeSchema analyzeRecordPatternSchema({
    required List<RecordPatternField<Node, Pattern>> fields,
  }) {
    List<TypeSchema> positional = [];
    List<(String, TypeSchema)> named = [];
    for (RecordPatternField<Node, Pattern> field in fields) {
      TypeSchema fieldType = dispatchPatternSchema(field.pattern);
      String? name = field.name;
      if (name != null) {
        named.add((name, fieldType));
      } else {
        positional.add(fieldType);
      }
    }
    return operations.recordTypeSchema(positional: positional, named: named);
  }

  /// Analyzes a relational pattern.  [node] is the pattern itself, and
  /// [operand] is a constant expression that will be passed to the relational
  /// operator.
  ///
  /// This method will invoke [resolveRelationalPatternOperator] to obtain
  /// information about the operator.
  ///
  /// Returns a [RelationalPatternResult] with the type of the [operand] and
  /// information about reported errors.
  ///
  /// See [dispatchPattern] for the meaning of [context].
  ///
  /// Stack effect: pushes (Expression).
  RelationalPatternResult<Type, Error> analyzeRelationalPattern(
      MatchContext<Node, Expression, Pattern, Type, Variable> context,
      Pattern node,
      Expression operand) {
    Type matchedValueType = flow.getMatchedValueType();
    // Stack: ()
    Error? refutablePatternInIrrefutableContextError;
    Node? irrefutableContext = context.irrefutableContext;
    if (irrefutableContext != null) {
      refutablePatternInIrrefutableContextError =
          errors.refutablePatternInIrrefutableContext(
              pattern: node, context: irrefutableContext);
    }
    RelationalOperatorResolution<Type>? operator =
        resolveRelationalPatternOperator(node, matchedValueType);
    Type? parameterType = operator?.parameterType;
    bool isEquality = switch (operator?.kind) {
      RelationalOperatorKind.equals => true,
      RelationalOperatorKind.notEquals => true,
      _ => false
    };
    if (isEquality && parameterType != null) {
      parameterType = operations.makeNullable(parameterType);
    }
    Type operandType = analyzeExpression(
        operand,
        parameterType == null
            ? operations.unknownType
            : operations.typeToSchema(parameterType));
    if (isEquality) {
      flow.equalityRelationalPattern_end(operand, operandType,
          notEqual: operator?.kind == RelationalOperatorKind.notEquals,
          matchedValueType: matchedValueType);
    } else {
      flow.nonEqualityRelationalPattern_end();
    }
    // Stack: (Expression)
    Error? argumentTypeNotAssignableError;
    Error? operatorReturnTypeNotAssignableToBoolError;
    if (operator != null) {
      if (parameterType != null &&
          !operations.isAssignableTo(operandType, parameterType)) {
        argumentTypeNotAssignableError =
            errors.relationalPatternOperandTypeNotAssignable(
          pattern: node,
          operandType: operandType,
          parameterType: operator.parameterType,
        );
      }
      if (!operations.isAssignableTo(
          operator.returnType, operations.boolType)) {
        operatorReturnTypeNotAssignableToBoolError =
            errors.relationalPatternOperatorReturnTypeNotAssignableToBool(
          pattern: node,
          returnType: operator.returnType,
        );
      }
    }
    return new RelationalPatternResult(
        operandType: operandType,
        refutablePatternInIrrefutableContextError:
            refutablePatternInIrrefutableContextError,
        operatorReturnTypeNotAssignableToBoolError:
            operatorReturnTypeNotAssignableToBoolError,
        argumentTypeNotAssignableError: argumentTypeNotAssignableError,
        matchedValueType: matchedValueType);
  }

  /// Computes the type schema for a relational pattern.
  ///
  /// Stack effect: none.
  TypeSchema analyzeRelationalPatternSchema() {
    // Relational patterns are only allowed in refutable contexts, and refutable
    // contexts don't propagate a type schema into the scrutinee.  So this
    // code path is only reachable if the user's code contains errors.
    errors.assertInErrorRecovery();
    return operations.unknownType;
  }

  /// Analyzes an expression of the form `switch (expression) { cases }`.
  ///
  /// Returns a [SwitchExpressionResult] with the static type of the switch
  /// expression and information about reported errors.
  ///
  /// Stack effect: pushes (Expression, n * ExpressionCase), where n is the
  /// number of cases.
  SwitchExpressionResult<Type, Error> analyzeSwitchExpression(
      Expression node, Expression scrutinee, int numCases, TypeSchema schema) {
    // Stack: ()

    // The static type of a switch expression `E` of the form `switch (e0) { p1
    // => e1, p2 => e2, ... pn => en }` with context type `K` is computed as
    // follows:
    //
    // - The scrutinee (`e0`) is first analyzed with context type `_`.
    Type expressionType = analyzeExpression(scrutinee, operations.unknownType);
    // Stack: (Expression)
    handleSwitchScrutinee(expressionType);
    flow.switchStatement_expressionEnd(null, scrutinee, expressionType);

    // - If the switch expression has no cases, its static type is `Never`.
    Map<int, Error>? nonBooleanGuardErrors;
    Map<int, Type>? guardTypes;
    Type staticType;
    if (numCases == 0) {
      staticType = operations.neverType;
    } else {
      // - Otherwise, for each case `pi => ei`, let `Ti` be the type of `ei`
      //   inferred with context type `K`.
      // - Let `T` be the least upper bound of the static types of all the case
      //   expressions.
      // - Let `S` be the greatest closure of `K`.
      Type? t;
      Type s = operations.greatestClosure(schema);
      bool allCasesSatisfyContext = true;
      for (int i = 0; i < numCases; i++) {
        // Stack: (Expression, i * ExpressionCase)
        SwitchExpressionMemberInfo<Node, Expression, Variable> memberInfo =
            getSwitchExpressionMemberInfo(node, i);
        flow.switchStatement_beginAlternatives();
        flow.switchStatement_beginAlternative();
        handleSwitchBeforeAlternative(node, caseIndex: i, subIndex: 0);
        Node? pattern = memberInfo.head.pattern;
        Expression? guard;
        if (pattern != null) {
          Map<String, List<Variable>> componentVariables = {};
          Map<String, int> patternVariablePromotionKeys = {};
          dispatchPattern(
            new MatchContext<Node, Expression, Pattern, Type, Variable>(
              isFinal: false,
              switchScrutinee: scrutinee,
              componentVariables: componentVariables,
              patternVariablePromotionKeys: patternVariablePromotionKeys,
            ),
            pattern,
          );
          _finishJoinedPatternVariables(
            memberInfo.head.variables,
            componentVariables,
            patternVariablePromotionKeys,
            location: JoinedPatternVariableLocation.singlePattern,
          );
          // Stack: (Expression, i * ExpressionCase, Pattern)
          guard = memberInfo.head.guard;
          bool hasGuard = guard != null;
          if (hasGuard) {
            Type guardType = analyzeExpression(
                guard, operations.typeToSchema(operations.boolType));
            Error? nonBooleanGuardError = _checkGuardType(guard, guardType);
            (guardTypes ??= {})[i] = guardType;
            if (nonBooleanGuardError != null) {
              (nonBooleanGuardErrors ??= {})[i] = nonBooleanGuardError;
            }
            // Stack: (Expression, i * ExpressionCase, Pattern, Expression)
          } else {
            handleNoGuard(node, i);
            // Stack: (Expression, i * ExpressionCase, Pattern, Expression)
          }
          handleCaseHead(node, caseIndex: i, subIndex: 0);
        } else {
          handleDefault(node, caseIndex: i, subIndex: 0);
        }
        flow.switchStatement_endAlternative(guard, {});
        flow.switchStatement_endAlternatives(null, hasLabels: false);
        // Stack: (Expression, i * ExpressionCase, CaseHead)
        Type ti = analyzeExpression(memberInfo.expression, schema);
        if (allCasesSatisfyContext && !operations.isSubtypeOf(ti, s)) {
          allCasesSatisfyContext = false;
        }
        flow.switchStatement_afterCase();
        // Stack: (Expression, i * ExpressionCase, CaseHead, Expression)
        if (t == null) {
          t = ti;
        } else {
          t = operations.lub(t, ti);
        }
        finishExpressionCase(node, i);
        // Stack: (Expression, (i + 1) * ExpressionCase)
      }
      // If `inferenceUpdate3` is not enabled, then the type of `E` is `T`.
      if (!this.options.inferenceUpdate3Enabled) {
        staticType = t!;
      } else
      // - If `T <: S`, then the type of `E` is `T`.
      if (operations.isSubtypeOf(t!, s)) {
        staticType = t;
      } else
      // - Otherwise, if `Ti <: S` for all `i`, then the type of `E` is `S`.
      if (allCasesSatisfyContext) {
        staticType = s;
      } else
      // - Otherwise, the type of `E` is `T`.
      {
        staticType = t;
      }
    }
    // Stack: (Expression, numCases * ExpressionCase)
    flow.switchStatement_end(true);
    return new SwitchExpressionResult(
        type: staticType,
        nonBooleanGuardErrors: nonBooleanGuardErrors,
        guardTypes: guardTypes);
  }

  /// Analyzes a statement of the form `switch (expression) { cases }`.
  ///
  /// Stack effect: pushes (Expression, n * StatementCase), where n is the
  /// number of cases after merging together cases that share a body.
  SwitchStatementTypeAnalysisResult<Type, Error> analyzeSwitchStatement(
      Statement node, Expression scrutinee, final int numCases) {
    // Stack: ()
    Type scrutineeType = analyzeExpression(scrutinee, operations.unknownType);
    // Stack: (Expression)
    handleSwitchScrutinee(scrutineeType);
    flow.switchStatement_expressionEnd(node, scrutinee, scrutineeType);
    bool hasDefault = false;
    bool lastCaseTerminates = true;
    Map<int, Error>? switchCaseCompletesNormallyErrors;
    Map<int, Map<int, Error>>? nonBooleanGuardErrors;
    Map<int, Map<int, Type>>? guardTypes;
    for (int caseIndex = 0; caseIndex < numCases; caseIndex++) {
      // Stack: (Expression, numExecutionPaths * StatementCase)
      flow.switchStatement_beginAlternatives();
      // Stack: (Expression, numExecutionPaths * StatementCase,
      //         numHeads * CaseHead)
      SwitchStatementMemberInfo<Node, Statement, Expression, Variable>
          memberInfo = getSwitchStatementMemberInfo(node, caseIndex);
      List<CaseHeadOrDefaultInfo<Node, Expression, Variable>> heads =
          memberInfo.heads;
      for (int headIndex = 0; headIndex < heads.length; headIndex++) {
        CaseHeadOrDefaultInfo<Node, Expression, Variable> head =
            heads[headIndex];
        Node? pattern = head.pattern;
        flow.switchStatement_beginAlternative();
        handleSwitchBeforeAlternative(node,
            caseIndex: caseIndex, subIndex: headIndex);
        Expression? guard;
        if (pattern != null) {
          Map<String, List<Variable>> componentVariables = {};
          Map<String, int> patternVariablePromotionKeys = {};
          dispatchPattern(
            new MatchContext<Node, Expression, Pattern, Type, Variable>(
              isFinal: false,
              switchScrutinee: scrutinee,
              componentVariables: componentVariables,
              patternVariablePromotionKeys: patternVariablePromotionKeys,
            ),
            pattern,
          );
          _finishJoinedPatternVariables(
            head.variables,
            componentVariables,
            patternVariablePromotionKeys,
            location: JoinedPatternVariableLocation.singlePattern,
          );
          // Stack: (Expression, numExecutionPaths * StatementCase,
          //         numHeads * CaseHead, Pattern),
          guard = head.guard;
          if (guard != null) {
            Type guardType = analyzeExpression(
                guard, operations.typeToSchema(operations.boolType));
            Error? nonBooleanGuardError = _checkGuardType(guard, guardType);
            ((guardTypes ??= {})[caseIndex] ??= {})[headIndex] = guardType;
            if (nonBooleanGuardError != null) {
              ((nonBooleanGuardErrors ??= {})[caseIndex] ??= {})[headIndex] =
                  nonBooleanGuardError;
            }
            // Stack: (Expression, numExecutionPaths * StatementCase,
            //         numHeads * CaseHead, Pattern, Expression),
          } else {
            handleNoGuard(node, caseIndex);
          }
          handleCaseHead(node, caseIndex: caseIndex, subIndex: headIndex);
        } else {
          hasDefault = true;
          handleDefault(node, caseIndex: caseIndex, subIndex: headIndex);
        }
        // Stack: (Expression, numExecutionPaths * StatementCase,
        //         numHeads * CaseHead),
        flow.switchStatement_endAlternative(guard, head.variables);
      }
      // Stack: (Expression, numExecutionPaths * StatementCase,
      //         numHeads * CaseHead)
      PatternVariableInfo<Variable> patternVariableInfo =
          flow.switchStatement_endAlternatives(node,
              hasLabels: memberInfo.hasLabels);
      Map<String, Variable> variables = memberInfo.variables;
      if (memberInfo.hasLabels || heads.length > 1) {
        _finishJoinedPatternVariables(
          variables,
          patternVariableInfo.componentVariables,
          patternVariableInfo.patternVariablePromotionKeys,
          location: JoinedPatternVariableLocation.sharedCaseScope,
        );
      }
      handleCase_afterCaseHeads(node, caseIndex, variables.values);
      // Stack: (Expression, numExecutionPaths * StatementCase, CaseHeads)
      // If there are joined variables, declare them.
      for (Statement statement in memberInfo.body) {
        dispatchStatement(statement);
      }
      // Stack: (Expression, numExecutionPaths * StatementCase, CaseHeads,
      //         n * Statement), where n = body.length
      lastCaseTerminates = !flow.switchStatement_afterCase();
      if (caseIndex < numCases - 1 &&
          options.nullSafetyEnabled &&
          !options.patternsEnabled &&
          !lastCaseTerminates) {
        (switchCaseCompletesNormallyErrors ??= {})[caseIndex] = errors
            .switchCaseCompletesNormally(node: node, caseIndex: caseIndex);
      }
      handleMergedStatementCase(node,
          caseIndex: caseIndex, isTerminating: lastCaseTerminates);
      // Stack: (Expression, (numExecutionPaths + 1) * StatementCase)
    }
    // Stack: (Expression, numExecutionPaths * StatementCase)
    bool isExhaustive;
    bool requiresExhaustivenessValidation;
    if (hasDefault) {
      isExhaustive = true;
      requiresExhaustivenessValidation = false;
    } else if (options.patternsEnabled) {
      requiresExhaustivenessValidation =
          isExhaustive = operations.isAlwaysExhaustiveType(scrutineeType);
    } else {
      isExhaustive = isLegacySwitchExhaustive(node, scrutineeType);
      requiresExhaustivenessValidation = false;
    }
    flow.switchStatement_end(isExhaustive);
    return new SwitchStatementTypeAnalysisResult(
      hasDefault: hasDefault,
      isExhaustive: isExhaustive,
      lastCaseTerminates: lastCaseTerminates,
      requiresExhaustivenessValidation: requiresExhaustivenessValidation,
      scrutineeType: scrutineeType,
      switchCaseCompletesNormallyErrors: switchCaseCompletesNormallyErrors,
      nonBooleanGuardErrors: nonBooleanGuardErrors,
      guardTypes: guardTypes,
    );
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
      {required bool isFinal}) {
    Type inferredType = declaredType ?? operations.dynamicType;
    setVariableType(variable, inferredType);
    flow.declare(variable, inferredType, initialized: false);
    return inferredType;
  }

  /// Analyzes a wildcard pattern.  [node] is the pattern.
  ///
  /// Returns a [WildcardPattern] with information about reported errors.
  ///
  /// See [dispatchPattern] for the meaning of [context].
  ///
  /// Stack effect: none.
  WildcardPatternResult<Type, Error> analyzeWildcardPattern({
    required MatchContext<Node, Expression, Pattern, Type, Variable> context,
    required Pattern node,
    required Type? declaredType,
  }) {
    Type matchedValueType = flow.getMatchedValueType();
    Node? irrefutableContext = context.irrefutableContext;
    Error? patternTypeMismatchInIrrefutableContextError;
    if (irrefutableContext != null && declaredType != null) {
      if (!operations.isAssignableTo(matchedValueType, declaredType)) {
        patternTypeMismatchInIrrefutableContextError =
            errors.patternTypeMismatchInIrrefutableContext(
          pattern: node,
          context: irrefutableContext,
          matchedType: matchedValueType,
          requiredType: declaredType,
        );
      }
    }

    bool isAlwaysMatching;
    if (declaredType != null) {
      isAlwaysMatching = flow.promoteForPattern(
          matchedType: matchedValueType, knownType: declaredType);
    } else {
      isAlwaysMatching = true;
    }

    UnnecessaryWildcardKind? unnecessaryWildcardKind =
        context.unnecessaryWildcardKind;
    if (isAlwaysMatching && unnecessaryWildcardKind != null) {
      errors.unnecessaryWildcardPattern(
        pattern: node,
        kind: unnecessaryWildcardKind,
      );
    }
    return new WildcardPatternResult(
        patternTypeMismatchInIrrefutableContextError:
            patternTypeMismatchInIrrefutableContextError,
        matchedValueType: matchedValueType);
  }

  /// Computes the type schema for a wildcard pattern.  [declaredType] is the
  /// explicitly declared type (if present).
  ///
  /// Stack effect: none.
  TypeSchema analyzeWildcardPatternSchema({
    required Type? declaredType,
  }) {
    return declaredType == null
        ? operations.unknownType
        : operations.typeToSchema(declaredType);
  }

  /// Calls the appropriate `analyze` method according to the form of
  /// collection [element], and then adjusts the stack as needed to combine
  /// any sub-structures into a single collection element.
  ///
  /// For example, if [element] is an `if` element, calls [analyzeIfElement].
  ///
  /// Stack effect: pushes (CollectionElement).
  void dispatchCollectionElement(Node element, Object? context);

  /// Calls the appropriate `analyze` method according to the form of
  /// [node], and then adjusts the stack as needed to combine any
  /// sub-structures into a single expression.
  ///
  /// For example, if [node] is a binary expression (`a + b`), calls
  /// [analyzeBinaryExpression].
  ///
  /// Stack effect: pushes (Expression).
  ExpressionTypeAnalysisResult<Type> dispatchExpression(
      Expression node, TypeSchema schema);

  /// Calls the appropriate `analyze` method according to the form of [pattern].
  ///
  /// [context] keeps track of other contextual information pertinent to the
  /// matching of the [pattern], such as the context of the top-level pattern,
  /// and the information accumulated while matching previous patterns.
  ///
  /// Stack effect: pushes (Pattern).
  PatternResult<Type> dispatchPattern(
      MatchContext<Node, Expression, Pattern, Type, Variable> context,
      Node pattern);

  /// Calls the appropriate `analyze...Schema` method according to the form of
  /// [pattern].
  ///
  /// Stack effect: none.
  TypeSchema dispatchPatternSchema(Node pattern);

  /// Calls the appropriate `analyze` method according to the form of
  /// [statement], and then adjusts the stack as needed to combine any
  /// sub-structures into a single statement.
  ///
  /// For example, if [statement] is a `while` loop, calls [analyzeWhileLoop].
  ///
  /// Stack effect: pushes (Statement).
  void dispatchStatement(Statement statement);

  /// Infers the type for the [pattern], should be a subtype of [matchedType].
  Type downwardInferObjectPatternRequiredType({
    required Type matchedType,
    required Pattern pattern,
  });

  /// Called after visiting an expression case.
  ///
  /// [node] is the enclosing switch expression, and [caseIndex] is the index of
  /// this code path within the switch expression's cases.
  ///
  /// Stack effect: pops (CaseHead, Expression) and pushes (ExpressionCase).
  void finishExpressionCase(Expression node, int caseIndex);

  void finishJoinedPatternVariable(
    Variable variable, {
    required JoinedPatternVariableLocation location,
    required JoinedPatternVariableInconsistency inconsistency,
    required bool isFinal,
    required Type type,
  });

  /// If the [element] is a map pattern entry, returns it.
  MapPatternEntry<Expression, Pattern>? getMapPatternEntry(Node element);

  /// If [node] is [isRestPatternElement], returns its optional pattern.
  Pattern? getRestPatternElementPattern(Node node);

  /// Returns an [ExpressionCaseInfo] object describing the [index]th `case` or
  /// `default` clause in the switch expression [node].
  ///
  /// Note: it is allowed for the client's AST nodes for `case` and `default`
  /// clauses to implement [ExpressionCaseInfo], in which case this method can
  /// simply return the [index]th `case` or `default` clause.
  ///
  /// See [analyzeSwitchExpression].
  SwitchExpressionMemberInfo<Node, Expression, Variable>
      getSwitchExpressionMemberInfo(Expression node, int index);

  /// Returns a [StatementCaseInfo] object describing the [index]th `case` or
  /// `default` clause in the switch statement [node].
  ///
  /// Note: it is allowed for the client's AST nodes for `case` and `default`
  /// clauses to implement [StatementCaseInfo], in which case this method can
  /// simply return the [index]th `case` or `default` clause.
  ///
  /// See [analyzeSwitchStatement].
  SwitchStatementMemberInfo<Node, Statement, Expression, Variable>
      getSwitchStatementMemberInfo(Statement node, int caseIndex);

  /// Called after visiting the pattern in `if-case` statement.
  void handle_ifCaseStatement_afterPattern({required Statement node}) {}

  /// Called after visiting the expression of an `if` element.
  void handle_ifElement_conditionEnd(Node node) {}

  /// Called after visiting the `else` element of an `if` element.
  void handle_ifElement_elseEnd(Node node, Node ifFalse) {}

  /// Called after visiting the `then` element of an `if` element.
  void handle_ifElement_thenEnd(Node node, Node ifTrue) {}

  /// Called after visiting the expression of an `if` statement.
  void handle_ifStatement_conditionEnd(Statement node) {}

  /// Called after visiting the `else` statement of an `if` statement.
  void handle_ifStatement_elseEnd(Statement node, Statement ifFalse) {}

  /// Called after visiting the `then` statement of an `if` statement.
  void handle_ifStatement_thenEnd(Statement node, Statement ifTrue) {}

  /// Called after visiting the left hand side of a logical-or (`||`) pattern.
  void handle_logicalOrPattern_afterLhs(Pattern node) {}

  /// Called after visiting a merged set of `case` / `default` clauses.
  ///
  /// [node] is the enclosing switch statement, [caseIndex] is the index of the
  /// merged `case` or `default` group.
  ///
  /// Stack effect: pops (numHeads * CaseHead) and pushes (CaseHeads).
  void handleCase_afterCaseHeads(
      Statement node, int caseIndex, Iterable<Variable> variables);

  /// Called after visiting a single `case` clause, consisting of a pattern and
  /// an optional guard.
  ///
  /// [node] is the enclosing switch statement or switch expression,
  /// [caseIndex] is the index of the `case` clause, and [subIndex] is the index
  /// of the case head.
  ///
  /// Stack effect: pops (Pattern, Expression) and pushes (CaseHead).
  void handleCaseHead(Node node,
      {required int caseIndex, required int subIndex});

  /// Called after visiting a `default` clause.
  ///
  /// [node] is the enclosing switch statement or switch expression and
  /// [caseIndex] is the index of the `default` clause.
  /// [subIndex] is the index of the case head.
  ///
  /// Stack effect: pushes (CaseHead).
  void handleDefault(
    Node node, {
    required int caseIndex,
    required int subIndex,
  });

  /// Called after visiting a rest element in a list pattern.
  ///
  /// Stack effect: pushes (Pattern).
  void handleListPatternRestElement(Pattern container, Node restElement);

  /// Called after visiting an entry element in a map pattern.
  ///
  /// Stack effect: pushes (MapPatternElement).
  void handleMapPatternEntry(
      Pattern container, Node entryElement, Type keyType);

  /// Called after visiting a rest element in a map pattern.
  ///
  /// Stack effect: pushes (MapPatternElement).
  void handleMapPatternRestElement(Pattern container, Node restElement);

  /// Called after visiting a merged statement case.
  ///
  /// [node] is enclosing switch statement, [caseIndex] is the index of the
  /// merged `case` or `default` group.
  ///
  /// If [isTerminating] is `true`, then flow analysis has determined that the
  /// case ends in a construct that doesn't complete normally (e.g. a `break`,
  /// `return`, `continue`, `throw`, or infinite loop); the client can use this
  /// to determine whether a jump is needed to the end of the switch statement.
  ///
  /// Stack effect: pops (CaseHeads, numStatements * Statement) and pushes
  /// (StatementCase).
  void handleMergedStatementCase(Statement node,
      {required int caseIndex, required bool isTerminating});

  /// Called when visiting a syntactic construct where there is an implicit
  /// no-op collection element.  For example, this is called in place of the
  /// missing `else` part of an `if` element that lacks an `else` clause.
  ///
  /// Stack effect: pushes (CollectionElement).
  void handleNoCollectionElement(Node node);

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

  /// Called before visiting a single `case` or `default` clause.
  ///
  /// [node] is the enclosing switch statement or switch expression and
  /// [caseIndex] is the index of the `case` or `default` clause.
  /// [subIndex] is the index of the case head.
  void handleSwitchBeforeAlternative(Node node,
      {required int caseIndex, required int subIndex});

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
  /// `default` clause, and patterns support is disabled.
  bool isLegacySwitchExhaustive(Node node, Type expressionType);

  /// Returns whether [node] is a rest element in a list or map pattern.
  bool isRestPatternElement(Node node);

  /// Queries whether [pattern] is a variable pattern.
  bool isVariablePattern(Node pattern);

  /// Returns the type of the property in [receiverType] that corresponds to
  /// the name of the [field].  If the property cannot be resolved, the client
  /// should report an error, and return `dynamic` for recovery.
  (Object?, Type) resolveObjectPatternPropertyGet({
    required Pattern objectPattern,
    required Type receiverType,
    required RecordPatternField<Node, Pattern> field,
  });

  /// Resolves the relational operator for [node] assuming that the value being
  /// matched has static type [matchedValueType].
  ///
  /// If no operator is found, `null` should be returned.  (This could happen
  /// either because the code is invalid, or because [matchedValueType] is
  /// `dynamic`).
  RelationalOperatorResolution<Type>? resolveRelationalPatternOperator(
      Pattern node, Type matchedValueType);

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
      flow.ifStatement_end(false);
    } else {
      flow.ifStatement_elseBegin();
      dispatchStatement(ifFalse);
      flow.ifStatement_end(true);
      handle_ifStatement_elseEnd(node, ifFalse);
    }
    // Stack: (Statement ifTrue, Statement ifFalse)
  }

  /// Common functionality shared by [analyzeIfElement] and
  /// [analyzeIfCaseElement].
  ///
  /// Stack effect: pushes (CollectionElement ifTrue,
  /// CollectionElement ifFalse).
  void _analyzeIfElementCommon(
      Node node, Node ifTrue, Node? ifFalse, Object? context) {
    // Stack: ()
    dispatchCollectionElement(ifTrue, context);
    handle_ifElement_thenEnd(node, ifTrue);
    // Stack: (CollectionElement ifTrue)
    if (ifFalse == null) {
      handleNoCollectionElement(node);
      flow.ifStatement_end(false);
    } else {
      flow.ifStatement_elseBegin();
      dispatchCollectionElement(ifFalse, context);
      flow.ifStatement_end(true);
      handle_ifElement_elseEnd(node, ifFalse);
    }
    // Stack: (CollectionElement ifTrue, CollectionElement ifFalse)
  }

  Error? _checkGuardType(Expression expression, Type type) {
    // TODO(paulberry): harmonize this with analyzer's checkForNonBoolExpression
    // TODO(paulberry): spec says the type must be `bool` or `dynamic`.  This
    // logic permits `T extends bool`, `T promoted to bool`, or `Never`.  What
    // do we want?
    if (!operations.isAssignableTo(type, operations.boolType)) {
      return errors.nonBooleanCondition(node: expression);
    }
    return null;
  }

  void _finishJoinedPatternVariables(
    Map<String, Variable> variables,
    Map<String, List<Variable>> componentVariables,
    Map<String, int> patternVariablePromotionKeys, {
    required JoinedPatternVariableLocation location,
  }) {
    assert(() {
      // Every entry in `variables` should match a variable we know about.
      for (String variableName in variables.keys) {
        assert(patternVariablePromotionKeys.containsKey(variableName));
      }
      return true;
    }());
    for (MapEntry<String, int> entry in patternVariablePromotionKeys.entries) {
      String variableName = entry.key;
      int promotionKey = entry.value;
      Variable? variable = variables[variableName];
      List<Variable> components = componentVariables[variableName] ?? [];
      bool isFirst = true;
      Type? typeIfConsistent;
      bool? isFinalIfConsistent;
      bool isIdenticalToComponent = false;
      for (Variable component in components) {
        if (identical(variable, component)) {
          isIdenticalToComponent = true;
        }
        Type componentType = operations.variableType(component);
        bool isComponentFinal = operations.isVariableFinal(component);
        if (isFirst) {
          typeIfConsistent = componentType;
          isFinalIfConsistent = isComponentFinal;
          isFirst = false;
        } else {
          bool inconsistencyFound = false;
          if (typeIfConsistent != null &&
              !_structurallyEqualAfterNormTypes(
                  typeIfConsistent, componentType)) {
            typeIfConsistent = null;
            inconsistencyFound = true;
          }
          if (isFinalIfConsistent != null &&
              isFinalIfConsistent != isComponentFinal) {
            isFinalIfConsistent = null;
            inconsistencyFound = true;
          }
          if (inconsistencyFound &&
              location == JoinedPatternVariableLocation.singlePattern &&
              variable != null) {
            errors.inconsistentJoinedPatternVariable(
                variable: variable, component: component);
          }
        }
      }
      if (variable != null) {
        if (!isIdenticalToComponent) {
          finishJoinedPatternVariable(variable,
              location: location,
              inconsistency: typeIfConsistent != null &&
                      isFinalIfConsistent != null
                  ? JoinedPatternVariableInconsistency.none
                  : JoinedPatternVariableInconsistency.differentFinalityOrType,
              isFinal: isFinalIfConsistent ?? false,
              type: typeIfConsistent ?? operations.errorType);
          flow.assignMatchedPatternVariable(variable, promotionKey);
        }
      }
    }
  }

  /// If the shape described by [fields] is the same as the shape of the
  /// [matchedType], returns matched types for each field in [fields].
  /// Otherwise returns `null`.
  List<Type>? _matchRecordTypeShape(
    List<RecordPatternField<Node, Pattern>> fields,
    SharedRecordType<Type> matchedType,
  ) {
    Map<String, Type> matchedTypeNamed = {};
    for (var SharedNamedType(:name, :type) in matchedType.namedTypes) {
      matchedTypeNamed[name] = type;
    }

    List<Type> result = [];
    int namedCount = 0;
    Iterator<Type> positionalIterator = matchedType.positionalTypes.iterator;
    for (RecordPatternField<Node, Pattern> field in fields) {
      Type? fieldType;
      String? name = field.name;
      if (name != null) {
        fieldType = matchedTypeNamed[name];
        if (fieldType == null) {
          return null;
        }
        namedCount++;
      } else {
        if (!positionalIterator.moveNext()) {
          return null;
        }
        fieldType = positionalIterator.current;
      }
      result.add(fieldType);
    }
    if (positionalIterator.moveNext()) {
      return null;
    }
    if (namedCount != matchedTypeNamed.length) {
      return null;
    }

    assert(result.length == fields.length);
    return result;
  }

  /// Reports errors for duplicate named record fields.
  Map<int, Error>? _reportDuplicateRecordPatternFields(
      Pattern pattern, List<RecordPatternField<Node, Pattern>> fields) {
    Map<int, Error>? errorResults;
    Map<String, RecordPatternField<Node, Pattern>> nameToField = {};
    for (int i = 0; i < fields.length; i++) {
      RecordPatternField<Node, Pattern> field = fields[i];
      String? name = field.name;
      if (name != null) {
        RecordPatternField<Node, Pattern>? original = nameToField[name];
        if (original != null) {
          (errorResults ??= {})[i] = errors.duplicateRecordPatternField(
            objectOrRecordPattern: pattern,
            name: name,
            original: original,
            duplicate: field,
          );
        } else {
          nameToField[name] = field;
        }
      }
    }
    return errorResults;
  }

  bool _structurallyEqualAfterNormTypes(Type type1, Type type2) {
    Type norm1 = operations.normalize(type1);
    Type norm2 = operations.normalize(type2);
    return norm1.isStructurallyEqualTo(norm2);
  }
}

/// Interface used by the shared [TypeAnalyzer] logic to report error conditions
/// up to the client during the "visit" phase of type analysis.
abstract class TypeAnalyzerErrors<
    Node extends Object,
    Statement extends Node,
    Expression extends Node,
    Variable extends Object,
    Type extends SharedType,
    Pattern extends Node,
    Error> implements TypeAnalyzerErrorsBase {
  /// Called if pattern support is disabled and a case constant's static type
  /// doesn't properly match the scrutinee's static type.
  Error caseExpressionTypeMismatch(
      {required Expression scrutinee,
      required Expression caseExpression,
      required Type scrutineeType,
      required Type caseExpressionType,
      required bool nullSafetyEnabled});

  /// Called for variable that is assigned more than once.
  ///
  /// Returns an error object that is passed on the the caller.
  Error duplicateAssignmentPatternVariable({
    required Variable variable,
    required Pattern original,
    required Pattern duplicate,
  });

  /// Called for a pair of named fields have the same name.
  Error duplicateRecordPatternField({
    required Pattern objectOrRecordPattern,
    required String name,
    required RecordPatternField<Node, Pattern> original,
    required RecordPatternField<Node, Pattern> duplicate,
  });

  /// Called for a duplicate rest pattern found in a list or map pattern.
  Error duplicateRestPattern({
    required Pattern mapOrListPattern,
    required Node original,
    required Node duplicate,
  });

  /// Called if a map pattern does not have elements.
  ///
  /// [pattern] is the map pattern.
  Error emptyMapPattern({
    required Pattern pattern,
  });

  /// Called when both branches have variables with the same name, but these
  /// variables either don't have the same finality, or their `NORM` types
  /// are not structurally equal.
  void inconsistentJoinedPatternVariable({
    required Variable variable,
    required Variable component,
  });

  /// Called when a null-assert or null-check pattern is used with the matched
  /// type that is strictly non-nullable, so the null check is not necessary.
  Error? matchedTypeIsStrictlyNonNullable({
    required Pattern pattern,
    required Type matchedType,
  });

  /// Called when the matched type of a cast pattern is a subtype of the
  /// required type, so the cast is not necessary.
  void matchedTypeIsSubtypeOfRequired({
    required Pattern pattern,
    required Type matchedType,
    required Type requiredType,
  });

  /// Called if the static type of a condition is not assignable to `bool`.
  Error nonBooleanCondition({required Expression node});

  /// Called if in a pattern `for-in` statement or element, the [expression]
  /// that should be an `Iterable` (or dynamic) is actually not.
  ///
  /// [expressionType] is the actual type of the [expression].
  Error patternForInExpressionIsNotIterable({
    required Node node,
    required Expression expression,
    required Type expressionType,
  });

  /// Called if, for a pattern in an irrefutable context, the matched type of
  /// the pattern is not assignable to the required type.
  ///
  /// [pattern] is the AST node of the pattern with the type error, [context] is
  /// the containing AST node that established an irrefutable context,
  /// [matchedType] is the matched type, and [requiredType] is the required
  /// type.
  Error patternTypeMismatchInIrrefutableContext(
      {required Pattern pattern,
      required Node context,
      required Type matchedType,
      required Type requiredType});

  /// Called if a refutable pattern is illegally used in an irrefutable context.
  ///
  /// [pattern] is the AST node of the refutable pattern, and [context] is the
  /// containing AST node that established an irrefutable context.
  ///
  /// TODO(paulberry): move this error reporting to the parser.
  Error refutablePatternInIrrefutableContext(
      {required Node pattern, required Node context});

  /// Called if the operand of the [pattern] has the type [operandType], which
  /// is not assignable to [parameterType] of the invoked relational operator.
  Error relationalPatternOperandTypeNotAssignable({
    required Pattern pattern,
    required Type operandType,
    required Type parameterType,
  });

  /// Called if the [returnType] of the invoked relational operator is not
  /// assignable to `bool`.
  Error relationalPatternOperatorReturnTypeNotAssignableToBool({
    required Pattern pattern,
    required Type returnType,
  });

  /// Called if a rest pattern found inside a map pattern.
  ///
  /// [node] is the map pattern.  [element] is the rest pattern.
  Error restPatternInMap({required Pattern node, required Node element});

  /// Called if one of the case bodies of a switch statement completes normally
  /// (other than the last case body), and the "patterns" feature is not
  /// enabled.
  ///
  /// [node] is the AST node of the switch statement.  [caseIndex] is the index
  /// of the merged case with the erroneous case body.
  Error switchCaseCompletesNormally(
      {required Statement node, required int caseIndex});

  /// Called when a wildcard pattern appears in the context where it is not
  /// necessary, e.g. `0 && var _` vs. `[var _]`, and does not add anything
  /// to type promotion, e.g. `final x = 0; if (x case int _ && > 0) {}`.
  void unnecessaryWildcardPattern({
    required Pattern pattern,
    required UnnecessaryWildcardKind kind,
  });
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

  final bool inferenceUpdate3Enabled;

  TypeAnalyzerOptions(
      {required this.nullSafetyEnabled,
      required this.patternsEnabled,
      required this.inferenceUpdate3Enabled});
}
