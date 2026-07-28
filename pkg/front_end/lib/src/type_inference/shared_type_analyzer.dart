// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/type_analysis_result.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart';
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:front_end/src/codes/diagnostic.dart' as diag;
import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';

import '../base/compiler_context.dart';
import '../base/messages.dart';
import '../kernel/external_ast_helper.dart' as extern;
import '../kernel/internal_ast.dart';
import '../source/check_helper.dart';
import 'inference_visitor.dart';

/// Implementation of [TypeAnalyzerErrors] that reports errors using the
/// front end's [InferenceHelper] class.
class SharedTypeAnalyzerErrors
    implements
        TypeAnalyzerErrors<
          InternalNode,
          InternalStatement,
          InternalExpression,
          InternalVariable,
          InternalPattern,
          InvalidExpression
        > {
  final InferenceVisitorImpl visitor;
  final ProblemReporting problemReporting;
  final CompilerContext compilerContext;
  final Uri uri;

  final CoreTypes coreTypes;

  new({
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
    required InternalExpression scrutinee,
    required InternalExpression caseExpression,
    required SharedTypeView caseExpressionType,
    required SharedTypeView scrutineeType,
  }) {
    return extern.createInvalidExpressionFromErrorText(
      problemReporting.buildProblem(
        compilerContext: compilerContext,
        message: diag.switchExpressionNotSubtype.withArguments(
          caseExpressionType: caseExpressionType.unwrapTypeView(),
          scrutineeType: scrutineeType.unwrapTypeView(),
        ),
        fileUri: uri,
        fileOffset: caseExpression.fileOffset,
        length: noLength,
        context: [
          diag.switchExpressionNotAssignableCause.withLocation(
            uri,
            scrutinee.fileOffset,
            noLength,
          ),
        ],
      ),
    );
  }

  @override
  InvalidExpression duplicateAssignmentPatternVariable({
    required InternalVariable variable,
    required InternalPattern original,
    required InternalPattern duplicate,
  }) {
    return extern.createInvalidExpressionFromErrorText(
      problemReporting.buildProblem(
        compilerContext: compilerContext,
        message: diag.duplicatePatternAssignmentVariable.withArguments(
          variableName: variable.cosmeticName!,
        ),
        fileUri: uri,
        fileOffset: duplicate.fileOffset,
        length: noLength,
        context: [
          diag.duplicatePatternAssignmentVariableContext.withLocation(
            uri,
            original.fileOffset,
            noLength,
          ),
        ],
      ),
    );
  }

  @override
  InvalidExpression duplicateRecordPatternField({
    required InternalPattern objectOrRecordPattern,
    required String name,
    required RecordPatternField<InternalNode, InternalPattern> original,
    required RecordPatternField<InternalNode, InternalPattern> duplicate,
  }) {
    return extern.createInvalidExpressionFromErrorText(
      problemReporting.buildProblem(
        compilerContext: compilerContext,
        message: diag.duplicateRecordPatternField.withArguments(
          fieldName: name,
        ),
        fileUri: uri,
        fileOffset: duplicate.pattern.fileOffset,
        length: noLength,
        context: [
          diag.duplicateRecordPatternFieldContext.withLocation(
            uri,
            original.pattern.fileOffset,
            noLength,
          ),
        ],
      ),
    );
  }

  @override
  InvalidExpression duplicateRestPattern({
    required InternalPattern mapOrListPattern,
    required InternalNode original,
    required InternalNode duplicate,
  }) {
    return extern.createInvalidExpressionFromErrorText(
      problemReporting.buildProblem(
        compilerContext: compilerContext,
        message: diag.duplicateRestElementInPattern,
        fileUri: uri,
        fileOffset: duplicate.fileOffset,
        length: noLength,
        context: [
          diag.duplicateRestElementInPatternContext.withLocation(
            uri,
            original.fileOffset,
            noLength,
          ),
        ],
      ),
    );
  }

  @override
  InvalidExpression emptyMapPattern({required InternalPattern pattern}) {
    return extern.createInvalidExpressionFromErrorText(
      problemReporting.buildProblem(
        compilerContext: compilerContext,
        message: diag.emptyMapPattern,
        fileUri: uri,
        fileOffset: pattern.fileOffset,
        length: noLength,
      ),
    );
  }

  @override
  void inconsistentJoinedPatternVariable({
    required InternalVariable variable,
    required InternalVariable component,
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
    required InternalPattern pattern,
    required SharedTypeView matchedType,
  }) {
    // These are only warnings, so we don't report anything.
    return null;
  }

  @override
  void matchedTypeIsSubtypeOfRequired({
    required InternalPattern pattern,
    required SharedTypeView matchedType,
    required SharedTypeView requiredType,
  }) {
    // TODO(scheglov) implement
  }

  @override
  InvalidExpression nonBooleanCondition({required InternalExpression node}) {
    return extern.createInvalidExpressionFromErrorText(
      problemReporting.buildProblem(
        compilerContext: compilerContext,
        message: diag.nonBoolCondition,
        fileUri: uri,
        fileOffset: node.fileOffset,
        length: noLength,
      ),
    );
  }

  @override
  InvalidExpression patternForInExpressionIsNotIterable({
    required InternalNode node,
    required InternalExpression expression,
    required SharedTypeView expressionType,
  }) {
    return extern.createInvalidExpressionFromErrorText(
      problemReporting.buildProblem(
        compilerContext: compilerContext,
        message: diag.forInLoopTypeNotIterable.withArguments(
          actualType: expressionType.unwrapTypeView(),
          expectedType: coreTypes.iterableNonNullableRawType,
        ),
        fileUri: uri,
        fileOffset: expression.fileOffset,
        length: noLength,
      ),
    );
  }

  @override
  InvalidExpression patternTypeMismatchInIrrefutableContext({
    required InternalPattern pattern,
    required InternalNode context,
    required SharedTypeView matchedType,
    required SharedTypeView requiredType,
  }) {
    return extern.createInvalidExpressionFromErrorText(
      problemReporting.buildProblem(
        compilerContext: compilerContext,
        message: diag.patternTypeMismatchInIrrefutableContext.withArguments(
          actualType: matchedType.unwrapTypeView(),
          expectedType: requiredType.unwrapTypeView(),
        ),
        fileUri: uri,
        fileOffset: pattern.fileOffset,
        length: noLength,
      ),
    );
  }

  @override
  InvalidExpression refutablePatternInIrrefutableContext({
    required covariant InternalPattern pattern,
    required InternalNode context,
  }) {
    return extern.createInvalidExpressionFromErrorText(
      problemReporting.buildProblem(
        compilerContext: compilerContext,
        message: diag.refutablePatternInIrrefutableContext,
        fileUri: uri,
        fileOffset: pattern.fileOffset,
        length: noLength,
      ),
    );
  }

  @override
  InvalidExpression relationalPatternOperandTypeNotAssignable({
    required covariant InternalRelationalPattern pattern,
    required SharedTypeView operandType,
    required SharedTypeView parameterType,
  }) {
    return extern.createInvalidExpressionFromErrorText(
      problemReporting.buildProblem(
        compilerContext: compilerContext,
        message: diag.argumentTypeNotAssignable.withArguments(
          actualType: operandType.unwrapTypeView(),
          expectedType: parameterType.unwrapTypeView(),
        ),
        fileUri: uri,
        fileOffset: pattern.expression.fileOffset,
        length: noLength,
      ),
    );
  }

  @override
  InvalidExpression relationalPatternOperatorReturnTypeNotAssignableToBool({
    required InternalPattern pattern,
    required SharedTypeView returnType,
  }) {
    return extern.createInvalidExpressionFromErrorText(
      problemReporting.buildProblem(
        compilerContext: compilerContext,
        message: diag.invalidAssignmentError.withArguments(
          actualType: returnType.unwrapTypeView(),
          expectedType: coreTypes.boolNonNullableRawType,
        ),
        fileUri: uri,
        fileOffset: pattern.fileOffset,
        length: noLength,
      ),
    );
  }

  @override
  InvalidExpression restPatternInMap({
    required InternalPattern node,
    required InternalNode element,
  }) {
    return extern.createInvalidExpressionFromErrorText(
      problemReporting.buildProblem(
        compilerContext: compilerContext,
        message: diag.restPatternInMapPattern,
        fileUri: uri,
        fileOffset: element.fileOffset,
        length: noLength,
      ),
    );
  }

  @override
  InvalidExpression switchCaseCompletesNormally({
    required covariant InternalSwitchStatement node,
    required int caseIndex,
  }) {
    return extern.createInvalidExpressionFromErrorText(
      problemReporting.buildProblem(
        compilerContext: compilerContext,
        message: diag.switchCaseFallThrough,
        fileUri: uri,
        fileOffset: node.cases[caseIndex].fileOffset,
        length: noLength,
      ),
    );
  }

  @override
  void unnecessaryWildcardPattern({
    required InternalPattern pattern,
    required UnnecessaryWildcardKind kind,
  }) {
    // TODO(scheglov): implement unnecessaryWildcardPattern
  }
}
