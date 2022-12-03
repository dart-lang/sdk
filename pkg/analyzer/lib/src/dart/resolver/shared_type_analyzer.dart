// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart'
    as shared;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/diagnostic/diagnostic_factory.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:collection/collection.dart';

typedef SharedRecordPatternField
    = shared.RecordPatternField<RecordPatternFieldImpl, DartPattern>;

/// Implementation of [shared.TypeAnalyzerErrors] that reports errors using the
/// analyzer's [ErrorReporter] class.
class SharedTypeAnalyzerErrors
    implements
        shared.TypeAnalyzerErrors<AstNode, Statement, Expression,
            PromotableElement, DartType, DartPattern> {
  final ErrorReporter _errorReporter;

  SharedTypeAnalyzerErrors(this._errorReporter);

  @override
  void argumentTypeNotAssignable({
    required Expression argument,
    required DartType argumentType,
    required DartType parameterType,
  }) {
    _errorReporter.reportErrorForNode(
      CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE,
      argument,
      [argumentType, parameterType],
    );
  }

  @override
  void assertInErrorRecovery() {}

  @override
  void caseExpressionTypeMismatch(
      {required Expression scrutinee,
      required Expression caseExpression,
      required scrutineeType,
      required caseExpressionType,
      required bool nullSafetyEnabled}) {
    if (nullSafetyEnabled) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode
              .CASE_EXPRESSION_TYPE_IS_NOT_SWITCH_EXPRESSION_SUBTYPE,
          caseExpression,
          [caseExpressionType, scrutineeType]);
    } else {
      // We only report the error if it occurs on the first case; otherwise
      // separate logic will report that different cases have different types.
      var switchStatement = scrutinee.parent as SwitchStatement;
      if (identical(
          switchStatement.members
              .whereType<SwitchCase>()
              .firstOrNull
              ?.expression,
          caseExpression)) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.SWITCH_EXPRESSION_NOT_ASSIGNABLE,
            scrutinee,
            [scrutineeType, caseExpressionType]);
      }
    }
  }

  @override
  void duplicateRecordPatternField({
    required String name,
    required covariant SharedRecordPatternField original,
    required covariant SharedRecordPatternField duplicate,
  }) {
    _errorReporter.reportError(
      DiagnosticFactory().duplicateRecordPatternField(
        source: _errorReporter.source,
        name: name,
        duplicateField: duplicate.node,
        originalField: original.node,
      ),
    );
  }

  @override
  void inconsistentJoinedPatternVariable({
    required PromotableElement variable,
    required PromotableElement component,
  }) {
    _errorReporter.reportErrorForElement(
      CompileTimeErrorCode.NOT_CONSISTENT_VARIABLE_PATTERN,
      component,
      [variable.name],
    );
  }

  @override
  void nonBooleanCondition(Expression node) {
    throw UnimplementedError('TODO(paulberry)');
  }

  @override
  void patternDoesNotAllowLate(AstNode pattern) {
    throw UnimplementedError('TODO(paulberry)');
  }

  @override
  void patternTypeMismatchInIrrefutableContext({
    required covariant DartPatternImpl pattern,
    required AstNode context,
    required DartType matchedType,
    required DartType requiredType,
  }) {
    _errorReporter.reportErrorForNode(
      CompileTimeErrorCode.PATTERN_TYPE_MISMATCH_IN_IRREFUTABLE_CONTEXT,
      pattern,
      [matchedType, requiredType],
    );
  }

  @override
  void refutablePatternInIrrefutableContext(AstNode pattern, AstNode context) {
    _errorReporter.reportErrorForNode(
      CompileTimeErrorCode.REFUTABLE_PATTERN_IN_IRREFUTABLE_CONTEXT,
      pattern,
    );
  }

  @override
  void relationalPatternOperatorReturnTypeNotAssignableToBool({
    required covariant RelationalPatternImpl node,
    required DartType returnType,
  }) {
    _errorReporter.reportErrorForToken(
      CompileTimeErrorCode
          .RELATIONAL_PATTERN_OPERATOR_RETURN_TYPE_NOT_ASSIGNABLE_TO_BOOL,
      node.operator,
    );
  }

  @override
  void restPatternWithSubPatternInMap(
    covariant MapPatternImpl node,
    covariant RestPatternElementImpl element,
  ) {
    _errorReporter.reportErrorForNode(
      CompileTimeErrorCode.REST_ELEMENT_WITH_SUBPATTERN_IN_MAP_PATTERN,
      element.pattern!,
    );
  }

  @override
  void switchCaseCompletesNormally(
      covariant SwitchStatement node, int caseIndex, int numHeads) {
    _errorReporter.reportErrorForToken(
        CompileTimeErrorCode.SWITCH_CASE_COMPLETES_NORMALLY,
        node.members[caseIndex + numHeads - 1].keyword);
  }
}
