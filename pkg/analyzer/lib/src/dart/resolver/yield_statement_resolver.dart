// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/type_system.dart';
import 'package:meta/meta.dart';

/// Helper for resolving [YieldStatement]s.
class YieldStatementResolver {
  final ResolverVisitor _resolver;

  YieldStatementResolver({
    @required ResolverVisitor resolver,
  }) : _resolver = resolver;

  ExecutableElement get _enclosingFunction => _resolver.enclosingFunction;

  ErrorReporter get _errorReporter => _resolver.errorReporter;

  bool get _inGenerator => _enclosingFunction?.isGenerator;

  TypeProvider get _typeProvider => _resolver.typeProvider;

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

  void resolve(YieldStatement node) {
    Expression e = node.expression;
    DartType returnType = _resolver.inferenceContext.returnContext;
    bool isGenerator = _enclosingFunction?.isGenerator ?? false;
    if (returnType != null && isGenerator) {
      // If we're not in a generator ([a]sync*, then we shouldn't have a yield.
      // so don't infer

      // If this just a yield, then we just pass on the element type
      DartType type = returnType;
      if (node.star != null) {
        // If this is a yield*, then we wrap the element return type
        // If it's synchronous, we expect Iterable<T>, otherwise Stream<T>
        type = _enclosingFunction.isSynchronous
            ? _typeProvider.iterableType2(type)
            : _typeProvider.streamType2(type);
      }
      InferenceContext.setType(e, type);
    }

    node.expression.accept(_resolver);

    if (node.star != null) {
      _resolver.nullableDereferenceVerifier.expression(node.expression);
    }

    DartType type = e?.staticType;
    if (type != null && isGenerator) {
      // If this just a yield, then we just pass on the element type
      if (node.star != null) {
        // If this is a yield*, then we unwrap the element return type
        // If it's synchronous, we expect Iterable<T>, otherwise Stream<T>
        if (type is InterfaceType) {
          ClassElement wrapperElement = _enclosingFunction.isSynchronous
              ? _typeProvider.iterableElement
              : _typeProvider.streamElement;
          var asInstanceType =
              (type as InterfaceTypeImpl).asInstanceOf(wrapperElement);
          if (asInstanceType != null) {
            type = asInstanceType.typeArguments[0];
          }
        }
      }
      if (type != null) {
        _resolver.inferenceContext.addReturnOrYieldType(type);
      }
    }

    _verify(node);
  }

  /// TODO(scheglov) This is duplicate
  bool _checkForAssignableExpressionAtType(
      Expression expression,
      DartType actualStaticType,
      DartType expectedStaticType,
      ErrorCode errorCode) {
    if (!_typeSystem.isAssignableTo2(actualStaticType, expectedStaticType)) {
      _errorReporter.reportErrorForNode(
          errorCode, expression, [actualStaticType, expectedStaticType]);
      return false;
    }
    return true;
  }

  /// Check for situations where the result of a method or function is used, when
  /// it returns 'void'. Or, in rare cases, when other types of expressions are
  /// void, such as identifiers.
  ///
  /// See [StaticWarningCode.USE_OF_VOID_RESULT].
  ///
  /// TODO(scheglov) This is duplicate
  /// TODO(scheglov) Also in [BoolExpressionVerifier]
  bool _checkForUseOfVoidResult(Expression expression) {
    if (expression == null ||
        !identical(expression.staticType, VoidTypeImpl.instance)) {
      return false;
    }

    if (expression is MethodInvocation) {
      SimpleIdentifier methodName = expression.methodName;
      _errorReporter.reportErrorForNode(
          StaticWarningCode.USE_OF_VOID_RESULT, methodName, []);
    } else {
      _errorReporter.reportErrorForNode(
          StaticWarningCode.USE_OF_VOID_RESULT, expression, []);
    }

    return true;
  }

  /// Check for a type mis-match between the yielded type and the declared
  /// return type of a generator function.
  ///
  /// This method should only be called in generator functions.
  void _checkForYieldOfInvalidType(
      Expression yieldExpression, bool isYieldEach) {
    assert(_inGenerator);
    if (_enclosingFunction == null) {
      return;
    }
    DartType declaredReturnType = _enclosingFunction.returnType;
    DartType staticYieldedType = yieldExpression.staticType;
    DartType impliedReturnType;
    if (isYieldEach) {
      impliedReturnType = staticYieldedType;
    } else if (_enclosingFunction.isAsynchronous) {
      impliedReturnType = _typeProvider.streamType2(staticYieldedType);
    } else {
      impliedReturnType = _typeProvider.iterableType2(staticYieldedType);
    }
    if (declaredReturnType != null &&
        !_checkForAssignableExpressionAtType(yieldExpression, impliedReturnType,
            declaredReturnType, StaticTypeWarningCode.YIELD_OF_INVALID_TYPE)) {
      return;
    }

    if (isYieldEach) {
      // Since the declared return type might have been "dynamic", we need to
      // also check that the implied return type is assignable to generic
      // Stream/Iterable.
      DartType requiredReturnType;
      if (_enclosingFunction.isAsynchronous) {
        requiredReturnType = _typeProvider.streamDynamicType;
      } else {
        requiredReturnType = _typeProvider.iterableDynamicType;
      }
      if (!_typeSystem.isAssignableTo2(impliedReturnType, requiredReturnType)) {
        _errorReporter.reportErrorForNode(
            StaticTypeWarningCode.YIELD_OF_INVALID_TYPE,
            yieldExpression,
            [impliedReturnType, requiredReturnType]);
        return;
      }
    }
  }

  void _verify(YieldStatement node) {
    if (_inGenerator) {
      _checkForYieldOfInvalidType(node.expression, node.star != null);
    } else {
      CompileTimeErrorCode errorCode;
      if (node.star != null) {
        errorCode = CompileTimeErrorCode.YIELD_EACH_IN_NON_GENERATOR;
      } else {
        errorCode = CompileTimeErrorCode.YIELD_IN_NON_GENERATOR;
      }
      _errorReporter.reportErrorForNode(errorCode, node);
    }
    _checkForUseOfVoidResult(node.expression);
  }
}
