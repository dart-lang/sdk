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
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/dart/resolver/invocation_inference_helper.dart';
import 'package:analyzer/src/dart/resolver/resolution_result.dart';
import 'package:analyzer/src/dart/resolver/type_property_resolver.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/element_type_provider.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/type_promotion_manager.dart';
import 'package:analyzer/src/generated/type_system.dart';
import 'package:analyzer/src/task/strong/checker.dart';
import 'package:meta/meta.dart';

/// Helper for resolving [BinaryExpression]s.
class BinaryExpressionResolver {
  final ResolverVisitor _resolver;
  final TypePromotionManager _promoteManager;
  final FlowAnalysisHelper _flowAnalysis;
  final ElementTypeProvider _elementTypeProvider;
  final TypePropertyResolver _typePropertyResolver;
  final InvocationInferenceHelper _inferenceHelper;

  BinaryExpressionResolver({
    @required ResolverVisitor resolver,
    @required TypePromotionManager promoteManager,
    @required FlowAnalysisHelper flowAnalysis,
    @required ElementTypeProvider elementTypeProvider,
  })  : _resolver = resolver,
        _promoteManager = promoteManager,
        _flowAnalysis = flowAnalysis,
        _elementTypeProvider = elementTypeProvider,
        _typePropertyResolver = resolver.typePropertyResolver,
        _inferenceHelper = resolver.inferenceHelper;

  ErrorReporter get _errorReporter => _resolver.errorReporter;

  bool get _isNonNullableByDefault => _typeSystem.isNonNullableByDefault;

  TypeProvider get _typeProvider => _resolver.typeProvider;

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

  void resolve(BinaryExpressionImpl node) {
    TokenType operator = node.operator.type;
    Expression left = node.leftOperand;
    Expression right = node.rightOperand;
    var flow = _flowAnalysis?.flow;

    if (operator == TokenType.AMPERSAND_AMPERSAND) {
      InferenceContext.setType(left, _typeProvider.boolType);
      InferenceContext.setType(right, _typeProvider.boolType);

      // TODO(scheglov) Do we need these checks for null?
      left?.accept(_resolver);

      if (_flowAnalysis != null) {
        flow?.logicalBinaryOp_rightBegin(left, isAnd: true);
        _flowAnalysis.checkUnreachableNode(right);
        right.accept(_resolver);
        flow?.logicalBinaryOp_end(node, right, isAnd: true);
      } else {
        _promoteManager.visitBinaryExpression_and_rhs(
          left,
          right,
          () {
            right.accept(_resolver);
          },
        );
      }

      _resolve1(node);
    } else if (operator == TokenType.BAR_BAR) {
      InferenceContext.setType(left, _typeProvider.boolType);
      InferenceContext.setType(right, _typeProvider.boolType);

      // TODO(scheglov) Do we need these checks for null?
      left?.accept(_resolver);

      flow?.logicalBinaryOp_rightBegin(left, isAnd: false);
      _flowAnalysis?.checkUnreachableNode(right);
      right.accept(_resolver);
      flow?.logicalBinaryOp_end(node, right, isAnd: false);

      _resolve1(node);
    } else if (operator == TokenType.BANG_EQ || operator == TokenType.EQ_EQ) {
      left.accept(_resolver);
      _flowAnalysis?.flow?.equalityOp_rightBegin(left);
      right.accept(_resolver);
      _resolve1(node);
      _flowAnalysis?.flow?.equalityOp_end(node, right,
          notEqual: operator == TokenType.BANG_EQ);
    } else {
      if (operator == TokenType.QUESTION_QUESTION) {
        InferenceContext.setTypeFromNode(left, node);
      }
      // TODO(scheglov) Do we need these checks for null?
      left?.accept(_resolver);

      // Call ElementResolver.visitBinaryExpression to resolve the user-defined
      // operator method, if applicable.
      _resolve1(node);

      if (operator == TokenType.QUESTION_QUESTION) {
        // Set the right side, either from the context, or using the information
        // from the left side if it is more precise.
        DartType contextType = InferenceContext.getContext(node);
        DartType leftType = left?.staticType;
        if (contextType == null || contextType.isDynamic) {
          contextType = leftType;
        }
        InferenceContext.setType(right, contextType);
      } else {
        var invokeType = node.staticInvokeType;
        if (invokeType != null && invokeType.parameters.isNotEmpty) {
          // If this is a user-defined operator, set the right operand context
          // using the operator method's parameter type.
          var rightParam = invokeType.parameters[0];
          InferenceContext.setType(
              right, _elementTypeProvider.getVariableType(rightParam));
        }
      }

      if (operator == TokenType.QUESTION_QUESTION) {
        flow?.ifNullExpression_rightBegin(node.leftOperand);
        right.accept(_resolver);
        flow?.ifNullExpression_end();
      } else {
        // TODO(scheglov) Do we need these checks for null?
        right?.accept(_resolver);
      }
    }
    _resolve2(node);
  }

  /// Set the static type of [node] to be the least upper bound of the static
  /// types of subexpressions [expr1] and [expr2].
  ///
  /// TODO(scheglov) this is duplicate
  void _analyzeLeastUpperBound(
      Expression node, Expression expr1, Expression expr2,
      {bool read = false}) {
    DartType staticType1 = _getExpressionType(expr1, read: read);
    DartType staticType2 = _getExpressionType(expr2, read: read);

    _analyzeLeastUpperBoundTypes(node, staticType1, staticType2);
  }

  /// Set the static type of [node] to be the least upper bound of the static
  /// types [staticType1] and [staticType2].
  ///
  /// TODO(scheglov) this is duplicate
  void _analyzeLeastUpperBoundTypes(
      Expression node, DartType staticType1, DartType staticType2) {
    if (staticType1 == null) {
      // TODO(brianwilkerson) Determine whether this can still happen.
      staticType1 = DynamicTypeImpl.instance;
    }

    if (staticType2 == null) {
      // TODO(brianwilkerson) Determine whether this can still happen.
      staticType2 = DynamicTypeImpl.instance;
    }

    DartType staticType =
        _typeSystem.getLeastUpperBound(staticType1, staticType2) ??
            DynamicTypeImpl.instance;

    staticType = _resolver.toLegacyTypeIfOptOut(staticType);

    _inferenceHelper.recordStaticType(node, staticType);
  }

  /// Gets the definite type of expression, which can be used in cases where
  /// the most precise type is desired, for example computing the least upper
  /// bound.
  ///
  /// See [getExpressionType] for more information. Without strong mode, this is
  /// equivalent to [_getStaticType].
  ///
  /// TODO(scheglov) this is duplicate
  DartType _getExpressionType(Expression expr, {bool read = false}) =>
      getExpressionType(expr, _typeSystem, _typeProvider,
          read: read, elementTypeProvider: _elementTypeProvider);

  /// Return the static type of the given [expression] that is to be used for
  /// type analysis.
  ///
  /// TODO(scheglov) this is duplicate
  DartType _getStaticType(Expression expression, {bool read = false}) {
    if (expression is NullLiteral) {
      return _typeProvider.nullType;
    }
    DartType type = read
        ? getReadType(expression, elementTypeProvider: _elementTypeProvider)
        : expression.staticType;
    return _resolveTypeParameter(type);
  }

  void _resolve1(BinaryExpressionImpl node) {
    Token operator = node.operator;
    if (operator.isUserDefinableOperator) {
      _resolveBinaryExpression(node, operator.lexeme);
    } else if (operator.type == TokenType.BANG_EQ) {
      _resolveBinaryExpression(node, TokenType.EQ_EQ.lexeme);
    }
  }

  void _resolve2(BinaryExpressionImpl node) {
    if (node.operator.type == TokenType.QUESTION_QUESTION) {
      if (_isNonNullableByDefault) {
        // The static type of a compound assignment using ??= with NNBD is the
        // least upper bound of the static types of the LHS and RHS after
        // promoting the LHS/ to non-null (as we know its value will not be used
        // if null)
        _analyzeLeastUpperBoundTypes(
            node,
            _typeSystem.promoteToNonNull(
                _getExpressionType(node.leftOperand, read: true)),
            _getExpressionType(node.rightOperand, read: true));
      } else {
        // Without NNBD, evaluation of an if-null expression e of the form
        // e1 ?? e2 is equivalent to the evaluation of the expression
        // ((x) => x == null ? e2 : x)(e1).  The static type of e is the least
        // upper bound of the static type of e1 and the static type of e2.
        _analyzeLeastUpperBound(node, node.leftOperand, node.rightOperand);
      }
      return;
    }

    if (identical(node.leftOperand.staticType, NeverTypeImpl.instance)) {
      _inferenceHelper.recordStaticType(node, NeverTypeImpl.instance);
      return;
    }

    DartType staticType =
        node.staticInvokeType?.returnType ?? DynamicTypeImpl.instance;
    if (node.leftOperand is! ExtensionOverride) {
      staticType = _typeSystem.refineBinaryExpressionType(
        _getStaticType(node.leftOperand),
        node.operator.type,
        node.rightOperand.staticType,
        staticType,
      );
    }
    _inferenceHelper.recordStaticType(node, staticType);
  }

  void _resolveBinaryExpression(BinaryExpression node, String methodName) {
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

    var leftType = _getStaticType(leftOperand);

    if (identical(leftType, NeverTypeImpl.instance)) {
      _resolver.errorReporter.reportErrorForNode(
        StaticWarningCode.INVALID_USE_OF_NEVER_VALUE,
        leftOperand,
      );
      return;
    }

    ResolutionResult result = _typePropertyResolver.resolve(
      receiver: leftOperand,
      receiverType: leftType,
      name: methodName,
      receiverErrorNode: leftOperand,
      nameErrorNode: node,
    );

    node.staticElement = result.getter;
    node.staticInvokeType =
        _elementTypeProvider.safeExecutableType(result.getter);
    if (_shouldReportInvalidMember(leftType, result)) {
      if (leftOperand is SuperExpression) {
        _errorReporter.reportErrorForToken(
          StaticTypeWarningCode.UNDEFINED_SUPER_OPERATOR,
          node.operator,
          [methodName, leftType],
        );
      } else {
        _errorReporter.reportErrorForToken(
          StaticTypeWarningCode.UNDEFINED_OPERATOR,
          node.operator,
          [methodName, leftType],
        );
      }
    }
  }

  /// If the given [type] is a type parameter, resolve it to the type that should
  /// be used when looking up members. Otherwise, return the original type.
  ///
  /// TODO(scheglov) this is duplicate
  DartType _resolveTypeParameter(DartType type) =>
      type?.resolveToBound(_typeProvider.objectType);

  /// Return `true` if we should report an error for the lookup [result] on
  /// the [type].
  ///
  /// TODO(scheglov) this is duplicate
  bool _shouldReportInvalidMember(DartType type, ResolutionResult result) {
    if (result.isNone && type != null && !type.isDynamic) {
      if (_isNonNullableByDefault && _typeSystem.isPotentiallyNullable(type)) {
        return false;
      }
      return true;
    }
    return false;
  }
}
