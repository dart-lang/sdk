// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/extension_member_resolver.dart';
import 'package:analyzer/src/dart/type_instantiation_target.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/listener.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// Resolves explicit type applications to function values.
class FunctionReferenceResolver {
  /// The resolver driving this participant.
  final ResolverVisitor _resolver;

  /// Helper for extension method resolution.
  final ExtensionMemberResolver _extensionResolver;

  FunctionReferenceResolver(this._resolver)
    : _extensionResolver = _resolver.extensionResolver;

  DiagnosticReporter get _diagnosticReporter => _resolver.diagnosticReporter;

  /// Resolves a type application whose operand has already been classified as
  /// a value. Name and member lookup belong to the canonical operand; this
  /// method only selects an implicit `call` tear-off and instantiates its type.
  void resolveInstantiation(FunctionInstantiationImpl node) {
    node.typeArguments.accept2(_resolver);
    _resolver.analyzeExpression(
      node.operand,
      _resolver.operations.unknownType,
      continueNullShorting: true,
    );
    var operand = _resolver.popRewrite()!;
    var rawType = operand.typeOrThrow;

    if (operand is ConstructorTearOffImpl) {
      var typeReference = operand.typeReference;
      var className = switch (typeReference.importPrefix) {
        var prefix? => '${prefix.name.lexeme}.${typeReference.name.lexeme}',
        _ => typeReference.name.lexeme,
      };
      _diagnosticReporter.report(
        diag.wrongNumberOfTypeArgumentsConstructor
            .withArguments(
              className: className,
              constructorName: operand.selector.name2.lexeme,
            )
            .at(node.typeArguments),
      );
      node.recordStaticType(InvalidTypeImpl.instance, resolver: _resolver);
      return;
    }
    if (rawType is InvalidType) {
      // Redundant: the head already reported why it did not resolve. Kept to
      // avoid changing the diagnostics that users see.
      // TODO(scheglov): Drop this cascading diagnostic.
      if (operand is DotShorthandNameExpressionImpl) {
        _diagnosticReporter.report(
          diag.disallowedTypeInstantiationExpression.at(operand),
        );
      }
      node.recordStaticType(InvalidTypeImpl.instance, resolver: _resolver);
      return;
    }

    InvocationTarget? target;
    if (_getCallMethod(node, rawType) case MethodElement callMethod) {
      var tearOff = ImplicitCallTearOffImpl(
        operand: operand,
        element: callMethod,
      );
      tearOff.setPseudoExpressionStaticType(callMethod.type);
      node.operand = tearOff;
      rawType = callMethod.type as TypeImpl;
      target = InvocationTargetExecutableElement(callMethod);
    } else {
      var resolution = switch (operand) {
        NameExpressionImpl(:var resolution) => resolution,
        _ => null,
      };
      target = switch (resolution) {
        // A dot shorthand constructor tear-off, such as `.new<int>`, keeps its
        // constructor resolution here, and [InvocationTargetExecutableElement]
        // rejects constructors. Report against the function type instead.
        // TODO(scheglov): Use [InvocationTargetConstructorElement].
        ExecutableTearOffResolutionImpl(element: ConstructorElement()) => null,
        ExecutableTearOffResolutionImpl(:var element) =>
          InvocationTargetExecutableElement(element),
        GetterInvocationResolutionImpl(:var element)
            when operand is UnqualifiedNameExpressionImpl =>
          InvocationTargetExecutableElement(element),
        _ => null,
      };
    }

    if (rawType is TypeParameterTypeImpl) {
      rawType =
          rawType.element.bound ?? _resolver.typeProvider.objectQuestionType;
    }
    if (rawType is FunctionTypeImpl) {
      var typeArgumentTypes = _checkTypeArguments(
        node.typeArguments,
        rawType.typeParameters,
        target: target ?? InvocationTargetFunctionTypedExpression(rawType),
      );
      node.typeArgumentTypes = typeArgumentTypes;
      node.recordStaticType(
        rawType.instantiate(typeArgumentTypes),
        resolver: _resolver,
      );
      return;
    }

    if (_resolver.isConstructorTearoffsEnabled) {
      if (rawType is DynamicType &&
          (operand is ReceiverPropertyExtractionImpl ||
              operand is ImportPrefixedNameExpressionImpl)) {
        _diagnosticReporter.report(
          diag.genericMethodTypeInstantiationOnDynamic.at(
            operand is ImportPrefixedNameExpressionImpl ||
                    operand is ReceiverPropertyExtractionImpl &&
                        operand.receiver is UnqualifiedNameExpressionImpl
                ? operand
                : node,
          ),
        );
      } else {
        _diagnosticReporter.report(
          diag.disallowedTypeInstantiationExpression.at(
            operand is ReceiverPropertyExtractionImpl &&
                    operand.receiver is! ExtensionOverride2Impl
                ? operand.name
                : operand,
          ),
        );
      }
      node.recordStaticType(InvalidTypeImpl.instance, resolver: _resolver);
    } else {
      node.recordStaticType(
        rawType is DynamicType
            ? DynamicTypeImpl.instance
            : InvalidTypeImpl.instance,
        resolver: _resolver,
      );
    }
  }

  List<TypeImpl> _checkTypeArguments(
    TypeArgumentList typeArgumentList,
    List<TypeParameterElement> typeParameters, {
    required TypeInstantiationTarget target,
  }) {
    if (typeArgumentList.arguments.length != typeParameters.length) {
      _diagnosticReporter.report(
        target
            .wrongNumberOfTypeArgumentsError(
              typeParameterCount: typeParameters.length,
              typeArgumentCount: typeArgumentList.arguments.length,
            )
            .at(typeArgumentList),
      );
      return List.filled(typeParameters.length, DynamicTypeImpl.instance);
    } else {
      return typeArgumentList.arguments
          .map((typeAnnotation) => typeAnnotation.typeOrThrow)
          .toList();
    }
  }

  ExecutableElement? _getCallMethod(ExpressionImpl node, DartType? type) {
    if (type is! InterfaceTypeImpl) {
      return null;
    }
    var callMethodName = Name(
      _resolver.definingLibrary.uri,
      MethodElement.CALL_METHOD_NAME,
    );
    if (type.nullabilitySuffix == NullabilitySuffix.question) {
      // If the interface type is nullable, only an applicable extension method
      // applies.
      return _extensionResolver
          .findExtension(type, node, callMethodName)
          .getter2;
    }
    // Otherwise, a 'call' method on the interface, or on an applicable
    // extension method applies.
    return type.lookUpMethod(
          MethodElement.CALL_METHOD_NAME,
          type.element.library,
        ) ??
        _extensionResolver.findExtension(type, node, callMethodName).getter2;
  }
}
