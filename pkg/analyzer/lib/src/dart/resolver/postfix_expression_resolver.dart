// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/dart/resolver/assignment_expression_resolver.dart';
import 'package:analyzer/src/dart/resolver/invocation_inferrer.dart';
import 'package:analyzer/src/dart/resolver/type_property_resolver.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// Helper for resolving [PostfixExpression]s.
class PostfixExpressionResolver {
  final ResolverVisitor _resolver;
  final TypePropertyResolver _typePropertyResolver;
  final AssignmentExpressionShared _assignmentShared;

  PostfixExpressionResolver({required ResolverVisitor resolver})
    : _resolver = resolver,
      _typePropertyResolver = resolver.typePropertyResolver,
      _assignmentShared = AssignmentExpressionShared(resolver: resolver);

  DiagnosticReporter get _diagnosticReporter => _resolver.diagnosticReporter;

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

  void resolve(PostfixExpressionImpl node, {required TypeImpl contextType}) {
    if (node.operator.type == TokenType.BANG) {
      _resolveNullCheck(node, contextType: contextType);
      return;
    }

    var operandResolution = _resolver.resolveForWrite(
      node: node.operand,
      hasRead: true,
    );

    var readElement = operandResolution.readElement2;
    var writeElement = operandResolution.writeElement2;

    var operand = node.operand;
    _resolver.setReadElement(
      operand,
      readElement,
      atDynamicTarget: operandResolution.atDynamicTarget,
    );
    _resolver.setWriteElement(
      operand,
      writeElement,
      atDynamicTarget: operandResolution.atDynamicTarget,
    );

    // TODO(scheglov): Use VariableElement and do in resolveForWrite() ?
    _assignmentShared.checkFinalAlreadyAssigned(operand);

    var receiverType = node.readType!;
    _resolve1(node, receiverType);
    _resolve2(node, receiverType);
  }

  /// Check that the result [type] of a prefix or postfix `++` or `--`
  /// expression is assignable to the write type of the [operand].
  ///
  // TODO(scheglov): this is duplicate
  void _checkForInvalidAssignmentIncDec(
    PostfixExpressionImpl node,
    Expression operand,
    TypeImpl type,
  ) {
    var operandWriteType = node.writeType!;
    if (!_typeSystem.isAssignableTo(
      type,
      operandWriteType,
      strictCasts: _resolver.analysisOptions.strictCasts,
    )) {
      _resolver.diagnosticReporter.atNode(
        node,
        CompileTimeErrorCode.invalidAssignment,
        arguments: [type, operandWriteType],
      );
    }
  }

  /// Compute the static return type of the method or function represented by the given element.
  ///
  /// @param element the element representing the method or function invoked by the given node
  /// @return the static return type that was computed
  ///
  // TODO(scheglov): this is duplicate
  TypeImpl _computeStaticReturnType(Element? element) {
    if (element is PropertyAccessorElement) {
      //
      // This is a function invocation expression disguised as something else.
      // We are invoking a getter and then invoking the returned function.
      //
      FunctionType propertyType = element.type;
      return InvocationInferrer.computeInvokeReturnType(
        propertyType.returnType,
      );
    } else if (element is ExecutableElement) {
      return InvocationInferrer.computeInvokeReturnType(element.type);
    }
    return DynamicTypeImpl.instance;
  }

  /// Return the name of the method invoked by the given postfix [expression].
  String _getPostfixOperator(PostfixExpression expression) {
    if (expression.operator.type == TokenType.PLUS_PLUS) {
      return TokenType.PLUS.lexeme;
    } else if (expression.operator.type == TokenType.MINUS_MINUS) {
      return TokenType.MINUS.lexeme;
    } else {
      throw UnsupportedError(
        'Unsupported postfix operator ${expression.operator.lexeme}',
      );
    }
  }

  void _resolve1(PostfixExpressionImpl node, TypeImpl receiverType) {
    ExpressionImpl operand = node.operand;

    if (identical(receiverType, NeverTypeImpl.instance)) {
      _resolver.diagnosticReporter.atNode(
        operand,
        WarningCode.receiverOfTypeNever,
      );
      return;
    }

    String methodName = _getPostfixOperator(node);
    var result = _typePropertyResolver.resolve(
      receiver: operand,
      receiverType: receiverType,
      name: methodName,
      hasRead: true,
      hasWrite: false,
      propertyErrorEntity: node.operator,
      nameErrorEntity: operand,
    );
    node.element = result.getter2 as MethodElement?;
    if (result.needsGetterError) {
      if (operand is SuperExpression) {
        _diagnosticReporter.atToken(
          node.operator,
          CompileTimeErrorCode.undefinedSuperOperator,
          arguments: [methodName, receiverType],
        );
      } else {
        _diagnosticReporter.atToken(
          node.operator,
          CompileTimeErrorCode.undefinedOperator,
          arguments: [methodName, receiverType],
        );
      }
    }
  }

  void _resolve2(PostfixExpressionImpl node, TypeImpl receiverType) {
    Expression operand = node.operand;

    if (identical(receiverType, NeverTypeImpl.instance)) {
      node.recordStaticType(NeverTypeImpl.instance, resolver: _resolver);
    } else {
      TypeImpl operatorReturnType;
      if (receiverType.isDartCoreInt) {
        // No need to check for `intVar++`, the result is `int`.
        operatorReturnType = receiverType;
      } else {
        var operatorElement = node.element;
        operatorReturnType = _computeStaticReturnType(operatorElement);
        _checkForInvalidAssignmentIncDec(node, operand, operatorReturnType);
      }
      if (operand is SimpleIdentifier) {
        var element = operand.element;
        if (element is PromotableElementImpl) {
          if (_resolver.definingLibrary.featureSet.isEnabled(
            Feature.inference_update_4,
          )) {
            _resolver.flowAnalysis.flow?.postIncDec(
              node,
              element,
              SharedTypeView(operatorReturnType),
            );
          } else {
            _resolver.flowAnalysis.flow?.write(
              node,
              element,
              SharedTypeView(operatorReturnType),
              null,
            );
          }
        }
      }
      node.recordStaticType(receiverType, resolver: _resolver);
    }
  }

  void _resolveNullCheck(
    PostfixExpressionImpl node, {
    required TypeImpl contextType,
  }) {
    var operand = node.operand;

    if (operand is SuperExpression) {
      _resolver.diagnosticReporter.atNode(
        node,
        ParserErrorCode.missingAssignableSelector,
      );
      operand.setPseudoExpressionStaticType(DynamicTypeImpl.instance);
      node.recordStaticType(DynamicTypeImpl.instance, resolver: _resolver);
      return;
    }

    _resolver.analyzeExpression(
      operand,
      SharedTypeSchemaView(_typeSystem.makeNullable(contextType)),
      continueNullShorting: true,
    );
    operand = _resolver.popRewrite()!;

    var operandType = operand.typeOrThrow;

    var type = _typeSystem.promoteToNonNull(operandType);
    node.recordStaticType(type, resolver: _resolver);

    _resolver.flowAnalysis.flow?.nonNullAssert_end(operand);
  }
}
