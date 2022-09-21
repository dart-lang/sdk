// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:collection/collection.dart';

/// Implementation of [TypeAnalyzerErrors] that reports errors using the
/// analyzer's [ErrorReporter] class.
class SharedTypeAnalyzerErrors
    implements
        TypeAnalyzerErrors<AstNode, Statement, Expression, PromotableElement,
            DartType> {
  final ErrorReporter _errorReporter;

  SharedTypeAnalyzerErrors(this._errorReporter);

  @override
  void assertInErrorRecovery() {
    throw UnimplementedError('TODO(paulberry)');
  }

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
  void inconsistentMatchVar(
      {required AstNode pattern,
      required DartType type,
      required AstNode previousPattern,
      required DartType previousType}) {
    throw UnimplementedError('TODO(paulberry)');
  }

  @override
  void inconsistentMatchVarExplicitness(
      {required AstNode pattern, required AstNode previousPattern}) {
    throw UnimplementedError('TODO(paulberry)');
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
  void patternTypeMismatchInIrrefutableContext(
      {required AstNode pattern,
      required AstNode context,
      required DartType matchedType,
      required DartType requiredType}) {
    throw UnimplementedError('TODO(paulberry)');
  }

  @override
  void refutablePatternInIrrefutableContext(AstNode pattern, AstNode context) {
    throw UnimplementedError('TODO(paulberry)');
  }

  @override
  void switchCaseCompletesNormally(
      covariant SwitchStatement node, int caseIndex, int numHeads) {
    _errorReporter.reportErrorForToken(
        CompileTimeErrorCode.SWITCH_CASE_COMPLETES_NORMALLY,
        node.members[caseIndex + numHeads - 1].keyword);
  }
}
