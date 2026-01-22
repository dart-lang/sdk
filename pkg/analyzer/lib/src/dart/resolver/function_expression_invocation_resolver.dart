// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/extension_member_resolver.dart';
import 'package:analyzer/src/dart/resolver/invocation_inferrer.dart';
import 'package:analyzer/src/dart/resolver/type_property_resolver.dart';
import 'package:analyzer/src/dart/type_instantiation_target.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/listener.dart';
import 'package:analyzer/src/error/nullable_dereference_verifier.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// Helper for resolving [FunctionExpressionInvocation]s.
class FunctionExpressionInvocationResolver {
  final ResolverVisitor _resolver;
  final TypePropertyResolver _typePropertyResolver;

  FunctionExpressionInvocationResolver({required ResolverVisitor resolver})
    : _resolver = resolver,
      _typePropertyResolver = resolver.typePropertyResolver;

  DiagnosticReporter get _diagnosticReporter => _resolver.diagnosticReporter;

  ExtensionMemberResolver get _extensionResolver => _resolver.extensionResolver;

  NullableDereferenceVerifier get _nullableDereferenceVerifier =>
      _resolver.nullableDereferenceVerifier;

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

  void resolve(
    FunctionExpressionInvocationImpl node,
    List<WhyNotPromotedGetter> whyNotPromotedArguments, {
    required TypeImpl contextType,
  }) {
    var function = node.function;

    if (function is ExtensionOverrideImpl) {
      _resolveReceiverExtensionOverride(
        node,
        function,
        whyNotPromotedArguments,
        contextType: contextType,
      );
      return;
    }

    var receiverType = function.typeOrThrow;
    if (_checkForUseOfVoidResult(function, receiverType)) {
      _unresolved(
        node,
        DynamicTypeImpl.instance,
        whyNotPromotedArguments,
        contextType: contextType,
      );
      return;
    }

    receiverType = _typeSystem.resolveToBound(receiverType);
    if (receiverType is FunctionTypeImpl) {
      _nullableDereferenceVerifier.expression(
        diag.uncheckedInvocationOfNullableValue,
        function,
      );
      _resolve(
        node,
        whyNotPromotedArguments,
        contextType: contextType,
        target: InvocationTargetFunctionTypedExpression(receiverType),
      );
      return;
    }

    if (identical(receiverType, NeverTypeImpl.instance)) {
      _diagnosticReporter.report(diag.receiverOfTypeNever.at(function));
      _unresolved(
        node,
        NeverTypeImpl.instance,
        whyNotPromotedArguments,
        contextType: contextType,
      );
      return;
    }

    var result = _typePropertyResolver.resolve(
      receiver: function,
      receiverType: receiverType,
      name: MethodElement.CALL_METHOD_NAME,
      hasRead: true,
      hasWrite: false,
      propertyErrorEntity: function,
      nameErrorEntity: function,
    );
    var callElement = result.getter2;

    if (callElement == null) {
      if (result.needsGetterError) {
        _diagnosticReporter.report(
          diag.invocationOfNonFunctionExpression.at(function),
        );
      }
      var type = result.isGetterInvalid
          ? InvalidTypeImpl.instance
          : DynamicTypeImpl.instance;
      _unresolved(
        node,
        type,
        whyNotPromotedArguments,
        contextType: contextType,
      );
      return;
    }

    if (callElement.kind != ElementKind.METHOD) {
      _diagnosticReporter.report(
        diag.invocationOfNonFunctionExpression.at(function),
      );
      _unresolved(
        node,
        InvalidTypeImpl.instance,
        whyNotPromotedArguments,
        contextType: contextType,
      );
      return;
    }

    node.element = callElement;
    _resolve(
      node,
      whyNotPromotedArguments,
      contextType: contextType,
      target: InvocationTargetExecutableElement(callElement),
    );
  }

  /// Check for situations where the result of a method or function is used,
  /// when it returns 'void'. Or, in rare cases, when other types of expressions
  /// are void, such as identifiers.
  ///
  /// See [diag.useOfVoidResult].
  ///
  // TODO(scheglov): this is duplicate
  bool _checkForUseOfVoidResult(Expression expression, DartType type) {
    if (!identical(type, VoidTypeImpl.instance)) {
      return false;
    }

    if (expression is MethodInvocation) {
      SimpleIdentifier methodName = expression.methodName;
      _diagnosticReporter.report(diag.useOfVoidResult.at(methodName));
    } else {
      _diagnosticReporter.report(diag.useOfVoidResult.at(expression));
    }

    return true;
  }

  void _resolve(
    FunctionExpressionInvocationImpl node,
    List<WhyNotPromotedGetter> whyNotPromotedArguments, {
    required TypeImpl contextType,
    required InvocationTarget target,
  }) {
    var returnType = FunctionExpressionInvocationInferrer(
      resolver: _resolver,
      node: node,
      argumentList: node.argumentList,
      whyNotPromotedArguments: whyNotPromotedArguments,
      contextType: contextType,
      target: target,
    ).resolveInvocation();

    node.recordStaticType(returnType, resolver: _resolver);
  }

  void _resolveReceiverExtensionOverride(
    FunctionExpressionInvocationImpl node,
    ExtensionOverrideImpl function,
    List<WhyNotPromotedGetter> whyNotPromotedArguments, {
    required TypeImpl contextType,
  }) {
    var result = _extensionResolver.getOverrideMember(
      function,
      MethodElement.CALL_METHOD_NAME,
    );
    var callElement = result.getter2;
    node.element = callElement;

    if (callElement == null) {
      _diagnosticReporter.report(
        diag.invocationOfExtensionWithoutCall
            .withArguments(name: function.name.lexeme)
            .at(function),
      );
      return _unresolved(
        node,
        DynamicTypeImpl.instance,
        whyNotPromotedArguments,
        contextType: contextType,
      );
    }

    if (callElement.isStatic) {
      _diagnosticReporter.report(
        diag.extensionOverrideAccessToStaticMember.at(node.argumentList),
      );
    }

    _resolve(
      node,
      whyNotPromotedArguments,
      contextType: contextType,
      target: InvocationTargetExecutableElement(callElement),
    );
  }

  void _unresolved(
    FunctionExpressionInvocationImpl node,
    TypeImpl type,
    List<WhyNotPromotedGetter> whyNotPromotedArguments, {
    required TypeImpl contextType,
  }) {
    _setExplicitTypeArgumentTypes(node);
    FunctionExpressionInvocationInferrer(
      resolver: _resolver,
      node: node,
      argumentList: node.argumentList,
      contextType: contextType,
      whyNotPromotedArguments: whyNotPromotedArguments,
      target: null,
    ).resolveInvocation();
    node.staticInvokeType = type;
    node.recordStaticType(type, resolver: _resolver);
  }

  /// Inference cannot be done, we still want to fill type argument types.
  static void _setExplicitTypeArgumentTypes(
    FunctionExpressionInvocationImpl node,
  ) {
    var typeArguments = node.typeArguments;
    if (typeArguments != null) {
      node.typeArgumentTypes = typeArguments.arguments
          .map((typeArgument) => typeArgument.typeOrThrow)
          .toList();
    } else {
      node.typeArgumentTypes = const <TypeImpl>[];
    }
  }
}
