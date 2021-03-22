// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/error/codes.dart';

/// Methods useful in detecting errors.  This mixin exists to allow code to be
/// more easily shared between the two visitors that do the majority of error
/// reporting (ResolverVisitor and ErrorVerifier).
mixin ErrorDetectionHelpers {
  ErrorReporter get errorReporter;

  TypeSystemImpl get typeSystem;

  /// Verify that the given [expression] can be assigned to its corresponding
  /// parameters. The [expectedStaticType] is the expected static type of the
  /// parameter. The [actualStaticType] is the actual static type of the
  /// argument.
  void checkForArgumentTypeNotAssignable(
      Expression expression,
      DartType? expectedStaticType,
      DartType actualStaticType,
      ErrorCode errorCode,
      {Map<DartType, NonPromotionReason> Function()? whyNotPromotedInfo}) {
    // Warning case: test static type information
    if (expectedStaticType != null) {
      if (!expectedStaticType.isVoid && checkForUseOfVoidResult(expression)) {
        return;
      }

      checkForAssignableExpressionAtType(
          expression, actualStaticType, expectedStaticType, errorCode,
          whyNotPromotedInfo: whyNotPromotedInfo);
    }
  }

  /// Verify that the given [argument] can be assigned to its corresponding
  /// parameter.
  ///
  /// This method corresponds to
  /// [BestPracticesVerifier.checkForArgumentTypeNotAssignableForArgument].
  ///
  /// See [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE].
  void checkForArgumentTypeNotAssignableForArgument(Expression argument,
      {bool promoteParameterToNullable = false,
      Map<DartType, NonPromotionReason> Function()? whyNotPromotedInfo}) {
    checkForArgumentTypeNotAssignableForArgument2(
      argument: argument,
      parameter: argument.staticParameterElement,
      promoteParameterToNullable: promoteParameterToNullable,
      whyNotPromotedInfo: whyNotPromotedInfo,
    );
  }

  void checkForArgumentTypeNotAssignableForArgument2({
    required Expression argument,
    required ParameterElement? parameter,
    required bool promoteParameterToNullable,
    Map<DartType, NonPromotionReason> Function()? whyNotPromotedInfo,
  }) {
    var staticParameterType = parameter?.type;
    if (promoteParameterToNullable && staticParameterType != null) {
      staticParameterType =
          typeSystem.makeNullable(staticParameterType as TypeImpl);
    }
    _checkForArgumentTypeNotAssignableWithExpectedTypes(
        argument,
        staticParameterType,
        CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE,
        whyNotPromotedInfo);
  }

  bool checkForAssignableExpressionAtType(
      Expression expression,
      DartType actualStaticType,
      DartType expectedStaticType,
      ErrorCode errorCode,
      {Map<DartType, NonPromotionReason> Function()? whyNotPromotedInfo}) {
    if (!typeSystem.isAssignableTo(actualStaticType, expectedStaticType)) {
      AstNode getErrorNode(AstNode node) {
        if (node is CascadeExpression) {
          return getErrorNode(node.target);
        }
        if (node is ParenthesizedExpression) {
          return getErrorNode(node.expression);
        }
        return node;
      }

      errorReporter.reportErrorForNode(
        errorCode,
        getErrorNode(expression),
        [actualStaticType, expectedStaticType],
        computeWhyNotPromotedMessages(
            expression, expression, whyNotPromotedInfo?.call()),
      );
      return false;
    }
    return true;
  }

  /// Check for situations where the result of a method or function is used,
  /// when it returns 'void'. Or, in rare cases, when other types of expressions
  /// are void, such as identifiers.
  ///
  /// See [StaticWarningCode.USE_OF_VOID_RESULT].
  bool checkForUseOfVoidResult(Expression expression) {
    if (!identical(expression.staticType, VoidTypeImpl.instance)) {
      return false;
    }

    if (expression is MethodInvocation) {
      SimpleIdentifier methodName = expression.methodName;
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.USE_OF_VOID_RESULT, methodName, []);
    } else {
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.USE_OF_VOID_RESULT, expression, []);
    }

    return true;
  }

  /// Computes the appropriate set of context messages to report along with an
  /// error that may have occurred because [expression] was not type promoted.
  ///
  /// If [expression] is `null`, it means the expression that was not type
  /// promoted was an implicit `this`.
  ///
  /// [errorEntity] is the entity whose location will be associated with the
  /// error.  This is needed for test instrumentation.
  ///
  /// [whyNotPromoted] should be the non-promotion details returned by the flow
  /// analysis engine.
  List<DiagnosticMessage> computeWhyNotPromotedMessages(
      Expression? expression,
      SyntacticEntity errorEntity,
      Map<DartType, NonPromotionReason>? whyNotPromoted);

  /// Verify that the given [expression] can be assigned to its corresponding
  /// parameters.
  ///
  /// See [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE],
  /// [CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE],
  /// [StaticWarningCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE],
  /// [CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE],
  /// [CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE],
  /// [StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE], and
  /// [StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE].
  void _checkForArgumentTypeNotAssignableWithExpectedTypes(
      Expression expression,
      DartType? expectedStaticType,
      ErrorCode errorCode,
      Map<DartType, NonPromotionReason> Function()? whyNotPromotedInfo) {
    checkForArgumentTypeNotAssignable(
        expression, expectedStaticType, expression.typeOrThrow, errorCode,
        whyNotPromotedInfo: whyNotPromotedInfo);
  }
}
