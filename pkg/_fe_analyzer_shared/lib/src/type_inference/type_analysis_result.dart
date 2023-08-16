// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'type_analyzer.dart';

/// Result for analyzing an assigned variable pattern in
/// [TypeAnalyzer.analyzeAssignedVariablePattern].
class AssignedVariablePatternResult<Error> {
  /// Error for when a variable was assigned multiple times within a pattern.
  final Error? duplicateAssignmentPatternVariableError;

  /// Error for when the matched value type is not assignable to the variable
  /// type in an irrefutable context.
  final Error? patternTypeMismatchInIrrefutableContextError;

  AssignedVariablePatternResult(
      {required this.duplicateAssignmentPatternVariableError,
      required this.patternTypeMismatchInIrrefutableContextError});
}

/// Result for analyzing a constant pattern in
/// [TypeAnalyzer.analyzeConstantPattern].
class ConstantPatternResult<Type extends Object, Error> {
  /// The static type of the constant expression.
  final Type expressionType;

  /// Error for when the pattern occurred in an irrefutable context.
  final Error? refutablePatternInIrrefutableContextError;

  /// Error for when the pattern, used as a case constant expression, does not
  /// have a valid type wrt. the switch expression type.
  final Error? caseExpressionTypeMismatchError;

  ConstantPatternResult(
      {required this.expressionType,
      required this.refutablePatternInIrrefutableContextError,
      required this.caseExpressionTypeMismatchError});
}

/// Result for analyzing a declared variable pattern in
/// [TypeAnalyzer.analyzeDeclaredVariablePattern].
class DeclaredVariablePatternResult<Type extends Object, Error> {
  /// The static type of the variable.
  final Type staticType;

  /// Error for when the matched value type is not assignable to the static
  /// type in an irrefutable context.
  final Error? patternTypeMismatchInIrrefutableContextError;

  DeclaredVariablePatternResult(
      {required this.staticType,
      required this.patternTypeMismatchInIrrefutableContextError});
}

/// Container for the result of running type analysis on an expression.
///
/// This class keeps track of a provisional type of the expression (prior to
/// resolving null shorting) as well as the information necessary to resolve
/// null shorting.
abstract class ExpressionTypeAnalysisResult<Type extends Object> {
  /// Type of the expression before resolving null shorting.
  ///
  /// For example, if `this` is the result of analyzing `(... as int?)?.isEven`,
  /// [provisionalType] will be `bool`, because the `isEven` getter returns
  /// `bool`, and it is not yet known (until looking at the surrounding code)
  /// whether there will be additional selectors after `isEven` that should act
  /// on the `bool` type.
  Type get provisionalType;

  /// Resolves any pending null shorting.  For example, if `this` is the result
  /// of analyzing `(... as int?)?.isEven`, then calling [resolveShorting] will
  /// cause the `?.` to be desugared (if code generation is occurring) and will
  /// return the type `bool?`.
  ///
  /// TODO(paulberry): document what calls back to the client might be made by
  /// invoking this method.
  Type resolveShorting();
}

/// Result for analyzing an if-case statement or element in
/// [TypeAnalyzer.analyzeIfCaseStatement] and
/// [TypeAnalyzer.analyzeIfCaseElement].
class IfCaseStatementResult<Type extends Object, Error> {
  /// The static type of the matched expression.
  final Type matchedExpressionType;

  /// Error for when the guard has a non-bool type.
  final Error? nonBooleanGuardError;

  /// The type of the guard expression, if present.
  final Type? guardType;

  IfCaseStatementResult(
      {required this.matchedExpressionType,
      required this.nonBooleanGuardError,
      required this.guardType});
}

/// Container for the result of running type analysis on an integer literal.
class IntTypeAnalysisResult<Type extends Object>
    extends SimpleTypeAnalysisResult<Type> {
  /// Whether the integer literal was converted to a double.
  final bool convertedToDouble;

  IntTypeAnalysisResult({required super.type, required this.convertedToDouble});
}

/// Result for analyzing a list pattern in [TypeAnalyzer.analyzeListPattern].
class ListPatternResult<Type extends Object, Error> {
  /// The required type of the list pattern.
  final Type requiredType;

  /// Errors for when multiple rest patterns occurred within the list pattern.
  ///
  /// The key is the index of the pattern within the list pattern.
  ///
  /// This is `null` if no such errors where found.
  final Map<int, Error>? duplicateRestPatternErrors;

  /// Error for when the matched value type is not assignable to the required
  /// type in an irrefutable context.
  final Error? patternTypeMismatchInIrrefutableContextError;

  ListPatternResult(
      {required this.requiredType,
      required this.duplicateRestPatternErrors,
      required this.patternTypeMismatchInIrrefutableContextError});
}

/// Result for analyzing a logical or pattern in
/// [TypeAnalyzer.analyzeLogicalOrPattern].
class LogicalOrPatternResult<Error> {
  /// Error for when the pattern occurred in an irrefutable context.
  final Error? refutablePatternInIrrefutableContextError;

  LogicalOrPatternResult(
      {required this.refutablePatternInIrrefutableContextError});
}

/// Result for analyzing a map pattern in [TypeAnalyzer.analyzeMapPattern].
class MapPatternResult<Type extends Object, Error> {
  /// The required type of the map pattern.
  final Type requiredType;

  /// Error for when the matched value type is not assignable to the required
  /// type in an irrefutable context.
  final Error? patternTypeMismatchInIrrefutableContextError;

  /// Error for when the map pattern is empty.
  final Error? emptyMapPatternError;

  /// Errors for when the map pattern contains rest patterns.
  ///
  /// The key is the indices it which the rest pattern occurred.
  final Map<int, Error>? restPatternErrors;

  MapPatternResult(
      {required this.requiredType,
      required this.patternTypeMismatchInIrrefutableContextError,
      required this.emptyMapPatternError,
      required this.restPatternErrors});
}

/// Information about the code context surrounding a pattern match.
class MatchContext<Node extends Object, Expression extends Node,
    Pattern extends Node, Type extends Object, Variable extends Object> {
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
          Map<String, int> patternVariablePromotionKeys) =>
      new MatchContext(
        irrefutableContext: irrefutableContext,
        isFinal: isFinal,
        switchScrutinee: null,
        assignedVariables: assignedVariables,
        componentVariables: componentVariables,
        patternVariablePromotionKeys: patternVariablePromotionKeys,
        unnecessaryWildcardKind: unnecessaryWildcardKind,
      );

  /// Returns a modified version of `this`, with both [initializer] and
  /// [switchScrutinee] set to `null` (because this context is not for a
  /// top-level pattern anymore).
  MatchContext<Node, Expression, Pattern, Type, Variable>
      withUnnecessaryWildcardKind(
          UnnecessaryWildcardKind? unnecessaryWildcardKind) {
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
class NullCheckOrAssertPatternResult<Error> {
  /// Error for when the pattern occurred in an irrefutable context.
  final Error? refutablePatternInIrrefutableContextError;

  /// Error for when the matched type is known to be non-null.
  final Error? matchedTypeIsStrictlyNonNullableError;

  NullCheckOrAssertPatternResult(
      {required this.refutablePatternInIrrefutableContextError,
      required this.matchedTypeIsStrictlyNonNullableError});
}

/// Result for analyzing an object pattern in
/// [TypeAnalyzer.analyzeObjectPattern].
class ObjectPatternResult<Type extends Object, Error> {
  /// The required type of the object pattern.
  final Type requiredType;

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

  ObjectPatternResult(
      {required this.requiredType,
      required this.duplicateRecordPatternFieldErrors,
      required this.patternTypeMismatchInIrrefutableContextError});
}

/// Container for the result of running type analysis on a pattern assignment.
class PatternAssignmentAnalysisResult<Type extends Object>
    extends SimpleTypeAnalysisResult<Type> {
  /// The type schema of the pattern on the left hand size of the assignment.
  final Type patternSchema;

  PatternAssignmentAnalysisResult({
    required this.patternSchema,
    required super.type,
  });
}

/// Container for the result of running type analysis on a pattern variable
/// declaration.
class PatternVariableDeclarationAnalysisResult<Type extends Object> {
  /// The type schema of the pattern on the left hand size of the declaration.
  final Type patternSchema;

  /// The type of the initializer expression.
  final Type initializerType;

  PatternVariableDeclarationAnalysisResult({
    required this.patternSchema,
    required this.initializerType,
  });
}

/// Result for analyzing a pattern-for-in statement or element in
/// [TypeAnalyzer.analyzePatternForIn].
class PatternForInResult<Type extends Object, Error> {
  /// The static type of the elements of the for in expression.
  final Type elementType;

  /// Error for when the expression is not an iterable.
  final Error? patternForInExpressionIsNotIterableError;

  PatternForInResult(
      {required this.elementType,
      required this.patternForInExpressionIsNotIterableError});
}

/// Result for analyzing a record pattern in
/// [TypeAnalyzer.analyzeRecordPattern].
class RecordPatternResult<Type extends Object, Error> {
  /// The required type of the record pattern.
  final Type requiredType;

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

  RecordPatternResult(
      {required this.requiredType,
      required this.duplicateRecordPatternFieldErrors,
      required this.patternTypeMismatchInIrrefutableContextError});
}

/// Result for analyzing a relational pattern in
/// [TypeAnalyzer.analyzeRelationalPattern].
class RelationalPatternResult<Type extends Object, Error> {
  /// The static type of the operand.
  final Type operandType;

  /// Error for when the pattern occurred in an irrefutable context.
  final Error? refutablePatternInIrrefutableContextError;

  /// Error for when the operand type is not assignable to the parameter type
  /// of the relational operator.
  final Error? argumentTypeNotAssignableError;

  /// Error for when the relational operator does not return a bool.
  final Error? operatorReturnTypeNotAssignableToBoolError;

  RelationalPatternResult(
      {required this.operandType,
      required this.refutablePatternInIrrefutableContextError,
      required this.argumentTypeNotAssignableError,
      required this.operatorReturnTypeNotAssignableToBoolError});
}

/// Container for the result of running type analysis on an expression that does
/// not contain any null shorting.
class SimpleTypeAnalysisResult<Type extends Object>
    implements ExpressionTypeAnalysisResult<Type> {
  /// The static type of the expression.
  final Type type;

  SimpleTypeAnalysisResult({required this.type});

  @override
  Type get provisionalType => type;

  @override
  Type resolveShorting() => type;
}

/// Result for analyzing a switch expression in
/// [TypeAnalyzer.analyzeSwitchExpression].
class SwitchExpressionResult<Type extends Object, Error>
    extends SimpleTypeAnalysisResult<Type> {
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
  final Map<int, Type>? guardTypes;

  SwitchExpressionResult(
      {required super.type,
      required this.nonBooleanGuardErrors,
      required this.guardTypes});
}

/// Container for the result of running type analysis on an integer literal.
class SwitchStatementTypeAnalysisResult<Type extends Object, Error> {
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
  final Type scrutineeType;

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
  final Map<int, Map<int, Type>>? guardTypes;

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
class WildcardPatternResult<Error> {
  /// Error for when the matched value type is not assignable to the wildcard
  /// type in an irrefutable context.
  final Error? patternTypeMismatchInIrrefutableContextError;

  WildcardPatternResult(
      {required this.patternTypeMismatchInIrrefutableContextError});
}
