// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/extension_member_resolver.dart';
import 'package:analyzer/src/dart/resolver/invocation_inference_helper.dart';
import 'package:analyzer/src/dart/resolver/type_property_resolver.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/nullable_dereference_verifier.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:meta/meta.dart';

/// Helper for resolving [FunctionExpressionInvocation]s.
class FunctionExpressionInvocationResolver {
  final ResolverVisitor _resolver;
  final TypePropertyResolver _typePropertyResolver;
  final InvocationInferenceHelper _inferenceHelper;

  FunctionExpressionInvocationResolver({
    @required ResolverVisitor resolver,
  })  : _resolver = resolver,
        _typePropertyResolver = resolver.typePropertyResolver,
        _inferenceHelper = resolver.inferenceHelper;

  ErrorReporter get _errorReporter => _resolver.errorReporter;

  ExtensionMemberResolver get _extensionResolver => _resolver.extensionResolver;

  NullableDereferenceVerifier get _nullableDereferenceVerifier =>
      _resolver.nullableDereferenceVerifier;

  void resolve(FunctionExpressionInvocationImpl node) {
    var function = node.function;

    if (function is ExtensionOverride) {
      _resolveReceiverExtensionOverride(node, function);
      return;
    }

    _nullableDereferenceVerifier.expression(function);

    var receiverType = function.staticType;
    if (receiverType is FunctionType) {
      _resolve(node, receiverType);
      return;
    }

    if (receiverType is InterfaceType) {
      _resolveReceiverInterfaceType(node, function, receiverType);
      return;
    }

    if (identical(receiverType, NeverTypeImpl.instance)) {
      _unresolved(node, NeverTypeImpl.instance);
      return;
    }

    _unresolved(node, DynamicTypeImpl.instance);
  }

  void _resolve(FunctionExpressionInvocationImpl node, FunctionType rawType) {
    _inferenceHelper.resolveFunctionExpressionInvocation(
      node: node,
      rawType: rawType,
    );

    var returnType = _inferenceHelper.computeInvokeReturnType(
      node.staticInvokeType,
    );
    _inferenceHelper.recordStaticType(node, returnType);
  }

  void _resolveArguments(FunctionExpressionInvocationImpl node) {
    node.argumentList.accept(_resolver);
  }

  void _resolveReceiverExtensionOverride(
    FunctionExpressionInvocation node,
    ExtensionOverride function,
  ) {
    var result = _extensionResolver.getOverrideMember(
      function,
      FunctionElement.CALL_METHOD_NAME,
    );
    var callElement = result.getter;
    node.staticElement = callElement;

    if (callElement == null) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.INVOCATION_OF_EXTENSION_WITHOUT_CALL,
        function,
        [function.extensionName.name],
      );
      return _unresolved(node, DynamicTypeImpl.instance);
    }

    if (callElement.isStatic) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.EXTENSION_OVERRIDE_ACCESS_TO_STATIC_MEMBER,
        node.argumentList,
      );
    }

    var rawType = callElement.type;
    _resolve(node, rawType);
  }

  void _resolveReceiverInterfaceType(
    FunctionExpressionInvocationImpl node,
    Expression function,
    InterfaceType receiverType,
  ) {
    var result = _typePropertyResolver.resolve(
      receiver: function,
      receiverType: receiverType,
      name: FunctionElement.CALL_METHOD_NAME,
      receiverErrorNode: function,
      nameErrorEntity: function,
    );
    var callElement = result.getter;

    if (callElement?.kind != ElementKind.METHOD) {
      _unresolved(node, DynamicTypeImpl.instance);
      return;
    }

    node.staticElement = callElement;
    var rawType = callElement.type;
    _resolve(node, rawType);
  }

  void _unresolved(FunctionExpressionInvocationImpl node, DartType type) {
    _setExplicitTypeArgumentTypes(node);
    _resolveArguments(node);
    node.staticInvokeType = DynamicTypeImpl.instance;
    node.staticType = type;
  }

  /// Inference cannot be done, we still want to fill type argument types.
  static void _setExplicitTypeArgumentTypes(
    FunctionExpressionInvocationImpl node,
  ) {
    var typeArguments = node.typeArguments;
    if (typeArguments != null) {
      node.typeArgumentTypes = typeArguments.arguments
          .map((typeArgument) => typeArgument.type)
          .toList();
    } else {
      node.typeArgumentTypes = const <DartType>[];
    }
  }
}
