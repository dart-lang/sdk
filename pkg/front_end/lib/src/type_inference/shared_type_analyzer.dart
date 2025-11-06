// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/type_analysis_result.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart';
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';

import '../base/compiler_context.dart';
import '../base/messages.dart';
import '../source/check_helper.dart';
import 'inference_visitor.dart';

/// Implementation of [TypeAnalyzerErrors] that reports errors using the
/// front end's [InferenceHelper] class.
class SharedTypeAnalyzerErrors
    implements
        TypeAnalyzerErrors<
          TreeNode,
          Statement,
          Expression,
          VariableDeclaration,
          SharedTypeView,
          Pattern,
          InvalidExpression
        > {
  final InferenceVisitorImpl visitor;
  final ProblemReporting problemReporting;
  final CompilerContext compilerContext;
  final Uri uri;

  final CoreTypes coreTypes;

  SharedTypeAnalyzerErrors({
    required this.visitor,
    required this.problemReporting,
    required this.compilerContext,
    required this.uri,
    required this.coreTypes,
  });

  @override
  void assertInErrorRecovery() {
    // TODO(paulberry): figure out how to do this.
  }

  @override
  InvalidExpression caseExpressionTypeMismatch({
    required Expression scrutinee,
    required Expression caseExpression,
    required SharedTypeView caseExpressionType,
    required SharedTypeView scrutineeType,
  }) {
    return problemReporting.buildProblem(
      compilerContext: compilerContext,
      message: codeSwitchExpressionNotSubtype.withArgumentsOld(
        caseExpressionType.unwrapTypeView(),
        scrutineeType.unwrapTypeView(),
      ),
      fileUri: uri,
      fileOffset: caseExpression.fileOffset,
      length: noLength,
      context: [
        codeSwitchExpressionNotAssignableCause.withLocation(
          uri,
          scrutinee.fileOffset,
          noLength,
        ),
      ],
    );
  }

  @override
  InvalidExpression duplicateAssignmentPatternVariable({
    required VariableDeclaration variable,
    required Pattern original,
    required Pattern duplicate,
  }) {
    return problemReporting.buildProblem(
      compilerContext: compilerContext,
      message: codeDuplicatePatternAssignmentVariable.withArgumentsOld(
        variable.name!,
      ),
      fileUri: uri,
      fileOffset: duplicate.fileOffset,
      length: noLength,
      context: [
        codeDuplicatePatternAssignmentVariableContext.withLocation(
          uri,
          original.fileOffset,
          noLength,
        ),
      ],
    );
  }

  @override
  InvalidExpression duplicateRecordPatternField({
    required Pattern objectOrRecordPattern,
    required String name,
    required RecordPatternField<TreeNode, Pattern> original,
    required RecordPatternField<TreeNode, Pattern> duplicate,
  }) {
    return problemReporting.buildProblem(
      compilerContext: compilerContext,
      message: codeDuplicateRecordPatternField.withArgumentsOld(name),
      fileUri: uri,
      fileOffset: duplicate.pattern.fileOffset,
      length: noLength,
      context: [
        codeDuplicateRecordPatternFieldContext.withLocation(
          uri,
          original.pattern.fileOffset,
          noLength,
        ),
      ],
    );
  }

  @override
  InvalidExpression duplicateRestPattern({
    required Pattern mapOrListPattern,
    required TreeNode original,
    required TreeNode duplicate,
  }) {
    return problemReporting.buildProblem(
      compilerContext: compilerContext,
      message: codeDuplicateRestElementInPattern,
      fileUri: uri,
      fileOffset: duplicate.fileOffset,
      length: noLength,
      context: [
        codeDuplicateRestElementInPatternContext.withLocation(
          uri,
          original.fileOffset,
          noLength,
        ),
      ],
    );
  }

  @override
  InvalidExpression emptyMapPattern({required Pattern pattern}) {
    return problemReporting.buildProblem(
      compilerContext: compilerContext,
      message: codeEmptyMapPattern,
      fileUri: uri,
      fileOffset: pattern.fileOffset,
      length: noLength,
    );
  }

  @override
  void inconsistentJoinedPatternVariable({
    required VariableDeclaration variable,
    required VariableDeclaration component,
  }) {
    // TODO(johnniwinther): How should we handle errors that are not report
    // here? Should we have a sentinel error node, allow a nullable result, or ?
    assert(
      visitor.libraryBuilder.loader.assertProblemReportedElsewhere(
        "SharedTypeAnalyzerErrors.inconsistentJoinedPatternVariable",
        expectedPhase: CompilationPhaseForProblemReporting.bodyBuilding,
      ),
    );
  }

  @override
  InvalidExpression? matchedTypeIsStrictlyNonNullable({
    required Pattern pattern,
    required SharedTypeView matchedType,
  }) {
    // These are only warnings, so we don't report anything.
    return null;
  }

  @override
  void matchedTypeIsSubtypeOfRequired({
    required Pattern pattern,
    required SharedTypeView matchedType,
    required SharedTypeView requiredType,
  }) {
    // TODO(scheglov) implement
  }

  @override
  InvalidExpression nonBooleanCondition({required Expression node}) {
    return problemReporting.buildProblem(
      compilerContext: compilerContext,
      message: codeNonBoolCondition,
      fileUri: uri,
      fileOffset: node.fileOffset,
      length: noLength,
    );
  }

  @override
  InvalidExpression patternForInExpressionIsNotIterable({
    required TreeNode node,
    required Expression expression,
    required SharedTypeView expressionType,
  }) {
    return problemReporting.buildProblem(
      compilerContext: compilerContext,
      message: codeForInLoopTypeNotIterable.withArgumentsOld(
        expressionType.unwrapTypeView(),
        coreTypes.iterableNonNullableRawType,
      ),
      fileUri: uri,
      fileOffset: expression.fileOffset,
      length: noLength,
    );
  }

  @override
  InvalidExpression patternTypeMismatchInIrrefutableContext({
    required Pattern pattern,
    required TreeNode context,
    required SharedTypeView matchedType,
    required SharedTypeView requiredType,
  }) {
    return problemReporting.buildProblem(
      compilerContext: compilerContext,
      message: codePatternTypeMismatchInIrrefutableContext.withArgumentsOld(
        matchedType.unwrapTypeView(),
        requiredType.unwrapTypeView(),
      ),
      fileUri: uri,
      fileOffset: pattern.fileOffset,
      length: noLength,
    );
  }

  @override
  InvalidExpression refutablePatternInIrrefutableContext({
    required covariant Pattern pattern,
    required TreeNode context,
  }) {
    return problemReporting.buildProblem(
      compilerContext: compilerContext,
      message: codeRefutablePatternInIrrefutableContext,
      fileUri: uri,
      fileOffset: pattern.fileOffset,
      length: noLength,
    );
  }

  @override
  InvalidExpression relationalPatternOperandTypeNotAssignable({
    required covariant RelationalPattern pattern,
    required SharedTypeView operandType,
    required SharedTypeView parameterType,
  }) {
    return problemReporting.buildProblem(
      compilerContext: compilerContext,
      message: codeArgumentTypeNotAssignable.withArgumentsOld(
        operandType.unwrapTypeView(),
        parameterType.unwrapTypeView(),
      ),
      fileUri: uri,
      fileOffset: pattern.expression.fileOffset,
      length: noLength,
    );
  }

  @override
  InvalidExpression relationalPatternOperatorReturnTypeNotAssignableToBool({
    required Pattern pattern,
    required SharedTypeView returnType,
  }) {
    return problemReporting.buildProblem(
      compilerContext: compilerContext,
      message: codeInvalidAssignmentError.withArgumentsOld(
        returnType.unwrapTypeView(),
        coreTypes.boolNonNullableRawType,
      ),
      fileUri: uri,
      fileOffset: pattern.fileOffset,
      length: noLength,
    );
  }

  @override
  InvalidExpression restPatternInMap({
    required Pattern node,
    required TreeNode element,
  }) {
    return problemReporting.buildProblem(
      compilerContext: compilerContext,
      message: codeRestPatternInMapPattern,
      fileUri: uri,
      fileOffset: element.fileOffset,
      length: noLength,
    );
  }

  @override
  InvalidExpression switchCaseCompletesNormally({
    required covariant SwitchStatement node,
    required int caseIndex,
  }) {
    return problemReporting.buildProblem(
      compilerContext: compilerContext,
      message: codeSwitchCaseFallThrough,
      fileUri: uri,
      fileOffset: node.cases[caseIndex].fileOffset,
      length: noLength,
    );
  }

  @override
  void unnecessaryWildcardPattern({
    required Pattern pattern,
    required UnnecessaryWildcardKind kind,
  }) {
    // TODO(scheglov): implement unnecessaryWildcardPattern
  }
}
