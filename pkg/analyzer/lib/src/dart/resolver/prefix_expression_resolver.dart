// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/assignment_expression_resolver.dart';
import 'package:analyzer/src/dart/resolver/invocation_inferrer.dart';
import 'package:analyzer/src/dart/resolver/type_property_resolver.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// Helper for resolving [PrefixExpression]s.
class PrefixExpressionResolver {
  final ResolverVisitor _resolver;
  final TypePropertyResolver _typePropertyResolver;
  final AssignmentExpressionShared _assignmentShared;

  PrefixExpressionResolver({required ResolverVisitor resolver})
    : _resolver = resolver,
      _typePropertyResolver = resolver.typePropertyResolver,
      _assignmentShared = AssignmentExpressionShared(resolver: resolver);

  DiagnosticReporter get _diagnosticReporter => _resolver.diagnosticReporter;

  TypeProviderImpl get _typeProvider => _resolver.typeProvider;

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

  void resolve(PrefixExpressionImpl node, {required TypeImpl contextType}) {
    var operator = node.operator.type;

    if (operator == TokenType.BANG) {
      _resolveNegation(node);
      return;
    }

    var operand = node.operand;
    if (operator.isIncrementOperator) {
      var operandResolution = _resolver.resolveForWrite(
        node: node.operand,
        hasRead: true,
      );

      var readElement = operandResolution.readElement2;
      var writeElement = operandResolution.writeElement2;

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

      _assignmentShared.checkFinalAlreadyAssigned(node.operand);
    } else {
      TypeImpl innerContextType;
      if (operator == TokenType.MINUS && operand is IntegerLiteralImpl) {
        // Negated integer literals should undergo int->double conversion in the
        // same circumstances as non-negated integer literals, so pass the
        // context type through.
        innerContextType = contextType;
      } else {
        innerContextType = UnknownInferredType.instance;
      }
      _resolver.analyzeExpression(
        operand,
        SharedTypeSchemaView(innerContextType),
      );
      _resolver.popRewrite();
    }

    _resolve1(node);
    _resolve2(node);
  }

  /// Check that the result [type] of a prefix or postfix `++` or `--`
  /// expression is assignable to the write type of the operand.
  ///
  // TODO(scheglov): this is duplicate
  void _checkForInvalidAssignmentIncDec(
    PrefixExpressionImpl node,
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
      var propertyType = element.type;
      return InvocationInferrer.computeInvokeReturnType(
        propertyType.returnType,
      );
    } else if (element is ExecutableElement) {
      return InvocationInferrer.computeInvokeReturnType(element.type);
    }
    return InvalidTypeImpl.instance;
  }

  /// Return the name of the method invoked by the given postfix [expression].
  String _getPrefixOperator(PrefixExpression expression) {
    var operator = expression.operator;
    var operatorType = operator.type;
    if (operatorType == TokenType.PLUS_PLUS) {
      return TokenType.PLUS.lexeme;
    } else if (operatorType == TokenType.MINUS_MINUS) {
      return TokenType.MINUS.lexeme;
    } else if (operatorType == TokenType.MINUS) {
      return "unary-";
    } else {
      return operator.lexeme;
    }
  }

  void _resolve1(PrefixExpressionImpl node) {
    Token operator = node.operator;
    TokenType operatorType = operator.type;
    if (operatorType.isUserDefinableOperator ||
        operatorType.isIncrementOperator) {
      ExpressionImpl operand = node.operand;
      String methodName = _getPrefixOperator(node);
      if (operand is ExtensionOverrideImpl) {
        var element = operand.element;
        var member = element.getMethod(methodName);
        if (member == null) {
          // Extension overrides always refer to named extensions, so we can
          // safely assume `element.name` is non-`null`.
          _diagnosticReporter.atToken(
            node.operator,
            CompileTimeErrorCode.undefinedExtensionOperator,
            arguments: [methodName, element.name!],
          );
        }
        node.element = member;
        return;
      }

      var readType = node.readType ?? operand.typeOrThrow;
      if (readType is InvalidType) {
        return;
      }
      if (identical(readType, NeverTypeImpl.instance)) {
        _resolver.diagnosticReporter.atNode(
          operand,
          WarningCode.receiverOfTypeNever,
        );
        return;
      }

      var result = _typePropertyResolver.resolve(
        receiver: operand,
        receiverType: readType,
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
            operator,
            CompileTimeErrorCode.undefinedSuperOperator,
            arguments: [methodName, readType],
          );
        } else {
          _diagnosticReporter.atToken(
            operator,
            CompileTimeErrorCode.undefinedOperator,
            arguments: [methodName, readType],
          );
        }
      }
    }
  }

  void _resolve2(PrefixExpressionImpl node) {
    TokenType operator = node.operator.type;
    var readType = node.readType ?? node.operand.staticType;
    if (identical(readType, NeverTypeImpl.instance)) {
      node.recordStaticType(NeverTypeImpl.instance, resolver: _resolver);
    } else {
      // The other cases are equivalent to invoking a method.
      TypeImpl staticType;
      if (readType is DynamicType) {
        staticType = DynamicTypeImpl.instance;
      } else if (readType is InvalidType) {
        staticType = InvalidTypeImpl.instance;
      } else {
        var staticMethodElement = node.element;
        staticType = _computeStaticReturnType(staticMethodElement);
      }
      Expression operand = node.operand;
      if (operand is ExtensionOverride) {
        // No special handling for incremental operators.
      } else if (operator.isIncrementOperator) {
        if (readType!.isDartCoreInt) {
          staticType = _typeProvider.intType;
        } else {
          _checkForInvalidAssignmentIncDec(node, staticType);
        }
        if (operand is SimpleIdentifier) {
          var element = operand.element;
          if (element is PromotableElementImpl) {
            _resolver.flowAnalysis.flow?.write(
              node,
              element,
              SharedTypeView(staticType),
              null,
            );
          }
        }
      }
      node.recordStaticType(staticType, resolver: _resolver);
    }
  }

  void _resolveNegation(PrefixExpressionImpl node) {
    var operand = node.operand;

    _resolver.analyzeExpression(
      operand,
      SharedTypeSchemaView(_typeProvider.boolType),
    );
    operand = _resolver.popRewrite()!;
    var whyNotPromoted = _resolver.flowAnalysis.flow?.whyNotPromoted(operand);

    _resolver.boolExpressionVerifier.checkForNonBoolNegationExpression(
      operand,
      whyNotPromoted: whyNotPromoted,
    );

    node.recordStaticType(_typeProvider.boolType, resolver: _resolver);

    _resolver.flowAnalysis.flow?.logicalNot_end(node, operand);
  }
}
