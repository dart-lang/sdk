// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/resolver/type_analyzer.dart';
import 'package:analyzer/src/dart/resolver/type_property_resolver.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/listener.dart';

/// Helper for resolving [UnaryOperatorInvocation]s.
class UnaryOperatorInvocationResolver {
  final TypeAnalyzer _typeAnalyzer;
  final TypePropertyResolver _typePropertyResolver;

  UnaryOperatorInvocationResolver(this._typeAnalyzer)
    : _typePropertyResolver = _typeAnalyzer.typePropertyResolver;

  void resolve(
    UnaryOperatorInvocationImpl node, {
    required TypeImpl contextType,
  }) {
    var operand = node.operand;
    var innerContextType =
        node.unaryOperator == UnaryOperator.negate &&
            operand is IntegerLiteralImpl
        ? contextType
        : UnknownInferredType.instance;
    operand = _typeAnalyzer.analyzeInstanceReceiver(
      operand,
      contextType: innerContextType,
    );

    node.element = null;
    TypeImpl type;
    switch (operand) {
      case ExpressionImpl():
      case SuperReferenceImpl():
        var operandType = _typeAnalyzer.instanceReceiverType(operand);
        if (operandType is DynamicTypeImpl) {
          type = DynamicTypeImpl.instance;
        } else if (operandType is InvalidTypeImpl) {
          type = InvalidTypeImpl.instance;
        } else if (identical(operandType, NeverTypeImpl.instance)) {
          _typeAnalyzer.diagnosticReporter.report(
            diag.receiverOfTypeNever.at(operand),
          );
          type = NeverTypeImpl.instance;
        } else {
          node.element = _resolveElement(node, operand, operandType);
          type = node.element?.returnType ?? InvalidTypeImpl.instance;
        }
      case ExtensionOverride2Impl():
        node.element = _resolveElement(node, operand, null);
        type = node.element?.returnType ?? InvalidTypeImpl.instance;
    }

    node.recordStaticType(type, typeAnalyzer: _typeAnalyzer);
  }

  InternalMethodElement? _resolveElement(
    UnaryOperatorInvocationImpl node,
    InstanceReceiverImpl operand,
    TypeImpl? operandType,
  ) {
    var methodName = switch (node.unaryOperator) {
      UnaryOperator.negate => 'unary-',
      UnaryOperator.bitwiseComplement => '~',
    };

    switch (operand) {
      case ExpressionImpl():
      case SuperReferenceImpl():
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
          if (operand is SuperReference) {
            _typeAnalyzer.diagnosticReporter.report(
              diag.undefinedSuperOperator
                  .withArguments(operator: methodName, type: operandType)
                  .at(node.operator),
            );
          } else {
            _typeAnalyzer.diagnosticReporter.report(
              diag.undefinedOperator
                  .withArguments(operator: methodName, type: operandType)
                  .at(node.operator),
            );
          }
        }
        return element;
      case ExtensionOverride2Impl():
        var extension = operand.element;
        var member = extension.getMethod(methodName);
        if (member == null) {
          // Extension overrides always refer to named extensions.
          _typeAnalyzer.diagnosticReporter.report(
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
  }
}
