// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/type_analysis_result.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart';
import 'package:front_end/src/fasta/type_inference/inference_visitor.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';

import '../fasta_codes.dart';
import 'inference_helper.dart';

/// Implementation of [TypeAnalyzerErrors] that reports errors using the
/// front end's [InferenceHelper] class.
class SharedTypeAnalyzerErrors
    implements
        TypeAnalyzerErrors<TreeNode, Statement, Expression, VariableDeclaration,
            DartType, Pattern, InvalidExpression> {
  final InferenceVisitorImpl visitor;
  final InferenceHelper helper;

  final Uri uri;

  final CoreTypes coreTypes;

  final bool isNonNullableByDefault;

  SharedTypeAnalyzerErrors(
      {required this.visitor,
      required this.helper,
      required this.uri,
      required this.coreTypes,
      required this.isNonNullableByDefault});

  @override
  void assertInErrorRecovery() {
    // TODO(paulberry): figure out how to do this.
  }

  @override
  InvalidExpression caseExpressionTypeMismatch(
      {required Expression scrutinee,
      required Expression caseExpression,
      required DartType caseExpressionType,
      required DartType scrutineeType,
      required bool nullSafetyEnabled}) {
    return helper.buildProblem(
        nullSafetyEnabled
            ? templateSwitchExpressionNotSubtype.withArguments(
                caseExpressionType, scrutineeType, nullSafetyEnabled)
            : templateSwitchExpressionNotAssignable.withArguments(
                scrutineeType, caseExpressionType, nullSafetyEnabled),
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
    // TODO(cstefantsova): Currently this error is reported elsewhere due to
    // the order the types are inferred.
    // TODO(johnniwinther): How should we handle errors that are not report
    // here? Should we have a sentinel error node, allow a nullable result, or ?
  }

  @override
  InvalidExpression matchedTypeIsStrictlyNonNullable({
    required Pattern pattern,
    required DartType matchedType,
  }) {
    // These are only warnings, so we don't update `pattern.error`.
    if (pattern is NullAssertPattern) {
      return helper.buildProblem(
          messageUnnecessaryNullAssertPattern, pattern.fileOffset, noLength);
    } else {
      return helper.buildProblem(
          messageUnnecessaryNullCheckPattern, pattern.fileOffset, noLength);
    }
  }

  @override
  void matchedTypeIsSubtypeOfRequired({
    required Pattern pattern,
    required DartType matchedType,
    required DartType requiredType,
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
    required DartType expressionType,
  }) {
    return helper.buildProblem(
        templateForInLoopTypeNotIterable.withArguments(expressionType,
            coreTypes.iterableNonNullableRawType, isNonNullableByDefault),
        expression.fileOffset,
        noLength);
  }

  @override
  InvalidExpression patternTypeMismatchInIrrefutableContext(
      {required Pattern pattern,
      required TreeNode context,
      required DartType matchedType,
      required DartType requiredType}) {
    return helper.buildProblem(
        templatePatternTypeMismatchInIrrefutableContext.withArguments(
            matchedType, requiredType, isNonNullableByDefault),
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
    required DartType operandType,
    required DartType parameterType,
  }) {
    return helper.buildProblem(
        templateArgumentTypeNotAssignable.withArguments(
            operandType, parameterType, isNonNullableByDefault),
        pattern.expression.fileOffset,
        noLength);
  }

  @override
  InvalidExpression relationalPatternOperatorReturnTypeNotAssignableToBool({
    required Pattern pattern,
    required DartType returnType,
  }) {
    return helper.buildProblem(
        templateInvalidAssignmentError.withArguments(returnType,
            coreTypes.boolNonNullableRawType, isNonNullableByDefault),
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
