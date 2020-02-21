// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/type_system.dart';
import 'package:meta/meta.dart';

/// Helper for resolving [YieldStatement]s.
class YieldStatementResolver {
  final ResolverVisitor _resolver;

  /// The element type required by the declared return type of the enclosing
  /// function. Note, that for function expressions the declared return type
  /// can be obtained by means of type inference.
  DartType _elementType;

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
  /// See [StaticWarningCode.USE_OF_VOID_RESULT].
  ///
  /// TODO(scheglov) This is duplicate
  /// TODO(scheglov) Also in [BoolExpressionVerifier]
  bool _checkForUseOfVoidResult(Expression expression) {
    if (!identical(expression.staticType, VoidTypeImpl.instance)) {
      return false;
    }

    if (expression is MethodInvocation) {
      _errorReporter.reportErrorForNode(
        StaticWarningCode.USE_OF_VOID_RESULT,
        expression.methodName,
      );
    } else {
      _errorReporter.reportErrorForNode(
        StaticWarningCode.USE_OF_VOID_RESULT,
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
    var expressionType = node.expression.staticType;

    if (node.star == null) {
      if (!_typeSystem.isAssignableTo2(expressionType, _elementType)) {
        _errorReporter.reportErrorForNode(
          StaticTypeWarningCode.YIELD_OF_INVALID_TYPE,
          node.expression,
          [expressionType, _elementType],
        );
      }
      return;
    }

    DartType yieldElementType;
    if (expressionType is InterfaceTypeImpl) {
      var sequenceType = expressionType.asInstanceOf(
        _typeProvider.iterableElement,
      );
      sequenceType ??= expressionType.asInstanceOf(
        _typeProvider.streamElement,
      );
      if (sequenceType != null) {
        yieldElementType = sequenceType.typeArguments[0];
      }
    }

    if (yieldElementType == null) {
      if (_typeSystem.isTop(expressionType) || expressionType.isDartCoreNull) {
        yieldElementType = DynamicTypeImpl.instance;
      } else {
        _errorReporter.reportErrorForNode(
          StaticTypeWarningCode.YIELD_OF_INVALID_TYPE,
          node.expression,
          [expressionType, _elementType],
        );
        return;
      }
    }

    if (!_typeSystem.isAssignableTo2(yieldElementType, _elementType)) {
      _errorReporter.reportErrorForNode(
        StaticTypeWarningCode.YIELD_OF_INVALID_TYPE,
        node.expression,
        [yieldElementType, _elementType],
      );
    }
  }

  void _computeElementType(YieldStatement node) {
    _elementType = _resolver.inferenceContext.returnContext;
    if (_elementType != null) {
      var contextType = _elementType;
      if (node.star != null) {
        contextType = _enclosingFunction.isSynchronous
            ? _typeProvider.iterableType2(_elementType)
            : _typeProvider.streamType2(_elementType);
      }
      InferenceContext.setType(node.expression, contextType);
    } else {
      _elementType ??= DynamicTypeImpl.instance;
    }
  }

  void _resolve_generator(YieldStatement node) {
    _computeElementType(node);

    node.expression.accept(_resolver);

    if (node.star != null) {
      _resolver.nullableDereferenceVerifier.expression(node.expression);
    }

    DartType type = node.expression?.staticType;
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
    _resolver.inferenceContext.addReturnOrYieldType(type);

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
