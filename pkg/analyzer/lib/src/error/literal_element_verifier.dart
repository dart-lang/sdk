// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/error/codes.dart';

/// Verifier for [CollectionElement]s in list, set, or map literals.
class LiteralElementVerifier {
  final TypeProvider typeProvider;
  final TypeSystemImpl typeSystem;
  final ErrorReporter errorReporter;
  final FeatureSet featureSet;
  final bool Function(Expression) checkForUseOfVoidResult;

  final bool forList;
  final bool forSet;
  final DartType elementType;

  final bool forMap;
  final DartType mapKeyType;
  final DartType mapValueType;

  LiteralElementVerifier(
    this.typeProvider,
    this.typeSystem,
    this.errorReporter,
    this.checkForUseOfVoidResult, {
    this.forList = false,
    this.forSet = false,
    this.elementType,
    this.forMap = false,
    this.mapKeyType,
    this.mapValueType,
    this.featureSet,
  });

  void verify(CollectionElement element) {
    _verifyElement(element);
  }

  /// Check that the given [type] is assignable to the [elementType], otherwise
  /// report the list or set error on the [errorNode].
  void _checkAssignableToElementType(DartType type, AstNode errorNode) {
    if (!typeSystem.isAssignableTo2(type, elementType)) {
      var errorCode = forList
          ? CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
          : CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE;
      errorReporter.reportErrorForNode(
        errorCode,
        errorNode,
        [type, elementType],
      );
    }
  }

  /// Verify that the given [element] can be assigned to the [elementType] of
  /// the enclosing list, set, of map literal.
  void _verifyElement(CollectionElement element) {
    if (element is Expression) {
      if (forList || forSet) {
        if (!elementType.isVoid && checkForUseOfVoidResult(element)) {
          return;
        }
        _checkAssignableToElementType(element.staticType, element);
      } else {
        errorReporter.reportErrorForNode(
            CompileTimeErrorCode.EXPRESSION_IN_MAP, element);
      }
    } else if (element is ForElement) {
      _verifyElement(element.body);
    } else if (element is IfElement) {
      _verifyElement(element.thenElement);
      _verifyElement(element.elseElement);
    } else if (element is MapLiteralEntry) {
      if (forMap) {
        _verifyMapLiteralEntry(element);
      } else {
        errorReporter.reportErrorForNode(
            CompileTimeErrorCode.MAP_ENTRY_NOT_IN_MAP, element);
      }
    } else if (element is SpreadElement) {
      var isNullAware = element.isNullAware;
      Expression expression = element.expression;
      if (forList || forSet) {
        _verifySpreadForListOrSet(isNullAware, expression);
      } else if (forMap) {
        _verifySpreadForMap(isNullAware, expression);
      }
    }
  }

  /// Verify that the [entry]'s key and value are assignable to [mapKeyType]
  /// and [mapValueType].
  void _verifyMapLiteralEntry(MapLiteralEntry entry) {
    if (!mapKeyType.isVoid && checkForUseOfVoidResult(entry.key)) {
      return;
    }

    if (!mapValueType.isVoid && checkForUseOfVoidResult(entry.value)) {
      return;
    }

    var keyType = entry.key.staticType;
    if (!typeSystem.isAssignableTo2(keyType, mapKeyType)) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE,
        entry.key,
        [keyType, mapKeyType],
      );
    }

    var valueType = entry.value.staticType;
    if (!typeSystem.isAssignableTo2(valueType, mapValueType)) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE,
        entry.value,
        [valueType, mapValueType],
      );
    }
  }

  /// Verify that the type of the elements of the given [expression] can be
  /// assigned to the [elementType] of the enclosing collection.
  void _verifySpreadForListOrSet(bool isNullAware, Expression expression) {
    var expressionType = expression.staticType;
    if (expressionType.isDynamic) return;

    if (typeSystem.isNonNullableByDefault) {
      if (typeSystem.isSubtypeOf2(expressionType, NeverTypeImpl.instance)) {
        return;
      }
      if (typeSystem.isSubtypeOf2(expressionType, typeSystem.nullNone)) {
        if (isNullAware) {
          return;
        }
        errorReporter.reportErrorForNode(
          CompileTimeErrorCode.NOT_NULL_AWARE_NULL_SPREAD,
          expression,
        );
        return;
      }
    } else {
      if (expressionType.isDartCoreNull) {
        if (isNullAware) {
          return;
        }
        errorReporter.reportErrorForNode(
          CompileTimeErrorCode.NOT_NULL_AWARE_NULL_SPREAD,
          expression,
        );
        return;
      }
    }

    var iterableType = expressionType.asInstanceOf(
      typeProvider.iterableElement,
    );

    if (iterableType == null) {
      return errorReporter.reportErrorForNode(
        CompileTimeErrorCode.NOT_ITERABLE_SPREAD,
        expression,
      );
    }

    var iterableElementType = iterableType.typeArguments[0];
    if (!typeSystem.isAssignableTo2(iterableElementType, elementType)) {
      var errorCode = forList
          ? CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
          : CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE;
      errorReporter.reportErrorForNode(
        errorCode,
        expression,
        [iterableElementType, elementType],
      );
    }
  }

  /// Verify that the [expression] is a subtype of `Map<Object, Object>`, and
  /// its key and values are assignable to [mapKeyType] and [mapValueType].
  void _verifySpreadForMap(bool isNullAware, Expression expression) {
    var expressionType = expression.staticType;
    if (expressionType.isDynamic) return;

    if (typeSystem.isNonNullableByDefault) {
      if (typeSystem.isSubtypeOf2(expressionType, NeverTypeImpl.instance)) {
        return;
      }
      if (typeSystem.isSubtypeOf2(expressionType, typeSystem.nullNone)) {
        if (isNullAware) {
          return;
        }
        errorReporter.reportErrorForNode(
          CompileTimeErrorCode.NOT_NULL_AWARE_NULL_SPREAD,
          expression,
        );
        return;
      }
    } else {
      if (expressionType.isDartCoreNull) {
        if (isNullAware) {
          return;
        }
        errorReporter.reportErrorForNode(
          CompileTimeErrorCode.NOT_NULL_AWARE_NULL_SPREAD,
          expression,
        );
        return;
      }
    }

    var mapType = expressionType.asInstanceOf(
      typeProvider.mapElement,
    );

    if (mapType == null) {
      return errorReporter.reportErrorForNode(
        CompileTimeErrorCode.NOT_MAP_SPREAD,
        expression,
      );
    }

    var keyType = mapType.typeArguments[0];
    if (!typeSystem.isAssignableTo2(keyType, mapKeyType)) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE,
        expression,
        [keyType, mapKeyType],
      );
    }

    var valueType = mapType.typeArguments[1];
    if (!typeSystem.isAssignableTo2(valueType, mapValueType)) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE,
        expression,
        [valueType, mapValueType],
      );
    }
  }
}
