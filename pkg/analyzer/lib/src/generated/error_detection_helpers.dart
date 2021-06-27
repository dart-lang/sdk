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
      {Map<DartType, NonPromotionReason> Function()? whyNotPromoted}) {
    // Warning case: test static type information
    if (expectedStaticType != null) {
      if (!expectedStaticType.isVoid && checkForUseOfVoidResult(expression)) {
        return;
      }

      _checkForAssignableExpressionAtType(
          expression, actualStaticType, expectedStaticType, errorCode,
          whyNotPromoted: whyNotPromoted);
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
      Map<DartType, NonPromotionReason> Function()? whyNotPromoted}) {
    _checkForArgumentTypeNotAssignableForArgument2(
      argument: argument is NamedExpression ? argument.expression : argument,
      parameter: argument.staticParameterElement,
      promoteParameterToNullable: promoteParameterToNullable,
      whyNotPromoted: whyNotPromoted,
    );
  }

  /// Verify that the given constructor field [initializer] has compatible field
  /// and initializer expression types. The [fieldElement] is the static element
  /// from the name in the [ConstructorFieldInitializer].
  ///
  /// See [CompileTimeErrorCode.CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE], and
  /// [StaticWarningCode.FIELD_INITIALIZER_NOT_ASSIGNABLE].
  void checkForFieldInitializerNotAssignable(
      ConstructorFieldInitializer initializer, FieldElement fieldElement,
      {required bool isConstConstructor,
      required Map<DartType, NonPromotionReason> Function()? whyNotPromoted}) {
    // prepare field type
    DartType fieldType = fieldElement.type;
    // prepare expression type
    Expression expression = initializer.expression;
    // test the static type of the expression
    DartType staticType = expression.typeOrThrow;
    if (typeSystem.isAssignableTo(staticType, fieldType)) {
      if (!fieldType.isVoid) {
        checkForUseOfVoidResult(expression);
      }
      return;
    }
    var messages =
        computeWhyNotPromotedMessages(expression, whyNotPromoted?.call());
    // report problem
    if (isConstConstructor) {
      // TODO(paulberry): this error should be based on the actual type of the
      // constant, not the static type.  See dartbug.com/21119.
      errorReporter.reportErrorForNode(
          CompileTimeErrorCode.CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE,
          expression,
          [staticType, fieldType],
          messages);
    }
    errorReporter.reportErrorForNode(
        CompileTimeErrorCode.FIELD_INITIALIZER_NOT_ASSIGNABLE,
        expression,
        [staticType, fieldType],
        messages);
    // TODO(brianwilkerson) Define a hint corresponding to these errors and
    // report it if appropriate.
//        // test the propagated type of the expression
//        Type propagatedType = expression.getPropagatedType();
//        if (propagatedType != null && propagatedType.isAssignableTo(fieldType)) {
//          return false;
//        }
//        // report problem
//        if (isEnclosingConstructorConst) {
//          errorReporter.reportTypeErrorForNode(
//              CompileTimeErrorCode.CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE,
//              expression,
//              propagatedType == null ? staticType : propagatedType,
//              fieldType);
//        } else {
//          errorReporter.reportTypeErrorForNode(
//              StaticWarningCode.FIELD_INITIALIZER_NOT_ASSIGNABLE,
//              expression,
//              propagatedType == null ? staticType : propagatedType,
//              fieldType);
//        }
//        return true;
  }

  /// Verify that the given left hand side ([lhs]) and right hand side ([rhs])
  /// represent a valid assignment.
  ///
  /// See [CompileTimeErrorCode.INVALID_ASSIGNMENT].
  void checkForInvalidAssignment(Expression? lhs, Expression? rhs,
      {Map<DartType, NonPromotionReason> Function()? whyNotPromoted}) {
    if (lhs == null || rhs == null) {
      return;
    }

    if (lhs is IndexExpression &&
            identical(lhs.realTarget.staticType, NeverTypeImpl.instance) ||
        lhs is PrefixedIdentifier &&
            identical(lhs.prefix.staticType, NeverTypeImpl.instance) ||
        lhs is PropertyAccess &&
            identical(lhs.realTarget.staticType, NeverTypeImpl.instance)) {
      return;
    }

    DartType leftType;
    var parent = lhs.parent;
    if (parent is AssignmentExpression && parent.leftHandSide == lhs) {
      leftType = parent.writeType!;
    } else {
      var leftVariableElement = getVariableElement(lhs);
      leftType = (leftVariableElement == null)
          ? lhs.typeOrThrow
          : leftVariableElement.type;
    }

    if (!leftType.isVoid && checkForUseOfVoidResult(rhs)) {
      return;
    }

    _checkForAssignableExpression(
        rhs, leftType, CompileTimeErrorCode.INVALID_ASSIGNMENT,
        whyNotPromoted: whyNotPromoted);
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

  void checkIndexExpressionIndex(
    Expression index, {
    required ExecutableElement? readElement,
    required ExecutableElement? writeElement,
    required Map<DartType, NonPromotionReason> Function()? whyNotPromoted,
  }) {
    if (readElement is MethodElement) {
      var parameters = readElement.parameters;
      if (parameters.isNotEmpty) {
        _checkForArgumentTypeNotAssignableForArgument2(
          argument: index,
          parameter: parameters[0],
          promoteParameterToNullable: false,
          whyNotPromoted: whyNotPromoted,
        );
      }
    }

    if (writeElement is MethodElement) {
      var parameters = writeElement.parameters;
      if (parameters.isNotEmpty) {
        _checkForArgumentTypeNotAssignableForArgument2(
          argument: index,
          parameter: parameters[0],
          promoteParameterToNullable: false,
        );
      }
    }
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
      SyntacticEntity errorEntity,
      Map<DartType, NonPromotionReason>? whyNotPromoted);

  /// Return the variable element represented by the given [expression], or
  /// `null` if there is no such element.
  VariableElement? getVariableElement(Expression? expression) {
    if (expression is Identifier) {
      var element = expression.staticElement;
      if (element is VariableElement) {
        return element;
      }
    }
    return null;
  }

  void _checkForArgumentTypeNotAssignableForArgument2({
    required Expression argument,
    required ParameterElement? parameter,
    required bool promoteParameterToNullable,
    Map<DartType, NonPromotionReason> Function()? whyNotPromoted,
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
        whyNotPromoted);
  }

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
      Map<DartType, NonPromotionReason> Function()? whyNotPromoted) {
    checkForArgumentTypeNotAssignable(
        expression, expectedStaticType, expression.typeOrThrow, errorCode,
        whyNotPromoted: whyNotPromoted);
  }

  bool _checkForAssignableExpression(
      Expression expression, DartType expectedStaticType, ErrorCode errorCode,
      {required Map<DartType, NonPromotionReason> Function()? whyNotPromoted}) {
    DartType actualStaticType = expression.typeOrThrow;
    return _checkForAssignableExpressionAtType(
        expression, actualStaticType, expectedStaticType, errorCode,
        whyNotPromoted: whyNotPromoted);
  }

  bool _checkForAssignableExpressionAtType(
      Expression expression,
      DartType actualStaticType,
      DartType expectedStaticType,
      ErrorCode errorCode,
      {Map<DartType, NonPromotionReason> Function()? whyNotPromoted}) {
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
        computeWhyNotPromotedMessages(expression, whyNotPromoted?.call()),
      );
      return false;
    }
    return true;
  }
}
