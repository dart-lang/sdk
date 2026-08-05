// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/assignment_expression_resolver.dart';
import 'package:analyzer/src/dart/resolver/invocation_inferrer.dart';
import 'package:analyzer/src/dart/resolver/type_property_resolver.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/listener.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// Helper for resolving prefix and postfix increment and decrement expressions.
class IncrementOrDecrementResolver {
  final ResolverVisitor _resolver;
  final TypePropertyResolver _typePropertyResolver;
  final AssignmentExpressionShared _assignmentShared;

  IncrementOrDecrementResolver({required ResolverVisitor resolver})
    : _resolver = resolver,
      _typePropertyResolver = resolver.typePropertyResolver,
      _assignmentShared = AssignmentExpressionShared(resolver: resolver);

  DiagnosticReporter get _diagnosticReporter => _resolver.diagnosticReporter;

  TypeProviderImpl get _typeProvider => _resolver.typeProvider;

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

  void resolve(IncrementOrDecrementExpressionImpl node) {
    var operand = node.operand;
    var operandResolution = _resolver.resolveForWrite(
      node: operand,
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

    // TODO(scheglov): Use VariableElement and do in resolveForWrite()?
    _assignmentShared.checkFinalAlreadyAssigned(operand);

    var isPrefix = _isPrefix(node);
    _resolveOperator(node, isPrefix: isPrefix);
    _resolveResult(node, isPrefix: isPrefix);
  }

  /// Check that the result [type] of a `++` or `--` expression is assignable
  /// to the write type of the operand.
  void _checkForInvalidAssignmentIncDec(
    IncrementOrDecrementExpressionImpl node,
    TypeImpl type,
  ) {
    var operandWriteType = node.writeType!;
    if (!_typeSystem.isAssignableTo(
      type,
      operandWriteType,
      strictCasts: _resolver.analysisOptions.strictCasts,
    )) {
      _resolver.diagnosticReporter.report(
        diag.invalidAssignment
            .withArguments(
              actualStaticType: type,
              expectedStaticType: operandWriteType,
            )
            .at(node),
      );
    }
  }

  /// Compute the static return type of the method or function represented by
  /// [element].
  TypeImpl _computeStaticReturnType(Element? element, TypeImpl fallback) {
    if (element is PropertyAccessorElement) {
      // This is a function invocation expression disguised as something else.
      // We are invoking a getter and then invoking the returned function.
      var propertyType = element.type;
      return InvocationInferrer.computeInvokeReturnType(
        propertyType.returnType,
      );
    } else if (element is ExecutableElement) {
      return InvocationInferrer.computeInvokeReturnType(element.type);
    }
    return fallback;
  }

  /// Return the name of the method invoked by the given [expression].
  String _getOperator(IncrementOrDecrementExpression expression) {
    return switch (expression) {
      PrefixIncrement() || PostfixIncrement() => TokenType.PLUS.lexeme,
      PrefixDecrement() || PostfixDecrement() => TokenType.MINUS.lexeme,
      _ => throw StateError('Expected an increment or decrement expression'),
    };
  }

  bool _isPrefix(IncrementOrDecrementExpression expression) {
    return switch (expression) {
      PrefixIncrement() || PrefixDecrement() => true,
      PostfixIncrement() || PostfixDecrement() => false,
      _ => throw StateError('Expected an increment or decrement expression'),
    };
  }

  void _resolveOperator(
    IncrementOrDecrementExpressionImpl node, {
    required bool isPrefix,
  }) {
    var operator = node.operator;
    var operand = node.operand;
    var methodName = _getOperator(node);

    // TODO(scheglov): Review why only prefix increment and decrement handle an
    // extension override by looking up the operator directly.
    if (isPrefix && operand is ExtensionOverrideImpl) {
      var element = operand.element;
      var member = element.getMethod(methodName);
      if (member == null) {
        // Extension overrides always refer to named extensions, so we can
        // safely assume `element.name` is non-`null`.
        _diagnosticReporter.report(
          diag.undefinedExtensionOperator
              .withArguments(operator: methodName, extensionName: element.name!)
              .at(node.operator),
        );
      }
      node.element = member;
      return;
    }

    // TODO(scheglov): Review why prefix recovery falls back to the operand
    // type, while postfix resolution requires `readType` to be set.
    var readType = isPrefix
        ? node.readType ?? operand.typeOrThrow
        : node.readType!;

    // TODO(scheglov): Review why an invalid read type stops operator lookup
    // only for prefix increment and decrement.
    if (isPrefix && readType is InvalidType) {
      return;
    }
    if (identical(readType, NeverTypeImpl.instance)) {
      _resolver.diagnosticReporter.report(diag.receiverOfTypeNever.at(operand));
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
    node.element = result.getter2 as InternalMethodElement?;
    if (result.needsGetterError) {
      if (operand is SuperExpression) {
        _diagnosticReporter.report(
          diag.undefinedSuperOperator
              .withArguments(operator: methodName, type: readType)
              .at(operator),
        );
      } else {
        _diagnosticReporter.report(
          diag.undefinedOperator
              .withArguments(operator: methodName, type: readType)
              .at(operator),
        );
      }
    }
  }

  void _resolveResult(
    IncrementOrDecrementExpressionImpl node, {
    required bool isPrefix,
  }) {
    var operandImpl = node.operand;
    Expression operand = operandImpl;

    // TODO(scheglov): Review why prefix recovery falls back to `staticType`,
    // while postfix resolution requires `readType` to be set.
    var readType = isPrefix
        ? node.readType ?? operandImpl.staticType
        : node.readType!;

    if (identical(readType, NeverTypeImpl.instance)) {
      node.operatorResultType = NeverTypeImpl.instance;
      node.recordStaticType(NeverTypeImpl.instance, resolver: _resolver);
      return;
    }

    TypeImpl operatorResultType;
    if (isPrefix && readType is DynamicType) {
      operatorResultType = DynamicTypeImpl.instance;
    } else if (isPrefix && readType is InvalidType) {
      operatorResultType = InvalidTypeImpl.instance;
    } else if (readType!.isDartCoreInt) {
      operatorResultType = isPrefix ? _typeProvider.intType : readType;
    } else {
      // TODO(scheglov): Review why a missing operator element produces an
      // invalid type for prefix expressions but `dynamic` for postfix ones.
      var fallback = isPrefix
          ? InvalidTypeImpl.instance
          : DynamicTypeImpl.instance;
      operatorResultType = _computeStaticReturnType(node.element, fallback);
    }

    // TODO(scheglov): Review why only prefix extension overrides skip the
    // write-back assignability check and flow-model update.
    if (!(isPrefix && operand is ExtensionOverride)) {
      _checkForInvalidAssignmentIncDec(node, operatorResultType);
      if (operand is SimpleIdentifier) {
        var element = operand.element;
        if (element is PromotableElementImpl) {
          if (isPrefix) {
            _resolver.flowAnalysis.storeExpressionInfo(
              node,
              _resolver.flowAnalysis.flow?.write(
                node,
                element,
                SharedTypeView(operatorResultType),
                null,
              ),
            );
          } else {
            _resolver.flowAnalysis.flow?.postIncDec(
              node,
              element,
              SharedTypeView(operatorResultType),
            );
          }
        }
      }
    }

    node.operatorResultType = operatorResultType;
    node.recordStaticType(
      isPrefix ? operatorResultType : readType!,
      resolver: _resolver,
    );
  }
}
