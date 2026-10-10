// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/extension_member_resolver.dart';
import 'package:analyzer/src/dart/resolver/invocation_inferrer.dart';
import 'package:analyzer/src/dart/resolver/resolution_result.dart';
import 'package:analyzer/src/dart/resolver/type_analyzer.dart';
import 'package:analyzer/src/dart/resolver/type_property_resolver.dart';
import 'package:analyzer/src/dart/type_instantiation_target.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/listener.dart';
import 'package:analyzer/src/error/nullable_dereference_verifier.dart';

/// Helper for resolving [CallInvocation]s.
class CallInvocationResolver {
  final TypeAnalyzer _typeAnalyzer;
  final TypePropertyResolver _typePropertyResolver;

  CallInvocationResolver({required TypeAnalyzer typeAnalyzer})
    : _typeAnalyzer = typeAnalyzer,
      _typePropertyResolver = typeAnalyzer.typePropertyResolver;

  DiagnosticReporter get _diagnosticReporter =>
      _typeAnalyzer.diagnosticReporter;

  ExtensionMemberResolver get _extensionResolver =>
      _typeAnalyzer.extensionResolver;

  NullableDereferenceVerifier get _nullableDereferenceVerifier =>
      _typeAnalyzer.nullableDereferenceVerifier;

  TypeSystemImpl get _typeSystem => _typeAnalyzer.typeSystem;

  void resolve(
    CallInvocationImpl node,
    List<WhyNotPromotedGetter> whyNotPromotedArguments, {
    required TypeImpl contextType,
  }) {
    switch (node.receiver) {
      case SuperReferenceImpl receiver:
        var result = _typePropertyResolver.resolve(
          receiver: receiver,
          receiverType: _typeAnalyzer.superLookupType(receiver),
          name: MethodElement.CALL_METHOD_NAME,
          hasRead: true,
          hasWrite: false,
          propertyErrorEntity: receiver,
          nameErrorEntity: receiver,
        );
        if (result.getter2 case InternalMethodElement element) {
          _resolve(
            node,
            whyNotPromotedArguments,
            contextType: contextType,
            target: InvocationTargetExecutableElement(element),
          );
        } else {
          if (result.getterOutcome == LookupOutcome.notFound ||
              result.getter2 != null) {
            _diagnosticReporter.report(
              diag.invocationOfNonFunctionExpression.at(receiver),
            );
          }
          _unresolved(
            node,
            InvalidTypeImpl.instance,
            whyNotPromotedArguments,
            contextType: contextType,
          );
        }
        return;
      case ExtensionOverride2Impl function:
        _resolveReceiverExtensionOverride(
          node,
          function,
          whyNotPromotedArguments,
          contextType: contextType,
        );
        return;
      case ExpressionImpl function:
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

        if (receiverType.isDartCoreFunction) {
          _nullableDereferenceVerifier.expression(
            diag.uncheckedInvocationOfNullableValue,
            function,
          );
          _unresolved(
            node,
            DynamicTypeImpl.instance,
            whyNotPromotedArguments,
            contextType: contextType,
            resolution: FunctionInterfaceInvocationResolutionImpl(
              type: DynamicTypeImpl.instance,
            ),
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

        if (result.recordField != null) {
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

        if (callElement == null) {
          if (result.getterOutcome == LookupOutcome.notFound) {
            _diagnosticReporter.report(
              diag.invocationOfNonFunctionExpression.at(function),
            );
          }
          var type = result.getterOutcome == LookupOutcome.resolved
              ? DynamicTypeImpl.instance
              : InvalidTypeImpl.instance;
          _unresolved(
            node,
            type,
            whyNotPromotedArguments,
            candidates: [?result.setter2],
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
            candidates: [callElement],
            contextType: contextType,
          );
          return;
        }

        _resolve(
          node,
          whyNotPromotedArguments,
          contextType: contextType,
          target: InvocationTargetExecutableElement(callElement),
        );
    }
  }

  /// Check for situations where the result of a method or function is used,
  /// when it returns 'void'. Or, in rare cases, when other types of expressions
  /// are void, such as identifiers.
  ///
  /// See [diag.useOfVoidResult].
  ///
  // TODO(scheglov): this is duplicate
  bool _checkForUseOfVoidResult(Expression expression, DartType type) {
    if (type is! VoidTypeImpl) {
      return false;
    }

    _diagnosticReporter.report(diag.useOfVoidResult.at(expression));

    return true;
  }

  void _resolve(
    CallInvocationImpl node,
    List<WhyNotPromotedGetter> whyNotPromotedArguments, {
    required TypeImpl contextType,
    required InvocationTarget target,
  }) {
    var returnType =
        CallInvocationInferrer(
              typeAnalyzer: _typeAnalyzer,
              node: node,
              argumentList: node.argumentList,
              whyNotPromotedArguments: whyNotPromotedArguments,
              contextType: contextType,
              target: target,
            ).resolveInvocation()
            as TypeImpl;

    var invokeType = node.staticInvokeType as FunctionTypeImpl;
    node.resolution = switch (target) {
      InvocationTargetExecutableElement(:var element) =>
        ExecutableInvocationResolutionImpl(
          element: element as InternalExecutableElement,
          invokeType: invokeType,
          type: returnType,
        ),
      InvocationTargetFunctionTypedExpression() =>
        FunctionTypeInvocationResolutionImpl(
          invokeType: invokeType,
          type: returnType,
        ),
      _ => throw StateError('Unexpected call invocation target: $target'),
    };
    node.recordStaticType(returnType, typeAnalyzer: _typeAnalyzer);
  }

  void _resolveReceiverExtensionOverride(
    CallInvocationImpl node,
    ExtensionOverride2Impl function,
    List<WhyNotPromotedGetter> whyNotPromotedArguments, {
    required TypeImpl contextType,
  }) {
    var result = _extensionResolver.getOverrideMember(
      function,
      MethodElement.CALL_METHOD_NAME,
    );
    var callElement = result.getter2;
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
    CallInvocationImpl node,
    TypeImpl type,
    List<WhyNotPromotedGetter> whyNotPromotedArguments, {
    List<Element> candidates = const [],
    required TypeImpl contextType,
    InvocationResolutionImpl? resolution,
  }) {
    _setExplicitTypeArgumentTypes(node);
    CallInvocationInferrer(
      typeAnalyzer: _typeAnalyzer,
      node: node,
      argumentList: node.argumentList,
      contextType: contextType,
      whyNotPromotedArguments: whyNotPromotedArguments,
      target: null,
    ).resolveInvocation();
    node.staticInvokeType = type;
    node.resolution =
        resolution ??
        switch (type) {
          NeverTypeImpl() => null,
          InvalidTypeImpl() => InvalidInvocationResolutionImpl(
            candidates: candidates,
            recovery: null,
            type: type,
          ),
          _ => DynamicInvocationResolutionImpl(type: type),
        };
    node.recordStaticType(type, typeAnalyzer: _typeAnalyzer);
  }

  /// Inference cannot be done, we still want to fill type argument types.
  static void _setExplicitTypeArgumentTypes(CallInvocationImpl node) {
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
