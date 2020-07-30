// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:meta/meta.dart';

/// Helper for resolving [YieldStatement]s.
class YieldStatementResolver {
  final ResolverVisitor _resolver;

  YieldStatementResolver({
    @required ResolverVisitor resolver,
  }) : _resolver = resolver;

  ExecutableElement get _enclosingFunction => _resolver.enclosingFunction;

  ErrorReporter get _errorReporter => _resolver.errorReporter;

  TypeProvider get _typeProvider => _resolver.typeProvider;

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

  void resolve(YieldStatement node) {
    if (_enclosingFunction?.isGenerator ?? false) {
      _resolve_generator(node);
    } else {
      _resolve_notGenerator(node);
    }
  }

  /// Check for situations where the result of a method or function is used, when
  /// it returns 'void'. Or, in rare cases, when other types of expressions are
  /// void, such as identifiers.
  ///
  /// See [CompileTimeErrorCode.USE_OF_VOID_RESULT].
  ///
  /// TODO(scheglov) This is duplicate
  /// TODO(scheglov) Also in [BoolExpressionVerifier]
  bool _checkForUseOfVoidResult(Expression expression) {
    if (!identical(expression.staticType, VoidTypeImpl.instance)) {
      return false;
    }

    if (expression is MethodInvocation) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.USE_OF_VOID_RESULT,
        expression.methodName,
      );
    } else {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.USE_OF_VOID_RESULT,
        expression,
      );
    }

    return true;
  }

  /// Check for a type mis-match between the yielded type and the declared
  /// return type of a generator function.
  ///
  /// This method should only be called in generator functions.
  void _checkForYieldOfInvalidType(YieldStatement node, bool isYieldEach) {
    var declaredReturnType = _enclosingFunction.returnType;

    var expression = node.expression;
    var expressionType = expression.staticType;

    DartType impliedReturnType;
    if (isYieldEach) {
      impliedReturnType = expressionType;
    } else if (_enclosingFunction.isSynchronous) {
      impliedReturnType = _typeProvider.iterableType2(expressionType);
    } else {
      impliedReturnType = _typeProvider.streamType2(expressionType);
    }

    if (declaredReturnType != null) {
      if (!_typeSystem.isAssignableTo2(impliedReturnType, declaredReturnType)) {
        _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.YIELD_OF_INVALID_TYPE,
          expression,
          [impliedReturnType, declaredReturnType],
        );
        return;
      }
    }

    if (isYieldEach) {
      // Since the declared return type might have been "dynamic", we need to
      // also check that the implied return type is assignable to generic
      // Iterable/Stream.
      DartType requiredReturnType;
      if (_enclosingFunction.isSynchronous) {
        requiredReturnType = _typeProvider.iterableDynamicType;
      } else {
        requiredReturnType = _typeProvider.streamDynamicType;
      }

      if (!_typeSystem.isAssignableTo2(impliedReturnType, requiredReturnType)) {
        _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.YIELD_OF_INVALID_TYPE,
          expression,
          [impliedReturnType, requiredReturnType],
        );
      }
    }
  }

  void _computeElementType(YieldStatement node) {
    var elementType = _resolver.inferenceContext.bodyContext?.contextType;
    if (elementType != null) {
      var contextType = elementType;
      if (node.star != null) {
        contextType = _enclosingFunction.isSynchronous
            ? _typeProvider.iterableType2(elementType)
            : _typeProvider.streamType2(elementType);
      }
      InferenceContext.setType(node.expression, contextType);
    }
  }

  void _resolve_generator(YieldStatement node) {
    _computeElementType(node);

    node.expression.accept(_resolver);

    if (node.star != null) {
      _resolver.nullableDereferenceVerifier.expression(node.expression);
    }

    _resolver.inferenceContext.bodyContext?.addYield(node);

    _checkForYieldOfInvalidType(node, node.star != null);
    _checkForUseOfVoidResult(node.expression);
  }

  void _resolve_notGenerator(YieldStatement node) {
    node.expression.accept(_resolver);

    _errorReporter.reportErrorForNode(
      node.star != null
          ? CompileTimeErrorCode.YIELD_EACH_IN_NON_GENERATOR
          : CompileTimeErrorCode.YIELD_IN_NON_GENERATOR,
      node,
    );

    _checkForUseOfVoidResult(node.expression);
  }
}
