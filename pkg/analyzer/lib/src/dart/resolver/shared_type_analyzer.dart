// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/type_analysis_result.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart'
    as shared;
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/diagnostic/diagnostic_factory.dart';
import 'package:analyzer/src/error/codes.dart';

typedef SharedPatternField =
    shared.RecordPatternField<PatternFieldImpl, DartPatternImpl>;

/// Implementation of [shared.TypeAnalyzerErrors] that reports errors using the
/// analyzer's [DiagnosticReporter] class.
class SharedTypeAnalyzerErrors
    implements
        shared.TypeAnalyzerErrors<
          AstNodeImpl,
          StatementImpl,
          ExpressionImpl,
          PromotableElementImpl2,
          SharedTypeView,
          DartPatternImpl,
          void
        > {
  final DiagnosticReporter _diagnosticReporter;

  SharedTypeAnalyzerErrors(this._diagnosticReporter);

  @override
  void assertInErrorRecovery() {}

  @override
  void caseExpressionTypeMismatch({
    required Expression scrutinee,
    required Expression caseExpression,
    required SharedTypeView scrutineeType,
    required SharedTypeView caseExpressionType,
  }) {
    _diagnosticReporter.atNode(
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
    _diagnosticReporter.reportError(
      DiagnosticFactory().duplicateAssignmentPatternVariable(
        source: _diagnosticReporter.source,
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
    _diagnosticReporter.reportError(
      DiagnosticFactory().duplicatePatternField(
        source: _diagnosticReporter.source,
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
    _diagnosticReporter.reportError(
      DiagnosticFactory().duplicateRestElementInPattern(
        source: _diagnosticReporter.source,
        originalElement: original,
        duplicateElement: duplicate,
      ),
    );
  }

  @override
  void emptyMapPattern({required DartPattern pattern}) {
    _diagnosticReporter.atNode(pattern, CompileTimeErrorCode.EMPTY_MAP_PATTERN);
  }

  @override
  void inconsistentJoinedPatternVariable({
    required PromotableElement variable,
    required PromotableElement component,
  }) {
    _diagnosticReporter.atElement2(
      component,
      CompileTimeErrorCode.INCONSISTENT_PATTERN_VARIABLE_LOGICAL_OR,
      arguments: [variable.name3!],
    );
  }

  @override
  void matchedTypeIsStrictlyNonNullable({
    required DartPattern pattern,
    required SharedTypeView matchedType,
  }) {
    if (pattern is NullAssertPattern) {
      _diagnosticReporter.atToken(
        pattern.operator,
        StaticWarningCode.UNNECESSARY_NULL_ASSERT_PATTERN,
      );
    } else if (pattern is NullCheckPattern) {
      _diagnosticReporter.atToken(
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
    required SharedTypeView matchedType,
    required SharedTypeView requiredType,
  }) {
    _diagnosticReporter.atToken(
      pattern.asToken,
      WarningCode.UNNECESSARY_CAST_PATTERN,
    );
  }

  @override
  void nonBooleanCondition({required Expression node}) {
    _diagnosticReporter.atNode(node, CompileTimeErrorCode.NON_BOOL_CONDITION);
  }

  @override
  void patternForInExpressionIsNotIterable({
    required AstNode node,
    required Expression expression,
    required SharedTypeView expressionType,
  }) {
    _diagnosticReporter.atNode(
      expression,
      CompileTimeErrorCode.FOR_IN_OF_INVALID_TYPE,
      arguments: [expressionType, 'Iterable'],
    );
  }

  @override
  void patternTypeMismatchInIrrefutableContext({
    required covariant DartPatternImpl pattern,
    required AstNode context,
    required SharedTypeView matchedType,
    required SharedTypeView requiredType,
  }) {
    _diagnosticReporter.atNode(
      pattern,
      CompileTimeErrorCode.PATTERN_TYPE_MISMATCH_IN_IRREFUTABLE_CONTEXT,
      arguments: [matchedType, requiredType],
    );
  }

  @override
  void refutablePatternInIrrefutableContext({
    required AstNode pattern,
    required AstNode context,
  }) {
    _diagnosticReporter.atNode(
      pattern,
      CompileTimeErrorCode.REFUTABLE_PATTERN_IN_IRREFUTABLE_CONTEXT,
    );
  }

  @override
  void relationalPatternOperandTypeNotAssignable({
    required covariant RelationalPatternImpl pattern,
    required SharedTypeView operandType,
    required SharedTypeView parameterType,
  }) {
    _diagnosticReporter.atNode(
      pattern.operand,
      CompileTimeErrorCode.RELATIONAL_PATTERN_OPERAND_TYPE_NOT_ASSIGNABLE,
      arguments: [operandType, parameterType, pattern.operator.lexeme],
    );
  }

  @override
  void relationalPatternOperatorReturnTypeNotAssignableToBool({
    required covariant RelationalPatternImpl pattern,
    required SharedTypeView returnType,
  }) {
    _diagnosticReporter.atToken(
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
    _diagnosticReporter.atNode(
      element,
      CompileTimeErrorCode.REST_ELEMENT_IN_MAP_PATTERN,
    );
  }

  @override
  void switchCaseCompletesNormally({
    required covariant SwitchStatementImpl node,
    required int caseIndex,
  }) {
    _diagnosticReporter.atToken(
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
        _diagnosticReporter.atNode(
          pattern,
          WarningCode.UNNECESSARY_WILDCARD_PATTERN,
        );
    }
  }
}
