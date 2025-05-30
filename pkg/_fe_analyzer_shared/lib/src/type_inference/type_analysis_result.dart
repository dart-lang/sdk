// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../types/shared_type.dart';
import 'type_analyzer.dart';

/// Result for analyzing an assigned variable pattern in
/// [TypeAnalyzer.analyzeAssignedVariablePattern].
class AssignedVariablePatternResult<Error> extends PatternResult {
  /// Error for when a variable was assigned multiple times within a pattern.
  final Error? duplicateAssignmentPatternVariableError;

  /// Error for when the matched value type is not assignable to the variable
  /// type in an irrefutable context.
  final Error? patternTypeMismatchInIrrefutableContextError;

  AssignedVariablePatternResult({
    required this.duplicateAssignmentPatternVariableError,
    required this.patternTypeMismatchInIrrefutableContextError,
    required super.matchedValueType,
  });
}

/// Result for analyzing a constant pattern in
/// [TypeAnalyzer.analyzeConstantPattern].
class ConstantPatternResult<Error> extends PatternResult {
  /// The static type of the constant expression.
  final SharedTypeView expressionType;

  /// Error for when the pattern occurred in an irrefutable context.
  final Error? refutablePatternInIrrefutableContextError;

  /// Error for when the pattern, used as a case constant expression, does not
  /// have a valid type wrt. the switch expression type.
  final Error? caseExpressionTypeMismatchError;

  ConstantPatternResult({
    required this.expressionType,
    required this.refutablePatternInIrrefutableContextError,
    required this.caseExpressionTypeMismatchError,
    required super.matchedValueType,
  });
}

/// Result for analyzing a declared variable pattern in
/// [TypeAnalyzer.analyzeDeclaredVariablePattern].
class DeclaredVariablePatternResult<Error> extends PatternResult {
  /// The static type of the variable.
  final SharedTypeView staticType;

  /// Error for when the matched value type is not assignable to the static
  /// type in an irrefutable context.
  final Error? patternTypeMismatchInIrrefutableContextError;

  DeclaredVariablePatternResult({
    required this.staticType,
    required this.patternTypeMismatchInIrrefutableContextError,
    required super.matchedValueType,
  });
}

/// Container for the result of running type analysis on an expression.
///
/// This class keeps track of the type of the expression. Derived classes expose
/// other results of type analysis that are specific to certain expression
/// types.
class ExpressionTypeAnalysisResult {
  /// The static type of the expression.
  final SharedTypeView type;

  ExpressionTypeAnalysisResult({required this.type});
}

/// Result for analyzing an if-case statement or element in
/// [TypeAnalyzer.analyzeIfCaseStatement] and
/// [TypeAnalyzer.analyzeIfCaseElement].
class IfCaseStatementResult<Error> {
  /// The static type of the matched expression.
  final SharedTypeView matchedExpressionType;

  /// Error for when the guard has a non-bool type.
  final Error? nonBooleanGuardError;

  /// The type of the guard expression, if present.
  final SharedTypeView? guardType;

  IfCaseStatementResult({
    required this.matchedExpressionType,
    required this.nonBooleanGuardError,
    required this.guardType,
  });
}

/// Container for the result of running type analysis on an integer literal.
class IntTypeAnalysisResult extends ExpressionTypeAnalysisResult {
  /// Whether the integer literal was converted to a double.
  final bool convertedToDouble;

  IntTypeAnalysisResult({required super.type, required this.convertedToDouble});
}

/// Result for analyzing a list pattern in [TypeAnalyzer.analyzeListPattern].
class ListPatternResult<Error> extends PatternResult {
  /// The required type of the list pattern.
  final SharedTypeView requiredType;

  /// Errors for when multiple rest patterns occurred within the list pattern.
  ///
  /// The key is the index of the pattern within the list pattern.
  ///
  /// This is `null` if no such errors where found.
  final Map<int, Error>? duplicateRestPatternErrors;

  /// Error for when the matched value type is not assignable to the required
  /// type in an irrefutable context.
  final Error? patternTypeMismatchInIrrefutableContextError;

  ListPatternResult({
    required this.requiredType,
    required this.duplicateRestPatternErrors,
    required this.patternTypeMismatchInIrrefutableContextError,
    required super.matchedValueType,
  });
}

/// Result for analyzing a logical or pattern in
/// [TypeAnalyzer.analyzeLogicalOrPattern].
class LogicalOrPatternResult<Error> extends PatternResult {
  /// Error for when the pattern occurred in an irrefutable context.
  final Error? refutablePatternInIrrefutableContextError;

  LogicalOrPatternResult({
    required this.refutablePatternInIrrefutableContextError,
    required super.matchedValueType,
  });
}

/// Result for analyzing a map pattern in [TypeAnalyzer.analyzeMapPattern].
class MapPatternResult<Error> extends PatternResult {
  /// The required type of the map pattern.
  final SharedTypeView requiredType;

  /// Error for when the matched value type is not assignable to the required
  /// type in an irrefutable context.
  final Error? patternTypeMismatchInIrrefutableContextError;

  /// Error for when the map pattern is empty.
  final Error? emptyMapPatternError;

  /// Errors for when the map pattern contains rest patterns.
  ///
  /// The key is the indices it which the rest pattern occurred.
  final Map<int, Error>? restPatternErrors;

  MapPatternResult({
    required this.requiredType,
    required this.patternTypeMismatchInIrrefutableContextError,
    required this.emptyMapPatternError,
    required this.restPatternErrors,
    required super.matchedValueType,
  });
}

/// Information about the code context surrounding a pattern match.
class MatchContext<
  Node extends Object,
  Expression extends Node,
  Pattern extends Node,
  Type extends Object,
  Variable extends Object
> {
  /// If non-`null`, the match is being done in an irrefutable context, and this
  /// is the surrounding AST node that establishes the irrefutable context.
  final Node? irrefutableContext;

  /// Indicates whether variables declared in the pattern should be `final`.
  final bool isFinal;

  /// The switch scrutinee, or `null` if this pattern does not occur in a switch
  /// statement or switch expression, or this pattern is not the top-level
  /// pattern.
  final Expression? switchScrutinee;

  /// If the match is being done in a pattern assignment, the set of variables
  /// assigned so far.
  final Map<Variable, Pattern>? assignedVariables;

  /// For each variable name in the pattern, a list of the variables which might
  /// capture that variable's value, depending upon which alternative is taken
  /// in a logical-or pattern.
  final Map<String, List<Variable>> componentVariables;

  /// For each variable name in the pattern, the promotion key holding the value
  /// captured by that variable.
  final Map<String, int> patternVariablePromotionKeys;

  /// If non-null, the warning that should be issued if the pattern is `_`
  final UnnecessaryWildcardKind? unnecessaryWildcardKind;

  MatchContext({
    this.irrefutableContext,
    required this.isFinal,
    this.switchScrutinee,
    this.assignedVariables,
    required this.componentVariables,
    required this.patternVariablePromotionKeys,
    this.unnecessaryWildcardKind,
  });

  /// Returns a modified version of `this`, with [irrefutableContext] set to
  /// `null`.  This is used to suppress cascading errors after reporting
  /// [TypeAnalyzerErrors.refutablePatternInIrrefutableContext].
  MatchContext<Node, Expression, Pattern, Type, Variable> makeRefutable() =>
      irrefutableContext == null
          ? this
          : new MatchContext(
            isFinal: isFinal,
            switchScrutinee: switchScrutinee,
            assignedVariables: assignedVariables,
            componentVariables: componentVariables,
            patternVariablePromotionKeys: patternVariablePromotionKeys,
          );

  /// Returns a modified version of `this`, with a new value of
  /// [patternVariablePromotionKeys].
  MatchContext<Node, Expression, Pattern, Type, Variable> withPromotionKeys(
    Map<String, int> patternVariablePromotionKeys,
  ) => new MatchContext(
    irrefutableContext: irrefutableContext,
    isFinal: isFinal,
    switchScrutinee: null,
    assignedVariables: assignedVariables,
    componentVariables: componentVariables,
    patternVariablePromotionKeys: patternVariablePromotionKeys,
    unnecessaryWildcardKind: unnecessaryWildcardKind,
  );

  /// Returns a modified version of `this`, with [switchScrutinee] set to `null`
  /// (because this context is not for a top-level pattern anymore).
  MatchContext<Node, Expression, Pattern, Type, Variable>
  withUnnecessaryWildcardKind(
    UnnecessaryWildcardKind? unnecessaryWildcardKind,
  ) {
    return new MatchContext(
      irrefutableContext: irrefutableContext,
      isFinal: isFinal,
      assignedVariables: assignedVariables,
      switchScrutinee: null,
      componentVariables: componentVariables,
      patternVariablePromotionKeys: patternVariablePromotionKeys,
      unnecessaryWildcardKind: unnecessaryWildcardKind,
    );
  }
}

/// Result for analyzing a null check or null assert pattern in
/// [TypeAnalyzer.analyzeNullCheckOrAssertPattern].
class NullCheckOrAssertPatternResult<Error> extends PatternResult {
  /// Error for when the pattern occurred in an irrefutable context.
  final Error? refutablePatternInIrrefutableContextError;

  /// Error for when the matched type is known to be non-null.
  final Error? matchedTypeIsStrictlyNonNullableError;

  NullCheckOrAssertPatternResult({
    required this.refutablePatternInIrrefutableContextError,
    required this.matchedTypeIsStrictlyNonNullableError,
    required super.matchedValueType,
  });
}

/// Result for analyzing an object pattern in
/// [TypeAnalyzer.analyzeObjectPattern].
class ObjectPatternResult<Error> extends PatternResult {
  /// The required type of the object pattern.
  final SharedTypeView requiredType;

  /// Errors for when the same property name was used multiple times in the
  /// object pattern.
  ///
  /// The key is the index of the duplicate field within the object pattern.
  ///
  /// This is `null` if no such properties were found.
  final Map<int, Error>? duplicateRecordPatternFieldErrors;

  /// Error for when the matched value type is not assignable to the required
  /// type in an irrefutable context.
  final Error? patternTypeMismatchInIrrefutableContextError;

  ObjectPatternResult({
    required this.requiredType,
    required this.duplicateRecordPatternFieldErrors,
    required this.patternTypeMismatchInIrrefutableContextError,
    required super.matchedValueType,
  });
}

/// Container for the result of running type analysis on a pattern assignment.
class PatternAssignmentAnalysisResult extends ExpressionTypeAnalysisResult {
  /// The type schema of the pattern on the left hand size of the assignment.
  final SharedTypeSchemaView patternSchema;

  PatternAssignmentAnalysisResult({
    required this.patternSchema,
    required super.type,
  });
}

/// Result for analyzing a pattern-for-in statement or element in
/// [TypeAnalyzer.analyzePatternForIn].
class PatternForInResult<Error> {
  /// The static type of the elements of the for in expression.
  final SharedTypeView elementType;

  /// The static type of the collection of elements of the for in expression.
  final SharedTypeView expressionType;

  /// Error for when the expression is not an iterable.
  final Error? patternForInExpressionIsNotIterableError;

  PatternForInResult({
    required this.elementType,
    required this.expressionType,
    required this.patternForInExpressionIsNotIterableError,
  });
}

/// Result for analyzing a pattern in [TypeAnalyzer].
class PatternResult {
  /// The matched value type that was used to type check the pattern.
  final SharedTypeView matchedValueType;

  PatternResult({required this.matchedValueType});
}

/// Container for the result of running type analysis on a pattern variable
/// declaration.
class PatternVariableDeclarationAnalysisResult {
  /// The type schema of the pattern on the left hand size of the declaration.
  final SharedTypeSchemaView patternSchema;

  /// The type of the initializer expression.
  final SharedTypeView initializerType;

  PatternVariableDeclarationAnalysisResult({
    required this.patternSchema,
    required this.initializerType,
  });
}

/// Result for analyzing a record pattern in
/// [TypeAnalyzer.analyzeRecordPattern].
class RecordPatternResult<Error> extends PatternResult {
  /// The required type of the record pattern.
  final SharedTypeView requiredType;

  /// Errors for when the same property name was used multiple times in the
  /// record pattern.
  ///
  /// The key is the index of the duplicate field within the record pattern.
  ///
  /// This is `null` if no such errors where found.
  final Map<int, Error>? duplicateRecordPatternFieldErrors;

  /// Error for when the matched value type is not assignable to the required
  /// type in an irrefutable context.
  final Error? patternTypeMismatchInIrrefutableContextError;

  RecordPatternResult({
    required this.requiredType,
    required this.duplicateRecordPatternFieldErrors,
    required this.patternTypeMismatchInIrrefutableContextError,
    required super.matchedValueType,
  });
}

/// Result for analyzing a relational pattern in
/// [TypeAnalyzer.analyzeRelationalPattern].
class RelationalPatternResult<Error> extends PatternResult {
  /// The static type of the operand.
  final SharedTypeView operandType;

  /// Error for when the pattern occurred in an irrefutable context.
  final Error? refutablePatternInIrrefutableContextError;

  /// Error for when the operand type is not assignable to the parameter type
  /// of the relational operator.
  final Error? argumentTypeNotAssignableError;

  /// Error for when the relational operator does not return a bool.
  final Error? operatorReturnTypeNotAssignableToBoolError;

  RelationalPatternResult({
    required this.operandType,
    required this.refutablePatternInIrrefutableContextError,
    required this.argumentTypeNotAssignableError,
    required this.operatorReturnTypeNotAssignableToBoolError,
    required super.matchedValueType,
  });
}

/// Result for analyzing a switch expression in
/// [TypeAnalyzer.analyzeSwitchExpression].
class SwitchExpressionResult<Error> extends ExpressionTypeAnalysisResult {
  /// Errors for non-bool guards.
  ///
  /// The key is the case index of the erroneous guard.
  ///
  /// This is `null` if no such errors where found.
  final Map<int, Error>? nonBooleanGuardErrors;

  /// The types of the guard expressions.
  ///
  /// The key is the case index of the guard.
  ///
  /// This is `null` if no such guards where present.
  final Map<int, SharedTypeView>? guardTypes;

  SwitchExpressionResult({
    required super.type,
    required this.nonBooleanGuardErrors,
    required this.guardTypes,
  });
}

/// Container for the result of running type analysis on an integer literal.
class SwitchStatementTypeAnalysisResult<Error> {
  /// Whether the switch statement had a `default` clause.
  final bool hasDefault;

  /// Whether the switch statement was exhaustive.
  final bool isExhaustive;

  /// Whether the last case body in the switch statement terminated.
  final bool lastCaseTerminates;

  /// If `true`, patterns support is enabled, there is no default clause, and
  /// the static type of the scrutinee expression is an "always exhaustive"
  /// type.  Therefore, flow analysis has assumed (without checking) that the
  /// switch statement is exhaustive.  So at a later stage of compilation, the
  /// exhaustiveness checking algorithm should check whether this switch
  /// statement was exhaustive, and report a compile-time error if it wasn't.
  final bool requiresExhaustivenessValidation;

  /// The static type of the scrutinee expression.
  final SharedTypeView scrutineeType;

  /// Errors for the cases that don't complete normally.
  ///
  /// This is `null` if no such errors where found.
  final Map<int, Error>? switchCaseCompletesNormallyErrors;

  /// Errors for non-bool guards.
  ///
  /// The keys of the maps are case and head indices of the erroneous guard.
  ///
  /// This is `null` if no such errors where found.
  final Map<int, Map<int, Error>>? nonBooleanGuardErrors;

  /// The types of the guard expressions.
  ///
  /// The keys of the maps are case and head indices of the guard.
  ///
  /// This is `null` if no such guards where present.
  final Map<int, Map<int, SharedTypeView>>? guardTypes;

  SwitchStatementTypeAnalysisResult({
    required this.hasDefault,
    required this.isExhaustive,
    required this.lastCaseTerminates,
    required this.requiresExhaustivenessValidation,
    required this.scrutineeType,
    required this.switchCaseCompletesNormallyErrors,
    required this.nonBooleanGuardErrors,
    required this.guardTypes,
  });
}

/// The location of a wildcard pattern that was found unnecessary.
///
/// When a wildcard pattern always matches, and is not required by the
/// by the location, we can report it as unnecessary. The locations where it
/// is necessary include list patterns, record patterns, cast patterns, etc.
enum UnnecessaryWildcardKind {
  /// The wildcard pattern is the left or the right side of a logical-and
  /// pattern. Because we found that is always matches, it has no effect,
  /// and can be removed.
  logicalAndPatternOperand,
}

/// Result for analyzing a wildcard pattern
/// [TypeAnalyzer.analyzeWildcardPattern].
class WildcardPatternResult<Error> extends PatternResult {
  /// Error for when the matched value type is not assignable to the wildcard
  /// type in an irrefutable context.
  final Error? patternTypeMismatchInIrrefutableContextError;

  WildcardPatternResult({
    required this.patternTypeMismatchInIrrefutableContextError,
    required super.matchedValueType,
  });
}
