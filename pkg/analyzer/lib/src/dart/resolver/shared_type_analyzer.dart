// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/type_analysis_result.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart'
    as shared;
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/diagnostic/diagnostic_factory.dart';
import 'package:analyzer/src/error/codes.dart';

typedef SharedPatternField
    = shared.RecordPatternField<PatternFieldImpl, DartPatternImpl>;

/// Implementation of [shared.TypeAnalyzerErrors] that reports errors using the
/// analyzer's [ErrorReporter] class.
class SharedTypeAnalyzerErrors
    implements
        shared.TypeAnalyzerErrors<AstNode, Statement, Expression,
            PromotableElement, SharedTypeView<DartType>, DartPattern, void> {
  final ErrorReporter _errorReporter;

  SharedTypeAnalyzerErrors(this._errorReporter);

  @override
  void assertInErrorRecovery() {}

  @override
  void caseExpressionTypeMismatch(
      {required Expression scrutinee,
      required Expression caseExpression,
      required SharedTypeView<DartType> scrutineeType,
      required SharedTypeView<DartType> caseExpressionType,
      required bool nullSafetyEnabled}) {
    _errorReporter.atNode(
      caseExpression,
      CompileTimeErrorCode
          .CASE_EXPRESSION_TYPE_IS_NOT_SWITCH_EXPRESSION_SUBTYPE,
      arguments: [caseExpressionType, scrutineeType],
    );
  }

  @override
  void duplicateAssignmentPatternVariable({
    required covariant PromotableElement variable,
    required covariant AssignedVariablePatternImpl original,
    required covariant AssignedVariablePatternImpl duplicate,
  }) {
    _errorReporter.reportError(
      DiagnosticFactory().duplicateAssignmentPatternVariable(
        source: _errorReporter.source,
        variable: variable,
        original: original,
        duplicate: duplicate,
      ),
    );
  }

  @override
  void duplicateRecordPatternField({
    required DartPattern objectOrRecordPattern,
    required String name,
    required covariant SharedPatternField original,
    required covariant SharedPatternField duplicate,
  }) {
    if (objectOrRecordPattern is RecordPatternImpl) {
      objectOrRecordPattern.hasDuplicateNamedField = true;
    }
    _errorReporter.reportError(
      DiagnosticFactory().duplicatePatternField(
        source: _errorReporter.source,
        name: name,
        duplicateField: duplicate.node,
        originalField: original.node,
      ),
    );
  }

  @override
  void duplicateRestPattern({
    required DartPattern mapOrListPattern,
    required covariant RestPatternElementImpl original,
    required covariant RestPatternElementImpl duplicate,
  }) {
    _errorReporter.reportError(
      DiagnosticFactory().duplicateRestElementInPattern(
        source: _errorReporter.source,
        originalElement: original,
        duplicateElement: duplicate,
      ),
    );
  }

  @override
  void emptyMapPattern({
    required DartPattern pattern,
  }) {
    _errorReporter.atNode(
      pattern,
      CompileTimeErrorCode.EMPTY_MAP_PATTERN,
    );
  }

  @override
  void inconsistentJoinedPatternVariable({
    required PromotableElement variable,
    required PromotableElement component,
  }) {
    _errorReporter.atElement(
      component,
      CompileTimeErrorCode.INCONSISTENT_PATTERN_VARIABLE_LOGICAL_OR,
      arguments: [variable.name],
    );
  }

  @override
  void matchedTypeIsStrictlyNonNullable({
    required DartPattern pattern,
    required SharedTypeView<DartType> matchedType,
  }) {
    if (pattern is NullAssertPattern) {
      _errorReporter.atToken(
        pattern.operator,
        StaticWarningCode.UNNECESSARY_NULL_ASSERT_PATTERN,
      );
    } else if (pattern is NullCheckPattern) {
      _errorReporter.atToken(
        pattern.operator,
        StaticWarningCode.UNNECESSARY_NULL_CHECK_PATTERN,
      );
    } else {
      throw UnimplementedError('(${pattern.runtimeType}) $pattern');
    }
  }

  @override
  void matchedTypeIsSubtypeOfRequired({
    required covariant CastPatternImpl pattern,
    required SharedTypeView<DartType> matchedType,
    required SharedTypeView<DartType> requiredType,
  }) {
    _errorReporter.atToken(
      pattern.asToken,
      WarningCode.UNNECESSARY_CAST_PATTERN,
    );
  }

  @override
  void nonBooleanCondition({required Expression node}) {
    _errorReporter.atNode(
      node,
      CompileTimeErrorCode.NON_BOOL_CONDITION,
    );
  }

  @override
  void patternForInExpressionIsNotIterable({
    required AstNode node,
    required Expression expression,
    required SharedTypeView<DartType> expressionType,
  }) {
    _errorReporter.atNode(
      expression,
      CompileTimeErrorCode.FOR_IN_OF_INVALID_TYPE,
      arguments: [expressionType, 'Iterable'],
    );
  }

  @override
  void patternTypeMismatchInIrrefutableContext({
    required covariant DartPatternImpl pattern,
    required AstNode context,
    required SharedTypeView<DartType> matchedType,
    required SharedTypeView<DartType> requiredType,
  }) {
    _errorReporter.atNode(
      pattern,
      CompileTimeErrorCode.PATTERN_TYPE_MISMATCH_IN_IRREFUTABLE_CONTEXT,
      arguments: [matchedType, requiredType],
    );
  }

  @override
  void refutablePatternInIrrefutableContext(
      {required AstNode pattern, required AstNode context}) {
    _errorReporter.atNode(
      pattern,
      CompileTimeErrorCode.REFUTABLE_PATTERN_IN_IRREFUTABLE_CONTEXT,
    );
  }

  @override
  void relationalPatternOperandTypeNotAssignable({
    required covariant RelationalPatternImpl pattern,
    required SharedTypeView<DartType> operandType,
    required SharedTypeView<DartType> parameterType,
  }) {
    _errorReporter.atNode(
      pattern.operand,
      CompileTimeErrorCode.RELATIONAL_PATTERN_OPERAND_TYPE_NOT_ASSIGNABLE,
      arguments: [operandType, parameterType, pattern.operator.lexeme],
    );
  }

  @override
  void relationalPatternOperatorReturnTypeNotAssignableToBool({
    required covariant RelationalPatternImpl pattern,
    required SharedTypeView<DartType> returnType,
  }) {
    _errorReporter.atToken(
      pattern.operator,
      CompileTimeErrorCode
          .RELATIONAL_PATTERN_OPERATOR_RETURN_TYPE_NOT_ASSIGNABLE_TO_BOOL,
    );
  }

  @override
  void restPatternInMap({
    required covariant MapPatternImpl node,
    required covariant RestPatternElementImpl element,
  }) {
    _errorReporter.atNode(
      element,
      CompileTimeErrorCode.REST_ELEMENT_IN_MAP_PATTERN,
    );
  }

  @override
  void switchCaseCompletesNormally(
      {required covariant SwitchStatement node, required int caseIndex}) {
    _errorReporter.atToken(
      node.members[caseIndex].keyword,
      CompileTimeErrorCode.SWITCH_CASE_COMPLETES_NORMALLY,
    );
  }

  @override
  void unnecessaryWildcardPattern({
    required covariant WildcardPatternImpl pattern,
    required UnnecessaryWildcardKind kind,
  }) {
    switch (kind) {
      case UnnecessaryWildcardKind.logicalAndPatternOperand:
        _errorReporter.atNode(
          pattern,
          WarningCode.UNNECESSARY_WILDCARD_PATTERN,
        );
    }
  }
}
