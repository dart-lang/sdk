// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart';
import 'package:kernel/ast.dart';

import '../fasta_codes.dart';
import '../kernel/internal_ast.dart';
import 'inference_helper.dart';

/// Implementation of [TypeAnalyzerErrors] that reports errors using the
/// front end's [InferenceHelper] class.
class SharedTypeAnalyzerErrors
    implements
        TypeAnalyzerErrors<Node, Statement, Expression, VariableDeclaration,
            DartType, Pattern> {
  final InferenceHelper helper;

  final Uri uriForInstrumentation;

  SharedTypeAnalyzerErrors(
      {required this.helper, required this.uriForInstrumentation});

  @override
  void argumentTypeNotAssignable({
    required Expression argument,
    required DartType argumentType,
    required DartType parameterType,
  }) {
    throw new UnimplementedError('TODO(scheglov)');
  }

  @override
  void assertInErrorRecovery() {
    // TODO(paulberry): figure out how to do this.
  }

  @override
  void caseExpressionTypeMismatch(
      {required Expression scrutinee,
      required Expression caseExpression,
      required caseExpressionType,
      required scrutineeType,
      required bool nullSafetyEnabled}) {
    helper.addProblem(
        nullSafetyEnabled
            ? templateSwitchExpressionNotSubtype.withArguments(
                caseExpressionType, scrutineeType, nullSafetyEnabled)
            : templateSwitchExpressionNotAssignable.withArguments(
                scrutineeType, caseExpressionType, nullSafetyEnabled),
        caseExpression.fileOffset,
        noLength,
        context: [
          messageSwitchExpressionNotAssignableCause.withLocation(
              uriForInstrumentation, scrutinee.fileOffset, noLength)
        ]);
  }

  @override
  void duplicateRecordPatternField({
    required String name,
    required RecordPatternField<Node, Pattern> original,
    required RecordPatternField<Node, Pattern> duplicate,
  }) {
    throw new UnimplementedError('TODO(scheglov)');
  }

  @override
  void inconsistentJoinedPatternVariable({
    required VariableDeclaration variable,
    required VariableDeclaration component,
  }) {
    // TODO(scheglov): implement logicalOrPatternInconsistentVariablePair
    throw new UnimplementedError('TODO(scheglov)');
  }

  @override
  void nonBooleanCondition(Expression node) {
    throw new UnimplementedError('TODO(paulberry)');
  }

  @override
  void patternDoesNotAllowLate(Node pattern) {
    throw new UnimplementedError('TODO(paulberry)');
  }

  @override
  void patternTypeMismatchInIrrefutableContext(
      {required Node pattern,
      required Node context,
      required DartType matchedType,
      required DartType requiredType}) {
    throw new UnimplementedError('TODO(paulberry)');
  }

  @override
  void refutablePatternInIrrefutableContext(Node pattern, Node context) {
    throw new UnimplementedError('TODO(paulberry)');
  }

  @override
  void relationalPatternOperatorReturnTypeNotAssignableToBool({
    required Node node,
    required DartType returnType,
  }) {
    throw new UnimplementedError('TODO(scheglov)');
  }

  @override
  void switchCaseCompletesNormally(
      covariant SwitchStatement node, int caseIndex, int numMergedCases) {
    helper.addProblem(messageSwitchCaseFallThrough,
        node.cases[caseIndex].fileOffset, noLength);
  }
}
