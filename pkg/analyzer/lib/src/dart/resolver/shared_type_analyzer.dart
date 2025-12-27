// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/type_analysis_result.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart'
    as shared;
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/diagnostic/diagnostic_factory.dart';
import 'package:analyzer/src/error/listener.dart';

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
          PromotableElementImpl,
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
    _diagnosticReporter.report(
      diag.caseExpressionTypeIsNotSwitchExpressionSubtype
          .withArguments(
            caseExpressionType: caseExpressionType.unwrapTypeView<TypeImpl>(),
            scrutineeType: scrutineeType.unwrapTypeView<TypeImpl>(),
          )
          .at(caseExpression),
    );
  }

  @override
  void duplicateAssignmentPatternVariable({
    required covariant PromotableElementImpl variable,
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
    _diagnosticReporter.report(diag.emptyMapPattern.at(pattern));
  }

  @override
  void inconsistentJoinedPatternVariable({
    required PromotableElementImpl variable,
    required PromotableElementImpl component,
  }) {
    // Local variables are never synthetic.
    assert(identical(component.nonSynthetic, component));
    var offset = component.firstFragment.nameOffset ?? 0;
    var length = component.name?.length ?? 1;
    _diagnosticReporter.report(
      diag.inconsistentPatternVariableLogicalOr
          .withArguments(name: variable.name!)
          .atOffset(offset: offset, length: length),
    );
  }

  @override
  void matchedTypeIsStrictlyNonNullable({
    required DartPattern pattern,
    required SharedTypeView matchedType,
  }) {
    if (pattern is NullAssertPattern) {
      _diagnosticReporter.report(
        diag.unnecessaryNullAssertPattern.at(pattern.operator),
      );
    } else if (pattern is NullCheckPattern) {
      _diagnosticReporter.report(
        diag.unnecessaryNullCheckPattern.at(pattern.operator),
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
    _diagnosticReporter.report(diag.unnecessaryCastPattern.at(pattern.asToken));
  }

  @override
  void nonBooleanCondition({required Expression node}) {
    _diagnosticReporter.report(diag.nonBoolCondition.at(node));
  }

  @override
  void patternForInExpressionIsNotIterable({
    required AstNode node,
    required Expression expression,
    required SharedTypeView expressionType,
  }) {
    _diagnosticReporter.report(
      diag.forInOfInvalidType
          .withArguments(
            expressionType: expressionType.unwrapTypeView<TypeImpl>(),
            expectedType: 'Iterable',
          )
          .at(expression),
    );
  }

  @override
  void patternTypeMismatchInIrrefutableContext({
    required covariant DartPatternImpl pattern,
    required AstNode context,
    required SharedTypeView matchedType,
    required SharedTypeView requiredType,
  }) {
    _diagnosticReporter.report(
      diag.patternTypeMismatchInIrrefutableContext
          .withArguments(
            matchedType: matchedType.unwrapTypeView<TypeImpl>(),
            requiredType: requiredType.unwrapTypeView<TypeImpl>(),
          )
          .at(pattern),
    );
  }

  @override
  void refutablePatternInIrrefutableContext({
    required AstNode pattern,
    required AstNode context,
  }) {
    _diagnosticReporter.report(
      diag.refutablePatternInIrrefutableContext.at(pattern),
    );
  }

  @override
  void relationalPatternOperandTypeNotAssignable({
    required covariant RelationalPatternImpl pattern,
    required SharedTypeView operandType,
    required SharedTypeView parameterType,
  }) {
    _diagnosticReporter.report(
      diag.relationalPatternOperandTypeNotAssignable
          .withArguments(
            operandType: operandType.unwrapTypeView<TypeImpl>(),
            parameterType: parameterType.unwrapTypeView<TypeImpl>(),
            operator: pattern.operator.lexeme,
          )
          .at(pattern.operand),
    );
  }

  @override
  void relationalPatternOperatorReturnTypeNotAssignableToBool({
    required covariant RelationalPatternImpl pattern,
    required SharedTypeView returnType,
  }) {
    _diagnosticReporter.report(
      diag.relationalPatternOperatorReturnTypeNotAssignableToBool.at(
        pattern.operator,
      ),
    );
  }

  @override
  void restPatternInMap({
    required covariant MapPatternImpl node,
    required covariant RestPatternElementImpl element,
  }) {
    _diagnosticReporter.report(diag.restElementInMapPattern.at(element));
  }

  @override
  void switchCaseCompletesNormally({
    required covariant SwitchStatementImpl node,
    required int caseIndex,
  }) {
    _diagnosticReporter.report(
      diag.switchCaseCompletesNormally.at(node.members[caseIndex].keyword),
    );
  }

  @override
  void unnecessaryWildcardPattern({
    required covariant WildcardPatternImpl pattern,
    required UnnecessaryWildcardKind kind,
  }) {
    switch (kind) {
      case UnnecessaryWildcardKind.logicalAndPatternOperand:
        _diagnosticReporter.report(diag.unnecessaryWildcardPattern.at(pattern));
    }
  }
}
