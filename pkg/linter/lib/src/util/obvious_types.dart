// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/ast/extensions.dart';

import '../extensions.dart';

bool _sameOrNull(DartType? t1, DartType? t2) =>
    t1 == null || t2 == null || t1 == t2;

extension CollectionElementExtensions on CollectionElement {
  DartType? get elementType => switch (this) {
    MapLiteralEntry() => null,
    ForElement() =>
      // No need to compute the type of a non-obvious element.
      null,
    IfElement() =>
      // We just need a candidate type, ignore `else`.
      thenElement.elementType,
    Expression() => staticType,
    SpreadElement() => expression.staticType.elementTypeOfIterable,
    NullAwareElement() =>
      // This should be the non-nullable version of `value.staticType`,
      // but since it requires computation, we return null.
      null,
    _ => null,
  };

  bool get hasObviousType => switch (this) {
    Expression() => this.hasObviousType,
    MapLiteralEntry() => key.hasObviousType && value.hasObviousType,
    IfElement() =>
      thenElement.hasObviousType && (elseElement?.hasObviousType ?? true),
    SpreadElement() => expression.hasObviousType,
    NullAwareElement() => value.hasObviousType,
    ForElement() => false,
    _ => false,
  };

  DartType? get keyType => switch (this) {
    MapLiteralEntry() => key.elementType,
    _ => null,
  };

  DartType? get valueType => switch (this) {
    MapLiteralEntry() => value.elementType,
    _ => null,
  };
}

extension DartTypeExtensions on DartType? {
  DartType? get elementTypeOfIterable {
    if (this is InterfaceType) {
      var iterableInterfaces = implementedInterfaces.where(
        (type) => type.isDartCoreIterable,
      );
      if (iterableInterfaces.length == 1) {
        return iterableInterfaces.first.typeArguments.first;
      }
    }
    return null;
  }

  ({DartType? key, DartType? value})? get keyValueTypeOfMap {
    if (this is InterfaceType) {
      var mapInterfaces = implementedInterfaces.where(
        (type) => type.isDartCoreMap,
      );
      if (mapInterfaces.length == 1) {
        var [key, value] = mapInterfaces.first.typeArguments;
        return (key: key, value: value);
      }
    }
    return null;
  }
}

extension ExpressionExtensions on Expression {
  bool get hasObviousType {
    switch (this) {
      case TypedLiteral():
        if (typeArguments != null) {
          // A collection literal with explicit type arguments is trivial.
          return true;
        }
        // A collection literal with no explicit type arguments.
        DartType? theObviousType, theObviousKeyType, theObviousValueType;
        NodeList<CollectionElement> elements = switch (this) {
          ListLiteral() => this.elements,
          SetOrMapLiteral() => this.elements,
        };
        for (var element in elements) {
          if (element.hasObviousType) {
            theObviousType ??= element.elementType;
            theObviousKeyType ??= element.keyType;
            theObviousValueType ??= element.valueType;
            if (!_sameOrNull(theObviousType, element.elementType) ||
                !_sameOrNull(theObviousKeyType, element.keyType) ||
                !_sameOrNull(theObviousValueType, element.valueType)) {
              return false;
            }
          } else {
            return false;
          }
        }
        if (theObviousType != null) {
          var theSelfElementType = staticType.elementTypeOfIterable;
          return theSelfElementType == theObviousType;
        } else if (theObviousKeyType != null && theObviousValueType != null) {
          var keyValueTypes = staticType.keyValueTypeOfMap;
          if (keyValueTypes == null) return false;
          return theObviousKeyType == keyValueTypes.key &&
              theObviousValueType == keyValueTypes.value;
        } else {
          return false;
        }
      case RecordLiteral():
        for (var field in fields) {
          if (field is RecordLiteralNamedField) return false;
          if (!field.fieldExpression.hasObviousType) return false;
        }
        return true;
      case Literal():
        // An atomic literal: `Literal` and not `TypedLiteral`.
        if (this is IntegerLiteral && (staticType?.isDartCoreDouble ?? true)) {
          // An integer literal with static type `double` is not trivial.
          return false;
        }
        return true;
      case SimpleIdentifier():
        if (isQualified) return false;
        var declaration = element;
        if (declaration is LocalVariableElement) {
          return staticType == declaration.type;
        }
        if (declaration is FormalParameterElement) {
          return staticType == declaration.type;
        }
        return false;
      case InstanceCreationExpression():
        var createdType = constructorName.type;
        if (createdType.typeArguments != null) {
          // Explicit type arguments provided.
          return true;
        } else {
          DartType? dartType = createdType.typeOrThrow;
          if (dartType is InterfaceType &&
              dartType.element.typeParameters.isNotEmpty) {
            // A raw type is not trivial.
            return false;
          }
          // A non-generic class or extension type.
          return true;
        }
      case PrefixExpression()
          when (operand is IntegerLiteral || operand is DoubleLiteral) &&
              operator.type == TokenType.MINUS:
        return operand.hasObviousType;
      case CascadeExpression():
        return target.hasObviousType;
      case AsExpression():
        return true;
      case ConditionalExpression():
        if (thenExpression.hasObviousType && elseExpression.hasObviousType) {
          var staticTypeThen = thenExpression.elementType;
          var staticTypeElse = elseExpression.elementType;
          return staticTypeThen == staticTypeElse;
        }
      case IsExpression():
        return true;
      case ThrowExpression():
        return true;
      case ParenthesizedExpression():
        return expression.hasObviousType;
      case ThisExpression():
        return true;
      case TypeLiteral():
        return true;
      case PropertyAccess():
        if (propertyName.name == 'hashCode') {
          return true;
        }
      case PrefixedIdentifier():
        if (identifier.name == 'hashCode') {
          return true;
        }
        return false;
      case MethodInvocation():
        if (methodName.name == 'toString') {
          return true;
        }
        return false;
      case BinaryExpression():
        var operatorName = operator.lexeme;
        if (operatorName == '==' || operatorName == '!=') {
          return true;
        }
    }
    return false;
  }
}
