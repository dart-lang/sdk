// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/error_verifier.dart';

/// Verifier for [CollectionElement]s in list, set, or map literals.
class LiteralElementVerifier {
  final TypeProvider typeProvider;
  final TypeSystemImpl typeSystem;
  final DiagnosticReporter _diagnosticReporter;
  final FeatureSet featureSet;
  final ErrorVerifier _errorVerifier;

  final bool forList;
  final bool forSet;
  final TypeImpl? elementType;

  final bool forMap;
  final TypeImpl? mapKeyType;
  final TypeImpl? mapValueType;

  LiteralElementVerifier(
    this.typeProvider,
    this.typeSystem,
    this._diagnosticReporter,
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
    _verifyElement(element as CollectionElementImpl);
  }

  /// Check that the given [type] is assignable to the [elementType], otherwise
  /// report the list or set error on the [errorNode].
  void _checkAssignableToElementType(TypeImpl type, AstNode errorNode) {
    var elementType = this.elementType;

    if (!typeSystem.isAssignableTo(
      type,
      elementType!,
      strictCasts: _strictCasts,
    )) {
      bool assignableWhenNullable = typeSystem.isAssignableTo(
        type,
        typeSystem.makeNullable(elementType),
        strictCasts: _strictCasts,
      );
      var errorCode = switch ((
        forList: forList,
        assignableWhenNullable: assignableWhenNullable,
      )) {
        (forList: false, assignableWhenNullable: false) =>
          CompileTimeErrorCode.setElementTypeNotAssignable,
        (forList: false, assignableWhenNullable: true) =>
          CompileTimeErrorCode.setElementTypeNotAssignableNullability,
        (forList: true, assignableWhenNullable: false) =>
          CompileTimeErrorCode.listElementTypeNotAssignable,
        (forList: true, assignableWhenNullable: true) =>
          CompileTimeErrorCode.listElementTypeNotAssignableNullability,
      };
      _diagnosticReporter.atNode(
        errorNode,
        errorCode,
        arguments: [type, elementType],
      );
    }
  }

  /// Verify that the given [element] can be assigned to the [elementType] of
  /// the enclosing list, set, of map literal.
  void _verifyElement(CollectionElementImpl? element) {
    switch (element) {
      case ExpressionImpl():
        if (forList || forSet) {
          if (elementType is! VoidType &&
              _errorVerifier.checkForUseOfVoidResult(element)) {
            return;
          }
          _checkAssignableToElementType(element.typeOrThrow, element);
        } else {
          _diagnosticReporter.atNode(
            element,
            CompileTimeErrorCode.expressionInMap,
          );
        }
      case ForElementImpl():
        _verifyElement(element.body);
      case IfElementImpl():
        _verifyElement(element.thenElement);
        _verifyElement(element.elseElement);
      case MapLiteralEntryImpl():
        if (forMap) {
          _verifyMapLiteralEntry(element);
        } else {
          _diagnosticReporter.atNode(
            element,
            CompileTimeErrorCode.mapEntryNotInMap,
          );
        }
      case SpreadElementImpl():
        var isNullAware = element.isNullAware;
        Expression expression = element.expression;
        if (forList || forSet) {
          _verifySpreadForListOrSet(isNullAware, expression);
        } else if (forMap) {
          _verifySpreadForMap(isNullAware, expression);
        }
      case NullAwareElementImpl():
        if (forList || forSet) {
          if (elementType is! VoidType &&
              _errorVerifier.checkForUseOfVoidResult(element.value)) {
            return;
          }
          _checkAssignableToElementType(
            typeSystem.promoteToNonNull(element.value.typeOrThrow),
            element,
          );
        } else {
          _diagnosticReporter.atNode(
            element,
            CompileTimeErrorCode.expressionInMap,
          );
        }
      case null:
        break;
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
    // If the key is null-aware, the entry is only added when the key is not
    // `null`, so the key type to check should be promoted to non-null.
    if (entry.keyQuestion != null) {
      keyType = typeSystem.promoteToNonNull(keyType);
    }
    if (!typeSystem.isAssignableTo(
      keyType,
      mapKeyType,
      strictCasts: _strictCasts,
    )) {
      if (entry.keyQuestion == null &&
          typeSystem.isAssignableTo(
            keyType,
            typeSystem.makeNullable(mapKeyType),
            strictCasts: _strictCasts,
          )) {
        _diagnosticReporter.atNode(
          entry.key,
          CompileTimeErrorCode.mapKeyTypeNotAssignableNullability,
          arguments: [keyType, mapKeyType],
        );
      } else {
        _diagnosticReporter.atNode(
          entry.key,
          CompileTimeErrorCode.mapKeyTypeNotAssignable,
          arguments: [keyType, mapKeyType],
        );
      }
    }

    var valueType = entry.value.typeOrThrow;
    // If the value is null-aware, the entry is only added when the value is not
    // `null`, so the value type to check should be promoted to non-null.
    if (entry.valueQuestion != null) {
      valueType = typeSystem.promoteToNonNull(valueType);
    }
    if (!typeSystem.isAssignableTo(
      valueType,
      mapValueType,
      strictCasts: _strictCasts,
    )) {
      if (entry.valueQuestion == null &&
          typeSystem.isAssignableTo(
            valueType,
            typeSystem.makeNullable(mapValueType),
            strictCasts: _strictCasts,
          )) {
        _diagnosticReporter.atNode(
          entry.value,
          CompileTimeErrorCode.mapValueTypeNotAssignableNullability,
          arguments: [valueType, mapValueType],
        );
      } else {
        _diagnosticReporter.atNode(
          entry.value,
          CompileTimeErrorCode.mapValueTypeNotAssignable,
          arguments: [valueType, mapValueType],
        );
      }
    }
  }

  /// Verify that the type of the elements of the given [expression] can be
  /// assigned to the [elementType] of the enclosing collection.
  void _verifySpreadForListOrSet(bool isNullAware, Expression expression) {
    var expressionType = expression.typeOrThrow;
    if (expressionType is DynamicType) {
      if (_errorVerifier.strictCasts) {
        _diagnosticReporter.atNode(
          expression,
          CompileTimeErrorCode.notIterableSpread,
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
      _diagnosticReporter.atNode(
        expression,
        CompileTimeErrorCode.notNullAwareNullSpread,
      );
      return;
    }

    var iterableType = expressionType.asInstanceOf(
      typeProvider.iterableElement,
    );

    if (iterableType == null) {
      _diagnosticReporter.atNode(
        expression,
        CompileTimeErrorCode.notIterableSpread,
      );
      return;
    }

    var iterableElementType = iterableType.typeArguments[0];
    var elementType = this.elementType;
    if (!typeSystem.isAssignableTo(
      iterableElementType,
      elementType!,
      strictCasts: _strictCasts,
    )) {
      var errorCode = forList
          ? CompileTimeErrorCode.listElementTypeNotAssignable
          : CompileTimeErrorCode.setElementTypeNotAssignable;
      // Also check for an "implicit tear-off conversion" which would be applied
      // after desugaring a spread element.
      var implicitCallMethod = _errorVerifier.getImplicitCallMethod(
        iterableElementType,
        elementType,
        expression,
      );
      if (implicitCallMethod == null) {
        _diagnosticReporter.atNode(
          expression,
          errorCode,
          arguments: [iterableElementType, elementType],
        );
      } else {
        var tearoffType = implicitCallMethod.type;
        if (featureSet.isEnabled(Feature.constructor_tearoffs)) {
          var typeArguments = typeSystem.inferFunctionTypeInstantiation(
            elementType as FunctionTypeImpl,
            tearoffType,
            diagnosticReporter: _diagnosticReporter,
            errorNode: expression,
            genericMetadataIsEnabled: true,
            inferenceUsingBoundsIsEnabled: featureSet.isEnabled(
              Feature.inference_using_bounds,
            ),
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

        if (!typeSystem.isAssignableTo(
          tearoffType,
          elementType,
          strictCasts: _strictCasts,
        )) {
          _diagnosticReporter.atNode(
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
        _diagnosticReporter.atNode(
          expression,
          CompileTimeErrorCode.notMapSpread,
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
      _diagnosticReporter.atNode(
        expression,
        CompileTimeErrorCode.notNullAwareNullSpread,
      );
      return;
    }

    var mapType = expressionType.asInstanceOf(typeProvider.mapElement);

    if (mapType == null) {
      _diagnosticReporter.atNode(expression, CompileTimeErrorCode.notMapSpread);
      return;
    }

    var keyType = mapType.typeArguments[0];
    var mapKeyType = this.mapKeyType;
    if (!typeSystem.isAssignableTo(
      keyType,
      mapKeyType!,
      strictCasts: _strictCasts,
    )) {
      _diagnosticReporter.atNode(
        expression,
        CompileTimeErrorCode.mapKeyTypeNotAssignable,
        arguments: [keyType, mapKeyType],
      );
    }

    var valueType = mapType.typeArguments[1];
    var mapValueType = this.mapValueType;
    if (!typeSystem.isAssignableTo(
      valueType,
      mapValueType!,
      strictCasts: _strictCasts,
    )) {
      _diagnosticReporter.atNode(
        expression,
        CompileTimeErrorCode.mapValueTypeNotAssignable,
        arguments: [valueType, mapValueType],
      );
    }
  }
}
