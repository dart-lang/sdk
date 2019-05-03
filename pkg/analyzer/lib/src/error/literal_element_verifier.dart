// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// Verifier for [CollectionElement]s in list, set, or map literals.
class LiteralElementVerifier {
  final TypeProvider typeProvider;
  final TypeSystem typeSystem;
  final ErrorReporter errorReporter;
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
  });

  void verify(CollectionElement element) {
    _verifyElement(element);
  }

  /// Check that the given [type] is assignable to the [elementType], otherwise
  /// report the list or set error on the [errorNode].
  void _checkAssignableToElementType(DartType type, AstNode errorNode) {
    if (!typeSystem.isAssignableTo(type, elementType)) {
      var errorCode = forList
          ? StaticWarningCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
          : StaticWarningCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE;
      errorReporter.reportTypeErrorForNode(
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
      var isNullAware = element.spreadOperator.type ==
          TokenType.PERIOD_PERIOD_PERIOD_QUESTION;
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
    if (!typeSystem.isAssignableTo(keyType, mapKeyType)) {
      errorReporter.reportTypeErrorForNode(
        StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE,
        entry.key,
        [keyType, mapKeyType],
      );
    }

    var valueType = entry.value.staticType;
    if (!typeSystem.isAssignableTo(valueType, mapValueType)) {
      errorReporter.reportTypeErrorForNode(
        StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE,
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

    if (expressionType.isDartCoreNull) {
      if (!isNullAware) {
        errorReporter.reportErrorForNode(
          CompileTimeErrorCode.NOT_NULL_AWARE_NULL_SPREAD,
          expression,
        );
      }
      return;
    }

    InterfaceType iterableType;
    var iterableObjectType = typeProvider.iterableObjectType;
    if (expressionType is InterfaceTypeImpl &&
        typeSystem.isSubtypeOf(expressionType, iterableObjectType)) {
      iterableType = expressionType.asInstanceOf(
        iterableObjectType.element,
      );
    }

    if (iterableType == null) {
      return errorReporter.reportErrorForNode(
        CompileTimeErrorCode.NOT_ITERABLE_SPREAD,
        expression,
      );
    }

    var iterableElementType = iterableType.typeArguments[0];
    if (!typeSystem.isAssignableTo(iterableElementType, elementType)) {
      var errorCode = forList
          ? StaticWarningCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
          : StaticWarningCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE;
      errorReporter.reportTypeErrorForNode(
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

    if (expressionType.isDartCoreNull) {
      if (!isNullAware) {
        errorReporter.reportErrorForNode(
          CompileTimeErrorCode.NOT_NULL_AWARE_NULL_SPREAD,
          expression,
        );
      }
      return;
    }

    InterfaceType mapType;
    var mapObjectObjectType = typeProvider.mapObjectObjectType;
    if (expressionType is InterfaceTypeImpl &&
        typeSystem.isSubtypeOf(expressionType, mapObjectObjectType)) {
      mapType = expressionType.asInstanceOf(mapObjectObjectType.element);
    }

    if (mapType == null) {
      return errorReporter.reportErrorForNode(
        CompileTimeErrorCode.NOT_MAP_SPREAD,
        expression,
      );
    }

    var keyType = mapType.typeArguments[0];
    if (!typeSystem.isAssignableTo(keyType, mapKeyType)) {
      errorReporter.reportTypeErrorForNode(
        StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE,
        expression,
        [keyType, mapKeyType],
      );
    }

    var valueType = mapType.typeArguments[1];
    if (!typeSystem.isAssignableTo(valueType, mapValueType)) {
      errorReporter.reportTypeErrorForNode(
        StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE,
        expression,
        [valueType, mapValueType],
      );
    }
  }
}
