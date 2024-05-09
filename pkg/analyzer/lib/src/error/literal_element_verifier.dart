// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/error_verifier.dart';

/// Verifier for [CollectionElement]s in list, set, or map literals.
class LiteralElementVerifier {
  final TypeProvider typeProvider;
  final TypeSystemImpl typeSystem;
  final ErrorReporter errorReporter;
  final FeatureSet featureSet;
  final ErrorVerifier _errorVerifier;

  final bool forList;
  final bool forSet;
  final DartType? elementType;

  final bool forMap;
  final DartType? mapKeyType;
  final DartType? mapValueType;

  LiteralElementVerifier(
    this.typeProvider,
    this.typeSystem,
    this.errorReporter,
    this._errorVerifier, {
    this.forList = false,
    this.forSet = false,
    this.elementType,
    this.forMap = false,
    this.mapKeyType,
    this.mapValueType,
    required this.featureSet,
  });

  bool get _strictCasts => _errorVerifier.options.strictCasts;

  void verify(CollectionElement element) {
    _verifyElement(element);
  }

  /// Check that the given [type] is assignable to the [elementType], otherwise
  /// report the list or set error on the [errorNode].
  void _checkAssignableToElementType(DartType type, AstNode errorNode) {
    var elementType = this.elementType;

    if (!typeSystem.isAssignableTo(type, elementType!,
        strictCasts: _strictCasts)) {
      var errorCode = forList
          ? CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
          : CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE;
      errorReporter.atNode(
        errorNode,
        errorCode,
        arguments: [type, elementType],
      );
    }
  }

  /// Verify that the given [element] can be assigned to the [elementType] of
  /// the enclosing list, set, of map literal.
  void _verifyElement(CollectionElement? element) {
    if (element is Expression) {
      if (forList || forSet) {
        if (elementType is! VoidType &&
            _errorVerifier.checkForUseOfVoidResult(element)) {
          return;
        }
        _checkAssignableToElementType(element.typeOrThrow, element);
      } else {
        errorReporter.atNode(
          element,
          CompileTimeErrorCode.EXPRESSION_IN_MAP,
        );
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
        errorReporter.atNode(
          element,
          CompileTimeErrorCode.MAP_ENTRY_NOT_IN_MAP,
        );
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
    var mapKeyType = this.mapKeyType!;
    if (mapKeyType is! VoidType &&
        _errorVerifier.checkForUseOfVoidResult(entry.key)) {
      return;
    }

    var mapValueType = this.mapValueType!;
    if (mapValueType is! VoidType &&
        _errorVerifier.checkForUseOfVoidResult(entry.value)) {
      return;
    }

    var keyType = entry.key.typeOrThrow;
    if (!typeSystem.isAssignableTo(keyType, mapKeyType,
        strictCasts: _strictCasts)) {
      errorReporter.atNode(
        entry.key,
        CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE,
        arguments: [keyType, mapKeyType],
      );
    }

    var valueType = entry.value.typeOrThrow;
    if (!typeSystem.isAssignableTo(valueType, mapValueType,
        strictCasts: _strictCasts)) {
      errorReporter.atNode(
        entry.value,
        CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE,
        arguments: [valueType, mapValueType],
      );
    }
  }

  /// Verify that the type of the elements of the given [expression] can be
  /// assigned to the [elementType] of the enclosing collection.
  void _verifySpreadForListOrSet(bool isNullAware, Expression expression) {
    var expressionType = expression.typeOrThrow;
    if (expressionType is DynamicType) {
      if (_errorVerifier.strictCasts) {
        errorReporter.atNode(
          expression,
          CompileTimeErrorCode.NOT_ITERABLE_SPREAD,
        );
      }
      return;
    }

    if (typeSystem.isSubtypeOf(expressionType, NeverTypeImpl.instance)) {
      return;
    }

    if (typeSystem.isSubtypeOf(expressionType, typeSystem.nullNone)) {
      if (isNullAware) {
        return;
      }
      errorReporter.atNode(
        expression,
        CompileTimeErrorCode.NOT_NULL_AWARE_NULL_SPREAD,
      );
      return;
    }

    var iterableType = expressionType.asInstanceOf(
      typeProvider.iterableElement,
    );

    if (iterableType == null) {
      return errorReporter.atNode(
        expression,
        CompileTimeErrorCode.NOT_ITERABLE_SPREAD,
      );
    }

    var iterableElementType = iterableType.typeArguments[0];
    var elementType = this.elementType;
    if (!typeSystem.isAssignableTo(iterableElementType, elementType!,
        strictCasts: _strictCasts)) {
      var errorCode = forList
          ? CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
          : CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE;
      // Also check for an "implicit tear-off conversion" which would be applied
      // after desugaring a spread element.
      var implicitCallMethod = _errorVerifier.getImplicitCallMethod(
          iterableElementType, elementType, expression);
      if (implicitCallMethod == null) {
        errorReporter.atNode(
          expression,
          errorCode,
          arguments: [iterableElementType, elementType],
        );
      } else {
        var tearoffType = implicitCallMethod.type;
        if (featureSet.isEnabled(Feature.constructor_tearoffs)) {
          var typeArguments = typeSystem.inferFunctionTypeInstantiation(
            elementType as FunctionType,
            tearoffType,
            errorReporter: errorReporter,
            errorNode: expression,
            genericMetadataIsEnabled: true,
            strictInference: _errorVerifier.options.strictInference,
            strictCasts: _errorVerifier.options.strictCasts,
            typeSystemOperations: _errorVerifier.typeSystemOperations,
            dataForTesting: null,
            nodeForTesting: null,
          );
          if (typeArguments.isNotEmpty) {
            tearoffType = tearoffType.instantiate(typeArguments);
          }
        }

        if (!typeSystem.isAssignableTo(tearoffType, elementType,
            strictCasts: _strictCasts)) {
          errorReporter.atNode(
            expression,
            errorCode,
            arguments: [iterableElementType, elementType],
          );
        }
      }
    }
  }

  /// Verify that the [expression] is a subtype of `Map<Object, Object>`, and
  /// its key and values are assignable to [mapKeyType] and [mapValueType].
  void _verifySpreadForMap(bool isNullAware, Expression expression) {
    var expressionType = expression.typeOrThrow;
    if (expressionType is DynamicType) {
      if (_errorVerifier.strictCasts) {
        errorReporter.atNode(
          expression,
          CompileTimeErrorCode.NOT_MAP_SPREAD,
        );
      }
      return;
    }

    if (typeSystem.isSubtypeOf(expressionType, NeverTypeImpl.instance)) {
      return;
    }

    if (typeSystem.isSubtypeOf(expressionType, typeSystem.nullNone)) {
      if (isNullAware) {
        return;
      }
      errorReporter.atNode(
        expression,
        CompileTimeErrorCode.NOT_NULL_AWARE_NULL_SPREAD,
      );
      return;
    }

    var mapType = expressionType.asInstanceOf(
      typeProvider.mapElement,
    );

    if (mapType == null) {
      return errorReporter.atNode(
        expression,
        CompileTimeErrorCode.NOT_MAP_SPREAD,
      );
    }

    var keyType = mapType.typeArguments[0];
    var mapKeyType = this.mapKeyType;
    if (!typeSystem.isAssignableTo(keyType, mapKeyType!,
        strictCasts: _strictCasts)) {
      errorReporter.atNode(
        expression,
        CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE,
        arguments: [keyType, mapKeyType],
      );
    }

    var valueType = mapType.typeArguments[1];
    var mapValueType = this.mapValueType;
    if (!typeSystem.isAssignableTo(valueType, mapValueType!,
        strictCasts: _strictCasts)) {
      errorReporter.atNode(
        expression,
        CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE,
        arguments: [valueType, mapValueType],
      );
    }
  }
}
