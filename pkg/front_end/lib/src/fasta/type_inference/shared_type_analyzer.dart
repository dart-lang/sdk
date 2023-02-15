// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:_fe_analyzer_shared/src/type_inference/type_analysis_result.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart';
import 'package:front_end/src/fasta/type_inference/inference_visitor.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';

import '../fasta_codes.dart';
import '../kernel/internal_ast.dart';
import 'inference_helper.dart';

/// Implementation of [TypeAnalyzerErrors] that reports errors using the
/// front end's [InferenceHelper] class.
class SharedTypeAnalyzerErrors
    implements
        TypeAnalyzerErrors<TreeNode, Statement, Expression, VariableDeclaration,
            DartType, Pattern> {
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
  void argumentTypeNotAssignable({
    required Expression argument,
    required DartType argumentType,
    required DartType parameterType,
  }) {
    helper.addProblem(
        templateArgumentTypeNotAssignable.withArguments(
            argumentType, parameterType, isNonNullableByDefault),
        argument.fileOffset,
        noLength);
  }

  @override
  void assertInErrorRecovery() {
    // TODO(paulberry): figure out how to do this.
  }

  @override
  void caseExpressionTypeMismatch(
      {required Expression scrutinee,
      required Expression caseExpression,
      required DartType caseExpressionType,
      required DartType scrutineeType,
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
              uri, scrutinee.fileOffset, noLength)
        ]);
  }

  @override
  void duplicateAssignmentPatternVariable({
    required VariableDeclaration variable,
    required Pattern original,
    required Pattern duplicate,
  }) {
    duplicate.error = helper.buildProblem(
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
  void duplicateRecordPatternField({
    required Pattern objectOrRecordPattern,
    required String name,
    required RecordPatternField<TreeNode, Pattern> original,
    required RecordPatternField<TreeNode, Pattern> duplicate,
  }) {
    objectOrRecordPattern.error = helper.buildProblem(
        templateDuplicateRecordPatternField.withArguments(name),
        duplicate.pattern.fileOffset,
        noLength,
        context: [
          messageDuplicateRecordPatternFieldContext.withLocation(
              uri, original.pattern.fileOffset, noLength)
        ]);
  }

  @override
  void duplicateRestPattern({
    required Pattern mapOrListPattern,
    required TreeNode original,
    required TreeNode duplicate,
  }) {
    mapOrListPattern.error = helper.buildProblem(
        messageDuplicateRestElementInPattern, duplicate.fileOffset, noLength,
        context: [
          messageDuplicateRestElementInPatternContext.withLocation(
              uri, original.fileOffset, noLength)
        ]);
  }

  @override
  void inconsistentJoinedPatternVariable({
    required VariableDeclaration variable,
    required VariableDeclaration component,
  }) {
    // TODO(cstefantsova): Currently this error is reported elsewhere due to
    // the order the types are inferred.
  }

  @override
  void matchedTypeIsStrictlyNonNullable({
    required Pattern pattern,
    required DartType matchedType,
  }) {
    // These are only warnings, so we don't update `pattern.error`.
    if (pattern is NullAssertPattern) {
      helper.addProblem(
          messageUnnecessaryNullAssertPattern, pattern.fileOffset, noLength);
    } else {
      helper.addProblem(
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
  void nonBooleanCondition({required Expression node}) {
    // TODO(johnniwinther): Find a way to propagate the error state to the
    // parent of the guard.
    helper.addProblem(messageNonBoolCondition, node.fileOffset, noLength);
  }

  @override
  void patternDoesNotAllowLate({required TreeNode pattern}) {
    // TODO(johnniwinther): Is late even supported by the grammar or parser?
    throw new UnimplementedError('TODO(paulberry)');
  }

  @override
  void patternForInExpressionIsNotIterable({
    required TreeNode node,
    required Expression expression,
    required DartType expressionType,
  }) {
    throw new UnimplementedError('TODO(scheglov)');
  }

  @override
  void patternTypeMismatchInIrrefutableContext(
      {required Pattern pattern,
      required TreeNode context,
      required DartType matchedType,
      required DartType requiredType}) {
    pattern.error = helper.buildProblem(
        templatePatternTypeMismatchInIrrefutableContext.withArguments(
            matchedType, requiredType, isNonNullableByDefault),
        pattern.fileOffset,
        noLength);
  }

  @override
  void refutablePatternInIrrefutableContext(
      {required covariant Pattern pattern, required TreeNode context}) {
    pattern.error = helper.buildProblem(
        messageRefutablePatternInIrrefutableContext,
        pattern.fileOffset,
        noLength);
  }

  @override
  void relationalPatternOperatorReturnTypeNotAssignableToBool({
    required Pattern pattern,
    required DartType returnType,
  }) {
    pattern.error = helper.buildProblem(
        templateInvalidAssignmentError.withArguments(returnType,
            coreTypes.boolNonNullableRawType, isNonNullableByDefault),
        pattern.fileOffset,
        noLength);
  }

  @override
  void restPatternNotLastInMap(
      {required Pattern node, required TreeNode element}) {
    // This is reported in the body builder.
  }

  @override
  void restPatternWithSubPatternInMap(
      {required Pattern node, required TreeNode element}) {
    // This is reported in the body builder.
  }

  @override
  void switchCaseCompletesNormally(
      {required covariant SwitchStatement node, required int caseIndex}) {
    helper.addProblem(messageSwitchCaseFallThrough,
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
