// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/resolver/type_property_resolver.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/listener.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// Helper for resolving [UnaryOperatorInvocation]s.
class UnaryOperatorInvocationResolver {
  final ResolverVisitor _resolver;
  final TypePropertyResolver _typePropertyResolver;

  UnaryOperatorInvocationResolver(this._resolver)
    : _typePropertyResolver = _resolver.typePropertyResolver;

  void resolve(
    UnaryOperatorInvocationImpl node, {
    required TypeImpl contextType,
  }) {
    var operand = node.operand as ExpressionImpl;
    var innerContextType =
        node.unaryOperator == UnaryOperator.negate &&
            operand is IntegerLiteralImpl
        ? contextType
        : UnknownInferredType.instance;
    _resolver.analyzeExpression(
      operand,
      SharedTypeSchemaView(innerContextType),
    );
    operand = _resolver.popRewrite()!;

    node.element = null;
    TypeImpl type;
    if (operand is ExtensionOverrideImpl) {
      node.element = _resolveElement(node, operand, null);
      type = node.element?.returnType ?? InvalidTypeImpl.instance;
    } else {
      var operandType = operand.typeOrThrow;
      if (operandType is DynamicTypeImpl) {
        type = DynamicTypeImpl.instance;
      } else if (operandType is InvalidTypeImpl) {
        type = InvalidTypeImpl.instance;
      } else if (identical(operandType, NeverTypeImpl.instance)) {
        _resolver.diagnosticReporter.report(
          diag.receiverOfTypeNever.at(operand),
        );
        type = NeverTypeImpl.instance;
      } else {
        node.element = _resolveElement(node, operand, operandType);
        type = node.element?.returnType ?? InvalidTypeImpl.instance;
      }
    }

    node.recordStaticType(type, resolver: _resolver);
  }

  InternalMethodElement? _resolveElement(
    UnaryOperatorInvocationImpl node,
    ExpressionImpl operand,
    TypeImpl? operandType,
  ) {
    var methodName = switch (node.unaryOperator) {
      UnaryOperator.negate => 'unary-',
      UnaryOperator.bitwiseComplement => '~',
    };

    if (operand is ExtensionOverrideImpl) {
      var extension = operand.element;
      var member = extension.getMethod(methodName);
      if (member == null) {
        // Extension overrides always refer to named extensions.
        _resolver.diagnosticReporter.report(
          diag.undefinedExtensionOperator
              .withArguments(
                operator: methodName,
                extensionName: extension.name!,
              )
              .at(node.operator),
        );
      }
      return member;
    }

    var result = _typePropertyResolver.resolve(
      receiver: operand,
      receiverType: operandType!,
      name: methodName,
      hasRead: true,
      hasWrite: false,
      propertyErrorEntity: node.operator,
      nameErrorEntity: operand,
    );
    var element = result.getter2 as InternalMethodElement?;
    if (result.needsGetterError) {
      if (operand is SuperExpression) {
        _resolver.diagnosticReporter.report(
          diag.undefinedSuperOperator
              .withArguments(operator: methodName, type: operandType)
              .at(node.operator),
        );
      } else {
        _resolver.diagnosticReporter.report(
          diag.undefinedOperator
              .withArguments(operator: methodName, type: operandType)
              .at(node.operator),
        );
      }
    }
    return element;
  }
}
