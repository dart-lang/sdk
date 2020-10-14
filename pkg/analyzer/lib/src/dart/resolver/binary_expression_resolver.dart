// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/dart/resolver/invocation_inference_helper.dart';
import 'package:analyzer/src/dart/resolver/resolution_result.dart';
import 'package:analyzer/src/dart/resolver/type_property_resolver.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/type_promotion_manager.dart';
import 'package:meta/meta.dart';

/// Helper for resolving [BinaryExpression]s.
class BinaryExpressionResolver {
  final ResolverVisitor _resolver;
  final TypePromotionManager _promoteManager;
  final FlowAnalysisHelper _flowAnalysis;
  final TypePropertyResolver _typePropertyResolver;
  final InvocationInferenceHelper _inferenceHelper;

  BinaryExpressionResolver({
    @required ResolverVisitor resolver,
    @required TypePromotionManager promoteManager,
    @required FlowAnalysisHelper flowAnalysis,
  })  : _resolver = resolver,
        _promoteManager = promoteManager,
        _flowAnalysis = flowAnalysis,
        _typePropertyResolver = resolver.typePropertyResolver,
        _inferenceHelper = resolver.inferenceHelper;

  ErrorReporter get _errorReporter => _resolver.errorReporter;

  bool get _isNonNullableByDefault => _typeSystem.isNonNullableByDefault;

  TypeProvider get _typeProvider => _resolver.typeProvider;

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

  void resolve(BinaryExpressionImpl node) {
    var operator = node.operator.type;

    if (operator == TokenType.AMPERSAND_AMPERSAND) {
      _resolveLogicalAnd(node);
      return;
    }

    if (operator == TokenType.BANG_EQ || operator == TokenType.EQ_EQ) {
      _resolveEqual(node, notEqual: operator == TokenType.BANG_EQ);
      return;
    }

    if (operator == TokenType.BAR_BAR) {
      _resolveLogicalOr(node);
      return;
    }

    if (operator == TokenType.QUESTION_QUESTION) {
      _resolveIfNull(node);
      return;
    }

    if (operator.isUserDefinableOperator) {
      _resolveUserDefinable(node);
      return;
    }

    _resolveUnsupportedOperator(node);
  }

  /// Set the static type of [node] to be the least upper bound of the static
  /// types [staticType1] and [staticType2].
  ///
  /// TODO(scheglov) this is duplicate
  void _analyzeLeastUpperBoundTypes(
      Expression node, DartType staticType1, DartType staticType2) {
    // TODO(brianwilkerson) Determine whether this can still happen.
    staticType1 ??= DynamicTypeImpl.instance;

    // TODO(brianwilkerson) Determine whether this can still happen.
    staticType2 ??= DynamicTypeImpl.instance;

    DartType staticType =
        _typeSystem.getLeastUpperBound(staticType1, staticType2) ??
            DynamicTypeImpl.instance;

    staticType = _resolver.toLegacyTypeIfOptOut(staticType);

    _inferenceHelper.recordStaticType(node, staticType);
  }

  void _checkNonBoolOperand(Expression operand, String operator) {
    _resolver.boolExpressionVerifier.checkForNonBoolExpression(
      operand,
      errorCode: CompileTimeErrorCode.NON_BOOL_OPERAND,
      arguments: [operator],
    );
  }

  void _resolveEqual(BinaryExpressionImpl node, {@required bool notEqual}) {
    var left = node.leftOperand;
    left.accept(_resolver);
    left = node.leftOperand;

    var flow = _flowAnalysis?.flow;
    var leftExtensionOverride = left is ExtensionOverride;
    if (!leftExtensionOverride) {
      flow?.equalityOp_rightBegin(left, left.staticType);
    }

    var right = node.rightOperand;
    right.accept(_resolver);
    right = node.rightOperand;

    if (!leftExtensionOverride) {
      flow?.equalityOp_end(node, right, right.staticType, notEqual: notEqual);
    }

    _resolveUserDefinableElement(
      node,
      TokenType.EQ_EQ.lexeme,
      promoteLeftTypeToNonNull: true,
    );
    _resolveUserDefinableType(node);
  }

  void _resolveIfNull(BinaryExpressionImpl node) {
    var left = node.leftOperand;
    var right = node.rightOperand;
    var flow = _flowAnalysis?.flow;

    var leftContextType = InferenceContext.getContext(node);
    if (leftContextType != null && _isNonNullableByDefault) {
      leftContextType = _typeSystem.makeNullable(leftContextType);
    }
    InferenceContext.setType(left, leftContextType);

    left.accept(_resolver);
    left = node.leftOperand;
    var leftType = left.staticType;

    var rightContextType = InferenceContext.getContext(node);
    if (rightContextType == null || rightContextType.isDynamic) {
      rightContextType = leftType;
    }
    InferenceContext.setType(right, rightContextType);

    flow?.ifNullExpression_rightBegin(left, leftType);
    right.accept(_resolver);
    right = node.rightOperand;
    flow?.ifNullExpression_end();

    var rightType = right.staticType;
    if (_isNonNullableByDefault) {
      var promotedLeftType = _typeSystem.promoteToNonNull(leftType);
      _analyzeLeastUpperBoundTypes(node, promotedLeftType, rightType);
    } else {
      _analyzeLeastUpperBoundTypes(node, leftType, rightType);
    }
  }

  void _resolveLogicalAnd(BinaryExpressionImpl node) {
    var left = node.leftOperand;
    var right = node.rightOperand;
    var flow = _flowAnalysis?.flow;

    InferenceContext.setType(left, _typeProvider.boolType);
    InferenceContext.setType(right, _typeProvider.boolType);

    flow?.logicalBinaryOp_begin();
    left.accept(_resolver);
    left = node.leftOperand;

    if (_flowAnalysis != null) {
      flow?.logicalBinaryOp_rightBegin(left, isAnd: true);
      _resolver.checkUnreachableNode(right);

      right.accept(_resolver);
      right = node.rightOperand;

      _resolver.nullSafetyDeadCodeVerifier?.flowEnd(right);
      flow?.logicalBinaryOp_end(node, right, isAnd: true);
    } else {
      _promoteManager.visitBinaryExpression_and_rhs(
        left,
        right,
        () {
          right.accept(_resolver);
          right = node.rightOperand;
        },
      );
    }

    _checkNonBoolOperand(left, '&&');
    _checkNonBoolOperand(right, '&&');

    _inferenceHelper.recordStaticType(node, _typeProvider.boolType);
  }

  void _resolveLogicalOr(BinaryExpressionImpl node) {
    var left = node.leftOperand;
    var right = node.rightOperand;
    var flow = _flowAnalysis?.flow;

    InferenceContext.setType(left, _typeProvider.boolType);
    InferenceContext.setType(right, _typeProvider.boolType);

    flow?.logicalBinaryOp_begin();
    left.accept(_resolver);
    left = node.leftOperand;

    flow?.logicalBinaryOp_rightBegin(left, isAnd: false);
    _resolver.checkUnreachableNode(right);

    right.accept(_resolver);
    right = node.rightOperand;

    _resolver.nullSafetyDeadCodeVerifier?.flowEnd(right);
    flow?.logicalBinaryOp_end(node, right, isAnd: false);

    _checkNonBoolOperand(left, '||');
    _checkNonBoolOperand(right, '||');

    _inferenceHelper.recordStaticType(node, _typeProvider.boolType);
  }

  /// If the given [type] is a type parameter, resolve it to the type that should
  /// be used when looking up members. Otherwise, return the original type.
  ///
  /// TODO(scheglov) this is duplicate
  DartType _resolveTypeParameter(DartType type) =>
      type?.resolveToBound(_typeProvider.objectType);

  void _resolveUnsupportedOperator(BinaryExpressionImpl node) {
    node.leftOperand.accept(_resolver);
    node.rightOperand.accept(_resolver);
    _inferenceHelper.recordStaticType(node, DynamicTypeImpl.instance);
  }

  void _resolveUserDefinable(BinaryExpressionImpl node) {
    var left = node.leftOperand;
    var right = node.rightOperand;

    left.accept(_resolver);
    left = node.leftOperand; // In case it was rewritten

    var operator = node.operator;
    _resolveUserDefinableElement(node, operator.lexeme);

    var invokeType = node.staticInvokeType;
    if (invokeType != null && invokeType.parameters.isNotEmpty) {
      // If this is a user-defined operator, set the right operand context
      // using the operator method's parameter type.
      var rightParam = invokeType.parameters[0];
      InferenceContext.setType(
          right,
          _typeSystem.refineNumericInvocationContext(
              left.staticType,
              node.staticElement,
              InferenceContext.getContext(node),
              rightParam.type));
    }

    right.accept(_resolver);

    _resolveUserDefinableType(node);
  }

  void _resolveUserDefinableElement(
    BinaryExpression node,
    String methodName, {
    bool promoteLeftTypeToNonNull = false,
  }) {
    Expression leftOperand = node.leftOperand;

    if (leftOperand is ExtensionOverride) {
      ExtensionElement extension = leftOperand.extensionName.staticElement;
      MethodElement member = extension.getMethod(methodName);
      if (member == null) {
        _errorReporter.reportErrorForToken(
          CompileTimeErrorCode.UNDEFINED_EXTENSION_OPERATOR,
          node.operator,
          [methodName, extension.name],
        );
      }
      node.staticElement = member;
      return;
    }

    var leftType = leftOperand.staticType;
    leftType = _resolveTypeParameter(leftType);

    if (identical(leftType, NeverTypeImpl.instance)) {
      _resolver.errorReporter.reportErrorForNode(
        HintCode.RECEIVER_OF_TYPE_NEVER,
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
      receiverErrorNode: leftOperand,
      nameErrorEntity: node,
    );

    node.staticElement = result.getter;
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

  void _resolveUserDefinableType(BinaryExpressionImpl node) {
    var leftOperand = node.leftOperand;

    var leftType = leftOperand.staticType;
    leftType = _resolveTypeParameter(leftType);

    if (identical(leftType, NeverTypeImpl.instance)) {
      _inferenceHelper.recordStaticType(node, NeverTypeImpl.instance);
      return;
    }

    DartType staticType =
        node.staticInvokeType?.returnType ?? DynamicTypeImpl.instance;
    if (leftOperand is! ExtensionOverride) {
      staticType = _typeSystem.refineBinaryExpressionType(
        leftType,
        node.operator.type,
        node.rightOperand.staticType,
        staticType,
        node.staticElement,
      );
    }
    _inferenceHelper.recordStaticType(node, staticType);
  }
}
