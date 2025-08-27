// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/body_inference_context.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// Helper for resolving [YieldStatement]s.
class YieldStatementResolver {
  final ResolverVisitor _resolver;

  YieldStatementResolver({required ResolverVisitor resolver})
    : _resolver = resolver;

  DiagnosticReporter get _diagnosticReporter => _resolver.diagnosticReporter;

  TypeProviderImpl get _typeProvider => _resolver.typeProvider;

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

  void resolve(YieldStatementImpl node) {
    var bodyContext = _resolver.bodyContext;
    if (bodyContext != null && bodyContext.isGenerator) {
      _resolve_generator(bodyContext, node);
    } else {
      _resolve_notGenerator(node);
    }
  }

  /// Check for situations where the result of a method or function is used, when
  /// it returns 'void'. Or, in rare cases, when other types of expressions are
  /// void, such as identifiers.
  ///
  /// See [CompileTimeErrorCode.useOfVoidResult].
  ///
  // TODO(scheglov): This is duplicate
  // TODO(scheglov): Also in [BoolExpressionVerifier]
  bool _checkForUseOfVoidResult(Expression expression) {
    if (!identical(expression.staticType, VoidTypeImpl.instance)) {
      return false;
    }

    if (expression is MethodInvocation) {
      _diagnosticReporter.atNode(
        expression.methodName,
        CompileTimeErrorCode.useOfVoidResult,
      );
    } else {
      _diagnosticReporter.atNode(
        expression,
        CompileTimeErrorCode.useOfVoidResult,
      );
    }

    return true;
  }

  /// Check for a type mis-match between the yielded type and the declared
  /// return type of a generator function.
  ///
  /// This method should only be called in generator functions.
  void _checkForYieldOfInvalidType(
    BodyInferenceContext bodyContext,
    YieldStatement node, {
    required bool isYieldEach,
  }) {
    var expression = node.expression;
    var expressionType = expression.typeOrThrow;

    TypeImpl impliedReturnType;
    if (isYieldEach) {
      impliedReturnType = expressionType;
    } else if (bodyContext.isSynchronous) {
      impliedReturnType = _typeProvider.iterableType(expressionType);
    } else {
      impliedReturnType = _typeProvider.streamType(expressionType);
    }

    var imposedReturnType = bodyContext.imposedType;
    if (imposedReturnType != null) {
      if (isYieldEach) {
        if (!_typeSystem.isAssignableTo(
          impliedReturnType,
          imposedReturnType,
          strictCasts: _resolver.analysisOptions.strictCasts,
        )) {
          _diagnosticReporter.atNode(
            expression,
            CompileTimeErrorCode.yieldEachOfInvalidType,
            arguments: [impliedReturnType, imposedReturnType],
          );
          return;
        }
      } else {
        var imposedSequenceType = imposedReturnType.asInstanceOf(
          bodyContext.isSynchronous
              ? _typeProvider.iterableElement
              : _typeProvider.streamElement,
        );
        if (imposedSequenceType != null) {
          var imposedValueType = imposedSequenceType.typeArguments[0];
          if (!_typeSystem.isAssignableTo(
            expressionType,
            imposedValueType,
            strictCasts: _resolver.analysisOptions.strictCasts,
          )) {
            _diagnosticReporter.atNode(
              expression,
              CompileTimeErrorCode.yieldOfInvalidType,
              arguments: [expressionType, imposedValueType],
            );
            return;
          }
        }
      }
    }

    if (isYieldEach) {
      // Since the declared return type might have been "dynamic", we need to
      // also check that the implied return type is assignable to generic
      // Iterable/Stream.
      TypeImpl requiredReturnType;
      if (bodyContext.isSynchronous) {
        requiredReturnType = _typeProvider.iterableDynamicType;
      } else {
        requiredReturnType = _typeProvider.streamDynamicType;
      }

      if (!_typeSystem.isAssignableTo(
        impliedReturnType,
        requiredReturnType,
        strictCasts: _resolver.analysisOptions.strictCasts,
      )) {
        _diagnosticReporter.atNode(
          expression,
          CompileTimeErrorCode.yieldEachOfInvalidType,
          arguments: [impliedReturnType, requiredReturnType],
        );
      }
    }
  }

  TypeImpl _computeContextType(
    BodyInferenceContext bodyContext,
    YieldStatement node,
  ) {
    var elementType = bodyContext.contextType;
    if (elementType != null) {
      var contextType = elementType;
      if (node.star != null) {
        contextType = bodyContext.isSynchronous
            ? _typeProvider.iterableType(elementType)
            : _typeProvider.streamType(elementType);
      }
      return contextType;
    } else {
      return UnknownInferredType.instance;
    }
  }

  void _resolve_generator(
    BodyInferenceContext bodyContext,
    YieldStatementImpl node,
  ) {
    _resolver.analyzeExpression(
      node.expression,
      SharedTypeSchemaView(_computeContextType(bodyContext, node)),
    );
    _resolver.popRewrite();

    if (node.star != null) {
      _resolver.nullableDereferenceVerifier.expression(
        CompileTimeErrorCode.uncheckedUseOfNullableValueInYieldEach,
        node.expression,
      );
    }

    bodyContext.addYield(node);

    _checkForYieldOfInvalidType(
      bodyContext,
      node,
      isYieldEach: node.star != null,
    );
    _checkForUseOfVoidResult(node.expression);
  }

  void _resolve_notGenerator(YieldStatementImpl node) {
    _resolver.analyzeExpression(
      node.expression,
      _resolver.operations.unknownType,
    );
    _resolver.popRewrite();

    _diagnosticReporter.atNode(
      node,
      node.star != null
          ? CompileTimeErrorCode.yieldEachInNonGenerator
          : CompileTimeErrorCode.yieldInNonGenerator,
    );

    _checkForUseOfVoidResult(node.expression);
  }
}
