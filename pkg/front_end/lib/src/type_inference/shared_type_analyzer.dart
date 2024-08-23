// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/type_analysis_result.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart';
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';

import '../codes/cfe_codes.dart';
import '../source/source_loader.dart';
import 'inference_helper.dart';
import 'inference_visitor.dart';

/// Implementation of [TypeAnalyzerErrors] that reports errors using the
/// front end's [InferenceHelper] class.
class SharedTypeAnalyzerErrors
    implements
        TypeAnalyzerErrors<TreeNode, Statement, Expression, VariableDeclaration,
            SharedTypeView<DartType>, Pattern, InvalidExpression> {
  final InferenceVisitorImpl visitor;
  final InferenceHelper helper;

  final Uri uri;

  final CoreTypes coreTypes;

  SharedTypeAnalyzerErrors(
      {required this.visitor,
      required this.helper,
      required this.uri,
      required this.coreTypes});

  @override
  void assertInErrorRecovery() {
    // TODO(paulberry): figure out how to do this.
  }

  @override
  InvalidExpression caseExpressionTypeMismatch(
      {required Expression scrutinee,
      required Expression caseExpression,
      required SharedTypeView<DartType> caseExpressionType,
      required SharedTypeView<DartType> scrutineeType,
      required bool nullSafetyEnabled}) {
    return helper.buildProblem(
        nullSafetyEnabled
            ? templateSwitchExpressionNotSubtype.withArguments(
                caseExpressionType.unwrapTypeView(),
                scrutineeType.unwrapTypeView())
            :
            // Coverage-ignore(suite): Not run.
            templateSwitchExpressionNotAssignable.withArguments(
                scrutineeType.unwrapTypeView(),
                caseExpressionType.unwrapTypeView()),
        caseExpression.fileOffset,
        noLength,
        context: [
          messageSwitchExpressionNotAssignableCause.withLocation(
              uri, scrutinee.fileOffset, noLength)
        ]);
  }

  @override
  InvalidExpression duplicateAssignmentPatternVariable({
    required VariableDeclaration variable,
    required Pattern original,
    required Pattern duplicate,
  }) {
    return helper.buildProblem(
        templateDuplicatePatternAssignmentVariable
            .withArguments(variable.name!),
        duplicate.fileOffset,
        noLength,
        context: [
          messageDuplicatePatternAssignmentVariableContext.withLocation(
              uri, original.fileOffset, noLength)
        ]);
  }

  @override
  InvalidExpression duplicateRecordPatternField({
    required Pattern objectOrRecordPattern,
    required String name,
    required RecordPatternField<TreeNode, Pattern> original,
    required RecordPatternField<TreeNode, Pattern> duplicate,
  }) {
    return helper.buildProblem(
        templateDuplicateRecordPatternField.withArguments(name),
        duplicate.pattern.fileOffset,
        noLength,
        context: [
          messageDuplicateRecordPatternFieldContext.withLocation(
              uri, original.pattern.fileOffset, noLength)
        ]);
  }

  @override
  InvalidExpression duplicateRestPattern({
    required Pattern mapOrListPattern,
    required TreeNode original,
    required TreeNode duplicate,
  }) {
    return helper.buildProblem(
        messageDuplicateRestElementInPattern, duplicate.fileOffset, noLength,
        context: [
          messageDuplicateRestElementInPatternContext.withLocation(
              uri, original.fileOffset, noLength)
        ]);
  }

  @override
  InvalidExpression emptyMapPattern({
    required Pattern pattern,
  }) {
    return helper.buildProblem(
        messageEmptyMapPattern, pattern.fileOffset, noLength);
  }

  @override
  void inconsistentJoinedPatternVariable({
    required VariableDeclaration variable,
    required VariableDeclaration component,
  }) {
    // TODO(johnniwinther): How should we handle errors that are not report
    // here? Should we have a sentinel error node, allow a nullable result, or ?
    assert(visitor.libraryBuilder.loader.assertProblemReportedElsewhere(
        "SharedTypeAnalyzerErrors.inconsistentJoinedPatternVariable",
        expectedPhase: CompilationPhaseForProblemReporting.bodyBuilding));
  }

  @override
  InvalidExpression? matchedTypeIsStrictlyNonNullable({
    required Pattern pattern,
    required SharedTypeView<DartType> matchedType,
  }) {
    // These are only warnings, so we don't report anything.
    return null;
  }

  @override
  void matchedTypeIsSubtypeOfRequired({
    required Pattern pattern,
    required SharedTypeView<DartType> matchedType,
    required SharedTypeView<DartType> requiredType,
  }) {
    // TODO(scheglov) implement
  }

  @override
  InvalidExpression nonBooleanCondition({required Expression node}) {
    return helper.buildProblem(
        messageNonBoolCondition, node.fileOffset, noLength);
  }

  @override
  InvalidExpression patternForInExpressionIsNotIterable({
    required TreeNode node,
    required Expression expression,
    required SharedTypeView<DartType> expressionType,
  }) {
    return helper.buildProblem(
        templateForInLoopTypeNotIterable.withArguments(
            expressionType.unwrapTypeView(),
            coreTypes.iterableNonNullableRawType),
        expression.fileOffset,
        noLength);
  }

  @override
  InvalidExpression patternTypeMismatchInIrrefutableContext(
      {required Pattern pattern,
      required TreeNode context,
      required SharedTypeView<DartType> matchedType,
      required SharedTypeView<DartType> requiredType}) {
    return helper.buildProblem(
        templatePatternTypeMismatchInIrrefutableContext.withArguments(
            matchedType.unwrapTypeView(), requiredType.unwrapTypeView()),
        pattern.fileOffset,
        noLength);
  }

  @override
  InvalidExpression refutablePatternInIrrefutableContext(
      {required covariant Pattern pattern, required TreeNode context}) {
    return helper.buildProblem(messageRefutablePatternInIrrefutableContext,
        pattern.fileOffset, noLength);
  }

  @override
  InvalidExpression relationalPatternOperandTypeNotAssignable({
    required covariant RelationalPattern pattern,
    required SharedTypeView<DartType> operandType,
    required SharedTypeView<DartType> parameterType,
  }) {
    return helper.buildProblem(
        templateArgumentTypeNotAssignable.withArguments(
            operandType.unwrapTypeView(), parameterType.unwrapTypeView()),
        pattern.expression.fileOffset,
        noLength);
  }

  @override
  InvalidExpression relationalPatternOperatorReturnTypeNotAssignableToBool({
    required Pattern pattern,
    required SharedTypeView<DartType> returnType,
  }) {
    return helper.buildProblem(
        templateInvalidAssignmentError.withArguments(
            returnType.unwrapTypeView(), coreTypes.boolNonNullableRawType),
        pattern.fileOffset,
        noLength);
  }

  @override
  InvalidExpression restPatternInMap({
    required Pattern node,
    required TreeNode element,
  }) {
    return helper.buildProblem(
        messageRestPatternInMapPattern, element.fileOffset, noLength);
  }

  @override
  InvalidExpression switchCaseCompletesNormally(
      {required covariant SwitchStatement node, required int caseIndex}) {
    return helper.buildProblem(messageSwitchCaseFallThrough,
        node.cases[caseIndex].fileOffset, noLength);
  }

  @override
  void unnecessaryWildcardPattern({
    required Pattern pattern,
    required UnnecessaryWildcardKind kind,
  }) {
    // TODO(scheglov): implement unnecessaryWildcardPattern
  }
}
