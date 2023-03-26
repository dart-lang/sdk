// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/invocation_inference_helper.dart';
import 'package:analyzer/src/dart/resolver/resolution_result.dart';
import 'package:analyzer/src/dart/resolver/type_property_resolver.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// Helper for resolving [BinaryExpression]s.
class BinaryExpressionResolver {
  final ResolverVisitor _resolver;
  final TypePropertyResolver _typePropertyResolver;
  final InvocationInferenceHelper _inferenceHelper;

  BinaryExpressionResolver({
    required ResolverVisitor resolver,
  })  : _resolver = resolver,
        _typePropertyResolver = resolver.typePropertyResolver,
        _inferenceHelper = resolver.inferenceHelper;

  ErrorReporter get _errorReporter => _resolver.errorReporter;

  bool get _isNonNullableByDefault => _typeSystem.isNonNullableByDefault;

  TypeProvider get _typeProvider => _resolver.typeProvider;

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

  void resolve(BinaryExpressionImpl node, {required DartType? contextType}) {
    var operator = node.operator.type;

    if (operator == TokenType.AMPERSAND_AMPERSAND) {
      _resolveLogicalAnd(node, contextType: contextType);
      return;
    }

    if (operator == TokenType.BANG_EQ || operator == TokenType.EQ_EQ) {
      _resolveEqual(node,
          notEqual: operator == TokenType.BANG_EQ, contextType: contextType);
      return;
    }

    if (operator == TokenType.BAR_BAR) {
      _resolveLogicalOr(node, contextType: contextType);
      return;
    }

    if (operator == TokenType.QUESTION_QUESTION) {
      _resolveIfNull(node, contextType: contextType);
      return;
    }

    if (operator.isUserDefinableOperator && operator.isBinaryOperator) {
      _resolveUserDefinable(node, contextType: contextType);
      return;
    }

    // Report an error if not already reported by the parser.
    if (operator != TokenType.BANG_EQ_EQ && operator != TokenType.EQ_EQ_EQ) {
      _errorReporter.reportErrorForToken(
          CompileTimeErrorCode.NOT_BINARY_OPERATOR,
          node.operator,
          [operator.lexeme]);
    }

    _resolveUnsupportedOperator(node, contextType: contextType);
  }

  /// Set the static type of [node] to be the least upper bound of the static
  /// types [staticType1] and [staticType2].
  ///
  /// TODO(scheglov) this is duplicate
  void _analyzeLeastUpperBoundTypes(
      ExpressionImpl node, DartType staticType1, DartType staticType2,
      {required DartType? contextType}) {
    var staticType = _typeSystem.getLeastUpperBound(staticType1, staticType2);

    staticType = _resolver.toLegacyTypeIfOptOut(staticType);

    _inferenceHelper.recordStaticType(node, staticType,
        contextType: contextType);
  }

  void _checkNonBoolOperand(Expression operand, String operator,
      {required Map<DartType, NonPromotionReason> Function()? whyNotPromoted}) {
    _resolver.boolExpressionVerifier.checkForNonBoolExpression(
      operand,
      errorCode: CompileTimeErrorCode.NON_BOOL_OPERAND,
      arguments: [operator],
      whyNotPromoted: whyNotPromoted,
    );
  }

  void _resolveEqual(BinaryExpressionImpl node,
      {required bool notEqual, required DartType? contextType}) {
    _resolver.analyzeExpression(node.leftOperand, null);
    var left = _resolver.popRewrite()!;

    var flowAnalysis = _resolver.flowAnalysis;
    var flow = flowAnalysis.flow;
    EqualityInfo<DartType>? leftInfo;
    var leftExtensionOverride = left is ExtensionOverride;
    if (!leftExtensionOverride) {
      leftInfo = flow?.equalityOperand_end(left, left.typeOrThrow);
    }

    _resolver.analyzeExpression(node.rightOperand, null);
    var right = _resolver.popRewrite()!;
    var whyNotPromoted = flowAnalysis.flow?.whyNotPromoted(right);

    if (!leftExtensionOverride) {
      flow?.equalityOperation_end(
          node, leftInfo, flow.equalityOperand_end(right, right.typeOrThrow),
          notEqual: notEqual);
    }

    _resolveUserDefinableElement(
      node,
      TokenType.EQ_EQ.lexeme,
      promoteLeftTypeToNonNull: true,
    );
    _resolveUserDefinableType(node, contextType: contextType);
    _resolver.checkForArgumentTypeNotAssignableForArgument(node.rightOperand,
        promoteParameterToNullable: true, whyNotPromoted: whyNotPromoted);

    void reportNullComparison(SyntacticEntity start, SyntacticEntity end) {
      var errorCode = notEqual
          ? WarningCode.UNNECESSARY_NULL_COMPARISON_FALSE
          : WarningCode.UNNECESSARY_NULL_COMPARISON_TRUE;
      var offset = start.offset;
      _errorReporter.reportErrorForOffset(errorCode, offset, end.end - offset);
    }

    if (left is SimpleIdentifierImpl && right is NullLiteralImpl) {
      var element = left.staticElement;
      if (element is PromotableElement &&
          flowAnalysis.isDefinitelyUnassigned(left, element)) {
        reportNullComparison(left, node.operator);
      }
    } else if (right is SimpleIdentifierImpl && left is NullLiteralImpl) {
      var element = right.staticElement;
      if (element is PromotableElement &&
          flowAnalysis.isDefinitelyUnassigned(right, element)) {
        reportNullComparison(node.operator, right);
      }
    }
  }

  void _resolveIfNull(BinaryExpressionImpl node,
      {required DartType? contextType}) {
    var left = node.leftOperand;
    var right = node.rightOperand;
    var flow = _resolver.flowAnalysis.flow;

    var leftContextType = contextType;
    if (leftContextType != null && _isNonNullableByDefault) {
      leftContextType = _typeSystem.makeNullable(leftContextType);
    }

    _resolver.analyzeExpression(left, leftContextType);
    left = _resolver.popRewrite()!;
    var leftType = left.typeOrThrow;

    var rightContextType = contextType;
    if (rightContextType == null || rightContextType.isDynamic) {
      rightContextType = leftType;
    }

    flow?.ifNullExpression_rightBegin(left, leftType);
    _resolver.analyzeExpression(right, rightContextType);
    right = _resolver.popRewrite()!;
    flow?.ifNullExpression_end();

    var rightType = right.typeOrThrow;
    if (_isNonNullableByDefault) {
      var promotedLeftType = _typeSystem.promoteToNonNull(leftType);
      _analyzeLeastUpperBoundTypes(node, promotedLeftType, rightType,
          contextType: contextType);
    } else {
      _analyzeLeastUpperBoundTypes(node, leftType, rightType,
          contextType: contextType);
    }
    _resolver.checkForArgumentTypeNotAssignableForArgument(right);
  }

  void _resolveLogicalAnd(BinaryExpressionImpl node,
      {required DartType? contextType}) {
    var left = node.leftOperand;
    var right = node.rightOperand;
    var flow = _resolver.flowAnalysis.flow;

    flow?.logicalBinaryOp_begin();
    _resolver.analyzeExpression(left, _typeProvider.boolType);
    left = _resolver.popRewrite()!;
    var leftWhyNotPromoted = _resolver.flowAnalysis.flow?.whyNotPromoted(left);

    flow?.logicalBinaryOp_rightBegin(left, node, isAnd: true);
    _resolver.checkUnreachableNode(right);

    _resolver.analyzeExpression(right, _typeProvider.boolType);
    right = _resolver.popRewrite()!;
    var rightWhyNotPromoted =
        _resolver.flowAnalysis.flow?.whyNotPromoted(right);

    _resolver.nullSafetyDeadCodeVerifier.flowEnd(right);
    flow?.logicalBinaryOp_end(node, right, isAnd: true);

    _checkNonBoolOperand(left, '&&', whyNotPromoted: leftWhyNotPromoted);
    _checkNonBoolOperand(right, '&&', whyNotPromoted: rightWhyNotPromoted);

    _inferenceHelper.recordStaticType(node, _typeProvider.boolType,
        contextType: contextType);
  }

  void _resolveLogicalOr(BinaryExpressionImpl node,
      {required DartType? contextType}) {
    var left = node.leftOperand;
    var right = node.rightOperand;
    var flow = _resolver.flowAnalysis.flow;

    flow?.logicalBinaryOp_begin();
    _resolver.analyzeExpression(left, _typeProvider.boolType);
    left = _resolver.popRewrite()!;
    var leftWhyNotPromoted = _resolver.flowAnalysis.flow?.whyNotPromoted(left);

    flow?.logicalBinaryOp_rightBegin(left, node, isAnd: false);
    _resolver.checkUnreachableNode(right);

    _resolver.analyzeExpression(right, _typeProvider.boolType);
    right = _resolver.popRewrite()!;
    var rightWhyNotPromoted =
        _resolver.flowAnalysis.flow?.whyNotPromoted(right);

    _resolver.nullSafetyDeadCodeVerifier.flowEnd(right);
    flow?.logicalBinaryOp_end(node, right, isAnd: false);

    _checkNonBoolOperand(left, '||', whyNotPromoted: leftWhyNotPromoted);
    _checkNonBoolOperand(right, '||', whyNotPromoted: rightWhyNotPromoted);

    _inferenceHelper.recordStaticType(node, _typeProvider.boolType,
        contextType: contextType);
  }

  void _resolveUnsupportedOperator(BinaryExpressionImpl node,
      {required DartType? contextType}) {
    node.leftOperand.accept(_resolver);
    node.rightOperand.accept(_resolver);
    _inferenceHelper.recordStaticType(node, DynamicTypeImpl.instance,
        contextType: contextType);
  }

  void _resolveUserDefinable(BinaryExpressionImpl node,
      {required DartType? contextType}) {
    _resolver.analyzeExpression(node.leftOperand, null);
    var left = _resolver.popRewrite()!;

    var operator = node.operator;
    _resolveUserDefinableElement(node, operator.lexeme);

    var invokeType = node.staticInvokeType;
    DartType? rightContextType;
    if (invokeType != null && invokeType.parameters.isNotEmpty) {
      // If this is a user-defined operator, set the right operand context
      // using the operator method's parameter type.
      var rightParam = invokeType.parameters[0];
      rightContextType = _typeSystem.refineNumericInvocationContext(
          left.staticType, node.staticElement, contextType, rightParam.type);
    }

    _resolver.analyzeExpression(node.rightOperand, rightContextType);
    var right = _resolver.popRewrite()!;
    var whyNotPromoted = _resolver.flowAnalysis.flow?.whyNotPromoted(right);

    _resolveUserDefinableType(node, contextType: contextType);
    _resolver.checkForArgumentTypeNotAssignableForArgument(right,
        whyNotPromoted: whyNotPromoted);
  }

  void _resolveUserDefinableElement(
    BinaryExpressionImpl node,
    String methodName, {
    bool promoteLeftTypeToNonNull = false,
  }) {
    Expression leftOperand = node.leftOperand;

    if (leftOperand is ExtensionOverride) {
      var extension =
          leftOperand.extensionName.staticElement as ExtensionElement;
      var member = extension.getMethod(methodName);
      if (member == null) {
        // Extension overrides can only be used with named extensions so it is
        // safe to assume `extension.name` is non-`null`.
        _errorReporter.reportErrorForToken(
          CompileTimeErrorCode.UNDEFINED_EXTENSION_OPERATOR,
          node.operator,
          [methodName, extension.name!],
        );
      }
      node.staticElement = member;
      node.staticInvokeType = member?.type;
      return;
    }

    var leftType = leftOperand.typeOrThrow;
    leftType = _typeSystem.resolveToBound(leftType);

    if (identical(leftType, NeverTypeImpl.instance)) {
      _resolver.errorReporter.reportErrorForNode(
        WarningCode.RECEIVER_OF_TYPE_NEVER,
        leftOperand,
      );
      return;
    }

    if (promoteLeftTypeToNonNull) {
      leftType = _typeSystem.promoteToNonNull(leftType);
    }

    ResolutionResult result = _typePropertyResolver.resolve(
      receiver: leftOperand,
      receiverType: leftType,
      name: methodName,
      propertyErrorEntity: node.operator,
      nameErrorEntity: node,
    );

    node.staticElement = result.getter as MethodElement?;
    node.staticInvokeType = result.getter?.type;
    if (result.needsGetterError) {
      if (leftOperand is SuperExpression) {
        _errorReporter.reportErrorForToken(
          CompileTimeErrorCode.UNDEFINED_SUPER_OPERATOR,
          node.operator,
          [methodName, leftType],
        );
      } else {
        _errorReporter.reportErrorForToken(
          CompileTimeErrorCode.UNDEFINED_OPERATOR,
          node.operator,
          [methodName, leftType],
        );
      }
    }
  }

  void _resolveUserDefinableType(BinaryExpressionImpl node,
      {required DartType? contextType}) {
    var leftOperand = node.leftOperand;

    DartType leftType;
    if (leftOperand is ExtensionOverrideImpl) {
      leftType = leftOperand.extendedType!;
    } else {
      leftType = leftOperand.typeOrThrow;
      leftType = _typeSystem.resolveToBound(leftType);
    }

    if (identical(leftType, NeverTypeImpl.instance)) {
      _inferenceHelper.recordStaticType(node, NeverTypeImpl.instance,
          contextType: contextType);
      return;
    }

    DartType staticType =
        node.staticInvokeType?.returnType ?? DynamicTypeImpl.instance;
    if (leftOperand is! ExtensionOverride) {
      staticType = _typeSystem.refineBinaryExpressionType(
        leftType,
        node.operator.type,
        node.rightOperand.typeOrThrow,
        staticType,
        node.staticElement,
      );
    }
    _inferenceHelper.recordStaticType(node, staticType,
        contextType: contextType);
  }
}
