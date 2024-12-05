// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../extensions.dart';

bool _sameOrNull(DartType? t1, DartType? t2) =>
    t1 == null || t2 == null || t1 == t2;

extension CollectionElementExtensions on CollectionElement {
  DartType? get elementType {
    var self = this; // Enable promotion.
    switch (self) {
      case MapLiteralEntry():
        return null;
      case ForElement():
        // No need to compute the type of a non-obvious element.
        return null;
      case IfElement():
        // We just need a candidate type, ignore `else`.
        return self.thenElement.elementType;
      case Expression():
        return self.staticType;
      case SpreadElement():
        return self.expression.staticType.elementTypeOfIterable;
      case NullAwareElement():
        // This should be the non-nullable version of `self.value.staticType`,
        // but since it requires computation, we return null.
        return null;
    }
  }

  bool get hasObviousType {
    var self = this; // Enable promotion.
    switch (self) {
      case Expression():
        return self.hasObviousType;
      case MapLiteralEntry():
        return self.key.hasObviousType && self.value.hasObviousType;
      case IfElement():
        return self.thenElement.hasObviousType &&
            (self.elseElement?.hasObviousType ?? true);
      case SpreadElement():
        return self.expression.hasObviousType;
      case NullAwareElement():
        return self.value.hasObviousType;
      case ForElement():
        return false;
    }
  }

  DartType? get keyType {
    var self = this; // Enable promotion.
    switch (self) {
      case MapLiteralEntry():
        return self.key.elementType;
      default:
        return null;
    }
  }

  DartType? get valueType {
    var self = this; // Enable promotion.
    switch (self) {
      case MapLiteralEntry():
        return self.value.elementType;
      default:
        return null;
    }
  }
}

extension DartTypeExtensions on DartType? {
  DartType? get elementTypeOfIterable {
    var self = this; // Enable promotion.
    if (self == null) return null;
    if (self is InterfaceType) {
      var iterableInterfaces =
          self.implementedInterfaces.where((type) => type.isDartCoreIterable);
      if (iterableInterfaces.length == 1) {
        return iterableInterfaces.first.typeArguments.first;
      }
    }
    return null;
  }
}

extension ExpressionExtensions on Expression {
  bool get hasObviousType {
    var self = this; // Enable promotion.
    switch (self) {
      case TypedLiteral():
        if (self.typeArguments != null) {
          // A collection literal with explicit type arguments is trivial.
          return true;
        }
        // A collection literal with no explicit type arguments.
        DartType? theObviousType, theObviousKeyType, theObviousValueType;
        NodeList<CollectionElement> elements = switch (self) {
          ListLiteral() => self.elements,
          SetOrMapLiteral() => self.elements
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
        var theSelfElementType = self.staticType.elementTypeOfIterable;
        return theSelfElementType == theObviousType;
      case RecordLiteral():
        for (var expression in self.fields) {
          if (!expression.hasObviousType) return false;
        }
        return true;
      case Literal():
        // An atomic literal: `Literal` and not `TypedLiteral`.
        if (self is IntegerLiteral) {
          // An integer literal with type `double` is clearly not trivial,
          // but even an `int` integer literal may be considered ambiguous.
          return false;
        }
        return true;
      case SimpleIdentifier():
        if (self.isQualified) return false;
        var declaration = self.staticElement?.declaration;
        if (declaration is! LocalVariableElement) return false;
        return self.staticType == declaration.type;
      case InstanceCreationExpression():
        var createdType = self.constructorName.type;
        if (createdType.typeArguments != null) {
          // Explicit type arguments provided.
          return true;
        } else {
          DartType? dartType = createdType.type;
          if (dartType != null) {
            if (dartType is InterfaceType &&
                dartType.element.typeParameters.isNotEmpty) {
              // A raw type is not trivial.
              return false;
            }
            // A non-generic class or extension type.
            return true;
          } else {
            // An unknown type is not trivial.
            return false;
          }
        }
      case CascadeExpression():
        return self.target.hasObviousType;
      case AsExpression():
        return true;
      case ConditionalExpression():
        if (self.thenExpression.hasObviousType &&
            self.elseExpression.hasObviousType) {
          var staticTypeThen = self.thenExpression.elementType;
          var staticTypeElse = self.elseExpression.elementType;
          return staticTypeThen == staticTypeElse;
        }
      case IsExpression():
        return true;
      case ThrowExpression():
        return true;
      case ParenthesizedExpression():
        return self.expression.hasObviousType;
      case ThisExpression():
        return true;
      case TypeLiteral():
        return true;
      case PropertyAccess():
        if (self.propertyName.name == 'hashCode') {
          return true;
        }
      case PrefixedIdentifier():
        if (self.identifier.name == 'hashCode') {
          return true;
        }
        return false;
      case MethodInvocation():
        if (self.methodName.name == 'toString') {
          return true;
        }
        return false;
      case BinaryExpression():
        var operatorName = self.operator.lexeme;
        if (operatorName == '==' || operatorName == '!=') {
          return true;
        }
    }
    return false;
  }
}
