// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';

class RelationalPatternResolver {
  final ResolverVisitor resolverVisitor;

  RelationalPatternResolver(this.resolverVisitor);

  ErrorReporter get errorReporter => resolverVisitor.errorReporter;

  TypeProviderImpl get typeProvider => typeSystem.typeProvider;

  TypeSystemImpl get typeSystem => resolverVisitor.typeSystem;

  void resolve({
    required RelationalPatternImpl node,
    required DartType matchedType,
  }) {
    resolveExpression(node.operand, matchedType);

    final operatorLexeme = node.operator.lexeme;
    final isEqEq = const {'==', '!='}.contains(operatorLexeme);
    final methodName = isEqEq ? '==' : operatorLexeme;

    final result = resolverVisitor.typePropertyResolver.resolve(
      receiver: null,
      receiverType: matchedType,
      name: methodName,
      propertyErrorEntity: node.operator,
      nameErrorEntity: node,
    );

    if (result.needsGetterError) {
      errorReporter.reportErrorForToken(
        CompileTimeErrorCode.UNDEFINED_OPERATOR,
        node.operator,
        [methodName, matchedType],
      );
    }

    final element = result.getter as MethodElement?;
    node.element = element;

    if (element != null) {
      final parameterType = element.firstParameterType;
      if (parameterType != null) {
        final operandType = node.operand.typeOrThrow;
        final argumentType =
            isEqEq ? typeSystem.promoteToNonNull(operandType) : operandType;
        if (!typeSystem.isAssignableTo(argumentType, parameterType)) {
          errorReporter.reportErrorForNode(
            CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE,
            node.operand,
            [argumentType, parameterType],
          );
        }
      }

      final returnType = element.returnType;
      if (!typeSystem.isAssignableTo(returnType, typeProvider.boolType)) {
        errorReporter.reportErrorForToken(
          CompileTimeErrorCode
              .RELATIONAL_PATTERN_OPERATOR_RETURN_TYPE_NOT_ASSIGNABLE_TO_BOOL,
          node.operator,
        );
      }
    }
  }

  /// Resolves the expression [node], using [contextType] as the type schema
  /// which should be used for type inference.
  ///
  /// Returns the rewritten (or the original) expression.
  ExpressionImpl? resolveExpression(
    ExpressionImpl node,
    DartType contextType,
  ) {
    resolverVisitor.analyzeExpression(node, contextType);
    return resolverVisitor.popRewrite();
  }
}
